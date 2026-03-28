# PWA Manifest Complete Reference

> **v24.5.0 SINGULARITY FORGE** | PWA Expert Skill
> **Critical for:** Installability, Rich Install UI, Store Presence

---

## Complete manifest.json Template

```json
{
  "$schema": "https://json.schemastore.org/web-manifest-combined.json",
  "name": "App Full Name - Up to 45 characters",
  "short_name": "AppName",
  "description": "Full description of what your app does. Keep under 300 characters for best display.",
  "start_url": "/?source=pwa",
  "scope": "/",
  "display": "standalone",
  "display_override": ["window-controls-overlay", "standalone", "minimal-ui", "browser"],
  "orientation": "any",
  "theme_color": "#1a1a2e",
  "background_color": "#1a1a2e",
  "dir": "rtl",
  "lang": "he-IL",
  "id": "/",
  "categories": ["productivity", "utilities"],
  "iarc_rating_id": "",
  "prefer_related_applications": false,
  "related_applications": [],
  "icons": [
    {
      "src": "/icons/icon-192x192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "/icons/icon-512x512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "/icons/icon-maskable-512x512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "maskable"
    }
  ],
  "screenshots": [
    {
      "src": "/screenshots/mobile-1.png",
      "sizes": "1080x1920",
      "type": "image/png",
      "form_factor": "narrow",
      "label": "מסך הבית של האפליקציה"
    },
    {
      "src": "/screenshots/mobile-2.png",
      "sizes": "1080x1920",
      "type": "image/png",
      "form_factor": "narrow",
      "label": "תצוגת הפרופיל"
    },
    {
      "src": "/screenshots/desktop-1.png",
      "sizes": "1920x1080",
      "type": "image/png",
      "form_factor": "wide",
      "label": "תצוגת שולחן עבודה"
    }
  ],
  "shortcuts": [
    {
      "name": "הוסף פריט חדש",
      "short_name": "הוסף",
      "description": "הוספת פריט חדש לרשימה",
      "url": "/new?source=shortcut",
      "icons": [
        {
          "src": "/icons/shortcut-add.png",
          "sizes": "96x96",
          "type": "image/png"
        }
      ]
    },
    {
      "name": "הגדרות",
      "short_name": "הגדרות",
      "url": "/settings?source=shortcut",
      "icons": [
        {
          "src": "/icons/shortcut-settings.png",
          "sizes": "96x96",
          "type": "image/png"
        }
      ]
    }
  ],
  "share_target": {
    "action": "/share-target",
    "method": "POST",
    "enctype": "multipart/form-data",
    "params": {
      "title": "title",
      "text": "text",
      "url": "url",
      "files": [
        {
          "name": "media",
          "accept": ["image/*", "video/*"]
        }
      ]
    }
  },
  "file_handlers": [
    {
      "action": "/open-file",
      "accept": {
        "application/json": [".json"],
        "text/plain": [".txt", ".md"]
      }
    }
  ],
  "protocol_handlers": [
    {
      "protocol": "web+myapp",
      "url": "/handle-protocol?url=%s"
    }
  ],
  "launch_handler": {
    "client_mode": ["navigate-existing", "auto"]
  },
  "handle_links": "preferred",
  "edge_side_panel": {
    "preferred_width": 400
  }
}
```

---

## Manifest Properties Reference

### Required Properties

| Property | Description | Example |
|----------|-------------|---------|
| `name` | Full app name (max 45 chars) | `"My App - Task Manager"` |
| `short_name` | Abbreviated name (max 12 chars) | `"MyApp"` |
| `start_url` | Entry point URL | `"/?source=pwa"` |
| `icons` | App icons (192x192 + 512x512 minimum) | See icons section |
| `display` | Display mode | `"standalone"` |

### Recommended Properties

| Property | Description | Example |
|----------|-------------|---------|
| `description` | App description (max 300 chars) | `"Manage tasks efficiently"` |
| `theme_color` | Browser UI color | `"#1a1a2e"` |
| `background_color` | Splash screen background | `"#1a1a2e"` |
| `scope` | Navigation scope | `"/"` |
| `id` | Unique app identifier | `"/"` |
| `lang` | Primary language | `"he-IL"` |
| `dir` | Text direction | `"rtl"` |

### Advanced Properties

