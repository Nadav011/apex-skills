# Network & Compression - Comprehensive Reference

> **APEX-PERF v24.7.0** | Domain: Performance/Network
> Consolidates: network-payloads, compression-streams, adaptive-loading

---

## 1. PAYLOAD BUDGETS

### Resource Type Budgets

| Resource Type | Budget (gzipped) | APEX Target |
|---------------|-----------------|-------------|
| Initial JS | < 120KB | < 100KB |
| Initial CSS | < 30KB | < 20KB |
| Per-route JS chunk | < 50KB | < 30KB |
| Hero Image | < 100KB | < 50KB |
| Total Initial | < 500KB | < 350KB |

### API Response Budgets

| Endpoint Type | Max Size |
|---------------|----------|
| List endpoints | < 50KB |
| Detail endpoints | < 10KB |
| Paginated (per page) | < 25KB |

### Connection Speed Impact

| Connection | 100KB Load | 500KB Load | 1MB Load |
|------------|-----------|-----------|---------|
| 4G (20Mbps) | 0.04s | 0.2s | 0.4s |
| 3G (1.5Mbps) | 0.5s | 2.6s | 5.3s |
| Slow 3G (400Kbps) | 2s | 10s | 20s |

---

## 2. COMPRESSION

### Brotli vs Gzip

| Algorithm | Compression Ratio | Speed | Browser Support |
|-----------|-------------------|-------|-----------------|
| Brotli | Best (15-20% smaller than gzip) | Slower compress, same decompress | All modern browsers |
| Gzip | Good (baseline) | Fast | Universal |
| Deflate | Moderate | Fastest | Universal |

### Webpack Compression Plugin

```typescript
// next.config.ts
const CompressionPlugin = require('compression-webpack-plugin');

module.exports = {
  webpack: (config, { isServer }) => {
    if (!isServer) {
      config.plugins.push(
        // Brotli (best compression, modern browsers)
        new CompressionPlugin({
          filename: '[path][base].br',
          algorithm: 'brotliCompress',
          test: /\.(js|css|html|svg)$/,
          threshold: 10240, // Only compress files > 10KB
          minRatio: 0.8,
        }),
        // Gzip (fallback for older browsers)
        new CompressionPlugin({
          filename: '[path][base].gz',
          algorithm: 'gzip',
          test: /\.(js|css|html|svg)$/,
          threshold: 10240,
          minRatio: 0.8,
        }),
      );
    }
    return config;
  },
};
```

### Vercel/CDN Configuration

```json
// vercel.json
{
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "Accept-Encoding",
          "value": "br, gzip, deflate"
        }
      ]
    },
    {
      "source": "/static/(.*)",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "public, max-age=31536000, immutable"
        }
      ]
    }
  ]
}
```

### Compression Comparison Script

```typescript
// scripts/compare-compression.ts
import { gzipSync, brotliCompressSync } from 'zlib';
import { readFileSync } from 'fs';

function compareCompression(filePath: string): void {
  const original = readFileSync(filePath);
  const gzipped = gzipSync(original, { level: 9 });
  const brotli = brotliCompressSync(original);

  console.log({
    file: filePath,
    original: `${(original.length / 1024).toFixed(2)} KB`,
    gzip: `${(gzipped.length / 1024).toFixed(2)} KB (${((1 - gzipped.length / original.length) * 100).toFixed(1)}% reduction)`,
    brotli: `${(brotli.length / 1024).toFixed(2)} KB (${((1 - brotli.length / original.length) * 100).toFixed(1)}% reduction)`,
  });
}
```

---

## 3. COMPRESSION STREAMS API

### Native Browser Compression

```typescript
// CompressionStream API (all modern browsers)
// Compress data in the browser without libraries

async function compressData(data: string): Promise<ArrayBuffer> {
  const blob = new Blob([data]);
  const stream = blob.stream().pipeThrough(new CompressionStream('gzip'));
  return new Response(stream).arrayBuffer();
}

async function decompressData(compressed: ArrayBuffer): Promise<string> {
  const blob = new Blob([compressed]);
  const stream = blob.stream().pipeThrough(new DecompressionStream('gzip'));
  return new Response(stream).text();
}

// Supported algorithms: 'gzip', 'deflate', 'deflate-raw'
```

### Streaming Compression for Large Data

```typescript
// Compress and upload large files
async function compressAndUpload(file: File, url: string): Promise<void> {
  const compressedStream = file.stream().pipeThrough(new CompressionStream('gzip'));

  await fetch(url, {
    method: 'POST',
    body: compressedStream,
    headers: {
      'Content-Encoding': 'gzip',
      'Content-Type': file.type,
    },
    // @ts-expect-error -- duplex required for streaming body
    duplex: 'half',
  });
}
```

