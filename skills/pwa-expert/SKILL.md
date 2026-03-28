---
name: pwa-expert
description: Use when user wants to 1. SCAN package.json, next.config, manifest 2. RESEARCH Context7 for vite-plugin-pwa + Workbox patterns
---

# PWA EXPERT v24.7.0 NVIDIA-LEVEL + ANDROID RENDERING

> vite-plugin-pwa + Workbox service workers, offline-first, Lighthouse 100, **35 NVIDIA optimizations**, **8 Android rendering fixes**. **NEVER use next-pwa.**

## COMMANDS
| Command | Action |
|---------|--------|
| `/pwa setup` | Initialize vite-plugin-pwa, manifest, icons |
| `/pwa audit` | Lighthouse PWA audit + fix plan |
| `/pwa debug` | SW registration troubleshooting |
| `/pwa manifest` | Validate/fix manifest.json |
| `/pwa icons` | Generate 192, 512, maskable PNGs |
| `/pwa offline` | Setup offline-first with OPFS |
| `/pwa cache` | Configure caching strategies |
| `/pwa test` | Test SW lifecycle via Playwright |
| `/pwa security` | Configure CSP, COOP/COEP |
| `/pwa doctor` | Full 30-gate health check |
| `/pwa nvidia` | Apply 35 NVIDIA-level optimizations |
| `/pwa brotli` | Setup Brotli compression |
| `/pwa streaming` | Configure streaming responses |
| `/pwa partytown` | Setup analytics offload |
| `/pwa android-rendering-audit` | Full Android rendering issues audit |
| `/pwa fix-content-visibility` | Disable content-visibility for Android |
| `/pwa fix-stroke-width` | Standardize SVG strokeWidth |
| `/pwa fix-touch-targets` | Add 44px touch target wrappers |
| `/pwa fix-view-transitions` | Disable View Transitions for old Android |
| `/pwa fix-scroll-margin` | Fix TanStack Virtual scrollMargin race |

## WORKFLOW
1. SCAN package.json, next.config, manifest
2. RESEARCH Context7 for Workbox/vite-plugin-pwa patterns
3. SETUP vite-plugin-pwa, sw.ts, manifest
4. CONFIGURE caching strategies
5. ICONS 192x192, 512x512, maskable
6. SECURITY CSP, COOP/COEP headers
7. TEST Lighthouse + offline mode
8. VERIFY 30/30 PWA gates

## 30 VERIFICATION GATES

### PWA Core Gates (G-PWA-1 to G-PWA-22)
| Gate | Name | Pass Criteria |
|------|------|---------------|
| PWA-1 | SW_REGISTERED | State: activated |
| PWA-2 | MANIFEST_VALID | 0 Lighthouse errors |
| PWA-3 | OFFLINE_WORKS | Page loads offline |
| PWA-4 | INSTALLABLE | beforeinstallprompt fires |
| PWA-5 | ICONS_CORRECT | 192, 512, maskable exist |
| PWA-6 | LIGHTHOUSE_100 | PWA score = 100 |
| PWA-7 | SECURITY_HEADERS | CSP + COOP/COEP present |
| PWA-8 | LCP_APEX | < 1.0s |
| PWA-9 | INP_APEX | < 100ms |
| PWA-10 | CLS_APEX | 0 |
| PWA-11 | BUNDLE_APEX | < 100KB initial JS |
| PWA-12 | TOUCH_TARGETS | 44x44px minimum |
| PWA-13 | MEMORY_MGMT | RAM-tier strategies active |
| PWA-14 | PLATFORM_PARITY | UI identical iOS/Android |
| PWA-15 | WEBVIEW_ESCAPE | "Open in Browser" shown |
| PWA-16 | OEM_BATTERY | Whitelist guidance shown |
| PWA-17 | NAV_PRELOAD | Navigation preload enabled |
| PWA-18 | STREAMING | Streaming responses active |
| PWA-19 | BROTLI | Brotli compression enabled |
| PWA-20 | PRELOAD_OPT | Module preload optimized |
| PWA-21 | BFCACHE | BFCache compatible |
| PWA-22 | SPECULATION | Speculation rules active |

### Android Rendering Gates (G-ARF-1 to G-ARF-8)
| Gate | Name | Pass Criteria |
|------|------|---------------|
| G-ARF-1 | CONTENT_VIS | content-visibility disabled for Android |
| G-ARF-2 | STROKE_WIDTH | SVG strokeWidth standardized to 2.5 |
| G-ARF-3 | VIEW_TRANS | View Transitions disabled for Chrome < 111 |
| G-ARF-4 | WILL_CHANGE | Single source of truth for will-change |
| G-ARF-5 | SCROLL_MARGIN | Virtual list scrollMargin race fixed |
| G-ARF-6 | TOUCH_44PX | Touch targets wrapped with min-h-11 |
| G-ARF-7 | Z_INDEX | Max z-index limited to 50 |
| G-ARF-8 | NET_TIMEOUT | Network timeout increased to 10s |

