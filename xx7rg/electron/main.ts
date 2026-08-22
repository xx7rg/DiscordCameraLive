import {
  app,
  BrowserWindow,
  ipcMain,
  Menu,
  nativeImage,
  Tray,
  shell,
} from "electron";
import path, { dirname } from "path";
import { fileURLToPath } from "url";
import { createRequire } from "module";
import { homedir } from "os";
import fs from "fs";
import { execFileSync, execSync, spawn, spawnSync } from "child_process";
import { bypassCode } from "./bypass";
import { runScript } from "./linux-helper";
import { setupUpdater, isQuittingForUpdate } from "./updater";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const isMac = process.platform === "darwin";
const IS_LINUX = process.platform === "linux";

// Cores da barra de titulo (Windows, titleBarOverlay) — casam com os tokens
// --canvas e --ink do renderer em cada tema.
const TITLEBAR = {
  light: { color: "#F7F6F3", symbolColor: "#2F3437" },
  dark: { color: "#0F0F12", symbolColor: "#E6E6EA" },
};
// Tema padrao: dark (o renderer tambem usa dark como fallback).
let theme: "light" | "dark" = "dark";

function applyTitlebarTheme() {
  if (!mainWindow || mainWindow.isDestroyed() || isMac) return;
  mainWindow.setTitleBarOverlay(TITLEBAR[theme]);
}

// No Linux com Wayland, o Chromium tenta inicializar Vulkan e o processo GPU cai com
// "'--ozone-platform=wayland' is not compatible with Vulkan" (wayland_surface_factory.cc).
// A janela abre, mas o renderer fica preso em "Verificando..." para sempre (o getStatus
// via IPC nunca responde). Desligar a aceleracao de hardware (SwiftShader no lugar) resolve
// — e este app e uma janela fixa de 480px, nao precisa de GPU. Vale para X11 tambem.
if (IS_LINUX) {
  app.disableHardwareAcceleration();
  app.commandLine.appendSwitch("disable-gpu");
}

// O fs do Electron trata *.asar como pasta. original-fs e o disco de verdade, o mesmo
// que o instalador do Vencord usa para renomear o app.asar.
const diskFs: typeof fs = (() => {
  try {
    return createRequire(import.meta.url)("original-fs");
  } catch {
    return fs;
  }
})();

const FLAVOURS = ["Discord", "DiscordPTB", "DiscordCanary"];

const MAC_APPS = [
  { flavour: "Discord", appName: "Discord.app", processName: "Discord" },
  {
    flavour: "DiscordPTB",
    appName: "Discord PTB.app",
    processName: "Discord PTB",
  },
  {
    flavour: "DiscordCanary",
    appName: "Discord Canary.app",
    processName: "Discord Canary",
  },
] as const;

const MAC_HELPER_PROCESSES = [
  "Discord Helper",
  "Discord Helper (GPU)",
  "Discord Helper (Renderer)",
  "Discord Helper (Plugin)",
];

let mainWindow: BrowserWindow | null = null;
let tray: Tray | null = null;

// Fechar a janela esconde na bandeja (Windows) / barra de menus (Mac); so o Sair do menu
// desliga o app (e reverte o bypass, como o fechar da janela fazia antes). Sem a trava, o X
// derrubaria o app e a pessoa nem notaria que a janela foi parar junto do relogio.
let quitting = false;
let cleaningUp = false;

// Os icones moram em assets/ e seguem no pacote pelo "files" do electron-builder. O icone do
// exe vem de build/icon.ico; no Mac o .icns e gerado a partir do mesmo desenho.
//
// Importante: no Linux (AppImage) os assets ficam DENTRO do app.asar, e o nativeImage
// createFromPath nao le de dentro do asar (API nativa, nao passa pelo patch do fs). Ler o
// arquivo com fs (que entende asar) e criar a imagem do buffer resolve a bandeja com icone
// vazio/invalido.
function assetPath(name: string) {
  return path.join(__dirname, "..", "assets", name);
}

function loadAsset(name: string) {
  const file = assetPath(name);
  try {
    return nativeImage.createFromBuffer(fs.readFileSync(file));
  } catch {
    return nativeImage.createFromPath(file);
  }
}

function startupLabel() {
  return isMac ? "Iniciar com o Mac" : "Iniciar com o Windows";
}

function enclosingApp(filePath: string) {
  let dir = path.resolve(filePath);
  while (dir !== path.dirname(dir)) {
    if (dir.endsWith(".app")) return dir;
    dir = path.dirname(dir);
  }
  return filePath;
}

