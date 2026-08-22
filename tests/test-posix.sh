#!/bin/sh
#
# Suite de testes POSIX do DiscordCameraLive (instalador + standalone)
#
# Roda em containers (podman ou docker) com varios shells e distros, validando:
#   1. sintaxe (sh -n) em sh, dash, bash, zsh, ash, ksh, mksh
#   2. --help
#   3. --status do standalone com Discord simulado
#   4. ciclo completo install -> uninstall do standalone
#   5. funcoes puras (flatpak_app_id, injected_path, install_location)
#
# Uso:
#   ./tests/test-posix.sh            # roda tudo
#   ./tests/test-posix.sh --quick    # so sintaxe + help

set -eu

REPO="$(cd -- "$(dirname -- "$0")/.." && pwd)"
PASS=0
FAIL=0

# Escolhe podman ou docker
if command -v podman >/dev/null 2>&1; then
    RUNTIME=podman
elif command -v docker >/dev/null 2>&1; then
    RUNTIME=docker
else
    echo "Preciso do podman ou do docker para rodar os testes." >&2
    exit 1
fi
echo "== Runtime: $RUNTIME =="

step() { printf '  [*] %s\n' "$1" >&2; }
ok()   { PASS=$((PASS + 1)); printf '  [OK] %s\n' "$1" >&2; }
bad()  { FAIL=$((FAIL + 1)); printf '  [FAIL] %s\n' "$1" >&2; }

run_container() {
    # $1=imagem  resto=comando
    img="$1"; shift
    "$RUNTIME" run --rm -v "$REPO:/repo:ro" "$img" "$@"
}

run_container_home() {
    # $1=imagem  $2=home_host  resto=comando
    img="$1"; home="$2"; shift 2
    "$RUNTIME" run --rm \
        -v "$REPO:/repo:ro" \
        -v "$home:/home/testuser" \
        -e HOME=/home/testuser \
        -e XDG_DATA_HOME=/home/testuser/.local/share \
        "$img" "$@"
}

make_fake_home() {
    # $1=destino
    rm -rf "$1"
    mkdir -p "$1/.config/discord/app-9.9.9/resources"
    printf 'fake app.asar' > "$1/.config/discord/app-9.9.9/resources/app.asar"
}

# --------------------------------------------------------------------------- sintaxe
echo
echo "== 1. Sintaxe (sh -n) =="
for img in debian:stable-slim alpine:latest fedora:latest ubuntu:latest; do
    step "pull $img"
    run_container "$img" sh -c "command -v \$SHELL || true" >/dev/null 2>&1 || true
done

# dash (debian), ash (alpine/busybox), bash (fedora)
for spec in \
    "debian:stable-slim sh" \
    "debian:stable-slim dash" \
    "alpine:latest ash" \
    "alpine:latest sh" \
    "fedora:latest bash" \
    "ubuntu:latest dash"
do
    set -- $spec
    img="$1"; shell="$2"
    for script in installer/discordcameralive-installer.sh standalone/discordcameralive-standalone.sh; do
        if run_container "$img" "$shell" -n "/repo/$script" >/dev/null 2>&1; then
            ok "sintaxe $shell $script ($img)"
        else
            bad "sintaxe $shell $script ($img)"
        fi
    done
done

# --------------------------------------------------------------------------- --help
echo
echo "== 2. --help =="
for spec in \
    "debian:stable-slim sh" \
    "alpine:latest ash" \
    "fedora:latest bash" \
    "ubuntu:latest dash"
do
    set -- $spec
    img="$1"; shell="$2"
    for script in installer/discordcameralive-installer.sh standalone/discordcameralive-standalone.sh; do
        out="$(run_container "$img" "$shell" "/repo/$script" --help 2>&1 || true)"
        if printf '%s' "$out" | grep -q 'DiscordCameraLive'; then
            ok "--help $shell $script ($img)"
        else
            bad "--help $shell $script ($img)"
        fi
    done
done

