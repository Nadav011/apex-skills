# Next.js 16 Accessibility Features & Patterns

> **v24.7.0** | Next.js 16.1.6 | React 19.2.4 | Biome 2.4.4 | Tailwind 4.2.1
> RTL-FIRST: `ms-`/`me-`/`ps-`/`pe-`/`inset-s-`/`inset-e-` — never `ml-`/`mr-`/`left-`/`right-`

---

## Built-In Accessibility Features

### Route Announcer (next/link)

Next.js injects a visually-hidden `<div aria-live="assertive">` that announces client-side route changes.

**Announcement resolution order:**

| Priority | Source | Condition |
|----------|--------|-----------|
| 1 | `document.title` | Non-empty string |
| 2 | First `<h1>` in DOM | `document.title` is empty |
| 3 | URL pathname | No `<h1>` found |

**Developer contracts (non-negotiable):**

```tsx
// REQUIRED: Unique, descriptive title on every page
// app/menu/page.tsx
export const metadata: Metadata = {
  title: 'Menu | Mexicani', // Route announcer reads this
  description: 'Browse our full menu selection',
};

// REQUIRED: Meaningful h1 on every page (fallback for Route Announcer)
export default function MenuPage() {
  return (
    <main id="main-content">
      <h1>Menu</h1> {/* Announced if title is empty */}
      {/* ... */}
    </main>
  );
}
```

Failure modes: pages without a title fall back to h1; pages without either announce the raw URL pathname — a poor SR experience.

### eslint-plugin-jsx-a11y (Biome 2.4.4)

Built into Next.js 16 default ESLint config. When using Biome 2.4.4 (project standard), these rules are enforced via Biome's a11y rule set — no separate plugin needed.

```json
// biome.json — a11y rules included in recommended
{
  "linter": {
    "rules": {
      "a11y": {
        "recommended": true,
        "noAccessKey": "error",
        "noAriaHiddenOnFocusable": "error",
        "noBlankTarget": "error",
        "noDistractingElements": "error",
        "noHeaderScope": "error",
        "noInteractiveElementToNoninteractiveRole": "error",
        "noNoninteractiveElementToInteractiveRole": "error",
        "noNoninteractiveTabindex": "error",
        "noPositiveTabindex": "error",
        "noRedundantAlt": "error",
        "noSvgWithoutTitle": "warn",
        "useAltText": "error",
        "useAnchorContent": "error",
        "useAriaActivedescendantWithTabindex": "error",
        "useAriaPropsForRole": "error",
        "useButtonType": "error",
        "useFocusableInteractive": "error",
        "useHeadingContent": "error",
        "useHtmlLang": "error",
        "useIframeTitle": "error",
        "useKeyWithClickEvents": "error",
        "useKeyWithMouseEvents": "error",
        "useMediaCaption": "error",
        "useValidAnchor": "error",
        "useValidAriaProps": "error",
        "useValidAriaRole": "error",
        "useValidAriaValues": "error",
        "useValidLang": "error"
      }
    }
  }
}
```

---

## What Next.js Does NOT Provide (Developer Responsibility)

| Gap | Developer Action Required |
|-----|--------------------------|
| Suspense-aware SR announcements | Add persistent `aria-live` region outside Suspense boundary |
| Focus management during route transitions | Implement `focusAfterTransition()` — see `async-content-a11y.md` |
| Skip-to-content link | Add manually to root layout |
| Heading hierarchy validation | Biome + manual review per page |
| Form error announcement | `useActionState` + `aria-live` region |
| Keyboard navigation in menus | Developer-managed `onKeyDown` handlers |

---

## Root Layout: Mandatory A11y Setup

```tsx
// app/layout.tsx
import type { Metadata } from 'next';

export const metadata: Metadata = {
  // Title template — each page provides the segment
  title: { template: '%s | AppName', default: 'AppName' },
  description: 'Application description for screen reader context',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    // ALWAYS set both lang AND dir on <html>
    <html lang="he" dir="rtl">
      <body>
        {/* Skip link — FIRST focusable element in DOM */}
        <a
          href="#main-content"
          className="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:inset-s-4
                     focus:z-50 focus:bg-white focus:text-black focus:p-4 focus:rounded-lg
                     focus:shadow-lg focus:outline focus:outline-2 focus:outline-blue-600"
        >
          דלג לתוכן הראשי
        </a>

        {/* Persistent announcement region — never unmounts */}
        <div
          id="page-announcer"
          role="status"
          aria-live="polite"
          aria-atomic="true"
          className="sr-only"
        />

        <header role="banner">
          <nav aria-label="ניווט ראשי">{/* ... */}</nav>
        </header>

        <main id="main-content" tabIndex={-1}>
          {children}
        </main>

        <footer role="contentinfo">{/* ... */}</footer>
      </body>
    </html>
  );
}
```

