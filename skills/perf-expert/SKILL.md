---
name: perf-expert
description: "Use when user wants to analyze or improve web performance — Core Web Vitals (LCP, INP, CLS), Lighthouse audits, bundle size analysis, runtime profiling, image/font optimization, caching strategy, or React/Turbopack performance"
---
# Performance Expert Skill

> **APEX-PERF v24.7.0** | Supreme Performance Analysis Skill
> Lighthouse, Bundle Analysis, Core Web Vitals, Runtime Profiling
> **Replaces:** standalone lighthouse skill, apex-perf archive

---

## Overview

The Performance Expert skill provides comprehensive web performance analysis, optimization, and monitoring capabilities. It consolidates 43 specialized performance reference files into 16 focused, production-grade documents covering every aspect of modern web performance for 2026.

**Agent Delegation:**
- `perf-analyzer` (Opus 4.6) -- orchestration, architecture, performance-critical analysis
- `lighthouse-auditor` (Sonnet 4.6) -- Lighthouse CI, audit interpretation, scoring
- `bundle-analyzer` (Sonnet 4.6) -- bundle composition, dependency cost, tree shaking

---

## Commands

| # | Command | Description |
|---|---------|-------------|
| 1 | `/perf-expert` | Load full skill + all references |
| 2 | `/perf-audit` | Run complete performance audit (Lighthouse + Bundle + CWV + Runtime) |
| 3 | `/perf-cwv` | Analyze Core Web Vitals (LCP, INP, CLS, FCP, TTFB, TBT) |
| 4 | `/perf-lighthouse` | Run Lighthouse CI audit with APEX thresholds |
| 5 | `/perf-bundle` | Analyze bundle size, composition, and dependencies |
| 6 | `/perf-runtime` | Runtime profiling: CPU, memory, render, long tasks |
| 7 | `/perf-images` | Image and font optimization audit |
| 8 | `/perf-network` | Network payload, compression, and transfer analysis |
| 9 | `/perf-cache` | Cache strategy, streaming SSR, and hydration analysis |
| 10 | `/perf-css` | CSS performance: containment, content-visibility, animations |
| 11 | `/perf-third-party` | Third-party script audit and optimization |
| 12 | `/perf-react` | React Compiler performance and RSC optimization |
| 13 | `/perf-turbopack` | Turbopack and build performance analysis |
| 14 | `/perf-rum` | RUM vs Lab data strategy and monitoring setup |
| 15 | `/perf-hints` | Resource hints, preloading, and fetch priority audit |
| 16 | `/perf-modern-apis` | Modern browser API adoption (LoAF, Scheduler, Speculation Rules) |
| 17 | `/perf-advanced` | Advanced APIs (WebGPU, WebCodecs, WASM, Compression Streams) |
| 18 | `/perf-report` | Generate comprehensive performance report |
| 19 | `/perf-budget` | Check all performance budgets (bundle, payload, CWV) |
| 20 | `/perf-compare` | Before/after performance comparison |
| 21 | `/perf-ci` | Set up Lighthouse CI + bundle checks in GitHub Actions |
| 22 | `/perf-fix [metric]` | Fix specific metric (lcp, inp, cls, fcp, ttfb, tbt, bundle) |
| 23 | `/perf-checklist` | Print complete performance optimization checklist |

---

## 9-Step Performance Workflow

