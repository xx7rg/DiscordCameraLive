#!/bin/sh
#
# Testes da re-selecao de saida em runtime do discordcameralive.js
#
# Cobrem o bug do "Discord carregando infinitamente": quando o pool inteiro de
# proxies gratuitos morre no meio da sessao, o bypass precisa procurar uma saida
# nova ANTES de cair para a conexao direta (IP brasileiro bloqueado).
#
# Roda em container (podman ou docker) com nodejs, carregando o discordcameralive.js
# numa sandbox VM e exercitando openThroughPool/refreshExit contra um servidor
# SOCKS5 de mentira e portas mortas.
#
# Uso:
#   ./tests/test-exit-refresh.sh
#   RUNTIME=docker ./tests/test-exit-refresh.sh

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
cat > "$TMP/socks-server.js" <<'EOF'
"use strict";
const net = require("net");
const PORT = Number(process.env.PORT || 1080);
const server = net.createServer((client) => {
  let buf = Buffer.alloc(0);
  let state = "greeting";
  let nmethods = 0;
  client.on("data", (chunk) => {
    buf = Buffer.concat([buf, chunk]);
    for (;;) {
      if (state === "greeting") {
        if (buf.length < 2) return;
        if (buf[0] !== 5) return client.destroy();
        nmethods = buf[1]; buf = buf.subarray(2); state = "methods";
      } else if (state === "methods") {
        if (buf.length < nmethods) return;
        buf = buf.subarray(nmethods);
        client.write(Buffer.from([5, 0]));
        state = "head";
      } else if (state === "head") {
        if (buf.length < 4) return;
        if (buf[0] !== 5 || buf[1] !== 1) return client.destroy();
        state = "target";
        buf = buf.subarray(4);
      } else if (state === "target") {
        client.write(Buffer.from([5, 0, 0, 1, 0, 0, 0, 0, 0, 0]));
        client.end();
        return;
      } else return;
    }
  });
  client.on("error", () => client.destroy());
});
server.listen(PORT, "0.0.0.0", () => console.log("socks-ok " + PORT));
EOF

cat > "$TMP/exit-refresh-test.js" <<'EOF'
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

