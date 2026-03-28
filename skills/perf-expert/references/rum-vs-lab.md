# RUM vs Lab Data - Comprehensive Reference

> **APEX-PERF v24.7.0** | Domain: Performance/Monitoring
> Consolidates: rum-vs-lab

---

## 1. KEY DIFFERENCES

| Aspect | Lab Data (Synthetic) | Field Data (RUM) |
|--------|---------------------|-------------------|
| Source | Simulated environment | Real user visits |
| Consistency | Reproducible | Variable |
| Network | Throttled/consistent | Real conditions |
| Device | Emulated | Actual devices |
| Use case | Debugging, CI/CD | Ranking, real impact |
| **Google ranking** | No | **Yes (CrUX)** |
| Tools | Lighthouse, WebPageTest, DevTools | CrUX, Vercel Analytics, custom RUM |

### The 75th Percentile Requirement

Google measures at the **75th percentile** -- meaning 75% of your users must have a "Good" experience for the metric to pass.

```
Example Distribution (100 users):
Users  1-50:  LCP = 1.5s  (Good)
Users 51-70:  LCP = 2.0s  (Good)
Users 71-75:  LCP = 2.4s  (Good)     <-- 75th percentile = Good!
Users 76-85:  LCP = 3.0s  (Needs Improvement)
Users 86-100: LCP = 5.0s  (Poor)

Result: Page PASSES LCP (75th percentile <= 2.5s)
```

---

## 2. WHEN TO USE WHICH

| Goal | Use | Why |
|------|-----|-----|
| Check Google ranking status | Field (CrUX/PSI) | Google uses CrUX for ranking |
| Debug specific issue | Lab (Lighthouse/DevTools) | Reproducible, detailed |
| CI/CD performance gate | Lab (Lighthouse CI) | Consistent, automatable |
| Monitor production | Field (RUM) | Real user experience |
| Before/after comparison | Lab (controlled) | Eliminate variables |
| Understand real user experience | Field (RUM) | Actual conditions |
| Identify slow user segments | Field (RUM + segmentation) | Device/network/geo data |

---

## 3. FIELD DATA SOURCES

### Chrome User Experience Report (CrUX)

```typescript
// Query CrUX API
async function getCrUXData(url: string): Promise<CrUXResult> {
  const response = await fetch(
    `https://chromeuxreport.googleapis.com/v1/records:queryRecord?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        url,
        metrics: [
          'largest_contentful_paint',
          'interaction_to_next_paint',
          'cumulative_layout_shift',
        ],
      }),
    },
  );
  return response.json();
}
```

### PageSpeed Insights (Combines Both)

```
PageSpeed Insights Report
├── Field Data (CrUX)           <-- Use for ranking assessment
│   ├── LCP: 2.1s (Good)
│   ├── INP: 180ms (Good)
│   └── CLS: 0.05 (Good)
│
└── Lab Data (Lighthouse)       <-- Use for debugging
    ├── Performance: 85
    ├── LCP: 1.8s
    └── Opportunities & Diagnostics
```

### Vercel Speed Insights

```tsx
// app/layout.tsx
import { SpeedInsights } from '@vercel/speed-insights/next';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="he" dir="rtl">
      <body>
        {children}
        <SpeedInsights />
      </body>
    </html>
  );
}
```

### Custom RUM with web-vitals

```typescript
// lib/performance/rum.ts
import { onCLS, onINP, onLCP, onFCP, onTTFB } from 'web-vitals';

// Network Information API (Navigator extension)
interface NetworkInformation extends EventTarget {
  readonly effectiveType: 'slow-2g' | '2g' | '3g' | '4g';
  readonly downlink: number;
  readonly rtt: number;
  readonly saveData: boolean;
  addEventListener(type: 'change', listener: EventListener): void;
  removeEventListener(type: 'change', listener: EventListener): void;
}

// Device Memory API + Network Information API on Navigator
declare global {
  interface Navigator {
    readonly connection?: NetworkInformation;
    readonly deviceMemory?: number;
  }
}

interface RUMMetric {
  name: string;
  value: number;
  rating: 'good' | 'needs-improvement' | 'poor';
  delta: number;
  id: string;
}

function sendToAnalytics(metric: RUMMetric): void {
  const body = JSON.stringify({
    name: metric.name,
    value: metric.value,
    rating: metric.rating,
    page: window.location.pathname,
    // Connection context
    connection: navigator.connection?.effectiveType,
    downlink: navigator.connection?.downlink,
    rtt: navigator.connection?.rtt,
    saveData: navigator.connection?.saveData,
    // Device context
    deviceMemory: navigator.deviceMemory,
    cores: navigator.hardwareConcurrency,
    mobile: /Mobi|Android/i.test(navigator.userAgent),
    // Timestamp
    timestamp: Date.now(),
  });

  // sendBeacon for reliability (fires even during page unload)
  if (navigator.sendBeacon) {
    navigator.sendBeacon('/api/vitals', body);
  } else {
    fetch('/api/vitals', { body, method: 'POST', keepalive: true });
  }
}

export function initRUM(): void {
  onCLS(sendToAnalytics);
  onINP(sendToAnalytics);
  onLCP(sendToAnalytics);
  onFCP(sendToAnalytics);
  onTTFB(sendToAnalytics);
}
```

---

## 4. FIELD DATA SEGMENTATION

### Type Declarations for Non-Standard Browser APIs

```typescript
// Augment Navigator for Network Information API + Device Memory API
interface NetworkInformation {
  effectiveType: 'slow-2g' | '2g' | '3g' | '4g';
  downlink: number;
  rtt: number;
  saveData: boolean;
}