function openAppManagementSettings() {
  void shell.openExternal(
    "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AppBundles",
  );
}

function writeError(targetPath: string) {
  if (isMac) {
    const appPath = enclosingApp(targetPath);
    return [
      `Não foi possível escrever dentro de Discord.app (${targetPath}).`,
      "",
      "O macOS bloqueia outros apps de alterar o Discord — é a mesma permissão que o Vencord pede.",
      "",
      "1. Ajustes do Sistema → Privacidade e Segurança → Administração de Apps",
      "2. Ative o DiscordCameraLive (ou arraste o app para a lista)",
      "3. Volte aqui e tente de novo",
      "",
      "Se ainda falhar, no Terminal:",
      `sudo chown -R "$(whoami):staff" ${JSON.stringify(appPath)}`,
    ].join("\n");
  }
  return `Não foi possível escrever na pasta do Discord (${targetPath}).`;
}

function macPermissionDenied(targetPath: string): never {
  openAppManagementSettings();
  throw new Error(writeError(targetPath));
}

function lockedFileHint(targetPath: string) {
  if (isMac) {
    return `Arquivo bloqueado pelo sistema: ${targetPath}\n\nDICA: Feche o Discord completamente (Cmd+Q) e tente novamente.`;
  }
  return `Arquivo bloqueado pelo sistema: ${targetPath}\n\nDICA: Feche o Discord completamente pelo Gerenciador de Tarefas e tente novamente.`;
}

function isPermissionError(e: any) {
  return e && (e.code === "EACCES" || e.code === "EPERM");
}

/**
 * O app mora na bandeja / barra de menus.  Windows o arg --hidden esconde a janela;
 * No Mac usamos wasOpenedAtLogin porque o openAsHidden morreu no macOS 13 :(
 * Nos dois casos sobe so o icone, sem jogar janela na cara do usuario a cada login.
 */
function getStartup() {
  if (IS_LINUX) {
    const file = path.join(app.getPath('home'), '.config', 'autostart', 'discordcameralive.desktop');
    return fs.existsSync(file);
  }
  return app.getLoginItemSettings().openAtLogin;
}

function setStartup(enabled: boolean) {
  if (IS_LINUX) {
    const dir = path.join(app.getPath('home'), '.config', 'autostart');
    const file = path.join(dir, 'discordcameralive.desktop');
    try {
      if (enabled) {
        fs.mkdirSync(dir, { recursive: true });
        // Exec com --hidden: abre so na bandeja/notificacao no login, sem jogar janela na tela.
        fs.writeFileSync(file, `[Desktop Entry]
Type=Application
Name=DiscordCameraLive
Comment=Devolve o Go Live e a camera no Discord
Exec=${process.execPath} --hidden
X-GNOME-Autostart-enabled=true
`);
      } else if (fs.existsSync(file)) {
        fs.unlinkSync(file);
      }
    } catch (error) {
      console.error('Falha ao alterar autostart:', error);
    }
    return;
  }
  app.setLoginItemSettings({
    openAtLogin: enabled,
    args: ["--hidden"],
  });
}

function launchedHidden() {
  return (
    process.argv.includes("--hidden") ||
    app.getLoginItemSettings().wasOpenedAtLogin
  );
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 480,
    // A altura e ajustada pelo proprio conteudo: a pagina avisa via IPC 'resize-window'
    // quando o warning do bypass ativo aparece/some, e a janela cresce/encolhe para nao
    // cortar nada (antes o aviso ficava cortado com a altura fixa de 560).
    height: 560,
    resizable: false,
    icon: loadAsset('icon.png'),
    webPreferences: {
      preload: path.join(__dirname, "preload.js"),
      nodeIntegration: false,
      contextIsolation: true,
      sandbox: true,
    },
    autoHideMenuBar: true,
    titleBarStyle: isMac ? "hiddenInset" : "hidden",
    ...(isMac
      ? {
          trafficLightPosition: { x: 8, y: 8 },
          useContentSize: true,
        }
      : {
          titleBarOverlay: TITLEBAR[theme],
        }),
  });

  // Sem isto, um link com target="_blank" abre numa janela do Electron sem barra de endereco:
  // a pessoa nao ve para onde esta indo, e nao tem como voltar. Vale para o botao do Discord,
  // que ja existia.
  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    if (/^https:\/\//.test(url)) void shell.openExternal(url);
    return { action: "deny" };
  });

  mainWindow.on("close", (event) => {
    if (quitting) return;
    // Fechar a janela esconde na bandeja / barra de menus e o app continua vivo em segundo
    // plano, nos tres SOs. Quem quer encerrar de verdade usa o "Sair" (que reverte o bypass).
    event.preventDefault();
    mainWindow?.hide();
  });

  if (process.env.VITE_DEV_SERVER_URL) {
    mainWindow.loadURL(process.env.VITE_DEV_SERVER_URL);
  } else {
    mainWindow.loadFile(path.join(__dirname, "../dist/index.html"));
  }
}