**Threshold**: 30/30 MUST pass

## TECHNOLOGY STACK
| Layer | Technology |
|-------|------------|
| Service Worker | **vite-plugin-pwa 0.22.x + Workbox 7.x** (MANDATORY) |
| Build Plugin | vite-plugin-pwa (injectManifest strategy) |
| SW Strategy | Custom src/sw.ts with modular architecture |
| Compression | vite-plugin-compression (Brotli) |
| Analytics Offload | Partytown (Web Worker) |
| Storage | OPFS > IndexedDB > localStorage |
| View Transitions | Native API (Baseline 2025) |
| Navigation | Speculation Rules (Chromium) |
| Auth | WebAuthn/Passkeys |

## CACHING STRATEGIES
| Strategy | Routes | TTL |
|----------|--------|-----|
| CacheFirst | Images, Fonts, Google Fonts | 7d-1y |
| NetworkFirst | Navigation (HTML), SVG, Supabase API | 3s timeout |
| StaleWhileRevalidate | JS, CSS (static assets) | 7d |
| NetworkOnly | `/auth/*`, connectivity checks | N/A |
| CacheOnly | `/offline.html` | Forever |
| Custom Streaming | Deliveries API (supabase.co/deliveries) | Cache + stream |

## PERFORMANCE TARGETS
| Metric | Target | Critical |
|--------|--------|----------|
| Lighthouse PWA | 100 | 100 |
| SW Boot | < 50ms | < 100ms |
| Cache Hit | > 90% | > 80% |
| Offline Load | < 500ms | < 1s |

## NVIDIA-LEVEL OPTIMIZATIONS (35 Total)

### Tier 1: Build (7 optimizations)
| # | Optimization | Impact |
|---|--------------|--------|
| 1 | Brotli Compression | 25-30% smaller |
| 2 | Aggressive Tree-shaking | 2-5% bundle reduction |
| 3 | Radix Base Chunk | Fix circular deps |
| 4 | Module Preload Filter | 100-200ms TTI |
| 5-7 | Strategic Chunking | Optimal loading |

### Tier 2: Service Worker (4 optimizations)
| # | Optimization | Impact |
|---|--------------|--------|
| 8 | Query Coalescing | Dedupe requests |
| 9 | Broadcast Channel | Multi-tab sync |
| 10 | Streaming Responses | 200-500ms faster 3G |
| 11 | Navigation Preload | 50-200ms faster |

### Tier 3: HTML (3 optimizations)
| # | Optimization | Impact |
|---|--------------|--------|
| 12 | fetchpriority="high" | 30% faster LCP |
| 13 | Font Subsetting | 74% smaller fonts |
| 14 | Partytown Analytics | 50% INP improvement |

### Tier 4: Runtime Hooks (5 optimizations)
| # | Optimization | Impact |
|---|--------------|--------|
| 15 | usePageLifecycle | 0% CPU frozen |
| 16 | useIdleCallback | Non-blocking work |
| 17 | View Transitions | Smooth navigation |
| 18 | useBfcache | 10x faster back |
| 19 | scheduler.postTask | Better INP |

### Tier 5: CSS (2 optimizations)
| # | Optimization | Impact |
|---|--------------|--------|
| 20 | content-visibility | 7x faster render |
| 21 | CSS Containment | Isolated reflows |

### Tier 6: Advanced (14 optimizations)
See `references/nvidia-level-optimizations.md` for full details.

## RTL/RESPONSIVE COMPLIANCE
| Element | RTL Pattern | Responsive |
|---------|-------------|------------|
| Install banner | `inset-inline-start` | `min-h-11 min-w-11` |
| Offline indicator | `inset-e-4` not `right-4` (TW 4.2; `end-4` deprecated) | `p-3` |
| Update prompt | `text-start` | `w-full sm:w-auto` |
| Icons | `rtl:rotate-180` + `aria-hidden="true"` | `text-base` min |

## GENERATED ARTIFACTS
| File | Location |
|------|----------|
| `sw.ts` | `src/sw.ts` (entry point, imports from src/sw/) |
| `sw/*.ts` | `src/sw/` (13 modular files) |
| `manifest.json` | `public/manifest.json` |
| `icons` | `public/` (logo.svg, pwa-192x192.png, pwa-512x512.png, apple-touch-icon.png) |
| `offline.html` | `public/offline.html` |

## SECURITY GATES
| Gate | Action |
|------|--------|
| SEC-1 | Verify SW scope matches app root |
| SEC-2 | Validate cached responses |
| SEC-3 | Ensure CSP allows SW |
| SEC-4 | Block HTTP in production |
| SEC-5 | COOP/COEP for SharedArrayBuffer |

