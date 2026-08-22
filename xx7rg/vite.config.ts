import { defineConfig } from 'vite'
import electron from 'vite-plugin-electron'
import renderer from 'vite-plugin-electron-renderer'

export default defineConfig({
  base: './',
  plugins: [
    electron([
      {
        entry: 'electron/main.ts',
        vite: {
          build: {
            rollupOptions: {
              external: ['original-fs'],
            },
          },
        },
      },
      {
        entry: 'electron/preload.ts',
        onstart(options) {
          options.reload()
        },
        vite: {
          build: {
            // package.json tem "type": "module", entao o vite-plugin-electron builda tudo em
            // ESM por padrao (build.lib.formats, nao rollupOptions/rolldownOptions -- e quem
            // decide o formato de verdade em modo lib). Com sandbox:true o preload roda num
            // loader que so aceita CommonJS -- em ESM ele falha em silencio, o contextBridge
            // nunca chama, e window.api fica undefined pro renderer inteiro (TypeError na
            // primeira leitura, "Cannot read properties of undefined (reading 'platform')").
            lib: {
              formats: ['cjs'],
            },
          },
        },
      },
    ]),
    renderer(),
  ],
})
