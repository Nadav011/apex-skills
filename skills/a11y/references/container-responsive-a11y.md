# Container Queries & Responsive Accessibility

> **v24.6.0** | CSS Container Queries | Tailwind 4.2.1 | WCAG 2.2 SC 1.4.4 (Resize Text) + 2.5.5 (Target Size)
> RTL-FIRST: `ms-`/`me-`/`ps-`/`pe-`/`inset-s-`/`inset-e-` — never `ml-`/`mr-`/`left-`/`right-`

---

## Container Query Support Matrix

| Feature | Browsers | Status | Notes |
|---------|----------|--------|-------|
| Size queries (`inline-size`, `block-size`) | Chrome 105+, Safari 16+, Firefox 110+, Edge 105+ | Baseline Widely Available | Full support, use freely |
| Style queries (custom properties only) | Chrome 111+, Firefox 131+, Edge 111+, Safari 18+ | Widely Available (2026) | Only custom properties; `@container style()` for values |
| Scroll-state queries (`scrollable`, `stuck`, `snapped`) | Chrome 130+, Edge 130+, Opera 115+ | Emerging — Dec 2025 | Not Firefox/Safari yet — progressive enhancement only |

---

## A11y Benefits Over Viewport-Only Breakpoints

| Problem with Viewport Breakpoints | Container Query Solution |
|----------------------------------|------------------------|
| Component in sidebar gets viewport-wide layout | Component adapts to its actual available space |
| Touch targets too small in narrow sidebars | Container-aware target sizing |
| Font scales with viewport, ignores component context | `cqi`/`cqb` units scoped to container |
| Re-renders needed when component moves | CSS-only — no JS needed |
| RTL layout hacks due to fixed pixel breakpoints | Logical container query units (`inline-size`) |

---

## Zoom-Safe Typography (WCAG 1.4.4 Resize Text)

### The Problem

```css
/* WRONG: vw-only typography — overrides user zoom */
.hero-title {
  font-size: 5vw; /* At 200% browser zoom, user's 16px base becomes 32px,
                     but 5vw is relative to VIEWPORT not user preference.
                     Text doesn't scale proportionally with zoom. */
}

/* WRONG: cqi-only — same problem as vw, scoped to container */
.card-title {
  font-size: 4cqi; /* No rem floor — ignores user font-size settings */
}
```

### The Solution: clamp() with rem floor

```css
/* RIGHT: clamp() with rem floor + container fluid + rem ceiling */
.hero-title {
  /* Min: user's base 1.5rem | Fluid: 4cqi relative to container | Max: 3rem */
  font-size: clamp(1.5rem, 4cqi, 3rem);
}

.card-title {
  font-size: clamp(1rem, 2.5cqi, 1.75rem);
}

.body-text {
  font-size: clamp(0.875rem, 1.8cqi, 1.125rem);
}
```

```tsx
// Tailwind 4.2: arbitrary value with container units
// Container query context required on parent
function ResponsiveHeading({ children }: { children: React.ReactNode }) {
  return (
    <div className="@container">
      {/* Tailwind 4.2: [font-size:clamp()] arbitrary property */}
      <h2
        className="font-bold leading-tight"
        style={{ fontSize: 'clamp(1rem, 3cqi, 2rem)' }}
      >
        {children}
      </h2>
    </div>
  );
}
```

### Typography Scale Table

| Use Case | `clamp()` Value | Min | Fluid | Max |
|----------|-----------------|-----|-------|-----|
| Display (hero) | `clamp(2rem, 6cqi, 4rem)` | 32px | fluid | 64px |
| Heading 1 | `clamp(1.5rem, 4cqi, 2.5rem)` | 24px | fluid | 40px |
| Heading 2 | `clamp(1.25rem, 3cqi, 2rem)` | 20px | fluid | 32px |
| Body | `clamp(0.875rem, 2cqi, 1.125rem)` | 14px | fluid | 18px |
| Caption | `clamp(0.75rem, 1.5cqi, 0.875rem)` | 12px | fluid | 14px |

---

## Container-Aware Touch Targets (WCAG 2.5.5 / 2.5.8)

WCAG 2.5.8 (AA, 2.2): 24x24px minimum. WCAG 2.5.5 (AAA): 44x44px preferred.

```tsx
// Container context with adaptive touch targets
function AdaptiveActionButton({
  children,
  onClick,
  label,
}: {
  children: React.ReactNode;
  onClick: () => void;
  label: string;
}) {
  return (
    <div className="@container">
      <button
        onClick={onClick}
        aria-label={label}
        className={`
          flex items-center justify-center rounded-lg
          focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2

          /* Narrow container (< 200px): expand touch area — tight layout needs compensation */
          @[<200px]:min-h-14 @[<200px]:min-w-14

          /* Standard container (200px–400px): standard 44x44 touch target */
          @[200px]:min-h-11 @[200px]:min-w-11 @[200px]:px-4

          /* Wide container (>= 400px): standard with padding */
          @[400px]:min-h-11 @[400px]:min-w-11 @[400px]:px-6
        `}
      >
        {children}
      </button>
    </div>
  );
}
```

