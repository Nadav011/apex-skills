# code-review-checklist — Real-World Examples

The skill provides a structured checklist for PR reviews. Each example shows a category of issue that reviewers frequently miss and the correct fix.

## Before / After

### Example 1: Missing ownership check (Broken Access Control)

**Before** (triggers the skill):
```typescript
// ❌ Auth check present, but no ownership verification — IDOR vulnerability
// Any authenticated user can update any other user's profile
export async function PATCH(
  req: Request,
  { params }: { params: { id: string } },
) {
  const session = await getServerSession();
  if (!session) return new Response('Unauthorized', { status: 401 });

  const body = await req.json();
  const user = await prisma.user.update({
    where: { id: params.id },   // ← params.id is not verified against session
    data: body,
  });
  return Response.json(user);
}
```

**After** (skill-compliant):
```typescript
// ✅ Ownership check ensures you can only update your own profile
export async function PATCH(
  req: Request,
  { params }: { params: { id: string } },
) {
  const session = await getServerSession();
  if (!session) return new Response('Unauthorized', { status: 401 });
  if (session.user.id !== params.id) {
    return new Response('Forbidden', { status: 403 });
  }

  const body = UpdateProfileSchema.parse(await req.json());
  const user = await prisma.user.update({
    where: { id: params.id },
    data: body,
    select: { id: true, name: true, email: true },
  });
  return Response.json(user);
}
```

**Why:** Authenticating a request (proving who you are) is not the same as authorizing it (proving you're allowed to touch this resource). An IDOR (Insecure Direct Object Reference) lets any logged-in user mutate any other user's data by changing the URL parameter.

---

### Example 2: Unbounded collection endpoint

**Before** (triggers the skill):
```typescript
// ❌ No pagination — returns entire table; catastrophic at scale
export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const search = searchParams.get('q') ?? '';

  const products = await prisma.product.findMany({
    where: { name: { contains: search } },
  });

  return Response.json(products); // could be 100,000 rows
}
```

**After** (skill-compliant):
```typescript
// ✅ Cursor pagination with enforced limit
export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const search = searchParams.get('q') ?? '';
  const cursor = searchParams.get('cursor') ?? undefined;
  const limit = Math.min(Number(searchParams.get('limit') ?? 20), 100);

  const products = await prisma.product.findMany({
    where: { name: { contains: search, mode: 'insensitive' } },
    take: limit + 1,
    ...(cursor && { cursor: { id: cursor }, skip: 1 }),
    orderBy: { createdAt: 'desc' },
    select: { id: true, name: true, price: true, imageUrl: true },
  });

  const hasMore = products.length > limit;
  return Response.json({
    data: hasMore ? products.slice(0, limit) : products,
    nextCursor: hasMore ? products[limit - 1]?.id : null,
  });
}
```

**Why:** Without pagination, a single request can read and serialize 100,000 rows, exhaust server memory, and time out. The limit cap prevents clients from requesting arbitrarily large pages even if they specify `limit=999999`.

---

### Example 3: Test asserting implementation, not behavior

**Before** (triggers the skill):
```typescript
// ❌ Tests that the mock was called — not that the user sees correct output
import { vi } from 'vitest';
import * as emailService from '@/lib/email';
import { registerUser } from '@/lib/auth';

it('sends a welcome email on registration', async () => {
  const spy = vi.spyOn(emailService, 'sendEmail');
  await registerUser({ email: 'test@example.com', password: 'hunter2' });
  expect(spy).toHaveBeenCalledTimes(1);
  // Does not verify: what address? what subject? was the user actually created?
});
```

**After** (skill-compliant):
```typescript
// ✅ Tests observable outcomes — user created, email delivered to correct address
import { http, HttpResponse } from 'msw';
import { server } from '@/tests/msw-server';
import { registerUser } from '@/lib/auth';
import { db } from '@/lib/db';

it('creates a user and sends a welcome email to the registered address', async () => {
  const capturedEmails: string[] = [];

  server.use(
    http.post('https://api.resend.com/emails', async ({ request }) => {
      const body = await request.json() as { to: string };
      capturedEmails.push(body.to);
      return HttpResponse.json({ id: 'email_123' });
    }),
  );

  await registerUser({ email: 'new@example.com', password: 'hunter2' });

  const user = await db.user.findUnique({ where: { email: 'new@example.com' } });
  expect(user).not.toBeNull();
  expect(user?.passwordHash).not.toBe('hunter2');       // stored as hash
  expect(capturedEmails).toContain('new@example.com');  // email went to the right address
});
```

**Why:** A spy-only test passes even if the function sends the email to the wrong address, sends it twice, or creates the user with a plaintext password. Testing observable outcomes makes the test meaningful and resilient to refactoring.