// A janela precisa refletir o que a bandeja fez; sem isto, ativar/desativar pelo icone deixava
// a interface com o estado antigo (botao "Ativar" com o bypass ja ativo, por exemplo).
function refreshWindowStatus() {
  if (mainWindow && !mainWindow.isDestroyed()) {
    mainWindow.webContents.send('refresh-status');
  }
}

function showWindow() {
  // Durante o encerramento (quit, auto-update reexecutando) nao faz sentido
  // mostrar janela: o mainWindow/tray podem ja estar destruidos, e acessar
  // objetos destruidos derruba o app com "Object has been destroyed".
  if (quitting) return;
  if (mainWindow && !mainWindow.isDestroyed()) {
    mainWindow.show();
    mainWindow.focus();
    // A bandeja pode ter mudado o startup ou o status com a janela escondida; ao reaparecer, sincroniza.
    mainWindow.webContents.send("refresh-startup");
    refreshWindowStatus();
  } else {
    createWindow();
  }
  refreshTray().catch(() => {});
}

function statusLabel(status: string) {
  if (status === "ACTIVE") return "ativo";
  if (status === "OTHER_MOD") return "outro mod detectado";
  if (status === "NOT_FOUND") return "Discord não encontrado";
  return "inativo";
}

// O status no Linux vem do script (async); no Windows e sincrono. Guardamos o ultimo valor
// para o menu montar sem travar e para o botao Ativar/Desativar ficar sempre clicavel.
let cachedStatus: string | null = null;

// O menu e remontado a cada mudanca: e o jeito simples de o rotulo de status e o item
// Ativar/Desativar refletirem o estado atual sem logica de diff.
async function refreshTray() {
  if (!tray) return;
  try {
    const status = IS_LINUX ? await linuxStatus() : getStatus();
    cachedStatus = status;
    const label = statusLabel(status);
    tray.setToolTip(`DiscordCameraLive — ${label}`);
    tray.setContextMenu(
      Menu.buildFromTemplate([
        { label: `DiscordCameraLive — ${label}`, enabled: false },
        { type: "separator" },
        { label: "Abrir", click: showWindow },
        {
          label: status === "ACTIVE" ? "Desativar o bypass" : "Ativar o bypass",
          // Sempre clicavel: mesmo com Discord "nao encontrado" a pessoa pode tentar de novo.
          click: () => { toggleFromTray().catch(() => refreshTray()); },
        },
        {
          label: startupLabel(),
          type: "checkbox",
          checked: getStartup(),
          click: (item) => setStartup(item.checked),
        },
        { type: "separator" },
        // Sair pela bandeja / barra de menus reverte so o que e nosso.
        {
          label: status === "ACTIVE" ? "Sair (desfaz o bypass)" : "Sair",
          click: quitApp,
        },
      ]),
    );
  } catch {
    // uma bandeja sem menu nao vale derrubar o app
  }
}

async function toggleFromTray() {
  try {
    // Atualiza o menu com "trabalhando" para dar feedback imediato do clique.
    if (tray) {
      tray.setToolTip('DiscordCameraLive — trabalhando...');
      tray.setContextMenu(Menu.buildFromTemplate([
        { label: 'DiscordCameraLive — trabalhando...', enabled: false },
      ]));
    }

    if (IS_LINUX) {
      const status = await linuxStatus();
      if (status === "ACTIVE") await linuxDeactivate(() => {});
      else await linuxActivate("", () => {});
    } else if (getStatus() === "ACTIVE") {
      await deactivateAll();
    } else {
      await activateBypass(null, "");
    }
  } catch (error) {
    console.error('toggle falhou:', error);
  } finally {
    await refreshTray().catch(() => {});
    refreshWindowStatus();
  }
}

async function quitApp() {
  // O restore (reverter o bypass) vive no before-quit, que cobre Sair da bandeja, Cmd+Q no
  // Mac e o quit do app; aqui so disparamos a saida. A reversao corre sem travar o quit.
  quitting = true;
  app.quit();
}

