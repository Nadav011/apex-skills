# Lighthouse CI - Comprehensive Reference

> **APEX-PERF v24.7.0** | Domain: Performance/Auditing
> Lighthouse 13.0.3, @lhci/cli 0.15.1, GitHub Actions Integration

---

## 1. LIGHTHOUSE 13.0 CHANGES

### Insight-Based Audits (New in 13.0)

Lighthouse 13.0.3 introduces insight-based audits that provide more actionable performance diagnostics:

| Insight Audit | Replaces | What It Does |
|---------------|----------|-------------|
| `cls-culprits-insight` | cls-culprits | Pinpoints exact CLS-causing elements with attribution |
| `image-delivery-insight` | uses-webp-images, uses-optimized-images | Unified image format/size recommendations |
| `document-latency-insight` | server-response-time | TTFB analysis with sub-part breakdown |
| `render-blocking-insight` | render-blocking-resources | Identifies render-blocking with priority recommendations |

### Scoring Changes

```
Performance Score Weights (Lighthouse 13.0):
├── FCP:  10%
├── SI:   10%
├── LCP:  25%
├── TBT:  30%
├── CLS:  25%
└── Total: 100%
```

---

## 2. LHCI SETUP

### Installation

```bash
# Install LHCI CLI
pnpm add -D @lhci/cli@0.15.1

# Or globally
npm install -g @lhci/cli@0.15.1
```

### Configuration File

```javascript
// lighthouserc.js
module.exports = {
  ci: {
    collect: {
      // URLs to audit
      url: [
        'http://localhost:3000/',
        'http://localhost:3000/dashboard',
        'http://localhost:3000/products',
      ],
      // Number of runs per URL (median used)
      numberOfRuns: 3,
      // Start server command
      startServerCommand: 'pnpm start',
      startServerReadyPattern: 'ready on',
      startServerReadyTimeout: 30000,
      // Lighthouse settings
      settings: {
        // Use mobile emulation (default)
        preset: 'desktop', // or 'perf' for mobile
        // Throttling
        throttling: {
          cpuSlowdownMultiplier: 4,
          requestLatencyMs: 150,
          downloadThroughputKbps: 1638.4,
          uploadThroughputKbps: 675,
        },
        // Only audit performance
        onlyCategories: ['performance'],
        // Skip specific audits
        skipAudits: ['uses-http2'],
      },
    },
    assert: {
      // APEX performance budgets
      assertions: {
        // Core Web Vitals -- BLOCK severity
        'largest-contentful-paint': ['error', { maxNumericValue: 2500 }],
        'interactive': ['error', { maxNumericValue: 3800 }],
        'cumulative-layout-shift': ['error', { maxNumericValue: 0.1 }],
        'total-blocking-time': ['error', { maxNumericValue: 200 }],

        // Scores -- BLOCK on < 70, WARN on < 90
        'categories:performance': ['error', { minScore: 0.7 }],
        'categories:accessibility': ['error', { minScore: 0.9 }],
        'categories:best-practices': ['error', { minScore: 0.9 }],
        'categories:seo': ['warn', { minScore: 0.9 }],

        // Resource optimization -- WARN severity
        'uses-webp-images': 'warn',
        'uses-optimized-images': 'warn',
        'uses-responsive-images': 'warn',
        'render-blocking-resources': 'warn',
        'unused-javascript': 'warn',
        'unused-css-rules': 'warn',
        'efficient-animated-content': 'warn',
        'unminified-javascript': 'error',
        'unminified-css': 'error',

        // Network -- WARN severity
        'uses-text-compression': 'error',
        'uses-long-cache-ttl': 'warn',
        'total-byte-weight': ['warn', { maxNumericValue: 500000 }],

        // DOM -- WARN severity
        'dom-size': ['warn', { maxNumericValue: 1500 }],
      },
    },
    upload: {
      // Upload to temporary public storage (free)
      target: 'temporary-public-storage',

      // Or upload to LHCI server
      // target: 'lhci',
      // serverBaseUrl: 'https://lhci.your-domain.com',
      // token: process.env.LHCI_TOKEN,
    },
  },
};
```

---

## 3. GITHUB ACTIONS INTEGRATION

### Basic Workflow

```yaml
# .github/workflows/lighthouse.yml
name: Lighthouse CI
on: [pull_request]

jobs:
  lighthouse:
    runs-on: [self-hosted, linux, x64, pop-os]
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '24'
          cache: 'pnpm'

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Build
        run: pnpm build

      - name: Run Lighthouse CI
        run: |
          npx @lhci/cli autorun --config=lighthouserc.js
        env:
          LHCI_GITHUB_APP_TOKEN: ${{ secrets.LHCI_GITHUB_APP_TOKEN }}

      - name: Upload results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: lighthouse-results
          path: .lighthouseci/
          retention-days: 30
```

