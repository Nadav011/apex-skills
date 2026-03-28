# Mobile Accessibility Reference

> **v24.6.0** | iOS VoiceOver | Android TalkBack | NVDA/JAWS | Cross-Platform
> RTL gestures: swipe directions reverse in RTL layouts

---

## iOS VoiceOver

### Gesture Reference

| Gesture | Action |
|---------|--------|
| Single tap | Select and read item |
| Swipe right | Next element |
| Swipe left | Previous element |
| Double tap | Activate selected item |
| Triple tap | Double-tap on element (long press) |
| Two-finger swipe up | Read from top |
| Two-finger swipe down | Read from current position |
| Two-finger tap | Pause/resume speech |
| Two-finger Z shape | Go back / dismiss |
| Two-finger scrub (Z) | Escape / dismiss dialog |
| Three-finger swipe up | Scroll down |
| Three-finger swipe down | Scroll up |
| Three-finger swipe right | Scroll left / next page |
| Three-finger swipe left | Scroll right / prev page |
| Three-finger double tap | Toggle mute |
| Rotor (two-finger twist) | Change navigation mode (headings, links, form controls) |
| Swipe up/down (with rotor) | Navigate by rotor category |
| Magic tap (two-finger double) | App-defined action (play/pause, answer/end call) |
| Four-finger tap top | First element |
| Four-finger tap bottom | Last element |

### Rotor Categories
Headings, Links, Form Controls, Static Text, Landmarks, Tables, Lists, Buttons, Text Fields, Search Fields, Images, Containers, Same Item.

### Dynamic Type

```swift
// UIKit
label.font = UIFont.preferredFont(forTextStyle: .body)
label.adjustsFontForContentSizeCategory = true

// SwiftUI
Text("Content").dynamicTypeSize(...DynamicTypeSize.xxxLarge)
```

- Sizes: xSmall through AX5 (accessibility extra large)
- Maximum scale: ~3.12x (AX5)
- Test at: Default, XXXL, and AX5 minimum
- Use `UIFontMetrics` for custom fonts

### Accessibility Inspector (Xcode)
- Audit tab: automated accessibility checks
- Inspection pointer: live element inspection
- Settings: override Dynamic Type, color filters, reduce motion
- Use for: validating labels, traits, hints on real device

### Voice Control (iOS 13+)
- Users speak commands: "Tap [label]", "Show numbers", "Show grid"
- Ensure every interactive element has a visible label that matches `accessibilityLabel`
- Grid overlay: users say grid numbers to interact

### iOS 26 Accessibility

**Accessibility Nutrition Labels:**
- App Store displays standardized accessibility capabilities
- Categories: Vision, Hearing, Mobility, Cognitive
- Declared by developer, validated by Apple review
- Include: VoiceOver support level, Dynamic Type support, haptic feedback, captions

**Personal Voice:**
- ~1 minute of voice recording creates personalized TTS
- On-device ML processing (no server upload)
- Available for Live Speech, third-party apps via Accessibility API
- Supports: English, and expanding to more languages

**VoiceOver refinements (iOS 26):**
- Improved navigation in complex scroll views
- Better web content handling in Safari
- Enhanced support for custom rotor items

---

## Android TalkBack

### Gesture Reference

| Gesture | Action |
|---------|--------|
| Touch and explore | Read element under finger |
| Swipe right | Next element |
| Swipe left | Previous element |
| Double tap | Activate selected item |
| Double tap and hold | Long press |
| Swipe up then down | Local context menu (actions for current item) |
| Swipe down then up | Global context menu (TalkBack settings) |
| Swipe right then left | Scroll forward / next page |
| Swipe left then right | Scroll backward / prev page |
| Swipe up then left | Back gesture |
| Two-finger tap | Pause/resume speech |
| Two-finger swipe up | Scroll down |
| Two-finger swipe down | Scroll up |
| Three-finger tap | Copy selected text |
| Three-finger swipe left | Next reading control |
| Three-finger swipe right | Previous reading control |
| Three-finger swipe up/down | Navigate by reading control |