---

## proxy.ts (Replaces middleware.ts in Next.js 16)

No direct a11y impact — proxy.ts operates at the routing layer before rendering. However:

```typescript
// proxy.ts — ensure redirects don't create SR dead-ends
export default function proxy(request: NextRequest) {
  // WRONG: Silent redirect to /login — SR user gets no explanation
  // (acceptable behavior; handled by the login page announcing its purpose)

  // RIGHT: Redirect destination must be accessible
  // login page must announce "You must sign in to continue" via metadata or h1
  if (!isAuthenticated(request)) {
    return NextResponse.redirect(new URL('/login', request.url));
  }
}
```

---

## Server Components

Server Components render static HTML on the server — ARIA attributes work without client JS.

```tsx
// Server Component — correct heading hierarchy established server-side
async function CategoryPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params; // Next.js 16: await params required
  const category = await fetchCategory(slug);

  return (
    <section aria-labelledby={`cat-${category.id}`}>
      <h1 id={`cat-${category.id}`}>{category.name}</h1>
      <p>{category.description}</p>
      {/* Items rendered server-side — no hydration needed for static content */}
      <ul aria-label={`${category.name} items`}>
        {category.items.map((item) => (
          <li key={item.id}>
            <a href={`/items/${item.id}`} className="min-h-11 flex items-center">
              {item.name}
            </a>
          </li>
        ))}
      </ul>
    </section>
  );
}
```

**Client Components required for:**
- Interactive ARIA states (`aria-expanded`, `aria-selected`, `aria-checked`)
- Focus management (`useRef` + `.focus()`)
- Live regions that update dynamically
- Keyboard event handlers

---

## Error Pages A11y

```tsx
// app/error.tsx — must announce error and offer recovery
'use client';

export default function ErrorPage({
  error,
  reset,
}: {
  error: Error;
  reset: () => void;
}) {
  return (
    <main id="main-content" aria-labelledby="error-heading">
      {/* assertive: error is critical, user needs to know immediately */}
      <div role="alert" aria-atomic="true">
        <h1 id="error-heading" className="text-2xl font-bold">
          אירעה שגיאה
        </h1>
        <p className="mt-2 text-gray-600">{error.message}</p>
        <button
          onClick={reset}
          autoFocus
          className="mt-6 min-h-11 min-w-11 px-6 py-3 rounded-lg bg-blue-600 text-white
                     focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2"
        >
          נסה שוב
        </button>
      </div>
    </main>
  );
}
```

```tsx
// app/not-found.tsx
export default function NotFoundPage() {
  return (
    <main id="main-content" aria-labelledby="notfound-heading">
      <h1 id="notfound-heading">הדף לא נמצא</h1>
      <p>הדף שחיפשת אינו קיים.</p>
      <a
        href="/"
        className="mt-6 inline-flex min-h-11 min-w-11 items-center px-6 rounded-lg
                   border border-gray-300 focus-visible:outline focus-visible:outline-2"
      >
        חזרה לדף הבית
      </a>
    </main>
  );
}
```

```tsx
// app/loading.tsx
export default function LoadingPage() {
  return (
    // aria-busy + aria-label: SR user knows content is loading
    <main
      id="main-content"
      aria-busy="true"
      aria-label="טוען תוכן"
      className="animate-pulse p-6 space-y-4"
    >
      <div className="h-8 w-64 rounded bg-gray-200" aria-hidden="true" />
      <div className="h-4 w-full rounded bg-gray-200" aria-hidden="true" />
      <div className="h-4 w-3/4 rounded bg-gray-200" aria-hidden="true" />
    </main>
  );
}
```

---

## Form Actions A11y (useActionState + useFormStatus)

```tsx
'use client';

import { useActionState, useRef } from 'react';
import { useFormStatus } from 'react-dom';

type ActionState = { success: boolean; message: string } | null;

function SubmitButton() {
  const { pending } = useFormStatus();
  return (
    <button
      type="submit"
      disabled={pending}
      aria-busy={pending}
      className="min-h-11 min-w-11 px-6 rounded-lg bg-blue-600 text-white
                 disabled:opacity-60 focus-visible:outline focus-visible:outline-2"
    >
      {pending ? 'שולח…' : 'שלח'}
    </button>
  );
}

export function ContactForm({ submitAction }: { submitAction: (fd: FormData) => Promise<ActionState> }) {
  const [state, formAction] = useActionState(submitAction, null);
  const resultRef = useRef<HTMLDivElement>(null);

  // Announce result after server action completes
  React.useEffect(() => {
    if (state && resultRef.current) {
      resultRef.current.textContent = state.message;
    }
  }, [state]);

  return (
    <form action={formAction} noValidate>
      {/* Announcement region — outside form fields */}
      <div
        ref={resultRef}
        role={state?.success ? 'status' : 'alert'}
        aria-live={state?.success ? 'polite' : 'assertive'}
        aria-atomic="true"
        className="sr-only"
      />

      {/* Visible inline error — also links field to error via aria-describedby */}
      {state && !state.success && (
        <div
          id="form-error"
          className="mb-4 p-4 rounded-lg bg-red-50 border border-red-200 text-red-700 text-sm"
        >
          {state.message}
        </div>
      )}

      <div className="space-y-4">
        <div>
          <label htmlFor="email" className="block text-sm font-medium mb-1">
            דוא"ל
          </label>
          <input
            id="email"
            name="email"
            type="email"
            required
            aria-required="true"
            aria-describedby={state && !state.success ? 'form-error' : undefined}
            className="w-full min-h-11 rounded-lg border border-gray-300 px-3
                       focus-visible:outline focus-visible:outline-2 focus-visible:outline-blue-600"
          />
        </div>
        <SubmitButton />
      </div>
    </form>
  );
}
```