| Property | Description | Browser Support |
|----------|-------------|-----------------|
| `display_override` | Fallback display modes | Chrome 89+ |
| `screenshots` | Rich install UI images | Chrome 90+ |
| `shortcuts` | App shortcuts | Chrome 84+ |
| `share_target` | Receive shared content | Chrome 71+ |
| `file_handlers` | Open files with app | Chrome 102+ |
| `protocol_handlers` | Custom URL protocols | Chrome 96+ |
| `launch_handler` | Control launch behavior | Chrome 110+ |
| `handle_links` | Capture link clicks | Chrome 121+ |
| `edge_side_panel` | Edge sidebar support | Edge 114+ |

---

## Icons - Complete Requirements

### Minimum Required Icons

| Size | Purpose | Notes |
|------|---------|-------|
| 192x192 | `any` | Chrome minimum for install |
| 512x512 | `any` | Chrome minimum for splash |
| 512x512 | `maskable` | Android adaptive icons |

### Recommended Icon Set

```json
{
  "icons": [
    {
      "src": "/icons/icon-72x72.png",
      "sizes": "72x72",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "/icons/icon-96x96.png",
      "sizes": "96x96",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "/icons/icon-128x128.png",
      "sizes": "128x128",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "/icons/icon-144x144.png",
      "sizes": "144x144",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "/icons/icon-152x152.png",
      "sizes": "152x152",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "/icons/icon-192x192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "/icons/icon-384x384.png",
      "sizes": "384x384",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "/icons/icon-512x512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "/icons/maskable-192x192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "maskable"
    },
    {
      "src": "/icons/maskable-512x512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "maskable"
    }
  ]
}
```

### Icon Purpose Values

| Purpose | Description | Use Case |
|---------|-------------|----------|
| `any` | Standard icon | Default, works everywhere |
| `maskable` | Adaptive icon | Android 8+, safe zone required |
| `monochrome` | Single-color icon | Android notification, theming |

### CRITICAL: Maskable Safe Zone

**NEVER use `"purpose": "any maskable"`** - Chrome warns against this!

Maskable icons have an 80% safe zone (circular). Keep ALL important content inside:

```
┌──────────────────────────────┐
│                              │
│    ┌──────────────────┐      │
│    │                  │      │
│    │    SAFE ZONE     │      │
│    │    (80% circle)  │      │
│    │                  │      │
│    └──────────────────┘      │
│                              │
└──────────────────────────────┘
```

Test maskable icons: https://maskable.app/

### Icon Generator Script

```typescript
import sharp from 'sharp';
import fs from 'fs/promises';
import path from 'path';

const ICON_SIZES = [72, 96, 128, 144, 152, 192, 384, 512];

async function generateIcons(sourcePath: string, outputDir: string) {
  await fs.mkdir(outputDir, { recursive: true });

  // Generate "any" purpose icons
  for (const size of ICON_SIZES) {
    await sharp(sourcePath)
      .resize(size, size, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
      .png()
      .toFile(path.join(outputDir, `icon-${size}x${size}.png`));

    console.log(`Generated: icon-${size}x${size}.png`);
  }
}

async function generateMaskableIcons(sourcePath: string, backgroundColor: string, outputDir: string) {
  await fs.mkdir(outputDir, { recursive: true });

  const sizes = [192, 512];

  for (const size of sizes) {
    // Maskable needs padding for safe zone (20% padding = 60% logo)
    const logoSize = Math.floor(size * 0.6);
    const padding = Math.floor((size - logoSize) / 2);

    // Resize logo
    const resizedLogo = await sharp(sourcePath)
      .resize(logoSize, logoSize, { fit: 'contain' })
      .toBuffer();

    // Create maskable with background
    await sharp({
      create: {
        width: size,
        height: size,
        channels: 4,
        background: backgroundColor,
      },
    })
      .composite([
        {
          input: resizedLogo,
          left: padding,
          top: padding,
        },
      ])
      .png()
      .toFile(path.join(outputDir, `maskable-${size}x${size}.png`));

    console.log(`Generated: maskable-${size}x${size}.png`);
  }
}

// Usage
generateIcons('./src/logo.svg', './public/icons');
generateMaskableIcons('./src/logo.svg', '#1a1a2e', './public/icons');
```

---

## Screenshots for Rich Install UI

### Requirements

| Requirement | Value |
|-------------|-------|
| Minimum width | 320px |
| Maximum width | 3840px |
| Aspect ratio | Max 2.3:1 |
| Format | PNG or JPEG only |
| Max count | 8 screenshots |

### Form Factors

