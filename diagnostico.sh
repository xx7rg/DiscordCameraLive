#!/bin/sh
#
# Diagnostico do DiscordCameraLive para Linux
#
# Coleta tudo o que ajuda a achar por que o bypass falhou: ambiente (distro,
# desktop, sessao, init), flatpak (versao, permissoes, overrides), TODOS os
# Discords instalados (nativo + flatpak + canary/ptb), a pasta do bypass com
# os logs e a configuracao (com a senha do proxy mascarada), processos e um
# teste de saida de rede.
#
# Uso:
#   sh diagnostico.sh
#
# A saida vai para a tela e tambem para ~/discordcameralive-diagnostico-<data>.txt
# — anexe esse arquivo (ou cole a saida) no relato do problema.

OUT="$HOME/discordcameralive-diagnostico-$(date +%Y%m%d-%H%M%S).txt"
mkdir -p "$HOME" 2>/dev/null || true

{
# ------------------------------------------------------------------ cabecalho
echo "================================================================"
echo " DiscordCameraLive - diagnostico"
echo " gerado em: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo " maquina:   $(hostname 2>/dev/null || echo '?')"
echo " usuario:   $(id -un 2>/dev/null) (uid=$(id -u 2>/dev/null))"
echo "================================================================"

secao() { echo; echo "===== $1 ====="; }

# ------------------------------------------------------------ 1. sistema
secao "1. Sistema"
if [ -r /etc/os-release ]; then
    sed -n 's/^\(PRETTY_NAME\|VERSION_ID\|ID\)=/\1=/p' /etc/os-release | tr -d '"'
else
    echo "sem /etc/os-release"
fi
uname -a 2>/dev/null
echo "desktop:  ${XDG_CURRENT_DESKTOP:-nao definido}"
echo "sessao:   ${XDG_SESSION_TYPE:-nao definido} (WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-vazio}, DISPLAY=${DISPLAY:-vazio})"
echo "init (pid 1): $(ps -p 1 -o comm= 2>/dev/null || echo '?')"
if command -v systemctl >/dev/null 2>&1; then
    echo "systemd:  presente (systemctl)"
elif command -v rc-service >/dev/null 2>&1; then
    echo "openrc:   presente (rc-service)"
fi

# ------------------------------------------------------------ 2. ferramentas
secao "2. Ferramentas disponiveis"
for cmd in sudo pkexec flatpak curl sh dash bash; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "$cmd: $(command -v "$cmd")"
    else
        echo "$cmd: AUSENTE"
    fi
done
if command -v sudo >/dev/null 2>&1; then
    if sudo -n true 2>/dev/null; then
        echo "sudo: NOPASSWD funcionando"
    else
        echo "sudo: presente, mas PEDE SENHA (falha sem TTY/sem senha)"
    fi
fi

# ------------------------------------------------------------ 3. flatpak
secao "3. Flatpak"
if command -v flatpak >/dev/null 2>&1; then
    flatpak --version 2>&1
    echo
    echo "--- apps do Discord instalados (flatpak list):"
    flatpak list --app 2>/dev/null | grep -i discord || echo "(nenhum discord flatpak na lista)"
    echo
    for id in com.discordapp.Discord com.discordapp.DiscordPTB com.discordapp.DiscordCanary; do
        if flatpak info "$id" >/dev/null 2>&1 || flatpak info --user "$id" >/dev/null 2>&1; then
            echo "### $id"
            if flatpak info --user "$id" >/dev/null 2>&1; then
                echo "  instalacao: USUARIO (--user)"
            else
                echo "  instalacao: SISTEMA"
            fi
            echo "  --- show-permissions (filesystems):"
            flatpak info --show-permissions "$id" 2>&1 | sed -n 's/^filesystems=//p' | tr ';' '\n' | sed 's/^/    /'
            echo "  --- override atual:"
            flatpak override --show "$id" 2>&1 | sed 's/^/    /'
            echo "  --- onde o app esta:"
            flatpak info --show-location "$id" 2>&1 | sed 's/^/    /'
        fi
    done
else
    echo "flatpak AUSENTE — o Discord por flatpak nao esta em uso"
fi

# ------------------------------------------------------------ 4. Discords instalados
secao "4. Discords instalados (todos os lugares possiveis)"
found=0
check_resources() {
    # $1 = caminho de resources
    [ -d "$1" ] || return
    found=$((found + 1))
    echo
    echo "### $1"
    if [ -f "$1/_app.asar" ]; then
        echo "  _app.asar: EXISTE (original guardado por alguem)"
        if [ -f "$1/app.asar/index.js" ] && grep -q "discordcameralive" "$1/app.asar/index.js" 2>/dev/null; then
            echo "  injecao:   NOSSA (DiscordCameraLive)"
        else
            echo "  injecao:   OUTRO MOD (app.asar e pasta, index.js sem discordcameralive)"
        fi
    elif [ -f "$1/app.asar" ] && [ ! -d "$1/app.asar" ]; then
        echo "  injecao:   VANILLA (app.asar original)"
    elif [ -d "$1/app.asar" ]; then
        echo "  injecao:   PASTA app.asar sem _app.asar (mod ativo)"
    else
        echo "  sem app.asar/_app.asar"
    fi
    ls -la "$1/app.asar" "$1/_app.asar" 2>/dev/null | sed 's/^/  /'
    echo "  settings.json local: $([ -f "$1/settings.json" ] && echo EXISTE || echo nao)"
    [ -f "$1/settings.json" ] && sed 's/^/    /' "$1/settings.json"
}

base="${XDG_CONFIG_HOME:-$HOME/.config}"
# bootstrap novo do Discord (app baixado no HOME)
for sub in "$base"/discord/app-*/resources "$base"/discordptb/app-*/resources "$base"/discordcanary/app-*/resources; do
    check_resources "$sub"
done
# instalacoes classicas
for raiz in \
    /usr/share/discord /usr/share/discord-ptb /usr/share/discord-canary \
    /usr/lib/discord /usr/lib/discord-ptb /usr/lib/discord-canary /usr/lib64/discord \
    /opt/discord /opt/Discord /opt/discord-ptb /opt/discord-canary \
    /usr/local/share/discord \
    "$HOME/.local/share/discord" "$HOME/Discord" "$HOME/discord"
do
    [ -d "$raiz" ] || continue
    check_resources "$raiz/resources"
    check_resources "$raiz"
done
# flatpak (sistema e usuario)
for raiz in /var/lib/flatpak/app "${XDG_DATA_HOME:-$HOME/.local/share}/flatpak/app"; do
    [ -d "$raiz" ] || continue
    for sub in "$raiz"/com.discordapp.*/current/active/files/*/resources; do
        check_resources "$sub"
    done
done
# flatpak do usuario (HOME do discord sandbox)
for id in com.discordapp.Discord com.discordapp.DiscordPTB com.discordapp.DiscordCanary; do
    for sub in "$HOME/.var/app/$id"/config/discord*/app-*/resources; do
        check_resources "$sub"
    done
done

if [ "$found" -eq 0 ]; then
    echo "NENHUM Discord encontrado em lugar nenhum!"
elif [ "$found" -gt 1 ]; then
    echo
    echo ">>> ATENCAO: $found instalacoes de Discord encontradas — pode haver conflito."
fi

# ------------------------------------------------------------ 5. pasta do bypass
INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/DiscordCameraLive"
secao "5. Pasta do bypass: $INSTALL_DIR"
if [ -d "$INSTALL_DIR" ]; then
    echo "--- conteudo:"
    ls -la "$INSTALL_DIR" 2>/dev/null | sed 's/^/  /'
    echo
    echo "--- settings.json (senha do proxy mascarada):"
    if [ -f "$INSTALL_DIR/settings.json" ]; then
        # mascara user:senha@ -> user:***@ para nunca vazar credencial
        sed -E 's#(://[^:/@]+:)[^@]*@#\1***@#g' "$INSTALL_DIR/settings.json" 2>/dev/null | sed 's/^/  /'
        echo "  (permissao: $(stat -c '%a' "$INSTALL_DIR/settings.json" 2>/dev/null || echo '?'))"
    else
        echo "  NAO EXISTE"
    fi
    echo
    echo "--- state.json (saida guardada, sem proxy):"
    if [ -f "$INSTALL_DIR/state.json" ]; then
        cat "$INSTALL_DIR/state.json" 2>/dev/null | sed 's/^/  /'
    else
        echo "  NAO EXISTE"
    fi
    echo
    echo "--- discordcameralive.log (ultimas 120 linhas):"
    if [ -f "$INSTALL_DIR/discordcameralive.log" ]; then
        echo "  (tamanho: $(stat -c '%s' "$INSTALL_DIR/discordcameralive.log" 2>/dev/null) bytes, modificado: $(stat -c '%y' "$INSTALL_DIR/discordcameralive.log" 2>/dev/null | cut -d. -f1))"
        echo "  ------------------------------------------------------------"
        tail -120 "$INSTALL_DIR/discordcameralive.log" 2>/dev/null | sed 's/^/  /'
        echo "  ------------------------------------------------------------"
    else
        echo "  NAO EXISTE — o bypass nunca rodou, ou o log esta em outro lugar"
    fi
else
    echo "NAO EXISTE — o bypass nunca foi ativado por este usuario"
fi

# ------------------------------------------------------------ 6. processos
secao "6. Processos do Discord"
ps -eo pid,comm,args 2>/dev/null | grep -iE "discord|golive" | grep -v grep | sed 's/^/  /' || echo "  nenhum processo Discord rodando"
if command -v flatpak >/dev/null 2>&1; then
    echo "--- flatpak ps:"
    flatpak ps --columns=application,pid 2>/dev/null | grep -i discord | sed 's/^/  /' || echo "  nenhum flatpak Discord rodando"
fi

# ------------------------------------------------------------ 7. autostart
secao "7. Autostart (iniciar com o sistema)"
if [ -f "$HOME/.config/autostart/discordcameralive.desktop" ]; then
    echo "EXISTE:"
    cat "$HOME/.config/autostart/discordcameralive.desktop" 2>/dev/null | sed 's/^/  /'
else
    echo "nao configurado"
fi

# ------------------------------------------------------------ 8. rede
secao "8. Saida de rede (para saber se o trafego sai do Brasil)"
if command -v curl >/dev/null 2>&1; then
    echo "--- cloudflare trace (mostra o pais de saida, loc=):"
    curl -s --max-time 10 https://cloudflare.com/cdn-cgi/trace 2>&1 | grep -E "^(ip|loc|colo)=" | sed 's/^/  /' || echo "  falhou ao consultar cloudflare"
    echo "--- gateway do discord responde? (sem proxy):"
    curl -s -o /dev/null -w "  http_code=%{http_code} tempo=%{time_total}s\n" --max-time 10 https://gateway.discord.gg 2>&1 || echo "  falhou"
else
    echo "curl ausente — nao da para testar a rede"
fi

# ------------------------------------------------------------ 9. como rodar a GUI com log
secao "9. Para capturar o erro da GUI no terminal"
echo "  Rode o AppImage pelo terminal (extrai sem FUSE, como o README manda):"
echo
echo "    ./DiscordCameraLive.AppImage --appimage-extract-and-run 2>&1 | tee gui.log"
echo
echo "  O stderr da GUI (Electron) vai para o terminal — inclusive o erro de"
echo "  ativacao que aparece so no popup. Cole o gui.log junto com este arquivo."

echo
echo "================================================================"
echo " Fim do diagnostico."
echo " Arquivo salvo em: $OUT"
echo "================================================================"
} 2>&1 | tee "$OUT"

echo
echo "Envie o arquivo abaixo (ou cole a saida) no relato do problema:"
echo "  $OUT"
