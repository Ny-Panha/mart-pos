# MART POS — Admin Manager Unified Design System

## 1. Design Principles

1. **Enterprise Clarity**: Immediate comprehension of business health, active operations, and urgent platform alerts.
2. **Anti-AI-Slop Discipline**:
   - Zero nested card borders (max 1 border level per view; flat horizontal rows with subtle dividers).
   - No neon drop-shadows or rainbow gradients.
   - One primary CTA per screen; secondary actions are quiet outline/ghost buttons.
   - Left & right alignment discipline with clean tabular figures for numerical data.
3. **Adaptive SaaS Architecture**:
   - Seamlessly responsive across 320px mobile to 1920px 4K displays.
   - Transforms complex tables into readable touch-optimized card stacks on narrow viewports.

---

## 2. Color System

### Brand Accent
- **Primary**: `#6D28D9` (Deep Royal Purple)
- **Primary Hover / Light**: `#7C3AED`
- **Primary Soft Background**: `#EDE9FE` (Light mode) / `#2E1065` (Dark mode)

### Light Theme Tokens
- **Background (`lightBg`)**: `#F7F8FA`
- **Surface / Card (`lightSurface`)**: `#FFFFFF`
- **Border (`lightBorder`)**: `#E2E8F0`
- **Primary Text**: `#0F172A` (Slate 900)
- **Secondary Text**: `#64748B` (Slate 500)
- **Muted Text**: `#94A3B8` (Slate 400)

### Dark Theme Tokens
- **Background (`darkBg`)**: `#10131B` (Deep Navy Charcoal)
- **Surface / Card (`darkSurface`)**: `#1A1F2B` (Elevated Charcoal)
- **Border (`darkBorder`)**: `#2D3442` (Subtle 1px border)
- **Primary Text**: `#F8FAFC` (Slate 50)
- **Secondary Text**: `#94A3B8` (Slate 400)
- **Muted Text**: `#64748B` (Slate 500)

### Semantic Status Tokens
- **Success / Active**: `#059669` (Emerald 600) | Soft: `#D1FAE5` / `#064E3B`
- **Warning / Low Stock**: `#D97706` (Amber 600) | Soft: `#FEF3C7` / `#78350F`
- **Danger / Suspended**: `#DC2626` (Red 600) | Soft: `#FEE2E2` / `#7F1D1D`
- **Neutral / Draft**: `#64748B` (Slate 500) | Soft: `#F1F5F9` / `#1E293B`

---

## 3. Typography Scale (Noto Sans Khmer + Inter/System)

All text uses the bundled `NotoSansKhmer` asset with 1.35x line height to prevent diacritic truncation:

| Token | Size | Weight | Line Height | Usage |
|-------|------|--------|-------------|-------|
| `Display / H1` | 26–30px | 800 (Bold) | 1.3 | Page Titles, Key Metrics |
| `Headline / H2`| 20–22px | 700 (Bold) | 1.35 | Section Headers, Modal Titles |
| `Title / H3`   | 16–18px | 600 (Semi-Bold) | 1.4 | Card Titles, Metric Labels |
| `Body Large`   | 15–16px | 500 (Medium) | 1.45 | Primary Content, Table Cells |
| `Body Small`   | 13–14px | 400 (Regular) | 1.45 | Descriptions, Secondary Rows |
| `Caption`      | 11–12px | 500/600 (Semi-Bold) | 1.3 | Badges, Timestamps, Subtitles |

---

## 4. Spacing & Shape Tokens

- **Base Grid**: 4px
- **Spacing Steps**: `4, 8, 12, 16, 20, 24, 32, 40`
- **Border Radii**:
  - `Card / Container`: 18px (Purrweb & Linear modern radius)
  - `Input / Button`: 12px
  - `Badge / Pill`: 9999px (Full rounded)
  - `Dialog / Bottom Sheet`: 24px (Top radius for bottom sheet)
- **Touch Targets**: Min 48×48 dp interactive hit area.

---

## 5. Standard Component Catalog

1. **`ManagerPageHeader`**:
   - Responsive flex/column header.
   - Khmer title + English subtitle.
   - Right-aligned actions row with primary CTA and secondary action buttons.
2. **`MetricCard`**:
   - Colored icon badge container (44×44 dp).
   - Label and optional context badge.
   - Large bold numeric value (24–28px) with `tabular-nums`.
3. **`ResponsiveDataTable`**:
   - Desktop: Clean, full-width table with sticky header, alternating subtle rows, and action column.
   - Mobile: Switches dynamically to a stacked card list with zero horizontal scrollbar requirement.
4. **`SearchFilterBar`**:
   - Integrated search text input with clear button.
   - Horizontal scrolling or wrapping filter chips for statuses (All, Active, Inactive, Low Stock, etc.).
5. **`ManagerEmptyState`**:
   - Centered icon with muted circular background.
   - Title explaining the empty situation.
   - Explanatory description.
   - Action button to create or navigate.
6. **`ManagerStatusChip`**:
   - Semantic color pill with dot indicator (Active, Suspended, Low Stock, In Stock).
7. **`ResponsiveFormDialog`**:
   - Renders as a centered dialog on desktop/tablet (max width 540dp).
   - Renders as an edge-to-edge bottom sheet on mobile (< 600dp) with keyboard-avoiding `SafeArea`.
