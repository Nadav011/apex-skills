# Bundle Optimization - Comprehensive Reference

> **APEX-PERF v24.7.0** | Domain: Performance/Bundle
> Consolidates: bundle-optimization, bundle-composition, dependency-cost, unused-code

---

## 1. BUNDLE BUDGETS

### Size Budgets (gzipped)

| Resource | Budget | APEX Target | Critical |
|----------|--------|-------------|----------|
| Initial JS | < 120KB | < 100KB | BLOCK |
| Initial CSS | < 30KB | < 20KB | BLOCK |
| Per-route JS chunk | < 50KB | < 30KB | BLOCK |
| Hero image | < 100KB | < 50KB | WARN |
| Total initial load | < 500KB | < 350KB | BLOCK |
| Third-party JS | < 50KB | < 30KB | WARN |

### Ideal Bundle Composition

```
Total: ~100KB gzipped
├── Framework (React/Next.js): 35KB (35%)
│   ├── react: ~6KB
│   ├── react-dom: ~25KB (streamed)
│   └── next/router: ~4KB
├── UI Components: 20KB (20%)
│   ├── shadcn/ui primitives
│   ├── Radix UI (tree-shaken)
│   └── Icons (lucide-react, tree-shaken)
├── State Management: 10KB (10%)
│   ├── TanStack Query: ~8KB
│   └── Zustand/Jotai: ~2KB
├── Utilities: 10KB (10%)
│   ├── clsx: ~0.5KB
│   ├── tailwind-merge: ~3KB
│   ├── Zod: ~5KB (or boundary-only)
│   └── date-fns (tree-shaken): ~1.5KB
├── Business Logic: 15KB (15%)
│   └── App-specific code
└── Third-party: 10KB (10%)
    ├── Analytics: ~3KB
    ├── Error tracking: ~5KB
    └── Other: ~2KB
```

---

## 2. BUNDLE ANALYSIS TOOLS

### Next.js Bundle Analyzer

```typescript
// next.config.ts
const withBundleAnalyzer = require('@next/bundle-analyzer')({
  enabled: process.env.ANALYZE === 'true',
});

module.exports = withBundleAnalyzer({
  // your config
});

// Run: ANALYZE=true pnpm run build
// Opens interactive treemap visualization
```

### Source Map Explorer

```bash
# Install
pnpm add -D source-map-explorer

# Generate source maps and analyze
pnpm run build -- --sourcemap
npx source-map-explorer '.next/static/chunks/*.js'
```

### Import Cost Analysis

```typescript
// scripts/dependency-cost-report.ts
import { readFileSync } from 'fs';

interface DepCost {
  name: string;
  version: string;
  size: number;
  gzip: number;
  treeShakeable: boolean;
  recommendation: string;
}

async function analyzeDependency(name: string): Promise<DepCost> {
  const pkgJson = JSON.parse(
    readFileSync(`node_modules/${name}/package.json`, 'utf-8')
  );

  const hasEsm = Boolean(pkgJson.module || pkgJson.exports);
  const bundleStats = await getBundleStats(name);

  let recommendation = '';
  if (bundleStats.gzip > 50000) {
    recommendation = 'Consider alternatives or lazy loading';
  } else if (!hasEsm) {
    recommendation = 'Not tree-shakeable -- import specific paths';
  } else if (bundleStats.unusedRatio > 0.5) {
    recommendation = 'High unused code -- import specific functions';
  }

  return {
    name,
    version: pkgJson.version,
    size: bundleStats.size,
    gzip: bundleStats.gzip,
    treeShakeable: hasEsm,
    recommendation,
  };
}
```

---

## 3. HEAVY DEPENDENCY ALTERNATIVES