| Form Factor | Description | Use Case |
|-------------|-------------|----------|
| `narrow` | Mobile portrait | Phone install UI |
| `wide` | Desktop/landscape | Desktop install UI |

### Screenshot Best Practices

```json
{
  "screenshots": [
    {
      "src": "/screenshots/mobile-home.png",
      "sizes": "1080x1920",
      "type": "image/png",
      "form_factor": "narrow",
      "label": "מסך הבית - סקירה מהירה של המשימות שלך"
    },
    {
      "src": "/screenshots/mobile-tasks.png",
      "sizes": "1080x1920",
      "type": "image/png",
      "form_factor": "narrow",
      "label": "ניהול משימות - הוספה, עריכה ומעקב"
    },
    {
      "src": "/screenshots/mobile-calendar.png",
      "sizes": "1080x1920",
      "type": "image/png",
      "form_factor": "narrow",
      "label": "תצוגת לוח שנה - ראה את כל האירועים"
    },
    {
      "src": "/screenshots/desktop-dashboard.png",
      "sizes": "1920x1080",
      "type": "image/png",
      "form_factor": "wide",
      "label": "לוח בקרה בשולחן עבודה - תצוגה מלאה"
    },
    {
      "src": "/screenshots/desktop-analytics.png",
      "sizes": "1920x1080",
      "type": "image/png",
      "form_factor": "wide",
      "label": "ניתוח נתונים - תובנות על הפרודוקטיביות שלך"
    }
  ]
}
```

---

## Display Modes

### Available Modes

| Mode | Description | Browser UI |
|------|-------------|------------|
| `fullscreen` | Full screen, no UI | None |
| `standalone` | App-like, minimal UI | Status bar only |
| `minimal-ui` | Some browser UI | Status bar + minimal nav |
| `browser` | Full browser UI | Full browser chrome |
| `window-controls-overlay` | Custom title bar | Traffic lights only |

### Display Override (Fallback Chain)

```json
{
  "display": "standalone",
  "display_override": [
    "window-controls-overlay",
    "standalone",
    "minimal-ui",
    "browser"
  ]
}
```

Browser tries modes in order, falls back if unsupported.

### Detecting Display Mode

```typescript
function getDisplayMode(): string {
  const modes = [
    { query: '(display-mode: fullscreen)', mode: 'fullscreen' },
    { query: '(display-mode: standalone)', mode: 'standalone' },
    { query: '(display-mode: minimal-ui)', mode: 'minimal-ui' },
    { query: '(display-mode: window-controls-overlay)', mode: 'window-controls-overlay' },
  ];

  for (const { query, mode } of modes) {
    if (window.matchMedia(query).matches) {
      return mode;
    }
  }

  // Check iOS standalone
  if ((navigator as any).standalone === true) {
    return 'standalone';
  }

  return 'browser';
}

// React hook
function useDisplayMode(): string {
  const [mode, setMode] = useState(getDisplayMode());

  useEffect(() => {
    const queries = [
      '(display-mode: fullscreen)',
      '(display-mode: standalone)',
      '(display-mode: minimal-ui)',
      '(display-mode: window-controls-overlay)',
    ];

    const handlers = queries.map(query => {
      const mql = window.matchMedia(query);
      const handler = () => setMode(getDisplayMode());
      mql.addEventListener('change', handler);
      return { mql, handler };
    });

    return () => {
      handlers.forEach(({ mql, handler }) => {
        mql.removeEventListener('change', handler);
      });
    };
  }, []);

  return mode;
}
```

---

## Shortcuts (App Shortcuts)

### Requirements

- Max 4 shortcuts (first 4 are shown)
- Icon size: 96x96 minimum (192x192 recommended)
- URL must be within app scope

```json
{
  "shortcuts": [
    {
      "name": "הוסף פריט חדש",
      "short_name": "הוסף",
      "description": "הוספת פריט חדש לרשימה במהירות",
      "url": "/new?source=shortcut",
      "icons": [
        {
          "src": "/icons/shortcuts/add-192.png",
          "sizes": "192x192",
          "type": "image/png"
        }
      ]
    },
    {
      "name": "חיפוש",
      "short_name": "חפש",
      "description": "חיפוש בכל הפריטים",
      "url": "/search?source=shortcut",
      "icons": [
        {
          "src": "/icons/shortcuts/search-192.png",
          "sizes": "192x192",
          "type": "image/png"
        }
      ]
    },
    {
      "name": "הגדרות",
      "short_name": "הגדרות",
      "description": "ניהול הגדרות האפליקציה",
      "url": "/settings?source=shortcut",
      "icons": [
        {
          "src": "/icons/shortcuts/settings-192.png",
          "sizes": "192x192",
          "type": "image/png"
        }
      ]
    }
  ]
}
```