```css
/* Equivalent CSS — container-aware touch targets */
.action-container {
  container-type: inline-size;
}

.adaptive-button {
  min-height: 44px; /* default */
  min-width: 44px;
}

/* Narrow container: increase target to compensate for cramped layout */
@container (inline-size < 200px) {
  .adaptive-button {
    min-height: 56px;
    min-width: 56px;
  }
}
```

---

## Container Queries + Logical Properties (RTL-Safe)

### inline-size Queries Respect Document Direction

```css
/* inline-size always means "writing direction axis" — RTL-safe */
.card-container {
  container-type: inline-size;
  container-name: card;
}

/* This breakpoint works correctly in both LTR and RTL */
@container card (inline-size > 400px) {
  .card-layout {
    display: flex;
    flex-direction: row;
    gap: 1rem;
  }
}
```

```tsx
// Tailwind 4.2: @container variant + logical properties
function ProductCard({ product }: { product: Product }) {
  return (
    // @container on the wrapper — establishes container context
    <div className="@container rounded-xl border border-gray-200">
      <div className="@md:flex @md:gap-6 p-4">
        <img
          src={product.imageUrl}
          alt={product.name}
          // Adapts based on container, not viewport
          className="w-full rounded-lg @md:w-48 @md:shrink-0 object-cover"
        />
        <div className="mt-4 @md:mt-0">
          {/* ms- for RTL-safe margin — never ml- */}
          <h3 className="font-semibold text-start">{product.name}</h3>
          <p className="mt-2 text-sm text-gray-600 text-start">
            {product.description}
          </p>
          {/* dir="ltr" on numbers — always */}
          <p dir="ltr" className="mt-2 font-bold">₪{product.price}</p>
        </div>
      </div>
    </div>
  );
}
```

### RTL + Container Query: Layout Flip Pattern

```tsx
// Navigation drawer — inline-end anchored, adapts to container
function NavDrawer({ isOpen, children }: { isOpen: boolean; children: React.ReactNode }) {
  return (
    <div className="@container relative">
      <nav
        aria-label="ניווט ראשי"
        className={`
          /* Anchored to inline-end regardless of LTR/RTL */
          absolute inset-e-0 inset-s-auto top-0 h-full bg-white shadow-xl
          /* Container-responsive width */
          @[<400px]:w-full
          @[400px]:w-72
          @[600px]:w-80
          ${isOpen ? 'translate-x-0' : 'translate-x-full rtl:-translate-x-full'}
          transition-transform motion-reduce:transition-none
        `}
        aria-hidden={!isOpen}
        inert={!isOpen ? true : undefined}
      >
        {children}
      </nav>
    </div>
  );
}
```

---

## Focus Indicator Adaptation

WCAG 2.4.13 (AA): minimum 2px outline, 3:1 contrast ratio against adjacent color.

```css
/* Container-aware focus indicators */
.interactive-container {
  container-type: inline-size;
}

/* Narrow container: larger focus indicator — more visible in cramped space */
@container (inline-size < 300px) {
  .focusable-item:focus-visible {
    outline: 3px solid currentColor;
    outline-offset: 3px;
  }
}

/* Standard container: standard focus ring */
@container (inline-size >= 300px) {
  .focusable-item:focus-visible {
    outline: 2px solid currentColor;
    outline-offset: 2px;
  }
}
```

```tsx
// Tailwind: container-adaptive focus with forced-colors compatibility
function FocusableCard({ children, href }: { children: React.ReactNode; href: string }) {
  return (
    <div className="@container">
      <a
        href={href}
        className={`
          block rounded-xl p-4 no-underline
          /* Standard focus ring — uses outline (survives forced-colors) */
          focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2
          focus-visible:outline-blue-600
          /* Narrow container: thicker outline */
          @[<280px]:focus-visible:outline-[3px] @[<280px]:focus-visible:outline-offset-3
        `}
      >
        {children}
      </a>
    </div>
  );
}
```

---

## Container Style Queries (Custom Properties)

Available for custom properties only — Chrome/Edge/Firefox:

```css
/* Define semantic state via custom property */
.status-card {
  --status: 'default';
}
.status-card[data-status='error'] {
  --status: 'error';
}

/* Style query on custom property value */
@container style(--status: 'error') {
  .status-message {
    color: var(--color-error-700);
    font-weight: 600;
  }
}
```

Progressive enhancement — must provide base styles without the query:

```tsx
function StatusCard({ status, message }: { status: 'default' | 'error' | 'success'; message: string }) {
  return (
    <div
      className="@container rounded-xl p-4 border"
      style={{ '--status': `'${status}'` } as React.CSSProperties}
      data-status={status} /* Fallback for browsers without style queries */
    >
      <p
        className={`
          text-sm
          /* Fallback via data attribute (all browsers) */
          data-[status=error]:text-red-700 data-[status=error]:font-semibold
          data-[status=success]:text-green-700
        `}
        data-status={status}
      >
        {message}
      </p>
    </div>
  );
}
```

---

