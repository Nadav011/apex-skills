# View Transitions API — Accessible Implementation

> **v24.6.0** | View Transitions L1 (same-document) + L2 (cross-document MPA) | Playwright 1.58.2
> RTL-FIRST: `ms-`/`me-`/`ps-`/`pe-`/`inset-s-`/`inset-e-` — never `ml-`/`mr-`/`left-`/`right-`

---

## Browser Support & Feature Detection

| Browser | Same-Document | Cross-Document (MPA) | Notes |
|---------|--------------|---------------------|-------|
| Chrome 111+ / Edge 111+ | Yes | Chrome 126+ | Full support |
| Safari 18+ | Yes | Safari 18+ | Full support |
| Firefox 130+ | Yes | Firefox 131+ | Full support |
| Global coverage | ~88% (2026-02) | ~85% (2026-02) | Fallback required |

Always feature-detect: `if (!document.startViewTransition)` before calling the API.

---

## MANDATORY: prefers-reduced-motion Guard

Every View Transition implementation requires both a CSS and JS guard. Neither alone is sufficient.

### CSS Guard (disable animation, keep instant state change)

```css
/* globals.css — place after @import "tailwindcss" */
@media (prefers-reduced-motion: reduce) {
  ::view-transition-group(*),
  ::view-transition-old(*),
  ::view-transition-new(*) {
    animation-duration: 0.01ms !important;
    animation-delay: 0ms !important;
  }
}
```

### JS Guard (skip transition entirely for complex animations)

```typescript
const prefersReducedMotion = (): boolean =>
  typeof window !== 'undefined' &&
  window.matchMedia('(prefers-reduced-motion: reduce)').matches;

function startAccessibleTransition(updateCallback: () => void | Promise<void>): void {
  // No API: fallback to direct update
  if (!document.startViewTransition) {
    void Promise.resolve(updateCallback());
    return;
  }
  // Reduced motion: skip transition, run update directly
  if (prefersReducedMotion()) {
    void Promise.resolve(updateCallback());
    return;
  }
  document.startViewTransition(updateCallback);
}
```

---

## Duration Rules

| Transition Type | Max Duration | Rationale |
|----------------|-------------|-----------|
| Full page navigation | 400ms | Feels like app, not delay |
| Shared element (hero) | 350ms | Tracks spatial relationship |
| Tab panel switch | 200ms | Small-scope change |
| Micro-interaction (toggle) | 150ms | Immediate feedback |

Exceeding these durations increases perceived latency and SR announcement lag.

---

## Same-Document Transitions (SPA)

### Next.js 16 Page Transition with A11y Guard

```tsx
// lib/view-transition.ts
export function navigateWithTransition(
  router: ReturnType<typeof useRouter>,
  href: string,
  announceRef: React.MutableRefObject<HTMLDivElement | null>,
): void {
  const update = () => {
    router.push(href);
    // Announce page change AFTER transition completes (not during)
    requestAnimationFrame(() => {
      if (announceRef.current) {
        announceRef.current.textContent = `Navigated to ${href}`;
      }
    });
  };

  startAccessibleTransition(update);
}
```

```tsx
// app/layout.tsx — persistent announcement region (outside transition scope)
export default function RootLayout({ children }: { children: React.ReactNode }) {
  const announceRef = React.useRef<HTMLDivElement>(null);

  return (
    <html lang="he" dir="rtl">
      <body>
        {/* Persistent — never wrapped in a view-transition-name container */}
        <div
          ref={announceRef}
          role="status"
          aria-live="polite"
          aria-atomic="true"
          className="sr-only"
        />
        <main id="main-content" style={{ viewTransitionName: 'main' }}>
          {children}
        </main>
      </body>
    </html>
  );
}
```

### Shared Element Transition (Product Card → Detail)

```tsx
// ProductCard.tsx
function ProductCard({ product, index }: { product: Product; index: number }) {
  const router = useRouter();
  const announceRef = React.useRef<HTMLDivElement>(null);

  const handleNavigate = () => {
    navigateWithTransition(router, `/products/${product.id}`, announceRef);
  };

  return (
    <>
      <div
        ref={announceRef}
        role="status"
        aria-live="polite"
        aria-atomic="true"
        className="sr-only"
      />
      <article
        // Unique view-transition-name per card instance
        style={{ viewTransitionName: `product-card-${product.id}` }}
        className="rounded-xl overflow-hidden cursor-pointer"
        onClick={handleNavigate}
        onKeyDown={(e) => e.key === 'Enter' && handleNavigate()}
        tabIndex={0}
        role="link"
        aria-label={`View ${product.name} details`}
      >
        <img
          src={product.imageUrl}
          alt={product.name}
          style={{ viewTransitionName: `product-image-${product.id}` }}
          className="w-full aspect-square object-cover"
        />
        <div className="p-4">
          <h3 className="font-semibold">{product.name}</h3>
          <p dir="ltr" className="text-gray-600">
            ₪{product.price}
          </p>
        </div>
      </article>
    </>
  );
}
```

