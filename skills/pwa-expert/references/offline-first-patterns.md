# Offline-First Patterns v24.5.0

> **PWA Expert Reference** | Offline-First Architecture Patterns

## Core Principles

1. **Local First** - Always read from local storage
2. **Optimistic Updates** - Write locally immediately
3. **Background Sync** - Sync to server when online
4. **Conflict Resolution** - Handle merge conflicts gracefully

## Storage Hierarchy

| Priority | Storage | Use Case | Size Limit |
|----------|---------|----------|------------|
| 1 | OPFS | Large files, blobs | Quota-based |
| 2 | IndexedDB | Structured data | Quota-based |
| 3 | Cache API | HTTP responses | Quota-based |
| 4 | localStorage | Small key-value | 5-10MB |

## Sync Queue Pattern

```typescript
interface SyncQueueItem {
  id: string;
  operation: 'create' | 'update' | 'delete';
  table: string;
  data: unknown;
  timestamp: number;
  retryCount: number;
}

// Process queue when online
async function processSyncQueue() {
  const queue = await getSyncQueue();
  for (const item of queue) {
    try {
      await syncToServer(item);
      await removeFromQueue(item.id);
    } catch (error) {
      await incrementRetryCount(item.id);
    }
  }
}
```

## Conflict Resolution Strategies

| Strategy | Use Case | Implementation |
|----------|----------|----------------|
| Last Write Wins | Simple data | Compare timestamps |
| Field-Level Merge | Complex objects | Merge changed fields |
| Server Wins | Critical data | Always use server value |
| User Decides | Important conflicts | Show UI prompt |

## Network Detection

```typescript
// Check online status
const isOnline = navigator.onLine;

// Listen for changes
window.addEventListener('online', handleOnline);
window.addEventListener('offline', handleOffline);

// Connection quality
const connection = navigator.connection;
const effectiveType = connection?.effectiveType; // '4g', '3g', '2g', 'slow-2g'
```

## Best Practices

1. Use UUIDs for client-generated IDs
2. Add `updated_at` timestamps to all records
3. Implement exponential backoff for retries
4. Show sync status to users
5. Handle quota exceeded errors gracefully
6. Test with airplane mode

## Related References

- `service-worker-patterns.md` - Caching strategies
- `pwa-freezing-prevention.md` - Background sync handling

---

<!-- OFFLINE_FIRST_PATTERNS v24.5.0 | Updated: 2026-02-19 -->
