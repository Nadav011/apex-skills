# Third-Party Script Audit - Comprehensive Reference

> **APEX-PERF v24.7.0** | Domain: Performance/Third-Party
> Consolidates: third-party-audit

---

## 1. THIRD-PARTY IMPACT

### Common Third-Party Costs

| Script Type | Typical Size (gz) | Main Thread (ms) | TBT Impact |
|-------------|-------------------|-------------------|------------|
| Google Analytics (GA4) | 30KB | 50-100ms | Medium |
| Google Tag Manager | 33KB | 100-200ms | High |
| Facebook Pixel | 25KB | 50-150ms | Medium |
| Intercom | 200KB+ | 300-500ms | Very High |
| Hotjar | 40KB | 100-200ms | High |
| Stripe.js | 45KB | 50-100ms | Medium |
| reCAPTCHA | 150KB+ | 200-400ms | Very High |
| YouTube embed | 500KB+ | 500-1000ms | Critical |
| Chat widgets | 100-300KB | 200-500ms | Very High |

### APEX Third-Party Budget

```
Total third-party JS: < 50KB gzipped (< 30KB APEX target)
Maximum third-party scripts: 5
Main thread blocking from third-party: < 100ms
```

---

## 2. NEXT.JS SCRIPT COMPONENT

### Loading Strategies

```tsx
import Script from 'next/script';

// 1. beforeInteractive -- Loads before hydration
// Only for critical scripts (very rare)
<Script
  src="https://polyfill.io/v3/polyfill.min.js"
  strategy="beforeInteractive"
/>

// 2. afterInteractive -- Loads immediately after hydration (default)
// For scripts needed soon but not blocking
<Script
  src="https://www.googletagmanager.com/gtag/js?id=G-XXXXX"
  strategy="afterInteractive"
/>

// 3. lazyOnload -- Loads during idle time
// For non-critical scripts
<Script
  src="https://connect.facebook.net/en_US/fbevents.js"
  strategy="lazyOnload"
/>

// 4. worker -- Runs in Web Worker via Partytown
// For scripts that don't need DOM access
<Script
  src="https://www.googletagmanager.com/gtag/js?id=G-XXXXX"
  strategy="worker"
/>
```

### Strategy Decision Matrix

| Strategy | When to Use | Impact on FCP/LCP | Impact on INP |
|----------|-------------|-------------------|---------------|
| `beforeInteractive` | Polyfills, auth SDKs | Delays FCP | None |
| `afterInteractive` | Analytics, A/B testing | None | Possible |
| `lazyOnload` | Social, chat, non-critical | None | None |
| `worker` | Analytics, tracking | None | None |

---

## 3. PARTYTOWN (Web Worker)

### Setup

```tsx
// app/layout.tsx
import { Partytown } from '@builder.io/partytown/react';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="he" dir="rtl">
      <head>
        <Partytown
          debug={process.env.NODE_ENV === 'development'}
          forward={['dataLayer.push', 'gtag']}
        />
      </head>
      <body>
        {children}
        {/* Scripts with type="text/partytown" run in Web Worker */}
        <script
          type="text/partytown"
          dangerouslySetInnerHTML={{
            __html: `
              window.dataLayer = window.dataLayer || [];
              function gtag(){dataLayer.push(arguments);}
              gtag('js', new Date());
              gtag('config', 'G-XXXXX');
            `,
          }}
        />
      </body>
    </html>
  );
}
```

### What Works with Partytown

| Script | Compatible | Notes |
|--------|:---:|-------|
| Google Analytics | Yes | Forward dataLayer.push |
| Google Tag Manager | Partial | Some custom tags may fail |
| Facebook Pixel | Yes | Forward fbq |
| Hotjar | Yes | Uses proxy for DOM access |
| Intercom | No | Heavy DOM manipulation |
| Stripe | No | Needs real DOM for PCI |
| reCAPTCHA | No | Needs real DOM |

---

## 4. FACADE PATTERN

### YouTube Facade

