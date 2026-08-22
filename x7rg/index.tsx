/*
 * Vencord, a Discord client mod
 * Copyright (c) 2026 Vendicated and contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import { sendBotMessage } from "@api/Commands";
import { definePluginSettings } from "@api/Settings";
import { Paragraph } from "@components/Paragraph";
import { copyWithToast } from "@utils/discord";
import { Logger } from "@utils/Logger";
import { useAwaiter } from "@utils/react";
import definePlugin, { OptionType, PluginNative } from "@utils/types";
import { findStoreLazy } from "@webpack";
import { Constants, RestAPI, SearchableSelect, showToast, Toasts, UserStore } from "@webpack/common";

const Native = VencordNative?.pluginHelpers?.DiscordCameraLive as PluginNative<typeof import("./native")> | undefined;

const logger = new Logger("DiscordCameraLive");

interface RegionStore {
    getPreferredRegion(): string | null;
    getPreferredRegions(): string[] | null;
    shouldIncludePreferredRegion(): boolean;
}

interface VoiceRegion {
    id: string;
    name: string;
    optimal: boolean;
    deprecated: boolean;
    custom: boolean;
}

interface MediaEngineStore {
    supportsInApp(kind: string): boolean;
    supports(kind: string): boolean;
    isSupported(): boolean;
}

interface ApexExperiments {
    getServerAssignment(kind: string, unitId: string, name: string): unknown;
}

interface DiagnosticStore {
    [method: string]: unknown;
}

const RTCRegionStore: RegionStore = findStoreLazy("RTCRegionStore");
const MediaEngineStore: MediaEngineStore = findStoreLazy("MediaEngineStore");
const ApexExperimentStore: ApexExperiments & DiagnosticStore = findStoreLazy("ApexExperimentStore");
const ApplicationStreamingStore: DiagnosticStore = findStoreLazy("ApplicationStreamingStore");
const StreamRTCConnectionStore: DiagnosticStore = findStoreLazy("StreamRTCConnectionStore");
const RTCConnectionStore: DiagnosticStore = findStoreLazy("RTCConnectionStore");

const VIDEO_GUARD = "2026-08-video-guard";

// O experimento so e reavaliado alguns ticks apos o CONNECTION_OPEN; perguntar na hora exata
// respondia "bloqueado" mesmo em sessao ja liberada, e o plugin recarregava a toa.
const VERDICT_DELAY_MS = 1500;

const AUTOMATIC = "";
const VOICE_KEYS: "voiceRegion"[] = ["voiceRegion"];
const STREAM_KEYS: "streamRegion"[] = ["streamRegion"];

let original: RegionStore | undefined;
let lastScope: string | null = null;

interface RegionSelectProps {
    value: string;
    placeholder: string;
    automaticLabel: string;
    onChange(region: string): void;
}

function RegionSelect({ value, placeholder, automaticLabel, onChange }: RegionSelectProps) {
    const [regions, error, pending] = useAwaiter(
        async () => {
            const { body } = await RestAPI.get({ url: Constants.Endpoints.REGIONS() });
            return (body as VoiceRegion[]).filter(region => !region.deprecated && !region.custom);
        },
        { fallbackValue: [] as VoiceRegion[] }
    );

    if (pending) return <Paragraph>Loading the region list.</Paragraph>;
    if (error) return <Paragraph>Discord did not hand over the region list. Log in and reopen settings to try again.</Paragraph>;

    const options = [
        { label: automaticLabel, value: AUTOMATIC },
        ...regions.map(region => ({ label: region.optimal ? `${region.name}, optimal for you` : region.name, value: region.id }))
    ];

    return (
        <SearchableSelect
            placeholder={placeholder}
            maxVisibleItems={8}
            options={options}
            value={options.find(option => option.value === value)?.value}
            onChange={onChange}
            closeOnSelect
        />
    );
}

function VoiceRegionPicker() {
    const { voiceRegion } = settings.use(VOICE_KEYS);

    return (
        <RegionSelect
            value={voiceRegion}
            placeholder="Pick the region your calls should connect through"
            automaticLabel="Automatic, whatever Discord picks"
            onChange={region => settings.store.voiceRegion = region}
        />
    );
}

function StreamRegionPicker() {
    const { streamRegion } = settings.use(STREAM_KEYS);

    return (
        <RegionSelect
            value={streamRegion}
            placeholder="Pick the region your screen share should go through"
            automaticLabel="Same region as your call"
            onChange={region => settings.store.streamRegion = region}
        />
    );
}

const settings = definePluginSettings({
    voiceRegion: {
        type: OptionType.COMPONENT,
        component: VoiceRegionPicker,
        default: AUTOMATIC
    },
    streamRegion: {
        type: OptionType.COMPONENT,
        component: StreamRegionPicker,
        default: AUTOMATIC
    },
    sessionRouting: {
        type: OptionType.SELECT,
        description: "What goes through the proxy. Only the gateway is what unlocks Go Live, and it keeps the rest of Discord at full speed. Adding the login also hides your real address while you authenticate, at the cost of a slower start.",
        options: [
            { label: "Gateway only, fastest", value: "gateway", default: true },
            { label: "Gateway and login, hides your address while you sign in", value: "login" }
        ]
    },
    proxy: {
        type: OptionType.STRING,
        description: "Proxy that carries the gateway connection, like socks5://127.0.0.1:9050 for Tor. Add a login as socks5://user:password@host:port when your proxy needs one. Leave empty and a free proxy is picked and tested for you, which means a stranger carries your login.",
        default: "",
        // Aceita usuario e senha antes do @. O trecho e casado com ganancia para a senha poder
        // conter @ e :, que e comum em credencial gerada por provedor.
        isValid: (value: string) => value.trim() === "" || /^(socks5|https?):\/\/(?:.+@)?[a-z0-9.-]{1,253}:\d{1,5}$/.test(value.trim())
            || "Use socks5://host:porta, ou socks5://usuario:senha@host:porta se o seu proxy pedir login."
    },
    excludedCountries: {
        type: OptionType.STRING,
        description: "Two letter country codes, comma separated, whose proxies are never used. The real exit address is checked, not the one the list claims.",
        default: "BR"
    }
});

function forcedRegion() {
    const region = settings.store.voiceRegion;
    if (typeof region !== "string") return null;

    const trimmed = region.trim();
    return trimmed === AUTOMATIC ? null : trimmed;
}

function forceRegion() {
    if (original !== undefined) return;

    const store = RTCRegionStore;
    if (typeof store.getPreferredRegion !== "function"
        || typeof store.getPreferredRegions !== "function"
        || typeof store.shouldIncludePreferredRegion !== "function") {
        showToast("DiscordCameraLive could not find Discord's region picker, so your call region is untouched.", Toasts.Type.FAILURE);
        return;
    }

    const saved: RegionStore = {
        getPreferredRegion: store.getPreferredRegion,
        getPreferredRegions: store.getPreferredRegions,
        shouldIncludePreferredRegion: store.shouldIncludePreferredRegion
    };

    store.getPreferredRegion = function () {
        return forcedRegion() ?? saved.getPreferredRegion.call(this);
    };

    store.getPreferredRegions = function () {
        const forced = forcedRegion();
        const ranked = saved.getPreferredRegions.call(this);
        return forced === null ? ranked : [forced, ...(ranked ?? []).filter(region => region !== forced)];
    };

    store.shouldIncludePreferredRegion = function () {
        return forcedRegion() !== null || saved.shouldIncludePreferredRegion.call(this);
    };

    original = saved;
}

function restoreRegion() {
    if (original === undefined) return;

    RTCRegionStore.getPreferredRegion = original.getPreferredRegion;
    RTCRegionStore.getPreferredRegions = original.getPreferredRegions;
    RTCRegionStore.shouldIncludePreferredRegion = original.shouldIncludePreferredRegion;
    original = undefined;
}

function videoIsBlocked() {
    const user = UserStore.getCurrentUser();
    if (user == null) return false;

    const assignment = ApexExperimentStore.getServerAssignment("user", user.id, VIDEO_GUARD);
    if (assignment === null || typeof assignment !== "object") return false;

    // As duas variacoes do experimento desligam video; o balde de controle nao tem nenhuma
    // delas. Ler supportsInApp aqui seria inutil: o patch do plugin deixa esse valor sempre
    // verdadeiro, e a checagem nunca detectaria bloqueio nenhum.
    const { variantId } = assignment as { variantId?: unknown; };
    return variantId === 1 || variantId === 2;
}

// O Logger do Vencord so aparece no console do DevTools, que ninguem abre para relatar um
// problema. Isto vai para o mesmo arquivo do processo principal, entao o registro conta a
// historia inteira num lugar so.
function record(message: string) {
    logger.info(message);
    Native?.logFromRenderer(message).catch(() => {
        // Sem o registro em arquivo ainda resta o console; nao vale quebrar o fluxo por isso.
    });
}

// O que so o renderer enxerga. Sem isto o arquivo mostraria qual saida subiu, mas nunca se o
// servidor aceitou, que e a pergunta que importa.
function recordSession() {
    const user = UserStore.getCurrentUser();
    const assignment = user == null ? "sem usuario" : ApexExperimentStore.getServerAssignment("user", user.id, VIDEO_GUARD);

    record(`sessao aberta | atribuicao do video guard: ${JSON.stringify(assignment)}`);
    record(`  o cliente aceita video? supports ${ask(MediaEngineStore, "supports", "VIDEO")} | supportsInApp ${ask(MediaEngineStore, "supportsInApp", "VIDEO")} | desktop ${ask(MediaEngineStore, "supportsInApp", "DESKTOP_CAPTURE")}`);
    record(`  regiao preferida ${ask(RTCRegionStore, "getPreferredRegion")} | lista ${JSON.stringify(ask(RTCRegionStore, "getPreferredRegions"))} | override instalado ${original !== undefined}`);
}

// Sem refazer o gateway a sessao fica bloqueada ate o proximo reinicio -- o socket que
// importa ja nasceu fora da rota. Recarregar e a unica saida, e o processo principal limita
// quantas vezes isso pode acontecer.
async function retryBehindExit() {
    if (!Native) return;

    try {
        const result = await Native.retryWithProxy(settings.store.excludedCountries);
        record(result.retried
            ? `recarregando para o gateway renascer atras da saida (tentativa ${result.attempt})`
            : `nao da para tentar de novo: ${result.reason}`);

        if (result.retried) {
            showToast(`DiscordCameraLive is reconnecting behind the proxy (attempt ${result.attempt}).`);
            return;
        }

        showToast(`DiscordCameraLive could not unlock this session (${result.reason}). Open your proxy, then restart Discord from the tray.`, Toasts.Type.FAILURE);
    } catch (error) {
        logger.error("Failed to reach the desktop process", error);
    }
}

// Incrementado a cada CONNECTION_OPEN: uma reconexao antes do timer anterior disparar
// invalida o veredito antigo, entao so a chamada mais recente age.
let sessionGeneration = 0;

async function reportSession() {
    if (!Native) return;

    const generation = ++sessionGeneration;
    recordSession();

    let exit: string | null = null;
    try {
        ({ exit, scope: lastScope } = await Native.sessionOpened());
    } catch (error) {
        logger.error("Failed to reach the desktop process", error);
        return;
    }

    // Try no corpo inteiro do timer: excecao aqui dentro escapa sem virar rejeicao pegavel,
    // e um rename em alguma loja faria o plugin ficar mudo em vez de registrar o erro.
    setTimeout(() => {
        if (generation !== sessionGeneration) return;

        try {
            if (videoIsBlocked()) {
                record(`o servidor continuou bloqueando video nesta sessao, saida do gateway: ${exit ?? "nenhuma"}`);
                retryBehindExit();
                return;
            }

            record(exit === null
                ? "o servidor liberou video sem precisar de proxy"
                : `o servidor liberou video nesta sessao, gateway por ${exit}`);
            Native.sessionWorked().catch(error => logger.error("Failed to reach the desktop process", error));

            showToast(exit === null
                ? "Go Live is unlocked on this session, no proxy was needed."
                : "Go Live is unlocked on this session. Only the gateway stays on the proxy, everything else is direct now.", Toasts.Type.SUCCESS);
        } catch (error) {
            logger.error("Failed to read the video guard verdict for this session", error);
        }
    }, VERDICT_DELAY_MS);
}

function ask(store: object, method: string, ...args: unknown[]) {
    const fn = (store as DiagnosticStore)[method];
    if (typeof fn !== "function") return "metodo ausente";

    try {
        return (fn as (...a: unknown[]) => unknown).apply(store, args) ?? null;
    } catch (error) {
        return `erro: ${error instanceof Error ? error.message : String(error)}`;
    }
}

async function buildReport() {
    const user = UserStore.getCurrentUser();
    const lines: string[] = ["DiscordCameraLive, diagnostico"];

    lines.push("", "== o servidor te bloqueia? ==");
    lines.push(`atribuicao do video guard: ${JSON.stringify(user == null ? "sem usuario" : ask(ApexExperimentStore, "getServerAssignment", "user", user.id, VIDEO_GUARD))}`);

    lines.push("", "== o cliente consegue fazer video? ==");
    lines.push(`supports(VIDEO)          ${ask(MediaEngineStore, "supports", "VIDEO")}`);
    lines.push(`supportsInApp(VIDEO)     ${ask(MediaEngineStore, "supportsInApp", "VIDEO")}`);
    lines.push(`supportsInApp(DESKTOP)   ${ask(MediaEngineStore, "supportsInApp", "DESKTOP_CAPTURE")}`);
    lines.push(`motor de midia pronto    ${ask(MediaEngineStore, "isSupported")}`);

    lines.push("", "== transmissao ==");
    lines.push(`minha transmissao ativa  ${JSON.stringify(ask(ApplicationStreamingStore, "getCurrentUserActiveStream"))}`);
    lines.push(`transmissoes visiveis    ${JSON.stringify(ask(ApplicationStreamingStore, "getAllActiveStreams"))}`);
    lines.push(`conexoes de midia        ${JSON.stringify(ask(StreamRTCConnectionStore, "getAllActiveStreamKeys"))}`);
    lines.push(`estado da call           ${ask(RTCConnectionStore, "getState")} em ${ask(RTCConnectionStore, "getHostname")}`);

    lines.push("", "== regiao ==");
    lines.push(`preferida  ${ask(RTCRegionStore, "getPreferredRegion")}`);
    lines.push(`lista      ${JSON.stringify(ask(RTCRegionStore, "getPreferredRegions"))}`);
    lines.push(`override instalado ${original !== undefined}`);

    lines.push("", "== configuracao ==");
    const { proxy, sessionRouting, voiceRegion, streamRegion, excludedCountries } = settings.store;
    lines.push(`proxy "${proxy}" | roteamento "${sessionRouting}" | regiao de call "${voiceRegion}" | regiao de stream "${streamRegion}" | paises fora "${excludedCountries}"`);

    lines.push("", "== processo principal ==");
    if (!Native) {
        lines.push("indisponivel, o plugin esta rodando sem a parte desktop");
    } else {
        // O que o CONNECTION_OPEN devolveu, nao uma pergunta nova: um diagnostico que mexe no
        // roteamento estragaria a sessao que a pessoa esta tentando descrever.
        lines.push(`escopo na abertura da sessao: ${lastScope ?? "a sessao nao abriu com o plugin no ar"}`);

        try {
            lines.push(`saida do gateway agora: ${await Native.getActiveProxy() ?? "nenhuma"}`);
            lines.push(await Native.getLog() || "sem registros");
        } catch (error) {
            lines.push(`nao consegui falar com o processo principal: ${error instanceof Error ? error.message : String(error)}`);
        }
    }

    return lines.join("\n");
}

export default definePlugin({
    name: "DiscordCameraLive",
    description: "Turns Go Live and camera back on for Brazilian accounts by neutralising Discord's video guard, and keeps your calls on the region you pick.",
    authors: [],
    tags: ["Voice", "Privacy"],
    settings,

    patches: [
        {
            find: "\"2026-08-video-guard\"",
            replacement: {
                match: /(?<=name:"2026-08-video-guard".{0,100}?)variations:\{.{0,120}?\}\}(?=\}\))/,
                replace: "variations:{}"
            }
        },
        {
            find: ".STREAM_CREATE,{type:",
            replacement: {
                match: /(?<=\.STREAM_CREATE,\{.{0,80}?preferred_region:)\i/,
                replace: "$self.pickStreamRegion($&)"
            }
        }
    ],

    pickStreamRegion(fallback: string | null) {
        const region = settings.store.streamRegion;
        return typeof region === "string" && region !== AUTOMATIC ? region : fallback;
    },

    commands: [
        {
            name: "discordcameralive",
            description: "Copia um diagnostico do plugin para voce colar no suporte.",
            async execute(_args, ctx) {
                const report = await buildReport();
                copyWithToast(report, "Diagnostico copiado. Cole no canal de suporte.");
                sendBotMessage(ctx.channel.id, { content: `\`\`\`\n${report.slice(0, 1800)}\n\`\`\`` });
            }
        }
    ],

    flux: {
        CONNECTION_OPEN() {
            reportSession();
        },

        LOGOUT() {
            record("voce saiu da conta, preparando a rota para o proximo login");
            Native?.sessionClosed().catch(error => logger.error("Failed to reach the desktop process", error));
        }
    },

    start() {
        forceRegion();

        // Cobre ativar o plugin com o Discord ja aberto: no boot o processo principal ja
        // chama isto sozinho, e la as duas chamadas dividem uma unica subida.
        Native?.enable().then(result => {
            if (result?.success === false)
                showToast("DiscordCameraLive could not start its local router. Details are in the log file.", Toasts.Type.FAILURE);
        }).catch(error => logger.error("Failed to reach the desktop process", error));
    },

    stop() {
        restoreRegion();
        Native?.shutdown().catch(error => logger.error("Failed to reach the desktop process", error));
    }
});