# --------------------------------------------------------------------------- status
echo
echo "== 3. status (Discord simulado) =="
FAKE_HOME="$(mktemp -d)"
make_fake_home "$FAKE_HOME"
for spec in \
    "debian:stable-slim sh" \
    "alpine:latest ash" \
    "fedora:latest bash" \
    "ubuntu:latest dash"
do
    set -- $spec
    img="$1"; shell="$2"
    out="$(run_container_home "$img" "$FAKE_HOME" "$shell" /repo/standalone/discordcameralive-standalone.sh --status 2>&1 || true)"
    if printf '%s' "$out" | grep -q 'sem nada instalado'; then
        ok "status $shell ($img)"
    else
        bad "status $shell ($img): $out"
    fi
done

# --------------------------------------------------------------------------- install/uninstall
echo
echo "== 4. ciclo install -> uninstall (standalone) =="
for spec in \
    "debian:stable-slim sh" \
    "alpine:latest ash" \
    "fedora:latest bash" \
    "ubuntu:latest dash"
do
    set -- $spec
    img="$1"; shell="$2"
    home="$(mktemp -d)"
    make_fake_home "$home"
    if run_container_home "$img" "$home" "$shell" /repo/standalone/discordcameralive-standalone.sh --yes >/dev/null 2>&1; then
        if [ -f "$home/.config/discord/app-9.9.9/resources/_app.asar" ] \
           && [ -f "$home/.config/discord/app-9.9.9/resources/app.asar/index.js" ] \
           && run_container_home "$img" "$home" "$shell" /repo/standalone/discordcameralive-standalone.sh --uninstall >/dev/null 2>&1 \
           && [ -f "$home/.config/discord/app-9.9.9/resources/app.asar" ] \
           && [ ! -e "$home/.config/discord/app-9.9.9/resources/_app.asar" ]; then
            ok "ciclo $shell ($img)"
        else
            bad "ciclo $shell ($img)"
        fi
    else
        bad "install $shell ($img)"
    fi
    # O container (root) grava no home fake; limpar dentro de um container root.
    "$RUNTIME" run --rm -u root -v "$home:/h" debian:stable-slim rm -rf /h >/dev/null 2>&1 || chmod -R u+rwx "$home" 2>/dev/null || true
    rm -rf "$home" 2>/dev/null || true
done
rm -rf "$FAKE_HOME"

# --------------------------------------------------------------------------- funcoes puras
echo
echo "== 5. funcoes puras =="
HARNESS="$(mktemp)"
cat > "$HARNESS" <<'HARNESS_EOF'
. /repo/standalone/discordcameralive-standalone.sh >/dev/null 2>&1 || true
HARNESS_EOF
# O script executa no source; usar extração de funções seria frágil. Em vez disso,
# testar via execução real: flatpak_app_id é chamada de dentro do fluxo normal.
# Testar a validacao de proxy invalida (deve falhar com RC=1)
if run_container "debian:stable-slim" sh /repo/standalone/discordcameralive-standalone.sh --proxy "invalido" >/dev/null 2>&1; then
    bad "proxy invalido aceito"
else
    ok "proxy invalido rejeitado (RC!=0)"
fi

# elevate: sem sudo NOPASSWD, o pkexec (polkit) assume — o caso do Fedora KDE/GNOME
# onde o sudo falha sem TTY. Simula com um pkexec fake que registra a chamada.
ELEVATE_HOME="$(mktemp -d)"
mkdir -p "$ELEVATE_HOME/bin"
cat > "$ELEVATE_HOME/bin/pkexec" <<'PKEXEC_EOF'
#!/bin/sh
echo "PKEXEC:$*" >> /tmp/elevate-used
exec "$@"
PKEXEC_EOF
chmod +x "$ELEVATE_HOME/bin/pkexec"
# extrai so as funcoes have/elevate do script (ate o banner final) para nao rodar o fluxo
ELEVATE_HARNESS="$(mktemp)"
awk '/^aviso_empacotado$/{exit} {print}' "$REPO/standalone/discordcameralive-standalone.sh" > "$ELEVATE_HARNESS"
cat >> "$ELEVATE_HARNESS" <<'H_EOF'
elevate sh -c "echo elevado > /tmp/fakehome/ok"
[ -f /tmp/fakehome/ok ] && grep -q "PKEXEC:sh" /tmp/elevate-used
H_EOF
elevate_out="$("$RUNTIME" run --rm -u 1000:1000 \
    -v "$ELEVATE_HARNESS:/t.sh:ro" \
    -v "$ELEVATE_HOME/bin:/tmp/fakebin:ro" \
    -v "$ELEVATE_HOME:/tmp/fakehome" \
    fedora:latest sh -c '
    export PATH=/tmp/fakebin:$PATH
    sh /t.sh