| Package | Gzip Size | Alternative | Savings | Notes |
|---------|-----------|-------------|---------|-------|
| moment | 72KB | date-fns (tree-shake) | 85% | Native Intl.DateTimeFormat for simple cases |
| lodash | 25KB | lodash-es or native | 80-100% | Most utils have native equivalents |
| axios | 14KB | native fetch | 100% | fetch is standard in all modern browsers |
| uuid | 4KB | crypto.randomUUID() | 100% | Built into Web Crypto API |
| classnames | 2KB | clsx | 50% | clsx is smaller and faster |
| numeral | 17KB | Intl.NumberFormat | 100% | Built into all modern browsers |
| validator | 42KB | Zod (already in stack) | varies | Zod handles validation holistically |
| chart.js | 64KB | Dynamic import | 100% initial | Load on demand only |

### Replacement Examples

```typescript
// BAD: Full lodash import
import _ from 'lodash';
_.get(obj, 'path.to.value');
_.debounce(fn, 300);
_.cloneDeep(obj);

// GOOD: Specific imports
import get from 'lodash/get';
import debounce from 'lodash/debounce';

// BEST: Native alternatives
obj?.path?.to?.value;                          // Optional chaining
structuredClone(obj);                           // Native deep clone
function debounce(fn: Function, ms: number) {   // Native implementation
  let timer: ReturnType<typeof setTimeout>;
  return (...args: unknown[]) => {
    clearTimeout(timer);
    timer = setTimeout(() => fn(...args), ms);
  };
}

// BAD: moment for formatting
import moment from 'moment';
moment(date).format('YYYY-MM-DD');

// GOOD: date-fns (tree-shakeable)
import { format } from 'date-fns';
format(date, 'yyyy-MM-dd');

// BEST: Native Intl (zero bundle cost)
new Intl.DateTimeFormat('he-IL', {
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
}).format(date);

// BAD: uuid package
import { v4 as uuidv4 } from 'uuid';
const id = uuidv4();

// GOOD: Native crypto
const id = crypto.randomUUID();

// BAD: numeral for formatting
import numeral from 'numeral';
numeral(1234567).format('0,0');

// GOOD: Native Intl
new Intl.NumberFormat('he-IL').format(1234567);
```

---

## 4. CODE SPLITTING

### Route-Based Splitting (Automatic in Next.js)

```typescript
// app/dashboard/page.tsx
// Each route is automatically a separate chunk

// Heavy components loaded on demand
import dynamic from 'next/dynamic';

const HeavyChart = dynamic(() => import('@/components/HeavyChart'), {
  loading: () => <ChartSkeleton />,
  ssr: false, // Client-only component
});

const DataTable = dynamic(() => import('@/components/DataTable'), {
  loading: () => <TableSkeleton />,
});

export default function DashboardPage() {
  return (
    <div>
      <Suspense fallback={<ChartSkeleton />}>
        <HeavyChart />
      </Suspense>
      <Suspense fallback={<TableSkeleton />}>
        <DataTable />
      </Suspense>
    </div>
  );
}
```

### Component-Level Lazy Loading

```typescript
// components/FeatureComponent.tsx
'use client';

import { lazy, Suspense, useState } from 'react';

const HeavyEditor = lazy(() => import('./HeavyEditor'));
const PDFViewer = lazy(() => import('./PDFViewer'));

export function FeatureComponent() {
  const [showEditor, setShowEditor] = useState(false);
  const [showPDF, setShowPDF] = useState(false);

  return (
    <div>
      <button
        onClick={() => setShowEditor(true)}
        className="min-h-11 min-w-11 rounded-lg bg-primary px-4 py-2"
      >
        Open Editor
      </button>

      {showEditor && (
        <Suspense fallback={<EditorSkeleton />}>
          <HeavyEditor onClose={() => setShowEditor(false)} />
        </Suspense>
      )}

      {showPDF && (
        <Suspense fallback={<PDFSkeleton />}>
          <PDFViewer onClose={() => setShowPDF(false)} />
        </Suspense>
      )}
    </div>
  );
}
```

---

## 5. TREE SHAKING

### Named Exports Pattern