function trayIcon() {
  // loadAsset le do buffer (fs entende o app.asar); no Linux/AppImage o createFromPath
  // nao enxerga dentro do asar e a bandeja ficaria com icone vazio.
  const source = loadAsset("tray.png");
  if (!isMac) return source;

  // tray.png e 32x32. Sem scaleFactor o macOS desenha 32pt, o dobro dos outros icones da barra.
  const icon = nativeImage.createFromBuffer(source.toPNG(), { scaleFactor: 2 });
  icon.setTemplateImage(true);
  return icon;
}

function createTray() {
  tray = new Tray(trayIcon());
  tray.on("click", showWindow);
  refreshTray().catch(() => {});
}

// No KDE Plasma (e outros com StatusNotifier), o Tray do Electron so aparece se o
// org.kde.StatusNotifierWatcher ja estiver no session bus na hora da criacao. No login via
// autostart o app sobe antes do Plasma terminar de subir, o watcher ainda nao existe, e o
// Electron cai para o GtkStatusIcon — que o Plasma 6 nao mostra na bandeja. Esperar o watcher
// (com timeout) resolve; sem watcher (ambientes sem SNI) cria mesmo assim, no fallback antigo.
function waitForStatusNotifier(timeoutMs = 10000): Promise<void> {
  if (!IS_LINUX) return Promise.resolve();
  return new Promise((resolve) => {
    const check = () => {
      try {
        execFileSync("dbus-send", [
          "--session",
          "--dest=org.freedesktop.DBus",
          "--type=method_call",
          "--print-reply",
          "/org/freedesktop/DBus",
          "org.freedesktop.DBus.NameHasOwner",
          "string:org.kde.StatusNotifierWatcher",
        ], { stdio: "ignore" });
        resolve();
        return;
      } catch {
        // watcher ainda nao subiu; tenta de novo ate o prazo
      }
      if (Date.now() - started > timeoutMs) {
        resolve();
        return;
      }
      setTimeout(check, 1000);
    };
    const started = Date.now();
    check();
  });
}

// Com o app morando na bandeja, rodar o exe de novo nao pode empilhar uma segunda copia:
// ela morre aqui e a janela da primeira aparece.
const gotLock = app.requestSingleInstanceLock();
if (!gotLock) {
  app.quit();
} else {
  app.on("second-instance", () => showWindow());

  app.whenReady().then(() => {
    // No login (start com --hidden / wasOpenedAtLogin) sobe so a bandeja; a janela aparece no clique.
    if (!launchedHidden()) createWindow();
    // No KDE o watcher da bandeja (StatusNotifier) pode demorar a subir no login; esperar
    // evita o Tray cair para o GtkStatusIcon, que o Plasma 6 nao exibe.
    waitForStatusNotifier().then(createTray);
    app.on("activate", showWindow);
    // Checa por atualizacao na release do GitHub (Windows portable: baixa e substitui;
    // Mac/Linux: autoUpdater nativo). Roda sozinho e em silencio se nao houver nada.
    setupUpdater(() => mainWindow);
  });
}

// Cmd+Q no Mac nao passa por window-all-closed da mesma forma que o Sair da bandeja no Windows:
// o restore vive aqui para os dois caminhos.
app.on("before-quit", (event) => {
  // Durante o auto-update o quit nao pode ser adiado: o processo novo ja foi
  // executado e precisa do lock de instancia unica. Sem esta saida, o app
  // antigo fica vivo e o novo morre — o "fecha mas nao abre".
  if (isQuittingForUpdate()) return;
  // A segunda instancia so acorda a primeira e morre: sem esta guarda ela restauraria o
  // Discord na saida, desfazendo o bypass que a instancia principal acabou de aplicar.
  if (!gotLock || cleaningUp) return;
  event.preventDefault();
  quitting = true;
  cleaningUp = true;
  // Reversao em background: o runScript roda detached/unref, entao o filho sobrevive ao
  // app.quit() e o Discord nao fica com a injecao pendurada. Sem esperar: o "Sair" sai na
  // hora mesmo se o script demorar (fechar o Discord, flatpak, sudo...).
  const restore = IS_LINUX ? linuxDeactivate(() => {}) : deactivateAll();
  restore.catch(() => {});
  app.quit();
});

// A bandeja e a "dona" do app: fechar a janela so esconde (em qualquer SO), e o processo
// continua vivo em segundo plano. Sem isto, no Linux o window-all-closed derrubaria o app
// inteiro ao fechar a janela. Quem quer encerrar de verdade usa o "Sair" (quitApp -> before-quit).
app.on("window-all-closed", () => {
  // manter vivo — a bandeja cuida do resto
});

function withNoAsar<T>(fn: () => T): T {
  const previous = process.noAsar;
  process.noAsar = true;
  try {
    return fn();
  } finally {
    process.noAsar = previous;
  }
}

