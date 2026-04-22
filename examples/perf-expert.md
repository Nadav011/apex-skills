# perf-expert — Real-World Examples

The skill audits Core Web Vitals (LCP, INP, CLS), bundle size, runtime performance, and enforces APEX thresholds: LCP < 1.5s, INP < 150ms, CLS < 0.05, initial JS < 100 KB gzip.

## Before / After

### Example 1: LCP regression from render-blocking hero image

**Before** (triggers the skill):
```tsx
// ❌ Hero image loaded lazily — LCP element takes 3.2s to appear
export default function HomePage() {
  return (
    <section>
      {/* No priority, lazy loading on above-the-fold image */}
      <img
        src="/hero.jpg"
        alt="Welcome"
        className="w-full"
        loading="lazy"   // WRONG: lazy makes LCP element load even later
        // No width/height → CLS score 0.31
        // JPEG 480 KB — no WebP conversion
      />
      <h1 className="mt-4 text-4xl font-bold">ברוכים הבאים</h1>
    </section>
  );
}
// Lighthouse LCP: 3.2s | CLS: 0.31
```

**After** (skill-compliant):
```tsx
// ✅ priority + next/image → LCP 0.9s, CLS 0, 85% smaller image
import Image from 'next/image';

export default function HomePage() {
  return (
    <section>
      <Image
        src="/hero.jpg"
        alt="Welcome"
        width={1440}
        height={600}
        priority           // fetchpriority="high" + <link rel="preload"> in <head>
        quality={85}       // WebP at 85% ≈ 68 KB vs 480 KB JPEG
        className="w-full object-cover"
        // Explicit dimensions prevent CLS — space reserved before image loads
      />
      <h1 className="mt-4 text-4xl font-bold">ברוכים הבאים</h1>
    </section>
  );
}
// Lighthouse LCP: 0.9s (−2.3s) | CLS: 0 | Image: 68 KB (−412 KB)
```

**Why:** `loading="lazy"` on an above-the-fold image is the most common LCP regression — it defers the most important image on the page. `priority` on `next/image` injects a `<link rel="preload">` in `<head>` so the browser starts downloading before it parses the `<img>` tag. Explicit `width`/`height` reserves space before the image loads, eliminating layout shift.

---

### Example 2: INP regression from synchronous filter on every keystroke

**Before** (triggers the skill):
```tsx
// ❌ Synchronous 2 MB JSON parse + O(n) filter on main thread every keystroke
function SearchBar() {
  const [results, setResults] = useState<Product[]>([]);

  function handleSearch(e: React.ChangeEvent<HTMLInputElement>) {
    const query = e.target.value;
    // 2 MB JSON.parse + 10 000-item linear scan, called 30× during fast typing
    const catalog: Product[] = JSON.parse(localStorage.getItem('catalog') ?? '[]');
    const filtered = catalog.filter(p =>
      p.name.toLowerCase().includes(query.toLowerCase())
    );
    setResults(filtered.slice(0, 20));
  }

  return <input onChange={handleSearch} placeholder="חפש..." />;
  // INP: 780 ms — UI freezes for 3/4 s on every keystroke
}
```

**After** (skill-compliant):
```tsx
// ✅ Web Worker + useTransition → INP 18 ms, search runs off main thread
import { useState, useEffect, useRef, useTransition } from 'react';

function SearchBar() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<Product[]>([]);
  const [isPending, startTransition] = useTransition();
  const workerRef = useRef<Worker>();

  useEffect(() => {
    workerRef.current = new Worker(new URL('./search.worker.ts', import.meta.url));
    workerRef.current.onmessage = (e: MessageEvent<Product[]>) => {
      startTransition(() => setResults(e.data));
    };
    return () => workerRef.current?.terminate();
  }, []);

  function handleInput(e: React.ChangeEvent<HTMLInputElement>) {
    const q = e.target.value;
    setQuery(q);  // instant — no blocking work on this path
    if (q.length >= 2) workerRef.current?.postMessage({ query: q });
    else setResults([]);
  }

  return (
    <>
      <input onChange={handleInput} value={query} placeholder="חפש..." />
      {isPending && <span className="sr-only">מחפש...</span>}
      <ul>{results.map(r => <li key={r.id}>{r.name}</li>)}</ul>
    </>
  );
}
// INP: 18 ms — input response is instant, results update asynchronously
```

**Why:** Parsing 2 MB of JSON and running a linear scan on the main thread blocks the browser's rendering pipeline for 780 ms — visually frozen UI on every keystroke. Moving the search to a `Worker` offloads all CPU work to a background thread. `useTransition` marks the result update as non-urgent, keeping the input field responsive even while results load.

---

### Example 3: CLS from dynamically injected banner above page content

**Before** (triggers the skill):
```tsx
// ❌ 48 px banner injected 800 ms after paint — pushes all content down
function Layout({ children }: { children: React.ReactNode }) {
  const [banner, setBanner] = useState<string | null>(null);

  useEffect(() => {
    fetch('/api/active-promotion')
      .then(r => r.json())
      .then(data => setBanner(data?.message ?? null));
  }, []);

  return (
    <div>
      {banner && (
        <div className="bg-yellow-400 px-4 py-3 text-center">{banner}</div>
      )}
      <nav>...</nav>
      <main>{children}</main>
    </div>
  );
  // CLS: 0.45 — entire page shifts down when banner appears
}
```

**After** (skill-compliant):
```tsx
// ✅ Space reserved from first paint — CLS 0
function Layout({ children }: { children: React.ReactNode }) {
  const [banner, setBanner] = useState<string | null | undefined>(undefined);
  // undefined = loading (reserve space) | null = no banner | string = show banner

  useEffect(() => {
    fetch('/api/active-promotion')
      .then(r => r.json())
      .then(data => setBanner(data?.message ?? null));
  }, []);

  return (
    <div>
      {/* Height reserved from first render — content never shifts */}
      <div
        className="overflow-hidden transition-[height] duration-200"
        style={{ height: banner === undefined || banner ? '48px' : '0px' }}
        aria-live="polite"
      >
        {banner && (
          <div className="bg-yellow-400 px-4 py-3 text-center">{banner}</div>
        )}
      </div>
      <nav>...</nav>
      <main>{children}</main>
    </div>
  );
  // CLS: 0 — space is either filled or smoothly collapses to 0
}
```

**Why:** CLS 0.45 means the page shifts significantly after initial paint — a jarring experience that causes accidental taps (user clicks "Confirm" just as the page shifts). The fix uses a three-state variable: `undefined` means "loading, reserve space"; `null` means "no banner, collapse"; `string` means "show banner". Space is always reserved from the first render, so no element ever moves.