## CASH APP — ACTUAL ARCHITECTURE

### Service Worker Modules (src/sw/ — 13 files)
| Module | File | Purpose |
|--------|------|---------|
| Entry | `sw.ts` | Lifecycle, precache, module init |
| Index | `sw/index.ts` | Barrel exports |
| Cache Config | `sw/cacheConfig.ts` | CACHE_VERSION="v8", named caches, plugin factories |
| Cache Routes | `sw/cacheRoutes.ts` | All cache strategies by asset type |
| Navigation | `sw/navigationHandler.ts` | NetworkFirst with 3s timeout + Navigation Preload |
| Streaming | `sw/streamingHandler.ts` | ReadableStream for deliveries API |
| Push | `sw/pushHandler.ts` | Push notification handling (Hebrew) |
| Sync | `sw/syncHandler.ts` | Background sync for Supabase CRUD |
| Periodic Sync | `sw/periodicSync.ts` | Periodic data refresh |
| Messages | `sw/messageHandlers.ts` | Client<->SW communication |
| Share Target | `sw/shareTargetHandler.ts` | Web Share Target API |
| IDB Helpers | `sw/idbHelpers.ts` | IndexedDB utilities |
| Fetch Handler | `sw/fetchHandler.ts` | Custom fetch handling |
| Types | `sw/types.ts` | TypeScript declarations |

### PWA Hooks (src/hooks/pwa/ — 32 files)
| Hook | Purpose |
|------|---------|
| `usePageLifecycle` | Page lifecycle state management |
| `usePageVisibility` | Document visibility tracking |
| `useBfcache` | BFCache compatibility |
| `useIdleCallback` | requestIdleCallback scheduling |
| `useIdleChunkedWork` | Chunked work during idle |
| `useDeferToIdle` | Deferred non-critical work |
| `useLongTasks` | Long task detection (PerformanceObserver) |
| `useMemoryPressure` | Memory pressure monitoring |
| `useAppBadge` | App badge API |
| `useWebShare` | Web Share API |
| `swHealthCheck` | SW health monitoring |
| `useAndroidBackButton` | Android back button handling |

### Cache Names (v8)
| Cache | Name | Strategy |
|-------|------|----------|
| SVG | `svg-v2` | NetworkFirst (10s timeout) |
| Images | `images-v2` | CacheFirst (7d, max 200) |
| Fonts | `fonts-v1` | CacheFirst (1y, max 30) |
| Google Fonts | `google-fonts-v1` | CacheFirst (1y) |
| Static (JS/CSS) | `static-v4` | StaleWhileRevalidate (7d) |
| API | `api-v1` | NetworkFirst (10s timeout, 5min) |
| Pages | `pages-v2` | NetworkFirst (3s timeout) |
| Offline | `offline-fallback-v1` | Precached |
| Prefetch | `prefetch-v1` | Periodic sync |

### SW Update Flow
1. `sw.ts` install: `skipWaiting()` + `clearOldCaches(CACHE_VERSION)` + precache offline page
2. `sw.ts` activate: `clients.claim()` + `clearOldCaches()` + `enableNavigationPreload()` + `postMessage("SW_UPDATED")`
3. `swSetup.ts` (client): listens for `controllerchange` then `reloadForUpdate()` with sessionStorage cooldown (5000ms)
4. Client polls `registration.update()` every 5 minutes

### Platform Detection (index.html inline script — BEFORE React renders)
Classes set synchronously on `<html>`:
- `is-android` — Any Android device
- `is-android-old` — Chrome < 84 OR Android < 10
- `is-ios` — Any iOS device
- `is-in-app-browser` — Instagram, Facebook, Line, Twitter, Snapchat
- `--vh` CSS variable — Dynamic viewport height for old Android

