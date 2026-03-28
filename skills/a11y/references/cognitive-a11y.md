# Cognitive Accessibility (COGA) Patterns

> **v24.6.0** | W3C COGA Supplemental Guidance | WCAG 2.2 Mapped Criteria
> RTL-FIRST: `ms-`/`me-`/`ps-`/`pe-`/`inset-s-`/`inset-e-` — never `ml-`/`mr-`/`left-`/`right-`

---

## COGA Overview

COGA = Cognitive and Learning Disabilities Accessibility Task Force (W3C).
Covers: attention, memory, executive function, language/literacy, math, mental health conditions, autism spectrum, acquired disabilities (TBI, stroke).

**W3C Supplemental Guidance:** Extends WCAG 2.2 — not normative requirements, but best practice.

### Core Principles

| Principle | Description | WCAG Mapping |
|-----------|-------------|-------------|
| Clear language | Plain, simple text at lower secondary reading level | 3.1.5 Reading Level (AAA) |
| Consistent UI | Same nav, same patterns across pages | 3.2.3 Consistent Nav (AA), 3.2.6 Consistent Help (A) |
| Error prevention | Confirm/reverse/check before submission | 3.3.4 Error Prevention (AA) |
| Minimal memory load | Auto-populate, no redundant entry | 3.3.7 Redundant Entry (A) |
| Predictable behavior | No unexpected context changes | 3.2.1/3.2.2 (A) |
| Accessible authentication | No cognitive tests; allow copy-paste | 3.3.8 (AA), 3.3.9 (AAA) |
| Timing flexibility | Warn before timeout, allow extension | 2.2.1 Timing Adjustable (A) |

---

## Mapped WCAG 2.2 Criteria

### 2.2.1 Timing Adjustable (Level A)

Users must be able to: turn off, adjust, or extend time limits.
Exception: 20-hour timeout (session management) is exempt.

```tsx
// Timeout warning component — warns 2 minutes before expiry
function SessionTimeoutWarning({ expiresAt }: { expiresAt: Date }) {
  const [showWarning, setShowWarning] = React.useState(false);
  const WARNING_MS = 2 * 60 * 1000; // 2 minutes

  React.useEffect(() => {
    const msUntilWarning = expiresAt.getTime() - Date.now() - WARNING_MS;
    if (msUntilWarning <= 0) return;

    const timer = setTimeout(() => setShowWarning(true), msUntilWarning);
    return () => clearTimeout(timer);
  }, [expiresAt]);

  if (!showWarning) return null;

  return (
    <dialog
      open
      role="alertdialog"
      aria-labelledby="timeout-title"
      aria-describedby="timeout-desc"
    >
      <h2 id="timeout-title">Session expiring soon</h2>
      <p id="timeout-desc">
        Your session will expire in 2 minutes. Would you like to continue?
      </p>
      <div className="flex gap-4 mt-6">
        <button
          autoFocus
          onClick={() => { extendSession(); setShowWarning(false); }}
          className="min-h-11 min-w-11 px-4"
        >
          Continue session
        </button>
        <button
          onClick={() => signOut()}
          className="min-h-11 min-w-11 px-4"
        >
          Sign out now
        </button>
      </div>
    </dialog>
  );
}
```

### 3.1.5 Reading Level (Level AAA)

Content must be understandable at lower secondary education level (approximately age 12–14, Flesch-Kincaid Grade ≤8) or a supplemental simpler version must be provided.

```typescript
// Flesch-Kincaid Grade Level calculation (server-side)
function fleschKincaidGrade(text: string): number {
  const sentences = text.split(/[.!?]+/).filter(Boolean).length;
  const words = text.split(/\s+/).filter(Boolean).length;
  const syllables = text
    .toLowerCase()
    .split(/\s+/)
    .reduce((sum, word) => sum + countSyllables(word), 0);

  if (sentences === 0 || words === 0) return 0;
  return 0.39 * (words / sentences) + 11.8 * (syllables / words) - 15.59;
}

// Grade <= 8 recommended for WCAG 3.1.5
```

### 3.2.3 Consistent Navigation (Level AA)

Navigation in the same relative order across pages. MUST NOT reorder nav items based on current page.

