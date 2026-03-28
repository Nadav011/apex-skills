# Async Content & Dynamic Updates Accessibility

> **v24.6.0** | React 19 Suspense | TanStack Query 5.90.21 | WCAG 2.2 SC 4.1.3 Live Regions
> RTL-FIRST: `ms-`/`me-`/`ps-`/`pe-`/`inset-s-`/`inset-e-` — never `ml-`/`mr-`/`left-`/`right-`

---

## React 19 Suspense + use() Hook

### CRITICAL: aria-live Region Placement

| Rule | Correct | Wrong |
|------|---------|-------|
| Region placement | Outside `<Suspense>` boundary — persists in DOM | Inside `<Suspense>` — unmounted during load, SR misses announcements |
| DOM mutation | Mutate text content of existing node | Replace DOM nodes — SR does not detect node swap |
| Priority | `polite` for loading states | `assertive` for loading states (jarring, interrupts) |
| Errors | `assertive` for critical failures only | `polite` for errors blocking task completion |

### Persistent Live Region + Suspense Pattern

```tsx
// WRONG: Live region inside Suspense — unmounts during fallback, announcements lost
function WrongPattern() {
  return (
    <Suspense fallback={<Skeleton />}>
      {/* SR never hears this — region unmounts with boundary */}
      <div aria-live="polite" aria-atomic="true">
        <UserProfile />
      </div>
    </Suspense>
  );
}

// RIGHT: Live region outside — persists through all Suspense states
function AsyncUserProfile({ userId }: { userId: string }) {
  const [announcement, setAnnouncement] = React.useState('');

  return (
    <>
      {/* Persistent region — never unmounts */}
      <div
        role="status"
        aria-live="polite"
        aria-atomic="true"
        className="sr-only"
      >
        {announcement}
      </div>

      <Suspense fallback={<ProfileSkeleton onMount={() => setAnnouncement('Loading profile')} />}>
        <ProfileContent userId={userId} onLoad={() => setAnnouncement('Profile loaded')} />
      </Suspense>
    </>
  );
}
```

### Skeleton Screens

```tsx
function ProfileSkeleton({ onMount }: { onMount?: () => void }) {
  React.useEffect(() => { onMount?.(); }, [onMount]);

  return (
    // aria-busy signals content is loading; aria-label describes what's loading
    <div aria-busy="true" aria-label="Loading profile" className="animate-pulse">
      <div className="h-12 w-12 rounded-full bg-gray-200" aria-hidden="true" />
      <div className="ms-4 space-y-2" aria-hidden="true">
        <div className="h-4 w-32 rounded bg-gray-200" />
        <div className="h-3 w-48 rounded bg-gray-200" />
      </div>
    </div>
  );
}
```

### Focus Management After Suspense Resolution

```tsx
function ProfileContent({ userId, onLoad }: { userId: string; onLoad: () => void }) {
  const data = use(fetchUser(userId)); // React 19 use() hook
  const headingRef = React.useRef<HTMLHeadingElement>(null);

  React.useEffect(() => {
    onLoad();
    // Focus first meaningful content after async resolution
    headingRef.current?.focus();
  }, [onLoad]);

  return (
    <section>
      {/* tabIndex={-1} allows programmatic focus without adding to tab order */}
      <h2 ref={headingRef} tabIndex={-1} className="outline-none">
        {data.name}
      </h2>
      <p>{data.email}</p>
    </section>
  );
}
```

---

## Infinite Scroll

### aria-live Announcement Pattern

```tsx
import { useInfiniteQuery } from '@tanstack/react-query';

function InfiniteItemList() {
  const [announcement, setAnnouncement] = React.useState('');
  const {
    data,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
  } = useInfiniteQuery({
    queryKey: ['items'],
    queryFn: ({ pageParam }) => fetchItems(pageParam),
    getNextPageParam: (last) => last.nextCursor,
  });

  const loadMore = React.useCallback(async () => {
    if (!hasNextPage || isFetchingNextPage) return;
    setAnnouncement('Loading more items');
    await fetchNextPage();
    const count = data?.pages.at(-1)?.items.length ?? 0;
    setAnnouncement(`${count} new items loaded`);
  }, [hasNextPage, isFetchingNextPage, fetchNextPage, data]);

  const allItems = data?.pages.flatMap((p) => p.items) ?? [];

  return (
    <>
      {/* Announcement region — outside the feed */}
      <div role="status" aria-live="polite" aria-atomic="true" className="sr-only">
        {announcement}
      </div>

      {/* role="feed" with aria-busy during load — WCAG 2.1 SC 1.3.1 */}
      <div role="feed" aria-busy={isFetchingNextPage} aria-label="Items list">
        {allItems.map((item) => (
          <article key={item.id} className="p-4 border-b border-gray-200">
            <h3>{item.title}</h3>
            <p>{item.description}</p>
          </article>
        ))}
      </div>

      {/* "Load more" button — keyboard-accessible alternative to scroll trigger */}
      {hasNextPage && (
        <button
          onClick={loadMore}
          disabled={isFetchingNextPage}
          aria-busy={isFetchingNextPage}
          className="mt-6 min-h-11 min-w-11 px-6 py-3 rounded-lg border border-gray-300
                     focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2"
        >
          {isFetchingNextPage ? 'Loading…' : 'Load more'}
        </button>
      )}
    </>
  );
}
```