### Advanced Workflow with Status Checks

```yaml
# .github/workflows/perf-gate.yml
name: Performance Gate
on:
  pull_request:
    branches: [main, develop]

concurrency:
  group: perf-${{ github.ref }}
  cancel-in-progress: true

jobs:
  lighthouse:
    runs-on: [self-hosted, linux, x64, pop-os]
    strategy:
      matrix:
        url:
          - /
          - /dashboard
          - /products
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '24'
          cache: 'pnpm'

      - run: pnpm install --frozen-lockfile
      - run: pnpm build

      - name: Lighthouse CI
        uses: treosh/lighthouse-ci-action@v12
        with:
          urls: |
            http://localhost:3000${{ matrix.url }}
          budgetPath: ./budget.json
          uploadArtifacts: true
          temporaryPublicStorage: true
          runs: 3

      - name: Check results
        if: always()
        run: |
          SCORE=$(cat .lighthouseci/manifest.json | jq '.[0].summary.performance')
          echo "Performance score: $SCORE"
          if (( $(echo "$SCORE < 0.70" | bc -l) )); then
            echo "::error::Performance score $SCORE is below 0.70 threshold"
            exit 1
          fi
```

---

## 4. PERFORMANCE BUDGETS

### Budget Configuration

```json
// budget.json
[
  {
    "path": "/*",
    "timings": [
      { "metric": "interactive", "budget": 3800 },
      { "metric": "first-contentful-paint", "budget": 1800 },
      { "metric": "largest-contentful-paint", "budget": 2500 },
      { "metric": "total-blocking-time", "budget": 200 },
      { "metric": "cumulative-layout-shift", "budget": 0.1 },
      { "metric": "speed-index", "budget": 3400 }
    ],
    "resourceSizes": [
      { "resourceType": "script", "budget": 120 },
      { "resourceType": "stylesheet", "budget": 30 },
      { "resourceType": "image", "budget": 200 },
      { "resourceType": "font", "budget": 80 },
      { "resourceType": "total", "budget": 500 },
      { "resourceType": "third-party", "budget": 50 }
    ],
    "resourceCounts": [
      { "resourceType": "script", "budget": 15 },
      { "resourceType": "stylesheet", "budget": 5 },
      { "resourceType": "image", "budget": 20 },
      { "resourceType": "font", "budget": 4 },
      { "resourceType": "third-party", "budget": 5 }
    ]
  }
]
```

---

## 5. CUSTOM AUDITS

### Custom Performance Audit

```typescript
// custom-audits/bundle-size-audit.ts
import { Audit } from 'lighthouse';

class BundleSizeAudit extends Audit {
  static get meta() {
    return {
      id: 'bundle-size-check',
      title: 'JavaScript bundle is within budget',
      failureTitle: 'JavaScript bundle exceeds budget',
      description: 'Check that initial JS bundle is under 100KB gzipped (APEX target)',
      requiredArtifacts: ['devtoolsLogs', 'traces'],
    };
  }

  interface NetworkRecord {
    resourceType: string;
    transferSize: number;
  }

  interface LighthouseArtifacts {
    devtoolsLogs: Record<string, NetworkRecord[]>;
  }

  static audit(artifacts: LighthouseArtifacts) {
    const devtoolsLog = artifacts.devtoolsLogs[Audit.DEFAULT_PASS];
    const networkRecords = devtoolsLog
      .filter((r) => r.resourceType === 'Script')
      .filter((r) => r.transferSize > 0);

    const totalJS = networkRecords.reduce(
      (sum, r) => sum + r.transferSize,
      0
    );

    const totalKB = totalJS / 1024;
    const passed = totalKB < 100;

    return {
      score: passed ? 1 : 0,
      numericValue: totalKB,
      numericUnit: 'kilobyte',
      displayValue: `${totalKB.toFixed(1)} KB total JS (budget: 100 KB)`,
    };
  }
}

export default BundleSizeAudit;
```

### Custom Gatherer

```typescript
// custom-gatherers/dom-stats-gatherer.ts
import { Gatherer } from 'lighthouse';

class DOMStatsGatherer extends Gatherer {
  async afterPass(passContext: { driver: { evaluate: <T>(fn: () => T) => Promise<T> } }) {
    const driver = passContext.driver;

    const domStats = await driver.evaluate(() => {
      const all = document.querySelectorAll('*');
      let maxDepth = 0;
      let maxChildren = 0;

      all.forEach((el) => {
        let depth = 0;
        let current: Element | null = el;
        while (current.parentElement) {
          depth++;
          current = current.parentElement;
        }
        maxDepth = Math.max(maxDepth, depth);
        maxChildren = Math.max(maxChildren, el.children.length);
      });

      return {
        totalElements: all.length,
        maxDepth,
        maxChildren,
      };
    });

    return domStats;
  }
}

export default DOMStatsGatherer;
```

