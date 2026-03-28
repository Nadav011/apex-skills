# Reduced Motion, Forced Colors & Contrast Modes

> **v24.6.0** | CSS Media Queries | Playwright Testing | React + Tailwind 4.2
> RTL-FIRST: `ms-`/`me-`/`ps-`/`pe-`/`inset-s-`/`inset-e-` — never `ml-`/`mr-`/`left-`/`right-`

---

## prefers-reduced-motion

### Mandatory Global Reset

Place in global CSS (before component styles, after Tailwind base):

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

### Tailwind 4.2 Variant

```tsx
// Tailwind motion-reduce: variant — applied when user prefers reduced motion
<div className="transition-transform duration-500 motion-reduce:transition-none">
  {children}
</div>

// Animate on hover — disable for reduced motion
<button className="hover:scale-105 motion-reduce:hover:scale-100 transition-transform">
  Submit
</button>
```

### JS: Conditional Logic

```typescript
const prefersReducedMotion = (): boolean =>
  window.matchMedia('(prefers-reduced-motion: reduce)').matches;

// Subscribe to changes (user can toggle OS setting without page reload)
function useReducedMotion(): boolean {
  const [reduced, setReduced] = React.useState(
    () => window.matchMedia('(prefers-reduced-motion: reduce)').matches
  );

  React.useEffect(() => {
    const mq = window.matchMedia('(prefers-reduced-motion: reduce)');
    const handler = (e: MediaQueryListEvent) => setReduced(e.matches);
    mq.addEventListener('change', handler);
    return () => mq.removeEventListener('change', handler);
  }, []);

  return reduced;
}
```

### Motion (formerly Framer Motion)

```tsx
import { useReducedMotion } from 'motion/react';

function AnimatedCard({ children }: { children: React.ReactNode }) {
  const shouldReduce = useReducedMotion();

  return (
    <motion.div
      initial={{ opacity: 0, y: shouldReduce ? 0 : 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: shouldReduce ? 0 : 0.3 }}
    >
      {children}
    </motion.div>
  );
}
```

### View Transitions API — MUST Guard

```typescript
// WRONG: Applies view transition regardless of user preference
document.startViewTransition(() => updateDOM());

// RIGHT: Guard mandatory
function navigate(updateFn: () => void) {
  if (!document.startViewTransition || prefersReducedMotion()) {
    updateFn();
    return;
  }
  document.startViewTransition(updateFn);
}
```

```css
/* View Transition pseudo-elements also need override */
@media (prefers-reduced-motion: reduce) {
  ::view-transition-old(*),
  ::view-transition-new(*) {
    animation: none !important;
  }
}
```

### Scroll-Driven Animations (animation-timeline)

```css
/* WRONG: No reduced-motion consideration */
.parallax {
  animation: parallax-scroll linear;
  animation-timeline: scroll(root);
}

/* RIGHT: Disable scroll-driven animation when reduced motion preferred */
@media (prefers-reduced-motion: no-preference) {
  .parallax {
    animation: parallax-scroll linear;
    animation-timeline: scroll(root);
  }
}
```

---

## prefers-contrast

### Values & Support

| Value | Meaning | Support |
|-------|---------|---------|
| `more` | User requests higher contrast | Full (since May 2022) |
| `less` | User requests lower contrast | Full |
| `custom` | User has set custom colors (Win 11) | Partial |
| `no-preference` | Default | Full |

### CSS + Tailwind

```css
@media (prefers-contrast: more) {
  /* Remove transparency */
  .card {
    background-color: Canvas; /* Use system color, no opacity */
    border: 2px solid CanvasText; /* Add visible border */
    box-shadow: none;
  }
}
```

```tsx
// Tailwind contrast-more: variant
<button className="
  border border-transparent
  contrast-more:border-current
  contrast-more:font-bold
  contrast-more:shadow-none
  min-h-11
">
  Submit
</button>
```

### Implementation Checklist

```
contrast-more: increases border width on cards/inputs
contrast-more: removes backdrop-blur (replace with solid bg)
contrast-more: removes subtle box-shadow decorations
contrast-more: increases font-weight for UI labels
contrast-more: ensures focus indicators are 3px+ (not just 2px)
```

---

## forced-colors: active (Windows High Contrast)

### System Color Keywords

```css
/* Use ONLY these system color keywords inside forced-colors context */
.button {
  color: ButtonText;
  background-color: ButtonFace;
  border-color: ButtonBorder;
}
.link { color: LinkText; }
.input { background-color: Field; color: FieldText; }
.selection { background-color: Highlight; color: HighlightText; }
.disabled { color: GrayText; }
```

