#!/bin/sh
#
# Teste ponta a ponta da GUI (AppImage) em container OpenRC (Artix Linux)
#
# Reproduz o bug Wayland+Vulkan do Electron 43: no Wayland o Chromium tenta
# inicializar Vulkan e o processo GPU cai com
#   "wayland_surface_factory.cc: '--ozone-platform=wayland' is not compatible with Vulkan"
# deixando a janela presa em "Verificando..." (o getStatus via IPC nunca responde).
#
# A correcao (electron/main.ts) desliga a aceleracao de hardware no Linux
# (app.disableHardwareAcceleration + --disable-gpu). Este teste valida:
#   1. o binario sobe no Wayland com Vulkan forcado SEM o erro de incompatibilidade
#   2. os processos (GPU + renderer) ficam vivos -> a janela carrega
#
# Uso:
#   ./tests/test-artix-gui.sh            # roda o teste completo
#   RUNTIME=docker ./tests/test-artix-gui.sh
#
# Requer podman ou docker (rootless OK) e o AppImage ja construido:
#   cd xx7rg && npm run build:linux

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

APPIMAGE="$REPO/xx7rg/dist-app/DiscordCameraLive.AppImage"
[ -f "$APPIMAGE" ] || {
    echo "AppImage nao encontrado. Rode 'cd xx7rg && npm run build:linux' primeiro." >&2
    exit 1
}

step() { printf '\n== %s ==\n' "$1"; }
ok()   { PASS=$((PASS + 1)); printf '  [OK] %s\n' "$1"; }
bad()  { FAIL=$((FAIL + 1)); printf '  [FAIL] %s\n' "$1"; }

step "Teste ponta a ponta: Artix (OpenRC) + weston headless + Wayland/Vulkan"
out="$("$RUNTIME" run --rm --pull=missing --user 0 \
    -v "$REPO:/repo:ro" \
    -e WAYLAND_DISPLAY=wayland-0 \
    -e XDG_RUNTIME_DIR=/tmp/home/.xdg \
    -e HOME=/tmp/home \
    -e DISPLAY= \
    "$IMG" sh -c '
    set -e
    # 1. deps GUI + weston (compositor wayland headless) + vulkan
    pacman -Sy --noconfirm --needed \
        nss atk gtk3 alsa-lib \
        libx11 libxcb libxkbcommon libxrandr libxcomposite libxdamage libxfixes \
        libxext libxi libxtst libgl libdrm mesa libxss libxinerama libxcursor \
        weston vulkan-icd-loader vulkan-mesa-layers \
        >/dev/null 2>&1 || { echo "FALHA_DEPS"; exit 1; }

    # 2. extrair o AppImage (sem FUSE -> --appimage-extract-and-run)
    mkdir -p /tmp/home/.xdg /tmp/app
    cp /repo/xx7rg/dist-app/DiscordCameraLive.AppImage /tmp/app/
    chmod +x /tmp/app/DiscordCameraLive.AppImage

    # 3. subir weston headless no socket wayland-0
    export HOME=/tmp/home XDG_RUNTIME_DIR=/tmp/home/.xdg
    chmod 700 /tmp/home/.xdg
    weston --backend=headless-backend.so --socket=wayland-0 --idle-time=0 > /tmp/weston.log 2>&1 &
    wpid=$!
    sleep 3
    [ -S /tmp/home/.xdg/wayland-0 ] || { echo "FALHA_WESTON"; cat /tmp/weston.log; exit 1; }

    # 4. rodar o AppImage com Wayland + Vulkan forcado (o cenario do bug)
    cd /tmp/app
    timeout 30 ./DiscordCameraLive.AppImage --appimage-extract-and-run --no-sandbox \
        --ozone-platform=wayland --enable-features=Vulkan --disable-dev-shm-usage \
        > /tmp/app.log 2>&1 &
    pid=$!
    sleep 15
    # 5. processos vivos? (GPU + renderer = janela carregou)
    procs="$(ps -ef | grep -c "[g]olive-gui" || true)"
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
    kill "$wpid" 2>/dev/null || true

    # 6. resultado
    vulkan_err="$(grep -c "not compatible with Vulkan" /tmp/app.log 2>/dev/null || true)"
    gpu_crash="$(grep -c "Failed to create and initialize" /tmp/app.log 2>/dev/null || true)"
    echo "PROCS=$procs VULKAN_ERR=$vulkan_err GPU_CRASH=$gpu_crash"
    grep -iE "vulkan|not compatible" /tmp/app.log | head -3 || true
' 2>&1)"

echo "$out" | tail -5

# Validacao: nenhum erro Vulkan, nenhum crash de GPU e processos vivos
if printf '%s' "$out" | grep -q "VULKAN_ERR=0" \
   && printf '%s' "$out" | grep -q "GPU_CRASH=0" \
   && printf '%s' "$out" | grep -q "PROCS=[1-9]"; then
    ok "AppImage roda no Wayland+Vulkan sem erro (Artix/OpenRC)"
else
    bad "AppImage ainda falha no Wayland+Vulkan: $(printf '%s' "$out" | tail -3)"
fi

echo
echo "== Resultado: $PASS ok, $FAIL falhas =="
[ "$FAIL" -eq 0 ] || exit 1
