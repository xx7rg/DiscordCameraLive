← [Voltar ao README](../README.md) · [Instalação](instalacao.md) · [Solução de problemas](solucao-de-problemas.md)

# Como funciona

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

- **Só funciona no Discord para computador** com Equicord ou Vencord injetado, incluindo o Discord instalado por Flatpak. **Vesktop** tem suporte manual — veja [Instalação no Vesktop](instalacao.md#instalação-no-vesktop). Equibop e Snap não: o Equibop traz o mod embutido e não carrega de um checkout, e o Snap fica dentro de um squashfs somente leitura. Não funciona na versão de navegador/extensão.
- **Proxies gratuitas são fracas para anonimato**: o operador da proxy vê seus metadados de conexão, muitas estão mortas ou lentas, e o Discord pode pedir captcha para IPs de proxies públicas. Para anonimato real, **use Tor**.
- Usar clientes modificados viola os Termos de Serviço do Discord. Use por sua conta e risco.
- A proxy carrega **só o gateway** (e também o login, se você ativar isso na configuração). Todo o resto — API, CDN, anexos, atualizações e a mídia das calls — sai direto com seu IP real o tempo todo.
- **O plugin nunca te deixa sem Discord.** Quem conversa com a proxy é um roteador local do plugin: se a saída falhar, aquela conexão cai para a direta e a busca por outra recomeça em segundo plano. O pior caso é abrir o Discord *sem* Go Live, nunca ficar sem conseguir abrir.

Riscos de segurança e o que o programa toca no seu sistema estão detalhados em [SECURITY.md](../SECURITY.md).

## As duas travas

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

### O que o standalone simplifica

O [modo standalone](instalacao.md#modo-standalone-só-o-discord-sem-equicord-e-sem-vencord) não tem plugin, então não pode aplicar a Trava 1 por patch. Ele funciona porque a trava do cliente só existe *depois* de o servidor te atribuir o experimento — e a atribuição parte do IP de origem do gateway. Com o gateway saindo por um IP não bloqueado, **o experimento nunca chega a ser atribuído**, e os botões de câmera/Go Live continuam livres por padrão, sem precisar de nenhum patch.

Sem a parte do cliente, sobra só o roteador do gateway: o standalone instala a mesma regra PAC por host do plugin, direto no `app.asar` do Discord, sem precisar de Equicord ou Vencord por baixo.

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
