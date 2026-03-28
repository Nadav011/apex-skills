# Dialog & Popover API Accessibility Patterns

> **v24.6.0** | Native `<dialog>` | Popover API | WAI-ARIA 1.2/1.3
> RTL-FIRST: `ms-`/`me-`/`ps-`/`pe-`/`inset-s-`/`inset-e-` — never `ml-`/`mr-`/`left-`/`right-`

---

## Native `<dialog>` Element

### What showModal() Provides Automatically

| Behavior | Detail |
|----------|--------|
| Background inert | All content outside `<dialog>` removed from tab order and AT tree |
| Auto-focus | First focusable element inside dialog receives focus |
| Focus trap | Tab/Shift+Tab cycles only within dialog |
| Esc to close | Browser handles keydown, fires `close` event |
| Focus return | `close()` returns focus to element that opened the dialog |
| Top layer | Dialog renders above all other content, no z-index needed |
| `aria-modal` | Not required — `showModal()` provides equivalent behavior implicitly |

### Focus Management

```tsx
// Place close button BELOW heading — SR reads heading first, then close button
// autofocus should be on the FIRST meaningful interactive element (usually close button)

function AccessibleDialog({
  isOpen,
  onClose,
  title,
  children,
  triggerId,
}: {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  children: React.ReactNode;
  triggerId: string;
}) {
  const dialogRef = React.useRef<HTMLDialogElement>(null);

  React.useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;

    if (isOpen) {
      dialog.showModal();
    } else if (dialog.open) {
      dialog.close();
    }
  }, [isOpen]);

  // Prevent scroll while dialog open; restore scroll position on close
  React.useEffect(() => {
    if (!isOpen) return;
    const scrollY = window.scrollY;
    document.body.style.overflow = 'hidden';
    document.body.style.top = `-${scrollY}px`;
    return () => {
      document.body.style.overflow = '';
      document.body.style.top = '';
      window.scrollTo(0, scrollY);
    };
  }, [isOpen]);

  return (
    <dialog
      ref={dialogRef}
      aria-labelledby={`${triggerId}-title`}
      onClose={onClose}
      className="rounded-xl p-0 backdrop:bg-black/50 max-w-lg w-full"
    >
      {/* Heading FIRST — SR announces it when dialog opens */}
      <div className="p-6">
        <h2 id={`${triggerId}-title`} className="text-xl font-semibold">
          {title}
        </h2>
        {/* Close button below heading — autofocus lands here */}
        <button
          autoFocus
          onClick={onClose}
          aria-label="Close dialog"
          className="absolute inset-e-4 inset-s-auto top-4 min-h-11 min-w-11 flex items-center justify-center"
        >
          ✕
        </button>
      </div>
      <div className="px-6 pb-6">
        {children}
      </div>
    </dialog>
  );
}
```

### Known Browser Bugs

| Bug | Platform | Workaround |
|-----|----------|-----------|
| `autofocus` skipped | Chrome macOS + Windows | Place close button as first focusable; Chrome will focus it |
| Virtual cursor escapes | TalkBack Android 12 | Test on Android 13+ — fixed there |
| `aria-modal` ignored | Some AT with `<dialog>` | Use `showModal()`, not `open` attribute |
| `inert` polyfill needed | Legacy browsers | `npm install wicg-inert` |

### Confirmation Dialog Pattern

```tsx
function ConfirmDialog({
  isOpen,
  onConfirm,
  onCancel,
  message,
}: {
  isOpen: boolean;
  onConfirm: () => void;
  onCancel: () => void;
  message: string;
}) {
  const dialogRef = React.useRef<HTMLDialogElement>(null);

  React.useEffect(() => {
    if (isOpen) dialogRef.current?.showModal();
    else dialogRef.current?.close();
  }, [isOpen]);

  return (
    <dialog
      ref={dialogRef}
      role="alertdialog"
      aria-labelledby="confirm-title"
      aria-describedby="confirm-desc"
      onClose={onCancel}
    >
      <h2 id="confirm-title">Are you sure?</h2>
      <p id="confirm-desc">{message}</p>
      <div className="flex gap-4 mt-6 justify-end">
        {/* Cancel first — autofocus on cancel is safer (prevents accidental confirm) */}
        <button autoFocus onClick={onCancel} className="min-h-11 min-w-11 px-6">
          Cancel
        </button>
        <button onClick={onConfirm} className="min-h-11 min-w-11 px-6">
          Confirm
        </button>
      </div>
    </dialog>
  );
}
```

### Non-Modal Dialog Pattern

Non-modal dialogs (notifications, inspectors) use `show()` not `showModal()`:

```tsx
function NonModalDialog({ isOpen, title, children }: {
  isOpen: boolean;
  title: string;
  children: React.ReactNode;
}) {
  const dialogRef = React.useRef<HTMLDialogElement>(null);

  React.useEffect(() => {
    if (isOpen) dialogRef.current?.show(); // non-modal — no focus trap, no inert
    else dialogRef.current?.close();
  }, [isOpen]);

  return (
    <dialog
      ref={dialogRef}
      aria-labelledby="nonmodal-title"
      // MUST set aria-modal="false" for non-modal (implicit default, but explicit is safer)
      aria-modal="false"
      className="fixed inset-e-6 inset-s-auto bottom-6 inset-s-unset w-80 rounded-xl shadow-xl"
    >
      <h3 id="nonmodal-title">{title}</h3>
      {children}
    </dialog>
  );
}
```

### Scroll Lock + Scrollbar Gutter

```css
/* Prevents layout shift when dialog opens (scrollbar disappears) */
html {
  scrollbar-gutter: stable;
}

/* Applied via JS when dialog is open */
body.modal-active {
  overflow: hidden;
}
```

### VoiceOver Behavior Notes

- VoiceOver works well when focus lands on a focusable element inside the dialog
- VoiceOver announces: dialog role + `aria-labelledby` content as the dialog name
- macOS VoiceOver: headings navigable inside dialog with `H` key
- iOS VoiceOver: swipe to navigate inside dialog; Esc = two-finger scrub

---

## Popover API

### What the Browser Provides Automatically

| Feature | Browser Support | Notes |
|---------|----------------|-------|
| `aria-expanded` on popovertarget button | Chrome/Edge/Firefox/Safari | Updated automatically on toggle |
| `aria-details` relationship | Chrome/Edge/Firefox | NOT Safari — add manually for Safari |
| `role="group"` on popover | Chrome/Edge/Firefox | NOT Safari |
| Focus return to invoking element on close | All | Built-in |
| Tab order insertion after invoking button | All | Popover content appears after button in tab order |
| Light dismiss (click outside, Esc) | All (popover="auto") | popover="manual" disables this |
| Top layer rendering | All | No z-index management needed |

### What Developers MUST Provide

```tsx
// Popover API gives you the plumbing; you must provide the semantics

// WRONG: No role, no label — SR user has no context
<div popover id="my-popover">
  <button>Item 1</button>
  <button>Item 2</button>
</div>

// RIGHT: Full semantic annotations
<div
  popover="auto"
  id="my-popover"
  role="menu"
  aria-label="User actions"
>
  <button role="menuitem" className="min-h-11 w-full text-start px-4 py-2">
    Edit profile
  </button>
  <button role="menuitem" className="min-h-11 w-full text-start px-4 py-2">
    Sign out
  </button>
</div>
<button
  popovertarget="my-popover"
  aria-haspopup="menu"
  className="min-h-11"
>
  Actions
</button>
```

### Accessible Dropdown Menu

```tsx
function DropdownMenu({
  label,
  items,
}: {
  label: string;
  items: Array<{ label: string; onClick: () => void }>;
}) {
  const popoverId = React.useId();

  return (
    <div className="relative inline-block">
      <button
        popovertarget={popoverId}
        aria-haspopup="menu"
        className="min-h-11 min-w-11 px-4 flex items-center gap-2"
      >
        {label}
        <span aria-hidden="true" className="rtl:rotate-180">▾</span>
      </button>

      <div
        popover="auto"
        id={popoverId}
        role="menu"
        aria-label={label}
        className="absolute inset-s-0 top-full mt-1 min-w-48 rounded-lg shadow-xl bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-700 p-1"
        onKeyDown={(e) => {
          // Arrow key navigation — not provided by browser
          if (e.key === 'ArrowDown') focusNextMenuItem(e);
          if (e.key === 'ArrowUp') focusPrevMenuItem(e);
          if (e.key === 'Home') focusFirstMenuItem(e);
          if (e.key === 'End') focusLastMenuItem(e);
        }}
      >
        {items.map((item) => (
          <button
            key={item.label}
            role="menuitem"
            onClick={() => {
              item.onClick();
              document.getElementById(popoverId)?.hidePopover();
            }}
            className="min-h-11 w-full text-start px-4 py-2 rounded hover:bg-gray-100 dark:hover:bg-gray-800 focus-visible:outline focus-visible:outline-2"
          >
            {item.label}
          </button>
        ))}
      </div>
    </div>
  );
}
```

### Accessible Tooltip

```tsx
function Tooltip({ content, children }: { content: string; children: React.ReactNode }) {
  const tooltipId = React.useId();

  return (
    <span className="relative inline-block">
      <span
        // Tooltips: use aria-describedby on trigger, not aria-labelledby
        aria-describedby={tooltipId}
        onMouseEnter={() => document.getElementById(tooltipId)?.showPopover()}
        onMouseLeave={() => document.getElementById(tooltipId)?.hidePopover()}
        onFocus={() => document.getElementById(tooltipId)?.showPopover()}
        onBlur={() => document.getElementById(tooltipId)?.hidePopover()}
      >
        {children}
      </span>
      <span
        popover="manual"
        id={tooltipId}
        role="tooltip"
        className="absolute inset-s-0 bottom-full mb-2 px-3 py-1.5 text-sm bg-gray-900 text-white rounded whitespace-nowrap pointer-events-none"
      >
        {content}
      </span>
    </span>
  );
}
```