```tsx
// app/products/[id]/page.tsx — matching view-transition-name on target
export default async function ProductDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params; // Next.js 16: await params required
  const product = await fetchProduct(id);

  return (
    <main>
      <article style={{ viewTransitionName: `product-card-${id}` }}>
        <img
          src={product.imageUrl}
          alt={product.name}
          style={{ viewTransitionName: `product-image-${id}` }}
          className="w-full max-h-96 object-cover"
        />
        <div className="p-6">
          <h1 className="text-2xl font-bold">{product.name}</h1>
        </div>
      </article>
    </main>
  );
}
```

### Tab Panel Transition with Focus Management

```tsx
function AccessibleTabPanel({
  tabs,
}: {
  tabs: Array<{ id: string; label: string; content: React.ReactNode }>;
}) {
  const [activeTab, setActiveTab] = React.useState(tabs[0].id);
  const [announcement, setAnnouncement] = React.useState('');
  const panelRef = React.useRef<HTMLDivElement>(null);

  const switchTab = (tabId: string) => {
    const tab = tabs.find((t) => t.id === tabId);
    if (!tab || tabId === activeTab) return;

    const update = () => {
      setActiveTab(tabId);
      setAnnouncement(`${tab.label} tab selected`);
      // Focus panel after transition completes
      requestAnimationFrame(() => panelRef.current?.focus());
    };

    startAccessibleTransition(update);
  };

  return (
    <>
      <div role="status" aria-live="polite" aria-atomic="true" className="sr-only">
        {announcement}
      </div>

      <div
        role="tablist"
        aria-label="Content sections"
        className="flex gap-1 border-b border-gray-200"
      >
        {tabs.map((tab) => (
          <button
            key={tab.id}
            role="tab"
            aria-selected={activeTab === tab.id}
            aria-controls={`panel-${tab.id}`}
            id={`tab-${tab.id}`}
            onClick={() => switchTab(tab.id)}
            onKeyDown={(e) => {
              const idx = tabs.findIndex((t) => t.id === activeTab);
              if (e.key === 'ArrowEnd') switchTab(tabs[tabs.length - 1].id);
              else if (e.key === 'ArrowStart') switchTab(tabs[0].id);
              else if (e.key === 'ArrowInlineEnd') switchTab(tabs[(idx + 1) % tabs.length].id);
              else if (e.key === 'ArrowInlineStart') switchTab(tabs[(idx - 1 + tabs.length) % tabs.length].id);
            }}
            className="min-h-11 px-4 py-2 rounded-t-lg text-sm font-medium
                       aria-selected:border-b-2 aria-selected:border-blue-600
                       focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2"
          >
            {tab.label}
          </button>
        ))}
      </div>

      <div
        ref={panelRef}
        role="tabpanel"
        id={`panel-${activeTab}`}
        aria-labelledby={`tab-${activeTab}`}
        tabIndex={-1}
        style={{ viewTransitionName: 'tab-content' }}
        className="p-6 outline-none"
      >
        {tabs.find((t) => t.id === activeTab)?.content}
      </div>
    </>
  );
}
```

---

## Cross-Document (MPA) Transitions

### CSS-Only Opt-In

```css
/* Opt the entire site in — guard reduced-motion immediately */
@view-transition {
  navigation: auto;
}

@media (prefers-reduced-motion: reduce) {
  ::view-transition-group(*),
  ::view-transition-old(*),
  ::view-transition-new(*) {
    animation-duration: 0.01ms !important;
  }
}
```

### Custom Cross-Document Animation

```css
/* Slide in from inline-end (RTL-safe) using custom keyframe */
@keyframes slide-in-from-end {
  from { transform: translateX(100%); }   /* Physical: not RTL-safe */
  to   { transform: translateX(0); }
}

/* RTL-safe approach: use logical transform direction via JS */
/* Or: use opacity-only for guaranteed RTL safety */
@keyframes fade-in {
  from { opacity: 0; }
  to   { opacity: 1; }
}

::view-transition-new(root) {
  animation: fade-in 300ms ease-out;
}
::view-transition-old(root) {
  animation: fade-in 300ms ease-out reverse;
}
```

---

## RTL Considerations

### Slide Direction — Physical vs Logical

```css
/* WRONG: Physical transform — slides wrong direction in RTL */
::view-transition-new(root) {
  animation: slide-from-right 300ms ease-out;
}
@keyframes slide-from-right {
  from { transform: translateX(100%); }
  to   { transform: translateX(0); }
}

/* RIGHT option A: Opacity-only — direction-agnostic */
::view-transition-new(root) {
  animation: fade-scale 300ms ease-out;
}
@keyframes fade-scale {
  from { opacity: 0; transform: scale(0.98); }
  to   { opacity: 1; transform: scale(1); }
}
```

```typescript
// RIGHT option B: JS-driven direction-aware transform
function getSlideAnimation(direction: 'forward' | 'back'): string {
  const isRTL = document.documentElement.dir === 'rtl';
  // Forward in LTR = slide from right (+100%), RTL = from left (-100%)
  const enterFrom = direction === 'forward'
    ? (isRTL ? '-100%' : '100%')
    : (isRTL ? '100%' : '-100%');
  return `slideIn ${enterFrom}`;
}
```

