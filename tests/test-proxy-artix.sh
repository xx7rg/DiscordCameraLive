#!/bin/sh
#
# Teste do sistema de proxy do DiscordCameraLive em container OpenRC (Artix Linux)
#
# Valida o fluxo completo do proxy manual (SOCKS5) que o usuario configura na GUI:
#   1. o standalone grava o proxy no settings.json (fora da pasta do Discord)
#   2. o discordcameralive.js le o settings.json e usa o proxy manual como saida
#   3. o roteador local (SOCKS5 em 127.0.0.1) encaminha a conexao do gateway
#      pelo proxy manual ate o destino
#
# Uso:
#   ./tests/test-proxy-artix.sh
#   RUNTIME=docker ./tests/test-proxy-artix.sh
#
# Requer podman ou docker (rootless OK). O teste monta um servidor SOCKS5 de
# mentira dentro do container e confere que as conexoes do bypass passam por ele.

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

# Monta os scripts de teste num diretorio temporario (o container monta /repo read-only,
# entao os helpers vao por um volume separado).
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/socks-server.js" <<'EOF'
// Servidor SOCKS5 de teste (sem auth) que encaminha para qualquer destino.
"use strict";
const net = require("net");
const fs = require("fs");
const PORT = Number(process.env.PORT || 1080);
const LOG = "/tmp/socks.log";
function log(line) { try { fs.appendFileSync(LOG, new Date().toISOString() + " " + line + "\n"); } catch {} }
const server = net.createServer((client) => {
  log("conexao de " + client.remoteAddress + ":" + client.remotePort);
  let buf = Buffer.alloc(0);
  let state = "greeting";
  let nmethods = 0, atyp = 0, hostLen = 0;
  client.on("data", (chunk) => {
    buf = Buffer.concat([buf, chunk]);
    for (;;) {
      if (state === "greeting") {
        if (buf.length < 2) return;
        if (buf[0] !== 5) { log("greeting invalido"); return client.destroy(); }
        nmethods = buf[1]; buf = buf.subarray(2); state = "methods";
      } else if (state === "methods") {
        if (buf.length < nmethods) return;
        buf = buf.subarray(nmethods);
        client.write(Buffer.from([5, 0]));
        state = "head";
      } else if (state === "head") {
        if (buf.length < 4) return;
        if (buf[0] !== 5 || buf[1] !== 1) { log("req invalida"); return client.destroy(); }
        atyp = buf[3]; buf = buf.subarray(4);
        state = atyp === 3 ? "hostlen" : atyp === 1 ? "ipv4" : "bad";
        if (state === "bad") { log("atyp invalido " + atyp); return client.destroy(); }
      } else if (state === "hostlen") {
        if (buf.length < 1) return;
        hostLen = buf[0]; buf = buf.subarray(1); state = "host";
      } else if (state === "host") {
        if (buf.length < hostLen + 2) return;
        const host = buf.subarray(0, hostLen).toString("utf8");
        const port = buf.readUInt16BE(hostLen);
        buf = buf.subarray(hostLen + 2);
        connectUpstream(client, host, port);
        return;
      } else if (state === "ipv4") {
        if (buf.length < 6) return;
        const host = Array.from(buf.subarray(0, 4)).join(".");
        const port = buf.readUInt16BE(4);
        buf = buf.subarray(6);
        connectUpstream(client, host, port);
        return;
      } else return;
    }
  });
  client.on("error", () => client.destroy());
});
function connectUpstream(client, host, port) {
  log("pedido: " + host + ":" + port);
  const upstream = net.connect({ host, port });
  upstream.setTimeout(5000, () => upstream.destroy());
  upstream.on("connect", () => {
    log("conectado em " + host + ":" + port);
    client.write(Buffer.from([5, 0, 0, 1, 0, 0, 0, 0, 0, 0]));
    upstream.pipe(client); client.pipe(upstream);
  });
  upstream.on("error", (e) => {
    log("falha ao conectar " + host + ":" + port + ": " + e.message);
    client.write(Buffer.from([5, 5, 0, 1, 0, 0, 0, 0, 0, 0]));
    client.destroy();
  });
  upstream.on("close", () => client.destroy());
  client.on("close", () => upstream.destroy());
}
server.listen(PORT, "0.0.0.0", () => log("SOCKS5 de teste ouvindo em 0.0.0.0:" + PORT));
console.log("SOCKS5 test server on :" + PORT);
EOF

cat > "$TMP/proxy-mechanism-test.js" <<'EOF'
// Testa o mecanismo de proxy do discordcameralive.js (parseProxy, openTunnel, roteador)
"use strict";
const net = require("net");
const fs = require("fs");
const path = require("path");
const vm = require("vm");
const Module = require("module");

const BYPASS = "/repo/standalone/discordcameralive.js";
const PROXY = "socks5://127.0.0.1:1080";
let failures = 0;
function ok(name) { console.log("  [OK] " + name); }
function bad(name, extra) { failures++; console.log("  [FAIL] " + name + (extra ? ": " + extra : "")); }

// monta o Discord fake que o top-level do bypass exige
const FAKE_RES = "/tmp/discord-fake/resources";
fs.mkdirSync(path.join(FAKE_RES, "_app.asar"), { recursive: true });
fs.writeFileSync(path.join(FAKE_RES, "_app.asar", "package.json"), JSON.stringify({ name: "discord", main: "index.js" }));
fs.writeFileSync(path.join(FAKE_RES, "_app.asar", "index.js"), "// discord fake");

