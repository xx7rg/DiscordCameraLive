# DiscordCameraLive — API de Bug Reports

API HTTP, em Go, que recebe relatos de bug dos apps do DiscordCameraLive e abre
issues no GitHub. Por enquanto só isto: um endpoint autenticado que transforma
um relato (título, descrição, log de diagnóstico e metadados) em uma issue.

- **Stack**: Go 1.26.5+ · [Echo v5](https://github.com/labstack/echo)
- **Dependência externa**: nenhuma além do Echo (o cliente do GitHub é stdlib)

## Como funciona

```
app (GUI/standalone, futuro)              API (este serviço)              GitHub
      │  POST /v1/reports                        │                              │
      │  Authorization: Bearer <API_TOKEN>       │                              │
      │  {title, description, log, meta} ───────►│  valida + monta markdown     │
      │                                          │  POST /repos/{repo}/issues ──►│
      │  201 {issue_number, issue_url} ◄─────────│◄── 201 {number, html_url}    │
```

## Setup

1. **Crie um PAT (fine-grained)** em *GitHub → Settings → Developer settings →
   Fine-grained personal access tokens*, com acesso somente ao repositório
   alvo (`Repository access → Only select repositories`) e permissão
   **Issues: write**.
2. **Crie a label** usada por padrão (`bug`) no repositório alvo — sem ela o
   GitHub responde 422 e a issue não é criada. A lista vem de `ISSUE_LABELS`.
3. **Gere o token compartilhado** com os apps (`API_TOKEN`), por exemplo:
   `openssl rand -hex 32`. Este token será embutido na GUI/standalone quando
   eles ganharem o botão de reportar bug — se vazar, troque o valor e o
   segredo embutido nos apps.

## Rodando

Os comandos desta seção devem ser executados dentro da pasta `api`.

### Bash ou Zsh

```bash
cd api
export API_TOKEN="substitua_por_um_segredo_compartilhado"
export GITHUB_TOKEN="substitua_pelo_pat_do_github"
go run ./cmd/api
```

### PowerShell

```powershell
Set-Location api
$env:API_TOKEN = 'substitua_por_um_segredo_compartilhado'
$env:GITHUB_TOKEN = 'substitua_pelo_pat_do_github'
go run ./cmd/api
```

Variáveis (todas em `.env.example`):

| Variável | Obrig. | Padrão | Descrição |
|---|---|---|---|
| `API_TOKEN` | sim | — | segredo compartilhado com os apps (Bearer) |
| `GITHUB_TOKEN` | sim | — | PAT com permissão Issues: write no repo alvo |
| `GITHUB_REPO` | não | `xx7rG/DiscordCameraLive` | `owner/repo` da issue |
| `ISSUE_LABELS` | não | `bug` | labels separadas por vírgula (precisam existir no repo) |
| `PORT` | não | `8080` | porta HTTP |
| `RATE_LIMIT` | não | `60` | requisições por minuto por IP |
| `MAX_LOG_BYTES` | não | `262144` | teto do campo `log` (256 KB) |
| `LOG_LEVEL` | não | `info` | `debug`, `info`, `warn`, `error` |

O arquivo `.env.example` é apenas um modelo. A API lê as variáveis do ambiente
do processo e não carrega esse arquivo automaticamente.

### Testar com curl

Os exemplos abaixo usam Bash ou Zsh e devem ser executados em outro terminal,
com a API já iniciada. Defina `API_TOKEN_VALUE` com o mesmo segredo configurado
em `API_TOKEN` no servidor.

```bash
API_TOKEN_VALUE='substitua_pelo_mesmo_segredo_do_servidor'

curl -s localhost:8080/healthz

# sem token → 401
curl -s -X POST localhost:8080/v1/reports \
  -H 'Content-Type: application/json' \
  -d '{"title":"x"}'

# validação → 400
curl -s -X POST localhost:8080/v1/reports \
  -H "Authorization: Bearer ${API_TOKEN_VALUE}" \
  -H 'Content-Type: application/json' \
  -d '{"title":""}'
```

Para confirmar o fluxo até o GitHub sem criar uma issue, inicie outra instância
com um token do GitHub inválido:

```bash
# primeiro terminal, dentro de api
API_TOKEN=dev GITHUB_TOKEN=fake GITHUB_REPO=xx7rG/DiscordCameraLive go run ./cmd/api

# segundo terminal
curl -s -X POST localhost:8080/v1/reports \
  -H 'Authorization: Bearer dev' \
  -H 'Content-Type: application/json' \
  -d '{"title":"Teste","log":"linha do log","meta":{"app":"cli","os":"linux"}}'
```

A resposta esperada é `502`: a API aceita o relato e o GitHub recusa o token
inválido. Não use esse teste com um `GITHUB_TOKEN` real, pois ele criaria uma
issue.

No PowerShell, use `curl.exe` para evitar o alias de `Invoke-WebRequest`:

```powershell
# primeiro terminal, dentro de api
$env:API_TOKEN = 'dev'
$env:GITHUB_TOKEN = 'fake'
$env:GITHUB_REPO = 'xx7rG/DiscordCameraLive'
go run ./cmd/api

# segundo terminal
curl.exe -s -X POST http://localhost:8080/v1/reports -H "Authorization: Bearer dev" -H "Content-Type: application/json" --data '{"title":"Teste","log":"linha do log","meta":{"app":"cli","os":"windows"}}'
```

### Docker

Execute este bloco a partir da raiz do repositório, onde a pasta `api` está
disponível:

```bash
docker build -t golive-api ./api
docker run --rm -p 8080:8080 \
  -e API_TOKEN=... -e GITHUB_TOKEN=... \
  -e GITHUB_REPO=xx7rG/DiscordCameraLive \
  golive-api
```

No PowerShell, o mesmo `docker run` pode ser escrito em uma única linha:

```powershell
docker run --rm -p 8080:8080 -e API_TOKEN=... -e GITHUB_TOKEN=... -e GITHUB_REPO=xx7rG/DiscordCameraLive golive-api
```

## Endpoints

### `POST /v1/reports`

Body (JSON):

```json
{
  "title": "Go Live não sobe após atualização",
  "description": "passos de reprodução...",
  "log": "====\nabrindo | win32 x64 | electron 42...",
  "meta": { "app": "golive-gui", "version": "1.2.0", "os": "linux x64" }
}
```

- `title` — obrigatório, até 200 caracteres (espaços nas bordas são removidos).
- `description` — opcional, até 8 KB.
- `log` — opcional; truncado em `MAX_LOG_BYTES`; o conteúdo é neutralizado para
  não quebrar o bloco de código da issue.
- `meta` — opcional; pares `chave: valor` exibidos numa tabela na issue.

Resposta `201`:

```json
{ "issue_number": 123, "issue_url": "https://github.com/.../issues/123" }
```

### `GET /healthz`

`200 {"status":"ok"}` — sem autenticação, para healthcheck.

## Erros

| Status | Quando | Body |
|---|---|---|
| `400` | payload inválido (JSON, title, tamanhos) | `{"message": "..."}` |
| `401` | token ausente ou errado | `{"message": "..."}` |
| `413` | corpo acima de 512 KB | `{"message": "..."}` |
| `429` | rate limit por IP excedido (header `Retry-After`) | `{"message": "..."}` |
| `404` / `405` | rota/método inexistente | `{"message": "..."}` |
| `502` | o GitHub recusou (auth, label inexistente, etc.) | detalhe só no log do servidor |

## Operação

- **TLS termina no reverse proxy** (Caddy, nginx, Traefik) — a API não fala
  TLS sozinha. Atrás do proxy, o rate limit usa o IP real do cliente por
  `X-Forwarded-For` (o Echo só confia em XFF vindo de IP de loopback ou rede
  privada).
- **Rate limit em memória**: suficiente para uma instância; com várias
  instâncias atrás de um load balancer, cada uma tem a própria contagem e o
  Redis seria o próximo passo (fora de escopo por enquanto).
- Desligamento gracioso em `SIGINT`/`SIGTERM` (até 10 s para requisições em
  andamento).

## Testes

```sh
cd api
go vet ./...
go test ./...
```

Cobertura: validação do payload e montagem do markdown (`internal/bugreport`),
cliente GitHub contra um fake HTTP (`internal/gh`), e os endpoints completos
com auth, rate limit, body limit e erros (`internal/server`).

## Integração futura (fora deste escopo)

A GUI (Electron) e o standalone ganharão um botão **"Reportar bug"** que
monta o relato — com o `discordcameralive.log` e os metadados do sistema — e chama
`POST /v1/reports` com o `API_TOKEN` embutido. A resposta traz a URL da issue
para mostrar ao usuário.