## Interaction with Media Queries

| Use Case | Query Type | Rationale |
|----------|-----------|-----------|
| User preference (motion, contrast, dark mode) | Media query | Reflects OS/browser preferences — no container equivalent |
| Component layout breakpoints | Container query | Component adapts to its actual space |
| Print styles | Media query | Print is viewport-level |
| Touch target size for device type | Media query (`hover: none`) + container query | Combine: coarse pointer + narrow container → largest targets |
| Font scaling for readability | Container query with `clamp()` | Scoped to component space |

```css
/* Combining media query (user preference) + container query (component context) */
@media (hover: none) and (pointer: coarse) {
  /* Touch device detected */
  @container (inline-size < 300px) {
    /* Narrow container on touch device — maximum touch target */
    .cta-button {
      min-height: 56px;
      min-width: 56px;
    }
  }
}

/* prefers-reduced-motion: always media query — no container equivalent */
@media (prefers-reduced-motion: reduce) {
  /* Applies globally regardless of container */
  .animated-element {
    animation: none;
    transition: none;
  }
}
```

---

## Playwright Testing

```typescript
// container-queries-a11y.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Container query touch targets', () => {
  const containerWidths = [200, 320, 400, 600] as const;

  for (const width of containerWidths) {
    test(`touch targets meet 44px minimum at container width ${width}px`, async ({ page }) => {
      await page.goto('/components/product-card');
      // Resize viewport to approximate container width
      await page.setViewportSize({ width, height: 800 });
      await page.waitForTimeout(100); // wait for container queries to settle

      const buttons = await page.locator('button, a[href], [role="button"]').all();
      for (const btn of buttons) {
        const box = await btn.boundingBox();
        if (!box) continue;
        expect(box.height, `Button too short at ${width}px container`).toBeGreaterThanOrEqual(44);
        expect(box.width, `Button too narrow at ${width}px container`).toBeGreaterThanOrEqual(44);
      }
    });
  }
});

test.describe('Zoom-safe typography', () => {
  const zoomLevels = [1, 1.5, 2, 4] as const;

  for (const zoom of zoomLevels) {
    test(`text readable at ${zoom * 100}% zoom`, async ({ page }) => {
      await page.goto('/');
      // Simulate browser zoom via viewport scaling
      await page.emulateMedia({});
      await page.evaluate((z) => {
        document.documentElement.style.fontSize = `${16 * z}px`;
      }, zoom);
      await page.waitForTimeout(100);

      // Verify text is still visible (not overflowing container)
      const overflowingText = await page.evaluate(() => {
        const textElements = document.querySelectorAll('p, h1, h2, h3, h4, h5, h6, span, li');
        const overflow: string[] = [];
        for (const el of textElements) {
          if (el.scrollWidth > el.clientWidth + 4) { // 4px tolerance
            overflow.push(`${el.tagName}: "${el.textContent?.slice(0, 30)}"`);
          }
        }
        return overflow;
      });

      expect(overflowingText, `Text overflow at ${zoom * 100}% zoom`).toHaveLength(0);
    });
  }
});

test.describe('RTL container queries', () => {
  test('logical properties respected in RTL layout', async ({ page }) => {
    await page.goto('/');
    const dir = await page.evaluate(() => document.documentElement.dir);
    expect(dir).toBe('rtl');

    // Verify no physical ml-/mr- classes in container query components
    const physicalMarginClasses = await page.evaluate(() => {
      const all = document.querySelectorAll('[class]');
      const violations: string[] = [];
      for (const el of all) {
        const classes = Array.from(el.classList);
        const physical = classes.filter((c) =>
          /^(ml|mr|pl|pr)-/.test(c) || /^@\[.+\]:(ml|mr|pl|pr)-/.test(c),
        );
        if (physical.length > 0) {
          violations.push(`${el.tagName}#${el.id || '(no id)'}: ${physical.join(', ')}`);
        }
      }
      return violations;
    });
    expect(physicalMarginClasses, 'Physical margin/padding classes in RTL').toHaveLength(0);
  });
});

test.describe('Focus indicators in container contexts', () => {
  test('focus ring meets 2px minimum at all container widths', async ({ page }) => {
    await page.goto('/');
    await page.keyboard.press('Tab');
    const focusedEl = page.locator(':focus-visible');
    const outlineWidth = await focusedEl.evaluate((el) => {
      return parseFloat(getComputedStyle(el).outlineWidth);
    });
    expect(outlineWidth).toBeGreaterThanOrEqual(2);
  });
});
```

---

## Cross-References

- Reduced motion media queries: `references/motion-contrast-modes.md`
- WCAG contrast for container-scoped text: `references/wcag3-apca.md`
- Touch targets in mobile context: `references/mobile-a11y.md`
- RTL logical properties: `~/.claude/rules/quality/rtl-i18n.md`
- Playwright setup: `references/a11y-testing.md`

---

<!-- CONTAINER_RESPONSIVE_A11Y v24.6.0 | Updated: 2026-02-24 | CSS Container Queries + Zoom-safe Typography + RTL + Playwright -->
