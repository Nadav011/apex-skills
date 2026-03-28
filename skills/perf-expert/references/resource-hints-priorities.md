# Resource Hints & Priorities - Comprehensive Reference

> **APEX-PERF v24.7.0** | Domain: Performance/Loading
> Consolidates: resource-hints, early-hints

---

## 1. RESOURCE HINT TYPES

### Priority and Timing Matrix

| Hint | Purpose | When Used | Impact |
|------|---------|-----------|--------|
| `dns-prefetch` | Resolve DNS early | Third-party origins | Low |
| `preconnect` | DNS + TCP + TLS | Critical third-party origins | Medium |
| `preload` | Fetch critical resource | LCP image, critical fonts, above-fold CSS | High |
| `prefetch` | Fetch next-navigation resource | Likely next pages | Low-Medium |
| `modulepreload` | Preload JS modules | Critical route chunks | Medium |
| `fetchPriority` | Adjust resource priority | Hero images, critical scripts | High |
| Early Hints (103) | Pre-response hints | Before HTML generation | Very High |

---

## 2. DNS-PREFETCH & PRECONNECT

### Usage

```html
<!-- DNS-only resolution (lightweight) -->
<link rel="dns-prefetch" href="https://fonts.googleapis.com" />
<link rel="dns-prefetch" href="https://analytics.example.com" />

<!-- Full connection (DNS + TCP + TLS) for critical origins -->
<link rel="preconnect" href="https://cdn.example.com" crossorigin />
<link rel="preconnect" href="https://api.example.com" crossorigin />

<!-- Pair preconnect with dns-prefetch for fallback -->
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
<link rel="dns-prefetch" href="https://fonts.gstatic.com" />
```

### Best Practices

- Maximum **2-4 preconnect** hints (each costs ~100ms of CPU)
- Use `dns-prefetch` for additional origins (cheaper)
- Always add `crossorigin` for CORS resources (fonts, API calls)
- Place in `<head>` before any resource that uses the origin

---

## 3. PRELOAD

### Critical Resource Preloading

```html
<!-- Preload hero image (LCP element) -->
<link
  rel="preload"
  as="image"
  href="/hero.avif"
  type="image/avif"
  fetchpriority="high"
/>

<!-- Preload critical font -->
<link
  rel="preload"
  as="font"
  href="/fonts/Heebo-Variable.woff2"
  type="font/woff2"
  crossorigin
/>

<!-- Preload critical CSS -->
<link rel="preload" as="style" href="/critical.css" />

<!-- Preload critical script -->
<link rel="preload" as="script" href="/_next/static/chunks/main.js" />

<!-- Responsive image preload -->
<link
  rel="preload"
  as="image"
  href="/hero-mobile.avif"
  type="image/avif"
  media="(max-width: 640px)"
/>
<link
  rel="preload"
  as="image"
  href="/hero-desktop.avif"
  type="image/avif"
  media="(min-width: 641px)"
/>
```

### Dynamic Preloading in Next.js

```typescript
// app/layout.tsx or page.tsx
import { headers } from 'next/headers';

export default async function Layout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="he" dir="rtl">
      <head>
        {/* Critical resource preloads */}
        <link rel="preconnect" href="https://cdn.supabase.co" crossOrigin="" />
        <link rel="preload" as="image" href="/hero.avif" fetchPriority="high" />
        <link
          rel="preload"
          as="font"
          href="/fonts/Heebo-Variable.woff2"
          type="font/woff2"
          crossOrigin=""
        />
      </head>
      <body>{children}</body>
    </html>
  );
}
```

---

## 4. PREFETCH & MODULEPRELOAD

### Next Page Prefetching

```html
<!-- Prefetch likely next page resources -->
<link rel="prefetch" href="/dashboard" />
<link rel="prefetch" as="script" href="/_next/static/chunks/dashboard.js" />

<!-- Module preload for critical JS modules -->
<link rel="modulepreload" href="/_next/static/chunks/main.js" />
```

### Next.js Link Prefetching

```tsx
import Link from 'next/link';

// Automatic prefetch on hover/viewport (default behavior)
<Link href="/dashboard">Dashboard</Link>

// Disable prefetch for rarely visited pages
<Link href="/admin/settings" prefetch={false}>
  Settings
</Link>

// Force prefetch immediately
<Link href="/products" prefetch={true}>
  Products
</Link>
```

---

## 5. FETCH PRIORITY API

### Priority Levels

| fetchPriority | Effect | Use For |
|---------------|--------|---------|
| `high` | Boost priority | Hero/LCP images, critical CSS |
| `low` | Lower priority | Below-fold images, analytics |
| `auto` | Browser decides | Default (most resources) |

### Usage Examples

```tsx
// Hero image -- high priority (LCP critical)
<img src="/hero.webp" alt="Hero" fetchPriority="high" />

// Next.js Image with priority
<Image src="/hero.webp" alt="Hero" priority /> {/* Sets fetchPriority="high" */}

// Below-fold image -- low priority
<img src="/footer-bg.webp" alt="" fetchPriority="low" loading="lazy" />

// Critical API fetch
fetch('/api/critical-data', { priority: 'high' });

// Non-critical API fetch
fetch('/api/analytics', { priority: 'low' });

// Critical script
<script src="/critical.js" fetchPriority="high" />

// Non-critical script
<script src="/analytics.js" fetchPriority="low" async />
```

