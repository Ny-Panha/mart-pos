# STATE: Mini-Mart POS Project Synchronization

## Last Session
- **Environment**: Antigravity IDE
- **Timestamp**: 2026-10-07 20:33 (ICT)
- **Author**: Pair programming with Nha (Build Bright University, Year 4 Semester 2)
- **Team**: នី បញ្ញា, គក់ ស្រីផ្កាយ, គុយ ដាលី

## Summary: W4 — Customers + Reports + Dashboard Implementation
1. **Customers Feature**:
   - `CustomerRepository` ([customer_provider.dart](file:///home/kali/Desktop/mart_pos/lib/features/customers/providers/customer_provider.dart)): Extended with `updateCustomer`, `isCustomerInUse`, and `deleteCustomer` which blocks deletion when customer has sales records.
   - `CustomerFormDialog` ([customer_form_dialog.dart](file:///home/kali/Desktop/mart_pos/lib/features/customers/presentation/customer_form_dialog.dart)): Responsive modal (`Dialog` on desktop, `ModalBottomSheet` on mobile) for adding and editing client profiles.
   - `CustomersScreen` ([customers_screen.dart](file:///home/kali/Desktop/mart_pos/lib/features/customers/presentation/customers_screen.dart)): Live search, dual-currency total spent display, edit/delete actions, and deletion blocker dialog.
   - `SaleRepository.checkoutSale` ([sale_repository.dart](file:///home/kali/Desktop/mart_pos/lib/data/repositories/sale_repository.dart)): Automatically increments `totalSpent: FieldValue.increment(sale.total)` in the same atomic `WriteBatch` whenever `customerId` is present.
2. **Reports Feature**:
   - `ReportRepository` ([report_repository.dart](file:///home/kali/Desktop/mart_pos/lib/data/repositories/report_repository.dart)): `watchSalesRange` query and pure `calculateProfit` helper (`revenue - Σ(qty * costPrice)`).
   - Providers ([report_provider.dart](file:///home/kali/Desktop/mart_pos/lib/features/reports/providers/report_provider.dart)): Date range notifier (Today, 7 days, 30 days, Custom date range picker) and `reportSummaryProvider` (Revenue, Profit, Transactions, Avg ticket).
   - Shared `SaleListTile` & `SaleDetailDialog` ([widgets](file:///home/kali/Desktop/mart_pos/lib/features/reports/presentation/widgets)): Itemized invoice breakdown with subtotal, discount, VAT, paid, and change amount.
   - `ReportsScreen` ([reports_screen.dart](file:///home/kali/Desktop/mart_pos/lib/features/reports/presentation/reports_screen.dart)): Date range chips, 4 financial summary cards, and sales invoice feed.
3. **Dashboard Feature ([dashboard_screen.dart](file:///home/kali/Desktop/mart_pos/lib/features/dashboard/presentation/dashboard_screen.dart))**:
   - 4 Live Metric cards: Today's Revenue (៛ + $), Today's Orders, Total Products, and Low Stock Alerts (with 1-tap navigation to `/admin/inventory`).
   - 30-Day aggregated Bar Chart (`fl_chart`): Aggregates daily sales client-side with interactive tooltips showing date and Riel amounts.
   - Recent 5 Sales feed using `SaleListTile` with itemized modal dialog on tap and "See All" navigation to `/admin/reports`.
4. **Quality & Tests**:
   - `flutter analyze`: **0 issues found** (clean 100%).
   - `flutter test`: **All 15 tests passed** (including profit math test and customer delete blocker test).

## Active Branch & Git
- **Branch**: `feat/w4` (created from `main` after merging PR #2)
- **PR Target**: `main`