interface DiscordInstall {
  flavour: string;
  resources: string;
  exePath: string;
  bundlePath?: string;
}

function getWinDiscordInstalls(): DiscordInstall[] {
  const localAppData = process.env.LOCALAPPDATA;
  if (!localAppData) return [];

  const installs: DiscordInstall[] = [];
  for (const flavour of FLAVOURS) {
    const rootPath = path.join(localAppData, flavour);
    if (!diskFs.existsSync(rootPath)) continue;

    const dirs = diskFs
      .readdirSync(rootPath)
      .filter((d) => d.startsWith("app-"));
    if (dirs.length === 0) continue;

    dirs.sort();
    const latestApp = dirs[dirs.length - 1];
    const resourcesPath = path.join(rootPath, latestApp, "resources");
    const exePath = path.join(rootPath, latestApp, `${flavour}.exe`);
    const asar = path.join(resourcesPath, "app.asar");
    const originalAsar = path.join(resourcesPath, "_app.asar");
    if (diskFs.existsSync(asar) || diskFs.existsSync(originalAsar)) {
      installs.push({ flavour, resources: resourcesPath, exePath });
    }
  }
  return installs;
}

function getMacDiscordInstalls(): DiscordInstall[] {
  const roots = ["/Applications", path.join(homedir(), "Applications")];
  const installs: DiscordInstall[] = [];
  const seen = new Set<string>();

  for (const root of roots) {
    for (const { flavour, appName } of MAC_APPS) {
      if (seen.has(flavour)) continue;
      const bundlePath = path.join(root, appName);
      const resources = path.join(bundlePath, "Contents", "Resources");
      const asar = path.join(resources, "app.asar");
      const originalAsar = path.join(resources, "_app.asar");
      if (diskFs.existsSync(asar) || diskFs.existsSync(originalAsar)) {
        installs.push({ flavour, resources, exePath: "", bundlePath });
        seen.add(flavour);
      }
    }
  }
  return installs;
}

function getDiscordInstalls(): DiscordInstall[] {
  return withNoAsar(() =>
    isMac ? getMacDiscordInstalls() : getWinDiscordInstalls(),
  );
}

function discordIsRunning(): boolean {
  if (isMac) {
    for (const { processName } of MAC_APPS) {
      try {
        execFileSync("pgrep", ["-x", processName], { stdio: "ignore" });
        return true;
      } catch {}
    }
    return false;
  }

  for (const flavour of FLAVOURS) {
    try {
      const out = execSync(`tasklist /FI "IMAGENAME eq ${flavour}.exe" /NH`, {
        encoding: "utf8",
        stdio: ["pipe", "pipe", "ignore"],
      });
      if (out.toLowerCase().includes(`${flavour}.exe`.toLowerCase()))
        return true;
    } catch {}
  }
  return false;
}

async function waitUntilDiscordGone(tries = 40, delayMs = 250) {
  for (let i = 0; i < tries; i++) {
    if (!discordIsRunning()) return true;
    await new Promise((r) => setTimeout(r, delayMs));
  }
  return !discordIsRunning();
}

function killMacProcesses(names: readonly string[], signal?: "-9") {
  for (const name of names) {
    try {
      execFileSync("killall", signal ? [signal, name] : [name], {
        stdio: "ignore",
      });
    } catch {}
  }
}

async function killDiscord() {
  if (isMac) {
    const mains = MAC_APPS.map((macApp) => macApp.processName);
    killMacProcesses(mains);
    killMacProcesses(MAC_HELPER_PROCESSES);
    if (!(await waitUntilDiscordGone())) {
      killMacProcesses(mains, "-9");
      killMacProcesses(MAC_HELPER_PROCESSES, "-9");
      await waitUntilDiscordGone(20, 250);
    }
    return;
  }

  for (const flavour of FLAVOURS) {
    try {
      execSync(`taskkill /F /T /IM ${flavour}.exe`, { stdio: "ignore" });
    } catch {}
  }
  await waitUntilDiscordGone();
}

function assertResourcesWritable(install: DiscordInstall) {
  const probe = path.join(install.resources, ".discordcameralive-write-test");
  try {
    withNoAsar(() => {
      diskFs.writeFileSync(probe, "");
      diskFs.unlinkSync(probe);
    });
  } catch {
    if (isMac) macPermissionDenied(install.bundlePath || install.resources);
    throw new Error(writeError(install.bundlePath || install.resources));
  }
}

