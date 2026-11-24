# MART POS — Admin Manager UI/UX Research Document

## 1. Executive Summary

This research document establishes the architectural and visual foundation for completely rebuilding the presentation layer of the MART POS **Admin Manager** (9 routes). The objective is to elevate the current interface from an unfinished prototype look into an enterprise-grade, modern SaaS platform and responsive mobile experience inspired by Apple HIG, Linear, Stripe Dashboard, Carbon Design System, and Purrweb.

Strict boundary: All backend contracts, Laravel APIs, Firestore schemas, role permissions, and checkout/POS business logic remain strictly untouched.

---

## 2. Product Design References & Findings

### 2.1 Apple Human Interface Guidelines (HIG)
- **Source**: https://developer.apple.com/design/human-interface-guidelines/
- **Key Principles**:
  - **Clarity & Visual Hierarchy**: Typography and negative space establish clear relationships before any borders or background fills.
  - **Touch Target Sizing**: Minimum interactive touch target of 44×44 pt (48×48 dp standard in Flutter/Android) to prevent mis-taps on mobile.
  - **Motion with Purpose**: Transitions communicate hierarchy and context (150–250ms ease-out). Respect user accessibility settings like `Reduce Motion`.
  - **Application to MART POS**:
    - Mobile buttons, table actions, and form inputs adhere to >= 48dp touch heights.
    - Motion uses subtle 150–200ms ease-out curves and respects `MediaQuery.disableAnimationsOf(context)`.

### 2.2 Material Design 3 (M3) & Flutter Adaptive Design
- **Source**: https://m3.material.io/ & https://docs.flutter.dev/ui/adaptive-responsive
- **Key Principles**:
  - **Adaptive Breakpoints**: Compact (< 600dp), Medium (600–840dp), Expanded (840–1200dp), Large (>= 1200dp).
  - **Navigation Adaptability**:
    - Compact (< 600dp): Bottom Navigation Bar + All Menu modal/screen.
    - Medium (600–840dp): Navigation Rail with icon + label.
    - Expanded / Large (>= 840dp): Persistent or Collapsible Sidebar Drawer.
  - **Application to MART POS**:
    - `main_shell.dart` adapts dynamically: desktop gets a sleek collapsible sidebar with grouped routes (Overview, Shops, Catalog, Platform), tablet gets an adaptive rail, and mobile retains a clean 4-tab bottom bar with an "All Menu" drawer/sheet for accessing all 9 routes seamlessly.

### 2.3 Linear & Stripe Dashboard Design Patterns
- **Source**: Linear App & Stripe Dashboard
- **Key Principles**:
  - **Quiet Surfaces**: Avoid neon drop-shadows and rainbow borders. Use subtle 1px border dividers (`#E2E8F0` light / `#2D3442` dark).
  - **Data Density & Tabular Numerals**: High-density display of counts, currencies, and dates with monospace/tabular alignment (`tabular-nums`).
  - **One Primary Action per View**: A single highlighted Primary CTA (e.g. "New Shop", "Add Administrator"), with secondary actions presented as quiet outline or ghost buttons.
  - **Application to MART POS**:
    - Standardize metrics on a unified `MetricCard` with clear label, prominent value (26–32px), and colored icon container.
    - Eliminate duplicate status badges and nested card-in-card borders.

### 2.4 Carbon Design System (IBM) — Enterprise Data Tables
- **Source**: https://carbondesignsystem.com/components/data-table/usage/
- **Key Principles**:
  - **Structured Toolbar**: Integrated search bar, active filter pills, and bulk/action buttons aligned on a single row above the table.
  - **Empty States with Direct CTA**: When a table is empty, do not display a collapsed corner box. Display a centered, well-spaced empty state explaining *why* it is empty and provide a clear primary button to initiate the first action (e.g., "Create First Shop").
  - **Responsive Grace**: On mobile, data tables transform into vertical card stacks rather than forcing users to scroll horizontally through tiny columns.
  - **Application to MART POS**:
    - Create `ResponsiveDataTable` and `ResponsiveEntityList` that automatically switch between a full-width desktop table and mobile card list.

### 2.5 Atlassian Design System — Empty & Error States
- **Source**: https://atlassian.design/components/empty-state/
- **Key Principles**:
  - **Action-Oriented Guidance**: An empty state must answer: 1) What is this space? 2) Why is it empty? 3) What can I do next?
  - **Application to MART POS**:
    - Admins screen: If 0 shops exist, explain: "No shops available. Administrator accounts must belong to a registered shop." with a direct button "Go to Shops".

