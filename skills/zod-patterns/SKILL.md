---
name: zod-patterns
description: Zod 4 validation patterns for TypeScript — schemas, transforms, refinements, error handling
trigger: /zod-patterns
---

# Zod 4 Patterns

This skill provides Zod 4 validation patterns. References the full guide at:
`~/.claude/skills/references/rules/validation/zod.md`

## Quick Reference

### Schema Definition
```typescript
import { z } from 'zod';

// Basic types
const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  role: z.enum(['user', 'admin', 'manager']),
  createdAt: z.string().datetime(),
});

type User = z.infer<typeof UserSchema>;
```

### Validation at Boundaries
Always validate at system boundaries (API endpoints, form submissions, external data):
```typescript
const result = UserSchema.safeParse(unknownData);
if (!result.success) {
  // result.error.issues contains details
  return { error: result.error.flatten() };
}
const user = result.data; // fully typed
```

### Transform & Refine
```typescript
const AmountSchema = z.string()
  .transform(val => parseFloat(val))
  .refine(n => !isNaN(n) && n > 0, 'Must be positive number');

const PasswordSchema = z.string()
  .min(8, 'Min 8 characters')
  .regex(/[A-Z]/, 'Must contain uppercase')
  .regex(/[0-9]/, 'Must contain number');
```

### Result Pattern (Law #1 — Zero Trust)
```typescript
import { z } from 'zod';

type Result<T, E = Error> =
  | { ok: true; data: T }
  | { ok: false; error: E };

async function validateAndProcess<T>(
  schema: z.ZodType<T>,
  data: unknown
): Promise<Result<T>> {
  const parsed = schema.safeParse(data);
  if (!parsed.success) {
    return { ok: false, error: new Error(parsed.error.message) };
  }
  return { ok: true, data: parsed.data };
}
```

### Environment Variables
```typescript
const EnvSchema = z.object({
  DATABASE_URL: z.string().url(),
  API_KEY: z.string().min(1),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
});

export const env = EnvSchema.parse(process.env); // Fail-fast in production
```

**Full reference:** `~/.claude/skills/references/rules/validation/zod.md`
