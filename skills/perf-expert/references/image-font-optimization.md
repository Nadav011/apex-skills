# Image & Font Optimization - Comprehensive Reference

> **APEX-PERF v24.7.0** | Domain: Performance/Assets
> Consolidates: image-optimization

---

## 1. IMAGE BUDGETS

| Image Type | Max Size | Format | Quality |
|------------|----------|--------|---------|
| Hero/Banner | < 100KB (< 50KB APEX) | AVIF/WebP | 75-80 |
| Product/Card | < 50KB | AVIF/WebP | 75-80 |
| Thumbnail | < 15KB | AVIF/WebP | 70-75 |
| Icon/Logo | < 5KB | SVG/WebP | N/A |
| Background | < 80KB | AVIF/WebP | 70 |
| Avatar | < 10KB | AVIF/WebP | 75 |

### Format Comparison

| Format | Compression | Browser Support | Use Case |
|--------|-------------|-----------------|----------|
| AVIF | Best (50% smaller than JPEG) | Chrome 85+, Firefox 93+, Safari 16+ | Default for photos |
| WebP | Good (25-35% smaller than JPEG) | All modern browsers | Fallback for AVIF |
| JPEG XL | Excellent | Chrome behind flag | Future consideration |
| SVG | Lossless (vector) | All browsers | Icons, logos, illustrations |
| PNG | Lossless (raster) | All browsers | Screenshots, transparency needed |

---

## 2. NEXT.JS IMAGE COMPONENT

### Basic Usage

```tsx
// components/OptimizedImage.tsx
import Image from 'next/image';

interface OptimizedImageProps {
  src: string;
  alt: string;
  priority?: boolean;
  sizes?: string;
  className?: string;
}

export function OptimizedImage({
  src,
  alt,
  priority = false,
  sizes = '(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw',
  className,
}: OptimizedImageProps) {
  return (
    <Image
      src={src}
      alt={alt}
      fill
      priority={priority}
      sizes={sizes}
      quality={80}
      placeholder="blur"
      blurDataURL="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD..."
      className={className}
    />
  );
}
```

### Hero Image (LCP Priority)

```tsx
// components/HeroImage.tsx
import Image from 'next/image';

export function HeroImage({ src, alt }: { src: string; alt: string }) {
  return (
    <div className="relative aspect-video w-full">
      <Image
        src={src}
        alt={alt}
        fill
        priority // Adds fetchPriority="high" + preload link
        sizes="100vw"
        quality={80}
        className="object-cover"
      />
    </div>
  );
}
```

### Responsive Image Patterns

```tsx
// Art direction with <picture>
export function ResponsiveHero() {
  return (
    <picture>
      <source
        media="(max-width: 640px)"
        srcSet="/hero-mobile.avif"
        type="image/avif"
      />
      <source
        media="(max-width: 640px)"
        srcSet="/hero-mobile.webp"
        type="image/webp"
      />
      <source
        media="(min-width: 641px)"
        srcSet="/hero-desktop.avif"
        type="image/avif"
      />
      <source
        media="(min-width: 641px)"
        srcSet="/hero-desktop.webp"
        type="image/webp"
      />
      <img
        src="/hero-desktop.jpg"
        alt="Hero image"
        width={1200}
        height={630}
        fetchPriority="high"
        decoding="async"
        className="w-full object-cover"
      />
    </picture>
  );
}
```

---

## 3. IMAGE CONFIGURATION

### next.config.ts

```typescript
// next.config.ts
module.exports = {
  images: {
    // Serve modern formats automatically
    formats: ['image/avif', 'image/webp'],

    // Device sizes for responsive images
    deviceSizes: [640, 750, 828, 1080, 1200, 1920],

    // Image sizes for width-based sizing
    imageSizes: [16, 32, 48, 64, 96, 128, 256],

    // Cache optimized images for 1 year
    minimumCacheTTL: 60 * 60 * 24 * 365,

    // External image domains
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'cdn.example.com',
      },
      {
        protocol: 'https',
        hostname: '*.supabase.co',
      },
    ],
  },
};
```