```typescript
// BAD: Default export prevents tree shaking of object members
export default {
  Button,
  Input,
  Select,
};

// GOOD: Named exports enable tree shaking
export { Button } from './Button';
export { Input } from './Input';
export { Select } from './Select';
```

### Side Effect Configuration

```json
// package.json
{
  "sideEffects": false
}

// Or specify files with side effects
{
  "sideEffects": [
    "*.css",
    "./src/polyfills.ts"
  ]
}
```

### Next.js Package Import Optimization

```javascript
// next.config.ts
module.exports = {
  modularizeImports: {
    'lodash': {
      transform: 'lodash/{{member}}',
    },
    '@mui/material': {
      transform: '@mui/material/{{member}}',
    },
    '@mui/icons-material': {
      transform: '@mui/icons-material/{{member}}',
    },
  },
  experimental: {
    optimizePackageImports: [
      'lucide-react',
      '@radix-ui/react-icons',
      'date-fns',
    ],
  },
};
```

### Barrel File Optimization

```typescript
// BAD: Barrel file imports everything
// components/index.ts
export * from './Button';
export * from './Input';
export * from './Select';
// ... 50 more components

// Importing one pulls the entire barrel
import { Button } from '@/components'; // Loads ALL components

// GOOD: Direct imports bypass barrel
import { Button } from '@/components/Button';

// BETTER: Configure optimizePackageImports in next.config.ts
// to automatically optimize barrel imports
```

---

## 6. UNUSED CODE DETECTION

### depcheck for Dependencies

```bash
# Install and run
pnpm add -g depcheck
depcheck .

# Output:
# Unused dependencies: lodash, moment
# Unused devDependencies: @types/old-library
# Missing dependencies: used-but-not-listed
```

### Automated Coverage Collection

```typescript
// scripts/collect-coverage.ts
import puppeteer from 'puppeteer';

interface CoverageResult {
  url: string;
  totalBytes: number;
  usedBytes: number;
  unusedPercent: number;
}

async function collectCoverage(pageUrl: string): Promise<CoverageResult[]> {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();

  await page.coverage.startJSCoverage();
  await page.coverage.startCSSCoverage();

  await page.goto(pageUrl, { waitUntil: 'networkidle0' });

  // Simulate user interaction
  await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
  await new Promise((r) => setTimeout(r, 1000));

  const [jsCoverage, cssCoverage] = await Promise.all([
    page.coverage.stopJSCoverage(),
    page.coverage.stopCSSCoverage(),
  ]);

  await browser.close();

  return [...jsCoverage, ...cssCoverage]
    .map((entry) => {
      const usedBytes = entry.ranges.reduce(
        (sum, range) => sum + range.end - range.start,
        0,
      );
      return {
        url: entry.url,
        totalBytes: entry.text.length,
        usedBytes,
        unusedPercent:
          ((entry.text.length - usedBytes) / entry.text.length) * 100,
      };
    })
    .sort((a, b) => b.unusedPercent - a.unusedPercent);
}
```

### Unused Export Finder

```typescript
// scripts/find-unused-exports.ts
import { Project } from 'ts-morph';

function findUnusedExports(): void {
  const project = new Project({
    tsConfigFilePath: './tsconfig.json',
  });

  const unusedExports: { file: string; export: string }[] = [];

  for (const sourceFile of project.getSourceFiles()) {
    const exports = sourceFile.getExportedDeclarations();

    for (const [name, declarations] of exports) {
      if (name === 'default') continue;

      const references = declarations[0]?.findReferencesAsNodes() || [];
      const externalRefs = references.filter(
        (ref) => ref.getSourceFile() !== sourceFile,
      );

      if (externalRefs.length === 0) {
        unusedExports.push({
          file: sourceFile.getFilePath(),
          export: name,
        });
      }
    }
  }

  console.log('Potentially unused exports:');
  unusedExports.forEach(({ file, export: exp }) => {
    console.log(`  ${file}: ${exp}`);
  });
}
```

---

## 7. DUPLICATE DETECTION