### TalkBack 16.2 (Dec 2025)

**Gemini-Powered Voice Dictation:**
- Context-aware dictation in text fields
- Handles punctuation, formatting commands
- Multi-language support including Hebrew
- Available on Pixel 6+ and Samsung Galaxy S23+

**Browse Mode (External Keyboards / Braille Displays):**
- H: next heading, Shift+H: previous heading
- K: next link, Shift+K: previous link
- B: next button, Shift+B: previous button
- Tab: next focusable, Shift+Tab: previous focusable
- Enter: activate, Escape: back

**Text Formatting Detection:**
- Announces bold, italic, underline in text content
- Reads heading levels (h1-h6)
- Reports list structure (ordered, unordered, nesting level)

### Android 16 Accessibility APIs

```kotlin
// New: setSupplementalDescription() — additional context beyond label
view.accessibilityDelegate = object : View.AccessibilityDelegate() {
    override fun onInitializeAccessibilityNodeInfo(host: View, info: AccessibilityNodeInfo) {
        super.onInitializeAccessibilityNodeInfo(host, info)
        info.setSupplementalDescription("3 unread messages")
    }
}

// New: setFieldRequired()
info.setFieldRequired(true)  // Announces "required" for form fields
```

### Android Font Scaling

```kotlin
// Get current scale
val fontScale = resources.configuration.fontScale

// Test with ADB
// adb shell settings put system font_scale 2.0
```

- Default scale: 1.0, maximum varies by OEM (~2.0 typical)
- Use `sp` for text sizes (scales with user preference)
- Use `dp` for non-text dimensions
- Test at 1.0x, 1.3x, and 2.0x minimum

### Accessibility Scanner (Google)
- Play Store app for automated checks
- Scans: touch target size, contrast ratio, label presence
- Produces suggestions with screenshots
- Use before manual testing

### Switch Access
- External switch or on-screen switch
- Scanning modes: linear, row-column
- Ensure all interactive elements are reachable in scan order
- Test: every button, link, input reachable via sequential scanning

---

## NVDA (Windows) Quick Reference

| Shortcut | Action |
|----------|--------|
| NVDA + Space | Toggle focus/browse mode |
| H | Next heading |
| Shift + H | Previous heading |
| K | Next link |
| D | Next landmark |
| F | Next form field |
| T | Next table |
| 1-6 | Next heading level 1-6 |
| Enter | Activate link/button |
| Space | Activate button / check checkbox |
| Tab | Next focusable element |
| Ctrl | Stop speech |
| NVDA + F7 | Elements list (links, headings, landmarks) |
| NVDA + F5 | Refresh virtual buffer |
| NVDA + T | Read title bar |

### NVDA Testing Protocol
1. Load page, listen to initial announcement
2. Use H to navigate all headings — verify hierarchy
3. Use D to navigate landmarks — verify banner, main, contentinfo
4. Tab through all interactive elements
5. Fill and submit forms — verify error announcements
6. Open/close dialogs — verify focus management
7. Test live regions — verify dynamic content announced

---

## JAWS Quick Reference

| Shortcut | Action |
|----------|--------|
| Insert + Down | Read from cursor |
| Insert + F6 | Heading list |
| Insert + F7 | Link list |
| Insert + F5 | Form fields list |
| Ctrl + Home | Top of page |
| H / Shift+H | Next/previous heading |
| R / Shift+R | Next/previous region/landmark |
| F / Shift+F | Next/previous form field |
| T / Shift+T | Next/previous table |
| G / Shift+G | Next/previous graphic |
| Enter | Activate link |
| Space | Activate button |

---

## ChromeVox (ChromeOS)

| Shortcut | Action |
|----------|--------|
| Search + Arrow Right | Next element |
| Search + Arrow Left | Previous element |
| Search + Space | Activate |
| Search + H | Next heading |
| Search + L | Next link |
| Search + . | Open ChromeVox menu |
| Ctrl | Stop speech |

