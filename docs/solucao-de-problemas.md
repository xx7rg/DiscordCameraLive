← [Voltar ao README](../README.md) · [Instalação](instalacao.md) · [Como funciona](como-funciona.md)

# Solução de problemas

- **Discord carregando infinitamente**: não deveria acontecer — sem saída pronta, o roteador segura o gateway por no máximo 12s e depois o solta para a conexão direta. Se mesmo assim persistir, com o Discord fechado abra `%APPDATA%/Equicord/settings/settings.json` (ou `.../Vencord/...`; no Linux `~/.config/Equicord/settings/settings.json`, e com Discord por Flatpak `~/.var/app/com.discordapp.Discord/config/Equicord/settings/settings.json`) e coloque `"DiscordCameraLive": { "enabled": false }`. Em `native-settings.json` a única chave deste plugin é `pool` (as saídas guardadas); apagá-la devolve tudo ao estado inicial. Se você usou uma versão anterior, apague também `verifiedProxy`, `bootPending` e `lastKnownProxy`, que não são mais lidas.
- **"DiscordCameraLive is reconnecting behind the proxy"**: a saída ficou pronta depois de o gateway já ter conectado, então a sessão nasceu desprotegida e o servidor manteve o bloqueio. O plugin procura uma saída que responda e recarrega o cliente sozinho para a sessão renascer atrás dela. São no máximo duas tentativas: sem esse teto, um bloqueio que a proxy não resolve viraria recarregamento sem fim.
- **Meu proxy pede usuário e senha**: coloque no próprio endereço, `socks5://usuario:senha@host:porta`. Funciona para SOCKS5 e para proxy HTTP. Se a senha tiver `@` ou `:`, codifique esses caracteres (`@` vira `%40`, `:` vira `%3A`) — sem isso não dá para saber onde a senha termina. A senha nunca aparece no registro.
- **"DiscordCameraLive could not unlock this session"**: depois das recargas automáticas o servidor continuou bloqueando. O motivo vem junto, entre parênteses: `nenhuma saida respondeu` (nenhuma candidata passou no teste TLS real naquele momento — tente de novo, ou use Tor / uma proxy sua), `tentativas esgotadas` (duas recargas não bastaram), `roteador desligado` (a regra de rota não pegou — veja o registro).
- **Quer ver o que aconteceu**: rode `/discordcameralive` em qualquer canal, ou abra o arquivo do [registro](#o-registro-o-que-o-plugin-anotou). Ele copia um diagnóstico com o estado das travas, da transmissão, da região e o registro do processo principal — qual proxy foi testada, quanto tempo levou, em que país ela sai e por que foi recusada.
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

## Ainda com problema?

Se nada acima resolveu, abra uma [issue no GitHub](https://github.com/xx7rG/DiscordCameraLive/issues) com o diagnóstico copiado por `/discordcameralive` (ou o conteúdo do arquivo de registro). Veja também [SECURITY.md](../SECURITY.md) se o problema for sobre segurança/privacidade em vez de um bug de uso.
