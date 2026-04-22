# nextjs-patterns — Real-World Examples

The skill enforces Next.js App Router conventions: correct file roles (`error.tsx`, `loading.tsx`, `route.ts`), Server Action validation, `use client` pushed to leaf components, and `next/image` for all content images.

## Before / After

### Example 1: Server Action with no validation and wrong redirect

**Before** (triggers the skill):
```typescript
// ❌ Server Action: no 'use server', trusted client data, router.push instead of redirect
export async function updateProfile(formData: FormData) {
  // Missing 'use server' directive
  const name = formData.get('name') as string; // no validation, could be 10MB
  const bio = formData.get('bio') as string;   // could be HTML injection
  const userId = formData.get('userId') as string; // trusts client-supplied userId!

  await db.profiles.update({
    where: { id: userId },
    data: { name, bio },
  });

  // Router.push doesn't work in Server Actions — this is silently a no-op
  // router.push('/profile'); // TypeError: router is not defined
}
```

**After** (skill-compliant):
```typescript
// ✅ 'use server', Zod validation, server-side userId, redirect()
'use server';

import { z } from 'zod';
import { redirect } from 'next/navigation';
import { revalidatePath } from 'next/cache';
import { getAuthenticatedUser } from '@/lib/auth';

const updateProfileSchema = z.object({
  name: z.string().min(1, 'Name is required').max(50),
  bio: z.string().max(300).optional(),
});

export async function updateProfile(
  formData: FormData,
): Promise<{ success: true } | { error: Record<string, string[]> }> {
  // userId always from session — never trust form input
  const { user } = await getAuthenticatedUser();
  if (!user) return { error: { _form: ['Not authenticated'] } };

  const result = updateProfileSchema.safeParse({
    name: formData.get('name'),
    bio: formData.get('bio') ?? undefined,
  });

  if (!result.success) {
    return { error: result.error.flatten().fieldErrors };
  }

  await db.profiles.update({
    where: { id: user.id },
    data: result.data,
  });

  revalidatePath('/profile');
  redirect('/profile'); // correct way to navigate from Server Actions
}
```

**Why:** Missing `'use server'` means the function runs on the client — the `await db.profiles.update()` call either fails or, worse, your database credentials leak to the browser bundle. `router.push()` doesn't exist in a Server Action context; `redirect()` from `next/navigation` is the correct primitive. `userId` from `formData` is client-supplied and spoofable.

---

### Example 2: Raw `<img>` and missing loading/error boundaries

**Before** (triggers the skill):
```tsx
// ❌ Raw img, no loading.tsx, error crashes silently, no Suspense
// app/products/page.tsx
export default async function ProductsPage() {
  const products = await db.products.findMany(); // if this throws → white screen

  return (
    <div>
      {products.map(p => (
        <div key={p.id}>
          <img src={p.imageUrl} alt={p.name} /> {/* no optimization, CLS */}
          <h2 className="text-left ml-2">{p.name}</h2> {/* RTL violations */}
        </div>
      ))}
    </div>
  );
}
// No loading.tsx → user sees blank page during fetch
// No error.tsx → unhandled error shows Next.js default error page in production
```

**After** (skill-compliant):
```tsx
// app/products/loading.tsx — shown automatically during Server Component fetch
export default function ProductsLoading() {
  return (
    <div className="grid grid-cols-2 gap-4 p-4 md:grid-cols-3">
      {Array.from({ length: 6 }).map((_, i) => (
        <div key={i} className="animate-pulse rounded-lg bg-gray-100">
          <div className="aspect-square rounded-lg bg-gray-200" />
          <div className="ms-2 mt-2 h-4 w-3/4 rounded bg-gray-200" />
        </div>
      ))}
    </div>
  );
}

// app/products/error.tsx — segment-level error boundary
'use client'; // error boundaries MUST be Client Components
import { useEffect } from 'react';

export default function ProductsError({
  error,
  reset,
}: { error: Error & { digest?: string }; reset: () => void }) {
  useEffect(() => { console.error(error); }, [error]);
  return (
    <div role="alert" className="p-8 text-center">
      <p className="text-red-600">Failed to load products</p>
      <button onClick={reset} className="mt-4 rounded bg-blue-600 px-4 py-2 text-white">
        Try again
      </button>
    </div>
  );
}

// app/products/page.tsx — clean Server Component
import Image from 'next/image';

export default async function ProductsPage() {
  const products = await db.products.findMany({
    select: { id: true, name: true, imageUrl: true, priceCents: true },
  });

  return (
    <div className="grid grid-cols-2 gap-4 p-4 md:grid-cols-3">
      {products.map(p => (
        <div key={p.id} className="rounded-lg border">
          <Image src={p.imageUrl} alt={p.name} width={400} height={400}
                 className="aspect-square rounded-t-lg object-cover" />
          <h2 className="ms-2 mt-1 text-start font-semibold">{p.name}</h2>
        </div>
      ))}
    </div>
  );
}
```

**Why:** Without `loading.tsx`, the browser shows a blank white page until the entire server component resolves. Without `error.tsx`, an unhandled database error crashes the entire route segment with Next.js's default error page (which leaks stack traces in development). `next/image` prevents CLS by requiring explicit dimensions and automatically serves optimized WebP.

---

### Example 3: Misplaced `use client` hoisted to page level

**Before** (triggers the skill):
```tsx
// ❌ 'use client' on the page — entire tree becomes client bundle
'use client';

import { useState } from 'react';
import { ProductGrid } from './product-grid';   // static, no interactivity
import { CategoryNav } from './category-nav';   // static links
import { CartButton } from './cart-button';     // needs useState

export default function ShopPage() {
  const [cartOpen, setCartOpen] = useState(false);
  // All imports (ProductGrid, CategoryNav) now ship to the browser
  // Even though they have zero interactivity
  return (
    <div>
      <CategoryNav />
      <ProductGrid />
      <CartButton open={cartOpen} onToggle={() => setCartOpen(o => !o)} />
    </div>
  );
}
```

**After** (skill-compliant):
```tsx
// ✅ 'use client' pushed to the leaf — only CartButton ships to browser
// app/shop/page.tsx — Server Component (no directive)
import { ProductGrid } from './product-grid';   // stays on server
import { CategoryNav } from './category-nav';   // stays on server
import { CartDrawer } from './cart-drawer';      // 'use client' lives here

export default function ShopPage() {
  // Server Component: can await db, read cookies, access env vars
  return (
    <div>
      <CategoryNav />     {/* renders to HTML, zero client JS */}
      <ProductGrid />     {/* renders to HTML, zero client JS */}
      <CartDrawer />      {/* isolated client island with useState */}
    </div>
  );
}

// cart-drawer.tsx — 'use client' only where interactivity is needed
'use client';
import { useState } from 'react';

export function CartDrawer() {
  const [open, setOpen] = useState(false);
  return (
    <>
      <button onClick={() => setOpen(true)} aria-label="פתח עגלה">
        <ShoppingCart className="h-6 w-6" aria-hidden="true" />
      </button>
      {open && <CartPanel onClose={() => setOpen(false)} />}
    </>
  );
}
```

**Why:** `'use client'` marks a tree boundary — every component imported by the marked file becomes client-side JavaScript, regardless of its own interactivity. `ProductGrid` with 50 product cards and `CategoryNav` with 10 links become client bundle weight for no reason. Pushing the boundary to `CartDrawer` keeps the static parts as zero-JS server-rendered HTML.
