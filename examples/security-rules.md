# security-rules — Real-World Examples

The skill enforces defense-in-depth security: supply chain integrity, secret management, Supabase RLS patterns, file upload validation, and secure auth (getUser, never getSession alone).

## Before / After

### Example 1: RLS policy with auth.uid() IS NULL bypass

**Before** (triggers the skill):
```sql
-- ❌ IS NULL condition grants full unauthenticated read access
CREATE POLICY "users can read own data"
ON profiles
FOR SELECT
USING (
  (auth.uid()) IS NULL  -- attacker sends request with no token → IS NULL = true
  OR auth.uid() = id    -- legitimate authenticated check
);

-- Attacker makes unauthenticated GET /rest/v1/profiles?select=*
-- IS NULL evaluates to true → returns ALL profiles → full data leak
```

**After** (skill-compliant):
```sql
-- ✅ Strict ownership check — unauthenticated requests get zero rows
CREATE POLICY "users can read own data"
ON profiles
FOR SELECT
TO authenticated  -- role restriction: only authenticated users can evaluate this
USING (
  auth.uid() = id  -- only the owner can read their own row
);

-- Additional admin policy using SECURITY DEFINER helper (avoids auth.users access issue)
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT raw_user_meta_data->>'role'
  FROM auth.users
  WHERE id = auth.uid()
$$;

CREATE POLICY "admins can read all profiles"
ON profiles
FOR SELECT
TO authenticated
USING (
  get_user_role() = 'admin'  -- never inline SELECT FROM auth.users in RLS
);
```

**Why:** `USING ((auth.uid()) IS NULL OR ...)` is a classic bypass: when a request has no JWT, `auth.uid()` returns `NULL`, making `IS NULL` evaluate to `true`, which satisfies the permissive policy — the attacker reads all rows unauthenticated. The `TO authenticated` role restriction is the correct guard. Inline `SELECT FROM auth.users` in RLS policies also fails silently because the `authenticated` role has no SELECT privilege on `auth.users` — always use a `SECURITY DEFINER` helper function.

---

### Example 2: File upload with no size limit or MIME validation

**Before** (triggers the skill):
```typescript
// ❌ No validation on file uploads — DoS and SVG XSS vectors
export async function POST(request: Request) {
  const { user } = await getAuthenticatedUser();
  if (!user) return Response.json({ error: 'Unauthorized' }, { status: 401 });

  const formData = await request.formData();
  const file = formData.get('avatar') as File;

  // No size check — attacker uploads 5 GB file → exhausts storage quota
  // No MIME check — attacker uploads SVG with <script> → XSS via public URL
  const { data, error } = await supabase.storage
    .from('avatars')
    .upload(`${user.id}/avatar`, file);

  if (error) return Response.json({ error: error.message }, { status: 500 });
  return Response.json({ path: data.path });
}
```

**After** (skill-compliant):
```typescript
// ✅ Size + MIME validated server-side; bucket configured with hard limits
const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp'] as const;
const MAX_FILE_SIZE_BYTES = 5 * 1024 * 1024; // 5 MB

export async function POST(request: Request) {
  const { user } = await getAuthenticatedUser();
  if (!user) return Response.json({ error: 'Unauthorized' }, { status: 401 });

  const formData = await request.formData();
  const file = formData.get('avatar');

  if (!(file instanceof File)) {
    return Response.json({ error: 'No file provided' }, { status: 400 });
  }

  // Validate size before reading bytes
  if (file.size > MAX_FILE_SIZE_BYTES) {
    return Response.json({ error: 'File too large (max 5 MB)' }, { status: 413 });
  }

  // Validate MIME type — never trust the client-supplied Content-Type
  const bytes = new Uint8Array(await file.arrayBuffer());
  const detectedMime = detectMimeFromBytes(bytes); // magic byte inspection
  if (!ALLOWED_MIME_TYPES.includes(detectedMime as typeof ALLOWED_MIME_TYPES[number])) {
    return Response.json({ error: 'File type not allowed' }, { status: 415 });
  }

  const { data, error } = await supabase.storage
    .from('avatars')
    .upload(`${user.id}/avatar.${detectedMime.split('/')[1]}`, bytes, {
      contentType: detectedMime,
      upsert: true,
    });

  if (error) {
    logger.error({ err: error, userId: user.id }, 'Avatar upload failed');
    return Response.json({ error: 'Upload failed' }, { status: 500 });
  }
  return Response.json({ path: data.path });
}

// Supabase bucket also configured with hard limits as defense-in-depth:
// file_size_limit: 5242880 (5 MB)
// allowed_mime_types: ['image/jpeg', 'image/png', 'image/webp']
// public: false (use signed URLs, not public access)
```

**Why:** Without MIME validation, an attacker uploads an SVG file containing `<script>alert(document.cookie)</script>`. When served from the same origin or a permissive CDN, the browser executes the script. Without a size limit, a single upload can exhaust the entire storage quota. Magic-byte inspection (`detectMimeFromBytes`) is required because `file.type` is client-supplied and can be spoofed.

---

### Example 3: Service role key exposed and getSession() used for auth

**Before** (triggers the skill):
```typescript
// ❌ Service role key in client bundle + getSession() for auth decisions
// lib/supabase-client.ts — THIS RUNS IN THE BROWSER
import { createClient } from '@supabase/supabase-js';

export const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!, // NEVER expose service role key to client
);

// app/api/admin/route.ts
export async function GET() {
  const { data: { session } } = await supabase.auth.getSession(); // trusts cookie
  if (!session) return Response.json({ error: 'Unauthorized' }, { status: 401 });

  // getSession() trusts the local cookie without server validation
  // An attacker with a forged or expired cookie passes this check
  const users = await supabase.from('users').select('*');
  return Response.json(users);
}
```

**After** (skill-compliant):
```typescript
// ✅ Service role key server-only; getUser() validates JWT with Supabase server
// lib/supabase-browser.ts — safe for client use
import { createBrowserClient } from '@supabase/ssr';
export const supabaseBrowser = () =>
  createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!, // anon key only in browser
  );

// lib/supabase-server.ts — server-only (never imported by client components)
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';

export async function createServerSupabase() {
  const cookieStore = await cookies();
  return createServerClient(
    process.env.SUPABASE_URL!,
    process.env.SUPABASE_ANON_KEY!,
    { cookies: { getAll: () => cookieStore.getAll(),
                  setAll: (c) => c.forEach(({ name, value, options }) =>
                    cookieStore.set(name, value, options)) } }
  );
}

// app/api/admin/route.ts
export async function GET() {
  const supabase = await createServerSupabase();
  // getUser() validates JWT against Supabase Auth server on every call
  const { data: { user }, error } = await supabase.auth.getUser();
  if (!user || error) return Response.json({ error: 'Unauthorized' }, { status: 401 });

  // Authorization: verify admin role
  const { data: profile } = await supabase
    .from('profiles').select('role').eq('id', user.id).single();
  if (profile?.role !== 'admin') {
    return Response.json({ error: 'Forbidden' }, { status: 403 });
  }

  const { data: users } = await supabase.from('users').select('id, email, role');
  return Response.json({ data: users });
}
```

**Why:** The service role key bypasses all RLS policies — anyone who obtains it has unrestricted read/write access to the entire database. Bundling it into a `NEXT_PUBLIC_` variable ships it to every browser via the JavaScript bundle. `getSession()` trusts the local cookie without network validation; a forged or expired JWT passes the check. `getUser()` makes a network call to Supabase Auth to validate the JWT on every request.
