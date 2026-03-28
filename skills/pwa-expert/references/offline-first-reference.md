# Offline-First Reference v24.5.0

> **PWA Expert Reference** | Complete Offline-First Implementation Guide

## Quick Start

```typescript
// 1. Setup IndexedDB
import { openDB } from 'idb';

const db = await openDB('app-db', 1, {
  upgrade(db) {
    db.createObjectStore('items', { keyPath: 'id' });
    db.createObjectStore('syncQueue', { keyPath: 'id' });
  },
});

// 2. Write locally first
async function saveItem(item: Item) {
  await db.put('items', { ...item, updatedAt: Date.now() });
  await queueSync('update', 'items', item);
}

// 3. Sync when online
if (navigator.onLine) {
  await processSyncQueue();
}
```

## Service Worker Integration

```typescript
// sw.ts - Background sync
self.addEventListener('sync', (event) => {
  if (event.tag === 'sync-queue') {
    event.waitUntil(processSyncQueue());
  }
});

// Register sync
await registration.sync.register('sync-queue');
```

## Data Flow

```
USER ACTION
    ↓
LOCAL STORAGE (IndexedDB)
    ↓
SYNC QUEUE (if online fails)
    ↓
BACKGROUND SYNC
    ↓
SERVER
```

## Error Handling

| Error | Action |
|-------|--------|
| Network offline | Queue for later |
| Server 5xx | Retry with backoff |
| Conflict 409 | Resolve or prompt user |
| Quota exceeded | Clean old data |

## Testing Checklist

- [ ] Works in airplane mode
- [ ] Syncs when coming online
- [ ] Handles conflicts correctly
- [ ] Shows sync status
- [ ] Recovers from errors

## Related

- `offline-first-patterns.md` - Architecture patterns
- `service-worker-patterns.md` - SW caching

---

<!-- OFFLINE_FIRST_REFERENCE v24.5.0 | Updated: 2026-02-19 -->