### Popover Testing Checklist

```
Tab:          Tab focuses launch button, then popover controls in DOM order
Space/Enter:  Toggles popover (browser handles for popovertarget buttons)
Escape:       Closes popover (browser handles for popover="auto")
Shift+Tab:    Can tab OUT of popover into content before trigger (non-modal)
SR desktop:   Announces: name + role (button) + state (expanded/collapsed)
SR desktop:   After opening: SR enters popover (tabbing in) or via virtual cursor
SR mobile:    Swipe focuses button, double-tap toggles
Focus trap:   NOT present for popover — user can tab through entire page
Arrow keys:   Developer responsibility for menu/listbox roles
```

---

## Comparison: dialog vs Popover vs Custom Overlay

| Feature | `<dialog showModal()>` | `<dialog show()>` | Popover API | Custom div + ARIA |
|---------|----------------------|-------------------|-------------|-------------------|
| Focus trap | Automatic | None | None | Manual |
| Background inert | Automatic | No | No | Manual with `inert` |
| Focus return | Automatic | No (manage manually) | Automatic | Manual |
| Esc to close | Automatic | No | Auto (popover="auto") | Manual |
| Top layer | Yes | No | Yes | z-index (fragile) |
| `aria-modal` needed | No | Yes (if modal-like) | No | Yes |
| Role needed | No (`dialog` implicit) | No (`dialog` implicit) | YES — developer sets | YES |
| Light dismiss | No (Esc only) | No | Yes (popover="auto") | Manual |
| Use case | Modal dialogs, confirms | Inspectors, drawers | Menus, tooltips, sheets | Avoid — use above |

---

## Common Mistakes and Fixes

| Mistake | Why It Fails | Fix |
|---------|-------------|-----|
| `role="dialog"` + `aria-modal="true"` on `<div>` | SR may not trap focus in AT | Use native `<dialog>` with `showModal()` |
| `autofocus` on heading `<h2>` | Not interactive — Chrome skips to next focusable | Use `autofocus` on close button or first control |
| Popover with no `role` | SR announces generic "group" (partial browsers) or nothing | Always set `role="menu"`, `role="dialog"`, `role="tooltip"` etc. |
| `aria-expanded` manually set on popovertarget | Conflicts with browser-managed attribute | Remove manual `aria-expanded` — browser manages it |
| No arrow key handling in `role="menu"` | WCAG 4.1.2 failure — menus require keyboard navigation | Add `onKeyDown` with ArrowDown/Up/Home/End |
| Dialog without `aria-labelledby` | SR announces "dialog" with no name | Add `aria-labelledby` pointing to heading |
| Multiple trigger buttons | `close()` may not return focus correctly | `close()` returns to last focused element — test multi-trigger flows |
| Scroll not locked | Content scrolls behind modal | Implement scroll lock + `scrollbar-gutter: stable` |

---

## RTL Considerations

### Positioning Popovers

```tsx
// RTL-safe popover positioning — use inset-s-* / inset-e-*
// Menu anchored to start (right in RTL, left in LTR)
<div
  popover="auto"
  className="absolute inset-s-0 inset-e-auto top-full"
>

// Tooltip above, aligned to start edge
<span
  popover="manual"
  className="absolute inset-s-0 inset-e-auto bottom-full mb-2"
>
```

### Reading Order in Dialogs

```tsx
// RTL: Button order in RTL confirmation — "Cancel" is on the left (end in RTL)
// Primary action should be at the end (right in LTR, left in RTL)
<div className="flex justify-end gap-4">
  {/* In RTL, flex order: Cancel appears on right, Confirm on left */}
  {/* Use flex-row-reverse in RTL if you want consistent visual positioning */}
  <button onClick={onCancel} className="min-h-11">ביטול</button>
  <button onClick={onConfirm} className="min-h-11">אישור</button>
</div>

// Directional chevron in dropdown trigger
<span aria-hidden="true" className="rtl:rotate-180">›</span>
```

---

## Cross-References

- WCAG 2.4.11/2.4.12 Focus Not Obscured (dialogs can obscure focus): `~/.claude/skills/a11y/SKILL.md`
- Popover positioning with Floating UI: `references/web-a11y.md`
- Testing dialogs with Playwright: `references/a11y-testing.md`
- Scroll-driven animation inside dialogs: `references/motion-contrast-modes.md`
- COGA: Confirmation dialogs prevent errors (3.3.4): `references/cognitive-a11y.md`

---

<!-- DIALOG_POPOVER_A11Y v24.6.0 | Updated: 2026-02-24 | Native dialog + Popover API + WAI-ARIA 1.2 -->
