import { sveltekit } from '@sveltejs/kit/vite'
import { enhancedImages } from '@sveltejs/enhanced-img'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [enhancedImages(), sveltekit()],
  test: {
    pool: 'forks',
    poolOptions: { forks: { singleFork: false } },
    environment: 'happy-dom',
    setupFiles: ['./vitest-setup.ts'],
  },
})