### IndexedDB with Compression

```typescript
// Compress data before storing in IndexedDB
async function storeCompressed(db: IDBDatabase, key: string, data: unknown): Promise<void> {
  const json = JSON.stringify(data);
  const compressed = await compressData(json);

  const tx = db.transaction('cache', 'readwrite');
  tx.objectStore('cache').put({ key, data: compressed, timestamp: Date.now() });
}

async function loadCompressed(db: IDBDatabase, key: string): Promise<unknown> {
  const tx = db.transaction('cache', 'readonly');
  interface CacheEntry {
    key: string;
    data: ArrayBuffer;
    timestamp: number;
  }

  const result = await new Promise<CacheEntry | undefined>((resolve) => {
    const request = tx.objectStore('cache').get(key);
    request.onsuccess = () => resolve(request.result as CacheEntry | undefined);
  });

  if (!result) return null;
  const json = await decompressData(result.data);
  return JSON.parse(json);
}
```

---

## 4. API PAYLOAD OPTIMIZATION

### Select Specific Fields

```typescript
// BAD: Fetching all columns
const { data: bad } = await supabase.from('users').select('*');

// GOOD: Select specific columns
const { data: good } = await supabase
  .from('users')
  .select('id, name, avatar_url')
  .limit(20);

// GOOD: Paginated response
const { data: paginated } = await supabase
  .from('posts')
  .select('id, title, excerpt, author:users(name)')
  .range(0, 19)
  .order('created_at', { ascending: false });
```

### GraphQL Field Selection

```typescript
// BAD: Over-fetching
const BAD_QUERY = gql`
  query {
    user {
      id name email avatar bio createdAt
      posts { id title content comments { id text author { id name } } }
    }
  }
`;

// GOOD: Fetch only what's needed
const GOOD_QUERY = gql`
  query UserSummary($id: ID!) {
    user(id: $id) {
      id
      name
      avatar
    }
  }
`;
```

---

## 5. ADAPTIVE LOADING

### Type Declarations for Non-Standard Browser APIs

```typescript
// lib/performance/browser-types.d.ts — Augment Navigator for non-standard APIs

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

### Network Information API

```typescript
// lib/performance/adaptive-loading.ts

type ConnectionQuality = 'poor' | 'moderate' | 'good' | 'excellent';

function getConnectionQuality(): ConnectionQuality {
  const conn = navigator.connection;
  if (!conn) return 'good'; // Default

  // Effective type based
  if (conn.effectiveType === 'slow-2g' || conn.effectiveType === '2g') return 'poor';
  if (conn.effectiveType === '3g') return 'moderate';

  // Downlink speed based
  if (conn.downlink >= 10) return 'excellent';
  if (conn.downlink >= 5) return 'good';
  if (conn.downlink >= 1) return 'moderate';

  return 'poor';
}
```

### Device Memory API

```typescript
function getDeviceCapability(): 'low' | 'mid' | 'high' {
  const memory = navigator.deviceMemory; // GB
  const cores = navigator.hardwareConcurrency;

  if ((memory && memory <= 2) || (cores && cores <= 2)) return 'low';
  if ((memory && memory <= 4) || (cores && cores <= 4)) return 'mid';
  return 'high';
}
```

### Save-Data Header

```typescript
function respectsSaveData(): boolean {
  const conn = navigator.connection;
  return conn?.saveData === true;
}
```

### Adaptive Image Component

```tsx
// components/AdaptiveImage.tsx
'use client';

import Image from 'next/image';

interface AdaptiveImageProps {
  src: string;
  alt: string;
  width: number;
  height: number;
  className?: string;
}

export function AdaptiveImage({ src, alt, width, height, className }: AdaptiveImageProps) {
  const quality = getAdaptiveQuality();
  const sizes = getAdaptiveSizes();

  return (
    <Image
      src={src}
      alt={alt}
      width={width}
      height={height}
      quality={quality}
      sizes={sizes}
      loading="lazy"
      className={className}
    />
  );
}

function getAdaptiveQuality(): number {
  const conn = navigator.connection;

  if (conn?.saveData) return 40;

  switch (conn?.effectiveType) {
    case 'slow-2g':
    case '2g':
      return 40;
    case '3g':
      return 60;
    default:
      return 80;
  }
}

function getAdaptiveSizes(): string {
  const conn = navigator.connection;

  if (conn?.saveData || conn?.effectiveType === '2g') {
    return '50vw'; // Smaller images on slow connections
  }
  return '(max-width: 768px) 100vw, 50vw';
}
```

### Adaptive Provider

```tsx
// providers/AdaptiveProvider.tsx
'use client';

import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';