```tsx
// Consistent nav — use static order, never sort by "relevance" per page
const NAV_ITEMS = [
  { href: '/', label: 'Home' },
  { href: '/menu', label: 'Menu' },
  { href: '/orders', label: 'Orders' },
  { href: '/account', label: 'Account' },
] as const;

// WRONG: filtering or sorting nav items based on current route
// RIGHT: always render same items in same order
function MainNav() {
  return (
    <nav aria-label="Main navigation">
      <ul role="list" className="flex gap-4">
        {NAV_ITEMS.map((item) => (
          <li key={item.href}>
            <a href={item.href} className="min-h-11 min-w-11 flex items-center px-3">
              {item.label}
            </a>
          </li>
        ))}
      </ul>
    </nav>
  );
}
```

### 3.3.4 Error Prevention (Level AA)

For legal, financial, data-deleting, or test submissions: reversible, checked, or confirmed.

```tsx
// Confirmation dialog for destructive actions
function DeleteOrderButton({ orderId }: { orderId: string }) {
  const [confirming, setConfirming] = React.useState(false);
  const dialogRef = React.useRef<HTMLDialogElement>(null);

  function openConfirmation() {
    setConfirming(true);
    dialogRef.current?.showModal();
  }

  function handleConfirm() {
    deleteOrder(orderId);
    dialogRef.current?.close();
    setConfirming(false);
  }

  return (
    <>
      <button
        onClick={openConfirmation}
        className="min-h-11 min-w-11"
        aria-haspopup="dialog"
      >
        Delete order
      </button>
      <dialog
        ref={dialogRef}
        aria-labelledby="delete-title"
        aria-describedby="delete-desc"
        onClose={() => setConfirming(false)}
      >
        <h2 id="delete-title">Delete this order?</h2>
        <p id="delete-desc">This action cannot be undone.</p>
        <div className="flex gap-4 mt-6">
          <button autoFocus onClick={() => dialogRef.current?.close()} className="min-h-11 min-w-11 px-4">
            Cancel
          </button>
          <button onClick={handleConfirm} className="min-h-11 min-w-11 px-4">
            Delete
          </button>
        </div>
      </dialog>
    </>
  );
}
```

### 3.3.7 Redundant Entry (Level A)

Auto-populate information already entered in the same session. Do not make users re-type the same data.

```tsx
// Auto-populate shipping from billing address
function CheckoutForm() {
  const [billing, setBilling] = React.useState({ name: '', address: '' });
  const [shipping, setShipping] = React.useState({ name: '', address: '' });
  const [sameAsBilling, setSameAsBilling] = React.useState(false);

  function handleSameAsBilling(checked: boolean) {
    setSameAsBilling(checked);
    if (checked) {
      // 3.3.7 — auto-populate to prevent redundant entry
      setShipping({ name: billing.name, address: billing.address });
    }
  }

  return (
    <form>
      <fieldset>
        <legend>Billing address</legend>
        <input
          value={billing.name}
          onChange={(e) => setBilling((b) => ({ ...b, name: e.target.value }))}
          aria-label="Billing name"
          className="min-h-11"
        />
      </fieldset>
      <fieldset>
        <legend>Shipping address</legend>
        <label className="flex items-center gap-3">
          <input
            type="checkbox"
            checked={sameAsBilling}
            onChange={(e) => handleSameAsBilling(e.target.checked)}
            className="min-h-5 min-w-5"
          />
          Same as billing address
        </label>
        <input
          value={shipping.name}
          onChange={(e) => setShipping((s) => ({ ...s, name: e.target.value }))}
          disabled={sameAsBilling}
          aria-label="Shipping name"
          className="min-h-11"
        />
      </fieldset>
    </form>
  );
}
```

### 3.3.8 / 3.3.9 Accessible Authentication (AA / AAA)

- **3.3.8 (AA):** No cognitive function tests in auth — allow copy-paste, password managers, object recognition OK.
- **3.3.9 (AAA):** No cognitive function tests at all — no object recognition, no image selection either.

```tsx
// WRONG: Blocking paste prevents password managers (fails 3.3.8)
<input type="password" onPaste={(e) => e.preventDefault()} />

// RIGHT: Allow paste, allow autocomplete
<input
  type="password"
  name="password"
  autoComplete="current-password"  // enables password manager integration
  // No onPaste handler — allow paste
  className="min-h-11"
/>

// For 2FA — allow paste for OTP codes
<input
  type="text"
  inputMode="numeric"
  name="otp"
  autoComplete="one-time-code"
  maxLength={6}
  className="min-h-11"
/>
```

---

## Progressive Disclosure Pattern

Show basic options first. Reveal advanced details on demand. Reduces cognitive load for most users while keeping power-user features accessible.

