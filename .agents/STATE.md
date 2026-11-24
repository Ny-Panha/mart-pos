# MART POS shared state

## Last Session

- Antigravity IDE · 2026-11-24 17:58 ICT
- Branch `ui/full-frontend-rebuild`

## Summary: Firebase Callable Serialization & Error Safety Fix

- **Root Cause & Permanent Fix**:
  - `functions.call('getPlatformDashboard')` previously passed Firestore `Timestamp` objects (`Timestamp.fromDate(from)`).
  - Firebase `HttpsCallable.call(parameters)` runs `assert(_debugIsValidParameterType(parameters))`, allowing only JSON primitive types (`String`, `num`, `bool`, `null`, `List`, `Map`).
  - Replaced parameters with UTC ISO 8601 strings: `from.toUtc().toIso8601String()` and `to.toUtc().toIso8601String()`.
- **Backend & Parity Verification (`functions/index.js`)**:
  - Verified backend `timestampFromInput(value)` parses ISO 8601 strings (`new Date(value)`).
  - Date range filtering `(!from || date >= from) && (!to || date <= to)` verified.
  - Added matching `from`/`to` date range filtering to Firestore fallback.
- **Error Handling Transparency**:
  - `FirebaseFunctionsException` with `unauthenticated`, `permission-denied`, or `invalid-argument` are explicitly rethrown, preventing silent fallback or masking of authentication/authorization failures.
  - Fallback errors rethrow clear error context rather than returning empty zero-state dashboards.
- **Verification & Regression Suite**:
  - Created `test/admin_manager_callable_serialization_test.dart` (3/3 passed).
  - `flutter test test/admin_manager_redesign_test.dart` (10/10 passed).
  - `flutter test test/widget_test.dart` (63/63 passed).
  - `flutter analyze`: **0 issues found**.

## Active Environment

- Flutter SDK: 3.x / Dart 3.x
- Backend: Laravel API on `http://localhost:8080`, MySQL on port 3306
- Platform Dashboard, Admin Operations, and POS Shell operational
- Current test URL: `http://localhost:44409/#/manager/dashboard`

## Next Steps

- Continue full frontend presentation rebuild across Cashier, Shop Admin, and Shared navigation layers.


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