### Sharp Processing (Build-Time)

```typescript
// scripts/optimize-images.ts
import sharp from 'sharp';
import { globSync } from 'glob';
import { mkdirSync } from 'fs';

const INPUT_DIR = 'public/images';
const OUTPUT_DIR = 'public/optimized';

async function optimizeImages(): Promise<void> {
  mkdirSync(OUTPUT_DIR, { recursive: true });
  const images = globSync(`${INPUT_DIR}/**/*.{jpg,jpeg,png}`);

  for (const imagePath of images) {
    const name = imagePath.replace(INPUT_DIR, '').replace(/\.[^.]+$/, '');

    // Generate AVIF
    await sharp(imagePath)
      .avif({ quality: 75 })
      .toFile(`${OUTPUT_DIR}${name}.avif`);

    // Generate WebP
    await sharp(imagePath)
      .webp({ quality: 80 })
      .toFile(`${OUTPUT_DIR}${name}.webp`);

    // Generate responsive sizes
    for (const width of [640, 1080, 1920]) {
      await sharp(imagePath)
        .resize(width)
        .avif({ quality: 75 })
        .toFile(`${OUTPUT_DIR}${name}-${width}.avif`);

      await sharp(imagePath)
        .resize(width)
        .webp({ quality: 80 })
        .toFile(`${OUTPUT_DIR}${name}-${width}.webp`);
    }
  }
}

optimizeImages();
```

---

## 4. BLUR PLACEHOLDER GENERATION

```typescript
// lib/image/blur-placeholder.ts
import sharp from 'sharp';

export async function generateBlurDataURL(
  imagePath: string,
): Promise<string> {
  const buffer = await sharp(imagePath)
    .resize(10, 10, { fit: 'inside' })
    .blur()
    .toBuffer();

  return `data:image/jpeg;base64,${buffer.toString('base64')}`;
}

// Generate for all images at build time
async function generatePlaceholders(): Promise<Record<string, string>> {
  const images = globSync('public/images/**/*.{jpg,jpeg,png,webp}');
  const placeholders: Record<string, string> = {};

  for (const img of images) {
    const key = img.replace('public', '');
    placeholders[key] = await generateBlurDataURL(img);
  }

  return placeholders;
}
```

---

## 5. FONT OPTIMIZATION

### Next.js Font System

```typescript
// app/layout.tsx
import { Heebo, Fira_Code } from 'next/font/google';
import localFont from 'next/font/local';

// Google Font -- auto-optimized, self-hosted
const heebo = Heebo({
  subsets: ['hebrew', 'latin'],
  display: 'swap',
  variable: '--font-heebo',
  preload: true,
  weight: ['400', '500', '600', '700'],
});

// Monospace for code
const firaCode = Fira_Code({
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-fira-code',
  preload: false, // Not critical
});

// Local font with size-adjust
const customFont = localFont({
  src: [
    { path: './fonts/Custom-Regular.woff2', weight: '400', style: 'normal' },
    { path: './fonts/Custom-Bold.woff2', weight: '700', style: 'normal' },
  ],
  display: 'swap',
  variable: '--font-custom',
  adjustFontFallback: 'Arial', // Auto size-adjust
});

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="he" dir="rtl" className={`${heebo.variable} ${firaCode.variable}`}>
      <body className="font-sans">{children}</body>
    </html>
  );
}
```

### Font Performance Best Practices

```css
/* Prevent FOIT with font-display */
@font-face {
  font-family: 'Heebo';
  src: url('/fonts/Heebo-Variable.woff2') format('woff2-variations');
  font-display: swap;
  font-weight: 100 900;
  unicode-range: U+0590-05FF, U+200C-2010, U+20AA, U+25CC, U+FB1D-FB4F;
  /* Hebrew subset only -- reduces file size */
}

/* Font size-adjust to prevent CLS */
@font-face {
  font-family: 'Heebo';
  src: url('/fonts/Heebo-Variable.woff2') format('woff2-variations');
  font-display: swap;
  size-adjust: 105%;
  ascent-override: 90%;
  descent-override: 20%;
}
```

