import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/services': {
        target: 'https://orgfarm-a90087f4cc-dev-ed.develop.my.salesforce.com',
        changeOrigin: true,
        rewrite: (path) => path,
      },
    },
  },
})