---

## 6. LHCI SERVER (Self-Hosted)

### Docker Setup

```yaml
# docker-compose.yml
version: '3.8'
services:
  lhci-server:
    image: patrickhulce/lhci-server:latest
    ports:
      - '9001:9001'
    volumes:
      - lhci-data:/data
    environment:
      - LHCI_STORAGE__SQL_DIALECT=sqlite
      - LHCI_STORAGE__SQL_DATABASE_PATH=/data/lhci.db

volumes:
  lhci-data:
```

### Server Configuration

```javascript
// lhci-server.config.js
module.exports = {
  server: {
    port: 9001,
    storage: {
      sqlDialect: 'postgres',
      sqlConnectionUrl: process.env.DATABASE_URL,
      sqlDatabasePath: undefined,
    },
    // Delete old builds after 90 days
    deleteOldBuildsCron: {
      schedule: '0 0 * * *', // Daily at midnight
      maxAgeInDays: 90,
    },
  },
};
```

---

## 7. PROGRAMMATIC USAGE

### Running Lighthouse Programmatically

```typescript
// scripts/lighthouse-audit.ts
import lighthouse from 'lighthouse';
import chromeLauncher from 'chrome-launcher';

interface AuditResult {
  url: string;
  performance: number;
  lcp: number;
  inp: number;
  cls: number;
  tbt: number;
  fcp: number;
  si: number;
}

async function runAudit(url: string): Promise<AuditResult> {
  const chrome = await chromeLauncher.launch({
    chromeFlags: ['--headless', '--no-sandbox'],
  });

  const result = await lighthouse(url, {
    port: chrome.port,
    onlyCategories: ['performance'],
    output: 'json',
  });

  await chrome.kill();

  const { lhr } = result!;
  const audits = lhr.audits;

  return {
    url,
    performance: lhr.categories.performance.score! * 100,
    lcp: audits['largest-contentful-paint'].numericValue!,
    inp: audits['interaction-to-next-paint']?.numericValue ?? 0,
    cls: audits['cumulative-layout-shift'].numericValue!,
    tbt: audits['total-blocking-time'].numericValue!,
    fcp: audits['first-contentful-paint'].numericValue!,
    si: audits['speed-index'].numericValue!,
  };
}

// Run multiple URLs
async function auditSite(urls: string[]): Promise<AuditResult[]> {
  const results: AuditResult[] = [];
  for (const url of urls) {
    const result = await runAudit(url);
    results.push(result);
    console.log(`${url}: Performance ${result.performance}`);
  }
  return results;
}
```

---

## 8. TROUBLESHOOTING

### Common Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| Inconsistent scores | Variability in runs | Use numberOfRuns: 5, take median |
| Server not ready | Startup timeout | Increase startServerReadyTimeout |
| Chrome crashes | Memory issues | Add --no-sandbox --disable-dev-shm-usage |
| Missing metrics | Page not fully loaded | Increase maxWaitForLoad |
| LHCI upload fails | Token/URL mismatch | Verify LHCI_TOKEN and serverBaseUrl |

### Debugging Commands

```bash
# Run single audit with verbose output
npx @lhci/cli collect --url=http://localhost:3000 --numberOfRuns=1 -v

# Check configuration
npx @lhci/cli healthcheck --config=lighthouserc.js

# Open last report in browser
npx @lhci/cli open

# Assert without collecting (use existing results)
npx @lhci/cli assert --config=lighthouserc.js
```

---

## 9. CHECKLIST

```markdown
## Lighthouse CI Checklist

### Setup
- [ ] @lhci/cli installed (0.15.1+)
- [ ] lighthouserc.js configured with APEX thresholds
- [ ] budget.json with resource budgets
- [ ] GitHub Action workflow created
- [ ] LHCI_GITHUB_APP_TOKEN configured

### Assertions
- [ ] Performance score >= 70 (BLOCK)
- [ ] LCP <= 2500ms (BLOCK)
- [ ] CLS <= 0.1 (BLOCK)
- [ ] TBT <= 200ms (BLOCK)
- [ ] Accessibility >= 90 (BLOCK)
- [ ] No unminified JS/CSS (BLOCK)
- [ ] Text compression enabled (BLOCK)

### CI/CD
- [ ] Runs on every PR
- [ ] Results uploaded as artifacts
- [ ] Status checks required for merge
- [ ] Performance trends tracked
- [ ] Budget violations block merge
```

---

<!-- LIGHTHOUSE_CI v24.7.0 | Lighthouse 13.0.3, @lhci/cli 0.15.1, Custom Audits, CI/CD -->
