# Accessibility Testing Reference

> **v24.6.0** | axe-core 4.11.1 | @chialab/vitest-axe 0.19.0 | Playwright 1.58.2 | Vitest 4.0.18
> Pin versions: `@axe-core/playwright@4.11.1`, `@chialab/vitest-axe@0.19.0`, `axe-core@4.11.1`

---

## Accessibility Gates (A1-A15)

### Blocker Gates (Must Pass — Block Merge)

| Gate | Check | Severity | Testing |
|------|-------|----------|---------|
| A2 | Alt text on all images | BLOCKER | Automated |
| A3 | Form labels associated | BLOCKER | Automated |
| A4 | Keyboard navigation works | BLOCKER | Automated + Manual |
| A10 | No keyboard traps | BLOCKER | Manual |

### Critical Gates (Should Pass — Block Deploy)

| Gate | Check | Severity | Testing |
|------|-------|----------|---------|
| A1 | Color contrast 7:1 (AAA) | CRITICAL | Automated |
| A5 | Focus indicators visible | CRITICAL | Automated |
| A9 | Touch targets 44px | CRITICAL | Automated |
| A11 | Screen reader compatible | CRITICAL | Manual |
| A12 | Errors announced | CRITICAL | Manual |
| A15 | RTL accessible | CRITICAL | Automated + Manual |

### Major Gates (Should Fix Before Deploy)

| Gate | Check | Severity | Testing |
|------|-------|----------|---------|
| A6 | ARIA attributes valid | MAJOR | Automated |
| A7 | Heading hierarchy | MAJOR | Automated |
| A8 | Skip links present | MAJOR | Automated |
| A13 | Reduced motion respected | MAJOR | Automated |
| A14 | Text resize works at 200% | MAJOR | Manual |

---

## @chialab/vitest-axe Setup

```bash
pnpm add -D @chialab/vitest-axe@0.19.0 axe-core@4.11.1
```

```typescript
// vitest.setup.ts
import * as matchers from '@chialab/vitest-axe/matchers';
import { expect } from 'vitest';

expect.extend(matchers);
```

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    setupFiles: ['./vitest.setup.ts'],
    environment: 'jsdom',
  },
});
```

### Basic Component Test

```typescript
import { describe, expect, it } from 'vitest';
import { axe } from '@chialab/vitest-axe';
import { render } from '@testing-library/react';

describe('Button accessibility', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(<Button>Submit</Button>);
    const results = await axe(container, {
      rules: {
        // Target WCAG 2.2 AA + AAA
        'color-contrast': { enabled: true },
      },
      tags: ['wcag2a', 'wcag2aa', 'wcag22aa'],
    });
    expect(results).toHaveNoViolations();
  });

  it('should have no a11y violations in disabled state', async () => {
    const { container } = render(<Button disabled>Submit</Button>);
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });
});
```

### Form + Error State Test

```typescript
it('form has labeled inputs + error announcements', async () => {
  const { container, getByRole } = render(<LoginForm />);
  expect(await axe(container, { tags: ['wcag2a', 'wcag2aa', 'wcag22aa'] })).toHaveNoViolations();

  fireEvent.click(getByRole('button', { name: /submit/i }));
  const email = getByRole('textbox', { name: /email/i });
  expect(email).toHaveAttribute('aria-invalid', 'true');
  expect(email).toHaveAttribute('aria-describedby');
});
```

---

## axe-core 4.11 Features

- **RGAA standard** support (French accessibility standard)
- **False positive fixes**: improved detection for complex widgets
- **10x performance** on pages with many similar elements (table rows, list items)
- **New rules**: improved WCAG 2.2 coverage including 2.5.8 target size

### axe Configuration

Tags: `['wcag2a', 'wcag2aa', 'wcag22aa', 'best-practice']`. Key rules: `color-contrast`, `heading-order`, `image-alt`, `label`, `link-name`, `target-size`. Exclude: `[['iframe'], ['.third-party-widget']]`.

---

## @axe-core/playwright E2E

```bash
pnpm add -D @axe-core/playwright@4.11.1
```

```typescript
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test('page has no a11y violations', async ({ page }) => {
  await page.goto('/');
  await page.waitForLoadState('networkidle');
  const results = await new AxeBuilder({ page })
    .withTags(['wcag2a', 'wcag2aa', 'wcag22aa'])
    .exclude('.third-party-widget')
    .analyze();
  expect(results.violations).toEqual([]);
});
```

---

## Playwright ARIA Snapshot Testing

YAML-based a11y tree assertions with partial matching and regex support.

```typescript
test('dialog ARIA structure', async ({ page }) => {
  await page.goto('/settings');
  await page.click('button:has-text("Delete Account")');
  await expect(page.getByRole('dialog')).toMatchAriaSnapshot(`
    - dialog "Delete Account":
      - heading "Delete Account" [level=2]
      - text: This action cannot be undone.
      - button "Cancel"
      - button "Delete"
  `);
});