' 2>&1)" && elevate_rc=0 || elevate_rc=$?
if [ "$elevate_rc" -eq 0 ]; then
    ok "elevate cai para pkexec sem sudo NOPASSWD (fedora)"
else
    bad "elevate nao usou pkexec sem sudo NOPASSWD: $elevate_out"
fi
rm -rf "$ELEVATE_HOME" "$ELEVATE_HARNESS"

rm -f "$HARNESS"

# --------------------------------------------------------------------------- shells extras (zsh/ksh/mksh)
echo
echo "== 6. shells extras (zsh, ksh, mksh) =="
# zsh no ubuntu, ksh/mksh no debian — instalamos dentro do container
for spec in \
    "ubuntu:latest zsh" \
    "debian:stable-slim ksh" \
    "debian:stable-slim mksh"
do
    set -- $spec
    img="$1"; shell="$2"
    setup="apt-get update -qq >/dev/null 2>&1; apt-get install -y -qq $shell >/dev/null 2>&1; "
    for script in installer/discordcameralive-installer.sh standalone/discordcameralive-standalone.sh; do
        # sintaxe
        if "$RUNTIME" run --rm -u root -v "$REPO:/repo:ro" "$img" sh -c "$setup $shell -n /repo/$script" >/dev/null 2>&1; then
            ok "sintaxe $shell $script ($img)"
        else
            bad "sintaxe $shell $script ($img)"
        fi
        # help
        out="$("$RUNTIME" run --rm -u root -v "$REPO:/repo:ro" "$img" sh -c "$setup $shell /repo/$script --help" 2>&1 || true)"
        if printf '%s' "$out" | grep -q 'DiscordCameraLive'; then
            ok "--help $shell $script ($img)"
        else
            bad "--help $shell $script ($img)"
        fi
    done

    # ciclo standalone (install -> uninstall) no shell extra
    home="$(mktemp -d)"
    make_fake_home "$home"
    if "$RUNTIME" run --rm -u root \
        -v "$REPO:/repo:ro" \
        -v "$home:/home/testuser" \
        -e HOME=/home/testuser \
        -e XDG_DATA_HOME=/home/testuser/.local/share \
        "$img" sh -c "$setup $shell /repo/standalone/discordcameralive-standalone.sh --yes" >/dev/null 2>&1 \
        && [ -f "$home/.config/discord/app-9.9.9/resources/_app.asar" ] \
        && "$RUNTIME" run --rm -u root \
            -v "$REPO:/repo:ro" \
            -v "$home:/home/testuser" \
            -e HOME=/home/testuser \
            -e XDG_DATA_HOME=/home/testuser/.local/share \
            "$img" sh -c "$setup $shell /repo/standalone/discordcameralive-standalone.sh --uninstall" >/dev/null 2>&1 \
        && [ ! -e "$home/.config/discord/app-9.9.9/resources/_app.asar" ]; then
        ok "ciclo $shell ($img)"
    else
        bad "ciclo $shell ($img)"
    fi
    # O container (root) grava no home fake; limpar dentro de um container root.
    "$RUNTIME" run --rm -u root -v "$home:/h" debian:stable-slim rm -rf /h >/dev/null 2>&1 || chmod -R u+rwx "$home" 2>/dev/null || true
    rm -rf "$home" 2>/dev/null || true
done

# --------------------------------------------------------------------------- cenarios especiais
echo
echo "== 7. cenarios especiais =="

