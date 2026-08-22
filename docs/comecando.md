← [Voltar ao README](../README.md)

# Guia para quem nunca instalou nada assim antes

Esse guia não presume que você sabe nada de computador. Se você só quer que o Go Live e a câmera voltem a funcionar no Discord, siga os passos na ordem — não precisa entender o "porquê" de nenhum deles.

**Tempo: 2 minutos. Não precisa abrir terminal, digitar comando nem instalar nenhum programa extra.**

## Passo 1 — Baixe o programa

1. Clique aqui: **[baixar a última versão](https://github.com/xx7rG/DiscordCameraLive/releases/latest)**.
2. A página vai abrir uma lista de arquivos, na parte de baixo, embaixo de "Assets". Baixe o que combina com o seu computador:

   | Seu computador | Baixe este arquivo |
   |---|---|
   | Windows | `DiscordCameraLive-1.1.5.exe` |
   | Mac (Apple Silicon, M1/M2/M3/M4) | `DiscordCameraLive.dmg` |
   | Linux | `DiscordCameraLive-1.1.5.AppImage` |

   Não sabe qual é o seu? Quase todo mundo com notebook ou PC comum usa **Windows** — é a opção mais provável.

3. O arquivo vai para a pasta **Downloads** do seu computador (é o padrão do navegador).

## Passo 2 — Abra o arquivo

Vá até a pasta Downloads e dê **dois cliques** no arquivo que você baixou.

Aqui o Windows ou o Mac provavelmente vai mostrar um aviso assustador. É normal — explico exatamente o que fazer abaixo.

### Se você usa Windows: "O Windows protegeu o computador"

Isso é o **SmartScreen**, um aviso padrão do Windows para qualquer programa novo que ainda não é muito conhecido (isso acontece porque o programa não pagou uma assinatura cara para "certificar" o instalador — não é sinal de vírus). O programa é [código aberto](https://github.com/xx7rG/DiscordCameraLive): qualquer pessoa pode ler exatamente o que ele faz.

1. Clique em **"Mais informações"** (texto pequeno, dentro da caixa de aviso).
2. Vai aparecer um botão **"Executar assim mesmo"**. Clique nele.

### Se você usa Mac: "Não é possível abrir porque..."

1. Em vez de clicar duas vezes, clique **uma vez** no arquivo com o botão **direito** do mouse (ou toque com dois dedos no trackpad).
2. Clique em **"Abrir"**.
3. Vai aparecer a mesma pergunta de novo, com um botão **"Abrir"** — clique nele de novo.

Se aparecer uma segunda tela pedindo permissão para o programa mexer no Discord: vá em **Ajustes do Sistema → Privacidade e Segurança**, ative o DiscordCameraLive na lista, e volte a clicar em Ativar.

## Passo 3 — Ative

Uma janela pequena e escura vai abrir. Ela mostra o nome do programa e, embaixo, um botão verde grande escrito **"Ativar Bypass"**.

Clique nesse botão.

O Discord vai **fechar e abrir sozinho** — é esperado, é o programa aplicando a mudança. Não mexa em nada, só espere.

## Passo 4 — Use o Discord normalmente

Pronto. Entre numa chamada de voz e ligue a câmera ou o Go Live normalmente, do jeito que você sempre fez. Deve funcionar.

**Se a transmissão aparecer com a tela preta ou não carregar**, aperte **Ctrl + R** (Windows/Linux) ou **Cmd + R** (Mac) com o Discord em foco. Isso recarrega e resolve na maioria das vezes.

## Depois disso

- **Pode fechar a janela do programa sem medo.** Ela não desliga nada — só esconde. O programa continua rodando discretamente perto do relógio, na bandeja do Windows (ou na barra de menus do Mac).
- **Para desligar de verdade** (e devolver o Discord ao normal): clique no ícone do programa perto do relógio/barra de menus, e escolha **"Sair"**. Só sair por esse ícone desfaz a mudança — fechar a janela não desfaz nada.

## Perguntas que todo mundo faz

**Isso é seguro? Não é vírus?**
O código é público — qualquer pessoa pode ler exatamente o que ele faz, em [github.com/xx7rG/DiscordCameraLive](https://github.com/xx7rG/DiscordCameraLive). Veja também [SECURITY.md](../SECURITY.md) para o que exatamente ele toca no seu sistema.

**Vou perder minha conta do Discord?**
O risco é baixo, mas existe: usar um programa que modifica o Discord tecnicamente [pode violar os termos de serviço](como-funciona.md#avisos-importantes) dele. Se isso te preocupa, considere usar numa conta secundária.

**Isso vai deixar meu computador lento, ou atrapalhar jogos?**
Não. O programa fica praticamente parado a maior parte do tempo, e só mexe na conexão do próprio Discord — nunca em outros programas ou jogos.

**Preciso saber programar ou usar o terminal?**
Não, nenhum passo aqui precisa disso. Se um dia você quiser instalar de outro jeito (via linha de comando, ou junto de um mod como Vencord/Equicord), isso existe, mas é opcional — veja o [guia completo de instalação](instalacao.md).

**Deu algum problema que não está aqui.**
Veja [Solução de problemas](solucao-de-problemas.md), com os casos mais comuns.