```tsx
type DisclosureMode = 'simplified' | 'advanced';

function DisclosureToggle() {
  const [mode, setMode] = React.useState<DisclosureMode>('simplified');

  return (
    <div data-a11y-mode={mode}>
      <div className="flex items-center justify-between mb-6">
        <h2 id="settings-title">Settings</h2>
        <button
          onClick={() => setMode((m) => (m === 'simplified' ? 'advanced' : 'simplified'))}
          aria-pressed={mode === 'advanced'}
          aria-label={mode === 'simplified' ? 'Show advanced options' : 'Show simplified view'}
          className="min-h-11 min-w-11 px-4"
        >
          {mode === 'simplified' ? 'Advanced' : 'Simplified'}
        </button>
      </div>

      {/* Always visible */}
      <BasicOptions />

      {/* Progressive disclosure — only rendered when needed */}
      {mode === 'advanced' && (
        <section aria-label="Advanced settings" className="mt-8 border-t pt-6">
          <AdvancedOptions />
        </section>
      )}
    </div>
  );
}
```

---

## Error Recovery with Undo

```tsx
type ToastState =
  | { type: 'idle' }
  | { type: 'success'; message: string; undo?: () => void };

function useUndoableAction() {
  const [toast, setToast] = React.useState<ToastState>({ type: 'idle' });

  function performWithUndo(action: () => void, undoFn: () => void, label: string) {
    action();
    setToast({ type: 'success', message: `${label} completed`, undo: undoFn });
    setTimeout(() => setToast({ type: 'idle' }), 5000);
  }

  return { toast, performWithUndo };
}

// Usage
function OrderCard({ order }: { order: Order }) {
  const { toast, performWithUndo } = useUndoableAction();

  function handleArchive() {
    performWithUndo(
      () => archiveOrder(order.id),
      () => restoreOrder(order.id),
      'Order archived'
    );
  }

  return (
    <>
      <button onClick={handleArchive} className="min-h-11">Archive</button>
      {toast.type === 'success' && (
        <div role="status" aria-live="polite" className="flex items-center gap-4 p-4">
          <span>{toast.message}</span>
          {toast.undo && (
            <button onClick={toast.undo} className="min-h-11 font-semibold underline">
              Undo
            </button>
          )}
        </div>
      )}
    </>
  );
}
```

---

## Readability Testing

| Tool | Method | Output |
|------|--------|--------|
| Hemingway Editor | Paste text at hemingwayapp.com | Highlighted complexity + grade |
| readable.io | API or web | Flesch-Kincaid, Gunning Fog, SMOG |
| textstat (Node) | `npm install textstat` | FK grade, readability score |
| Google Docs | Tools > Word Count > Accessibility | Grade level (US) |

**Target:** Flesch-Kincaid Grade Level ≤ 8 for body copy. Provide summary version if content is inherently complex (legal, medical, financial).

---

## RTL Considerations

All COGA patterns apply identically in RTL. Additional checks:

- Simplified mode toggle must render correctly in RTL — use `ms-`/`me-` for spacing, not `ml-`/`mr-`
- Error messages in Hebrew/Arabic: ensure right-to-left reading order is natural, not translated LTR
- Numbers in error messages: wrap in `<span dir="ltr">` — e.g., `<span dir="ltr">3</span> שגיאות`
- Confirmation dialogs: button order should follow RTL convention (primary action on right = `inset-e-`)
- Auto-populate (3.3.7): works language-agnostic; ensure form field `dir` matches expected input language

```tsx
// RTL-correct error message with numeric count
function ErrorSummary({ errors }: { errors: string[] }) {
  return (
    <div role="alert" aria-live="assertive" className="ps-4 border-s-4 border-red-500">
      <p>
        נמצאו{' '}
        <span dir="ltr">{errors.length}</span>
        {' '}שגיאות. אנא תקנו אותן לפני שתמשיכו.
      </p>
      <ul className="mt-2 space-y-1">
        {errors.map((err, i) => (
          <li key={i}>{err}</li>
        ))}
      </ul>
    </div>
  );
}
```

---

## Cross-References

- Timeout / timing patterns: `~/.claude/skills/a11y/SKILL.md` (2.2.1)
- WCAG 3.0 COGA in new outcomes: `references/wcag3-apca.md`
- Dialog patterns for confirmation: `references/dialog-popover-a11y.md`
- Testing COGA patterns: `references/a11y-testing.md`

---

<!-- COGNITIVE_A11Y v24.6.0 | Updated: 2026-02-24 | COGA W3C Supplemental Guidance | WCAG 2.2 AA/AAA -->