# 7a. substituicao de outro mod (Equicord stub) com --yes
home="$(mktemp -d)"
# stub do Equicord de verdade: _app.asar (original renomeado) + pasta app.asar com require
mkdir -p "$home/.config/discord/app-9.9.9/resources"
printf 'original asar' > "$home/.config/discord/app-9.9.9/resources/_app.asar"
mkdir -p "$home/.config/discord/app-9.9.9/resources/app.asar"
printf '{"name":"discord","main":"index.js"}' > "$home/.config/discord/app-9.9.9/resources/app.asar/package.json"
printf 'require("/home/user/Equicord/dist/desktop");' > "$home/.config/discord/app-9.9.9/resources/app.asar/index.js"
if run_container_home "debian:stable-slim" "$home" sh /repo/standalone/discordcameralive-standalone.sh --yes >/dev/null 2>&1 \
    && [ -f "$home/.config/discord/app-9.9.9/resources/_app.asar" ]; then
    ok "substituicao de outro mod (debian sh)"
else
    bad "substituicao de outro mod (debian sh)"
fi
"$RUNTIME" run --rm -u root -v "$home:/h" debian:stable-slim rm -rf /h >/dev/null 2>&1 || true
rm -rf "$home" 2>/dev/null || true

# 7b. flatpak do sistema
fp_root="$(mktemp -d)"
mkdir -p "$fp_root/var/lib/flatpak/app/com.discordapp.Discord/current/active/files/discord/resources"
printf 'fake' > "$fp_root/var/lib/flatpak/app/com.discordapp.Discord/current/active/files/discord/resources/app.asar"
home="$(mktemp -d)"
if "$RUNTIME" run --rm -u root \
        -v "$REPO:/repo:ro" \
        -v "$home:/home/testuser" \
        -v "$fp_root/var/lib/flatpak:/var/lib/flatpak" \
        -e HOME=/home/testuser \
        -e XDG_DATA_HOME=/home/testuser/.local/share \
        debian:stable-slim sh /repo/standalone/discordcameralive-standalone.sh --yes >/dev/null 2>&1 \
    && [ -f "$fp_root/var/lib/flatpak/app/com.discordapp.Discord/current/active/files/discord/resources/_app.asar" ]; then
    ok "instalacao em flatpak do sistema (debian sh)"
else
    bad "instalacao em flatpak do sistema (debian sh)"
fi
"$RUNTIME" run --rm -u root -v "$fp_root:/h" debian:stable-slim rm -rf /h >/dev/null 2>&1 || true
rm -rf "$fp_root" "$home" 2>/dev/null || true

# 7c. --status --json (saida maquina para a GUI)
home="$(mktemp -d)"
mkdir -p "$home/.config/discord/app-9.9.9/resources"
printf 'fake' > "$home/.config/discord/app-9.9.9/resources/app.asar"
out="$(run_container_home "debian:stable-slim" "$home" sh /repo/standalone/discordcameralive-standalone.sh --status --json 2>/dev/null)"
if printf '%s' "$out" | grep -q '"state":"vanilla"'; then
    ok "status --json (debian sh)"
else
    bad "status --json (debian sh): $out"
fi
"$RUNTIME" run --rm -u root -v "$home:/h" debian:stable-slim rm -rf /h >/dev/null 2>&1 || true
rm -rf "$home" 2>/dev/null || true

# 7d. modo portatil: install reabre o Discord, uninstall reabre limpo
home="$(mktemp -d)"
mkdir -p "$home/.config/discord/app-9.9.9/resources" "$home/bin"
printf 'fake' > "$home/.config/discord/app-9.9.9/resources/app.asar"
printf '#!/bin/sh\necho DISCORD_ABERTO >> /tmp/calls\n' > "$home/bin/discord"
chmod +x "$home/bin/discord"
out="$("$RUNTIME" run --rm -u root \
    -v "$REPO:/repo:ro" \
    -v "$home:/home/testuser" \
    -v "$home/bin:/usr/local/bin" \
    -e HOME=/home/testuser \
    -e XDG_DATA_HOME=/home/testuser/.local/share \
    -e PATH=/usr/local/bin:/usr/bin:/bin \
    debian:stable-slim sh -c 'sh /repo/standalone/discordcameralive-standalone.sh --yes >/dev/null 2>&1; sleep 1; echo "I=$(cat /tmp/calls 2>/dev/null | wc -l)"; sh /repo/standalone/discordcameralive-standalone.sh --uninstall >/dev/null 2>&1; sleep 1; echo "U=$(cat /tmp/calls 2>/dev/null | wc -l)"' 2>&1)"