function isAdHocSigned(bundlePath: string) {
  const result = spawnSync("codesign", ["-dv", "--verbose=2", bundlePath], {
    encoding: "utf8",
  });
  const info = `${result.stdout}\n${result.stderr}`;
  return /\badhoc\b/i.test(info) || /TeamIdentifier=not set/.test(info);
}

function assertDiscordSignature(bundlePath: string | undefined) {
  if (!isMac || !bundlePath) return;
  if (!isAdHocSigned(bundlePath)) return;
  throw new Error(
    [
      "O Discord.app está com a assinatura quebrada (assinatura ad-hoc).",
      "",
      "O macOS trata esse Discord como outro app: pede a senha do Keychain (Discord Safe Storage) e o cliente cai. Desativar o bypass não devolve a assinatura original da Discord Inc.",
      "",
      "Baixe o Discord de novo em https://discord.com/download e substitua o app em Aplicativos.",
      "Não apague ~/Library/Application Support/discord — sua conta continua lá.",
    ].join("\n"),
  );
}

/**
 *  Reassinar com codesign --deep --sign apaga as entitlements (JIT, library validation) e o Team ID: o Keychain pede senha e
 * o Chromium crasha.
 */
function clearBundleQuarantine(bundlePath: string | undefined) {
  if (!isMac || !bundlePath) return;
  try {
    execFileSync("xattr", ["-cr", bundlePath], { stdio: "ignore" });
  } catch {
    // sem atributos estendidos nao e erro
  }
}

async function safeRename(oldPath: string, newPath: string) {
  let lastError;
  for (let i = 0; i < 15; i++) {
    try {
      withNoAsar(() => {
        diskFs.renameSync(oldPath, newPath);
      });
      return;
    } catch (e: any) {
      if (isPermissionError(e)) {
        if (isMac) macPermissionDenied(oldPath);
        throw new Error(writeError(oldPath));
      }
      lastError = e;
      await new Promise((r) => setTimeout(r, 500));
    }
  }
  throw new Error(
    `${lockedFileHint(oldPath)}\nErro: ${lastError?.message || "Desconhecido"}`,
  );
}

async function safeRemove(targetPath: string) {
  let lastError;
  for (let i = 0; i < 15; i++) {
    try {
      withNoAsar(() => {
        if (diskFs.existsSync(targetPath)) {
          diskFs.rmSync(targetPath, { recursive: true, force: true });
        }
      });
      return;
    } catch (e: any) {
      if (isPermissionError(e)) {
        if (isMac) macPermissionDenied(targetPath);
        throw new Error(writeError(targetPath));
      }
      lastError = e;
      await new Promise((r) => setTimeout(r, 500));
    }
  }
  throw new Error(`Falha ao remover arquivo bloqueado: ${targetPath}`);
}

function startDiscord(install: DiscordInstall) {
  try {
    // exec() deixava o stdout do Discord preso num pipe nosso: quando a GUI morria (ou o
    // buffer do exec enchia), o pipe quebrava, e qualquer log de excecao do processo
    // principal do Discord virava EPIPE fatal ("A JavaScript error occurred in the main
    // process", relato real). O Discord precisa nascer sem pipe nenhum para nos: stdio
    // ignorado e sem referencia. Sem detached de proposito: no Windows ele faz o filho
    // sair na hora em alguns ambientes, e aqui ele nao falta.
    if (isMac && install.bundlePath) {
      spawn("open", [install.bundlePath], { stdio: "ignore" }).unref();
    } else if (install.exePath) {
      spawn(install.exePath, [], { stdio: "ignore" }).unref();
    }
  } catch {}
}

// O _app.asar so existe quando alguem ja injetou: e o Discord original guardado de lado. Se ele
// existe e o app.asar nao e nosso, quem esta ali e outro mod.
function isOurInjection(resources: string) {
  return withNoAsar(() => {
    const indexJs = path.join(resources, "app.asar", "index.js");
    if (!diskFs.existsSync(indexJs)) return false;
    return diskFs.readFileSync(indexJs, "utf8").includes("discordcameralive.js");
  });
}

// ---------------------------------------------------------------------------
// Troca transacional do app.asar: nenhuma das duas funcoes abaixo apaga o conteudo
// atual antes de o novo estar pronto e validado do lado. Uma queda de energia, disco
// cheio ou permissao negada no meio do caminho no maximo deixa uma pasta/arquivo de
// staging ou rollback solto (que a proxima chamada limpa sozinha) -- nunca um Discord
// sem app.asar nenhum, que era o estado antigo em caso de falha no meio da escrita.
// ---------------------------------------------------------------------------