---

## Metadata A11y

```tsx
// Every page — mandatory fields
export const metadata: Metadata = {
  title: 'Page Name | App',  // Route Announcer reads this — must be unique
  description: 'Page description — visible to SR users via browser accessibility tree',
  // NEVER skip these on dynamic pages
};

// Root layout html element
// ALWAYS set both lang and dir — SR uses lang for pronunciation, dir for reading order
<html lang="he" dir="rtl">
```

| Metadata Field | A11y Impact | Default if Missing |
|---------------|-------------|--------------------|
| `title` | Route Announcer falls back to h1 → pathname | Poor SR experience on navigation |
| `description` | Accessible to SR via browser meta | No context on page load |
| `lang` on `<html>` | SR pronunciation, reading order | Defaults to browser language — wrong for Hebrew content |
| `dir` on `<html>` | Layout direction, caret position | LTR assumed — breaks RTL content |

---

## Playwright: Next.js A11y Test Suite

```typescript
// tests/nextjs-a11y.spec.ts
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

const ROUTES = ['/', '/menu', '/orders', '/profile'];

test.describe('Route Announcer behavior', () => {
  test('route announcer fires on client-side navigation', async ({ page }) => {
    await page.goto('/');
    // The Next.js route announcer element
    const announcer = page.locator('[aria-live="assertive"]').first();
    await page.click('nav a[href="/menu"]');
    await page.waitForURL('/menu');
    // Announcer should contain page title or h1 text
    await expect(announcer).not.toBeEmpty();
  });
});

test.describe('Skip link', () => {
  for (const route of ROUTES) {
    test(`skip link present and functional on ${route}`, async ({ page }) => {
      await page.goto(route);
      // Tab once to focus skip link
      await page.keyboard.press('Tab');
      const skipLink = page.locator('a[href="#main-content"]');
      await expect(skipLink).toBeFocused();
      // Activate skip link
      await page.keyboard.press('Enter');
      const main = page.locator('#main-content');
      await expect(main).toBeFocused();
    });
  }
});

test.describe('Page title uniqueness', () => {
  test('each route has unique, non-empty title', async ({ page }) => {
    const titles = new Set<string>();
    for (const route of ROUTES) {
      await page.goto(route);
      const title = await page.title();
      expect(title.trim()).not.toBe('');
      expect(titles.has(title)).toBe(false);
      titles.add(title);
    }
  });
});

test.describe('axe-core: no a11y violations', () => {
  for (const route of ROUTES) {
    test(`no violations on ${route}`, async ({ page }) => {
      await page.goto(route);
      const results = await new AxeBuilder({ page })
        .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
        .analyze();
      expect(results.violations).toHaveLength(0);
    });
  }
});

test.describe('Heading hierarchy', () => {
  for (const route of ROUTES) {
    test(`single h1 on ${route}`, async ({ page }) => {
      await page.goto(route);
      const h1Count = await page.locator('h1').count();
      expect(h1Count).toBe(1);
    });
  }
});

test.describe('Lang + dir attributes', () => {
  test('html element has lang=he and dir=rtl', async ({ page }) => {
    await page.goto('/');
    const lang = await page.locator('html').getAttribute('lang');
    const dir = await page.locator('html').getAttribute('dir');
    expect(lang).toBe('he');
    expect(dir).toBe('rtl');
  });
});
```

---

## Cross-References

- Async content + Suspense a11y: `references/async-content-a11y.md`
- View Transitions + route announcer interaction: `references/view-transitions-a11y.md`
- Playwright test setup: `references/a11y-testing.md`
- Form error patterns: `references/web-a11y.md`
- RTL layout fundamentals: `~/.claude/rules/quality/rtl-i18n.md`

---

<!-- NEXTJS_A11Y v24.7.0 | Updated: 2026-02-26 | Next.js 16.1.6 + React 19 + Biome 2.4.4 + useActionState -->