```typescript
// scripts/find-duplicates.ts
// Detect duplicate packages in bundle
import { execSync } from 'child_process';

function findDuplicatePackages(): void {
  const lockfile = execSync('pnpm ls --json --depth=Infinity').toString();
  const deps = JSON.parse(lockfile);

  const packageVersions = new Map<string, Set<string>>();

  interface NpmTreeNode {
    version: string;
    dependencies?: Record<string, NpmTreeNode>;
  }

  function traverse(tree: NpmTreeNode, path: string = '') {
    for (const [name, info] of Object.entries(tree.dependencies || {})) {
      const versions = packageVersions.get(name) || new Set();
      versions.add(info.version);
      packageVersions.set(name, versions);
      traverse(info, `${path}/${name}`);
    }
  }

  traverse(deps[0]);

  const duplicates = [...packageVersions.entries()].filter(
    ([_, versions]) => versions.size > 1,
  );

  if (duplicates.length > 0) {
    console.log('Duplicate packages found:');
    duplicates.forEach(([name, versions]) => {
      console.log(`  ${name}: ${[...versions].join(', ')}`);
    });
  }
}
```

---

## 8. CI BUNDLE CHECKS

### GitHub Action

```yaml
# .github/workflows/bundle-check.yml
name: Bundle Size Check
on: [pull_request]

jobs:
  bundle-check:
    runs-on: [self-hosted, linux, x64, pop-os]
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '24'
          cache: 'pnpm'

      - run: pnpm install --frozen-lockfile

      - name: Build with analysis
        run: ANALYZE=true pnpm build

      - name: Check bundle size
        run: npx bundlesize --config bundlesize.config.json

      - name: Check unused dependencies
        run: |
          npx depcheck --json > depcheck.json
          UNUSED=$(cat depcheck.json | jq '.dependencies | length')
          if [ "$UNUSED" -gt 0 ]; then
            echo "Found $UNUSED unused dependencies"
            cat depcheck.json | jq '.dependencies'
            exit 1
          fi

      - name: Check unused CSS
        run: |
          # PurgeCSS analysis
          npx purgecss --css .next/static/css/*.css \
            --content 'app/**/*.tsx' 'components/**/*.tsx' \
            --output purged/
```

### bundlesize Configuration

```json
// bundlesize.config.json
{
  "files": [
    {
      "path": ".next/static/chunks/main-*.js",
      "maxSize": "100 kB",
      "compression": "gzip"
    },
    {
      "path": ".next/static/chunks/pages/_app-*.js",
      "maxSize": "50 kB",
      "compression": "gzip"
    },
    {
      "path": ".next/static/css/*.css",
      "maxSize": "20 kB",
      "compression": "gzip"
    }
  ]
}
```

---

## 9. CHECKLIST

```markdown
## Bundle Optimization Checklist

### Analysis
- [ ] Bundle analyzer run (ANALYZE=true pnpm build)
- [ ] Source map explorer for detailed attribution
- [ ] depcheck for unused dependencies
- [ ] Coverage analysis for unused code (< 5% target)
- [ ] Duplicate package detection

### Optimization
- [ ] Named exports for tree shaking
- [ ] sideEffects: false in package.json
- [ ] Barrel file optimization or direct imports
- [ ] Heavy dependencies replaced (moment, lodash, axios, uuid)
- [ ] Dynamic imports for non-critical components
- [ ] optimizePackageImports configured

### Budgets
- [ ] Initial JS < 100KB gzipped
- [ ] Per-route chunk < 30KB gzipped
- [ ] Total initial < 350KB gzipped
- [ ] Third-party < 30KB gzipped
- [ ] Unused code < 5%
- [ ] 0 duplicate packages

### CI/CD
- [ ] Bundle size checks in pipeline
- [ ] Unused dependency checks
- [ ] Budget violations block merge
- [ ] Size comparison on PRs
```

---

<!-- BUNDLE_OPTIMIZATION v24.7.0 | Bundle analysis, composition, dependencies, unused code, tree shaking -->
