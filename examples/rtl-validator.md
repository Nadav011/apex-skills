# rtl-validator — Real-World Examples

The skill enforces APEX Law #5 (RTL-FIRST): zero tolerance for physical
directional CSS properties. Every violation here breaks layout in Hebrew or
Arabic UIs.

## Before / After

### Example 1: Sidebar navigation with active-item indicator

**Before** (triggers the skill):
```tsx
// ❌ 6 RTL violations — sidebar renders mirrored in Hebrew
<nav className="fixed left-0 top-0 h-screen w-64 border-r bg-white shadow-lg">
  <ul className="mt-6 space-y-1">
    <li className="border-l-4 border-l-blue-600 bg-blue-50 pl-4 pr-3 py-2">
      <span className="text-left font-semibold text-blue-700">Dashboard</span>
    </li>
    <li className="pl-4 pr-3 py-2 text-gray-600 hover:bg-gray-50">
      <span className="text-left">Settings</span>
    </li>
  </ul>
</nav>
```

**After** (skill-compliant):
```tsx
// ✅ Logical properties — sidebar renders correctly in both LTR and RTL
<nav className="fixed inset-s-0 top-0 h-screen w-64 border-e bg-white shadow-lg">
  <ul className="mt-6 space-y-1">
    <li className="border-s-4 border-s-blue-600 bg-blue-50 ps-4 pe-3 py-2">
      <span className="text-start font-semibold text-blue-700">Dashboard</span>
    </li>
    <li className="ps-4 pe-3 py-2 text-gray-600 hover:bg-gray-50">
      <span className="text-start">Settings</span>
    </li>
  </ul>
</nav>
```

**Why:** `fixed left-0` pins the sidebar to the physical left edge — in RTL this
means it overlaps the content instead of sitting at the reading start. `border-l`
/ `pl-` also flip to the wrong side. Logical equivalents (`inset-s-0`, `border-s`,
`ps-`) automatically adapt to the document direction.

---

### Example 2: Product card with price and navigation arrow

**Before** (triggers the skill):
```tsx
// ❌ Physical margin, text alignment, and missing icon flip
function ProductCard({ name, price }: { name: string; price: number }) {
  return (
    <div className="rounded-lg border p-4">
      <h3 className="text-left font-bold text-gray-900">{name}</h3>
      <p className="ml-2 mt-1 text-gray-500">In stock</p>
      <div className="mt-4 flex items-center justify-between">
        <span className="text-right font-mono text-lg">₪{price}</span>
        <button className="flex items-center gap-1 text-blue-600">
          View details
          <ChevronRight className="h-4 w-4" />
        </button>
      </div>
    </div>
  );
}
```

**After** (skill-compliant):
```tsx
// ✅ Logical classes + LTR-isolated price + flipped directional icon
function ProductCard({ name, price }: { name: string; price: number }) {
  return (
    <div className="rounded-lg border p-4">
      <h3 className="text-start font-bold text-gray-900">{name}</h3>
      <p className="ms-2 mt-1 text-gray-500">In stock</p>
      <div className="mt-4 flex items-center justify-between">
        {/* Numbers are always LTR regardless of page direction */}
        <span dir="ltr" className="text-end font-mono text-lg">₪{price}</span>
        <button className="flex items-center gap-1 text-blue-600">
          View details
          <ChevronRight className="h-4 w-4 rtl:rotate-180" />
        </button>
      </div>
    </div>
  );
}
```

**Why:** `text-left` hard-codes reading direction, `ml-2` adds margin on the
wrong side in RTL, and the `ChevronRight` arrow points the wrong way without
`rtl:rotate-180`. The price needs `dir="ltr"` so the currency symbol and digits
always read left-to-right regardless of page direction.

---

### Example 3: Inline styles and CSS-in-JS with physical properties

**Before** (triggers the skill):
```tsx
// ❌ Physical properties in both styled-component and inline style
const TooltipContainer = styled.div`
  position: absolute;
  right: 100%;
  margin-right: 8px;
  border-left: 2px solid #e5e7eb;
  padding-left: 12px;
`;

function Tooltip({ children }: { children: React.ReactNode }) {
  return (
    <TooltipContainer>
      <div style={{ marginLeft: 8, paddingRight: 12 }}>
        {children}
      </div>
    </TooltipContainer>
  );
}
```

**After** (skill-compliant):
```tsx
// ✅ CSS logical properties in both styled-component and inline style
const TooltipContainer = styled.div`
  position: absolute;
  inset-inline-end: 100%;
  margin-inline-end: 8px;
  border-inline-start: 2px solid #e5e7eb;
  padding-inline-start: 12px;
`;

function Tooltip({ children }: { children: React.ReactNode }) {
  return (
    <TooltipContainer>
      <div style={{ marginInlineStart: 8, paddingInlineEnd: 12 }}>
        {children}
      </div>
    </TooltipContainer>
  );
}
```

**Why:** Physical properties (`right`, `margin-right`, `border-left`,
`padding-left`) in CSS-in-JS are just as broken as Tailwind violations — the
browser does not auto-flip them in RTL mode. CSS logical properties
(`inset-inline-end`, `margin-inline-end`, `border-inline-start`,
`padding-inline-start`) are the only correct approach regardless of the styling
library used.
