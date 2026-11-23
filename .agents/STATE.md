# STATE: Mini-Mart POS Project Synchronization

## Last Session
- **Environment**: Antigravity IDE
- **Timestamp**: 2026-11-23 21:46 (ICT)
- **Branch**: `fix/final-safety-repair`
- **Base Branch**: `fix/targeted-release-blockers` (Commit: `4f92b8136f4462ea75c3f4f6069f37f8eee3df80`)
- **Author**: Ny Panha & Antigravity

## Summary: Final Targeted Safety Repair

### 1. P0 — Isolated & Safe MySQL Test Suite (`MysqlConcurrencyAndIdempotencyTest.php`, `phpunit.xml`)
- **Hard Guard Against Live DB**: Added strict assertion enforcing that tests NEVER run against `mart_pos_db` or the application database. Tests fail immediately with `RuntimeException` if `DB_TEST_DATABASE` is missing, matches the app DB, or does not clearly end in `_test`.
- **Zero Hardcoded Credentials**: Database host, port, username, and password are read exclusively from environment variables (`DB_TEST_*` or `DB_*`).
- **Isolated Per-Run Fixtures & Cleanup**: Fixtures use unique per-run tokens (`runKey`). Cleanup in `tearDown` targets strictly entities belonging to the test run, avoiding sweeping deletions of shared database tables.
- **True Concurrency Testing**: Implemented `test_mysql_simultaneous_database_operations_with_independent_connections` using two independent MySQL sessions (`mysql` and `mysql_secondary`) to verify that MySQL `UNIQUE` index on `client_operation_id` rejects concurrent duplicates (error 23000) under separate transactions.

### 2. P0 — Durable Checkout Identity Persistence (`pos_cart_provider.dart`, `sale_repository.dart`)
- **Durable Identity**: Persists pending checkout `operationId`, `invoiceNumber`, full payload, and status (`idle`, `pending`, `confirmed`, `failed`) into `SharedPreferences`.
- **Restoration on Startup**: Provider restores unresolved operation state upon application boot via `restorePendingCheckout()`.
- **Pre-checkout Reconciliation**: Queries `GET /orders/by-operation/{opId}` prior to mutating backend or retrying, recovering confirmed orders seamlessly after dropped connections without duplicate sales.
- **Preserved Unresolved Identity**: `PosCartState.copyWith` prevents clearing active operation identity on cart alterations while an operation remains unresolved (`pending` or `failed`).
- **Concurrency Submission Lock**: Rejects overlapping checkout requests if `isCheckingOut` is already active.
- **Accurate Offline Messaging**: Removed false claims that offline checkouts are queued to cloud; updated `offline_bar.dart` and `pos_screen.dart` to clarify that an authoritative server connection is required.

### 3. P0 — Repaired Cash USD Payment (`sale_repository.dart`, `sale_model.dart`, `OrderController.php`)
- **Real USD Received Mapping**: Replaced hardcoded `'received_usd': '0.00'` with actual `received_usd` and `change_usd` values derived from tendered payment.
- **Positive Tendered Validation**: `OrderController` strictly rejects non-positive or insufficient USD received amounts for `cash_usd` payment method.
- **Flexible Currency Change**: Validates that change due is properly accounted for in USD, Khmer Riel (at 4,100 Riel/USD), or mixed combinations within standard rounding tolerances.
- **Idempotency Payload Check**: Updated `isEquivalentPayload` to compare `received_usd` and `change_usd` on retried `cash_usd` operations.

### 4. P1 — Preserved Purchase Idempotency (`purchase_repository.dart`, `purchase_form_dialog.dart`)
- **Stable Purchase Identity**: `PurchaseRepository.createPurchase` accepts optional `purchaseId` and `clientOperationId`, reusing existing identifiers across retries.
- **Dialog Retry Continuity**: `_PurchaseFormDialogState` retains `_activePurchaseId` so that retrying submission after a network timeout reuses the same operation identity.
- **Safe Cache Updates**: Never uses `FieldValue.increment` on replayed / already-recorded purchases; always favors exact authoritative stock quantities returned from MySQL.

### 5. P1 — Server-Side Tax Policy Enforcement (`OrderController.php`)
- **Deterministic Recalculation**: Explicitly validates `tax_rate` (0.0 to 0.30) against server-side subtotal and discount.
- **Inconsistent Amount Rejection**: Rejects client-provided `tax_riel` that diverges (> 2 Riel) from server-calculated tax with HTTP 422.
- **Tax Cap Guard**: Prevents applying tax on zero taxable base and caps implicit tax at 30%.

## Active Environment
- **Flutter App**: `e:\Project\flutter\project\mart_pos`
- **Laravel Backend**: `e:\Project\flutter\project\mart_pos\backend`
- **Backend API Server**: `http://localhost:8080`
- **MySQL Application Database**: `mart_pos_db` on `127.0.0.1:3306`
- **MySQL Dedicated Test Database**: `mart_pos_test` on `127.0.0.1:3306`

## Verification & Test Results
- `cd backend; php artisan test`: **All 24 tests passed (127 assertions)!**
  - Includes `MysqlConcurrencyAndIdempotencyTest` (isolated test DB guard, real MySQL transactions, multi-connection concurrency verification).
  - Includes `OrderAndInventoryTest` (cash USD flow, zero-USD rejection, inconsistent tax rejection, consistent tax success).
- `flutter analyze lib/`: **No issues found!** (ran in 5.7s)
- `flutter test`: **All 54 tests passed!**
  - Includes MoneyUtils, Role guards, Code uniqueness, Profit math, Stable checkout identity preservation across cart mutations, Cash USD model serialization, Purchase input guards, and Graceful network handling.

## Remaining Limitations
- Mart POS operates strictly with an authoritative MySQL backend for sales and inventory mutation. When offline, catalog browsing is available via cache, but sales transactions require an authoritative server connection because a full offline durable mutation outbox has not yet been built.
