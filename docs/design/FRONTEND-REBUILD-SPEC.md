# MART POS — Frontend Rebuild Architecture & Specification

## 1. Executive Summary & Design Principles

MART POS is rebuilt from the ground up as a high-performance, modern multi-tenant Point-of-Sale and Retail Management platform. The new architecture transitions away from legacy generic dashboards into a bespoke, precision-crafted retail command center inspired by:
- **Linear**: High visual density, subtle 1px dividers, zero neon glow, unified command & search.
- **Stripe**: Enterprise-grade financial transparency, tabular numbers, status badge consistency.
- **Shopify & Square POS**: Rapid touch-first checkout, split-screen POS catalog & cart, instant KHQR/Cash tenders, offline safety.
- **Apple HIG & Purrweb**: Ergonomic 48px touch targets, fluid bottom sheets, purposeful hierarchy, and native Khmer/English typography.

---

## 2. Design Tokens & Sensory Foundations

### 2.1 Color Architecture (Semantic Discipline)
- **Brand Violet**: Primary `#6D28D9` / Electric `#7C3AED` / Container `#EDE9FE`
- **Surface Canvas (Light)**: Background `#F8FAFC`, Surface `#FFFFFF`, Elevated `#FFFFFF`, Borders `#E2E8F0`
- **Surface Canvas (Dark)**: Background `#0A0D14`, Surface `#111622`, Elevated `#182030`, Borders `#1F293D`
- **Functional Semantics**:
  - Emerald (`#10B981`): In-stock, Paid, Completed sales, Active status.
  - Amber (`#F59E0B`): Low-stock warning, Pending checkout, Draft.
  - Rose (`#EF4444`): Out-of-stock, Cancelled, Debt/Due, Destructive actions.
  - Sky Blue (`#0EA5E9`): Active session, Location branch, Shift open.

### 2.2 Typography Scale (Noto Sans Khmer + Inter)
- Display: 28px / 36px line-height, Weight 800
- Title: 20px / 28px line-height, Weight 700
- Body Strong: 14px / 20px line-height, Weight 600
- Body Regular: 13.5px / 19px line-height, Weight 400
- Caption: 11px / 16px line-height, Weight 500
- Monospace Tabular: Numbers, barcodes, SKU, and monetary values use aligned widths.

### 2.3 Motion System
- Duration: 150ms–200ms for button clicks, chip selections, hover states.
- Transition: 240ms ease-out cubic curve `(0.16, 1, 0.3, 1)` for navigation transitions, modals, and sheets.
- Reduced Motion: Respects OS accessibility settings.

---

## 3. Navigation & Shell Architecture

### 3.1 Adaptive Split
- **Desktop (width >= 1024px)**:
  - Collapsible side navigation rail (width 260px expanded, 78px collapsed).
  - Top app header with search trigger, shop switcher, theme toggle, and user profile pill.
  - Unconstrained body with responsive column grids.
- **Tablet (650px <= width < 1024px)**:
  - Compact icon rail navigation (width 80px) or responsive drawer.
  - Dual-pane layout where appropriate (e.g. Catalog + Cart).
- **Mobile (width < 650px)**:
  - Ergonomic bottom navigation bar (3 primary actions + "All Menu" launcher).
  - Modern gesture-driven bottom sheet modal for remaining system operations.
  - Full-screen push dialogs with top cancel/done bars.

---

## 4. Screen Architecture by Role

### 4.1 Platform Manager
1. `/manager`: 8-metric adaptive KPI grid, recent shop ledger, critical system alerts.
2. `/manager/shops`: Dual-mode table/cards with instant provisioning modal.
3. `/manager/admins`: Shop admin management, credential resets, shop assignment.
4. `/manager/locations`: Multi-branch overview with map/contact badges.
5. `/manager/subscriptions`: Tier matrix (Basic, Pro, Enterprise) and seat allocations.
6. `/manager/stock`: Multi-shop inventory health ledger and out-of-stock emergency alerts.
7. `/manager/products`: Cross-shop visual merchandising catalog with category pills, shop filter, and photo viewer.
8. `/manager/reports`: Revenue line charts, daily transactions, volume breakdown.
9. `/manager/system`: Audit logs, service health, and platform killswitches.

### 4.2 Shop Admin
1. `/admin`: Business cockpit, today's sales, gross profit, low stock notifications, fast actions.
2. `/admin/products`: Product catalog management, category tabs, photo upload, barcode scanner integration.
3. `/admin/inventory`: Stock adjustments, transfer history, inward/outward ledger.
4. `/admin/purchases`: Purchase order tracking, supplier bills, status pipeline.
5. `/admin/suppliers`: Supplier directory, contact cards, order history.
6. `/admin/customers`: Customer CRM, loyalty tiers, outstanding credit ledger.
7. `/admin/reports`: Sales analytics, product velocity, cashier performance reports.
8. `/admin/users`: Cashier & staff accounts, shift assignments, PIN/password resets.
9. `/admin/attendance`: Timeclock records, clock-in/out timestamps, hours worked.
10. `/admin/notifications`: System alerts, low stock reminders, daily summaries.
11. `/admin/audit-log`: Immutable security trail of sensitive store operations.
12. `/admin/settings`: Store metadata, currency defaults (KHR/USD), tax, receipt customization.

### 4.3 Cashier POS
1. `/pos`: Responsive split view (Catalog grid on left, sticky Order Cart on right on desktop; tabbed/sheet on mobile).
2. Cart: Quantity steppers, line-item notes, discounts, instant subtotal.
3. Checkout & Payment: Slide-out sheet with dual-currency calculations (៛ Riel & $ USD), quick cash denominations, KHQR QR-code generator, receipt print.
4. `/cashier/history`: Daily invoice list with reprint & refund triggers.
5. `/cashier/stock`: Fast in-store price & stock lookup by barcode/name.
6. `/cashier/shift`: Cash drawer float, opening count, cash movements, end-of-day z-report.