async function writeInjectionStaged(resources: string, proxyAddress: string) {
  const staging = path.join(resources, "app.asar.discordcameralive-staging");
  await safeRemove(staging);
  try {
    withNoAsar(() => {
      diskFs.mkdirSync(staging);
      diskFs.writeFileSync(
        path.join(staging, "package.json"),
        JSON.stringify({ name: "discord", main: "index.js" }),
      );
      diskFs.writeFileSync(path.join(staging, "discordcameralive.js"), bypassCode);
      diskFs.writeFileSync(
        path.join(staging, "settings.json"),
        JSON.stringify({ enabled: true, proxy: proxyAddress }),
      );
      diskFs.writeFileSync(
        path.join(staging, "index.js"),
        `require('./discordcameralive.js');`,
      );
    });
  } catch (e) {
    await safeRemove(staging).catch(() => {});
    throw e;
  }
  return staging;
}

// Promove newContentPath a app.asar. O app.asar anterior (se existir) so sai do
// caminho por rename para um nome de rollback -- e so e apagado de vez depois que o
// novo ja esta no lugar certo. Se o rename final falhar, tenta devolver o anterior
// para o Discord nao ficar sem nada.
async function swapIn(resources: string, newContentPath: string) {
  const asar = path.join(resources, "app.asar");
  const rollback = path.join(resources, "app.asar.discordcameralive-rollback");
  await safeRemove(rollback);
  const hadPrevious = withNoAsar(() => diskFs.existsSync(asar));
  if (hadPrevious) await safeRename(asar, rollback);
  try {
    await safeRename(newContentPath, asar);
  } catch (e) {
    if (hadPrevious) await safeRename(rollback, asar).catch(() => {});
    throw e;
  }
  if (hadPrevious) await safeRemove(rollback);
}

async function activateBypass(event: any, proxyAddress: string = "") {
  const installs = getDiscordInstalls();
  if (installs.length === 0) throw new Error("Nenhum Discord encontrado.");

  for (const install of installs) {
    assertDiscordSignature(install.bundlePath);
    assertResourcesWritable(install);
  }

  await killDiscord();

  for (const install of installs) {
    const asar = path.join(install.resources, "app.asar");
    const originalAsar = path.join(install.resources, "_app.asar");

    const hasOriginal = withNoAsar(() => diskFs.existsSync(originalAsar));
    const hasAsar = withNoAsar(() => diskFs.existsSync(asar));

    if (!hasOriginal && hasAsar) {
      // Discord intocado: garante o backup do original antes de qualquer coisa tocar
      // o app.asar. E a unica copia do Discord de verdade que existe.
      await safeRename(asar, originalAsar);
    }
    // Nos demais casos (outro mod, ou nossa propria injecao antiga) o backup ja
    // existe em _app.asar; so falta trocar o conteudo do app.asar pelo novo.

    const staging = await writeInjectionStaged(install.resources, proxyAddress);
    await swapIn(install.resources, staging);

    clearBundleQuarantine(install.bundlePath);
    startDiscord(install);
  }
}

async function deactivateAll() {
  const installs = getDiscordInstalls();

  // So desfaz o que e nosso. Isto roda ao sair do app, e antes desfazia qualquer injecao:
  // quem tinha Equicord ou Vencord abria este app, fechava, e o mod sumia sem nada avisar.
  const ours = installs.filter(
    (install) =>
      withNoAsar(() =>
        diskFs.existsSync(path.join(install.resources, "_app.asar")),
      ) && isOurInjection(install.resources),
  );

  // Decidido antes de matar o Discord: sem isto, quem tem outro mod teria o Discord fechado
  // para nada, porque nao haveria o que desfazer depois.
  if (ours.length === 0) return;

  for (const install of ours) assertResourcesWritable(install);

  await killDiscord();

  for (const install of ours) {
    const originalAsar = path.join(install.resources, "_app.asar");
    // swapIn preserva o app.asar (nossa injecao) num rollback ate o original estar
    // no lugar; se o restore falhar no meio, o Discord fica com a injecao de volta
    // em vez de sem app.asar nenhum.
    await swapIn(install.resources, originalAsar);
    clearBundleQuarantine(install.bundlePath);
    startDiscord(install);
  }
}

function getStatus(): string {
  const installs = getDiscordInstalls();
  if (installs.length === 0) return "NOT_FOUND";
  return withNoAsar(() => {
    for (const install of installs) {
      const asar = path.join(install.resources, "app.asar");
      const originalAsar = path.join(install.resources, "_app.asar");
      if (diskFs.existsSync(originalAsar)) {
        // Checa se é o nosso bypass
        const indexJs = path.join(asar, "index.js");
        if (diskFs.existsSync(indexJs)) {
          const content = diskFs.readFileSync(indexJs, "utf8");
          if (content.includes("discordcameralive.js")) return "ACTIVE";
        }
        return "OTHER_MOD";
      }
    }
    return "INACTIVE";
  });
}

