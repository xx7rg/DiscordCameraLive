# DiscordCameraLive — Bypass do Go Live no Discord (Brasil)

**Devolve o Go Live e a câmera para usuários brasileiros** no Discord para computador. Você não precisa entender de tecnologia para usar: o jeito mais fácil é o [aplicativo de um clique](#-novo-interface-gráfica-plug-and-play-windows-e-macos) logo abaixo.

Por dentro, só o WebSocket de gateway do Discord passa por uma proxy fora do Brasil — todo o resto sai direto, na sua velocidade normal. Os detalhes técnicos ficam [mais abaixo](#como-funciona).

> **English summary below / Resumo em inglês no final.**

## 🌟 NOVO: Interface Gráfica Plug and Play (Windows e macOS)

Criamos um aplicativo completo que faz todo o trabalho de forma **100% automática**, sem precisar abrir terminais, usar scripts ou instalar modificações complexas como o Equicord.

<p align="center">
  <img src="xx7rg/src/assets/hero-ui.png" alt="A interface do DiscordCameraLive: status do Discord, botao de ativar, tema claro e escuro e proxy customizada" width="420">
</p>

### Como Baixar e Instalar
1. Vá na **[última release](https://github.com/xx7rG/DiscordCameraLive/releases/latest)** aqui no GitHub.
2. Baixe o arquivo da sua plataforma, na lista no fim da página:
   - **Windows:** `DiscordCameraLive.exe` (portátil, roda direto sem instalar)
   - **macOS (Apple Silicon):** `DiscordCameraLive.dmg`, ou o `DiscordCameraLive.zip` se preferir
3. Abra o arquivo que você acabou de baixar.

O programa **não é assinado**. O sistema avisa na primeira vez. Se preferir não correr esse risco, use a [instalação por comando](#um-comando-só), que é o mesmo bypass sem executável.

**Windows (SmartScreen):** **Mais informações → Executar assim mesmo**.

#### macOS

Dois avisos do sistema, e nenhum dos dois é o DiscordCameraLive “quebrado”.

**1. Abrir o app (Gatekeeper).** Clique com o **botão direito** no DiscordCameraLive → **Abrir** → **Abrir**. Se o macOS só mostrar que não é possível abrir, vá em **Ajustes do Sistema → Privacidade e Segurança** e clique em **Abrir mesmo assim**.

**2. Deixar o app mexer no Discord (Administração de Apps).** Se você já usou o Vencord, sabe qual é essa tela: o macOS não deixa um programa alterar o `Discord.app` até você autorizar. É **a mesma permissão**. Na primeira vez que você clicar em Ativar, o sistema bloqueia a escrita; o DiscordCameraLive tenta abrir **Ajustes do Sistema → Privacidade e Segurança → Administração de Apps**. Ative o DiscordCameraLive (ou arraste o app para a lista) e clique em Ativar de novo.

**Depois de uma atualização do Discord.** No Mac o instalador troca o `.app` inteiro e a injeção some. Abra o DiscordCameraLive e ative de novo. (No Windows o standalone tenta adiantar isso sozinho; na GUI do Mac isso não existe.)

### Como Usar
1. O aplicativo vai detectar o seu Discord automaticamente (no Mac, em `/Applications` ou `~/Applications`, inclusive PTB e Canary).
2. Clique em **"Ativar Bypass"**.
3. O Discord vai reiniciar automaticamente com o Go Live desbloqueado!
4. Pode fechar a janela sem medo: o app fica na **bandeja** do Windows (junto do relógio) ou na **barra de menus** do Mac. Clique no ícone de lá para reabrir, ativar/desativar ou **Sair** — sair por esse ícone é o que reverte tudo ao normal.
5. Se quiser que ele já abra com o PC (direto escondido, sem janela pulando na tela), marque **"Iniciar com o Windows"** ou **"Iniciar com o Mac"** na janela ou no menu do ícone.

> **Dica Importante:** Se a sua transmissão ficar com a tela preta ou não carregar de primeira, recarregue o Discord: **Ctrl + R** no Windows, **Cmd + R** no Mac.


## 🐧 Interface Gráfica para Linux (AppImage)

A mesma interface gráfica do Windows, **agora para Linux**, empacotada como **AppImage** (roda em qualquer distro: Debian, Ubuntu, Fedora, Arch e derivadas).

Assim como a versão Windows, ela é **portátil**: ativa o DiscordCameraLive ao clicar e fica na **bandeja** do sistema — fechar a janela só a esconde, e o **Sair** pelo ícone da bandeja é o que reverte tudo ao normal. Por baixo, ela chama o [modo standalone](#modo-standalone-só-o-discord-sem-equicord-e-sem-vencord) (POSIX, funciona em qualquer shell), então toda a lógica de detecção — Discord nativo, flatpak, bootstrap novo, snap — é a mesma dos scripts, com o progresso aparecendo na tela.

### Como Baixar e Instalar
1. Vá na **[última release](https://github.com/xx7rG/DiscordCameraLive/releases/latest)**.
2. Baixe o **`DiscordCameraLive-*.AppImage`**.
3. Dê permissão de execução e abra:

```sh
chmod +x DiscordCameraLive-*.AppImage
./DiscordCameraLive-*.AppImage
```

> Se o seu sistema não tiver FUSE (alguns containers/WSL), use `--appimage-extract-and-run`:
> ```sh
> ./DiscordCameraLive-*.AppImage --appimage-extract-and-run
> ```

### Como Usar
1. O aplicativo detecta o seu Discord automaticamente (nativo ou flatpak).
2. Clique em **"Ativar Bypass"** — o Discord fecha, o bypass entra e ele reabre.
3. Fechar a janela só a esconde na bandeja (o app continua vivo); para reverter o bypass de verdade, use o **Sair** no menu do ícone da bandeja.

> **Nota:** se o seu Discord é flatpak do sistema, a primeira ativação pode pedir sua senha (via `pkexec`) para liberar a pasta do bypass para o sandbox.

---

---

## Índice

**Quero instalar agora**
- [**Interface Gráfica (Windows e macOS)**](#-novo-interface-gráfica-plug-and-play-windows-e-macos) — 1 clique para ativar/desativar, sem terminal
- [**Interface Gráfica (Linux, AppImage)**](#-interface-gráfica-para-linux-appimage) — 1 clique, portátil, em qualquer distro
- [**Um comando só**](#um-comando-só) — uma linha no PowerShell ou no terminal, sem baixar nada
- [Instalação automática](#instalação-automática-recomendado) — o instalador completo, com menu, para usar via plugin Equicord/Vencord
- [Modo Standalone (Scripts)](#modo-standalone-só-o-discord-sem-equicord-e-sem-vencord) — direto no Discord, sem mod e sem compilar nada
- [**Linux: Arch, Debian, Ubuntu, Fedora**](#linux-arch-debian-ubuntu-fedora) — onde o Discord fica em cada distro, e a pedra do Node no Debian

**Já instalei**
- [Uso](#uso) — o que fazer depois de instalar
- [Configuração](#configuração) — região da call, região da transmissão, roteamento, proxy
- [Solução de problemas](#solução-de-problemas) — Discord travado, transmissão que não sobe, plugin sumido
- [O registro](#o-registro-o-que-o-plugin-anotou) — o arquivo que conta o que aconteceu, para relatar um problema

**Quero entender ou fazer à mão**
- [Por que este plugin existe](#por-que-este-plugin-existe)
- [Go Live no Brasil: por que funciona](#go-live-no-brasil-por-que-funciona)
- [Avisos importantes](#avisos-importantes) — o que o plugin faz com a sua conexão, e os riscos
- [Como funciona](#como-funciona) — as duas travas e como cada uma é desarmada
- [Instalação manual, passo a passo](#instalação-passo-a-passo-completo) — cada etapa à mão
- [Instalação no Vesktop](#instalação-no-vesktop) — passo a passo para quem usa o Vesktop no lugar do Discord normal
- [Dependências](#dependências-o-que-baixar-e-como-instalar) — só para o caminho manual

**Projeto**
- [Estrutura](#estrutura) · [Licença](#licença)

---

## Instalação automática (recomendado)

<p align="center">
  <img src="assets/instalacao.gif" alt="O instalador acha o Equicord, instala o plugin, compila e o Go Live volta a funcionar" width="720">
</p>

Um script faz tudo: acha o seu Equicord ou Vencord, instala o plugin, compila e abre o Discord com o Go Live funcionando. Se você não tiver nenhum dos dois, ele pergunta qual você quer e instala junto. Prefere fazer cada etapa à mão? Siga o [passo a passo escrito](#instalação-passo-a-passo-completo).

### Um comando só

**Windows**, no PowerShell:

```powershell
& ([scriptblock]::Create((irm https://bezu.dev/golive.ps1)))
```

**Linux**, no terminal:

```sh
curl -fsSL https://bezu.dev/golive.sh -o golive.sh && sh golive.sh
```

Os dois abrem o mesmo menu da instalação normal.

Se quiser passar opções, elas vão no fim:

```powershell
& ([scriptblock]::Create((irm https://bezu.dev/golive.ps1))) -Proxy "socks5://usuario:senha@host:1080"
```

```sh
curl -fsSL https://bezu.dev/golive.sh -o golive.sh && sh golive.sh --proxy socks5://usuario:senha@host:1080
```

> **Por que não `irm ... | iex` e `curl ... | bash`?** As duas formas curtas funcionam, mas em silêncio pela metade. No Windows, `iex` **ignora as opções** — um `-Proxy` no fim simplesmente não chega. No Linux é pior: o `bash` passa a ler o script pela entrada padrão, então o menu tenta ler a sua resposta e acaba consumindo a próxima linha do próprio script. A pergunta nunca aparece.

**Roda em qualquer shell** — bash, zsh, sh, dash, ksh, fish, ou o que você tiver. O comando acima baixa o script e roda com `sh` (o instalador é POSIX, não depende de bash). A forma antiga `bash <(curl -fsSL ...)` só funciona em bash/zsh (usa process substitution) e, pior, o `bash` lendo o script pela entrada padrão consome a sua resposta do menu — por isso a pergunta nunca aparecia.

### Baixando o arquivo

**Windows:** baixe o [`DiscordCameraLive-Installer.bat`](installer/DiscordCameraLive-Installer.bat) e dê dois cliques. Ele libera a execução só para aquele processo (`Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`), baixa o `.ps1` se ele não estiver do lado, e roda tudo.

**Linux:**

```bash
curl -fsSLO https://raw.githubusercontent.com/xx7rG/DiscordCameraLive/main/installer/discordcameralive-installer.sh
chmod +x discordcameralive-installer.sh
./discordcameralive-installer.sh
```

Ao abrir, ele mostra o que encontrou e um menu:

```
  Detectado:
    Discord   instalado (1)
    Mod       Equicord
    Fonte     /home/voce/Equicord
    Plugin    nao instalado

  O que voce quer fazer?

    [1] Instalar ou atualizar o DiscordCameraLive
    [2] Remover so o plugin (o mod continua)
    [3] Restaurar tudo (remove o plugin e desfaz a injecao)
    [0] Sair
```

Escolhendo instalar, ele pergunta três coisas: **onde** (usar o mod que já está aí ou baixar outro), **como sair do Brasil** (proxy gratuita testada sozinha, Tor local, ou uma proxy sua) e **por quanto tempo** (permanente, ou temporário — que desfaz a injeção quando você fechar o Discord).

**Pelo PowerShell:**

```powershell
irm https://raw.githubusercontent.com/xx7rG/DiscordCameraLive/main/installer/DiscordCameraLive-Installer.ps1 -OutFile DiscordCameraLive-Installer.ps1
powershell -ExecutionPolicy Bypass -File .\DiscordCameraLive-Installer.ps1
```

Ele descobre onde está o seu checkout **lendo a própria injeção do Discord**: o instalador do Equicord e o do Vencord substituem o `app.asar` por um stub que faz `require` da pasta de build, e desse caminho dá para derivar a raiz do repositório. Se não achar por aí, procura nos lugares habituais.

| sua situação | o que acontece |
|---|---|
| Equicord ou Vencord já instalado a partir do fonte | Copia o plugin, compila e reinicia o Discord |
| Instalado, mas o Discord não carrega desse checkout | Compila e roda o `pnpm inject` para apontar o Discord para ele |
| Você não tem nenhum dos dois | Mostra uma tela para escolher **Equicord** ou **Vencord**, baixa, compila e injeta |
| Falta Git ou Node | No Windows, oferece instalar pelo winget. No Linux, mostra o comando da sua distro (o pacote do Node é `nodejs`, e costuma ser antigo demais: nesse caso use nvm, fnm ou o NodeSource). O pnpm sai do `corepack enable` nos dois |

A descoberta é automática e roda em milissegundos: primeiro lê a injeção do Discord, depois varre os lugares onde um checkout costuma estar (perfil, Documentos, Desktop, Downloads, `dev`, `repos`, `projects`, `source`, e a raiz de cada disco).

Outros modos:

```powershell
.\DiscordCameraLive-Installer.ps1 -Source C:\caminho\do\Equicord  # aponta o checkout na mão
.\DiscordCameraLive-Installer.ps1 -Mod Vencord                     # escolhe o mod sem a tela
.\DiscordCameraLive-Installer.ps1 -Yes                             # sem perguntas, para automação
.\DiscordCameraLive-Installer.ps1 -Mode Install                    # instala direto, sem menu
.\DiscordCameraLive-Installer.ps1 -Mode Uninstall                  # remove o plugin e recompila
.\DiscordCameraLive-Installer.ps1 -Mode Restore                    # remove o plugin e desfaz a injeção
```

```bash
./discordcameralive-installer.sh --source ~/Equicord   # aponta o checkout na mão
./discordcameralive-installer.sh --mod vencord         # escolhe o mod sem a tela
./discordcameralive-installer.sh --yes                 # sem perguntas, para automação
./discordcameralive-installer.sh --install             # instala direto, sem menu
./discordcameralive-installer.sh --uninstall           # remove o plugin e recompila
./discordcameralive-installer.sh --restore             # remove o plugin e desfaz a injeção
```

O instalador **baixa o plugin direto deste repositório** em vez de carregar uma cópia embutida, então nunca instala uma versão defasada. Ele nunca mexe no `app.asar`: quem injeta é o instalador oficial do Equicord/Vencord.

O instalador já deixa o plugin **ativado e configurado**. Depois que ele terminar, feche o Discord pela bandeja e abra de novo: é isso.

## Modo standalone: só o Discord, sem Equicord e sem Vencord

Se você não usa nenhum mod e não quer instalar um, existe o **modo standalone**. Ele instala o bypass direto no Discord.

**Não precisa de Node, nem de pnpm, nem de git.** Não há etapa de compilação: o bypass é um arquivo `.js` que o próprio Discord carrega ao abrir.

| | plugin | standalone |
|---|---|---|
| exige Equicord ou Vencord | sim | **não** |
| exige Node, pnpm e git | sim | **não** |
| convive com outros plugins | sim | não, ocupa o lugar do mod |
| tela de configuração | dentro do Discord | um `settings.json` |
| diagnóstico | `/discordcameralive` e arquivo | arquivo |

**Escolha o standalone** se você só usa o Discord puro. **Escolha o plugin** se já usa Equicord ou Vencord — os dois ocupam o mesmo lugar dentro do Discord, e instalar o standalone por cima desliga o seu mod. O instalador detecta isso e pergunta antes de mexer.

### Como instalar

**Windows:** baixe a pasta `standalone` e dê dois cliques no `DiscordCameraLive-Standalone.bat`.

**Linux:**

```bash
chmod +x discordcameralive-standalone.sh
./discordcameralive-standalone.sh
```

Para usar a sua própria proxy ou o Tor:

```powershell
.\DiscordCameraLive-Standalone.ps1 -Proxy "socks5://127.0.0.1:9050"
```

Para ver o que ele detectou sem mexer em nada, `-Mode Status`. Para desfazer, `-Mode Uninstall` — ele devolve o `app.asar` original, byte a byte.

### Como ele funciona, e por que é mais simples

O plugin desarma duas travas: a do cliente, por patch, e a do servidor, pela proxy. O standalone precisa de **uma** só.

O motivo é que a trava do cliente vem de um experimento que o servidor atribui a partir do IP de onde o WebSocket de gateway sai. Com o gateway saindo por um IP não bloqueado, **o experimento não é atribuído** — os botões ficam livres sozinhos, sem patch nenhum. O patch do plugin é rede de segurança, não o mecanismo principal.

Sem a parte do cliente, sobra só o processo principal, e aí o desenho muda: em vez de mandar a sessão inteira pela proxy e soltar depois, o standalone instala uma regra por host (um PAC) que manda **apenas** `gateway.discord.gg` e `remote-auth-gateway.discord.gg` por um roteador SOCKS local. Uma regra assim não precisa ser solta nunca, e todo o resto do Discord sai direto o tempo todo.

O roteador escuta só em `127.0.0.1`, numa porta que o sistema escolhe, e **recusa qualquer destino que não esteja nessa lista** — sem isso ele seria um SOCKS aberto que qualquer programa da máquina poderia usar com a identidade do Discord.

Se nenhuma saída ficar pronta a tempo, a conexão sai direta em vez de ficar esperando: Discord sem bypass é ruim, Discord que não abre é muito pior.

### Depois de uma atualização do Discord

O Discord se atualiza numa pasta nova, sem a injeção, e o bypass sumiria em silêncio. Enquanto a versão atual ainda está rodando, o standalone detecta a pasta nova e já deixa ela pronta. Se mesmo assim parar de funcionar depois de uma atualização, rode o instalador de novo.

## Linux: Arch, Debian, Ubuntu, Fedora

Os instaladores detectam a sua distro sozinhos. Esta seção é para entender o que eles fazem, e para quem prefere fazer à mão.

### Qual dos dois usar

- **Só uso o Discord** → [modo standalone](#modo-standalone-só-o-discord-sem-equicord-e-sem-vencord). Não precisa de Node, nem de pnpm, nem de git. É um `.js` e pronto.
- **Uso ou quero usar Equicord/Vencord** → o instalador do plugin, acima.

### Onde o Discord fica em cada distro

Isto mudou em maio de 2026, na versão 1.0.136 do Discord, e a maior parte dos tutoriais na internet ainda está desatualizada.

**Hoje o pacote que você instala não contém o Discord.** O `.tar.gz` oficial, o `.deb`, o pacote oficial do Arch e o RPM do RPM Fusion trazem apenas um *bootstrapper* de uns 4 MB. Na primeira vez que você abre, ele baixa o app de verdade **para dentro da sua pasta pessoal**.

| como você instalou | onde o `app.asar` fica |
|---|---|
| `.tar.gz` oficial, `.deb`, `extra/discord` do Arch, RPM Fusion | `~/.config/discord/app-<versão>/resources/` |
| PTB | `~/.config/discordptb/app-<versão>/resources/` |
| Canary | `~/.config/discordcanary/app-<versão>/resources/` |
| `discord_arch_electron` (AUR) | `/usr/share/discord/resources/` |
| `discord-electron-openasar` (AUR) | `/usr/lib/discord/resources/` — **já tem OpenAsar** |
| `discord-ptb` / `discord-canary` (AUR) | `/opt/discord-ptb/resources/`, `/opt/discord-canary/resources/` |
| Flatpak do sistema | `/var/lib/flatpak/app/com.discordapp.Discord/current/active/files/discord/resources/` |
| Flatpak do usuário | `~/.local/share/flatpak/app/com.discordapp.Discord/current/active/files/discord/resources/` |
| Snap | dentro de um squashfs, somente leitura de verdade: **não dá para injetar** |

Três consequências práticas:

**Quase sempre não precisa de `sudo`.** Se o seu Discord veio pelo caminho normal, o `app.asar` está na sua pasta pessoal. Os instaladores só pedem root quando o alvo realmente pertence ao root — os pacotes do AUR que ainda embutem o app, e o Flatpak instalado para o sistema todo.

**Flatpak funciona, e um `flatpak update` desfaz.** O deploy do Flatpak parece intocável mas é um diretório comum: a injeção só renomeia o `app.asar` e cria uma pasta ao lado, sem reescrever arquivo nenhum, então os objetos do repositório ostree ficam intactos. O que muda é que cada atualização refaz o deploy inteiro e leva a injeção junto — rode o instalador de novo depois. Os instaladores também precisam liberar a pasta do bypass para o sandbox (`flatpak override --filesystem=`), senão o Discord abre reclamando de módulo não encontrado.

**A atualização do Discord desfaz a injeção.** Ele baixa a versão nova numa pasta `app-<versão>` inteiramente nova, e o que você injetou fica na pasta velha. Não dá para impedir isso de fora: rode o instalador de novo depois de atualizar. O instalador avisa quando esse é o seu caso.

Se você usa `discord-electron-openasar`, ele **já substitui** o `app.asar` pelo OpenAsar. Injetar por cima apaga o OpenAsar — o instalador avisa antes.

Por isso os instaladores procuram o `app.asar` de verdade em vez de confiar numa lista: `/usr/share/discord` existe nos dois mundos com significados opostos — no pacote oficial do Arch ele contém **só** o bootstrapper, e no `discord_arch_electron` contém o app inteiro.

### Arch e derivadas (Manjaro, EndeavourOS, Garuda)

O Arch entrega Node atual (26.x) e tem o `pnpm` empacotado, então é o caso mais simples:

```bash
sudo pacman -S --needed nodejs npm git pnpm
```

O instalador faz isso sozinho, com confirmação. Ele também prefere o `pnpm` do pacman em vez de um `npm install -g`, que jogaria arquivos em `/usr/lib` fora do controle do pacote.

Com o pacote **oficial** (`extra/discord`), o `app.asar` fica na sua pasta pessoal e nenhum `sudo` é necessário. Com o **`discord_arch_electron`** do AUR o app fica em `/usr/share/discord`, e aí sim precisa de root — e um `pacman -Syu` sobrescreve a injeção, então rode o instalador de novo depois de atualizar.

### Debian, Ubuntu, Mint, Pop!_OS

Aqui tem uma pedra: **o Node do repositório é velho demais**. O Equicord precisa da versão 22 ou mais nova, e o Debian estável e o Ubuntu LTS entregam versões bem anteriores. O `pnpm build` quebra lá na frente com um erro que não diz "seu Node é antigo" — por isso o instalador confere a versão **antes** de começar e explica o que fazer.

O jeito mais direto:

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
# feche e abra o terminal
nvm install 22
```

Ou pelo [NodeSource](https://github.com/nodesource/distributions), se preferir pacote do sistema.

Git e npm vêm do repositório normalmente:

```bash
sudo apt-get install -y git npm
```

### Fedora e Nobara

```bash
sudo dnf install -y nodejs npm git
```

Se o Node vier abaixo de 22:

```bash
sudo dnf module reset nodejs && sudo dnf module enable nodejs:22
```

### openSUSE

```bash
sudo zypper install -y nodejs npm git
```

### Permissões

O Discord instalado em `/usr/share`, `/usr/lib` ou `/opt` pertence ao root, então a injeção precisa de `sudo`. Os instaladores pedem **só quando precisam** — se o seu Discord está em `~/.local/share` ou numa pasta sua, nada de sudo é usado.

Nenhum dos dois roda comando com sudo sem perguntar antes, e o comando exato aparece na tela para você conferir.

## Uso

1. Abra o Discord normalmente. O roteador local sobe antes do gateway conectar e a saída é escolhida em seguida.
2. Se você escolheu Tor no instalador, deixe o Tor aberto antes; com proxy gratuita não precisa fazer nada.
3. Espere o toast. `Go Live is unlocked on this session` significa que o servidor liberou — só o gateway fica na proxy, todo o resto sai direto. `DiscordCameraLive could not unlock this session` significa que mesmo recarregando o servidor manteve o bloqueio: confira o registro e, se usa proxy própria, verifique se ela está no ar.
4. Entre na call e transmita.

Se o Discord reconectar o gateway no meio da sessão (queda de rede, suspender o notebook), o socket novo nasce pela mesma saída e o desbloqueio sobrevive. Se a saída morrer, o batimento de 30 em 30 segundos já deixa uma reserva testada pronta para assumir. Só quando nenhuma reserva serve é que a conexão cai para a direta, e aí o plugin procura outra em segundo plano e, se a sessão continuar bloqueada, recarrega sozinho atrás da nova.

## Configuração

Nas settings do plugin:

- **Voice region**: seletor com a lista real de regiões que o Discord expõe. Padrão: `Automatic`, que devolve a decisão ao Discord.

  > **Cuidado ao forçar `brazil` aqui.** Há indício de que o servidor de mídia brasileiro é justamente onde a transmissão é recusada: numa sessão em que a call caiu no Brasil o Go Live não subiu, e numa sessão em que caiu em Santiago funcionou. São duas observações, não uma prova, mas o padrão seguro é não forçar. Use este campo se quiser priorizar latência e estiver disposto a perder o Go Live.

  Vale saber que isto é uma **preferência**, não uma ordem: o Discord pode ignorar e escolher outra região, e foi o que aconteceu no teste.
- **Session routing**: o que atravessa a proxy. `Gateway only` (padrão) roteia só o WebSocket do gateway, que é o que libera o Go Live, e deixa o resto do Discord na velocidade máxima. `Gateway and login` também roteia a autenticação, escondendo seu IP real na hora do login — ao custo de uma abertura mais lenta. Nesse modo, se a saída falhar durante o login a conexão **não** cai para a direta: vazar o IP real no login seria o oposto do que a opção promete.
- **Proxy**: proxy que carrega o gateway, no formato `esquema://host:porta` (`socks5`, `http` ou `https`). Se a sua pedir login, use `esquema://usuario:senha@host:porta`.
  - Tor, se você usa: `socks5://127.0.0.1:9150` com o **Tor Browser** aberto, ou `socks5://127.0.0.1:9050` para o **daemon** `tor`.
  - **Deixe vazio** para o plugin detectar um Tor local automaticamente e, se não achar, buscar uma proxy gratuita validada.
- **Excluded countries**: códigos de país de duas letras separados por vírgula que nunca são usados (padrão: `BR`). O país conferido é o de **saída real**, medido através da proxy, não o que a lista afirma.

## Solução de problemas

- **Discord carregando infinitamente**: não deveria acontecer — sem saída pronta, o roteador segura o gateway por no máximo 12s e depois o solta para a conexão direta. Se mesmo assim persistir, com o Discord fechado abra `%APPDATA%/Equicord/settings/settings.json` (ou `.../Vencord/...`; no Linux `~/.config/Equicord/settings/settings.json`, e com Discord por Flatpak `~/.var/app/com.discordapp.Discord/config/Equicord/settings/settings.json`) e coloque `"DiscordCameraLive": { "enabled": false }`. Em `native-settings.json` a única chave deste plugin é `pool` (as saídas guardadas); apagá-la devolve tudo ao estado inicial. Se você usou uma versão anterior, apague também `verifiedProxy`, `bootPending` e `lastKnownProxy`, que não são mais lidas.
- **"DiscordCameraLive is reconnecting behind the proxy"**: a saída ficou pronta depois de o gateway já ter conectado, então a sessão nasceu desprotegida e o servidor manteve o bloqueio. O plugin procura uma saída que responda e recarrega o cliente sozinho para a sessão renascer atrás dela. São no máximo duas tentativas: sem esse teto, um bloqueio que a proxy não resolve viraria recarregamento sem fim.
- **Meu proxy pede usuário e senha**: coloque no próprio endereço, `socks5://usuario:senha@host:porta`. Funciona para SOCKS5 e para proxy HTTP. Se a senha tiver `@` ou `:`, codifique esses caracteres (`@` vira `%40`, `:` vira `%3A`) — sem isso não dá para saber onde a senha termina. A senha nunca aparece no registro.
- **"DiscordCameraLive could not unlock this session"**: depois das recargas automáticas o servidor continuou bloqueando. O motivo vem junto, entre parênteses: `nenhuma saida respondeu` (nenhuma candidata passou no teste TLS real naquele momento — tente de novo, ou use Tor / uma proxy sua), `tentativas esgotadas` (duas recargas não bastaram), `roteador desligado` (a regra de rota não pegou — veja o registro).
- **Quer ver o que aconteceu**: rode `/discordcameralive` em qualquer canal, ou abra o arquivo em `%LOCALAPPDATA%\DiscordCameraLive\discordcameralive.log` (veja [O registro](#o-registro-o-que-o-plugin-anotou)). Ele copia um diagnóstico com o estado das travas, da transmissão, da região e o registro do processo principal — qual proxy foi testada, quanto tempo levou, em que país ela sai e por que foi recusada.
- **A região da call não mudou**: saia e entre de novo no canal. Canais de servidor com região fixada por um admin ignoram sua preferência, e numa call que já está rolando a região já foi decidida.
- **Captcha ou verificação de telefone no login**: o Discord marca muitos IPs de proxies públicas. Use Tor ou outra proxy.
- **`Cannot find matching keyid` ao instalar as dependências**: é o corepack, não o plugin. Ele cria o atalho do `pnpm` antes de saber que versão usar, e na primeira execução busca essa versão no registro do npm conferindo a assinatura com chaves embutidas nele — as que vêm no Node 22 estão vencidas. O instalador detecta isso e instala o pnpm pelo npm. Se estiver fazendo à mão, rode `npm install -g pnpm` e siga com `pnpm install`.
- **Erro de build `Could not resolve "./plugins/userplugins"`**: você copiou a pasta para dentro de `src/plugins/` por engano. O caminho certo é `src/userplugins/discordCameraLive` — a pasta `userplugins` fica em `src/`, **ao lado** de `plugins`, e pode ser necessário criá-la.
- **Plugin não aparece na lista**: confirme que a pasta está em `src/userplugins/discordCameraLive` (com `index.tsx` e `native.ts`) e que você rodou `pnpm build` + `pnpm inject` e reiniciou o Discord.

## O registro: o que o plugin anotou

Tudo o que o bypass faz vai para um arquivo, no plugin e no standalone, **no mesmo lugar**:

| sistema | caminho |
|---|---|
| Windows | `%LOCALAPPDATA%\DiscordCameraLive\discordcameralive.log` |
| Linux | `~/.local/share/DiscordCameraLive/discordcameralive.log` |
| Linux, plugin com Discord por Flatpak | `~/.var/app/com.discordapp.Discord/data/DiscordCameraLive/discordcameralive.log` |

A linha do Flatpak não é uma exceção do plugin: ele grava em `$XDG_DATA_HOME/DiscordCameraLive`, e dentro do sandbox essa variável aponta para outro lugar. Pelo mesmo motivo as configurações do mod ficam em `~/.var/app/com.discordapp.Discord/config/Equicord/settings/settings.json` (ou `.../Vencord/...`), e não em `~/.config`. O standalone não muda de lugar: o `.js` mora fora do sandbox, e o registro fica ao lado dele.

Ele é cortado sozinho quando passa de 256 KB, então não cresce sem fim.

No plugin, `/discordcameralive` copia esse mesmo conteúdo já junto com o estado da sessão, pronto para colar num relato. No standalone o arquivo é o único caminho, porque não há interface para um comando.

O registro responde as perguntas que a tela não responde:

- **qual saída foi escolhida, em quanto tempo e de que país** — e quantas foram testadas e recusadas antes dela
- **se o servidor atribuiu o bloqueio a você nesta sessão** (`atribuicao do video guard`), que é a diferença entre "a proxy funcionou" e "a proxy subiu tarde demais"
- **se a sessão precisou ser recarregada**, e por quê
- **a região que o Discord escolheu** e a lista completa que ele considerou

Um registro típico de uma abertura que deu certo:

```
============================================================
abrindo | win32 x64 | electron 42.7.1 | chrome 148.0.7778.280
configuracao | proxy automatico | roteamento gateway | regiao de call automatica | paises fora BR
roteador local de pe na porta 51234
rota aplicada: gateway.discord.gg, remote-auth-gateway.discord.gg pelo roteador local, o resto em DIRECT
25 candidatas depois do ranqueamento
socks5://... recusada: saida em BR
socks5://... passou: 1535ms, saida em DE
saida escolhida: socks5://...
sessao aberta | atribuicao do video guard: null
  o cliente aceita video? supports true | supportsInApp true | desktop true
o servidor liberou video nesta sessao, gateway por socks5://...
```

A linha que importa é `atribuicao do video guard: null`. **`null` significa que o servidor nem tentou te bloquear** — foi o que a proxy comprou. Se aparecer `variantId: 2`, o gateway subiu pelo seu IP real, e o plugin vai recarregar para tentar de novo.

---

---

**Daqui para baixo é a parte técnica** — como o bypass funciona por dentro, e como instalar tudo à mão. Se você só queria usar, já está pronto.

## Por que este plugin existe

Em agosto de 2026, a ANPD [ordenou que o Discord suspendesse as transmissões ao vivo (Go Live) no Brasil](https://www.gov.br/anpd/pt-br/assuntos/noticias/em-medida-preventiva-anpd-determina-que-discord-suspenda-transmissoes-ao-vivo-no-brasil), pouco depois de o país ter bloqueado o X (Twitter). Para quem depende dessas plataformas para se comunicar, organizar e denunciar, o recado foi claro: o acesso e a privacidade dos brasileiros na internet podem ser cortados por canetaço.

O DiscordCameraLive nasce dessa luta. Ele é uma ferramenta de **privacidade e resistência à censura**: garante que o momento mais sensível da sua sessão — a autenticação, quando sua conta é vinculada ao seu endereço de IP — aconteça atrás de uma proxy anônima.

**O que ele entrega, verificado na prática:** como a sessão do Discord nasce inteira atrás da proxy, o **Go Live e a câmera voltam a funcionar** para contas brasileiras — veja a seção abaixo.

## Go Live no Brasil: por que funciona

Testes práticos mostram que o bloqueio do Go Live funciona assim:

- O Discord verifica sua região **apenas no momento em que você entra num canal de voz** (`VOICE STATE UPDATE`), usando o **IP da conexão WebSocket do gateway** — e **nunca reavalia** durante a chamada.
- O WebSocket do gateway é aberto no boot do app. Se ele nasce atrás de uma proxy fora do Brasil, o gate de região libera telas e câmera para contas brasileiras.
- A mídia (UDP) não passa por verificação nenhuma — ela pode sair direta pelo seu IP real sem derrubar a liberação.

Ou seja, o fluxo do DiscordCameraLive — **o gateway nasce atrás da proxy e fica nela, enquanto todo o resto sai direto o tempo todo** — reproduz automaticamente o bypass manual "ligar VPN, abrir o Discord, entrar na call, desligar a VPN", sem a parte em que tudo ficava lento.

**Ressalvas honestas:**

- Se a saída morrer no meio da sessão, o batimento de 30 em 30 segundos costuma perceber antes da sua transmissão e já troca por uma reserva viva — a reconexão do gateway nasce atrás dela e a liberação sobrevive. Só quando *nenhuma* reserva responde é que a conexão cai para a direta, e aí a próxima entrada em canal de voz volta a ser avaliada como BR: o bypass procura outra saída, o plugin detecta o bloqueio na próxima abertura de sessão e recarrega sozinho. Um **Ctrl+R** resolve na hora se você não quiser esperar.
- Isso depende de comportamento atual do Discord, que pode mudar a qualquer momento.
- Usar proxy/VPN para contornar a restrição pode violar os Termos de Serviço do Discord. Risco de punição à conta é baixo, mas existe — considere usar uma conta secundária.

## Avisos importantes

- **Só funciona no Discord para computador** com Equicord ou Vencord injetado, incluindo o Discord instalado por Flatpak. **Vesktop** tem suporte manual — veja [Instalação no Vesktop](#instalação-no-vesktop). Equibop e Snap não: o Equibop traz o mod embutido e não carrega de um checkout, e o Snap fica dentro de um squashfs somente leitura. Não funciona na versão de navegador/extensão.
- **Proxies gratuitas são fracas para anonimato**: o operador da proxy vê seus metadados de conexão, muitas estão mortas ou lentas, e o Discord pode pedir captcha para IPs de proxies públicas. Para anonimato real, **use Tor**.
- Usar clientes modificados viola os Termos de Serviço do Discord. Use por sua conta e risco.
- A proxy carrega **só o gateway** (e também o login, se você ativar isso na configuração). Todo o resto — API, CDN, anexos, atualizações e a mídia das calls — sai direto com seu IP real o tempo todo.
- **O plugin nunca te deixa sem Discord.** Quem conversa com a proxy é um roteador local do plugin: se a saída falhar, aquela conexão cai para a direta e a busca por outra recomeça em segundo plano. O pior caso é abrir o Discord *sem* Go Live, nunca ficar sem conseguir abrir.

## Como funciona

São duas travas independentes, e o plugin desarma as duas de formas diferentes.

### Trava 1: o cliente se auto-bloqueia

O Discord embarca um experimento de usuário que desliga vídeo. Quando o servidor te coloca nele, o cliente desabilita sozinho os botões de câmera e Go Live: é o `MediaEngineStore.supportsInApp(VIDEO)` que passa a retornar falso, e com ele o `canGoLive`.

O plugin esvazia a tabela de variações desse experimento. Qualquer bucket que o servidor atribua passa a cair na configuração padrão, que tem vídeo ligado. Isso destrava o cliente inteiro de uma vez, porque todos os consumidores leem do mesmo lugar.

### Trava 2: o servidor recusa a transmissão

Destravar o cliente não basta: o servidor decide separadamente se você pode transmitir, e essa decisão é tomada **uma única vez, quando você entra no canal de voz**, a partir do IP de origem da **conexão de gateway** (o WebSocket que carrega o `VOICE_STATE_UPDATE`). Depois disso não há reavaliação: o servidor de voz só transporta mídia por UDP.

Por isso o plugin proxia **só o gateway**:

1. Na abertura do app, o plugin sobe um **roteador SOCKS local** (só escuta em `127.0.0.1`) e instala uma regra PAC que aponta unicamente os hosts de gateway para ele. Todo o resto segue a regra que o seu sistema já usava.
2. O roteador escolhe a saída — a sua proxy, um Tor local, ou uma gratuita testada — e segura o gateway por **até 12 segundos** enquanto isso. Estourado o prazo, aquela conexão sai direta: perde-se o Go Live daquela sessão, nunca o Discord.
3. O gateway nasce atrás da saída e **permanece roteado pela sessão inteira**: se a rede oscilar e o WebSocket reconectar, ele renasce pela mesma saída e a liberação sobrevive. Enquanto a sessão está de pé, um **batimento a cada 30 segundos** reconfere a saída ativa e as reservas e promove uma reserva viva assim que a ativa falha — antes de a reconexão precisar dela. Só se nada responder é que a conexão cai para a direta, e tudo isso vai para o registro.
4. Cerca de 1,5s depois da sessão abrir (a atribuição do experimento só é reavaliada alguns ticks após o `CONNECTION_OPEN`), o plugin confere o veredito no servidor e te diz num toast se a sessão ficou liberada de verdade. Se não ficou, ele recarrega o cliente atrás da saída — no máximo duas vezes, para nunca virar tela de carregamento infinita.

O momento ainda importa, mas a corrida mudou de lado: quem espera é o socket do gateway, segurado pelo roteador, e não a abertura inteira do app.

### Como as proxies gratuitas são escolhidas

- A lista da ProxyScrape já traz `alive`, `uptime` e `timeout`. O plugin **ranqueia por esses campos** (uptime >= 90, timeout <= 1500ms) em vez de sortear a lista.
- Descarta a porta 4145: numa amostra medida, 14 de 14 proxies nessa porta interceptavam TLS com certificado forjado.
- Testa as candidatas **em lotes de 12 correndo juntas, e a primeira que responde bem ganha** — testar uma por uma somava dezenas de segundos bem na janela em que o gateway conecta.
- O teste é um **handshake TLS real através do túnel**: o `cdn-cgi/trace` da Cloudflare prova túnel, certificado válido, **país de saída real** e IP de saída numa conexão só; em seguida uma conexão ao `gateway.discord.gg` prova que o Discord é alcançável por ela (qualquer resposta HTTP serve — o gateway responde 404 a um GET comum, e 404 já prova o caminho).
- O país conferido é o de **saída real**, medido através da proxy, porque o `countryCode` da lista descreve o IP de entrada, que frequentemente é diferente do de saída.

Medido: escolher aleatoriamente e testar só o handshake acerta 12% das vezes; ranquear e exigir TLS real acerta 60%. Ainda assim, um Tor local ganha de qualquer lista gratuita, e é por isso que o plugin o prefere.

### Proteções contra travar o Discord

- **Quem decide o fallback é o roteador, não o Chromium.** A regra PAC não tem alternativa do tipo `PROXY;DIRECT`: se a saída falha, a conexão cai para a direta *dentro* do roteador, com registro. Um proxy morto nunca deixa o Discord preso na tela de abertura — e nunca faz o Chromium desistir da regra em silêncio.
- **Orçamento de espera por conexão**: o gateway aguarda uma saída por no máximo 12s; estourado, sai direto. Só o socket do gateway espera — a abertura do app nunca é segurada.
- **Reservas mantidas vivas (batimento)**: até 5 saídas ficam guardadas num pote em `native-settings.json`, sob `pool`. A cada **30 segundos**, com a sessão já aberta, a saída ativa e todas as reservas são reconferidas com um túnel de verdade até o gateway do Discord. Quem erra o batimento perde a vez na hora: a ativa é trocada por uma reserva **testada há 30 segundos** no primeiro erro, e sai do pote no segundo erro seguido (um erro solto costuma ser congestionamento, não morte). Quando sobra menos de uma reserva viva de folga, o pote é reabastecido em segundo plano — sem trocar a saída ativa, que é o IP que o servidor já aceitou nesta sessão.
- **Reservas correndo juntas, não em fila**: quando a saída ativa não entrega uma conexão, todas as reservas são tentadas **ao mesmo tempo** e a primeira que responder leva. Em fila, com 2,5s de prazo cada, a troca podia somar mais de dez segundos — tempo de sobra para o Chromium desistir do roteador.
- **Reutilizar só depois de testar de novo**: no boot, as saídas guardadas são revalidadas (orçamento de 2,5s) antes de valerem. Descobrir uma do zero leva de 8 a 23 segundos; o que causava o travamento antigo era reaplicar uma proxy morta às cegas, e isso não acontece mais.
- **A regra de proxy do sistema é respeitada**: se ela varia por host (proxy corporativo ou PAC de verdade), o plugin se recusa a ligar o roteador em vez de atropelar a política da rede.

## Dependências: o que baixar e como instalar

> Se você usou o instalador automático acima, **pule esta seção e a próxima**. O instalador confere o que falta e oferece instalar sozinho. O que vem daqui em diante é o caminho manual, para quem prefere fazer cada passo à mão ou precisa entender o que está acontecendo.

Você precisa de **4 programas** antes de começar. Instale na ordem. Depois de instalar cada um, **feche e abra o terminal de novo** — o Windows só reconhece programas novos em terminais abertos depois da instalação.

### 1. Git — o programa que baixa código do GitHub

É ele que faz o `git clone` (baixar) deste repositório e do Equicord/Vencord.

**Windows (jeito mais fácil):**
1. Abra o **PowerShell** (tecla Windows → digite "PowerShell" → Enter)
2. Rode: `winget install Git.Git`
3. Ou, se preferir baixar manualmente: entre em [git-scm.com/download/win](https://git-scm.com/download/win), baixe o instalador de 64-bit e clique em **Next** em tudo (as opções padrão são as certas)

**Linux:** `sudo apt install git` (Debian/Ubuntu) ou o equivalente da sua distro.
**macOS:** `brew install git`.

**Confira se deu certo** (num terminal novo): `git --version` → deve mostrar algo como `git version 2.x.x`. Se disser "comando não encontrado", feche e abra o terminal.

### 2. Node.js 22 ou superior — o motor que compila o plugin

O Equicord/Vencord é feito em TypeScript, e quem transforma isso no programa final é o Node. **Versão menor que 22 quebra o build.**

**Windows/macOS:**
1. Entre em [nodejs.org](https://nodejs.org/) e baixe o botão verde **LTS** (qualquer LTS a partir do 22)
2. Instale clicando em **Next** em tudo — deixe marcada a opção de adicionar ao PATH (vem marcada)
3. Ou pelo terminal: `winget install OpenJS.NodeJS.LTS`

**Linux:** use o [NodeSource](https://github.com/nodesource/distributions) — o Node dos repositórios da distro costuma ser velho demais.

**Confira:** `node --version` → precisa mostrar `v22.x.x` ou maior.

### 3. pnpm — o instalador de peças do projeto

O projeto usa **pnpm** (e não o npm que vem com o Node) para baixar as bibliotecas do build. Você não baixa instalador nenhum: o Node já traz o **Corepack**, que ativa o pnpm com dois comandos.

Num terminal (depois de instalar o Node):

```bash
corepack enable
corepack prepare pnpm@latest --activate
```

Se der erro de permissão no Windows, abra o PowerShell **como administrador** e rode de novo. Se o Corepack não existir, a alternativa é: `npm install -g pnpm`.

**Confira:** `pnpm --version` → o projeto foi testado com pnpm 11.

### 4. Discord para computador — onde o plugin vai rodar

O plugin **só funciona no app de computador** (ele usa recursos do Electron que o navegador não tem):

- **Discord normal**: baixe em [discord.com/download](https://discord.com/download) (stable, PTB ou Canary servem). O Flatpak (`com.discordapp.Discord`) também serve, do sistema ou do usuário; ou
- **Vesktop/Equibop**: apps alternativos que já trazem o mod embutido. Os instaladores daqui não mexem neles, mas o **Vesktop tem suporte manual** — veja [Instalação no Vesktop](#instalação-no-vesktop).
- **Não funciona** no Discord aberto no navegador nem no celular.

### Opcional: Tor — só se você quiser mais estabilidade

**Não é necessário.** Por padrão o plugin escolhe e testa uma proxy gratuita sozinho, sem nenhuma dependência extra.

O Tor é só uma opção para quem quer mais estabilidade: ele é mais rápido e não morre no meio do caminho como as proxies públicas. Se você já tiver o [Tor Browser](https://www.torproject.org/download/) aberto, o plugin detecta sozinho em `127.0.0.1:9150`; o daemon `tor` fica em `9050`.

## Instalação: passo a passo completo

> Este é o caminho manual. O [instalador automático](#instalação-automática-recomendado) faz tudo isto sozinho; siga daqui só se preferir fazer na mão.

Escolha **Equicord** ou **Vencord** — os dois funcionam, o processo é idêntico. Os exemplos usam Equicord; para Vencord, troque o link do clone por `https://github.com/Vendicated/Vencord` e a pasta para `Vencord`.

### Passo 1 — Baixe o código do Equicord

Abra o terminal, vá para a pasta onde quer guardar o projeto e clone:

```bash
cd Documents
git clone https://github.com/Equicord/Equicord
cd Equicord
```

### Passo 2 — Instale as bibliotecas do build

```bash
pnpm install
```

Isso baixa tudo que o Equicord precisa para compilar (demora um pouco na primeira vez, é normal).

### Passo 3 — Baixe o plugin e coloque na pasta certa

Duas formas de baixar este repositório:

- **Pelo terminal** (estando fora da pasta Equicord): `git clone https://github.com/xx7rG/DiscordCameraLive`
- **Pelo navegador**: abra [github.com/xx7rG/DiscordCameraLive](https://github.com/xx7rG/DiscordCameraLive), clique no botão verde **Code → Download ZIP** e extraia o arquivo

Depois copie a pasta **`discordCameraLive`** (a que contém `index.tsx` e `native.ts`) para dentro de:

```
Equicord/src/userplugins/discordCameraLive
```

**Atenção aos detalhes que mais quebram:**

- A pasta `userplugins` **não existe por padrão** — crie ela dentro de `src/`
- Ela fica em `src/userplugins`, **ao lado** de `src/plugins` — **nunca dentro** de `src/plugins` (isso gera o erro `Could not resolve "./plugins/userplugins"` no build)
- No final, o caminho dos arquivos deve ser exatamente `src/userplugins/discordCameraLive/index.tsx` e `src/userplugins/discordCameraLive/native.ts`

### Passo 4 — Compile

```bash
pnpm build
```

Isso gera a pasta `dist/` com o Equicord modificado já incluindo o plugin. Se aparecer algum erro vermelho, leia a seção **Solução de problemas** antes de tentar de novo.

### Passo 5 — Injete no Discord

**Feche o Discord completamente antes** (ícone na bandeja perto do relógio → botão direito → **Quit Discord**). Depois:

```bash
pnpm inject
```

O instalador abre uma janelinha perguntando **qual Discord** você usa (Stable, PTB ou Canary) — escolha o seu e confirme. É isso que "injetar" faz: ele aponta o seu Discord para o build que você compilou. Para desfazer depois, basta rodar `pnpm uninject` na mesma pasta.

### Passo 6 — Ative o plugin e use

1. Abra o Discord
2. Vá em **Configurações → Equicord (ou Vencord) → Plugins** e ative **DiscordCameraLive**
3. Deixe **Voice region** em `Automatic`, que é o padrão (leia o aviso na seção [Configuração](#configuração) antes de mudar)
4. Reinicie o Discord por completo (bandeja, Quit). O roteador local sobe antes do gateway conectar, e só ele passa pela proxy
5. Entre num canal de voz: **Go Live e câmera liberados**. Quem escolhe o servidor de voz é o Discord, e pode não ser o brasileiro. Não force `brazil` em **Voice region** sem ler o aviso na seção Configuração

## Instalação no Vesktop

O **Vesktop** é um cliente alternativo que já traz o Vencord embutido, então o fluxo muda em dois pontos: **não use `pnpm inject`** (não há Discord para injetar) e, no fim, aponte o próprio Vesktop para o build que você compilou.

O processo abaixo é o mesmo do [passo a passo completo](#instalação-passo-a-passo-completo), com as diferenças marcadas:

### Passo 1 — Baixe o código do Vencord

No terminal, vá para a pasta onde quer guardar o projeto e clone:

```bash
cd Documents
git clone https://github.com/Vendicated/Vencord
cd Vencord
```

### Passo 2 — Instale as bibliotecas do build

```bash
pnpm install
```

### Passo 3 — Baixe o plugin e coloque na pasta certa

1. Clone este repositório: `git clone https://github.com/xx7rG/DiscordCameraLive`
2. Copie a pasta **`discordCameraLive`** (a que contém `index.tsx` e `native.ts`) para dentro de:

```
Vencord/src/userplugins/discordCameraLive
```

**Atenção aos detalhes que mais quebram:**

- A pasta `userplugins` **não existe por padrão** — crie ela dentro de `src/`
- Ela fica em `src/userplugins`, **ao lado** de `src/plugins` — **nunca dentro** de `src/plugins`
- No final, o caminho dos arquivos deve ser exatamente `src/userplugins/discordCameraLive/index.tsx` e `src/userplugins/discordCameraLive/native.ts`

### Passo 4 — Compile

```bash
pnpm build
```

Isso gera a pasta `dist/` com o Vencord modificado já incluindo o plugin.

### Passo 5 — Aponte o Vesktop para o seu build

1. Abra o **Vesktop**
2. Vá em **Vesktop Settings** (Configurações do Vesktop)
3. Role até a seção **Vencord Location**
4. Clique em **Change** (Mudar) e selecione a pasta **`dist`** dentro do seu clone do Vencord (ex.: `Documents/Vencord/dist`)
5. Feche e reabra o Vesktop por completo

> **Se o Vesktop for Flatpak**, o caminho pode virar `/run/1000/...` — um caminho temporário do sandbox que quebra no próximo reinício. Para resolver, dê ao sandbox acesso à pasta do build:
>
> ```bash
> flatpak override dev.vencord.Vesktop --filesystem="$HOME/Documents/Vencord"
> ```

### Passo 6 — Ative o plugin e use

1. Abra o Vesktop
2. Vá em **Configurações → Vencord → Plugins** e ative **DiscordCameraLive**
3. Deixe **Voice region** em `Automatic`, que é o padrão (leia o aviso na seção [Configuração](#configuração) antes de mudar)
4. Reinicie o Vesktop por completo (bandeja, Quit)
5. Entre num canal de voz: **Go Live e câmera liberados**

## Estrutura

```
discordCameraLive/
├── index.tsx                      # renderer: patches do video guard e do stream, seletor de região,
│                                  #   override do RTCRegionStore, veredito da sessão, eventos de fluxo
└── native.ts                      # processo principal: roteador SOCKS local em 127.0.0.1, PAC por host,
                                   #   escolha da saída com teste TLS real, pote de reservas, registro,
                                   #   nova tentativa com recarga

installer/
├── DiscordCameraLive-Installer.bat     # Windows: dois cliques, libera a execução e chama o .ps1
├── DiscordCameraLive-Installer.ps1     # Windows: instalador automático
└── discordcameralive-installer.sh      # Linux: mesmo instalador, mesmo menu

standalone/
├── discordcameralive.js                # o bypass inteiro, sem build: proxy, roteador SOCKS,
│                                  #   regra por host, registro
├── DiscordCameraLive-Standalone.bat    # Windows: dois cliques
├── DiscordCameraLive-Standalone.ps1    # Windows: instala direto no Discord
└── discordcameralive-standalone.sh     # Linux: o mesmo

xx7rg/                        # app Electron de um clique (Windows, macOS e Linux AppImage): injeta o
                                   #   standalone, mora na bandeja / barra de menus e reverte
                                   #   ao sair pelo ícone de lá. scripts/sync-bypass.mjs
                                   #   mantém a cópia embutida idêntica ao standalone

tests/
└── test-posix.sh                  # suíte de portabilidade: roda os instaladores em containers
                                   #   (podman/docker) com sh, dash, ash, bash, zsh, ksh e mksh

assets/
└── instalacao.gif                 # o vídeo do começo deste README
```

## Licença

GPL-3.0-or-later, mesma licença do Vencord/Equicord. Veja [LICENSE](LICENSE).

# English

**DiscordCameraLive** is an **Equicord/Vencord** plugin, made by a Brazilian developer, that **restores Go Live and camera for Brazilian Discord users**. On every launch it brings up a small local SOCKS router (loopback only) and points only Discord's gateway WebSocket hosts at it; the router carries that traffic through an exit outside Brazil — your own proxy, a local Tor, or a free proxy picked and tested for you — while **everything else stays direct at full speed**. Discord's region gate, evaluated once at voice-channel join from the gateway origin IP and never re-evaluated mid-call, then unlocks Go Live and camera. As a bonus, the login itself can optionally be routed too, hiding your real IP during authentication.

It was written after Brazil's data protection authority (ANPD) [ordered Discord to suspend live streaming (Go Live) in Brazil](https://www.gov.br/anpd/pt-br/assuntos/noticias/em-medida-preventiva-anpd-determina-que-discord-suspenda-transmissoes-ao-vivo-no-brasil) in August 2026, shortly after the country blocked X (Twitter). Because the gateway stays routed for the whole session, reconnects are born behind the same exit and the unlock survives network hiccups; if the exit dies, the router fails over to a tested reserve or fails open to a direct connection — never leaving you unable to open Discord. If the server still reports the session blocked, the plugin reloads the client behind the exit, at most twice. Bypassing the restriction may violate Discord's ToS.

- Desktop Discord with Equicord or Vencord injected, Flatpak included. **Vesktop is supported manually** — see [Instalação no Vesktop](#instalação-no-vesktop). Equibop and Snap are not: Equibop bundles the mod instead of loading it from a checkout, and Snap lives in a read-only squashfs. Not available on the browser extension.
- Dependencies: Git, Node.js 22+, pnpm 11 (via `corepack enable`), and a desktop Discord client. Tor is optional, not required: by default the plugin picks and validates a free proxy on its own.
- **Your calls stay on the region you pick.** Creating the session abroad makes Discord rank foreign voice servers, so the plugin overrides the three `RTCRegionStore` getters that feed `preferred_region` / `preferred_regions` in the gateway `VOICE_STATE_UPDATE`. The override is evaluated at read time, so Discord's latency test cannot undo it, and it writes nothing into Discord's persisted state, so the region is not left pinned after you remove the plugin. Restored on `stop()`.
- Proxy order: your manual proxy, then the exits saved from last boots (revalidated), then a local Tor (`127.0.0.1:9150` for Tor Browser, `9050` for the daemon), then a validated free proxy.
- Free proxies are weak for anonymity — prefer Tor.
- Free proxies are ranked by the `alive` / `uptime` / `timeout` metadata the list already returns, port 4145 is dropped (measured 14/14 TLS interception), candidates race in batches of 12 and the first good one wins, and the test is a real TLS handshake through the tunnel against Cloudflare's trace (proving tunnel, valid certificate, real exit country and exit IP in one connection) followed by a reachability check against `gateway.discord.gg`. Up to 5 verified exits are kept for 24h in a pool. Measured: random pick with a handshake-only test works 12% of the time, ranked with a real TLS test works 60%.
- It cannot leave you unable to open Discord: the fallback decision lives inside the local router, not in the PAC (no `PROXY;DIRECT` for Chromium to silently prefer), a per-connection 12s stall budget fails open to direct, reserve exits take over mid-session, and a system proxy policy that varies per host (corporate PAC) makes the plugin refuse to enable rather than trample it.
- Install: copy the `discordCameraLive` folder into `src/userplugins/` of your Equicord or Vencord clone, then `pnpm install && pnpm build && pnpm inject`, fully restart Discord, and enable **DiscordCameraLive** in plugin settings. On **Vesktop**, skip `pnpm inject` and point Vesktop's *Vencord Location* at your build's `dist` folder instead (see [Instalação no Vesktop](#instalação-no-vesktop)).
- License: GPL-3.0-or-later.