---

## 6. HTTP 103 EARLY HINTS

### How Early Hints Work

```
Traditional Flow:
Client ──GET──> Server [processing 500ms] ──200 + HTML──> Client
                                                          [starts loading resources]

Early Hints Flow:
Client ──GET──> Server ──103 Early Hints──> Client [starts preloading!]
                        [processing 500ms]
                        ──200 + HTML──> Client [resources already loading!]

Time saved: 300-500ms on LCP
```

### Link Header Syntax

```http
HTTP/1.1 103 Early Hints
Link: </fonts/Heebo-Variable.woff2>; rel=preload; as=font; crossorigin
Link: </hero.avif>; rel=preload; as=image
Link: <https://cdn.supabase.co>; rel=preconnect; crossorigin

HTTP/1.1 200 OK
Content-Type: text/html
...
```

### CDN Configuration

#### Cloudflare

```
# Cloudflare automatically sends Early Hints
# from Link headers and <link> tags in HTML

# Enable in Cloudflare dashboard:
# Speed > Optimization > Early Hints: ON
```

#### Vercel

```json
// vercel.json
{
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "Link",
          "value": "</fonts/Heebo-Variable.woff2>; rel=preload; as=font; crossorigin, <https://cdn.supabase.co>; rel=preconnect; crossorigin"
        }
      ]
    }
  ]
}
```

#### NGINX

```nginx
location / {
    http2_push_preload on;

    add_header Link "</fonts/Heebo-Variable.woff2>; rel=preload; as=font; crossorigin" always;
    add_header Link "</hero.avif>; rel=preload; as=image" always;
    add_header Link "<https://cdn.supabase.co>; rel=preconnect; crossorigin" always;

    proxy_pass http://upstream;
}
```

### Early Hints Priority Table

| Resource | Priority | Early Hint? | Rationale |
|----------|----------|-------------|-----------|
| Critical font (Hebrew) | High | Yes | Prevents FOIT, CLS |
| Hero image | High | Yes | LCP element |
| Critical CSS | High | Yes | Render-blocking |
| CDN origin | High | Yes (preconnect) | API/image origins |
| Below-fold images | Low | No | Not critical path |
| Analytics script | Low | No | Non-essential |
| Next-page JS | Low | No | Prefetch later |

---

## 7. NEXT.JS RESOURCE HINT PATTERNS

### Complete Head Configuration

```tsx
// app/layout.tsx
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="he" dir="rtl">
      <head>
        {/* Preconnect -- critical third-party origins */}
        <link rel="preconnect" href="https://cdn.supabase.co" crossOrigin="" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="" />

        {/* DNS prefetch -- additional origins */}
        <link rel="dns-prefetch" href="https://analytics.example.com" />

        {/* Preload -- critical resources */}
        <link
          rel="preload"
          as="font"
          href="/fonts/Heebo-Variable.woff2"
          type="font/woff2"
          crossOrigin=""
        />
      </head>
      <body>{children}</body>
    </html>
  );
}

// Per-page preloads
// app/products/page.tsx
export default function ProductsPage() {
  return (
    <>
      <link rel="preload" as="image" href="/products-hero.avif" fetchPriority="high" />
      <main>
        {/* Page content */}
      </main>
    </>
  );
}
```

---

## 8. TESTING EARLY HINTS

```typescript
// tests/early-hints.spec.ts
import { test, expect } from '@playwright/test';

test('Early Hints are sent correctly', async ({ page }) => {
  const earlyHints: string[] = [];

  page.on('response', (response) => {
    const status = response.status();
    if (status === 103) {
      const linkHeader = response.headers()['link'];
      if (linkHeader) earlyHints.push(linkHeader);
    }
  });

  await page.goto('https://your-site.com');

  // Verify early hints were sent
  expect(earlyHints.length).toBeGreaterThan(0);

  // Verify critical font is preloaded
  const fontHint = earlyHints.find((h) => h.includes('font'));
  expect(fontHint).toBeDefined();
});
```

---

## 9. CHECKLIST

```markdown
## Resource Hints Checklist

### Preconnect (2-4 max)
- [ ] CDN origin (e.g., Supabase, Cloudinary)
- [ ] Font origin (fonts.gstatic.com if Google Fonts)
- [ ] API origin (if different from page)
- [ ] crossorigin attribute on CORS origins

### Preload
- [ ] LCP hero image with fetchPriority="high"
- [ ] Critical Hebrew font (WOFF2)
- [ ] Responsive image preload with media queries
- [ ] Critical above-fold CSS

### Fetch Priority
- [ ] Hero image: fetchPriority="high"
- [ ] Below-fold images: fetchPriority="low"
- [ ] Critical API calls: priority "high"
- [ ] Analytics: priority "low"

### Early Hints (103)
- [ ] CDN supports Early Hints (Cloudflare, Vercel)
- [ ] Critical font in Link header
- [ ] Hero image in Link header
- [ ] CDN preconnect in Link header
- [ ] Tested with Playwright

### Prefetch
- [ ] Likely next-page navigation prefetched
- [ ] Non-critical pages: prefetch={false}
- [ ] Module preload for critical JS
```

---

<!-- RESOURCE_HINTS v24.7.0 | Preload, prefetch, preconnect, fetchPriority, Early Hints (103) -->
