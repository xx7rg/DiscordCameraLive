# Segurança

## O que este software toca

O DiscordCameraLive (plugin, standalone e GUI) modifica a instalação do seu Discord: ele renomeia o `app.asar` original para `_app.asar` e escreve um `app.asar` novo que carrega o bypass. Nada é apagado — o original fica guardado ao lado, e desativar (`-Mode Uninstall`, "Desativar Bypass" na GUI, ou `--uninstall`) devolve exatamente o arquivo original.

Na GUI Electron, a troca é feita em duas etapas (escreve o conteúdo novo numa pasta temporária, valida, e só então troca o `app.asar` por `rename`) para que uma queda de energia ou falha de disco no meio do processo nunca deixe o Discord sem `app.asar` nenhum — veja `xx7rg/electron/main.ts` (`writeInjectionStaged` / `swapIn`).

Nenhum dado seu é enviado para nenhum servidor deste projeto. A única rede que o bypass usa é a proxy que você configurou (ou uma proxy gratuita/Tor, se você deixar em automático) para carregar o WebSocket de gateway do Discord — veja [docs/como-funciona.md](docs/como-funciona.md).

## GUI Electron

A janela roda com `nodeIntegration: false`, `contextIsolation: true` e `sandbox: true`; o `preload` expõe só as operações específicas via `contextBridge`, e o `index.html` carrega com uma Content-Security-Policy restrita (`script-src 'self'`, sem scripts inline). As mensagens IPC que recebem valor do renderer (endereço de proxy, altura da janela) são validadas no processo principal antes de usar.

## API de relatório de bugs

A GUI pode enviar um relatório de bug (log + descrição) para uma API própria ([api/](api/)), que abre uma issue no GitHub em seu nome. O `API_TOKEN` dessa API nunca deve ser embutido num binário distribuído publicamente — veja [api/README.md](api/README.md) para como hospedar a sua própria instância.

## Licença e procedência

Este projeto é um plugin para Vencord/Equicord e contém código derivado desse ecossistema, licenciado GPL-3.0-or-later. A GPL exige manter os avisos de licença e distribuir trabalhos derivados sob a mesma licença — os identificadores SPDX e o [LICENSE](LICENSE) não devem ser removidos ou trocados sem a autorização de todos os titulares de direitos envolvidos.

## Riscos de usar

- Usar clientes modificados (Equicord/Vencord) e proxies/VPN para contornar restrições de região pode violar os Termos de Serviço do Discord. O risco de punição à conta é baixo, mas existe — considere usar uma conta secundária.
- Proxies gratuitas são fracas para anonimato: o operador da proxy vê seus metadados de conexão. Para anonimato de verdade, use Tor.
- O bypass nunca deixa você sem conseguir abrir o Discord (se a proxy falhar, a conexão cai para direta), mas **não** garante que o Go Live vai funcionar em toda sessão — veja as ressalvas em [docs/como-funciona.md](docs/como-funciona.md).

## Reportando um problema de segurança

Se você encontrar uma vulnerabilidade (não um bug de uso comum — para isso veja [docs/solucao-de-problemas.md](docs/solucao-de-problemas.md)), abra uma [issue no GitHub](https://github.com/xx7rG/DiscordCameraLive/issues) descrevendo o problema. Para algo sensível que prefere não deixar público, entre em contato diretamente com o mantenedor antes de publicar detalhes.