### Font Loading Strategy

| Strategy | FOUT | FOIT | CLS | Best For |
|----------|------|------|-----|----------|
| `swap` | Yes | No | Possible | Primary text fonts |
| `optional` | No | Brief | None | Non-critical fonts |
| `fallback` | Brief | Brief | Minimal | Secondary fonts |
| `block` | No | Yes (3s) | None | Icon fonts |

**Recommendation:** Use `swap` with `size-adjust` for Hebrew text fonts. Use `optional` for decorative fonts.

---

## 6. LAZY LOADING IMAGES

### Intersection Observer Pattern

```typescript
// hooks/useLazyImage.ts
'use client';

import { useState, useEffect, useRef } from 'react';

export function useLazyImage() {
  const [isVisible, setIsVisible] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setIsVisible(true);
          observer.disconnect();
        }
      },
      { rootMargin: '200px' }, // Start loading 200px before visible
    );

    if (ref.current) observer.observe(ref.current);

    return () => observer.disconnect();
  }, []);

  return { ref, isVisible };
}

// Usage
function LazyImage({ src, alt }: { src: string; alt: string }) {
  const { ref, isVisible } = useLazyImage();

  return (
    <div ref={ref} className="relative aspect-video">
      {isVisible ? (
        <Image src={src} alt={alt} fill sizes="100vw" />
      ) : (
        <div className="h-full w-full animate-pulse bg-muted" />
      )}
    </div>
  );
}
```

### Native Lazy Loading

```tsx
// For images below the fold -- native lazy loading
<Image
  src={src}
  alt={alt}
  width={800}
  height={450}
  loading="lazy" // Default for non-priority images in Next.js
  sizes="(max-width: 768px) 100vw, 50vw"
/>

// For hero images above the fold -- eager with priority
<Image
  src={heroSrc}
  alt={heroAlt}
  width={1200}
  height={630}
  priority // Sets loading="eager" + fetchPriority="high"
  sizes="100vw"
/>
```

---

## 7. SVG OPTIMIZATION

```typescript
// SVG as React component (inline, cacheable)
import { type SVGProps } from 'react';

export function ArrowIcon(props: SVGProps<SVGSVGElement>) {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={2}
      className="rtl:rotate-180" // RTL support
      {...props}
    >
      <path d="M5 12h14M12 5l7 7-7 7" />
    </svg>
  );
}

// Icon library (tree-shaken)
import { ArrowRight, Menu, X } from 'lucide-react';

// Configure in next.config.ts for optimal tree shaking
module.exports = {
  experimental: {
    optimizePackageImports: ['lucide-react'],
  },
};
```

---

## 8. CHECKLIST

```markdown
## Image & Font Optimization Checklist

### Images
- [ ] Hero image < 50KB (APEX) / < 100KB (budget)
- [ ] AVIF format with WebP fallback
- [ ] Responsive sizes configured
- [ ] priority on LCP images
- [ ] Lazy loading for below-fold images
- [ ] Blur placeholders generated
- [ ] Alt text on all images
- [ ] Sharp processing for build-time optimization
- [ ] CDN for external images

### Fonts
- [ ] font-display: swap on all fonts
- [ ] Variable fonts where available
- [ ] Unicode-range subsetting (Hebrew, Latin)
- [ ] size-adjust to prevent CLS
- [ ] Preload critical fonts
- [ ] Maximum 2-3 font families
- [ ] WOFF2 format (best compression)
- [ ] next/font for auto-optimization

### SVG/Icons
- [ ] SVG for icons and logos
- [ ] Tree-shaken icon library (lucide-react)
- [ ] rtl:rotate-180 on directional icons
- [ ] Inline SVG for frequently used icons
```

---

<!-- IMAGE_FONT_OPTIMIZATION v24.7.0 | Image formats, responsive, Next.js Image, fonts, SVG -->
