# backend-rules — Real-World Examples

The skill enforces the non-negotiable backend order: rate limit → auth (`getUser()`) → Zod validation → authorization → business logic → response. Any deviation is a production incident waiting to happen.

## Before / After

### Example 1: Route handler with missing auth and no validation

**Before** (triggers the skill):
```typescript
// ❌ No rate limit, getSession instead of getUser, no Zod, no authz
export async function POST(request: Request) {
  const session = await getServerSession(authOptions); // trusts cookie, not server-validated
  const body = await request.json(); // no validation

  const comment = await db.comments.create({
    data: {
      content: body.content, // unsanitized
      postId: body.postId,   // no ownership check
      authorId: session?.user?.id ?? 'anonymous', // null session allowed
    },
  });

  return Response.json(comment);
}
```

**After** (skill-compliant):
```typescript
// ✅ Full order: rate limit → getUser → Zod → authz → business logic
import { z } from 'zod';
import { getClientIp, commentRatelimit } from '@/lib/ratelimit';
import { getAuthenticatedUser } from '@/lib/auth';

const createCommentSchema = z.object({
  postId: z.string().uuid(),
  content: z.string().min(1).max(2000),
});

export async function POST(request: Request) {
  // 1. Rate limit — always first
  const ip = getClientIp(request);
  const { success, limit, remaining, reset } = await commentRatelimit.limit(ip);
  if (!success) {
    return Response.json({ error: 'Rate limit exceeded' }, {
      status: 429,
      headers: { 'Retry-After': String(Math.ceil((reset - Date.now()) / 1000)) },
    });
  }

  // 2. Server-validated auth
  const { user, error } = await getAuthenticatedUser();
  if (!user || error) return Response.json({ error: 'Unauthorized' }, { status: 401 });

  // 3. Zod input validation
  let raw: unknown;
  try { raw = await request.json(); }
  catch { return Response.json({ error: 'Invalid JSON' }, { status: 400 }); }

  const result = createCommentSchema.safeParse(raw);
  if (!result.success) {
    return Response.json(
      { error: 'Validation failed', details: result.error.flatten().fieldErrors },
      { status: 422 }
    );
  }

  // 4. Authorization — verify the post exists and is commentable
  const post = await db.posts.findUnique({
    where: { id: result.data.postId, commentsEnabled: true },
  });
  if (!post) return Response.json({ error: 'Not found' }, { status: 404 });

  // 5. Business logic
  const comment = await db.comments.create({
    data: { content: result.data.content, postId: post.id, authorId: user.id },
    select: { id: true, content: true, createdAt: true, authorId: true },
  });

  return Response.json({ data: comment }, { status: 201 });
}
```

**Why:** Using `getServerSession()` (or `getSession()`) trusts the client cookie without round-tripping to the Supabase Auth server — a forged or expired token passes. `getUser()` validates the JWT server-side every time. Skipping Zod means `body.content` could be `undefined` or a 10MB string; the schema bounds both cases before they reach the database.

---

### Example 2: Server action bypassing auth in Next.js

**Before** (triggers the skill):
```typescript
// ❌ Server Action with no auth and trusted client data
'use server';

export async function updateProfileAction(formData: FormData) {
  const userId = formData.get('userId') as string; // client-supplied userId!
  const displayName = formData.get('displayName') as string;
  const bio = formData.get('bio') as string;

  await db.profiles.update({
    where: { id: userId }, // anyone can pass any userId
    data: { displayName, bio }, // no length validation
  });

  revalidatePath('/profile');
  return { success: true };
}
```

**After** (skill-compliant):
```typescript
// ✅ Server Action: auth from session, userId from server, Zod validation
'use server';

import { z } from 'zod';
import { getAuthenticatedUser } from '@/lib/auth';
import { revalidatePath } from 'next/cache';

const updateProfileSchema = z.object({
  displayName: z.string().min(1).max(50),
  bio: z.string().max(300).optional(),
});

export async function updateProfileAction(formData: FormData) {
  // Auth — userId comes from the server, never the form
  const { user } = await getAuthenticatedUser();
  if (!user) return { error: { _form: ['Not authenticated'] } };

  const result = updateProfileSchema.safeParse({
    displayName: formData.get('displayName'),
    bio: formData.get('bio') ?? undefined,
  });

  if (!result.success) {
    return { error: result.error.flatten().fieldErrors };
  }

  try {
    await db.profiles.update({
      where: { id: user.id }, // userId from verified session
      data: result.data,
    });
    revalidatePath('/profile');
    return { success: true };
  } catch (err) {
    console.error('[updateProfileAction]', err);
    return { error: { _form: ['Failed to update profile. Please try again.'] } };
  }
}
```

**Why:** Trusting `userId` from `formData` means any user can update any other user's profile by manipulating the form payload. Server Actions run on the server but receive all input from the client — they are NOT inherently trusted. `userId` must always come from the server-side auth session.

---

### Example 3: Missing rate-limit headers and error detail leak

**Before** (triggers the skill):
```typescript
// ❌ Generic error exposed to client, no rate-limit headers, no structured errors
export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { data, error } = await supabase.auth.signInWithPassword({
      email: body.email,
      password: body.password,
    });
    if (error) throw error; // throws Supabase error with internal details
    return Response.json({ token: data.session?.access_token });
  } catch (err) {
    // leaks: "AuthApiError: Invalid login credentials (status: 400)"
    return Response.json({ error: (err as Error).message }, { status: 500 });
  }
}
```

**After** (skill-compliant):
```typescript
// ✅ Rate-limited, structured errors, no internal detail leak
import { authRatelimit, getClientIp } from '@/lib/ratelimit';

const signInSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

export async function POST(request: Request) {
  // Auth endpoints get strictest rate limiting (5 per minute)
  const ip = getClientIp(request);
  const { success, limit, remaining, reset } = await authRatelimit.limit(ip);
  if (!success) {
    return Response.json({ error: { code: 'RATE_LIMITED', message: 'Too many login attempts' } }, {
      status: 429,
      headers: {
        'X-RateLimit-Limit': String(limit),
        'X-RateLimit-Remaining': String(remaining),
        'X-RateLimit-Reset': new Date(reset).toISOString(),
        'Retry-After': String(Math.ceil((reset - Date.now()) / 1000)),
      },
    });
  }

  const result = signInSchema.safeParse(await request.json().catch(() => ({})));
  if (!result.success) {
    return Response.json({ error: { code: 'VALIDATION_FAILED',
      message: 'Invalid credentials format' } }, { status: 422 });
  }

  const { data, error } = await supabase.auth.signInWithPassword(result.data);

  if (error) {
    // Log internal details — return generic message to client
    console.error('[POST /auth/sign-in] supabase auth error', { code: error.status });
    // Use same response for wrong email and wrong password — no enumeration
    return Response.json({ error: { code: 'INVALID_CREDENTIALS',
      message: 'Email or password is incorrect' } }, { status: 401 });
  }

  return Response.json({ data: { accessToken: data.session?.access_token } });
}
```

**Why:** Leaking the raw Supabase error message tells attackers whether an email exists in the system (user enumeration). Returning identical `INVALID_CREDENTIALS` responses for both cases prevents enumeration. Rate limiting on auth endpoints stops credential stuffing — without it, an attacker can try millions of passwords per day.