### 2.6 Purrweb Mobile UI/UX Baseline
- **Source**: Reference Reel https://facebook.com/reel/1876971113736878/
- **Key Principles**:
  - Card radius of 18–24px with soft container backgrounds.
  - Monochromatic dark/light backgrounds (`#10131B` dark / `#F7F8FA` light) with purple `#6D28D9` as brand accent.
  - Smooth pill filters with instant visual feedback.

---

## 3. Audit of Existing 9 Admin Manager Screens

| # | Route | Current UI Problem | Target Solution |
|---|-------|-------------------|-----------------|
| 1 | `/manager` (Dashboard) | Metric cards oversized, lack visual hierarchy, empty space wasted on desktop, Cloud Functions assertion crash on unhandled DateTime types. | 4-col desktop / 2-col mobile adaptive grid, compact metric cards, live revenue overview, full-width recent shops & alerts, resilient Firestore fallback. |
| 2 | `/manager/shops` | Tiny empty state in corner, basic list with limited status differentiation. | Responsive data table on desktop, stacked cards on mobile, search + plan filter chips, comprehensive empty state with "Add Shop" CTA. |
| 3 | `/manager/admins` | Confusing when no shops exist; lack of owner vs cashier role distinction. | Avatar initials, status badge, shop association pill, empty state with guidance to create shop first. |
| 4 | `/manager/locations` | Basic dialog and plain card list lacking branch management feel. | Clean branch cards with address/phone/status icons, responsive modal/bottom sheet for add/edit. |
| 5 | `/manager/subscriptions` | Minimal empty state, lacks summary indicators. | Plan tier cards (Free, Basic, Pro, Enterprise), seat count indicators, status pills, filter by active/expired. |
| 6 | `/manager/stock` | Narrow table with poor desktop space utilization, text clipping. | Full-width data table on desktop, low-stock highlight pills, compact mobile cards, search by name/SKU/barcode. |
| 7 | `/manager/products` | Looks identical to stock overview, no product images. | Product catalog grid or rich list with image thumbnails, category tags, price in USD & Riel, stock status. |
| 8 | `/manager/reports` | Oversized primitive chart without axes or readable tooltips, lacks date filter context. | Compact operational KPI row, responsive spline/bar chart with clear date axes, currency tooltips, transaction breakdown. |
| 9 | `/manager/system` | Fixed-height empty containers for Logs, Alerts, Health, Settings; confusing tabs. | Content-adaptive tabs with animated switching; readable severity badges for logs; interactive resolve actions for alerts; categorized platform toggles with save feedback. |

---

## 4. Technical Architecture & Performance Strategy

1. **Rendering Performance**:
   - Prefer `const` widgets everywhere.
   - Use `ListView.builder` / `SliverList` for unbounded lists to avoid layout passes over off-screen items.
   - Avoid nesting scroll views without proper constraints (no arbitrary `shrinkWrap: true`).
2. **Khmer Typography & Localization**:
   - Use the bundled `NotoSansKhmer` font with appropriate `lineHeight` (1.3 to 1.4) to ensure Khmer vowel/subscript diacritics are never clipped.
   - Pair Khmer titles with clean English subtitles for bilingual SaaS clarity.
3. **Motion Architecture**:
   - Durations: Buttons (100–150ms), Tabs & Filters (200–250ms), Page/Sheet transitions (250–300ms).
   - Use `AnimatedSwitcher` and `AnimatedContainer` with standard `Curves.easeInOutCubic`.
   - Wrap animations to honor `MediaQuery.disableAnimationsOf(context)`.

---

## 5. Implementation Roadmap

1. **Phase 1**: Research & Specifications (Completed).
2. **Phase 2**: Central Design Tokens & Presentation Components (`docs/design/DESIGN-SYSTEM.md` & `manager_widgets.dart`).
3. **Phase 3**: Navigation Shell & Platform Dashboard Rebuild (`main_shell.dart` & `admin_manager_dashboard_screen.dart`).
4. **Phase 4**: Core Operations Rebuild (`admin_manager_operations_screens.dart` — Shops, Admins, Locations, Subscriptions).
5. **Phase 5**: Inventory & Catalog Rebuild (`Stock Overview`, `Global Products`).
6. **Phase 6**: Analytics & System Operations Rebuild (`admin_manager_reports_screen.dart`, `admin_manager_system_screen.dart`).
7. **Phase 7**: Automated Verification & Visual Testing (Golden tests, `flutter analyze`, `flutter test`, responsive verification).
8. **Phase 8**: Acceptance Documentation & Git Integration (`UI-ACCEPTANCE-REPORT.md`, commit and push).