// ---------------------------------------------------------------------------
// Linux: delega para o script standalone (POSIX). A GUI e uma casca: quem decide
// tudo (deteccao, flatpak, sudo, injecao) e o script, e a GUI mostra o progresso.
// ---------------------------------------------------------------------------

function linuxStatus(): Promise<string> {
  return runScript(["--status", "--json"])
    .then(({ code, stdout }) => {
      if (code !== 0) return "NOT_FOUND";
      try {
        const data = JSON.parse(stdout);
        const discords = data.discords ?? [];
        if (discords.length === 0) return "NOT_FOUND";
        const anyOurs = discords.some(
          (d: { state: string }) => d.state === "nosso",
        );
        const anyMod = discords.some(
          (d: { state: string }) => d.state === "outromod",
        );
        if (anyOurs) return "ACTIVE";
        if (anyMod) return "OTHER_MOD";
        return "INACTIVE";
      } catch {
        return "NOT_FOUND";
      }
    })
    .catch(() => "NOT_FOUND");
}

async function linuxActivate(
  proxyAddress: string,
  onChunk: (c: string) => void,
) {
  const args = ["--yes"];
  if (proxyAddress.trim() !== "") args.push("--proxy", proxyAddress.trim());
  const { code, stderr } = await runScript(args, onChunk);
  if (code !== 0) {
    throw new Error(
      stderr.split("\n").filter(Boolean).slice(-3).join("\n") ||
        "Falha ao ativar",
    );
  }
}

async function linuxDeactivate(onChunk: (c: string) => void) {
  const { code, stderr } = await runScript(["--uninstall"], onChunk);
  if (code !== 0) {
    throw new Error(
      stderr.split("\n").filter(Boolean).slice(-3).join("\n") ||
        "Falha ao desativar",
    );
  }
}

// A bandeja precisa refletir o que os botoes da janela fizeram, entao os handlers de IPC
// tambem remontam o menu ao terminar.
ipcMain.handle("activate", async (event, proxyAddress: unknown) => {
  // proxyAddress vem do renderer: nunca confiar no tipo, so o preload garante o shape.
  const addr = typeof proxyAddress === "string" ? proxyAddress.slice(0, 512) : "";
  if (IS_LINUX) {
    await linuxActivate(addr, (c) =>
      event.sender.send("bypass-log", c),
    );
  } else {
    await activateBypass(event, addr);
  }
  refreshTray().catch(() => {});
});
ipcMain.handle("deactivate", async (event) => {
  if (IS_LINUX) {
    await linuxDeactivate((c) => event.sender.send("bypass-log", c));
  } else {
    await deactivateAll();
  }
  refreshTray().catch(() => {});
});
ipcMain.handle("get-platform", () => (IS_LINUX ? "linux" : isMac ? "mac" : "windows"));
ipcMain.handle("get-status", async () => {
  if (IS_LINUX) return linuxStatus();
  return getStatus();
});
ipcMain.handle("get-startup", () => getStartup());
ipcMain.handle("set-startup", (_event, enabled: unknown) => {
  setStartup(enabled === true);
  refreshTray().catch(() => {});
});

// A pagina reporta a altura de que precisa (o warning do bypass ativo faz o conteudo crescer).
// A janela e fixa (resizable: false), entao o proprio app ajusta para caber tudo sem cortar.
ipcMain.on('resize-window', (_event, height: unknown) => {
  const h = Number(height);
  // Teto de 1200: a pagina e uma janela fixa de 480px de largura com conteudo
  // curto, nao ha motivo legitimo para pedir uma altura maior que isso.
  if (!mainWindow || mainWindow.isDestroyed() || !Number.isFinite(h) || h <= 0 || h > 1200) return;
  const [, currentH] = mainWindow.getSize();
  if (Math.abs(currentH - Math.round(h)) < 2) return;
  mainWindow.setSize(480, Math.round(h));
});

// O renderer avisa quando o tema muda para o overlay da barra de titulo
// (Windows) acompanhar; no Mac e Linux nao ha overlay a ajustar.
ipcMain.on('set-theme', (_event, value: unknown) => {
  if (value !== 'light' && value !== 'dark') return;
  theme = value;
  applyTitlebarTheme();
});