---

## Share Target

### Receive Text/URLs

```json
{
  "share_target": {
    "action": "/share-target",
    "method": "GET",
    "params": {
      "title": "title",
      "text": "text",
      "url": "url"
    }
  }
}
```

### Receive Files

```json
{
  "share_target": {
    "action": "/share-target",
    "method": "POST",
    "enctype": "multipart/form-data",
    "params": {
      "title": "title",
      "text": "text",
      "url": "url",
      "files": [
        {
          "name": "images",
          "accept": ["image/*"]
        },
        {
          "name": "files",
          "accept": [
            "application/pdf",
            "application/json",
            "text/*"
          ]
        }
      ]
    }
  }
}
```

### Share Target Handler (Next.js)

```typescript
// app/share-target/route.ts
import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  const formData = await request.formData();

  const title = formData.get('title') as string | null;
  const text = formData.get('text') as string | null;
  const url = formData.get('url') as string | null;
  const files = formData.getAll('images') as File[];

  // Process shared content
  const shareData = {
    title,
    text,
    url,
    fileCount: files.length,
  };

  console.log('Received share:', shareData);

  // Handle files
  for (const file of files) {
    // Save or process file
    const buffer = await file.arrayBuffer();
    // await saveFile(file.name, buffer);
  }

  // Redirect to app with shared content
  const redirectUrl = new URL('/shared', request.url);
  if (title) redirectUrl.searchParams.set('title', title);
  if (text) redirectUrl.searchParams.set('text', text);
  if (url) redirectUrl.searchParams.set('url', url);

  return NextResponse.redirect(redirectUrl);
}

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);

  const title = searchParams.get('title');
  const text = searchParams.get('text');
  const url = searchParams.get('url');

  // Redirect to app with query params
  const redirectUrl = new URL('/shared', request.url);
  if (title) redirectUrl.searchParams.set('title', title);
  if (text) redirectUrl.searchParams.set('text', text);
  if (url) redirectUrl.searchParams.set('url', url);

  return NextResponse.redirect(redirectUrl);
}
```

---

## File Handlers

```json
{
  "file_handlers": [
    {
      "action": "/open-file",
      "accept": {
        "application/json": [".json"],
        "text/plain": [".txt", ".md"],
        "image/png": [".png"],
        "image/jpeg": [".jpg", ".jpeg"]
      }
    }
  ]
}
```

### File Handler Page

```typescript
// app/open-file/page.tsx
'use client';

import { useEffect, useState } from 'react';

export default function OpenFilePage() {
  const [files, setFiles] = useState<File[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function handleFiles() {
      if ('launchQueue' in window) {
        // Launch Handler API (experimental, no stable types yet)
        (window as unknown as { launchQueue: { setConsumer: (cb: (params: { files?: Array<{ getFile: () => Promise<File> }>; }) => Promise<void>) => void } }).launchQueue.setConsumer(async (launchParams: { files?: Array<{ getFile: () => Promise<File> }> }) => {
          if (!launchParams.files?.length) return;

          const fileHandles = launchParams.files;
          const loadedFiles: File[] = [];

          for (const handle of fileHandles) {
            try {
              const file = await handle.getFile();
              loadedFiles.push(file);
            } catch (e) {
              setError(`Failed to open file: ${(e as Error).message}`);
            }
          }

          setFiles(loadedFiles);
        });
      }
    }

    handleFiles();
  }, []);

  return (
    <div>
      <h1>Open File</h1>
      {error && <p className="error">{error}</p>}
      {files.map((file, i) => (
        <div key={i}>
          <p>{file.name} ({file.type})</p>
          <p>{(file.size / 1024).toFixed(2)} KB</p>
        </div>
      ))}
    </div>
  );
}
```

---

## Protocol Handlers

```json
{
  "protocol_handlers": [
    {
      "protocol": "web+myapp",
      "url": "/handle-protocol?url=%s"
    }
  ]
}
```

### Usage

Links like `web+myapp://open/item/123` will open your PWA with `/handle-protocol?url=web%2Bmyapp%3A%2F%2Fopen%2Fitem%2F123`

