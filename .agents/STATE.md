# STATE: Mini-Mart POS Project Synchronization

## Last Session
- **Environment**: Antigravity IDE
- **Timestamp**: 2026-10-07 19:50 (ICT)
- **Author**: Pair programming with Nha (Build Bright University, Year 4 Semester 2)
- **Team**: នី បញ្ញា, គក់ ស្រីផ្កាយ, គុយ ដាលី

## Summary of Recent Fixes & Wiring (POS Screen Review)
1. **BUG Fixed - `cashierId` UID Storage**:
   - `lib/features/pos/presentation/pos_screen.dart`: Changed `user?.name` to `user?.id ?? 'cashier_unknown'`. Sale invoices now correctly link to the authenticated user's Firebase UID.
2. **Interactive Payment Dialog**:
   - Implemented `lib/features/pos/presentation/payment_dialog.dart`.
   - Supports Cash payment with exact amount button, quick Riel/USD chips (+5,000៛, +10,000៛, +20,000៛, +50,000៛, $5, $10, $20), and live dual-currency change calculation (អាប់ជូន).
   - Supports Bakong KHQR QR-code tab.
   - Shows detailed confirmation receipt dialog with print trigger upon sale completion.
3. **Interactive Customer Selector**:
   - Made customer container tappable in the POS Cart panel.
   - Added `_showCustomerSelectorDialog()` with real-time search, Walk-in customer option (`customerId: null`), and list of registered customers via `customersStreamProvider`.
   - Added `_showAddCustomerDialog()` backed by `CustomerRepository.createCustomer` for fast on-the-spot customer registration.
4. **Discount & Tax Wiring**:
   - Made Discount row tappable with editable dialog + quick chips (0៛, 1,000៛, 2,000៛, 5,000៛, 10,000៛).
   - Added interactive Tax / VAT rate selector dialog (0%, 5%, 10% VAT), recalculating cart totals in real-time.
5. **Cleaned Physics**:
   - Replaced custom `NeverScrollableScrollExceptionStream` with standard Flutter `NeverScrollableScrollPhysics` across `pos_screen.dart`, `dashboard_screen.dart`, and `products_screen.dart`.

## Tech Stack & Architecture
- **Flutter & Dart**: Mobile-first architecture with responsive breakpoints (`phone < 600px`, `tablet 600-1024px`, `desktop >= 1024px`).
- **State Management**: `flutter_riverpod` (v3.4.3) with `NotifierProvider` and `AsyncNotifierProvider`.
- **Navigation**: `go_router` (v18.0.2) with AuthGuard & Role-Based Guard (Admin vs Cashier).
- **Backend**: Firebase (`firebase_core`, `firebase_auth`, `cloud_firestore` with offline persistence enabled).
- **Project Connected**: Firebase `mart-pos-app` (Cloud Firestore in Test Mode, Email/Password enabled).
- **Localization**: Official `flutter_localizations` with `app_en.arb` and `app_km.arb` via `l10n.yaml`.

## Quality & Tests
- `flutter test`: **All 4 tests passed** (`widget_test.dart`).
- `flutter analyze`: **No issues found!** (0 Errors, 0 Warnings, 0 Infos).
- Dev Server: Running on `http://localhost:35641`.

## GitHub Repository
- **URL**: `https://github.com/Ny-Panha/mart-pos`
- **Visibility**: Private
- **Branch**: `main`
