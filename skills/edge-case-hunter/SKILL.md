---
name: edge-case-hunter
description: Exhaustively enumerate code paths and find unhandled edge cases
triggers: [edge cases, edge case hunt, find edge cases, unhandled paths]
---

# /edge-case-hunter — Edge Case Discovery

## Protocol

Given code or a diff, enumerate ALL execution paths systematically:

1. **Happy path** — nominal flow, expected inputs
2. **Error paths** — what can throw, what can fail
3. **Boundary conditions** — off-by-one, min/max values, empty vs single vs many
4. **Concurrent access** — race conditions, shared state, parallel mutations
5. **Null/undefined** — missing fields, optional chaining gaps, uninitialized state
6. **Type coercion** — implicit JS coercion, NaN propagation, string/number confusion
7. **RTL edge cases** — bidirectional text, mixed Hebrew/English, number direction
8. **Numeric overflow** — integer limits, float precision, currency arithmetic
9. **Empty collections** — zero-length arrays, empty maps, null vs empty distinction
10. **Async/await** — unhandled rejections, race conditions, stale closures, cancellation

Must find **at least 10 edge cases** or explicitly explain why fewer exist.

## Format

Output one JSON object per edge case:

```json
{
  "location": "file.ts:42 — functionName()",
  "trigger_condition": "When user.profile is null and role check is called",
  "guard_snippet": "if (!user?.profile?.role) return null;",
  "potential_consequence": "TypeError: Cannot read property 'role' of null — crashes auth middleware",
  "severity": "BLOCKER"
}
```

Severity levels: `BLOCKER` | `CRITICAL` | `MAJOR` | `MINOR`

After the JSON list, provide a **summary table**:

| # | Location | Condition | Severity |
|---|----------|-----------|----------|
| 1 | file:line | brief trigger | BLOCKER |

## Rules

- Minimum 10 edge cases per review or justify why fewer
- Check every function parameter for null/undefined/wrong-type
- Trace async flows end-to-end — find every `await` that can reject silently
- For RTL: check every string that might contain Hebrew, every directional icon, every `left`/`right` CSS value
- For React: check every `useEffect` dependency array, every conditional hook call
- For Supabase: check every RLS policy gap, every missing `.error` check
- Never say "this looks safe" — prove it or flag it
