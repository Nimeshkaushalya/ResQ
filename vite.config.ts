import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  base: './',
  build: {
    outDir: 'dist',
  },
  // Essential for allowing the app to run on a local network (for testing on phone via IP)
  server: {
    host: true
  }
});