```
Step 1: MEASURE (Baseline)
  ├── Lighthouse audit (lab data)
  ├── CrUX/RUM data (field data)
  ├── Bundle analysis
  └── Runtime profiling

Step 2: IDENTIFY (Bottlenecks)
  ├── Largest Contentful Paint element
  ├── Interaction to Next Paint handlers
  ├── Cumulative Layout Shift sources
  ├── Long tasks / main thread blocking
  └── Heavy dependencies / unused code

Step 3: PRIORITIZE (Impact Matrix)
  ├── BLOCK: CWV failures, bundle >120KB, Lighthouse <70
  ├── WARN: CWV borderline, bundle >100KB, Lighthouse <85
  └── INFO: Optimization opportunities, modern API adoption

Step 4: OPTIMIZE (Apply Fixes)
  ├── LCP: preload hero, optimize images, streaming SSR
  ├── INP: scheduler.yield(), code splitting, event delegation
  ├── CLS: explicit dimensions, font display, skeleton loading
  ├── Bundle: tree shaking, dynamic imports, dependency replacement
  └── Runtime: virtualization, Web Workers, requestIdleCallback

Step 5: VERIFY (Gate Checks)
  ├── All 30 verification gates must pass
  ├── Lighthouse CI thresholds met
  ├── Bundle budgets within limits
  └── CWV targets achieved

Step 6: MONITOR (Continuous)
  ├── RUM with web-vitals 5.1.0
  ├── CrUX monthly review
  ├── Vercel Speed Insights
  └── Sentry performance monitoring

Step 7: PREVENT (CI/CD Gates)
  ├── Lighthouse CI on every PR
  ├── Bundle size checks
  ├── Performance budgets
  └── Automated regression detection

Step 8: ITERATE (Continuous Improvement)
  ├── Review field data trends
  ├── Adopt new browser APIs
  ├── Update optimization strategies
  └── Refine budgets based on data

Step 9: REPORT (Stakeholder Communication)
  ├── CWV scorecard
  ├── Bundle composition breakdown
  ├── Before/after comparisons
  └── Recommendations with impact estimates
```

---

## APEX Performance Thresholds

### Core Web Vitals Targets

| Metric | Google "Good" | APEX Target | APEX Stretch |
|--------|---------------|-------------|--------------|
| LCP | <= 2.5s | < 1.5s | < 1.0s |
| INP | <= 200ms | < 150ms | < 100ms |
| CLS | <= 0.1 | < 0.05 | 0 |
| FCP | <= 1.8s | < 1.2s | < 0.8s |
| TTFB | <= 800ms | < 400ms | < 200ms |
| TBT | <= 200ms | < 150ms | < 100ms |
| SI | <= 3.4s | < 2.0s | < 1.5s |

### Bundle Budgets (gzipped)

| Resource | Budget | APEX Target |
|----------|--------|-------------|
| Initial JS | < 120KB | < 100KB |
| Initial CSS | < 30KB | < 20KB |
| Per-route JS chunk | < 50KB | < 30KB |
| Hero image | < 100KB | < 50KB |
| Total initial load | < 500KB | < 350KB |

### Ideal Bundle Composition

| Category | Target Size | Max % |
|----------|-------------|-------|
| Framework (React/Next) | 35KB | 35% |
| UI Components | 20KB | 20% |
| State Management | 10KB | 10% |
| Utilities | 10KB | 10% |
| Business Logic | 15KB | 15% |
| Third-party | 10KB | 10% |

### Runtime Targets

| Metric | Target |
|--------|--------|
| Long tasks | 0 tasks > 50ms |
| DOM elements | < 1000 (APEX), < 1500 (Lighthouse) |
| DOM depth | < 32 |
| DOM children per node | < 60 |
| Layout thrashing | forcedStyleAndLayoutDuration < 30ms |
| Memory leaks | 0 detached DOM nodes |
| Unused code | < 5% |

---

## Verification Gates (30 Gates, 5 Clusters)

### Cluster 1: Core Web Vitals (BLOCK)

| # | Gate | Threshold | Severity |
|---|------|-----------|----------|
| 1 | LCP (p75 field) | <= 2.5s | BLOCK |
| 2 | LCP (lab) | < 1.5s | BLOCK |
| 3 | INP (p75 field) | <= 200ms | BLOCK |
| 4 | INP (lab) | < 150ms | BLOCK |
| 5 | CLS (p75 field) | <= 0.1 | BLOCK |
| 6 | CLS (lab) | < 0.05 | BLOCK |
| 7 | FCP (lab) | < 1.2s | BLOCK |
| 8 | TTFB (lab) | < 400ms | BLOCK |