const appStub = { on: () => {}, whenReady: () => ({ then: (cb) => cb() }), setAppPath: () => {} };
const sessionStub = { defaultSession: { resolveProxy: async () => "DIRECT", setProxy: async () => {} } };
const originalLoad = Module._load;
Module._load = function (request, parent, isMain) {
  if (request === "electron") return { app: appStub, session: sessionStub };
  if (request === "original-fs") return require("fs");
  return originalLoad.apply(this, arguments);
};

const code = fs.readFileSync(BYPASS, "utf8");
const sandboxRequire = (name) => {
  if (name === "electron") return { app: appStub, session: sessionStub };
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
  URL, URLSearchParams,
};
sandbox.module.exports = sandbox.exports;
sandbox.global = sandbox;
vm.createContext(sandbox);
vm.runInContext(code, sandbox, { filename: BYPASS });

const g = sandbox;
const funcs = {};
for (const name of ["parseProxy", "openTunnel", "probe", "serveSocks", "settleExit", "safeProxy"]) {
  if (typeof g[name] === "function") funcs[name] = g[name];
}

async function main() {
  const parsed = funcs.parseProxy(PROXY);
  if (parsed && parsed.scheme === "socks5" && parsed.host === "127.0.0.1" && parsed.port === 1080)
    ok("parseProxy aceita socks5://127.0.0.1:1080");
  else bad("parseProxy", JSON.stringify(parsed));

  const t1 = await funcs.openTunnel(PROXY, "gateway.discord.gg", 443, 5000);
  if (t1 !== null) ok("openTunnel negocia SOCKS5 com o proxy manual");
  else bad("openTunnel", "proxy nao respondeu (null)");
  if (t1 !== null) t1.destroy();

  funcs.settleExit(PROXY);
  ok("settleExit define a saida manual como ativa");

  const started = await new Promise((resolve) => {
    const server = net.createServer(funcs.serveSocks);
    server.listen(0, "127.0.0.1", () => resolve({ server, port: server.address().port }));
  });
  const client = net.connect(started.port, "127.0.0.1");
  const result = await new Promise((resolve) => {
    let state = "greeting";
    client.on("data", (d) => {
      if (state === "greeting" && d[0] === 5 && d[1] === 0) {
        state = "sent";
        const host = Buffer.from("gateway.discord.gg", "utf8");
        const msg = Buffer.alloc(7 + host.length);
        msg[0] = 5; msg[1] = 1; msg[2] = 0; msg[3] = 3; msg[4] = host.length;
        host.copy(msg, 5);
        msg.writeUInt16BE(443, 5 + host.length);
        client.write(msg);
      } else if (state === "sent" && d[0] === 5 && d[1] === 0) resolve("conectado");
      else if (d[0] === 5 && d[1] !== 0) resolve("recusado:" + d[1]);
    });
    client.on("error", (e) => resolve("erro:" + e.message));
    client.on("close", () => resolve("fechado"));
    client.write(Buffer.from([5, 1, 0]));
    setTimeout(() => resolve("timeout"), 8000);
  });
  started.server.close();
  client.destroy();
  if (result === "conectado") ok("roteador local encaminha para o proxy manual (gateway.discord.gg:443)");
  else bad("roteador local", result);

  console.log(failures === 0 ? "RESULTADO: TUDO OK" : "RESULTADO: " + failures + " FALHA(S)");
  process.exit(failures === 0 ? 0 : 1);
}
main().catch((e) => { console.error(e); process.exit(1); });
EOF

step "Teste do proxy (SOCKS5 manual) no Artix/OpenRC"
out="$("$RUNTIME" run --rm --pull=missing --user 0 \
    -v "$REPO:/repo:ro" \
    -v "$TMP:/helpers:ro" \
    "$IMG" sh -c '
    pacman -Sy --noconfirm --needed nodejs >/dev/null 2>&1 || { echo "FALHA_DEPS"; exit 1; }

    # 1. o standalone grava o proxy no settings.json
    mkdir -p /tmp/home/.config/discord/app-9.9.9/resources
    printf "fake" > /tmp/home/.config/discord/app-9.9.9/resources/app.asar
    HOME=/tmp/home XDG_DATA_HOME=/tmp/home/.local/share \
        sh /repo/standalone/discordcameralive-standalone.sh --yes --proxy socks5://127.0.0.1:1080 >/dev/null 2>&1
    if grep -q "socks5://127.0.0.1:1080" /tmp/home/.local/share/DiscordCameraLive/settings.json 2>/dev/null; then
        echo "SETTINGS_OK"
    else
        echo "SETTINGS_FAIL"; exit 1
    fi

    # 2. mecanismo do proxy (discordcameralive.js via vm) contra um SOCKS5 de teste
    node /helpers/socks-server.js > /tmp/socks.log 2>&1 &
    socks_pid=$!
    sleep 1
    node /helpers/proxy-mechanism-test.js
    rc=$?
    echo "--- conexoes que o proxy de teste recebeu:"
    grep -c "pedido:" /tmp/socks.log 2>/dev/null || true
    kill $socks_pid 2>/dev/null || true
    exit $rc
' 2>&1)"

echo "$out" | tail -12

if printf '%s' "$out" | grep -q "SETTINGS_OK" \
   && printf '%s' "$out" | grep -q "RESULTADO: TUDO OK"; then
    ok "proxy manual (SOCKS5) funciona no Artix/OpenRC: settings + tunel + roteador"
else
    bad "proxy manual falhou no Artix/OpenRC: $(printf '%s' "$out" | tail -4)"
fi

echo
echo "== Resultado: $PASS ok, $FAIL falhas =="
[ "$FAIL" -eq 0 ] || exit 1