// Regex for dynamic content: heading /.*/ [level=3], text: /\\$\\d+\\.\\d{2}/
// Update snapshots: npx playwright test --update-snapshots
```

---

## Pa11y 9

```bash
pnpm add -D pa11y@9
npx pa11y http://localhost:3000 --standard WCAG2AAA
npx pa11y-ci --config .pa11yci.json  # Multi-page scan
```

`.pa11yci.json`: set `"standard": "WCAG2AAA"`, list URLs, add actions for dynamic pages (`"wait for element #form to be visible"`).

---

## Vitest 4 Browser Mode — Visual A11y Regression

```typescript
// Focus element, then screenshot comparison for focus ring visibility
await page.goto('/');
await page.keyboard.press('Tab');
await expect(page.getByRole('button').first()).toMatchScreenshot({ maxDiffPixels: 50 });
```

---

## Reduced Motion Test Variant

```typescript
test('respects reduced motion', async ({ page }) => {
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await page.goto('/');
  // No running animations
  expect(await page.evaluate(() =>
    document.getAnimations().some(a => a.playState === 'running')
  )).toBe(false);
});
```

---

## Dark Mode / Forced Colors Test Variants

```typescript
test('dark mode contrast', async ({ page }) => {
  await page.emulateMedia({ colorScheme: 'dark' });
  await page.goto('/');
  const r = await new AxeBuilder({ page }).withTags(['wcag2aa']).analyze();
  expect(r.violations.filter(v => v.id === 'color-contrast')).toEqual([]);
});

test('forced colors mode', async ({ page }) => {
  await page.emulateMedia({ forcedColors: 'active' });
  await page.goto('/');
  expect(await page.getByRole('button', { name: 'Submit' }).isVisible()).toBe(true);
  expect((await new AxeBuilder({ page }).analyze()).violations).toEqual([]);
});
```

---

## Dialog / Popover Testing Protocol

```typescript
test('dialog: focus trap + escape + focus return', async ({ page }) => {
  await page.goto('/settings');
  const trigger = page.getByRole('button', { name: 'Delete Account' });
  await trigger.click();
  const dialog = page.getByRole('dialog');
  await expect(dialog).toBeVisible();

  // Focus inside dialog
  const focused = await page.evaluate(() => document.activeElement?.tagName);
  expect(['BUTTON', 'INPUT']).toContain(focused);

  // Tab stays in dialog
  for (let i = 0; i < 3; i++) await page.keyboard.press('Tab');
  expect(await page.evaluate(() =>
    document.querySelector('[role="dialog"]')?.contains(document.activeElement)
  )).toBe(true);

  // Escape closes, focus returns
  await page.keyboard.press('Escape');
  await expect(dialog).not.toBeVisible();
  await expect(trigger).toBeFocused();
});
```

---

## Flutter Semantics Test Patterns

```dart
testWidgets('page meets a11y guidelines', (tester) async {
  final handle = tester.ensureSemantics();
  await tester.pumpWidget(const MaterialApp(home: MyPage()));
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  handle.dispose();
});
```

---

## CI Accessibility Pipeline

### GitHub Actions (Essential Steps)

```yaml
# 1. pnpm vitest run tests/a11y/           — Unit axe tests
# 2. pnpm build && pnpm start &            — Build + serve
# 3. pnpm playwright test tests/e2e/a11y/  — E2E axe + ARIA snapshots
# 4. npx pa11y-ci --config .pa11yci.json   — Pa11y WCAG2AAA scan
```

### Pre-Commit Hook (Quick Checks)

```bash
# Block on physical CSS classes (RTL violation)
grep -rn "ml-\|mr-\|pl-\|pr-\|left-\|right-\|text-left\|text-right" \
  --include="*.tsx" $(git diff --cached --name-only) && exit 1

# Warn on missing alt text
grep -rn "<img\|<Image" --include="*.tsx" $(git diff --cached --name-only) | grep -v "alt="

# Warn on outline-none without focus-visible
grep -rn "outline-none" --include="*.tsx" $(git diff --cached --name-only) | grep -v "focus-visible:"
```

---

## Multi-Page A11y Audit Template

```typescript
const PAGES = ['/', '/login', '/dashboard', '/settings', '/products'];

for (const path of PAGES) {
  test(`${path} passes axe WCAG 2.2`, async ({ page }) => {
    await page.goto(path);
    await page.waitForLoadState('networkidle');
    expect((await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag22aa']).analyze()).violations).toEqual([]);
  });

  test(`${path} a11y OK with reduced motion`, async ({ page }) => {
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await page.goto(path);
    expect((await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa']).analyze()).violations).toEqual([]);
  });

  test(`${path} contrast OK in dark mode`, async ({ page }) => {
    await page.emulateMedia({ colorScheme: 'dark' });
    await page.goto(path);
    const r = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa']).analyze();
    expect(r.violations.filter(v => v.id === 'color-contrast')).toEqual([]);
  });
}
```

---

<!-- A11Y_TESTING v24.6.0 | axe-core 4.11.1, @chialab/vitest-axe 0.19.0, Playwright 1.58.2, Pa11y 9, CI -->