### SW Registration (index.html — DOMContentLoaded, not window.load)
1. HEAD request to `/sw.js` with `cache: "no-store"`
2. Check response OK + `content-type: javascript`
3. Only then `navigator.serviceWorker.register("/sw.js", { scope: "/" })`
4. Silent fail in dev mode (SW file won't exist)

## RESEARCH-FIRST (MANDATORY)
| Step | Tool |
|------|------|
| Query Workbox patterns | Context7: `/googlechrome/workbox` |
| Query vite-plugin-pwa | Context7: `/vite-pwa/vite-plugin-pwa` |
| Search past implementations | MCP Memory |

## REFERENCES
| Reference | Path |
|-----------|------|
| **NVIDIA Optimizations** | `references/nvidia-level-optimizations.md` |
| **Vite PWA Config** | `references/vite-pwa-nvidia-config.md` |
| **Runtime Hooks** | `references/pwa-runtime-hooks.md` |
| Master Checklist | `references/pwa-master-checklist.md` |
| Lighthouse Fixes | `references/pwa-lighthouse-fixes.md` |
| SW Patterns | `references/service-worker-patterns.md` |
| iOS Limitations | `references/pwa-ios-limitations.md` |
| Android Optimization | `references/pwa-android-optimization.md` |
| TWA Play Store | `references/pwa-twa-play-store.md` |
| Push Troubleshooting | `references/pwa-push-troubleshooting.md` |
| Analytics | `references/pwa-analytics.md` |
| Device Parity | `references/pwa-device-parity-checklist.md` |
| Old Android CSS | `references/old-android-css-compat.md` |
| Freezing Prevention | `references/pwa-freezing-prevention.md` |
| iOS/Android Parity | `references/pwa-ios-android-parity.md` |
| Edge Cases | `references/pwa-edge-cases.md` |
| Manifest Complete | `references/pwa-manifest-complete.md` |
| Testing Patterns | `references/pwa-testing-patterns.md` |
| **Android Rendering Fixes** | `references/android-rendering-fixes.md` |

**Phase**: 2.4 | **Fallback**: mobile agent (Capacitor)

---

## MCP 2.0 & SUBAGENT DELEGATION

### Agent Orchestration Pattern
When implementing PWA features, delegate to specialized agents:

| Task | Agent | Model |
|------|-------|-------|
| PWA architecture decisions | `architect` | Opus |
| Service Worker implementation | `code-writer-agent` | Sonnet |
| Manifest/icon validation | `Explore` | Sonnet |
| Lighthouse audit analysis | `perf-analyzer` | Sonnet |
| SW test generation | `test-generator` | Sonnet |
| Security CSP review | `security-auditor` | Opus |
| Bundle size analysis | `perf-analyzer` | Sonnet |
| Accessibility audit | `accessibility-agent` | Sonnet |

### Parallel Execution Pattern
```
Phase 1 (parallel): [architect] + [Explore] + [security-auditor]
Phase 2 (parallel): [code-writer] + [test-generator]
Phase 3 (sequential): [perf-analyzer] → [verify-app]
```

### Cross-Skill Integration
| Skill | Integration Point |
|-------|------------------|
| `perf-analyzer` | Bundle size + CWV after SW changes |
| `security-auditor` | CSP headers, COOP/COEP validation |
| `test-generator` | SW lifecycle + offline E2E tests |
| `accessibility-agent` | Reduced motion, screen reader with SW |
| `mobile` | Capacitor + native PWA integration |

---

## 9-DIMENSIONAL ALIGNMENT

| Dimension | Coverage | PWA Relevance |
|-----------|----------|---------------|
| D1: Security | 85% | CSP, COOP/COEP, SW scope isolation |
| D2: Performance | 100% | 35 NVIDIA optimizations, CWV |
| D3: Accessibility | 80% | Reduced motion, offline indicators, aria-hidden on icons |
| D4: SEO | N/A | PWA not SEO-relevant |
| D5: RTL | 100% | Logical properties in all examples |
| D6: Responsive | 100% | 44px touch, device parity |
| D7: Offline | 100% | Core domain - offline-first |
| D8: Testing | 95% | Playwright SW, Lighthouse CI |
| D9: Documentation | 100% | 19 reference files + 1 lessons-learned |

<!-- PWA_EXPERT v24.7.0 | Updated: 2026-02-26 -->


---

## COMPLETION VERIFICATION GATES

> **v24.7.0** | Mandatory verification before claiming completion

### Pre-Execution Gates
- [ ] User requirements clearly understood
- [ ] Relevant files and context identified
- [ ] Existing patterns and conventions reviewed

### Post-Execution Gates
- [ ] `pnpm run typecheck` passes (0 errors)
- [ ] `pnpm run lint` passes (0 errors)
- [ ] No `any` types introduced
- [ ] No `console.log` statements in production code
- [ ] No TODO/FIXME/HACK comments in new code
- [ ] RTL compliance verified (ms/me not ml/mr)
- [ ] All user requirements fulfilled with evidence
- [ ] Edge cases identified and handled
- [ ] Error handling complete

### Completion Criteria

**NEVER claim "done", "complete", "finished", or "ready" without:**

1. **Running Verification Commands:**
   ```bash
   pnpm run typecheck && pnpm run lint && pnpm run test
   ```

2. **Showing Output as Proof:**
   - Paste actual command output
   - Show pass/fail status

3. **Requirements Checklist:**
   ```
   Requirements from original request:
   1. [requirement 1] - ✅/❌
   2. [requirement 2] - ✅/❌
   ...
   ```

4. **Self-Interrogation:**
   - "Did I miss any implicit requirements?"
   - "What edge cases did I not handle?"
   - "If user asks 'are you sure?', what would I find missing?"

---

<!-- VERIFICATION_GATES v24.7.0 | Updated: 2026-02-26 -->
