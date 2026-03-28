# Turbopack & Build Performance - Comprehensive Reference

> **APEX-PERF v24.7.0** | Domain: Performance/Build
> Consolidates: turbopack-optimization

---

## 1. TURBOPACK OVERVIEW

### Performance Gains

| Metric | Webpack | Turbopack | Improvement |
|--------|---------|-----------|-------------|
| Dev server startup | 12-30s | 1-3s | 10-14x faster |
| HMR (Hot Module Replacement) | 300-800ms | 10-50ms | 15-30x faster |
| Route compilation | 1-5s | 50-200ms | 10-25x faster |
| Full build | 60-180s | 15-45s | 3-4x faster |

### Default in Next.js 16

```typescript
// next.config.ts
// Turbopack is the DEFAULT build system in Next.js 16
// No configuration needed for standard usage

const nextConfig = {
  // Turbopack-specific options (optional):
  turbopack: {
    // Module resolution aliases
    resolveAlias: {
      '@/': './src/',
    },
  },
};

export default nextConfig;
```

---

## 2. PERSISTENT CACHING

### File System Cache

```typescript
// next.config.ts
const nextConfig = {
  experimental: {
    // Enable persistent caching across restarts
    turbo: {
      unstable_persistentCaching: true,
    },
  },
};

// Results:
// First startup:  ~3s (cold cache)
// Second startup: ~0.5s (warm cache, 10-14x faster)
// Subsequent HMR: <10ms
```

### Cache Location and Management

```bash
# Cache stored in .next/cache/turbopack/
# Clear cache if needed:
rm -rf .next/cache/turbopack/

# Or clean all:
pnpm next clean
```

### CI/CD Cache Integration

```yaml
# .github/workflows/build.yml
- name: Cache Turbopack
  uses: actions/cache@v4
  with:
    path: |
      .next/cache/turbopack
    key: turbopack-${{ runner.os }}-${{ hashFiles('pnpm-lock.yaml') }}-${{ hashFiles('**/*.ts', '**/*.tsx') }}
    restore-keys: |
      turbopack-${{ runner.os }}-${{ hashFiles('pnpm-lock.yaml') }}-
      turbopack-${{ runner.os }}-

- name: Build
  run: pnpm build
```

---

## 3. BUILD OPTIMIZATION

### Parallel Compilation

Turbopack automatically parallelizes compilation across CPU cores. Key optimizations:

```typescript
// 1. Module graph parallelism
// Turbopack builds the module graph incrementally
// Multiple modules compile simultaneously

// 2. Incremental computation
// Only recompiles changed files and their dependents
// Uses fine-grained invalidation tracking

// 3. Lazy compilation in dev
// Only compiles routes when accessed
// Unused routes don't consume build time
```

### optimizePackageImports

```typescript
// next.config.ts
const nextConfig = {
  experimental: {
    // Optimize barrel imports for these packages
    optimizePackageImports: [
      'lucide-react',
      '@radix-ui/react-icons',
      'date-fns',
      'lodash-es',
      '@heroicons/react',
    ],
  },
};

// Effect: import { Search } from 'lucide-react'
// Turbopack only includes the Search icon, not all 1000+ icons
```

### TypeScript Compilation

```typescript
// tsconfig.json optimizations for Turbopack
{
  "compilerOptions": {
    // Turbopack uses SWC for TypeScript compilation
    // These settings affect type checking only:
    "strict": true,
    "moduleResolution": "bundler", // Optimal for Turbopack
    "target": "ES2022",
    "module": "ESNext",
    "jsx": "preserve", // Let Turbopack/SWC handle JSX

    // Path aliases (also configure in next.config.ts)
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

---

## 4. DEV SERVER OPTIMIZATION

### Reducing Cold Start

```typescript
// 1. Minimize imported modules in layout.tsx
// BAD: Importing heavy library at root
import { Chart } from 'chart.js'; // 200KB loaded on every page

// GOOD: Dynamic import where needed
const Chart = dynamic(() => import('chart.js'), { ssr: false });

// 2. Use Server Components for data-heavy imports
// Heavy libraries in Server Components don't affect dev HMR
```

### HMR Performance Tips

```
Tips for optimal HMR performance:

1. Keep component files < 150 lines
   - Smaller files = faster recompilation

2. Avoid circular dependencies
   - Turbopack handles them but they slow invalidation

3. Use path aliases consistently
   - @/ prefix for all imports
   - Helps Turbopack's module graph

4. Minimize barrel file usage
   - Direct imports are faster to invalidate
   - import { Button } from '@/components/Button'
   - NOT import { Button } from '@/components'

5. Split CSS modules
   - Per-component CSS modules compile independently
   - Global CSS changes invalidate more
```

---

## 5. PRODUCTION BUILD

### Build Analysis

```bash
# Analyze build output
ANALYZE=true pnpm build

# Build with timing information
NEXT_TELEMETRY_DEBUG=1 pnpm build

# Build output summary
pnpm build 2>&1 | grep -E "Route|Size|First Load"
```

### Build Output Optimization

```
Route (app)                              Size     First Load JS
┌ / (static)                             5.2 kB        89 kB
├ /dashboard (dynamic)                   12.1 kB       96 kB
├ /products (static, cached 1h)          8.4 kB        92 kB
├ /products/[id] (dynamic)               6.7 kB        91 kB
└ /api/[...] (API routes)               0 B            0 B

Target: First Load JS < 100KB per route
```

### Deployment Configuration

```json
// vercel.json
{
  "buildCommand": "pnpm build",
  "framework": "nextjs",
  "regions": ["fra1"],
  "crons": [],
  "headers": [
    {
      "source": "/_next/static/(.*)",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "public, max-age=31536000, immutable"
        }
      ]
    }
  ]
}
```

---

## 6. TROUBLESHOOTING

### Common Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| Slow initial dev startup | Large node_modules | Use optimizePackageImports |
| HMR not updating | Circular dependency | Check import graph |
| Build OOM | Large project | Increase Node memory: `NODE_OPTIONS='--max-old-space-size=8192'` |
| Cache stale | Corrupted cache | `rm -rf .next/cache` |
| Type errors in build | SWC vs tsc difference | Run `pnpm tsc --noEmit` separately |

### Debug Commands

```bash
# Verbose build output
TURBOPACK_DEBUG=1 pnpm dev

# Profile build performance
TURBOPACK_PROFILE=1 pnpm build

# Check module graph
npx next info
```

---

## 7. CHECKLIST

```markdown
## Turbopack & Build Performance Checklist

### Configuration
- [ ] Turbopack is default (Next.js 16)
- [ ] persistentCaching enabled for dev
- [ ] optimizePackageImports configured
- [ ] moduleResolution: "bundler" in tsconfig

### Dev Performance
- [ ] Dev startup < 3s (cold) / < 0.5s (warm)
- [ ] HMR < 50ms
- [ ] No circular dependencies
- [ ] Direct imports (not barrel files)
- [ ] Components < 150 lines

### Build Performance
- [ ] Build time tracked in CI
- [ ] Turbopack cache in CI/CD
- [ ] First Load JS < 100KB per route
- [ ] ANALYZE=true reviewed periodically
- [ ] Static routes where possible

### Deployment
- [ ] Static assets: immutable cache headers
- [ ] Edge regions configured
- [ ] Build output sizes within budget
```

---

<!-- TURBOPACK_BUILD_PERF v24.7.0 | Turbopack, persistent caching, build optimization -->
