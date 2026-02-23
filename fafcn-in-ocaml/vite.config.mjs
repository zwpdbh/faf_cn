import { defineConfig } from 'vite'
import { nodeResolve } from '@rollup/plugin-node-resolve'

export default defineConfig({
  plugins: [nodeResolve()],
  server: {
    watch: {
      // Only ignore _opam, not _build (we need _build for Melange output)
      ignored: ['**/_opam']
    }
  },
  build: {
    outDir: 'dist'
  }
});