### view-transition-name in RTL Layouts

```tsx
// Popover/panel anchored to inline-end in RTL: name must be unique per component
<div
  style={{ viewTransitionName: `sidebar-panel` }}
  className="fixed inset-e-0 inset-s-auto top-0 h-full w-80 bg-white shadow-xl"
>
  {children}
</div>
```

---

## Screen Reader Interaction

### Timing & Announcement Rules

| Risk | Details | Mitigation |
|------|---------|-----------|
| Transition interrupts SR announcement | SR mid-sentence when transition starts | Keep transitions ≤ 400ms; use `polite` not `assertive` |
| Content announced before visible | SR reads new content during transition | Post announcements via `requestAnimationFrame` after `transition.ready` |
| Focus target disappears | Element removed during transition | Check `document.contains(target)` before `focus()` |

```typescript
// Announce AFTER transition completes, not during
async function transitionAndAnnounce(
  updateFn: () => void,
  announcementText: string,
  announceEl: HTMLElement,
): Promise<void> {
  if (!document.startViewTransition || prefersReducedMotion()) {
    updateFn();
    announceEl.textContent = announcementText;
    return;
  }

  const transition = document.startViewTransition(updateFn);
  // Wait for animation to complete before announcing
  await transition.finished;
  announceEl.textContent = announcementText;
}
```

---

## Focus Management After Transition

```typescript
function focusAfterTransition(
  targetSelector: string,
  fallbackSelector = 'main h1, main [role="heading"]',
): void {
  requestAnimationFrame(() => {
    const target = document.querySelector<HTMLElement>(targetSelector);

    if (target && document.contains(target)) {
      target.focus();
      return;
    }
    // Fallback: nearest logical heading
    const fallback = document.querySelector<HTMLElement>(fallbackSelector);
    if (fallback) {
      if (!fallback.hasAttribute('tabindex')) fallback.setAttribute('tabindex', '-1');
      fallback.focus();
    }
  });
}
```

---

## Playwright Testing

```typescript
// view-transitions.spec.ts
import { test, expect } from '@playwright/test';

test.describe('View Transitions — reduced motion', () => {
  test.use({ contextOptions: { reducedMotion: 'reduce' } });

  test('transition completes without animation in reduced-motion', async ({ page }) => {
    await page.goto('/products');
    await page.click('[data-testid="product-card-1"]');
    // Page navigated — no lingering transition pseudo-elements
    await expect(page.locator('h1')).toBeVisible();
    // Check no long animation durations remain
    const maxDuration = await page.evaluate(() => {
      const el = document.querySelector('::view-transition-new(*)');
      if (!el) return 0;
      return parseFloat(getComputedStyle(el as Element).animationDuration) * 1000;
    });
    expect(maxDuration).toBeLessThan(50);
  });
});

test.describe('View Transitions — focus management', () => {
  test('focus moves to main content after navigation', async ({ page }) => {
    await page.goto('/products');
    await page.click('[data-testid="product-card-1"]');
    await page.waitForURL('/products/*');
    // Focus should be on first meaningful content (h1 or tabIndex={-1} element)
    const focusedTag = await page.evaluate(() => document.activeElement?.tagName);
    expect(['H1', 'MAIN', 'ARTICLE']).toContain(focusedTag);
  });

  test('SR announcement fires after transition completes', async ({ page }) => {
    await page.goto('/');
    const announcement = page.locator('[role="status"][aria-live="polite"]');
    await page.click('nav a[href="/about"]');
    await expect(announcement).not.toBeEmpty();
  });
});

test.describe('View Transitions — RTL', () => {
  test('no physical transform classes present in RTL layout', async ({ page }) => {
    await page.goto('/');
    // Check dir attribute set correctly
    const dir = await page.evaluate(() => document.documentElement.dir);
    expect(dir).toBe('rtl');
    // Verify no PhysicalL-R slide keyframes active
    const physicalKeyframes = await page.evaluate(() => {
      const sheets = Array.from(document.styleSheets);
      return sheets.flatMap((s) => {
        try {
          return Array.from(s.cssRules)
            .filter((r) => r instanceof CSSKeyframesRule)
            .map((r) => (r as CSSKeyframesRule).name);
        } catch { return []; }
      });
    });
    const lrKeyframes = physicalKeyframes.filter((n) =>
      /slide.*right|slide.*left|from-right|from-left/.test(n),
    );
    expect(lrKeyframes).toHaveLength(0);
  });
});
```

---

## Cross-References

- Reduced motion global reset: `references/motion-contrast-modes.md`
- Focus management in dialogs: `references/dialog-popover-a11y.md`
- Next.js 16 route announcer interaction: `references/nextjs-a11y.md`
- Playwright a11y test setup: `references/a11y-testing.md`

---

<!-- VIEW_TRANSITIONS_A11Y v24.6.0 | Updated: 2026-02-24 | View Transitions L1+L2 + reduced-motion guards + RTL + Playwright -->
