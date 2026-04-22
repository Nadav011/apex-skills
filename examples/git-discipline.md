# git-discipline — Real-World Examples

The skill enforces Git hygiene: conventional commit format, branch naming, no direct pushes to main, meaningful PR descriptions, and clean staged diffs before commit.

## Before / After

### Example 1: Meaningless commit messages

**Before** (triggers the skill):
```bash
# ❌ Commit messages that carry zero information
git commit -m "fix stuff"
git commit -m "WIP"
git commit -m "updates"
git commit -m "asdfgh"
git commit -m "final"
git commit -m "final 2"
git commit -m "PLEASE WORK"

# git log --oneline output:
# a1b2c3d PLEASE WORK
# e4f5g6h final 2
# i7j8k9l final
# m0n1o2p asdfgh
# q3r4s5t updates
# Completely useless — impossible to bisect, understand history, or write CHANGELOG
```

**After** (skill-compliant):
```bash
# ✅ Conventional commits — self-documenting history, enables automated CHANGELOG
git commit -m "fix(checkout): correct VAT calculation for EU customers

Previously the 17% VAT was applied before the coupon discount,
resulting in a higher total than displayed. VAT now applies to the
post-discount subtotal.

Closes #342"

git commit -m "feat(auth): add Google OAuth alongside email/password login"
git commit -m "chore(deps): upgrade Next.js 15.2.4 → 16.1.0"
git commit -m "refactor(db): extract query builder into repository pattern"
git commit -m "test(payment): add edge cases for declined card responses"
git commit -m "perf(images): switch product thumbnails to next/image with WebP"

# git log --oneline output:
# a1b2c3d perf(images): switch product thumbnails to next/image with WebP
# e4f5g6h test(payment): add edge cases for declined card responses
# i7j8k9l refactor(db): extract query builder into repository pattern
# Each commit tells you exactly what changed and why
```

**Why:** `git log` and `git bisect` are your debugging tools when production breaks at 2 AM. "PLEASE WORK" tells you nothing. Conventional commits let tools auto-generate CHANGELOGs, enable `git bisect` to pinpoint when a bug was introduced, and give reviewers context in GitHub's PR timeline. The format `type(scope): description` is under 72 characters, imperative mood, no period.

---

### Example 2: Pushing directly to main with debug code

**Before** (triggers the skill):
```bash
# ❌ Committed directly to main with debug artifacts
git add .   # stages everything including .env.local, console.logs, commented-out code
git commit -m "add user auth"
git push origin main  # BLOCKED by hook: never push directly to main

# Staged diff included:
# + console.log('DEBUG token:', token); // leaks JWT in logs
# + // TODO: remove this before merge
# + const DEBUG_USER = { id: 'test123', role: 'admin' }; // debug bypass
# + API_KEY=sk-ant-api03-real-key-here  (from accidentally staged .env.local)
```

**After** (skill-compliant):
```bash
# ✅ Feature branch, clean diff review before commit
git checkout -b feat/user-authentication

# Review EVERY line before staging
git diff  # read full diff

# Stage selectively — not git add .
git add src/lib/auth.ts src/app/login/page.tsx src/components/AuthButton.tsx

# Verify staged diff
git diff --staged
# Confirm: no console.log, no API keys, no TODO/FIXME, no commented-out blocks

git commit -m "feat(auth): add email/password authentication with Supabase

- createServerClient setup with cookie-based session
- Login page with Zod-validated form
- getUser() helper for server-side auth verification
- AuthButton client component with loading state"

git push -u origin feat/user-authentication
# Then open PR via GitHub or gh pr create
```

**Why:** `git add .` is a landmine — it stages everything in the working tree including `.env.local`, build artifacts, and debug code. A `console.log('DEBUG token:', token)` in production logs leaks JWTs to anyone with log access. The pre-commit checklist (`git diff --staged`) is the last safety net before code is permanent in history.

---

### Example 3: PR with no description leaving reviewers blind

**Before** (triggers the skill):
```markdown
# ❌ PR with no context — reviewer cannot evaluate correctness or test it
Title: fix bug

Description:
(empty)

Files changed: 47 files, +892 −156 lines
```

**After** (skill-compliant):
```markdown
# ✅ PR with full context — reviewable without reading every line of code
Title: fix(checkout): correct tax calculation order for coupon + VAT

## Summary
- VAT was applied before coupon discount, resulting in higher totals than shown
- Fix: apply coupon first, then calculate VAT on the discounted subtotal
- Affected: all EU checkout flows with active coupons

## Root Cause
`calculateOrderTotal()` in `lib/pricing.ts` was applying `tax = subtotal * 0.17`
before `discount = subtotal * coupon.rate`. The displayed price used the correct
order; the actual charge used the wrong order.

## Test Plan
- [ ] Checkout with 20% coupon + 17% VAT — verify total = (subtotal × 0.8) × 1.17
- [ ] Checkout without coupon — verify total unchanged
- [ ] Checkout with 100% coupon — verify total = 0 (not negative)
- [ ] VAT receipt line items show correct values

## Breaking Changes
None — same API, same response shape.

## Related
Closes #342 | Ref #289 (original tax calculation PR)
```

**Why:** An empty PR description means the reviewer must read every changed line cold, with no idea what problem is being solved or how to verify the fix works. A well-structured PR description lets the reviewer assess correctness without context-switching to Jira, understand the root cause, and follow a test plan — reducing review time from 45 minutes to 10.
