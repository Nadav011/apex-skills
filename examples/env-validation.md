# env-validation — Real-World Examples

The skill enforces validated, typed environment variable access: never raw `process.env`, Zod schema at startup, fail-fast on missing variables, and `.env.example` committed while `.env.local` is gitignored.

## Before / After

### Example 1: Raw process.env scattered across the codebase

**Before** (triggers the skill):
```typescript
// ❌ Raw process.env — wrong types, undefined at runtime, no discoverability
// lib/stripe.ts
import Stripe from 'stripe';
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!); // ! hides undefined

// lib/db.ts
export const pool = new Pool({
  connectionString: process.env.DATABASE_URL,          // possibly undefined
  max: parseInt(process.env.DB_POOL_SIZE || '10'),     // NaN if set to "ten"
});

// app/api/webhook/route.ts
const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET as string; // cast masks undefined
```

**After** (skill-compliant):
```typescript
// ✅ Validated once at module load — all other files import from here
// lib/env.ts
import { z } from 'zod';

const schema = z.object({
  DATABASE_URL:           z.string().url(),
  STRIPE_SECRET_KEY:      z.string().startsWith('sk_'),
  STRIPE_WEBHOOK_SECRET:  z.string().startsWith('whsec_'),
  NEXT_PUBLIC_APP_URL:    z.string().url(),
  DB_POOL_SIZE:           z.coerce.number().int().min(1).max(100).default(10),
  NODE_ENV:               z.enum(['development', 'test', 'production']).default('development'),
});

export const env = schema.parse(process.env);
// Missing or wrong-type variable → throws at startup with a clear error,
// not 3 hours into a deploy when a code path is first reached.

// lib/stripe.ts
import { env } from '@/lib/env';
const stripe = new Stripe(env.STRIPE_SECRET_KEY); // string — guaranteed

// lib/db.ts
export const pool = new Pool({
  connectionString: env.DATABASE_URL, // string URL — guaranteed
  max: env.DB_POOL_SIZE,              // number — guaranteed, not NaN
});
```

**Why:** `process.env.X` returns `string | undefined` in TypeScript, but `!` and `as string` suppress the warning without adding any runtime check. The error manifests as a cryptic `Cannot read properties of undefined` deep in a library, not as a clear startup failure. `schema.parse(process.env)` throws immediately with a message listing every missing or malformed variable.

---

### Example 2: Next.js NEXT_PUBLIC_ prefix confusion leaking server secrets

**Before** (triggers the skill):
```typescript
// ❌ Server secrets accessible on client, public vars undefined server-side
// lib/env.ts (broken)
export const config = {
  supabaseUrl:    process.env.SUPABASE_URL,         // undefined in browser
  supabaseAnonKey: process.env.SUPABASE_ANON_KEY,  // undefined in browser
  apiSecret:      process.env.API_SECRET,           // exposed if prefixed!
};

// components/LoginButton.tsx ('use client')
import { config } from '@/lib/env';
const supabase = createBrowserClient(config.supabaseUrl!, config.supabaseKey!);
// ↑ silently undefined — user sees blank login page with no error
```

**After** (skill-compliant):
```typescript
// ✅ t3-env: enforced server/client split, TypeScript error on wrong-side access
// lib/env.ts
import { createEnv } from '@t3-oss/env-nextjs';
import { z } from 'zod';

export const env = createEnv({
  server: {
    DATABASE_URL:               z.string().url(),
    SUPABASE_SERVICE_ROLE_KEY:  z.string().min(1), // admin — server only
    API_SECRET:                 z.string().min(32),
  },
  client: {
    NEXT_PUBLIC_SUPABASE_URL:       z.string().url(),
    NEXT_PUBLIC_SUPABASE_ANON_KEY:  z.string().min(1),
    NEXT_PUBLIC_APP_URL:            z.string().url(),
  },
  runtimeEnv: {
    DATABASE_URL:               process.env.DATABASE_URL,
    SUPABASE_SERVICE_ROLE_KEY:  process.env.SUPABASE_SERVICE_ROLE_KEY,
    API_SECRET:                 process.env.API_SECRET,
    NEXT_PUBLIC_SUPABASE_URL:   process.env.NEXT_PUBLIC_SUPABASE_URL,
    NEXT_PUBLIC_SUPABASE_ANON_KEY: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
    NEXT_PUBLIC_APP_URL:        process.env.NEXT_PUBLIC_APP_URL,
  },
});

// components/LoginButton.tsx ('use client')
import { env } from '@/lib/env';
// env.DATABASE_URL          → TypeScript ERROR: not available on client ✅
// env.NEXT_PUBLIC_SUPABASE_URL → string, safe ✅
const supabase = createBrowserClient(
  env.NEXT_PUBLIC_SUPABASE_URL,
  env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
);
```

**Why:** Next.js only inlines `NEXT_PUBLIC_*` variables into the browser bundle. Accessing a server-only variable in a client component silently returns `undefined` with no compile-time warning — unless you use `t3-env`, which makes it a TypeScript error. It also guards against accidentally adding `NEXT_PUBLIC_` to `API_SECRET` and shipping it to every browser.

---

### Example 3: Missing .env.example and no CI validation gate

**Before** (triggers the skill):
```bash
# ❌ No .env.example — new developers get cryptic runtime crashes
# No CI validation — missing secrets discovered at deploy time

# New developer experience:
# 1. git clone && pnpm install && pnpm dev
# 2. TypeError: Cannot read properties of undefined (reading 'split')
#    at Pool (/node_modules/pg/lib/pool.js:38)
# 3. Two hours of debugging to discover DATABASE_URL is required
# 4. Find out by reading source code, not documentation
```

**After** (skill-compliant):
```bash
# ✅ .env.example — committed, documents every required variable
# .env.example
DATABASE_URL=postgresql://localhost:5432/myapp_dev
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
SUPABASE_SERVICE_ROLE_KEY=eyJ...
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
NEXT_PUBLIC_APP_URL=http://localhost:3000
DB_POOL_SIZE=10
NODE_ENV=development
```

```gitignore
# .gitignore — real values never committed
.env
.env.local
.env.*.local
*.env
```

```yaml
# .github/workflows/ci.yml — validate env before build
- name: Validate environment variables
  run: node -e "require('./src/lib/env')"
  env:
    DATABASE_URL: ${{ secrets.DATABASE_URL }}
    STRIPE_SECRET_KEY: ${{ secrets.STRIPE_SECRET_KEY }}
    STRIPE_WEBHOOK_SECRET: ${{ secrets.STRIPE_WEBHOOK_SECRET }}
    SUPABASE_SERVICE_ROLE_KEY: ${{ secrets.SUPABASE_SERVICE_ROLE_KEY }}
    NEXT_PUBLIC_SUPABASE_URL: ${{ vars.NEXT_PUBLIC_SUPABASE_URL }}
    NEXT_PUBLIC_SUPABASE_ANON_KEY: ${{ vars.NEXT_PUBLIC_SUPABASE_ANON_KEY }}
    NEXT_PUBLIC_APP_URL: ${{ vars.NEXT_PUBLIC_APP_URL }}
```

**Why:** `.env.example` is the contract between the codebase and its operators. Without it, adding a new required variable silently breaks every developer setup, staging environment, and production deploy until someone reads the error and traces it back to the missing variable. The CI step `node -e "require('./src/lib/env')"` runs the Zod parse in the pipeline — a missing GitHub secret fails the build before any Docker image is built or deployed.
