# Flutter Accessibility Reference

> **v24.6.0** | Flutter 3.41.2 / Dart 3.11 | WCAG 2.2 AAA | VoiceOver + TalkBack
> CRITICAL: Use `textScalerOf` (NOT deprecated `textScaleFactorOf`)

---

## Semantics Widget — Full Reference

### Basic Usage

```dart
// Image with semantic label
Image.asset(
  'assets/logo.png',
  semanticLabel: 'Company logo - TechCorp',
);

// Custom widget with semantics
Semantics(
  label: 'Shopping cart with 3 items',
  button: true,
  onTap: () => openCart(),
  child: CustomCartIcon(itemCount: 3),
);

// Decorative — exclude from AT
Image.asset(
  'assets/decorative-border.png',
  excludeFromSemantics: true,
);
```

### SemanticsProperties Reference

| Category | Properties |
|----------|-----------|
| **Identity** | `label`, `hint`, `value`, `tooltip` |
| **Role** | `button`, `link`, `header`, `textField`, `slider`, `image`, `readOnly` |
| **State** | `enabled`, `selected`, `checked` (true/false/null), `toggled`, `focused`, `hidden`, `obscured`, `liveRegion` |
| **Sorting** | `sortKey: OrdinalSortKey(1.0)` |
| **Actions** | `onTap`, `onLongPress`, `onScrollLeft/Right/Up/Down`, `onIncrease`, `onDecrease`, `onDismiss`, `onCopy/Cut/Paste` |
| **Tree** | `container`, `explicitChildNodes`, `excludeSemantics` |

```dart
Semantics(
  label: 'Cart with 3 items',  hint: 'Double tap to open',
  button: true,  enabled: true,
  onTap: () => openCart(),
  child: CustomCartIcon(itemCount: 3),
)
```

---

## MergeSemantics

Groups related elements into a single SR announcement.

```dart
// Before: SR reads "Star icon", "4.5", "rating", "(128 reviews)" separately
// After: SR reads "4.5 rating (128 reviews)"
MergeSemantics(
  child: Row(
    children: [
      const Icon(Icons.star, color: Colors.amber),
      const SizedBox(width: 4),
      const Text('4.5 rating'),
      const Text('(128 reviews)'),
    ],
  ),
)
```

**Use when:** icon + label, rating + count, status indicator + text.
**Do NOT use on:** interactive elements that need separate focus.

---

## ExcludeSemantics

Removes decorative elements from the accessibility tree.

```dart
// Decorative background
ExcludeSemantics(
  child: DecorativeBackground(),
)

// Alternative: property on Semantics
Semantics(
  excludeSemantics: true,
  child: AnimatedGradient(),
)
```

**Use for:** decorative images, background animations, visual-only dividers.

---

## SemanticsService

Programmatic announcements to screen readers.

```dart
// Announce in Hebrew (RTL)
SemanticsService.announce('הטופס נשלח בהצלחה', TextDirection.rtl);

// Announce navigation
SemanticsService.announce('Page 2 of 5', TextDirection.ltr);

// Announce with tooltip
SemanticsService.tooltip('Double tap to copy');
```

### Hebrew Announcer Pattern

```dart
class HebrewAnnouncer {
  static void announce(String message) =>
    SemanticsService.announce(message, TextDirection.rtl);
  static void announceError(String error) => announce('שגיאה: $error');
  static void announceSuccess(String msg) => announce('הצלחה: $msg');
  static void announceLoading() => announce('טוען, אנא המתן');
}
```

---

## Focus Management

### FocusTraversalGroup

```dart
FocusTraversalGroup(
  policy: OrderedTraversalPolicy(),
  child: Column(children: [
    FocusTraversalOrder(order: const NumericFocusOrder(1), child: usernameField),
    FocusTraversalOrder(order: const NumericFocusOrder(2), child: passwordField),
    FocusTraversalOrder(order: const NumericFocusOrder(3), child: loginButton),
  ]),
)
```

| Policy | Behavior |
|--------|----------|
| `ReadingOrderTraversalPolicy()` | Follows reading direction (respects RTL) |
| `OrderedTraversalPolicy()` | Uses explicit `FocusTraversalOrder` widgets |
| `WidgetOrderTraversalPolicy()` | Follows widget tree order |

### FocusScope + FocusNode

```dart
// Modal dialog with trapped focus + primary action autofocus
FocusScope(
  autofocus: true,
  child: AlertDialog(
    title: Semantics(header: true, child: const Text('אישור פעולה')),
    content: const Text('האם אתה בטוח?'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ביטול')),
      TextButton(autofocus: true, onPressed: () => Navigator.pop(context, true), child: const Text('אישור')),
    ],
  ),
)

// Manual focus control
final focusNode = FocusNode();
// ...dispose in State.dispose()
focusNode.requestFocus();
SemanticsService.announce('Field focused', TextDirection.ltr);
```

---

## RTL Semantics

### Bidirectional Semantic Widget

