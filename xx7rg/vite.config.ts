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
      },
    ]),
    renderer(),
  ],
})
