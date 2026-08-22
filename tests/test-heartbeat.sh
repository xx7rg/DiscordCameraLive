#!/bin/sh
#
# Testes do batimento (heartbeat) do discordcameralive.js
#
# O refreshExit conserta a saida depois que uma conexao ja falhou. O batimento existe para que
# ela nao chegue a falhar: de trinta em trinta segundos a saida ativa e as reservas sao
# reconferidas, e a troca acontece antes de o Discord precisar dela -- que e o que salva uma
# transmissao em andamento, porque a reconexao do gateway e o que decide se o video cai.
#
# Roda em container (podman ou docker) com nodejs, carregando o discordcameralive.js numa sandbox VM
# e chamando checkPool/beat direto, com o probe trocado por um de mentira.
#
# Uso:
#   ./tests/test-heartbeat.sh
#   RUNTIME=docker ./tests/test-heartbeat.sh

set -eu

REPO="$(cd -- "$(dirname -- "$0")/.." && pwd)"
RUNTIME="${RUNTIME:-podman}"
IMG="artixlinux/artixlinux:latest"
PASS=0
FAIL=0

if ! command -v "$RUNTIME" >/dev/null 2>&1; then
    echo "Preciso do $RUNTIME para rodar os testes." >&2
    exit 1
fi

step() { printf '\n== %s ==\n' "$1"; }
ok()   { PASS=$((PASS + 1)); printf '  [OK] %s\n' "$1"; }
bad()  { FAIL=$((FAIL + 1)); printf '  [FAIL] %s\n' "$1"; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Servidor SOCKS5 de mentira: aceita a negociacao e responde sucesso.

cat > "$TMP/heartbeat-test.js" <<'JSEOF'
// Exercita openThroughPool + refreshExit do discordcameralive.js em sandbox VM.
"use strict";
const net = require("net");
const fs = require("fs");
const path = require("path");
const vm = require("vm");
const Module = require("module");

const BYPASS = "/repo/standalone/discordcameralive.js";
let failures = 0;
function ok(name) { console.log("  [OK] " + name); }
function bad(name, extra) { failures++; console.log("  [FAIL] " + name + (extra ? ": " + extra : "")); }

// Discord fake exigido pelo top-level do bypass.
const FAKE_RES = "/tmp/discord-fake/resources";
fs.mkdirSync(path.join(FAKE_RES, "_app.asar"), { recursive: true });
fs.writeFileSync(path.join(FAKE_RES, "_app.asar", "package.json"), JSON.stringify({ name: "discord", main: "index.js" }));
fs.writeFileSync(path.join(FAKE_RES, "_app.asar", "index.js"), "// discord fake");
fs.writeFileSync(path.join(FAKE_RES, "settings.json"), JSON.stringify({ enabled: true, proxy: "", excludedCountries: "BR" }));

// whenReady NAO dispara o callback: o start() real baixaria a API de saidas e travaria o
// teste. O teste chama openThroughPool/refreshExit diretamente.
const appStub = { on: () => {}, whenReady: () => ({ then: () => {} }), setAppPath: () => {} };
const sessionStub = { defaultSession: { resolveProxy: async () => "DIRECT", setProxy: async () => {} } };

const code = fs.readFileSync(BYPASS, "utf8");
const sandboxRequire = (name) => {
  if (name === "electron") return { app: appStub, session: sessionStub };
  if (name === "original-fs") return require("fs");
  return Module._load(name, { filename: BYPASS }, false);
};
sandboxRequire.main = { filename: "/tmp/discord-fake/resources/app.asar/index.js" };
const sandbox = {
  require: sandboxRequire,
  module: { exports: {} },
  exports: {},
  __dirname: "/tmp/discord-fake/resources",
  __filename: BYPASS,
  console, process, Buffer,
  setTimeout, clearTimeout, setInterval, clearInterval,
  URL, URLSearchParams, Date,
};
sandbox.module.exports = sandbox.exports;
sandbox.global = sandbox;
vm.createContext(sandbox);
vm.runInContext(code, sandbox, { filename: BYPASS });

const g = sandbox;
const logs = [];
const origLog = g.log;
g.log = (line) => { logs.push(String(line)); origLog(line); };

// Relogio fake: o bypass usa Date.now() para cooldown e idade do cache.
// Controlar o tempo permite testar o cooldown de 30s sem esperar.
let fakeNow = Date.now();
g.Date.now = () => fakeNow;
const advance = (ms) => { fakeNow += ms; };

const funcs = {};
for (const name of ["parseProxy", "openTunnel", "openThroughPool", "refreshExit", "settleExit", "pickFreeExit", "cachedExit", "safeProxy", "probe"]) {
  if (typeof g[name] === "function") funcs[name] = g[name];
}

const DEAD = (port) => "socks5://127.0.0.1:" + port;
const TARGET = { host: "gateway.discord.gg", port: 443 };

async function deadPort() {
  return new Promise((resolve) => {
    const srv = net.createServer();
    srv.listen(0, "127.0.0.1", () => { const p = srv.address().port; srv.close(() => resolve(p)); });
  });
}


// ------------------------------------------------------------------ testes do batimento

// Semeia o pote pelo unico caminho que existe: cachedExit() le o state.json e preenche `pool`.
// `pool` e `chosenExit` sao let no topo do arquivo, entao atribuir g.pool nao chega no modulo --
// o binding lexico sombreia a propriedade global. Por isso o estado entra por aqui.
async function seed(entries, active) {
  fs.writeFileSync(path.join("/tmp/discord-fake/resources", "state.json"),
    JSON.stringify({ pool: entries.map(p => ({ proxy: p, ms: 10, country: "US" })), at: fakeNow }));
  g.probe = async (proxy) => ({ proxy, ms: 10 });
  await g.cachedExit();
  g.settleExit(active);
}

function vivos(lista) {
  g.probe = async (proxy) => (lista.includes(proxy) ? { proxy, ms: 10 } : null);
}

async function main() {
  const A = "socks5://127.0.0.1:1111";
  const B = "socks5://127.0.0.1:2222";
  const C = "socks5://127.0.0.1:3333";

  // impede que stockReserves saia para a internet durante os testes
  g.huntExits = async () => [];

  // 1) tudo vivo: nada muda
  await seed([A, B, C], A);
  vivos([A, B, C]);
  await g.checkPool();
  let s = g.poolStatus();
  if (s.active === A && s.pool.length === 3) ok("1. tudo vivo mantem ativa e pote");
  else bad("1. tudo vivo", JSON.stringify(s));

  // 2) ativa morre: reserva assume no PRIMEIRO erro, ninguem sai do pote ainda
  await seed([A, B, C], A);
  vivos([B, C]);
  logs.length = 0;
  await g.checkPool();
  s = g.poolStatus();
  if (s.active !== A && (s.active === B || s.active === C)) ok("2. reserva assume no primeiro erro");
  else bad("2. promocao", JSON.stringify(s));
  if (s.pool.length === 3) ok("2b. um erro so nao tira do pote");
  else bad("2b. pote", JSON.stringify(s.pool));
  if (s.missed.some(([p, n]) => p === A && n === 1)) ok("2c. o erro ficou marcado");
  else bad("2c. marca", JSON.stringify(s.missed));
  if (logs.some(l => l.includes("perdeu o batimento, assumindo a reserva"))) ok("2d. a troca foi registrada");
  else bad("2d. registro", logs.join(" | "));

  // 3) segundo erro seguido: sai do pote
  await g.checkPool();
  s = g.poolStatus();
  if (!s.pool.includes(A) && s.pool.length === 2) ok("3. segundo erro seguido tira do pote");
  else bad("3. remocao", JSON.stringify(s.pool));
  if (!s.missed.some(([p]) => p === A)) ok("3b. a marca foi limpa junto");
  else bad("3b. marca", JSON.stringify(s.missed));

  // 4) uma resposta boa zera a contagem
  await seed([A, B], A);
  vivos([B]);
  await g.checkPool();          // A erra uma vez (e B assume)
  vivos([A, B]);
  await g.checkPool();          // A volta
  s = g.poolStatus();
  if (!s.missed.some(([p]) => p === A) && s.pool.includes(A)) ok("4. resposta boa zera a contagem");
  else bad("4. recuperacao", JSON.stringify(s));

  // 5) nada vivo: chama o refreshExit em vez de promover uma morta
  await seed([A, B], A);
  vivos([]);
  let refreshed = 0;
  const realRefresh = g.refreshExit;
  g.refreshExit = async () => { refreshed++; return null; };
  logs.length = 0;
  await g.checkPool();
  s = g.poolStatus();
  if (refreshed === 1) ok("5. sem reserva viva chama o refreshExit");
  else bad("5. refreshExit", "chamadas=" + refreshed);
  if (s.active === A) ok("5b. nao promoveu uma morta");
  else bad("5b. promocao indevida", JSON.stringify(s));
  g.refreshExit = realRefresh;

  // 6) reservas de menos disparam a reposicao, sem trocar a ativa
  await seed([A, B], A);
  vivos([A]);                    // A viva, zero reservas vivas
  let stocked = 0;
  g.huntExits = async () => { stocked++; return []; };
  fakeNow += 181_000;            // passa o STOCK_COOLDOWN_MS, que e de tres minutos
  await g.checkPool();
  await new Promise(r => setTimeout(r, 20));
  s = g.poolStatus();
  if (stocked === 1) ok("6. pote baixo dispara a reposicao");
  else bad("6. reposicao", "chamadas=" + stocked);
  if (s.active === A) ok("6b. a reposicao nao troca a ativa saudavel");
  else bad("6b. ativa trocada", JSON.stringify(s));

  // 7) o batimento nao se sobrepoe a si mesmo
  await seed([A, B], A);
  let probes = 0;
  g.probe = async (proxy) => { probes++; await new Promise(r => setTimeout(r, 40)); return { proxy, ms: 10 }; };
  const dois = Promise.all([g.beat(), g.beat()]);
  await dois;
  if (probes === 2) ok("7. batimento simultaneo roda uma vez so");
  else bad("7. sobreposicao", "probes=" + probes + " (esperado 2, um por saida)");

  console.log(failures === 0 ? "\nRESULTADO: TUDO OK" : "\nRESULTADO: " + failures + " FALHA(S)");
  process.exit(failures === 0 ? 0 : 1);
}

main().catch(e => { console.error(e); process.exit(1); });

JSEOF

step "Batimento: manter reserva viva (checkPool)"
out="$("$RUNTIME" run --rm --pull=missing --user 0 \
    -v "$REPO:/repo:ro" \
    -v "$TMP:/helpers:ro" \
    "$IMG" sh -c '
    pacman -Sy --noconfirm --needed nodejs >/dev/null 2>&1 || { echo "FALHA_DEPS"; exit 1; }
    node /helpers/heartbeat-test.js
' 2>&1)"

echo "$out" | grep -E "\[OK\]|\[FAIL\]|RESULTADO" | sed 's/^\[DiscordCameraLive\] //'

if printf '%s' "$out" | grep -q "RESULTADO: TUDO OK"; then
    ok "batimento: todos os cenarios"
else
    bad "batimento falhou: $(printf '%s' "$out" | grep -E '\[FAIL\]' | tail -4)"
fi

echo
echo "== Resultado: $PASS ok, $FAIL falhas =="
[ "$FAIL" -eq 0 ] || exit 1