### Rules

- Announce "Loading more items" **before** fetch starts (polite, not assertive)
- Announce "X new items loaded" **after** fetch resolves
- Never jump focus to newly loaded content — maintain user position
- Scroll-triggered load must have a "Load more" button alternative (scroll-only fails WCAG 2.1.1)
- `role="feed"` is the correct semantic for infinitely-loading article lists

---

## Real-Time Data Updates

### Live Scores / Stock Prices / Notifications

```tsx
// Throttle high-frequency updates — max 1 announcement per 5 seconds
function useThrottledAnnouncement(value: string, intervalMs = 5000) {
  const [announced, setAnnounced] = React.useState(value);
  const lastAnnouncedAt = React.useRef(0);

  React.useEffect(() => {
    const now = Date.now();
    if (now - lastAnnouncedAt.current >= intervalMs) {
      setAnnounced(value);
      lastAnnouncedAt.current = now;
    }
  }, [value, intervalMs]);

  return announced;
}

function LiveScoreWidget({ homeTeam, awayTeam, homeScore, awayScore }: ScoreProps) {
  const scoreText = `${homeTeam} ${homeScore}, ${awayTeam} ${awayScore}`;
  const throttledScore = useThrottledAnnouncement(scoreText);

  return (
    <div className="rounded-xl p-4">
      {/* aria-atomic="true": announces full score, not just changed number */}
      <div
        aria-live="polite"
        aria-atomic="true"
        aria-label="Live score"
        className="sr-only"
      >
        {throttledScore}
      </div>
      {/* Visual display — separate from SR announcements */}
      <div className="flex gap-4 items-center justify-center" aria-hidden="true">
        <span>{homeTeam}</span>
        <span dir="ltr" className="text-2xl font-bold">{homeScore}:{awayScore}</span>
        <span>{awayTeam}</span>
      </div>

      {/* WCAG 2.2.2 Pause, Stop, Hide — user control for live updates */}
      <PauseResumeControl />
    </div>
  );
}
```

### Pause/Resume Live Updates (WCAG 2.2.2)

```tsx
function PauseResumeControl() {
  const [paused, setPaused] = React.useState(false);

  return (
    <button
      onClick={() => setPaused((p) => !p)}
      aria-pressed={paused}
      className="min-h-11 min-w-11 mt-3 px-4 py-2 text-sm rounded-lg border
                 border-gray-300 focus-visible:outline focus-visible:outline-2"
    >
      {paused ? 'Resume live updates' : 'Pause live updates'}
    </button>
  );
}
```

### High-Frequency Update Throttle Rules

| Update Frequency | Strategy | WCAG SC |
|-----------------|----------|---------|
| > 1/sec (ticker, game) | Throttle to ≤ 1/5sec via `useThrottledAnnouncement` | 2.2.2 |
| 1/sec (score, price) | `aria-live="polite"` with `aria-atomic="true"` | 4.1.3 |
| < 1/min (notification) | `role="status"` — polite, no interruption | 4.1.3 |
| Critical alert (error) | `role="alert"` — assertive, immediate | 4.1.3 |

---

## Data Table Pagination

