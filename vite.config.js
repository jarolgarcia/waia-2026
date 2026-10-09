import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";
import { fileURLToPath, URL } from "node:url";

export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./src", import.meta.url)),
    },
  },
  server: {
    host: "127.0.0.1",
    port: 5173,
    strictPort: false,
    open: true,
    proxy: {
      "/waia-api": {
        target: "http://localhost/Waia-main/backend/api",
        changeOrigin: false,
        rewrite: (path) => path.replace(/^\/waia-api/, ""),
      },
    },
  },
  preview: {
    host: "127.0.0.1",
    port: 4173,
  },
});