interface AdaptiveConfig {
  connectionQuality: ConnectionQuality;
  deviceCapability: 'low' | 'mid' | 'high';
  saveData: boolean;
  imageQuality: number;
  enableAnimations: boolean;
  enablePrefetch: boolean;
  videoAutoplay: boolean;
}

const AdaptiveContext = createContext<AdaptiveConfig>({
  connectionQuality: 'good',
  deviceCapability: 'high',
  saveData: false,
  imageQuality: 80,
  enableAnimations: true,
  enablePrefetch: true,
  videoAutoplay: true,
});

export function AdaptiveProvider({ children }: { children: ReactNode }) {
  const [config, setConfig] = useState<AdaptiveConfig>({
    connectionQuality: 'good',
    deviceCapability: 'high',
    saveData: false,
    imageQuality: 80,
    enableAnimations: true,
    enablePrefetch: true,
    videoAutoplay: true,
  });

  useEffect(() => {
    const conn = navigator.connection;
    const quality = getConnectionQuality();
    const capability = getDeviceCapability();
    const saveData = conn?.saveData ?? false;

    const isPoor = quality === 'poor' || capability === 'low' || saveData;

    setConfig({
      connectionQuality: quality,
      deviceCapability: capability,
      saveData,
      imageQuality: isPoor ? 40 : quality === 'moderate' ? 60 : 80,
      enableAnimations: !isPoor,
      enablePrefetch: !isPoor,
      videoAutoplay: quality === 'excellent' && capability === 'high',
    });

    // Listen for connection changes
    const handleChange = () => {
      setConfig((prev) => ({
        ...prev,
        connectionQuality: getConnectionQuality(),
      }));
    };

    conn?.addEventListener('change', handleChange);
    return () => conn?.removeEventListener('change', handleChange);
  }, []);

  return (
    <AdaptiveContext.Provider value={config}>
      {children}
    </AdaptiveContext.Provider>
  );
}

export const useAdaptive = () => useContext(AdaptiveContext);
```

### Client Hints (Server-Side Adaptive)

```typescript
// Accept-CH header for server-side adaptive loading
// vercel.json or proxy.ts
{
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "Accept-CH",
          "value": "DPR, Width, Viewport-Width, Downlink, ECT, Save-Data, Device-Memory"
        }
      ]
    }
  ]
}

// Server-side usage
export async function GET(request: Request) {
  const saveData = request.headers.get('Save-Data') === 'on';
  const ect = request.headers.get('ECT'); // '4g', '3g', '2g', 'slow-2g'
  const deviceMemory = Number(request.headers.get('Device-Memory')) || 8;

  if (saveData || ect === '2g') {
    return NextResponse.json(getLightweightData());
  }

  return NextResponse.json(getFullData());
}
```

---

## 6. NETWORK MONITORING

### Payload Analyzer

```typescript
// lib/performance/payload-analyzer.ts
export function analyzePayloads(): PayloadEntry[] {
  const resources = performance.getEntriesByType('resource') as PerformanceResourceTiming[];

  return resources
    .filter((r) => r.transferSize > 0)
    .map((r) => ({
      url: r.name,
      type: r.initiatorType,
      transferSize: r.transferSize,
      decodedSize: r.decodedBodySize,
      compressionRatio:
        r.decodedBodySize > 0 ? 1 - r.transferSize / r.decodedBodySize : 0,
    }))
    .sort((a, b) => b.transferSize - a.transferSize);
}

export function getPayloadSummary(): Record<string, number> {
  return analyzePayloads().reduce(
    (acc, p) => {
      const type = p.type || 'other';
      acc[type] = (acc[type] || 0) + p.transferSize;
      return acc;
    },
    {} as Record<string, number>,
  );
}
```

---

## 7. CHECKLIST

```markdown
## Network & Compression Checklist

### Compression
- [ ] Brotli compression enabled (CDN/Vercel)
- [ ] Gzip fallback configured
- [ ] Text assets > 10KB compressed
- [ ] CompressionStream for client-side compression

### Payload Budgets
- [ ] Initial JS < 100KB gzipped
- [ ] Total initial < 350KB gzipped
- [ ] API list responses < 50KB
- [ ] API detail responses < 10KB
- [ ] Paginated at < 25KB per page

### API Optimization
- [ ] Select specific columns (no SELECT *)
- [ ] Pagination on list endpoints
- [ ] GraphQL: no over-fetching
- [ ] Response compression middleware

### Adaptive Loading
- [ ] Network quality detection
- [ ] Device capability detection
- [ ] Save-Data header respected
- [ ] Image quality adapts to connection
- [ ] Prefetch disabled on slow connections
- [ ] Client Hints configured
```

---

<!-- NETWORK_COMPRESSION v24.7.0 | Payloads, Brotli/gzip, CompressionStream, adaptive loading -->
