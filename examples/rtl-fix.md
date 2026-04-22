# rtl-fix — Real-World Examples

The skill auto-fixes RTL violations in React, Next.js, CSS, and Flutter/Dart: replacing physical directional properties with CSS logical equivalents, and adding `rtl:rotate-180` to horizontal directional icons.

## Before / After

### Example 1: Tailwind physical classes — mechanical batch replacement

**Before** (triggers the skill):
```tsx
// ❌ 8 RTL violations — layout breaks in Hebrew/Arabic UIs
function Sidebar({ items }: { items: NavItem[] }) {
  return (
    <nav className="fixed left-0 top-0 h-screen w-64 border-r bg-white">
      <ul className="mt-6 space-y-1">
        {items.map(item => (
          <li
            key={item.id}
            className="flex items-center border-l-4 border-l-blue-600 pl-4 pr-3 py-2"
          >
            <item.Icon className="mr-2 h-5 w-5" />
            <span className="text-left font-medium">{item.label}</span>
          </li>
        ))}
      </ul>
    </nav>
  );
}
// Violations: left-0, border-r, border-l-4, border-l-blue-600, pl-4, pr-3, mr-2, text-left
```

**After** (rtl-fix applied):
```tsx
// ✅ All 8 violations replaced with logical equivalents
function Sidebar({ items }: { items: NavItem[] }) {
  return (
    <nav className="fixed inset-s-0 top-0 h-screen w-64 border-e bg-white">
      <ul className="mt-6 space-y-1">
        {items.map(item => (
          <li
            key={item.id}
            className="flex items-center border-s-4 border-s-blue-600 ps-4 pe-3 py-2"
          >
            <item.Icon className="me-2 h-5 w-5" />
            <span className="text-start font-medium">{item.label}</span>
          </li>
        ))}
      </ul>
    </nav>
  );
}
// Mapping: left-0→inset-s-0 | border-r→border-e | border-l-4→border-s-4
//           pl-4→ps-4 | pr-3→pe-3 | mr-2→me-2 | text-left→text-start
```

**Why:** `fixed left-0` pins the sidebar to the physical left edge — in RTL mode it overlaps the content instead of sitting at the reading start. `border-l-4` draws the active indicator on the wrong side. All eight violations are mechanical, 1-to-1 replacements that `rtl-fix` applies automatically with zero risk of semantic change.

---

### Example 2: CSS-in-JS and icon flip additions

**Before** (triggers the skill):
```tsx
// ❌ Physical CSS properties + directional icons missing rtl:rotate-180
import styled from 'styled-components';

const BreadcrumbItem = styled.li`
  padding-left: 12px;
  margin-right: 8px;
  border-left: 1px solid #e5e7eb;
`;

function Breadcrumb({ items }: { items: BreadcrumbItem[] }) {
  return (
    <ol className="flex items-center">
      {items.map((item, i) => (
        <BreadcrumbItem key={item.id} className="flex items-center">
          {i > 0 && <ChevronRight className="mx-1 h-4 w-4 text-gray-400" />}
          {/* ChevronRight missing rtl:rotate-180 — points wrong way in RTL */}
          <a href={item.href} className="text-blue-600">{item.label}</a>
        </BreadcrumbItem>
      ))}
    </ol>
  );
}
```

**After** (rtl-fix applied):
```tsx
// ✅ CSS logical properties + icon flip added
import styled from 'styled-components';

const BreadcrumbItem = styled.li`
  padding-inline-start: 12px;   /* was: padding-left */
  margin-inline-end: 8px;        /* was: margin-right */
  border-inline-start: 1px solid #e5e7eb; /* was: border-left */
`;

function Breadcrumb({ items }: { items: BreadcrumbItem[] }) {
  return (
    <ol className="flex items-center">
      {items.map((item, i) => (
        <BreadcrumbItem key={item.id} className="flex items-center">
          {i > 0 && (
            <ChevronRight
              className="mx-1 h-4 w-4 text-gray-400 rtl:rotate-180"
              aria-hidden="true"
            />
          )}
          <a href={item.href} className="text-blue-600">{item.label}</a>
        </BreadcrumbItem>
      ))}
    </ol>
  );
}
```

**Why:** Physical CSS properties in styled-components are just as broken as Tailwind violations — the browser does not auto-flip them in RTL mode. CSS logical properties (`padding-inline-start`, `margin-inline-end`, `border-inline-start`) are the only correct approach. The `ChevronRight` arrow is a horizontal directional icon — without `rtl:rotate-180` it points right in both LTR and RTL, which is the wrong reading direction for RTL breadcrumbs.

---

### Example 3: Flutter physical EdgeInsets and Alignment

**Before** (triggers the skill):
```dart
// ❌ Physical left/right — breaks in Arabic locale (Directionality.rtl)
class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 8, top: 12, bottom: 12),
        // BLOCKED: physical left/right
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft, // BLOCKED: physical alignment
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name),
                    Positioned( // inside a Stack elsewhere
                      left: 8, // BLOCKED: physical position
                      child: Badge(count: product.newCount),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**After** (rtl-fix applied):
```dart
// ✅ Directional widgets — adapts to Directionality.rtl automatically
class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: 16, end: 8, top: 12, bottom: 12,
        ), // was: EdgeInsets.only(left: 16, right: 8, ...)
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                // was: Alignment.centerLeft
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name),
                    PositionedDirectional( // was: Positioned
                      start: 8,           // was: left: 8
                      child: Badge(count: product.newCount),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Why:** Flutter's `EdgeInsets.only(left: 16)` hard-codes padding to the physical left side. In an app used in Arabic or Hebrew where `Directionality` is RTL, the padding appears on the wrong side. `EdgeInsetsDirectional.only(start: 16)` maps to physical-left in LTR and physical-right in RTL with zero conditional code. The same principle applies to `Alignment`, `Positioned`, and `BorderRadius` — always use the `Directional` variants.