### Cluster 2: Bundle Size (BLOCK/WARN)

| # | Gate | Threshold | Severity |
|---|------|-----------|----------|
| 9 | Initial JS (gz) | < 120KB | BLOCK |
| 10 | Initial JS (gz) APEX | < 100KB | WARN |
| 11 | Per-route chunk (gz) | < 50KB | BLOCK |
| 12 | Total initial (gz) | < 500KB | BLOCK |
| 13 | Unused code | < 10% | WARN |
| 14 | Duplicate packages | 0 | WARN |

### Cluster 3: Lighthouse Score (BLOCK/WARN)

| # | Gate | Threshold | Severity |
|---|------|-----------|----------|
| 15 | Performance score | >= 70 | BLOCK |
| 16 | Performance score APEX | >= 90 | WARN |
| 17 | Accessibility score | >= 90 | BLOCK |
| 18 | Best Practices score | >= 90 | BLOCK |
| 19 | SEO score | >= 90 | WARN |
| 20 | No render-blocking resources | 0 | WARN |

### Cluster 4: Runtime (WARN)

| # | Gate | Threshold | Severity |
|---|------|-----------|----------|
| 21 | Long tasks > 50ms | 0 on critical path | WARN |
| 22 | TBT | < 200ms | WARN |
| 23 | TBT APEX | < 100ms | WARN |
| 24 | DOM elements | < 1500 | WARN |
| 25 | Memory leaks | 0 | WARN |
| 26 | Layout thrashing | < 30ms forced | WARN |

### Cluster 5: Modern Optimization (WARN/INFO)

| # | Gate | Threshold | Severity |
|---|------|-----------|----------|
| 27 | Image formats | WebP/AVIF served | WARN |
| 28 | Compression | Brotli enabled | WARN |
| 29 | Resource hints | Preconnect critical origins | INFO |
| 30 | Cache headers | Immutable for static assets | INFO |

---

## Reference Files

| # | File | Content | Source Files |
|---|------|---------|--------------|
| 1 | `core-web-vitals.md` | LCP, INP, CLS, FCP, TTFB, TBT, Speed Index | core-web-vitals, tbt-analysis, speed-index, dom-size |
| 2 | `lighthouse-ci.md` | Lighthouse 13.0.3, @lhci/cli, CI integration, custom audits | lighthouse-ci |
| 3 | `bundle-optimization.md` | Bundle size, composition, tree shaking, dependencies | bundle-optimization, bundle-composition, dependency-cost, unused-code |
| 4 | `image-font-optimization.md` | Image formats, next/image, font loading, responsive | image-optimization |
| 5 | `rum-vs-lab.md` | CrUX, RUM, field vs lab, monitoring strategy | rum-vs-lab |
| 6 | `resource-hints-priorities.md` | Preload, prefetch, preconnect, fetchPriority, Early Hints | resource-hints, early-hints |
| 7 | `runtime-profiling.md` | CPU, memory, render, long tasks, layout thrashing | runtime-profiling, long-tasks, layout-thrashing, code-analysis |
| 8 | `cache-streaming-hydration.md` | cacheComponents, streaming SSR, RSC, hydration | cache-components, streaming-ssr, hydration-analysis, ppr-optimization |
| 9 | `modern-browser-apis.md` | LoAF, Scheduler API, Speculation Rules, View Transitions | loaf-attribution, scheduler-api, speculation-rules, view-transitions |
| 10 | `css-performance.md` | Containment, content-visibility, scroll animations, render blocking | css-containment, content-visibility, render-blocking, scroll-animations |
| 11 | `third-party-audit.md` | Third-party cost, Script strategies, Partytown, facades | third-party-audit |
| 12 | `react-compiler-perf.md` | React Compiler, React 19.2 features, RSC optimization | react-compiler-deep, react-19-2-features |
| 13 | `turbopack-build-perf.md` | Turbopack, persistent caching, build optimization | turbopack-optimization |
| 14 | `network-compression.md` | Payloads, Brotli/gzip, API optimization, adaptive loading | network-payloads, compression-streams, adaptive-loading |
| 15 | `advanced-apis.md` | WebGPU, WebCodecs, WASM, Background Sync, BFCache, requestIdleCallback | webgpu-compute, webcodecs, webassembly-perf, background-sync, bfcache-optimization, request-idle-callback |
| 16 | `perf-report-template.md` | Report template, scorecards, before/after, recommendations | Generated from all sources |

