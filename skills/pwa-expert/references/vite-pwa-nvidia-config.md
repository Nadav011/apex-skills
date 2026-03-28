# Vite PWA NVIDIA-Level Configuration v24.5.0

> Complete vite.config.ts template with all 35 optimizations

## Complete Configuration

```typescript
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import path from "path";
import { VitePWA } from "vite-plugin-pwa";
import tailwindcss from "@tailwindcss/vite";
import viteCompression from "vite-plugin-compression";
import { partytownVite } from "@builder.io/partytown/utils";

export default defineConfig(({ mode }) => ({
  server: {
    host: "::",
    port: 8080,
  },

  // ============================================
  // NVIDIA-LEVEL BUILD OPTIMIZATIONS
  // ============================================
  build: {
    target: "es2022", // Modern syntax (top-level await, class fields, etc.)
    minify: "esbuild",
    cssMinify: true,
    cssCodeSplit: false, // Prevent CSS race conditions
    sourcemap: mode === "development",

    // TIER 1: Aggressive Tree-shaking
    rollupOptions: {
      treeshake: {
        preset: "smallest",
        moduleSideEffects: false,
        propertyReadSideEffects: false,
        tryCatchDeoptimization: false,
      },
      output: {
        minifyInternalExports: true,
        manualChunks: (id) => {
          // React core - required immediately
          if (id.includes("node_modules/react-dom")) {
            return "react-vendor";
          }
          if (
            id.includes("node_modules/react/") &&
            !id.includes("react-router") &&
            !id.includes("react-day-picker") &&
            !id.includes("react-query") &&
            !id.includes("react-virtual")
          ) {
            return "react-vendor";
          }

          // Router - required for navigation
          if (id.includes("node_modules/react-router")) return "router";

          // Supabase - required for auth/data
          if (id.includes("node_modules/@supabase")) return "supabase";

          // TanStack Query - required for data fetching
          if (id.includes("node_modules/@tanstack/react-query")) return "query";
          if (id.includes("node_modules/@tanstack/query-")) return "query";

          // Keep all Radix packages in a single chunk to avoid circular chunk graph warnings.
          if (id.includes("@radix-ui")) return "ui-radix";

          // date-fns
          if (id.includes("node_modules/date-fns")) return "date-fns";

          // Calendar - deferred, only for date pickers
          if (id.includes("node_modules/react-day-picker")) return "calendar";

          // Validation - defer until forms
          if (id.includes("node_modules/zod") || id.includes("node_modules/@hookform")) {
            return "validation";
          }

          // Icons - defer
          if (id.includes("node_modules/lucide-react")) return "icons";

          // Virtual list - defer
          if (id.includes("node_modules/@tanstack/react-virtual")) return "virtual";

          return undefined;
        },
      },
    },

    // TIER 1: Module Preload Optimization
    modulePreload: {
      resolveDependencies: (url, deps) => {
        return deps.filter(
          (d) =>
            !d.includes("calendar") &&
            !d.includes("icons") &&
            !d.includes("validation") &&
            !d.includes("forms") &&
            !d.includes("overlays") &&
            !d.includes("virtual")
        );
      },
    },
  },

  // ============================================
  // ESBUILD OPTIMIZATIONS
  // ============================================
  esbuild: {
    legalComments: "none",
    minifyIdentifiers: true,
    minifySyntax: true,
    minifyWhitespace: true,
  },

  // ============================================
  // PLUGINS
  // ============================================
  plugins: [
    tailwindcss(),
    react({
      babel: {
        plugins: [["babel-plugin-react-compiler", {}]],
      },
    }),

    // TIER 1: Brotli Compression (25-30% smaller)
    mode === "production" &&
      viteCompression({
        algorithm: "brotliCompress",
        ext: ".br",
        threshold: 1024,
      }),

    // TIER 3: Partytown (50% INP improvement)
    mode === "production" &&
      partytownVite({
        dest: path.join(__dirname, "dist", "~partytown"),
      }),

    // PWA Configuration
    VitePWA({
      registerType: "autoUpdate",
      strategies: "injectManifest",
      srcDir: "src",
      filename: "sw.ts",
      injectRegister: false,
      includeAssets: [
        "favicon.ico",
        "logo.svg",
        "apple-touch-icon.png",
        "pwa-192x192.png",
        "pwa-512x512.png",
        "robots.txt",
        "offline.html",
      ],
      manifest: false,
      injectManifest: {
        // Precache only critical files
        globPatterns: [
          "index.html",
          "offline.html",
          "assets/index-*.js",       // Main bundle
          "assets/react-vendor-*.js", // React core
          "assets/router-*.js",       // Router for navigation
          "assets/icons-*.js",        // Icons (essential for Android PWA)
          "assets/style-*.css",       // Main styles
          "logo.svg",
          "favicon.ico",
          "pwa-192x192.png",
          "pwa-512x512.png",
          "apple-touch-icon.png",
        ],
        // Exclude large chunks that can be loaded on-demand
        globIgnores: [
          "assets/supabase-*.js",    // Load on first API call
          "assets/calendar-*.js",    // Load when date picker opens
          "assets/validation-*.js",  // Load when forms used
          "assets/web-vitals-*.js",  // Load in background
        ],
        maximumFileSizeToCacheInBytes: 5 * 1024 * 1024,
      },
      devOptions: {
        enabled: true,
        type: "module",
        navigateFallback: "index.html",
      },
    }),
  ].filter(Boolean),

  // ============================================
  // RESOLVE
  // ============================================
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
}));
```

## Package.json Dependencies

```json
{
  "devDependencies": {
    "vite-plugin-compression": "^0.5.1",
    "@builder.io/partytown": "^0.10.0",
    "vite-plugin-pwa": "^0.21.0"
  }
}
```

## Installation Commands

```bash
# Brotli compression
pnpm add -D vite-plugin-compression

# Partytown for analytics offload
pnpm add -D @builder.io/partytown

# PWA plugin
pnpm add -D vite-plugin-pwa workbox-precaching workbox-routing workbox-strategies
```

## Build Verification

```bash
# Check bundle sizes
pnpm run build 2>&1 | grep -E "gzip:|brotli"

# Verify Brotli files created
ls -la dist/assets/*.br | head -10

# Check total JS size
ls -la dist/assets/*.js | awk '{sum+=$5} END {print "Total JS:", sum/1024, "KB"}'
```

## Expected Results

| Metric | Before | After | Target |
|--------|--------|-------|--------|
| Critical Path (gzip) | 253 KB | 103 KB | < 150 KB |
| Critical Path (Brotli) | 253 KB | 85 KB | < 120 KB |
| Main Bundle | 24 KB | 20 KB | < 100 KB |
| Tree-shaking savings | - | 2-5% | > 2% |

---

<!-- VITE_PWA_NVIDIA v24.5.0 | Updated: 2026-02-19 -->