---

## Cross-Platform Testing

### Focus Order Testing

```
1. Enable screen reader
2. Navigate to first element (top of page)
3. Swipe right (mobile) or Tab (desktop) through ALL elements
4. Record the order — compare to visual layout
5. Verify: matches top-to-bottom, start-to-end reading order
6. Check: no elements skipped, no focus traps
7. In RTL: verify start-to-end means right-to-left
```

### Announcement Testing

```
For each interactive element:
1. Focus the element
2. Record what SR announces
3. Verify: role (button, link, etc.) is correct
4. Verify: label is descriptive and matches visible text
5. Verify: state is announced (expanded, selected, checked)
6. Verify: hint provides action guidance
7. For custom widgets: verify custom role description
```

### Dismissal Pattern Testing

| Action | Expected |
|--------|----------|
| Esc key (desktop) | Close dialog/popover, return focus to trigger |
| Two-finger Z (VoiceOver) | Dismiss, return focus |
| Back gesture (TalkBack) | Dismiss, return focus |
| Swipe down from top (Android) | Dismiss notification panel, not app dialog |
| Click/tap outside (popover) | Light dismiss, return focus |

---

## RTL Gestures

### Swipe Direction in RTL

| Gesture | LTR Meaning | RTL Meaning |
|---------|------------|------------|
| Swipe right | Next | Next (same — SR convention) |
| Swipe left | Previous | Previous (same) |
| Three-finger swipe right | Next page | Next page |
| Three-finger swipe left | Previous page | Previous page |

**Key insight:** VoiceOver/TalkBack swipe gestures do NOT reverse in RTL. "Swipe right = next" is a universal SR convention regardless of layout direction.

### Navigation Drawer
- In RTL: drawer opens from the end (right side in LTR, left side in RTL)
- Swipe from end edge to open
- Flutter: `Scaffold(endDrawer:)` for actions, `drawer:` auto-mirrors in RTL

---

## Structured Screen Reader Testing Protocol

### Phase 1: Page Load
1. Enable SR, navigate to page
2. Verify: page title announced
3. Verify: main landmark found
4. Navigate to first heading (H key)
5. Verify: H1 present and descriptive

### Phase 2: Navigation
1. Navigate all headings (H repeatedly) — verify hierarchy (H1 > H2 > H3)
2. Navigate all landmarks (D/R key) — verify: banner, nav, main, contentinfo
3. Navigate all links (K key) — verify: descriptive text, not "click here"
4. Check skip link: Tab from top — verify "Skip to main content" works

### Phase 3: Interaction
1. Tab to every interactive element
2. For each: verify role, label, state announced
3. Activate buttons: Enter/Space
4. Open dialogs: verify focus moves inside, Esc returns focus
5. Fill forms: verify label read for each field
6. Submit with errors: verify error announcements
7. Submit success: verify success announcement

### Phase 4: Dynamic Content
1. Trigger content updates (load more, real-time)
2. Verify: aria-live regions announce changes
3. Verify: loading states announced
4. Verify: error states announced with `assertive`
5. Test auto-complete: verify suggestions announced

### Phase 5: RTL-Specific
1. Verify: reading order follows RTL (right-to-left)
2. Verify: focus order matches visual RTL layout
3. Verify: numbers announced correctly
4. Verify: mixed content (Hebrew + English) handled
5. Verify: directional icons have correct labels (not "left arrow" in RTL)

### Assertion Template

```
Element: [name/selector]
Expected Role: [button/link/heading/etc.]
Expected Label: [exact text]
Expected State: [expanded/selected/checked/disabled]
Expected Hint: [action description]
Actual: [what SR announced]
Result: [PASS/FAIL]
```

---

<!-- MOBILE_A11Y v24.6.0 | VoiceOver, TalkBack 16.2, NVDA, JAWS, ChromeVox, RTL gestures -->