```tsx
function PaginatedTable<T extends Record<string, unknown>>({
  data,
  columns,
  totalItems,
  pageSize,
}: TableProps<T>) {
  const [page, setPage] = React.useState(1);
  const [sortCol, setSortCol] = React.useState<string | null>(null);
  const [sortDir, setSortDir] = React.useState<'asc' | 'desc'>('asc');
  const [announcement, setAnnouncement] = React.useState('');
  const firstRowRef = React.useRef<HTMLTableRowElement>(null);

  const totalPages = Math.ceil(totalItems / pageSize);
  const start = (page - 1) * pageSize + 1;
  const end = Math.min(page * pageSize, totalItems);

  const goToPage = (newPage: number) => {
    setPage(newPage);
    setAnnouncement(`Page ${newPage} of ${totalPages}, showing items ${(newPage - 1) * pageSize + 1} to ${Math.min(newPage * pageSize, totalItems)} of ${totalItems}`);
    // Focus first data row after page change
    requestAnimationFrame(() => firstRowRef.current?.focus());
  };

  const handleSort = (col: string) => {
    const newDir = sortCol === col && sortDir === 'asc' ? 'desc' : 'asc';
    setSortCol(col);
    setSortDir(newDir);
    setAnnouncement(`Sorted by ${col} ${newDir === 'asc' ? 'ascending' : 'descending'}`);
  };

  return (
    <>
      <div role="status" aria-live="polite" aria-atomic="true" className="sr-only">
        {announcement}
      </div>

      <table aria-label="Data table">
        <thead>
          <tr>
            {columns.map((col) => (
              <th
                key={col.key}
                aria-sort={sortCol === col.key ? (sortDir === 'asc' ? 'ascending' : 'descending') : 'none'}
                className="text-start p-3 font-semibold"
              >
                <button
                  onClick={() => handleSort(col.key)}
                  className="flex items-center gap-1 min-h-11 focus-visible:outline focus-visible:outline-2 rounded"
                >
                  {col.label}
                  <span aria-hidden="true" className={sortCol === col.key ? 'opacity-100' : 'opacity-30'}>
                    {sortDir === 'asc' ? '↑' : '↓'}
                  </span>
                </button>
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {data.map((row, i) => (
            <tr
              key={String(row.id)}
              ref={i === 0 ? firstRowRef : undefined}
              tabIndex={i === 0 ? -1 : undefined}
              className="border-b border-gray-200 focus-visible:outline focus-visible:outline-2"
            >
              {columns.map((col) => (
                <td key={col.key} className="p-3 text-start">
                  {String(row[col.key] ?? '')}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>

      <nav aria-label="Table pagination" className="flex items-center gap-2 mt-4">
        <span aria-live="polite" className="text-sm text-gray-600">
          {start}–<span dir="ltr">{end}</span> of <span dir="ltr">{totalItems}</span>
        </span>
        <button
          onClick={() => goToPage(page - 1)}
          disabled={page === 1}
          aria-label="Previous page"
          className="min-h-11 min-w-11 rounded-lg border border-gray-300 px-3
                     disabled:opacity-40 focus-visible:outline focus-visible:outline-2"
        >
          <span aria-hidden="true" className="rtl:rotate-180">←</span>
        </button>
        <button
          onClick={() => goToPage(page + 1)}
          disabled={page === totalPages}
          aria-label="Next page"
          className="min-h-11 min-w-11 rounded-lg border border-gray-300 px-3
                     disabled:opacity-40 focus-visible:outline focus-visible:outline-2"
        >
          <span aria-hidden="true" className="rtl:rotate-180">→</span>
        </button>
      </nav>
    </>
  );
}
```

---

## Toast / Notification Patterns

### Role Selection

| Scenario | Role | aria-live | Interrupts SR? |
|----------|------|-----------|---------------|
| Success (save, submit) | `role="status"` | polite | No |
| Info (sync complete) | `role="status"` | polite | No |
| Warning (session expiring) | `role="status"` | polite | No |
| Error (payment failed) | `role="alert"` | assertive | Yes |
| Destructive action complete | `role="alert"` | assertive | Yes |

```tsx
type ToastVariant = 'success' | 'info' | 'warning' | 'error';

const TOAST_ROLE: Record<ToastVariant, 'status' | 'alert'> = {
  success: 'status',
  info: 'status',
  warning: 'status',
  error: 'alert',
} as const;

function Toast({
  message,
  variant,
  action,
  onDismiss,
  durationMs = 5000,
}: ToastProps) {
  const timerRef = React.useRef<ReturnType<typeof setTimeout>>();
  const role = TOAST_ROLE[variant];

  // Minimum 5 seconds visible; pause on hover/focus (WCAG 2.2.1)
  const startTimer = React.useCallback(() => {
    timerRef.current = setTimeout(onDismiss, durationMs);
  }, [onDismiss, durationMs]);

  const pauseTimer = React.useCallback(() => {
    clearTimeout(timerRef.current);
  }, []);

  React.useEffect(() => {
    startTimer();
    return pauseTimer;
  }, [startTimer, pauseTimer]);

  return (
    <div
      role={role}
      aria-atomic="true"
      onMouseEnter={pauseTimer}
      onMouseLeave={startTimer}
      onFocus={pauseTimer}
      onBlur={startTimer}
      // RTL: slide in from inline-end; text aligned to start
      className="fixed bottom-4 inset-e-4 inset-s-auto max-w-sm w-full rounded-xl
                 shadow-xl p-4 flex items-start gap-3 bg-white dark:bg-gray-900
                 border border-gray-200 dark:border-gray-700"
    >
      <p className="flex-1 text-start text-sm">{message}</p>
      {action && (
        <button
          onClick={action.onClick}
          className="min-h-11 min-w-11 shrink-0 text-sm font-medium
                     text-blue-600 dark:text-blue-400 focus-visible:outline
                     focus-visible:outline-2 rounded"
        >
          {action.label}
        </button>
      )}
      <button
        onClick={onDismiss}
        aria-label="Dismiss notification"
        className="min-h-11 min-w-11 shrink-0 flex items-center justify-center
                   rounded-lg focus-visible:outline focus-visible:outline-2"
      >
        <span aria-hidden="true">✕</span>
      </button>
    </div>
  );
}
```

---

## Cross-References

- Focus management principles: `references/web-a11y.md`
- Playwright testing async content: `references/a11y-testing.md`
- Cognitive load for loading states: `references/cognitive-a11y.md`
- Next.js useActionState SR patterns: `references/nextjs-a11y.md`

---

<!-- ASYNC_CONTENT_A11Y v24.6.0 | Updated: 2026-02-24 | React 19 Suspense + use() + TanStack Query + live regions -->
