# PWA Testing Patterns

> **v24.5.0 SINGULARITY FORGE** | Domain: PWA Testing | Law: #1 (ZERO TRUST)

## Real Device Testing Matrix

| Device | OS | Browser | Priority | Why |
|--------|-----|---------|----------|-----|
| Samsung Galaxy A13 | Android 12 | Chrome | HIGH | Low-end, common |
| iPhone SE (3rd gen) | iOS 17 | Safari | HIGH | Small screen |
| Pixel 7a | Android 14 | Chrome | MEDIUM | Mid-range |
| iPhone 15 | iOS 18 | Safari | MEDIUM | Latest iOS |

## Service Worker Lifecycle Tests

```typescript
import { test, expect } from '@playwright/test';

test.describe('Service Worker Lifecycle', () => {
  test('registers and activates', async ({ page }) => {
    await page.goto('/');

    const swState = await page.evaluate(async () => {
      const reg = await navigator.serviceWorker.getRegistration();
      return reg?.active?.state;
    });

    expect(swState).toBe('activated');
  });

  test('handles updates correctly', async ({ page }) => {
    await page.goto('/');

    const hasWaiting = await page.evaluate(async () => {
      const reg = await navigator.serviceWorker.getRegistration();
      return !!reg?.waiting;
    });

    console.log('Update waiting:', hasWaiting);
  });
});
```

## Offline Mode E2E Tests

```typescript
test.describe('Offline Functionality', () => {
  test('app works offline', async ({ page, context }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    await context.setOffline(true);
    await page.goto('/');

    await expect(page.locator('main')).toBeVisible();
    await context.setOffline(false);
  });

  test('shows offline indicator', async ({ page, context }) => {
    await page.goto('/');
    await context.setOffline(true);
    await page.reload();

    await expect(page.locator('[data-testid="offline-indicator"]')).toBeVisible();
  });

  test('queues actions while offline', async ({ page, context }) => {
    await page.goto('/');
    await context.setOffline(true);

    await page.click('[data-testid="submit-button"]');
    await expect(page.locator('[data-testid="pending-sync"]')).toBeVisible();

    await context.setOffline(false);
    await expect(page.locator('[data-testid="pending-sync"]')).not.toBeVisible();
  });
});
```

## Network Simulation Tests

```typescript
test.describe('Slow Network', () => {
  test('handles slow 3G gracefully', async ({ page, context }) => {
    const client = await context.newCDPSession(page);
    await client.send('Network.emulateNetworkConditions', {
      offline: false,
      downloadThroughput: (500 * 1024) / 8,
      uploadThroughput: (500 * 1024) / 8,
      latency: 400,
    });

    const startTime = Date.now();
    await page.goto('/');
    const loadTime = Date.now() - startTime;

    expect(loadTime).toBeLessThan(5000);
  });
});
```

## Lighthouse CI Integration

```javascript
// lighthouserc.cjs (Lighthouse CI still uses CJS config)
module.exports = {
  ci: {
    collect: {
      url: ['http://localhost:3000/', 'http://localhost:3000/dashboard'],
      numberOfRuns: 3,
    },
    assert: {
      assertions: {
        'categories:performance': ['error', { minScore: 0.9 }],
        'categories:pwa': ['error', { minScore: 1 }],
        'categories:accessibility': ['error', { minScore: 0.9 }],
        'first-contentful-paint': ['error', { maxNumericValue: 1800 }],
        'largest-contentful-paint': ['error', { maxNumericValue: 2500 }],
        'cumulative-layout-shift': ['error', { maxNumericValue: 0.1 }],
        'interactive': ['error', { maxNumericValue: 3800 }],
      },
    },
    upload: {
      target: 'temporary-public-storage',
    },
  },
};
```

## Install Prompt Tests

```typescript
test.describe('Install Prompt', () => {
  test('shows install button when installable', async ({ page }) => {
    await page.goto('/');

    await page.evaluate(() => {
      window.dispatchEvent(new Event('beforeinstallprompt'));
    });

    await expect(page.locator('[data-testid="install-button"]')).toBeVisible();
  });

  test('install button has proper touch target', async ({ page }) => {
    await page.goto('/');

    const button = page.locator('[data-testid="install-button"]');
    const box = await button.boundingBox();

    expect(box?.width).toBeGreaterThanOrEqual(44);
    expect(box?.height).toBeGreaterThanOrEqual(44);
  });
});
```

## Push Notification Tests

```typescript
test.describe('Push Notifications', () => {
  test('requests permission correctly', async ({ page, context }) => {
    await context.grantPermissions(['notifications']);

    await page.goto('/');
    await page.click('[data-testid="enable-notifications"]');

    const permission = await page.evaluate(() => Notification.permission);
    expect(permission).toBe('granted');
  });
});
```

## RTL Testing for PWA

```typescript
test.describe('RTL Support', () => {
  test('offline page renders correctly in RTL', async ({ page, context }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    await page.evaluate(() => {
      document.documentElement.dir = 'rtl';
      document.documentElement.lang = 'he';
    });

    await context.setOffline(true);
    await page.reload();

    const dir = await page.evaluate(() => document.documentElement.dir);
    expect(dir).toBe('rtl');

    const hasCorrectClasses = await page.evaluate(() => {
      const html = document.body.innerHTML;
      return !html.includes('ml-') && !html.includes('mr-');
    });
    expect(hasCorrectClasses).toBe(true);
  });
});
```

## Performance Metrics Collection

```typescript
test('collect Core Web Vitals', async ({ page }) => {
  await page.goto('/');

  const metrics = await page.evaluate(() => {
    return new Promise((resolve) => {
      const results: Record<string, number> = {};

      new PerformanceObserver((list) => {
        for (const entry of list.getEntries()) {
          if (entry.name === 'largest-contentful-paint') {
            results.lcp = entry.startTime;
          }
        }
      }).observe({ entryTypes: ['largest-contentful-paint'] });

      new PerformanceObserver((list) => {
        for (const entry of list.getEntries()) {
          results.cls = (results.cls || 0) + (entry as any).value;
        }
      }).observe({ entryTypes: ['layout-shift'] });

      setTimeout(() => resolve(results), 3000);
    });
  });

  console.log('Core Web Vitals:', metrics);
  expect((metrics as any).lcp).toBeLessThan(2500);
});
```

## Test Commands

```bash
# Run PWA tests
npx playwright test pwa.spec.ts

# Run with slow 3G simulation
npx playwright test --project=slow-3g

# Run Lighthouse CI
npx lhci autorun

# Test offline mode
npx playwright test --grep "offline"
```


<!-- PWA-EXPERT/TESTING v24.5.0 | Updated: 2026-02-19 -->