async function main() {
  const LIVE = "socks5://127.0.0.1:" + process.env.LIVE_PORT;

  // ------------------------------------------------------------------ 1. pool morto -> refresh
  const p1 = await deadPort(), p2 = await deadPort(), p3 = await deadPort();
  funcs.settleExit(DEAD(p1));
  g.pool = [
    { proxy: DEAD(p1), ms: 100, country: "US" },
    { proxy: DEAD(p2), ms: 200, country: "DE" },
    { proxy: DEAD(p3), ms: 300, country: "GB" },
  ];
  g.pickFreeExit = async () => LIVE;

  const s1 = await funcs.openThroughPool(TARGET);
  if (s1 !== null) ok("1. pool morto -> refresh acha saida viva (nao vai direto)");
  else bad("1. pool morto -> refresh", "openThroughPool retornou null (foi direto)");
  if (s1 !== null) s1.destroy();
  if (logs.some(l => l.includes("procurando uma saida nova"))) ok("1b. log registra a busca por saida nova");
  else bad("1b. log da busca", "nao achei 'procurando uma saida nova' no log");

  // ------------------------------------------------------------------ 2. pool vivo -> sem refresh
  logs.length = 0;
  funcs.settleExit(LIVE);
  g.pool = [{ proxy: LIVE, ms: 100, country: "US" }];
  const s2 = await funcs.openThroughPool(TARGET);
  if (s2 !== null) ok("2. pool vivo -> entrega sem refresh");
  else bad("2. pool vivo", "nao entregou com saida viva");
  if (s2 !== null) s2.destroy();
  if (logs.some(l => l.includes("procurando uma saida nova"))) bad("2b. refresh indevido", "refresh rodou com pool vivo");
  else ok("2b. refresh nao rodou com pool vivo");

  // ------------------------------------------------------------------ 3. dedupe (closure lastRefreshAt zerada: so o teste 1 rodou
  // refresh, e o teste 2 nao; avancamos o tempo para garantir cooldown livre).
  advance(31_000);
  logs.length = 0;
  let calls = 0;
  g.pickFreeExit = async () => { calls++; await new Promise(r => setTimeout(r, 50)); return null; };
  const [ra, rb] = await Promise.all([funcs.refreshExit(), funcs.refreshExit()]);
  if (calls === 1 && ra === null && rb === null) ok("3. dedupe: 2 chamadas simultaneas = 1 busca");
  else bad("3. dedupe", "calls=" + calls);

  // ------------------------------------------------------------------ 3b. cooldown
  // A chamada acima setou lastRefreshAt; chamada imediata e bloqueada.
  logs.length = 0;
  calls = 0;
  const r3 = await funcs.refreshExit();
  if (r3 === null && calls === 0) ok("3b. cooldown respeitado (null, API nao chamada)");
  else bad("3b. cooldown", "r3=" + r3 + " calls=" + calls);

  // ------------------------------------------------------------------ 4. refresh falha -> direto
  advance(31_000);
  logs.length = 0;
  g.pickFreeExit = async () => null;
  const p4 = await deadPort();
  funcs.settleExit(DEAD(p4));
  g.pool = [{ proxy: DEAD(p4), ms: 100, country: "US" }];
  const s4 = await funcs.openThroughPool(TARGET);
  if (s4 === null) ok("4. refresh falha -> cai para direto (fallback intacto)");
  else { bad("4. fallback direto", "deveria ser null"); s4.destroy(); }

  // ------------------------------------------------------------------ 5. saida viva (manual) nao e trocada
  advance(31_000);
  logs.length = 0;
  g.pickFreeExit = async () => LIVE;
  funcs.settleExit(LIVE);
  g.pool = [];
  const s5 = await funcs.openThroughPool(TARGET);
  if (s5 !== null) ok("5. saida viva entrega sem refresh");
  else bad("5. saida viva", "nao entregou");
  if (s5 !== null) s5.destroy();
  if (logs.some(l => l.includes("procurando uma saida nova"))) bad("5b. refresh indevido", "refresh rodou com saida viva");
  else ok("5b. refresh nao rodou com saida viva");

  // ------------------------------------------------------------------ 6. cache de 30min
  // cachedExit valida as guardadas com probe(); um probe fake evita o TLS real.
  g.probe = async (proxy) => ({ proxy: proxy, ms: 50 });
  fs.writeFileSync(path.join(FAKE_RES, "state.json"), JSON.stringify({ pool: [{ proxy: LIVE, ms: 50, country: "US" }], at: fakeNow }));
  const c1 = await funcs.cachedExit();
  if (c1 !== null) ok("6. cache recente reutilizado");
  else bad("6. cache recente", "null");

  fs.writeFileSync(path.join(FAKE_RES, "state.json"), JSON.stringify({ pool: [{ proxy: LIVE, ms: 50, country: "US" }], at: fakeNow - 2 * 60 * 60 * 1000 }));
  const c2 = await funcs.cachedExit();
  if (c2 === null) ok("6b. cache antigo (>30min) ignorado");
  else bad("6b. cache antigo", "reutilizou saida velha");

  // ------------------------------------------------------------------ 7. regressao do mecanismo
  const parsed = funcs.parseProxy("socks5://127.0.0.1:1080");
  if (parsed && parsed.scheme === "socks5" && parsed.host === "127.0.0.1" && parsed.port === 1080)
    ok("7. parseProxy continua funcionando");
  else bad("7. parseProxy", JSON.stringify(parsed));

  const t7 = await funcs.openTunnel(LIVE, "gateway.discord.gg", 443, 5000);
  if (t7 !== null) { ok("7b. openTunnel negocia SOCKS5"); t7.destroy(); }
  else bad("7b. openTunnel", "null");

  console.log(failures === 0 ? "RESULTADO: TUDO OK" : "RESULTADO: " + failures + " FALHA(S)");
  process.exit(failures === 0 ? 0 : 1);
}
main().catch((e) => { console.error(e); process.exit(1); });
EOF

step "Re-selecao de saida em runtime (refreshExit)"
out="$("$RUNTIME" run --rm --pull=missing --user 0 \
    -v "$REPO:/repo:ro" \
    -v "$TMP:/helpers:ro" \
    "$IMG" sh -c '
    pacman -Sy --noconfirm --needed nodejs >/dev/null 2>&1 || { echo "FALHA_DEPS"; exit 1; }

    # SOCKS5 fake: aceita e encaminha (saida viva)
    node /helpers/socks-server.js >/tmp/live.log 2>&1 &
    live_pid=$!
    sleep 1
    LIVE_PORT="$(sed -n "s/^socks-ok //p" /tmp/live.log | head -1)"
    [ -n "$LIVE_PORT" ] || { echo "FALHA_LIVE_SOCKS"; exit 1; }

    LIVE_PORT="$LIVE_PORT" node /helpers/exit-refresh-test.js
    rc=$?
    kill $live_pid 2>/dev/null || true
    exit $rc
' 2>&1)"

echo "$out" | grep -E "\[OK\]|\[FAIL\]|RESULTADO" | sed 's/^\[DiscordCameraLive\] //'

if printf '%s' "$out" | grep -q "RESULTADO: TUDO OK"; then
    ok "re-selecao de saida em runtime: todos os cenarios"
else
    bad "re-selecao de saida falhou: $(printf '%s' "$out" | grep -E '\[FAIL\]' | tail -4)"
fi

echo
echo "== Resultado: $PASS ok, $FAIL falhas =="
[ "$FAIL" -eq 0 ] || exit 1
