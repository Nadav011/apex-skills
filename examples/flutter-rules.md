# flutter-rules — Real-World Examples

The skill enforces Flutter 3.x/Dart 3.x development rules: RTL-safe directional widgets, Riverpod patterns, accessibility requirements (44px touch targets, tooltip on every IconButton), and safe async/error handling.

## Before / After

### Example 1: Physical directional padding and alignment in RTL layout

**Before** (triggers the skill):
```dart
// ❌ Physical left/right properties — breaks in Arabic/Hebrew RTL context
class MessageTile extends StatelessWidget {
  final Message message;
  const MessageTile({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 8), // BLOCKED: physical left/right
      child: Row(
        children: [
          Icon(Icons.person, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft, // BLOCKED: physical alignment
              child: Text(message.content, textAlign: TextAlign.left),
            ),
          ),
          Text(message.time, textAlign: TextAlign.right), // BLOCKED: physical align
        ],
      ),
    );
  }
}
```

**After** (skill-compliant):
```dart
// ✅ Directional widgets — adapts automatically to RTL locale
class MessageTile extends StatelessWidget {
  final Message message;
  const MessageTile({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16, end: 8), // logical
      child: Row(
        children: [
          const Icon(Icons.person, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart, // logical
              child: Text(
                message.content,
                textAlign: TextAlign.start, // logical
              ),
            ),
          ),
          Text(
            message.time,
            textAlign: TextAlign.end, // logical
          ),
        ],
      ),
    );
  }
}
```

**Why:** `EdgeInsets.only(left: 16)` hard-codes padding to the physical left edge. In a Hebrew or Arabic app where `Directionality` is RTL, the sender's avatar appears on the wrong side and text alignment is mirrored. `EdgeInsetsDirectional.only(start: 16)` maps to physical-left in LTR and physical-right in RTL, giving correct layout with zero conditional code.

---

### Example 2: IconButton missing tooltip and touch target

**Before** (triggers the skill):
```dart
// ❌ No tooltip (fails WCAG 4.1.2), touch target likely < 44px
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('הודעות'),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => context.push('/search'),
          // Missing: tooltip — screen reader announces "button" only
          iconSize: 20, // Touch target may be well under 44px
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => showOptionsSheet(context),
          iconSize: 20,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
```

**After** (skill-compliant):
```dart
// ✅ Every IconButton has tooltip, tap target meets 44px minimum
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('הודעות'),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'חיפוש הודעות', // announces to screen readers
          onPressed: () => context.push('/search'),
          iconSize: 24,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          tooltip: 'אפשרויות נוספות',
          onPressed: () => showOptionsSheet(context),
          iconSize: 24,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
```

**Why:** `IconButton` without `tooltip` announces "button" to screen readers with no context — a WCAG 4.1.2 failure. The `constraints: BoxConstraints(minWidth: 44, minHeight: 44)` expands the tap area to the minimum recommended by Apple HIG and Material Design without changing the visual icon size. This is especially critical for users with motor impairments.

---

### Example 3: Silent async error in Riverpod provider

**Before** (triggers the skill):
```dart
// ❌ Fire-and-forget async, silent catch, no error state exposed
@riverpod
class OrderNotifier extends _$OrderNotifier {
  @override
  List<Order> build() => [];

  Future<void> placeOrder(OrderRequest request) async {
    try {
      final order = await ref.read(orderRepositoryProvider).create(request);
      state = [...state, order];
    } catch (e) {
      // silent — user sees nothing, order may or may not have been placed
      debugPrint('Order failed: $e'); // only in debug mode — zero logs in release
    }
  }
}
```

**After** (skill-compliant):
```dart
// ✅ Typed error state, logged at all build modes, UI can react
@riverpod
class OrderNotifier extends _$OrderNotifier {
  @override
  AsyncValue<List<Order>> build() => const AsyncValue.data([]);

  Future<void> placeOrder(OrderRequest request) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(orderRepositoryProvider);
      final order = await repo.create(request);
      state = state.whenData((orders) => [...orders, order]);
    } on NetworkException catch (e, stack) {
      // Log at warn level — always fires in release too
      log('Order placement failed: $e', level: 900, error: e, stackTrace: stack);
      // Optional: capture to Sentry
      ref.read(sentryProvider).captureException(e, stackTrace: stack);
      state = AsyncValue.error(e, stack);
    } catch (e, stack) {
      log('Unexpected order error', level: 1000, error: e, stackTrace: stack);
      state = AsyncValue.error(e, stack);
    }
  }
}

// UI reacts to error state without polling
class OrderButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderNotifierProvider);
    return orderState.when(
      data: (_) => ElevatedButton(
        onPressed: () => ref.read(orderNotifierProvider.notifier).placeOrder(request),
        child: const Text('הזמן'),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (err, _) => Column(children: [
        const Text('ההזמנה נכשלה', style: TextStyle(color: Colors.red)),
        TextButton(onPressed: () => ref.read(orderNotifierProvider.notifier).placeOrder(request),
                   child: const Text('נסה שוב')),
      ]),
    );
  }
}
```

**Why:** `debugPrint` is gated by `kDebugMode` — it produces zero output in release builds. A failed order in production is completely invisible. Using `AsyncValue<T>` as the state type makes loading, data, and error states first-class — the UI can render a retry button and the logging fires in every build mode, enabling ops visibility.
