# React Compiler & Performance - Comprehensive Reference

> **APEX-PERF v24.7.0** | Domain: Performance/React
> Consolidates: react-compiler-deep, react-19-2-features

---

## 1. REACT COMPILER (Stable in 19.2.4)

### Overview

React Compiler automatically memoizes components, hooks, and callbacks at build time. This eliminates the need for manual `useMemo`, `useCallback`, and `React.memo`.

### What It Replaces

```typescript
// BEFORE (Manual memoization -- no longer needed)
import { memo, useMemo, useCallback } from 'react';

const ProductCard = memo(function ProductCard({ product }: { product: Product }) {
  const formattedPrice = useMemo(
    () => new Intl.NumberFormat('he-IL', { style: 'currency', currency: 'ILS' }).format(product.price),
    [product.price],
  );

  const handleClick = useCallback(() => {
    addToCart(product.id);
  }, [product.id]);

  return (
    <div>
      <span>{product.name}</span>
      <span dir="ltr">{formattedPrice}</span>
      <button onClick={handleClick} className="min-h-11">Add</button>
    </div>
  );
});

// AFTER (React Compiler auto-memoizes)
function ProductCard({ product }: { product: Product }) {
  const formattedPrice = new Intl.NumberFormat('he-IL', {
    style: 'currency',
    currency: 'ILS',
  }).format(product.price);

  const handleClick = () => addToCart(product.id);

  return (
    <div>
      <span>{product.name}</span>
      <span dir="ltr">{formattedPrice}</span>
      <button onClick={handleClick} className="min-h-11">Add</button>
    </div>
  );
}
```

### Configuration

```typescript
// next.config.ts (Next.js 16.1.6)
const nextConfig = {
  // React Compiler is enabled by default in Next.js 16
  // Explicit configuration for customization:
  reactCompiler: {
    // Compile all components (default)
    compilationMode: 'all',

    // Or annotate-only mode:
    // compilationMode: 'annotation',
    // Only compiles components with "use memo" directive
  },
};

export default nextConfig;
```

### Opting Out

```typescript
// Opt out specific component with 'use no memo'
function UnstableComponent() {
  'use no memo';

  // This component won't be auto-memoized
  // Use when compiler causes issues (rare)
  return <div>{/* ... */}</div>;
}
```

### Biome Integration

```json
// biome.json
{
  "linter": {
    "rules": {
      "correctness": {
        "noUnnecessaryReactMemo": "error",
        "noUnnecessaryUseMemo": "error",
        "noUnnecessaryUseCallback": "error"
      }
    }
  }
}
```

---

## 2. REACT 19.2 PERFORMANCE FEATURES

### Activity Component (State Preservation)

```tsx
// The Activity component preserves state when hidden
// Replaces patterns that used display:none + state management

import { Activity } from 'react';

function TabPanel({ activeTab }: { activeTab: string }) {
  return (
    <div>
      {/* Visible tab: fully rendered and interactive */}
      {/* Hidden tabs: preserved in memory, not rendered */}
      <Activity mode={activeTab === 'overview' ? 'visible' : 'hidden'}>
        <OverviewTab />
      </Activity>

      <Activity mode={activeTab === 'details' ? 'visible' : 'hidden'}>
        <DetailsTab />
      </Activity>

      <Activity mode={activeTab === 'settings' ? 'visible' : 'hidden'}>
        <SettingsTab />
      </Activity>
    </div>
  );
}

// Activity modes:
// 'visible' -- Component is rendered and interactive
// 'hidden'  -- Component is hidden but state is preserved
//              Effects are cleaned up, refs are detached
//              Re-activating is instant (no re-mount)
```

### Performance Benefits of Activity

```
Without Activity (unmount/remount):
Tab switch: Unmount old → Mount new → Re-fetch data → Render
Time: 500-2000ms (depends on data fetching)

With Activity (hide/show):
Tab switch: Hide old → Show new (state preserved)
Time: <16ms (single frame, no re-fetch)
```

### useEffectEvent Hook

```typescript
// useEffectEvent creates stable callback references for effects
// Without re-subscribing when the callback's closure changes

import { useEffectEvent, useEffect } from 'react';

function ChatRoom({ roomId, onMessage }: {
  roomId: string;
  onMessage: (msg: Message) => void;
}) {
  // Stable reference -- won't cause effect re-subscription
  const handleMessage = useEffectEvent((msg: Message) => {
    onMessage(msg); // Always uses latest onMessage
  });

  useEffect(() => {
    const connection = createConnection(roomId);
    connection.on('message', handleMessage);
    connection.connect();

    return () => connection.disconnect();
  }, [roomId]); // Only re-runs when roomId changes, NOT when onMessage changes
}
```

### Performance Tracks (DevTools)