### forced-color-adjust: none

Opt specific elements out of forced-colors (use sparingly — only for semantic color like status badges):

```css
.status-badge {
  forced-color-adjust: none;
  /* Custom colors now respected even in High Contrast mode */
  background-color: var(--status-color);
  color: white;
  /* MUST ensure your colors still meet contrast in forced-colors context */
}
```

### Focus Indicators in High Contrast

```css
/* WRONG: box-shadow focus ring disappears in forced-colors */
:focus-visible {
  outline: none;
  box-shadow: 0 0 0 3px #4A90E2;
}

/* RIGHT: Use outline — survives forced-colors */
:focus-visible {
  outline: 3px solid Highlight; /* system color */
  outline-offset: 2px;
}
```

### SVG Compatibility

```tsx
// WRONG: Hardcoded fill disappears in forced-colors
<svg fill="#4A90E2">...</svg>

// RIGHT: currentColor inherits from CSS cascade, respects forced-colors
<svg fill="currentColor" aria-hidden="true">
  <path d="..." />
</svg>
```

### Box Shadow Replacement

```css
/* WRONG: Only box-shadow — disappears in High Contrast */
.card {
  box-shadow: 0 4px 16px rgba(0,0,0,0.12);
}

/* RIGHT: Border fallback visible in High Contrast */
.card {
  box-shadow: 0 4px 16px rgba(0,0,0,0.12);
  border: 1px solid transparent; /* transparent normally, visible in forced-colors */
}

@media (forced-colors: active) {
  .card {
    border-color: CanvasText;
  }
}
```

---

## prefers-reduced-transparency

### Values & Support

| Value | Support |
|-------|---------|
| `reduce` | ~71% — needs fallback |
| `no-preference` | ~71% |

### Implementation with Fallback

```css
/* Default: transparent overlay (all browsers) */
.modal-backdrop {
  background-color: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(4px);
}

/* Reduced transparency: solid background */
@media (prefers-reduced-transparency: reduce) {
  .modal-backdrop {
    background-color: rgb(0, 0, 0); /* solid, no transparency */
    backdrop-filter: none;
  }
}
```

```tsx
// Tailwind — no built-in variant yet; use arbitrary CSS or @apply
const backdropClass = `
  bg-black/50 backdrop-blur-sm
  [@media(prefers-reduced-transparency:reduce)]:bg-black
  [@media(prefers-reduced-transparency:reduce)]:backdrop-blur-none
`;
```

---

## prefers-color-scheme (Dark Mode A11y)

### Dark Mode Contrast Requirements

WCAG 2.2 contrast ratios apply equally in dark mode. Common failures:

| Failure | Dark Mode Symptom | Fix |
|---------|------------------|-----|
| Low contrast links | Blue link barely visible on dark bg | Use lighter blue (`#60A5FA` not `#3B82F6`) |
| Disabled state | Disabled text too close to bg | Increase disabled opacity (try `opacity-60` not `opacity-30`) |
| Focus rings | White ring on near-white bg | Use accent color, not white |
| Placeholder text | Nearly invisible | Minimum Lc 45 (APCA) or 3:1 (WCAG 2.2) |

### Dual-Mode Contrast Validation

```typescript
// Check contrast passes in BOTH light and dark mode
import { checkContrast } from './contrast-utils'; // from wcag3-apca.md

const COLORS = {
  light: { text: '#111827', bg: '#FFFFFF', link: '#2563EB' },
  dark: { text: '#F9FAFB', bg: '#111827', link: '#60A5FA' },
} as const;

const lightResult = checkContrast(COLORS.light.text, COLORS.light.bg);
const darkResult = checkContrast(COLORS.dark.text, COLORS.dark.bg);

// Both must pass 4.5:1 (AA) — verify programmatically in CI
console.assert(lightResult.wcag2Passes, 'Light mode contrast fails');
console.assert(darkResult.wcag2Passes, 'Dark mode contrast fails');
```

---

## Complete Playwright Test Suite

