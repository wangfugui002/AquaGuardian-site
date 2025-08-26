import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  // 本地开发时不需要base路径，生产构建时会自动处理
  base: process.env.NODE_ENV === 'production' ? '/AquaGuardian-site/' : '/',
  server: {
    port: 3002, // 修改为您使用的端口
    open: true,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
        secure: false
      }
    }
  },
  build: {
    outDir: 'dist',
    assetsDir: 'assets'
  }
}) 