```typescript
// React 19.2 adds Performance Tracks in Chrome DevTools
// Shows React-specific timing in the Performance tab:
//
// Performance Panel:
// ├── Main Thread
// │   ├── React: Render Phase (Component A)
// │   ├── React: Commit Phase
// │   ├── React: Passive Effects
// │   └── React: Layout Effects
// ├── React Server Components
// │   ├── RSC: Fetch (ProductList)
// │   ├── RSC: Serialize
// │   └── RSC: Stream
// └── React Transitions
//     ├── Transition: Search
//     └── Transition: Filter
```

---

## 3. USERANSITION & USEDEFERREDVALUE

### useTransition for Non-Blocking Updates

```typescript
import { useTransition, useState } from 'react';

function SearchPage() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<SearchResult[]>([]);
  const [isPending, startTransition] = useTransition();

  function handleSearch(e: React.ChangeEvent<HTMLInputElement>) {
    const value = e.target.value;
    setQuery(value); // Urgent: update input immediately

    startTransition(() => {
      // Non-urgent: defer expensive search
      const filtered = searchDatabase(value);
      setResults(filtered);
    });
  }

  return (
    <div>
      <input
        value={query}
        onChange={handleSearch}
        className="min-h-11 w-full rounded-lg border px-4"
        placeholder="Search products..."
      />
      {isPending && <div className="text-muted-foreground">Searching...</div>}
      <SearchResults results={results} />
    </div>
  );
}
```

### useDeferredValue for Expensive Renders

```typescript
import { useDeferredValue } from 'react';

function FilteredList({ items, filter }: { items: Item[]; filter: string }) {
  // Deferred value: React keeps showing old value while computing new
  const deferredFilter = useDeferredValue(filter);
  const isStale = filter !== deferredFilter;

  const filtered = items.filter((item) =>
    item.name.toLowerCase().includes(deferredFilter.toLowerCase()),
  );

  return (
    <div className={isStale ? 'opacity-50 transition-opacity' : ''}>
      {filtered.map((item) => (
        <ItemCard key={item.id} item={item} />
      ))}
    </div>
  );
}
```

---

## 4. SERVER COMPONENTS PERFORMANCE

### Moving Dependencies to Server

```typescript
// BEFORE: Client Component (65KB client JS)
'use client';
import { format, parseISO } from 'date-fns';
import { he } from 'date-fns/locale';

export function OrderHistory({ orders }: { orders: Order[] }) {
  return (
    <ul>
      {orders.map((order) => (
        <li key={order.id}>
          {format(parseISO(order.date), 'PPP', { locale: he })}
        </li>
      ))}
    </ul>
  );
}

// AFTER: Server Component (0KB client JS)
import { format, parseISO } from 'date-fns';
import { he } from 'date-fns/locale';

export async function OrderHistory({ userId }: { userId: string }) {
  const orders = await db.orders.findMany({
    where: { userId },
    orderBy: { date: 'desc' },
    take: 10,
  });

  return (
    <ul className="space-y-2">
      {orders.map((order) => (
        <li key={order.id} className="flex justify-between">
          <span>{format(parseISO(order.date), 'PPP', { locale: he })}</span>
        </li>
      ))}
    </ul>
  );
}

// date-fns (12KB) stays server-side = 0KB added to client bundle
```

---

## 5. PERFORMANCE ANTI-PATTERNS TO AVOID

| Anti-Pattern | Impact | Fix |
|-------------|--------|-----|
| `'use client'` on data-display components | Unnecessary client JS | Remove directive, use RSC |
| Manual `React.memo` with React Compiler | Double memoization | Remove manual memo |
| `useEffect` for data fetching in RSC-capable app | Waterfall, extra renders | Use Server Components |
| `useState` for server-known data | Unnecessary hydration | Pass as props from RSC |
| Large client-side libraries | Bundle bloat | Move to Server Components |

---

## 6. CHECKLIST

```markdown
## React Performance Checklist

### React Compiler
- [ ] React Compiler enabled (default in Next.js 16)
- [ ] Removed manual useMemo/useCallback/React.memo
- [ ] Biome rules for unnecessary memoization
- [ ] 'use no memo' only where compiler causes issues

### React 19.2 Features
- [ ] Activity component for tab/panel state preservation
- [ ] useEffectEvent for stable effect callbacks
- [ ] useTransition for non-blocking updates
- [ ] useDeferredValue for expensive renders
- [ ] Performance Tracks in DevTools for debugging

### Server Components
- [ ] Default to Server Components (no 'use client')
- [ ] Heavy libraries in Server Components only
- [ ] Composition pattern (Server wrapping Client)
- [ ] Bundle analyzer confirms savings

### Anti-Patterns
- [ ] No unnecessary 'use client' directives
- [ ] No manual memoization with Compiler active
- [ ] No useEffect for server-available data
- [ ] No useState for server-known values
```

---

<!-- REACT_COMPILER_PERF v24.7.0 | React Compiler, React 19.2 features, RSC performance -->