i="$(printf '%s' "$out" | sed -n 's/^I=//p')"
u="$(printf '%s' "$out" | sed -n 's/^U=//p')"
if [ "${i:-0}" -ge 1 ] && [ "${u:-0}" -ge 2 ]; then
    ok "modo portatil reabre Discord (install + uninstall)"
else
    bad "modo portatil reabre Discord (install=$i uninstall=$u)"
fi
"$RUNTIME" run --rm -u root -v "$home:/h" debian:stable-slim rm -rf /h >/dev/null 2>&1 || true
rm -rf "$home" 2>/dev/null || true

# --------------------------------------------------------------------------- instalador: descoberta de checkout
echo
echo "== 8. instalador: descoberta de checkout (bug dos here-docs) =="
# Simula um Discord injetado apontando para um checkout do Equicord e confere se o
# instalador encontra sozinho. Este caso pegava o bug dos here-docs indentados, que
# engolia injected_path/installed_mod/checkout_from_injection/checkout_on_disk.
for spec in \
    "debian:stable-slim sh" \
    "alpine:latest ash" \
    "fedora:latest bash" \
    "ubuntu:latest dash"
do
    set -- $spec
    img="$1"; shell="$2"
    home="$(mktemp -d)"
    # checkout fake do Equicord
    mkdir -p "$home/Equicord/src/utils" "$home/Equicord/dist/desktop"
    printf '{"name":"Equicord","version":"1.0.0"}' > "$home/Equicord/package.json"
    printf 'export type x = 1;' > "$home/Equicord/src/utils/types.ts"
    # Discord injetado apontando para o checkout
    mkdir -p "$home/.config/discord/app-9.9.9/resources/app"
    printf 'require("/home/testuser/Equicord/dist/desktop");' > "$home/.config/discord/app-9.9.9/resources/app/index.js"
    printf 'original' > "$home/.config/discord/app-9.9.9/resources/_app.asar"

    HARNESS="$(mktemp)"
    # extrair as funcoes do instalador (ate o banner final) e rodar a descoberta
    awk '/^banner$/{exit} {print}' "$REPO/installer/discordcameralive-installer.sh" > "$HARNESS"
    cat >> "$HARNESS" <<'H_EOF'
p="$(injected_path /home/testuser/.config/discord/app-9.9.9/resources || echo NAO)"
[ "$p" = "/home/testuser/Equicord/dist/desktop" ] || exit 1
root="$(checkout_from_injection || true)"
[ "$root" = "/home/testuser/Equicord" ] || exit 1
mod="$(installed_mod || true)"
[ "$mod" = "Equicord" ] || exit 1
echo DESCOBERTA_OK
H_EOF

    if "$RUNTIME" run --rm \
            -v "$HARNESS:/t.sh:ro" \
            -v "$home:/home/testuser" \
            -e HOME=/home/testuser \
            -e XDG_DATA_HOME=/home/testuser/.local/share \
            "$img" "$shell" /t.sh 2>/dev/null | grep -q DESCOBERTA_OK; then
        ok "descoberta de checkout $shell ($img)"
    else
        bad "descoberta de checkout $shell ($img)"
    fi
    rm -f "$HARNESS"
    "$RUNTIME" run --rm -u root -v "$home:/h" debian:stable-slim rm -rf /h >/dev/null 2>&1 || true
    rm -rf "$home" 2>/dev/null || true
done

echo
echo "== Resultado: $PASS ok, $FAIL falhas =="
[ "$FAIL" -eq 0 ] || exit 1
