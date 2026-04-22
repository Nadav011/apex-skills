# commit — Real-World Examples

The skill runs the OMEGA flow before every commit: purge artifacts, run all 8
verification gates, stage atomically, scan for secrets, and enforce Conventional
Commits format. The before/after gap is the difference between a commit that
poisons the history and one that every teammate can trust.

## Before / After

### Example 1: Vague message, `git add .`, secret accidentally staged

**Before** (triggers the skill):
```bash
# ❌ Staged everything including an .env file
# ❌ Commit message gives no information about what changed or why
# ❌ Live API keys about to be pushed to the remote

git add .
git commit -m "fixes"
git push origin main
```

What was actually staged (the danger inside `git add .`):
```diff
# .env (should never be committed)
+STRIPE_SECRET_KEY=sk_live_<redacted-rotate-immediately>
+OPENAI_API_KEY=sk-proj-<redacted-rotate-immediately>

# src/lib/payment.ts
+async function charge(amount: number) {
+  if (!amount) return; // forgot to handle negative amounts
```

**After** (skill-compliant):
```bash
# Step 1: PURGE — clear stale artifacts
rm -rf .next node_modules/.cache

# Step 2: AUDIT — all gates must pass
pnpm typecheck && pnpm lint && pnpm test --run

# Step 3: ATOMIC — stage only the files related to this change
git add src/lib/payment.ts src/lib/payment.test.ts

# Step 4: SECURITY — scan staged diff for secrets before committing
git diff --cached | grep -E \
  "(sk-[a-zA-Z0-9]{20,}|pk_live_[a-zA-Z0-9]+|AKIA[0-9A-Z]{16})" \
  && echo "SECRET DETECTED — abort" && exit 1 \
  || echo "Secret scan: clean"

# Step 5: RELEASE — Conventional Commits with imperative description
git commit -m "fix(payment): reject negative and zero charge amounts

Previously, passing amount=0 silently created a zero-value charge which
Stripe accepted but our ledger treated as an error. Added guard at entry
point and covered with unit tests for 0, negative, and NaN inputs."
```

**Why:** `git add .` staged `.env` with live API keys — one `git push` and the
secrets are in the remote forever (rotation required even after deletion from
history). The message `"fixes"` tells a future reader nothing about what broke,
why, or how it was fixed. Atomic staging makes `git bisect` and `git revert`
reliable.

---

### Example 2: Wrong commit type, missing scope, mixed concerns in one commit

**Before** (triggers the skill):
```bash
# ❌ "update" is not a valid Conventional Commits type
# ❌ No scope — impossible to know which subsystem changed
# ❌ Two unrelated concerns (auth refactor + button style) in one commit

git add .
git commit -m "update auth and fix button"
```

Resulting commit contains:
- Refactored `src/lib/auth/session.ts` (session token rotation logic)
- Updated `src/components/ui/Button.tsx` (changed border radius)
- Modified `tailwind.config.ts` (new color token)

**After** (skill-compliant):
```bash
# Split into two atomic commits — each answers "what is undone if I revert this?"

# Commit 1: the auth change
git add src/lib/auth/session.ts src/lib/auth/session.test.ts
git commit -m "refactor(auth): rotate session token on privilege escalation

Session tokens were not rotated when a user's role changed from 'user' to
'admin'. An existing session with the old low-privilege token could be
reused. Token is now invalidated and re-issued on any role change.

Refs: APEX-421"

# Commit 2: the UI change (separate concern, separate commit)
git add src/components/ui/Button.tsx tailwind.config.ts
git commit -m "chore(ui): apply 8pt grid to Button border radius

Border radius was using an arbitrary 6px value outside the design system.
Aligned to 8pt grid (rounded-md = 6px → rounded-lg = 8px) per Figma spec."
```

**Why:** Mixed commits make code review harder (reviewer must mentally separate
unrelated changes) and make `git bisect` unreliable. Valid Conventional Commits
types (`refactor`, `chore`, `feat`, `fix`, `perf`, `docs`, `test`, `ci`,
`revert`) tell automated tooling how to bump the version and generate the
changelog.

---

### Example 3: Pushing directly to `main`, skipping hooks with `--no-verify`

**Before** (triggers the skill):
```bash
# ❌ Pushed directly to main — bypasses all branch protection and PR review
# ❌ --no-verify skipped pre-commit hooks (typecheck, lint, secret scan bypassed)
# ❌ No review of what was actually being pushed

git commit --no-verify -m "hotfix"
git push origin main
```

**After** (skill-compliant):
```bash
# Step 1: Create a branch — never commit directly to main
git checkout -b fix/payment-timeout-on-slow-connections

# Step 2: Run all gates explicitly (hooks run these too, verify manually first)
pnpm typecheck   # 0 errors required
pnpm lint        # 0 errors required
pnpm test --run  # 0 failures required

# Step 3: Review exactly what you are about to push
git log origin/main..HEAD --oneline
# → fix: increase payment API timeout for slow mobile connections

git diff origin/main...HEAD --stat
# → src/lib/payment.ts    |  3 +-
# → src/lib/payment.test.ts | 18 +++++++++++++++++-

# Step 4: Push the feature branch and open a PR
git push -u origin fix/payment-timeout-on-slow-connections

gh pr create \
  --title "fix(payment): increase API timeout for slow mobile connections" \
  --body "$(cat <<'EOF'
## Summary
- Increase payment API timeout from 5s to 15s to accommodate 3G mobile users
- Add test asserting the timeout value is read from environment config

## Why
Support reported 12% of mobile users hitting timeout errors during checkout.
P95 latency on mobile is 11s; the 5s limit was too aggressive.

## Test plan
- [x] Unit tests added for timeout configuration
- [x] Tested locally on throttled (3G) network in Chrome DevTools
- [x] typecheck: 0 errors
- [x] lint: 0 errors
- [x] tests: all pass
EOF
)" \
  --base main
```

**Why:** `--no-verify` disables every pre-commit hook — typecheck, lint, RTL
scan, and secret scan all run inside hooks. Bypassing them is how secrets ship
to production. Pushing directly to `main` skips code review, which is both an
OWASP A01 (access control) risk and a team workflow failure. Branch + PR ensures
every change is reviewed before it lands.