```typescript
// a11y-media-queries.spec.ts
import { test, expect } from '@playwright/test';

const ROUTES = ['/', '/menu', '/orders'];

test.describe('prefers-reduced-motion', () => {
  test.use({ contextOptions: { reducedMotion: 'reduce' } });

  for (const route of ROUTES) {
    test(`no animations on ${route}`, async ({ page }) => {
      await page.goto(route);
      // Verify no long-duration transitions exist
      const animatingElements = await page.evaluate(() => {
        const all = document.querySelectorAll('*');
        const violators: string[] = [];
        for (const el of all) {
          const style = getComputedStyle(el);
          const duration = parseFloat(style.transitionDuration);
          if (duration > 0.02) {
            violators.push(`${el.tagName}.${el.className}: ${duration}s`);
          }
        }
        return violators;
      });
      expect(animatingElements, 'Long transitions detected with reduced-motion').toHaveLength(0);
    });
  }
});

test.describe('forced-colors: active', () => {
  test.use({ contextOptions: { forcedColors: 'active' } });

  test('focus indicator visible in high contrast', async ({ page }) => {
    await page.goto('/');
    await page.keyboard.press('Tab');
    const focusedElement = page.locator(':focus');
    const outlineStyle = await focusedElement.evaluate((el) => {
      const s = getComputedStyle(el);
      return { outline: s.outline, outlineWidth: s.outlineWidth };
    });
    // outline must not be 'none' in forced-colors
    expect(outlineStyle.outline).not.toBe('none');
  });

  test('SVG icons use currentColor', async ({ page }) => {
    await page.goto('/');
    const svgFills = await page.evaluate(() => {
      const svgs = document.querySelectorAll('svg');
      return Array.from(svgs).map((svg) => ({
        fill: svg.getAttribute('fill') || getComputedStyle(svg).fill,
        id: svg.id || svg.className,
      }));
    });
    // Hardcoded hex fills fail in forced-colors
    const hardcodedFills = svgFills.filter((s) => /^#[0-9a-fA-F]/.test(s.fill));
    expect(hardcodedFills, 'SVGs with hardcoded fills').toHaveLength(0);
  });
});

test.describe('prefers-contrast: more', () => {
  test.use({ contextOptions: { forcedColors: 'none' } });

  test('contrast-more styles applied', async ({ page }) => {
    await page.emulateMedia({ colorScheme: 'light' });
    // Playwright doesn't natively emulate prefers-contrast — use CDP
    const cdpSession = await page.context().newCDPSession(page);
    await cdpSession.send('Emulation.setEmulatedMedia', {
      features: [{ name: 'prefers-contrast', value: 'more' }],
    });
    await page.goto('/');
    const buttonBorder = await page.locator('button').first().evaluate((el) => {
      return getComputedStyle(el).borderWidth;
    });
    // contrast-more should increase border width
    expect(parseInt(buttonBorder)).toBeGreaterThanOrEqual(2);
  });
});

test.describe('dark mode contrast', () => {
  test.use({ colorScheme: 'dark' });

  test('text contrast passes WCAG 2.2 AA in dark mode', async ({ page }) => {
    await page.goto('/');
    // Use axe-playwright for automated contrast checking
    const results = await page.evaluate(async () => {
      const { default: axe } = await import('axe-core');
      const r = await axe.run({ runOnly: ['color-contrast'] });
      return r.violations;
    });
    expect(results, 'Color contrast violations in dark mode').toHaveLength(0);
  });
});

test.describe('combined: dark + reduced-motion + high-contrast', () => {
  test('page renders correctly under all restrictions simultaneously', async ({ browser }) => {
    const context = await browser.newContext({
      colorScheme: 'dark',
      reducedMotion: 'reduce',
      forcedColors: 'active',
    });
    const page = await context.newPage();
    await page.goto('/');
    // No visual errors, page is functional
    await expect(page.locator('main')).toBeVisible();
    await context.close();
  });
});
```

---

## Media Query Interaction Matrix

| Combination | Risk | Mitigation |
|-------------|------|-----------|
| dark + forced-colors | System colors override dark-mode palette | Test both independently + combined |
| reduced-motion + dark | Framer animations disabled, dark colors independent | Use `useReducedMotion()` per component |
| forced-colors + reduced-transparency | Both affect overlays | Solid-color overlays with system colors |
| contrast-more + dark | Dark palette may fail higher contrast threshold | Separate dark + contrast-more token variants |

---

## Cross-References

- APCA dark mode contrast values: `references/wcag3-apca.md`
- Playwright testing setup: `references/a11y-testing.md`
- RTL + dark mode: `~/.claude/rules/quality/rtl-i18n.md`
- Focus indicator requirements (WCAG 2.4.11/2.4.12/2.4.13): `~/.claude/skills/a11y/SKILL.md`

---

<!-- MOTION_CONTRAST_MODES v24.6.0 | Updated: 2026-02-24 | prefers-* media queries + forced-colors + Playwright -->