```dart
class RTLSemanticWidget extends StatelessWidget {
  final String hebrewLabel;
  final String englishLabel;
  final Widget child;

  const RTLSemanticWidget({
    required this.hebrewLabel,
    required this.englishLabel,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      label: isRTL ? hebrewLabel : englishLabel,
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: child,
    );
  }
}
```

### RTL Focus Traversal

```dart
// ReadingOrderTraversalPolicy respects RTL automatically
Directionality(
  textDirection: TextDirection.rtl,
  child: FocusTraversalGroup(
    policy: ReadingOrderTraversalPolicy(),
    child: Row(
      children: [
        _buildButton('ראשון'),   // First focus in RTL (rightmost)
        _buildButton('שני'),
        _buildButton('שלישי'),   // Last focus in RTL (leftmost)
      ],
    ),
  ),
)
```

---

## Touch Target Validation

Material 3: **48dp minimum** (`const double kMinTouchTarget = 48.0`), 8dp spacing between targets.

```dart
// Wrap with Semantics + ConstrainedBox for any custom touch target
Semantics(
  label: semanticLabel, button: true,
  child: InkWell(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      child: Center(child: child),
    ),
  ),
)

// IconButton: always set constraints + tooltip
IconButton(
  icon: const Icon(Icons.settings), onPressed: openSettings, tooltip: 'Settings',
  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
)
```

---

## Font Scaling — textScalerOf

```dart
// CORRECT: Use textScalerOf (Flutter 3.41.2+)
final textScaler = MediaQuery.textScalerOf(context);

// Scale-aware layout
final scaledPadding = 16.0 * textScaler.scale(1.0);

// Detect large text for layout adaptation
final isLargeText = textScaler.scale(1.0) > 1.5;
if (isLargeText) {
  // Switch to vertical layout for readability
  return Column(children: [...]);
}

// WRONG: deprecated API
// final scale = MediaQuery.textScaleFactorOf(context); // DO NOT USE
```

---

## High Contrast Theme

```dart
// Detection
final isHighContrast = MediaQuery.highContrastOf(context);

// High contrast: max contrast colors, thicker borders (2-3px), no transparency
// Light HC: black text on white, blue links, red errors
// Dark HC: white text on black, cyan links, #FF6666 errors
// InputDecoration: OutlineInputBorder(borderSide: BorderSide(width: isHighContrast ? 3 : 1))
```

---

## SemanticsDebugger

```dart
// Overlay semantic boundaries on screen
void main() {
  runApp(
    SemanticsDebugger(
      child: const MyApp(),
    ),
  );
}

// Or toggle in MaterialApp
MaterialApp(
  showSemanticsDebugger: true,  // Toggle for debugging
  home: const MyHomePage(),
)
```

**Reads:** Shows semantic labels, roles, and actions for each node.
**Use for:** verifying SR will announce correct content, finding missing labels.

---

## Integration Testing for Semantics

```dart
testWidgets('Button has correct semantics', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: LoginPage()));
  final btn = find.bySemanticsLabel('התחבר');
  expect(btn, findsOneWidget);
  final sem = tester.getSemantics(btn);
  expect(sem.hasFlag(SemanticsFlag.isButton), true);
  expect(sem.hasFlag(SemanticsFlag.isEnabled), true);
});

testWidgets('All images have semantic labels', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: ProductPage()));
  for (final img in find.byType(Image).evaluate()) {
    expect((img.widget as Image).semanticLabel, isNotNull);
  }
});

testWidgets('Touch targets >= 48dp', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: MyApp()));
  final interactive = find.byWidgetPredicate((w) =>
      w is GestureDetector || w is InkWell || w is ElevatedButton || w is IconButton);
  for (final el in interactive.evaluate()) {
    final size = tester.getSize(find.byWidget(el.widget));
    expect(size.width >= 48 && size.height >= 48, true,
        reason: 'Touch target: ${size.width}x${size.height}');
  }
});

testWidgets('SR announcements fire', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: FormPage()));
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle();
  expect(tester.takeAnnouncements(),
    contains(predicate<CapturedAccessibilityAnnouncement>(
      (a) => a.message.contains('הצלחה'))));
});
```

---

## Color Contrast Utilities

```dart
class ContrastChecker {
  static double ratio(Color fg, Color bg) {
    final l1 = fg.computeLuminance(), l2 = bg.computeLuminance();
    return ((l1 > l2 ? l1 : l2) + 0.05) / ((l1 > l2 ? l2 : l1) + 0.05);
  }
  static bool meetsAA(Color fg, Color bg) => ratio(fg, bg) >= 4.5;
  static bool meetsAAA(Color fg, Color bg) => ratio(fg, bg) >= 7.0;
}

// Assert at build time
assert(ContrastChecker.meetsAA(theme.colorScheme.onPrimary, theme.colorScheme.primary));
```

---

<!-- FLUTTER_A11Y v24.6.0 | Semantics, focus, RTL, touch targets, textScalerOf, testing -->