declare global {
  interface Navigator {
    connection?: NetworkInformation;
    deviceMemory?: number;
  }
}
```

### By Connection Type

```typescript
function getConnectionTier(): 'poor' | 'moderate' | 'good' | 'excellent' {
  const conn = navigator.connection;
  if (!conn) return 'good'; // Default assumption

  if (conn.effectiveType === 'slow-2g' || conn.effectiveType === '2g') return 'poor';
  if (conn.effectiveType === '3g') return 'moderate';
  if (conn.downlink >= 10) return 'excellent';
  return 'good';
}
```

### By Device Capability

```typescript
function getDeviceTier(): 'low' | 'mid' | 'high' {
  const memory = navigator.deviceMemory;
  const cores = navigator.hardwareConcurrency;

  if (memory && memory <= 2) return 'low';
  if (memory && memory <= 4) return 'mid';
  if (cores && cores <= 2) return 'low';
  if (cores && cores <= 4) return 'mid';
  return 'high';
}
```

### By Geography (Server-Side)

```typescript
// app/api/vitals/route.ts
import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  const country = request.headers.get('x-vercel-ip-country');
  const city = request.headers.get('x-vercel-ip-city');
  const metric = await request.json();

  await saveMetric({
    ...metric,
    geo: { country, city },
  });

  return NextResponse.json({ ok: true });
}
```

---

## 5. LAB DATA SOURCES

### Lighthouse CLI

```bash
# Basic audit
npx lighthouse https://example.com --output=json --output-path=./report.json

# Mobile with throttling
npx lighthouse https://example.com --preset=perf --throttling-method=simulate

# Desktop
npx lighthouse https://example.com --preset=desktop
```

### Chrome DevTools Performance

```
1. Open DevTools (F12)
2. Performance tab
3. Check "Screenshots" and "Web Vitals"
4. Click Record
5. Reload page (Cmd+Shift+R)
6. Stop recording
7. Analyze timeline:
   - Main thread activity
   - Long tasks (red bars)
   - Layout shifts (purple markers)
   - LCP (green marker)
```

### WebPageTest API

```bash
curl "https://www.webpagetest.org/runtest.php?url=https://example.com&k=YOUR_API_KEY&f=json&runs=3&location=ec2-eu-west-1.3G"
```

---

## 6. MONITORING STRATEGY

```
┌─────────────────────────────────────────────────────────────┐
│                    MONITORING STRATEGY                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Development          Staging              Production        │
│  ┌──────────┐        ┌──────────┐         ┌──────────┐      │
│  │ DevTools  │        │Lighthouse│         │   RUM    │      │
│  │ Local     │   ->   │   CI     │    ->   │  CrUX    │      │
│  └──────────┘        └──────────┘         └──────────┘      │
│       |                   |                    |             │
│    Debug              Gate PRs           Track real          │
│    issues             Block bad          user impact         │
│                       deploys                                │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Alert Configuration

```typescript
// lib/performance/alerts.ts
interface AlertConfig {
  metric: string;
  threshold: number;
  window: string;
  severity: 'info' | 'warn' | 'critical';
}

const alertConfigs: AlertConfig[] = [
  { metric: 'lcp_p75', threshold: 2500, window: '24h', severity: 'critical' },
  { metric: 'inp_p75', threshold: 200, window: '24h', severity: 'critical' },
  { metric: 'cls_p75', threshold: 0.1, window: '24h', severity: 'critical' },
  { metric: 'lcp_p75', threshold: 1500, window: '1h', severity: 'warn' },
  { metric: 'tbt_p75', threshold: 200, window: '24h', severity: 'warn' },
];

async function checkAlerts(): Promise<void> {
  for (const config of alertConfigs) {
    const value = await getMetricP75(config.metric, config.window);
    if (value > config.threshold) {
      await sendAlert({
        message: `${config.metric} p75 (${value}) exceeds threshold (${config.threshold})`,
        severity: config.severity,
      });
    }
  }
}
```

---

## 7. COMMON PITFALLS

### Pitfall 1: Optimizing Only for Lab

```
WRONG: "Lighthouse score is 100, we're done!"
RIGHT: "Lighthouse is 100, but CrUX shows LCP p75 = 3.5s (Poor)"
       -> Real users on slow connections have different experience
```

### Pitfall 2: Ignoring the Long Tail

```
WRONG: "Average LCP is 1.5s, great!"
RIGHT: "P75 LCP is 3.2s -- 25% of users have poor experience"
       -> Focus on slowest users, not average
```

### Pitfall 3: Lab-Only CI/CD

```yaml
# WRONG: Lab only
- name: Lighthouse CI
  run: lhci autorun

# RIGHT: Lab + Field monitoring
- name: Lighthouse CI
  run: lhci autorun
- name: Check CrUX
  run: npx crux-api --url=$URL --threshold=good
```

---

## 8. CHECKLIST

```markdown
## RUM vs Lab Monitoring Checklist

### Field Data (RUM)
- [ ] web-vitals 5.1.0 integrated
- [ ] Sending metrics to analytics endpoint
- [ ] Segmenting by device/connection/geo
- [ ] Monitoring 75th percentile
- [ ] Alerting on regressions
- [ ] Weekly CrUX review
- [ ] Vercel Speed Insights enabled

### Lab Data
- [ ] Lighthouse CI in pipeline
- [ ] Performance budgets set
- [ ] Blocking PRs on regression
- [ ] Testing on throttled network
- [ ] Testing on mobile emulation
- [ ] Multiple runs per URL (median)

### Combined Strategy
- [ ] Lab for debugging
- [ ] Field for truth
- [ ] Both for complete picture
- [ ] Weekly review cadence
```

---

<!-- RUM_VS_LAB v24.7.0 | Field vs Lab, CrUX, RUM, monitoring, alerting -->
