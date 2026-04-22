# bundle-analyze — Real-World Examples

The skill enforces bundle size discipline: 100 KB gzip per dynamic chunk, chunking strategy for shared vendor code, lazy loading for heavy components, and CI gates that fail on regressions.

## Before / After

### Example 1: Importing entire packages instead of tree-shaking

**Before** (triggers the skill):
```typescript
// ❌ Full package imports — bundler cannot tree-shake these
import _ from 'lodash';              // 531 KB minified
import * as Icons from 'lucide-react'; // loads all 1500+ icons
import moment from 'moment';          // 329 KB + locale files

function OrderList({ orders }: { orders: Order[] }) {
  const sorted = _.orderBy(orders, ['createdAt'], ['desc']);
  const formatted = sorted.map(o => ({
    ...o,
    date: moment(o.createdAt).format('DD/MM/YYYY'),
    icon: <Icons.ShoppingCart className="h-4 w-4" />,
  }));
  return <ul>{formatted.map(renderOrder)}</ul>;
}
// Bundle cost: ~860 KB for 3 utility functions
```

**After** (skill-compliant):
```typescript
// ✅ Named imports only — tree-shaker removes unused code
import { orderBy } from 'lodash-es';          // only orderBy (~3 KB)
import { ShoppingCart } from 'lucide-react';  // only ShoppingCart (~1 KB)
import { format, parseISO } from 'date-fns';  // only format + parseISO (~5 KB)
import { he } from 'date-fns/locale';

function OrderList({ orders }: { orders: Order[] }) {
  const sorted = orderBy(orders, ['createdAt'], ['desc']);
  const formatted = sorted.map(o => ({
    ...o,
    date: format(parseISO(o.createdAt), 'dd/MM/yyyy', { locale: he }),
    icon: <ShoppingCart className="h-4 w-4" />,
  }));
  return <ul>{formatted.map(renderOrder)}</ul>;
}
// Bundle cost: ~9 KB for the same functionality
```

**Why:** Default imports from `lodash`, `moment`, and `lucide-react` pull in the entire library regardless of what you use. `lodash-es` with named imports lets Rollup/Vite eliminate unused functions. `date-fns` is designed for tree-shaking — individual function imports result in ~95% smaller output than `moment`.

---

### Example 2: Heavy component loaded on every page

**Before** (triggers the skill):
```tsx
// ❌ Chart library (280 KB) and PDF viewer (2.5 MB) imported statically
import { AreaChart, BarChart, PieChart, ResponsiveContainer } from 'recharts';
import { Document, Page as PdfPage, pdfjs } from 'react-pdf';

export default function DashboardPage() {
  const [showPdf, setShowPdf] = useState(false);

  return (
    <div>
      <AreaChart data={salesData} width={600} height={300}>
        <Area dataKey="revenue" />
      </AreaChart>
      <button onClick={() => setShowPdf(true)}>View Report</button>
      {showPdf && <Document file="/report.pdf"><PdfPage pageNumber={1} /></Document>}
    </div>
  );
}
// Initial JS: 2.8 MB — all users pay the cost even if they never open the PDF
```

**After** (skill-compliant):
```tsx
// ✅ Lazy-load heavy dependencies — user pays cost only when needed
import dynamic from 'next/dynamic';

const AreaChart = dynamic(
  () => import('recharts').then(m => m.AreaChart),
  { loading: () => <div className="h-72 animate-pulse rounded-lg bg-gray-100" />, ssr: false }
);
const Area = dynamic(() => import('recharts').then(m => m.Area), { ssr: false });

const PdfViewer = dynamic(
  () => import('@/components/PdfViewer'), // wraps react-pdf with worker setup
  { loading: () => <div className="h-96 animate-pulse rounded bg-gray-100" />, ssr: false }
);

export default function DashboardPage() {
  const [showPdf, setShowPdf] = useState(false);

  return (
    <div>
      <AreaChart data={salesData} width={600} height={300}>
        <Area dataKey="revenue" />
      </AreaChart>
      <button onClick={() => setShowPdf(true)}>View Report</button>
      {showPdf && <PdfViewer file="/report.pdf" />}
    </div>
  );
}
// Initial JS: ~95 KB — recharts loads with chart, PDF only on button click
```

**Why:** The PDF viewer at 2.5 MB is only needed by users who click "View Report" — likely a small fraction of visits. Static import forces every visitor to download it on first load, adding ~3 seconds on a median mobile connection. Dynamic imports split the code into separate chunks loaded on demand.

---

### Example 3: Missing Vite manualChunks causing bloated initial bundle

**Before** (triggers the skill):
```typescript
// ❌ No manualChunks — everything lands in one massive vendor chunk
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  build: {
    // No rollupOptions — default chunking is naive
    // Result: vendor.js = 1.2 MB (React + Router + Radix + Zod + TanStack all together)
    // Any change to any vendor = full vendor cache miss for all users
  },
});
```

**After** (skill-compliant):
```typescript
// ✅ Explicit manualChunks splits vendor code into cacheable, stable chunks
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  build: {
    rollupOptions: {
      output: {
        manualChunks: (id) => {
          if (id.includes('node_modules/react') ||
              id.includes('node_modules/react-dom') ||
              id.includes('node_modules/scheduler')) {
            return 'react-vendor'; // ~35 KB — very stable, long cache life
          }
          if (id.includes('node_modules/@radix-ui') ||
              id.includes('node_modules/lucide-react')) {
            return 'ui'; // ~45 KB — changes when design system updates
          }
          if (id.includes('node_modules/zod') ||
              id.includes('node_modules/@tanstack')) {
            return 'data'; // ~38 KB — changes with data layer updates
          }
          if (id.includes('node_modules/recharts') ||
              id.includes('node_modules/d3')) {
            return 'charts'; // ~120 KB — only loaded on pages with charts
          }
        },
      },
    },
    chunkSizeWarningLimit: 150, // warn at 150 KB, CI fails at 200 KB
  },
});
// Result: react-vendor is cached across all page navigations and deploys
// until React itself updates — dramatically improves repeat-visit performance
```

**Why:** Without `manualChunks`, Vite/Rollup creates an automatic vendor chunk but it co-locates all dependencies together. A UI library version bump busts the cache for React, TanStack Query, and Zod simultaneously. Explicit chunks create stable, independently cacheable units — updating Radix UI doesn't evict the React or data chunks from the browser cache.
