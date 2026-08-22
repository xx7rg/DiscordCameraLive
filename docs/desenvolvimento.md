← [Voltar ao README](../README.md)

# Desenvolvimento

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

api/
└── ...                             # API Go que recebe relatórios de bug da GUI e abre issue no GitHub

tests/
├── test-posix.sh                  # suíte de portabilidade: roda os instaladores em containers
│                                  #   (podman/docker) com sh, dash, ash, bash, zsh, ksh e mksh
├── test-exit-refresh.sh           # re-seleção de saída em runtime do standalone
├── test-heartbeat.sh              # o batimento de 30s que revalida a saída ativa e as reservas
├── test-proxy-artix.sh            # fluxo de proxy manual ponta a ponta (Artix/OpenRC)
└── test-artix-gui.sh              # GUI ponta a ponta (AppImage) em Wayland/Vulkan headless

assets/
└── instalacao.gif                 # o vídeo do começo do README
```

## Rodando localmente

**GUI (`xx7rg/`):**

```bash
cd xx7rg
npm ci
npm run dev          # abre a janela Electron em modo dev
npm run compile      # tsc + build de produção (renderer, main, preload)
```

`npm run compile` roda `scripts/sync-bypass.mjs` primeiro, que regrava `electron/bypass.ts` a partir de `standalone/discordcameralive.js` — os dois **precisam** ficar idênticos, porque a GUI embute o bypass como string (o electron-builder empacota tudo num `.asar`, e um arquivo solto não sobreviveria a isso). Rode `node scripts/sync-bypass.mjs --check` para só validar sem escrever (é o que o CI usa).

**API (`api/`):** ver [api/README.md](../api/README.md).

## Testes

- **Go**: `cd api && go test ./... && go vet ./...`
- **GUI**: `cd xx7rg && npm run compile` (não há suíte de testes JS ainda — `tsc` cobre tipos, `vite build` cobre o bundle)
- **Instaladores/standalone**: os scripts em `tests/` precisam de podman ou docker (`RUNTIME=docker ./tests/test-posix.sh`, por exemplo)

## CI

`.github/workflows/ci.yml` roda em todo push/PR: compila a GUI, testa e vetta a API, e roda os testes shell dos instaladores. `.github/workflows/build-gui.yml` é manual, só para releases — gera os três instaladores (Windows, macOS, Linux) e publica na release do GitHub.
