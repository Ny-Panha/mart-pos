# MART POS shared state

## Last Session

- Codex CLI · 2026-11-24 11:45 ICT
- Branch `ui/premium-pos-redesign`, based on `fix/final-safety-repair` at `b77de897e5c2a0138ab9db319611999ddc753503`.

## Summary

- Redesigned the POS product browser, cart and payment dialog. Mobile has separate catalog and cart views with sticky actions. Desktop uses two panes. The existing app theme loads bundled Noto Sans Khmer assets.
- Search, barcode entry, recent scans, category filters, customer selection, line-price overrides, quantity entry, tax and discount controls use the existing providers. Unresolved checkouts expose the existing reconciliation, retry and dismissal paths.
- `flutter analyze` passed. `flutter test` passed all 81 tests, including 14 new POS widget tests. The cashier shell was exercised at 320, 360, 390, 430, 768, 1024 and 1440 logical pixels, including payment with keyboard insets.
- Captured and inspected five Flutter-rendered screens in `docs/screenshots/pos/`. The widget harness uses a snapshot of local API products and categories, a test cashier and an open-shift fixture. To regenerate, run `flutter test --update-goldens test/pos_redesign_test.dart`.

## Active Environment

- Local Laravel API at `http://localhost:8080` served the catalog. MySQL was listening on port 3306.
- The screenshots use Flutter's test renderer. No sale was submitted to the live backend during UI verification.

## Next Steps

- Physical-device camera scanning and live payment settlement were outside the widget test run.
- The workspace contains prior edits in `backend/database/seeders/DatabaseSeeder.php` and `lib/features/admin_manager/data/admin_manager_service.dart`, excluded from this branch commit.

## Previous Session

- **Environment**: Antigravity IDE
- **Timestamp**: 2026-11-24 00:05 (ICT)
- **Branch**: `fix/final-safety-repair`
- **Base Branch**: `fix/targeted-release-blockers`
- **Author**: Ny Panha & Antigravity

## Summary: Cancelled Operation Status Fix & Safety Hardening

### 1. Authoritative Backend Communication (`backend/app/Http/Controllers/Api/OrderController.php`)
- `GET /api/orders/by-operation/{opId}` explicitly communicates operation status:
  - For completed orders: `"operation_status": "completed"`
  - For cancelled tombstones: `"operation_status": "cancelled"`, message `"Operation was cancelled and not committed as a sale."`
- `resolveIdempotentOrder()` strictly prevents committing retried checkout attempts when `status === 'cancelled'`, returning HTTP 409 Conflict.
- Verified in `backend/tests/Feature/OrderAndInventoryTest.php` (`test_abort_operation_tombstones_operation_and_prevents_commit`).

### 2. Flutter Operation Resolution Distinction (`lib/data/repositories/sale_repository.dart`)
- `OperationResolution` enum explicitly distinguishes `completed`, `cancelled`, `notFound`, and `unknown` (with `confirmed = completed` alias).
- `resolveOperationStatus()` checks both `operation_status` and `order.status` to return `OperationResolution.cancelled`.
- `checkOperationStatus()` convenience wrapper returns `null` for cancelled operations, preventing callers from interpreting tombstones as valid orders.

### 3. Tombstone Firestore Rejection & No Receipt / Spending Updates (`sale_repository.dart`, `pos_cart_provider.dart`)
- `reconcileConfirmedOrder()` strictly guards against cancelled operations, aborting before Firestore writes (no sales document, no stock movement, no customer spending increment).
- `restorePendingCheckout()`: when encountering a cancelled operation upon app restart:
  - Clears persisted pending checkout from SharedPreferences.
  - Resets cart state to idle with `lastCompletedInvoice == null` (zero spurious receipts).
  - Skips Firestore cache reconciliation completely.
- `reconcileActiveCheckout()` safely clears pending checkout and resets cart to idle on cancelled status.

### 4. Cancelled Checkout Retry Lockout (`pos_cart_provider.dart`)
- `checkout()` inspects `resolveOperationStatus()` prior to retrying.
- If the operation is cancelled, it clears pending checkout, resets checking-out flag, and throws an exception, blocking retries from creating or confirming sales.

### 5. Comprehensive Regression Suite (`test/widget_test.dart`)
- Added end-to-end regression test:
  1. Abort operation successfully via `saleRepo.abortOperation()`.
  2. GET operation returns `OperationResolution.cancelled`.
  3. Seed persisted pending state and restart Flutter (`restorePendingCheckout()`).
  4. Verify `lastCompletedInvoice == null`, status is idle, and pending state is cleared from SharedPreferences.
  5. Verify `reconcileConfirmedOrder()` refuses to write cancelled orders.
  6. Verify checkout retry with cancelled operation throws exception and is blocked.

## Active Environment
- **Flutter App**: `e:\Project\flutter\project\mart_pos`
- **Laravel Backend**: `e:\Project\flutter\project\mart_pos\backend`
- **Backend API Server**: `http://localhost:8080`
- **MySQL Application Database**: `mart_pos_db` on `127.0.0.1:3306`
- **MySQL Dedicated Test Database**: `mart_pos_test` on `127.0.0.1:3306`

## Verification & Test Results
- `cd backend; php artisan test`: **All 27 tests passed (143 assertions)!**
- `flutter analyze`: **No issues found!** (ran in 5.1s)
- `flutter test`: **All 67 tests passed!** (100% passed across all unit and widget tests)

## Remaining Limitations
- Mart POS operates strictly with an authoritative MySQL backend for sales and inventory mutation. When offline, catalog browsing is available via cache, but sales transactions require an authoritative server connection.
