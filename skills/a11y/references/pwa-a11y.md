# PWA Accessibility Reference

> **v24.6.0** | Progressive Web Apps | Offline + Push + Install | Cash PWA Patterns
> RTL-FIRST: `inset-s-*`/`inset-e-*` for positioning (TW 4.2)

---

## Offline Mode Indicators

```html
<div role="status" aria-live="polite" aria-atomic="true" class="fixed top-0 inset-s-0 inset-e-0 z-50">
  {isOffline && <span>You are offline. Some features may be limited.</span>}
</div>
```

- `role="status"` + `aria-live="polite"`: non-interrupting announcement
- Position with `inset-s-0 inset-e-0` (not `left-0 right-0`) for RTL
- Announce BOTH going offline AND coming back online
- Listen to `online`/`offline` events, call `announceToSR()` on each transition

---

## Install Prompt

```html
<div role="alertdialog" aria-labelledby="install-title" aria-describedby="install-desc">
  <h2 id="install-title">Install App</h2>
  <p id="install-desc">Install for faster access and offline support.</p>
  <button autofocus>Install</button>
  <button>Not now</button>
</div>
```

- `role="alertdialog"` requires user decision; `autofocus` on primary action
- Escape dismisses; focus returns to previous element
- Do not auto-show on first visit; announce install success via `appinstalled` event

---

## Service Worker Update

```html
<div role="alert" aria-live="assertive" class="fixed bottom-4 inset-s-4 inset-e-4 z-50">
  <p>A new version is available.</p>
  <button class="min-h-11 min-w-11" aria-label="Update app">Update</button>
  <button class="min-h-11 min-w-11" aria-label="Dismiss">Later</button>
</div>
```

- `assertive`: important update, interrupts; touch targets 44x44px
- Provide "Later" option; explain update triggers page reload

---

## Push Notifications

| Platform | Support |
|----------|---------|
| iOS | 16.4+ home screen PWA only; Safari 18.4+ Declarative Web Push |
| Android | Full (Push API + Notification API) |
| Desktop | Full (Chromium + Firefox) |

- Never request permission on page load; explain value first
- Announce permission result to SR (granted/denied)
- Keep notification `body` concise; SR reads full text
- Use `tag` to prevent duplicate announcements

---

## Loading States

```html
<!-- Skeleton: aria-busy + hidden visuals -->
<div aria-busy="true" aria-label="Loading menu items" role="status">
  <div aria-hidden="true" class="animate-pulse">...</div>
</div>

<!-- Progressive loading announcer -->
<div aria-live="polite" class="sr-only">
  {loadingState === 'loading' && 'Loading content...'}
  {loadingState === 'complete' && 'All content loaded'}
  {loadingState === 'error' && 'Failed to load. Pull to retry.'}
</div>
```

Remove `aria-busy` and `aria-hidden` when content loads. Announce completion count.

---

## Background Sync

- Listen for SW `message` events: announce sync success/failure to SR
- Background Sync not available on iOS; provide manual sync fallback button
- Queue announcements; do not interrupt mid-interaction

---

## App Badge

- `navigator.setAppBadge(count)` / `navigator.clearAppBadge()`
- NOT announced by screen readers; fallback: include count in `<title>` (`(5) Cash`)
- In-app: use `aria-live="polite"` region to announce count changes

---

## Share Target + File Handling

**Share Target:** announce received content, pre-fill labeled form fields, confirm save result.

**File Handling:** announce file name + size on open, progress for large files, explain rejection reason on error.

---

## PWA Standalone Mode — Lost Browser Features

| Lost Feature | PWA Compensation |
|-------------|-----------------|
| Back button | In-app nav with `min-h-11 min-w-11` button, `rtl:rotate-180` arrow |
| Address bar | SR-only live region: "Currently viewing: {page}" |
| Find on page | In-app search with ARIA combobox |
| Zoom controls | Proper `rem` sizing, `<meta name="viewport">` without `user-scalable=no` |

```html
<nav aria-label="App navigation" class="fixed top-0 inset-s-0 inset-e-0 z-40">
  <button aria-label="Go back" class="min-h-11 min-w-11">
    <svg aria-hidden="true" class="rtl:rotate-180"><!-- back arrow --></svg>
  </button>
</nav>
```

---

## Delivery Status — Cash PWA Patterns

```html
<!-- Order tracking live region -->
<div role="status" aria-live="polite" aria-atomic="true">
  {status === 'preparing' && 'Order is being prepared'}
  {status === 'delivering' && `Driver is ${distance} away`}
  {status === 'delivered' && 'Order delivered successfully'}
</div>
```

- Throttle driver location announcements: max every 30 seconds
- Delivery completion: `role="alert"` + `assertive` for immediate notification
- Rating UI: `role="group" aria-label="Rating"` with individual `aria-label` on each star button

---

## SR Announcement Helper

```typescript
function announceToSR(message: string, priority: 'polite' | 'assertive' = 'polite') {
  const el = document.getElementById('sr-announcer') || createAnnouncer(priority);
  el.textContent = '';
  requestAnimationFrame(() => { el.textContent = message; });
}

function createAnnouncer(priority: string): HTMLElement {
  const el = document.createElement('div');
  Object.assign(el, { id: 'sr-announcer', className: 'sr-only' });
  el.setAttribute('role', 'status');
  el.setAttribute('aria-live', priority);
  el.setAttribute('aria-atomic', 'true');
  document.body.appendChild(el);
  return el;
}
```

---

<!-- PWA_A11Y v24.6.0 | Offline, push, install, standalone, Cash PWA patterns -->
