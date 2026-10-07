# STATE: Mini-Mart POS Project Synchronization

## Last Session
- **Environment**: Antigravity IDE
- **Timestamp**: 2026-10-07 18:54 (ICT)
- **Author**: Pair programming with Nha (Build Bright University, Year 4 Semester 2)
- **Team**: នី បញ្ញា, គក់ ស្រីផ្កាយ, គុយ ដាលី

## Tech Stack & Architecture Delivered
- **Flutter & Dart**: Mobile-first architecture with responsive breakpoints (`phone < 600px`, `tablet 600-1024px`, `desktop >= 1024px`).
- **State Management**: `flutter_riverpod` (v3.4.3) with `NotifierProvider` and `AsyncNotifierProvider`.
- **Navigation**: `go_router` (v18.0.2) with AuthGuard & Role-Based Guard (Admin vs Cashier).
- **Backend**: Firebase (`firebase_core`, `firebase_auth`, `cloud_firestore` with offline persistence enabled).
- **Project Connected**: Firebase `mart-pos-app` (Cloud Firestore in Test Mode, Email/Password enabled).
- **Localization**: Official `flutter_localizations` with `app_en.arb` and `app_km.arb` via `l10n.yaml`.

## Directory Structure
```
lib/
  main.dart                               # FlutterFire init, offline persistence, ProviderScope
  app.dart                                # MaterialApp.router, GoRouter, ThemeMode.system, Locales
  firebase_options.dart                   # Connected to mart-pos-app
  l10n/                                   # app_en.arb, app_km.arb, app_localizations.dart
  core/
    theme/                                # lightTheme, darkTheme, AppColors, AppRadius, AppTextStyles
    widgets/                              # AppButton, AppCard, AppSearchBar, EmptyState, QtyStepper, OfflineBar, PageHeader, MainShell
    utils/                                # money.dart (int riel rule), date.dart, responsive.dart
    router.dart                           # GoRouter with auth & role guards
  data/
    firestore/                            # FirestoreCollections withConverters for 10 models
      models/                             # 10 Models (user, category, product, productCode, customer, sale, heldBill, stockMovement, dailyClose, counter)
    repositories/                         # AuthRepository, ProductRepository, SaleRepository
    services/                             # InvoiceCounterService (online transaction, offline timestamp fallback)
  features/
    auth/                                 # LoginScreen (Responsive split-screen & mobile layout), AuthNotifier
    pos/                                  # PosScreen (Priority #1), PosCartNotifier (WriteBatch checkout, 1.5s debounce, strict stock)
    products/                             # ProductsScreen (toolbar, data table, mobile cards), ProductNotifier
    dashboard/                            # DashboardScreen (metric cards, fl_chart 30-day revenue, recent sales)
    inventory/                            # InventoryScreen (stock in/out movements stub)
    customers/                            # CustomersScreen (customer directory stub)
    reports/                              # ReportsScreen (daily close & shift stub)
    users/                                # UsersScreen (staff access control stub)
```

## Critical Rules Implemented
1. **MONEY RULE**: Stored strictly as `int` (riel). Displayed with `MoneyUtils.formatRiel` and `MoneyUtils.formatDual`.
2. **CHECKOUT WRITEBATCH**: Atomic batch write `sales` + `stockQty decrement` + `stockMovements` (offline-first).
3. **ANTI-DOUBLE-SCAN**: 1.5s (1500ms) debounce on barcode scanning.
4. **ROLE BOUNDARIES**: Strictly `ADMIN` and `CASHIER`. No admin manager.

## Quality & Tests
- `flutter test`: **All 4 tests passed** (`widget_test.dart`).
- `flutter analyze`: **0 Errors, 0 Warnings** (100% clean).
- Dev Server: Running on `http://localhost:35641`.

## GitHub Repository
- **URL**: `https://github.com/Ny-Panha/mart-pos`
- **Visibility**: Private
- **Branch**: `main`
