← [Voltar ao README](../README.md)

# Instalação

Este guia cobre **todos** os jeitos de instalar o DiscordCameraLive, do mais simples ao mais manual. Se você não sabe qual escolher, comece pela tabela abaixo — ela te leva direto pro caminho certo.

## Qual caminho escolher

| Você... | Use |
|---|---|
| nunca instalou nada assim, ou quer o passo a passo mais devagar possível | [Guia para leigos](comecando.md) |
| usa Windows ou macOS e só quer clicar num botão | [Interface Gráfica (Windows e macOS)](#interface-gráfica-windows-e-macos) |
| usa Linux e quer clique único, sem terminal | [Interface Gráfica para Linux (AppImage)](#interface-gráfica-para-linux-appimage) |
| já usa Equicord ou Vencord e não se importa com um comando no terminal | [Instalação automática](#instalação-automática-um-comando) |
| só usa o Discord puro, sem Equicord/Vencord, e não quer instalar um mod | [Modo standalone](#modo-standalone-só-o-discord-sem-equicord-e-sem-vencord) |
| quer entender cada etapa ou prefere fazer tudo à mão | [Instalação manual, passo a passo](#instalação-manual-passo-a-passo) |
| usa Vesktop no lugar do Discord normal | [Instalação no Vesktop](#instalação-no-vesktop) |

Depois de instalar, veja **[Uso e Configuração](#uso)** logo abaixo das seções de instalação — é o que fazer na primeira vez que abrir o Discord.

Se algo não funcionar, o guia de **[Solução de problemas](solucao-de-problemas.md)** cobre os casos mais comuns.

---

## Interface Gráfica (Windows e macOS)

Um aplicativo completo que faz todo o trabalho de forma **100% automática**, sem precisar abrir terminais, usar scripts ou instalar modificações complexas como o Equicord.

<p align="center">
  <img src="../xx7rg/src/assets/hero-ui.png" alt="A interface do DiscordCameraLive: status do Discord, botao de ativar, tema claro e escuro e proxy customizada" width="420">
</p>

### Como baixar e instalar

1. Vá na **[última release](https://github.com/xx7rG/DiscordCameraLive/releases/latest)** aqui no GitHub.
2. Baixe o arquivo da sua plataforma, na lista no fim da página:
   - **Windows:** `DiscordCameraLive.exe` (portátil, roda direto sem instalar)
   - **macOS (Apple Silicon):** `DiscordCameraLive.dmg`, ou o `DiscordCameraLive.zip` se preferir
3. Abra o arquivo que você acabou de baixar.

O programa **não é assinado**. O sistema avisa na primeira vez. Se preferir não correr esse risco, use a [instalação por comando](#instalação-automática-um-comando), que é o mesmo bypass sem executável.

**Windows (SmartScreen):** **Mais informações → Executar assim mesmo**.

#### macOS

Dois avisos do sistema, e nenhum dos dois é o DiscordCameraLive "quebrado".

**1. Abrir o app (Gatekeeper).** Clique com o **botão direito** no DiscordCameraLive → **Abrir** → **Abrir**. Se o macOS só mostrar que não é possível abrir, vá em **Ajustes do Sistema → Privacidade e Segurança** e clique em **Abrir mesmo assim**.

**2. Deixar o app mexer no Discord (Administração de Apps).** Se você já usou o Vencord, sabe qual é essa tela: o macOS não deixa um programa alterar o `Discord.app` até você autorizar. É **a mesma permissão**. Na primeira vez que você clicar em Ativar, o sistema bloqueia a escrita; o DiscordCameraLive tenta abrir **Ajustes do Sistema → Privacidade e Segurança → Administração de Apps**. Ative o DiscordCameraLive (ou arraste o app para a lista) e clique em Ativar de novo.

**Depois de uma atualização do Discord.** No Mac o instalador troca o `.app` inteiro e a injeção some. Abra o DiscordCameraLive e ative de novo. (No Windows o standalone tenta adiantar isso sozinho; na GUI do Mac isso não existe.)

### Como usar

1. O aplicativo vai detectar o seu Discord automaticamente (no Mac, em `/Applications` ou `~/Applications`, inclusive PTB e Canary).
2. Clique em **"Ativar Bypass"**.
3. O Discord vai reiniciar automaticamente com o Go Live desbloqueado!
4. Pode fechar a janela sem medo: o app fica na **bandeja** do Windows (junto do relógio) ou na **barra de menus** do Mac. Clique no ícone de lá para reabrir, ativar/desativar ou **Sair** — sair por esse ícone é o que reverte tudo ao normal.
5. Se quiser que ele já abra com o PC (direto escondido, sem janela pulando na tela), marque **"Iniciar com o Windows"** ou **"Iniciar com o Mac"** na janela ou no menu do ícone.

> **Dica importante:** se a sua transmissão ficar com a tela preta ou não carregar de primeira, recarregue o Discord: **Ctrl + R** no Windows, **Cmd + R** no Mac.

## Interface Gráfica para Linux (AppImage)

A mesma interface gráfica do Windows, empacotada como **AppImage** (roda em qualquer distro: Debian, Ubuntu, Fedora, Arch e derivadas).

Assim como a versão Windows, ela é **portátil**: ativa o DiscordCameraLive ao clicar e fica na **bandeja** do sistema — fechar a janela só a esconde, e o **Sair** pelo ícone da bandeja é o que reverte tudo ao normal. Por baixo, ela chama o [modo standalone](#modo-standalone-só-o-discord-sem-equicord-e-sem-vencord) (POSIX, funciona em qualquer shell), então toda a lógica de detecção — Discord nativo, flatpak, bootstrap novo, snap — é a mesma dos scripts, com o progresso aparecendo na tela.

### Como baixar e instalar

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

### Como usar

1. O aplicativo detecta o seu Discord automaticamente (nativo ou flatpak).
2. Clique em **"Ativar Bypass"** — o Discord fecha, o bypass entra e ele reabre.
3. Fechar a janela só a esconde na bandeja (o app continua vivo); para reverter o bypass de verdade, use o **Sair** no menu do ícone da bandeja.

> **Nota:** se o seu Discord é flatpak do sistema, a primeira ativação pode pedir sua senha (via `pkexec`) para liberar a pasta do bypass para o sandbox.

## Instalação automática (um comando)

<p align="center">
  <img src="../assets/instalacao.gif" alt="O instalador acha o Equicord, instala o plugin, compila e o Go Live volta a funcionar" width="720">
</p>

Um script faz tudo: acha o seu Equicord ou Vencord, instala o plugin, compila e abre o Discord com o Go Live funcionando. Se você não tiver nenhum dos dois, ele pergunta qual você quer e instala junto. Prefere fazer cada etapa à mão? Siga o [passo a passo escrito](#instalação-manual-passo-a-passo).

### Um comando só

**Windows**, no PowerShell:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/xx7rG/DiscordCameraLive/main/installer/DiscordCameraLive-Installer.ps1)))
```

**Linux**, no terminal:

```sh
curl -fsSL https://raw.githubusercontent.com/xx7rG/DiscordCameraLive/main/installer/discordcameralive-installer.sh -o discordcameralive-installer.sh && sh discordcameralive-installer.sh
```

Os dois abrem o mesmo menu da instalação normal.

Se quiser passar opções, elas vão no fim:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/xx7rG/DiscordCameraLive/main/installer/DiscordCameraLive-Installer.ps1))) -Proxy "socks5://usuario:senha@host:1080"
```

```sh
curl -fsSL https://raw.githubusercontent.com/xx7rG/DiscordCameraLive/main/installer/discordcameralive-installer.sh -o discordcameralive-installer.sh && sh discordcameralive-installer.sh --proxy socks5://usuario:senha@host:1080
```

> **Por que não `irm ... | iex` e `curl ... | bash`?** As duas formas curtas funcionam, mas em silêncio pela metade. No Windows, `iex` **ignora as opções** — um `-Proxy` no fim simplesmente não chega. No Linux é pior: o `bash` passa a ler o script pela entrada padrão, então o menu tenta ler a sua resposta e acaba consumindo a próxima linha do próprio script. A pergunta nunca aparece.

**Roda em qualquer shell** — bash, zsh, sh, dash, ksh, fish, ou o que você tiver. O comando acima baixa o script e roda com `sh` (o instalador é POSIX, não depende de bash). A forma antiga `bash <(curl -fsSL ...)` só funciona em bash/zsh (usa process substitution) e, pior, o `bash` lendo o script pela entrada padrão consome a sua resposta do menu — por isso a pergunta nunca aparecia.

### Baixando o arquivo

**Windows:** baixe o [`DiscordCameraLive-Installer.bat`](../installer/DiscordCameraLive-Installer.bat) e dê dois cliques. Ele libera a execução só para aquele processo (`Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`), baixa o `.ps1` se ele não estiver do lado, e roda tudo.

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

### Depois de uma atualização do Discord

O Discord se atualiza numa pasta nova, sem a injeção, e o bypass sumiria em silêncio. Enquanto a versão atual ainda está rodando, o standalone detecta a pasta nova e já deixa ela pronta. Se mesmo assim parar de funcionar depois de uma atualização, rode o instalador de novo.

Como o standalone funciona por dentro (a diferença para o plugin) está explicado em **[Como funciona](como-funciona.md#o-que-o-standalone-simplifica)**.

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
3. Espere o toast. `Go Live is unlocked on this session` significa que o servidor liberou — só o gateway fica na proxy, todo o resto sai direto. `DiscordCameraLive could not unlock this session` significa que mesmo recarregando o servidor manteve o bloqueio: confira o registro (veja [Solução de problemas](solucao-de-problemas.md)) e, se usa proxy própria, verifique se ela está no ar.
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

## Instalação manual, passo a passo

> Este é o caminho manual. A [instalação automática](#instalação-automática-um-comando) faz tudo isto sozinha; siga daqui só se preferir fazer na mão ou quiser entender cada etapa.

Antes de começar, veja **[Dependências](#dependências-o-que-baixar-e-como-instalar)** logo abaixo — são 4 programas para instalar, na ordem certa.

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

Isso gera a pasta `dist/` com o Equicord modificado já incluindo o plugin. Se aparecer algum erro vermelho, leia [Solução de problemas](solucao-de-problemas.md) antes de tentar de novo.

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

## Dependências: o que baixar e como instalar

> Se você usou a instalação automática ou a GUI acima, **pule esta seção**. O instalador confere o que falta e oferece instalar sozinho. O que vem daqui em diante é para quem segue o [caminho manual](#instalação-manual-passo-a-passo).

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

## Instalação no Vesktop

O **Vesktop** é um cliente alternativo que já traz o Vencord embutido, então o fluxo muda em dois pontos: **não use `pnpm inject`** (não há Discord para injetar) e, no fim, aponte o próprio Vesktop para o build que você compilou.

O processo abaixo é o mesmo do [passo a passo completo](#instalação-manual-passo-a-passo), com as diferenças marcadas:

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

---

Próximo passo: leia [Como funciona](como-funciona.md) para entender o que o bypass faz de verdade, ou vá direto para [Solução de problemas](solucao-de-problemas.md) se algo não funcionou.