```typescript
// app/handle-protocol/page.tsx
'use client';

import { useSearchParams, useRouter } from 'next/navigation';
import { useEffect } from 'react';

export default function HandleProtocolPage() {
  const searchParams = useSearchParams();
  const router = useRouter();

  useEffect(() => {
    const url = searchParams.get('url');
    if (!url) return;

    // Parse the protocol URL
    const parsed = new URL(url);
    const path = parsed.pathname;

    // Route based on path
    if (path.startsWith('/open/item/')) {
      const itemId = path.split('/').pop();
      router.replace(`/items/${itemId}`);
    } else {
      router.replace('/');
    }
  }, [searchParams, router]);

  return <div>Loading...</div>;
}
```

---

## Launch Handler

Control how the app launches when already open:

```json
{
  "launch_handler": {
    "client_mode": ["navigate-existing", "auto"]
  }
}
```

| Mode | Behavior |
|------|----------|
| `auto` | Browser decides |
| `navigate-new` | Always open new window |
| `navigate-existing` | Reuse existing window |
| `focus-existing` | Focus existing, don't navigate |

---

## Scope and Navigation

### Scope

```json
{
  "scope": "/",
  "start_url": "/"
}
```

- Navigation outside scope opens in browser
- Can break auth flows if login is on different domain

### Handle Links

```json
{
  "handle_links": "preferred"
}
```

| Value | Behavior |
|-------|----------|
| `auto` | Browser decides |
| `preferred` | PWA captures links when possible |
| `not-preferred` | Links open in browser |

---

## Orientation Lock Warning

**WCAG 2.1 Level AA Violation!**

Locking orientation can fail accessibility requirements. Only lock if absolutely necessary (games).

```json
{
  "orientation": "any"
}
```

Options: `any`, `natural`, `landscape`, `portrait`, `portrait-primary`, `portrait-secondary`, `landscape-primary`, `landscape-secondary`

---

## Categories

For app store listings:

```json
{
  "categories": ["productivity", "utilities", "business"]
}
```

Valid categories: `books`, `business`, `education`, `entertainment`, `finance`, `fitness`, `food`, `games`, `government`, `health`, `kids`, `lifestyle`, `magazines`, `medical`, `music`, `navigation`, `news`, `personalization`, `photo`, `politics`, `productivity`, `security`, `shopping`, `social`, `sports`, `travel`, `utilities`, `weather`

---

## RTL Support

```json
{
  "dir": "rtl",
  "lang": "he-IL",
  "name": "האפליקציה שלי",
  "short_name": "אפליקציה",
  "description": "תיאור מלא של האפליקציה בעברית"
}
```

---

## Next.js Manifest Generation

```typescript
// app/manifest.ts
import type { MetadataRoute } from 'next';

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: 'My PWA App',
    short_name: 'MyPWA',
    description: 'A progressive web application',
    start_url: '/',
    display: 'standalone',
    background_color: '#1a1a2e',
    theme_color: '#1a1a2e',
    dir: 'rtl',
    lang: 'he-IL',
    icons: [
      {
        src: '/icons/icon-192x192.png',
        sizes: '192x192',
        type: 'image/png',
      },
      {
        src: '/icons/icon-512x512.png',
        sizes: '512x512',
        type: 'image/png',
      },
      {
        src: '/icons/maskable-512x512.png',
        sizes: '512x512',
        type: 'image/png',
        purpose: 'maskable',
      },
    ],
    screenshots: [
      {
        src: '/screenshots/mobile-1.png',
        sizes: '1080x1920',
        type: 'image/png',
        // @ts-ignore - Next.js types don't include form_factor yet
        form_factor: 'narrow',
      },
    ],
  };
}
```

---

## Manifest Validation Checklist

- [ ] `name` and `short_name` provided
- [ ] `start_url` is within `scope`
- [ ] Icons: 192x192 and 512x512 minimum
- [ ] Maskable icon has content in 80% safe zone
- [ ] `display` is `standalone` or `fullscreen`
- [ ] `theme_color` and `background_color` set
- [ ] `description` under 300 characters
- [ ] Screenshots have correct dimensions
- [ ] RTL apps have `dir: "rtl"` and `lang` set
- [ ] Shortcuts icons are 96x96 minimum
- [ ] Protocol handlers use `web+` prefix

<!-- PWA-EXPERT/MANIFEST-COMPLETE v24.5.0 SINGULARITY FORGE | Updated: 2026-02-19 -->