---

## Tech Stack

| Tool | Version | Purpose |
|------|---------|---------|
| Lighthouse | 13.0.3 | Lab performance auditing |
| @lhci/cli | 0.15.1 | Lighthouse CI integration |
| web-vitals | 5.1.0 | RUM Core Web Vitals |
| @next/bundle-analyzer | latest | Bundle visualization |
| source-map-explorer | latest | Source map analysis |
| depcheck | latest | Unused dependency detection |
| Puppeteer | latest | Automated coverage collection |
| ts-morph | latest | Unused export detection |
| React Compiler | stable | Auto-memoization (React 19.2.4) |
| Turbopack | default | Build system (Next.js 16.1.6) |

---

## Quick Start

### 1. Run Full Audit
```bash
# Lighthouse
npx @lhci/cli autorun --config=lighthouserc.js

# Bundle analysis
ANALYZE=true pnpm run build

# CWV check
npx web-vitals-cli https://your-site.com
```

### 2. Check Budgets
```bash
# Bundle size
npx bundlesize --config bundlesize.config.json

# Unused deps
npx depcheck .

# Coverage
npx puppeteer-coverage http://localhost:3000
```

### 3. Set Up CI
```yaml
# .github/workflows/perf.yml
name: Performance Gate
on: [pull_request]
jobs:
  lighthouse:
    runs-on: [self-hosted, linux, x64, pop-os]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '24'
          cache: 'pnpm'
      - run: pnpm install
      - run: pnpm build
      - run: npx @lhci/cli autorun
  bundle:
    runs-on: [self-hosted, linux, x64, pop-os]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '24'
          cache: 'pnpm'
      - run: pnpm install
      - run: ANALYZE=true pnpm build
      - run: npx bundlesize
```

---

## Performance Checklist

### Pre-Launch
- [ ] All 30 verification gates passing
- [ ] Lighthouse Performance >= 90
- [ ] LCP < 1.5s (lab), <= 2.5s (field p75)
- [ ] INP < 150ms (lab), <= 200ms (field p75)
- [ ] CLS < 0.05 (lab), <= 0.1 (field p75)
- [ ] Initial JS < 100KB gzipped
- [ ] Images in WebP/AVIF with responsive sizes
- [ ] Brotli compression enabled
- [ ] Resource hints configured (preconnect, preload)
- [ ] Cache headers set (immutable for static)

### Post-Launch
- [ ] RUM monitoring active (web-vitals)
- [ ] CrUX data collection confirmed
- [ ] Performance alerts configured
- [ ] Lighthouse CI in pipeline
- [ ] Bundle size checks in CI
- [ ] Monthly performance review scheduled

### Continuous
- [ ] Review field data weekly
- [ ] Compare lab vs field trends
- [ ] Update budgets based on data
- [ ] Adopt new browser APIs when stable
- [ ] Audit third-party scripts quarterly
- [ ] Review dependency costs monthly

---

## Related Skills

| Skill | Relationship |
|-------|-------------|
| `/verify-app` | Includes performance verification gates |
| `/frontend-rules` | Frontend coding standards affecting performance |
| `/a11y` | Accessibility requirements that impact performance choices |
| `/testing-rules` | Performance testing patterns |

---

<!-- PERF_EXPERT v24.7.0 | 23 commands, 30 gates (5 clusters), 9-step workflow, 16 reference files | Consolidates 43 archived apex-perf files -->