```tsx
// components/YouTubeFacade.tsx
'use client';

import { useState } from 'react';
import Image from 'next/image';

interface YouTubeFacadeProps {
  videoId: string;
  title: string;
}

export function YouTubeFacade({ videoId, title }: YouTubeFacadeProps) {
  const [loaded, setLoaded] = useState(false);

  if (loaded) {
    return (
      <iframe
        src={`https://www.youtube-nocookie.com/embed/${videoId}?autoplay=1`}
        title={title}
        allow="autoplay; encrypted-media"
        allowFullScreen
        className="aspect-video w-full"
        loading="lazy"
      />
    );
  }

  return (
    <button
      onClick={() => setLoaded(true)}
      className="group relative aspect-video w-full overflow-hidden rounded-lg"
      aria-label={`Play video: ${title}`}
    >
      <Image
        src={`https://i.ytimg.com/vi/${videoId}/maxresdefault.jpg`}
        alt={title}
        fill
        sizes="(max-width: 768px) 100vw, 50vw"
        className="object-cover"
      />
      {/* Play button overlay */}
      <div className="absolute inset-0 flex items-center justify-center bg-black/20 group-hover:bg-black/30 transition-colors">
        <svg className="h-16 w-16 text-white" viewBox="0 0 68 48" fill="currentColor">
          <path d="M66.52 7.74c-.78-2.93-2.49-5.41-5.42-6.19C55.79.13 34 0 34 0S12.21.13 6.9 1.55C3.97 2.33 2.27 4.81 1.48 7.74.06 13.05 0 24 0 24s.06 10.95 1.48 16.26c.78 2.93 2.49 5.41 5.42 6.19C12.21 47.87 34 48 34 48s21.79-.13 27.1-1.55c2.93-.78 4.64-3.26 5.42-6.19C67.94 34.95 68 24 68 24s-.06-10.95-1.48-16.26z" />
          <path d="M45 24L27 14v20" fill="white" />
        </svg>
      </div>
    </button>
  );
}

// Savings: ~500KB JavaScript, ~500ms main thread time
```

### Chat Widget Facade

```tsx
// components/ChatFacade.tsx
'use client';

import { useState } from 'react';

export function ChatFacade() {
  const [loaded, setLoaded] = useState(false);

  if (loaded) {
    return <IntercomWidget />;
  }

  return (
    <button
      onClick={() => setLoaded(true)}
      className="fixed bottom-4 inset-e-4 z-50 flex min-h-11 min-w-11 items-center gap-2 rounded-full bg-primary px-4 py-3 text-white shadow-lg"
      aria-label="Open chat"
    >
      <ChatIcon className="h-5 w-5" />
      <span className="hidden sm:inline">Chat with us</span>
    </button>
  );
}
```

---

## 5. THIRD-PARTY AUDIT SCRIPT

```typescript
// scripts/audit-third-party.ts
import puppeteer from 'puppeteer';

interface ThirdPartyResult {
  url: string;
  transferSize: number;
  mainThreadTime: number;
  blockingTime: number;
}

async function auditThirdParty(pageUrl: string): Promise<ThirdPartyResult[]> {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();

  // Enable CDP for main thread timing
  const client = await page.target().createCDPSession();
  await client.send('Performance.enable');

  const thirdParty: ThirdPartyResult[] = [];

  page.on('response', async (response) => {
    const url = response.url();
    const isThirdParty = !url.includes(new URL(pageUrl).hostname);

    if (isThirdParty && response.request().resourceType() === 'script') {
      const buffer = await response.buffer().catch(() => null);
      thirdParty.push({
        url,
        transferSize: buffer?.length ?? 0,
        mainThreadTime: 0, // Set after page load
        blockingTime: 0,
      });
    }
  });

  await page.goto(pageUrl, { waitUntil: 'networkidle0' });
  await browser.close();

  // Sort by size
  return thirdParty.sort((a, b) => b.transferSize - a.transferSize);
}
```

---

## 6. CONTENT SECURITY POLICY FOR THIRD-PARTY

```typescript
// Configure CSP to control third-party scripts
// vercel.json or proxy.ts
const cspDirectives = {
  'script-src': [
    "'self'",
    'https://www.googletagmanager.com',
    'https://www.google-analytics.com',
    // No eval, no inline by default
  ],
  'connect-src': [
    "'self'",
    'https://www.google-analytics.com',
    'https://fonts.googleapis.com',
    'https://fonts.gstatic.com',
  ],
  'img-src': [
    "'self'",
    'data:',
    'https://www.google-analytics.com',
  ],
};
```

---

## 7. CHECKLIST

```markdown
## Third-Party Audit Checklist

### Inventory
- [ ] All third-party scripts documented
- [ ] Size and main thread time measured
- [ ] Total third-party < 50KB (< 30KB APEX)
- [ ] Maximum 5 third-party scripts

### Loading Strategy
- [ ] Analytics: lazyOnload or worker strategy
- [ ] Chat: facade pattern (load on click)
- [ ] Video embeds: facade pattern (load on play)
- [ ] Social: lazyOnload or removed
- [ ] Critical scripts (auth, payment): afterInteractive

### Optimization
- [ ] Partytown for analytics scripts
- [ ] Facade pattern for heavy embeds
- [ ] next/script with appropriate strategy
- [ ] CSP configured for third-party origins
- [ ] Self-hosted where possible (fonts, analytics)

### Monitoring
- [ ] Third-party impact in Lighthouse
- [ ] Main thread blocking monitored
- [ ] Quarterly audit of third-party scripts
- [ ] Remove unused scripts
```

---

<!-- THIRD_PARTY_AUDIT v24.7.0 | Third-party costs, Script strategies, Partytown, facades -->
