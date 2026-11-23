# STATE: Mini-Mart POS Project Synchronization

## Last Session
- **Environment**: Antigravity IDE
- **Timestamp**: 2026-11-23 22:45 (ICT)
- **Branch**: `fix/final-safety-repair`
- **Base Branch**: `fix/targeted-release-blockers` (Commit: `4f92b8136f4462ea75c3f4f6069f37f8eee3df80`)
- **Author**: Ny Panha & Antigravity

## Summary: Final Targeted Safety Repair & Acceptance Items

### 1. P0 — Isolated & Real MySQL Concurrency Test Suite (`MysqlConcurrencyAndIdempotencyTest.php`)
- **Strict Test Database Safety**: Verified tests only execute on `mart_pos_test` (rejecting live app DBs).
- **True In-Flight Concurrency Tests Across Independent Connections**:
  - `test_mysql_concurrent_in_flight_transactions_and_unique_key_collision`: Connection 1 starts transaction and inserts `client_operation_id` without committing; Connection 2 attempts simultaneous insert and is blocked by InnoDB unique key row-lock wait; Connection 1 commits; Connection 2 unblocks and permanently fails with error 23000 (duplicate entry).
  - `test_mysql_concurrent_pessimistic_row_locking_prevents_stock_double_spend`: Connection 1 acquires pessimistic row lock with `lockForUpdate`; Connection 2 attempts simultaneous `lockForUpdate` and waits; Connection 1 decrements stock to 0 and commits; Connection 2 receives lock and safely detects 0 remaining stock, preventing double-spend.

### 2. P0 — Complete Checkout Recovery & Cart Mutation Lock (`pos_cart_provider.dart`, `sale_repository.dart`)
- **Full Cart Payload Restoration**: When recovering an unresolved checkout on app boot, restores not only `operation_id` and `invoice_number`, but also the full serialized cart draft and items (`_serializeCartDraft`, `_prefPendingCartDraft`), ensuring retried operations have identical payload and exact verification data.
- **Cart Mutation Guard**: While a checkout operation is unresolved (`isPendingUnresolved`), all cart modifications (`addProduct`, `updateQty`, `removeProduct`, `clearCart`) are strictly blocked with an actionable error message, preventing payload drift and idempotency conflicts.
- **Unresolved Checkout Banner**: UI banner allows the cashier to Reconcile with the backend, Retry payment with the exact restored payload, or Dismiss the unresolved state.

### 3. P0 — Real Cash USD Input & Dual-Currency Change Flow (`payment_dialog.dart`, `pos_screen.dart`)
- **3-Tab Payment Dialog**: Supports `Cash (៛ KHR)`, `Cash ($ USD)`, and `Bakong KHQR`.
- **Live Dual-Currency Conversion**: When Cash USD is selected, calculates required USD at 4,100 Riel/USD, accepts tendered USD amount with quick chips ($5, $10, $20, $50, $100), and computes change due in both USD and Khmer Riel.
- **Backend Dispatch**: Passes accurate `paymentMethod: 'cash_usd'`, `receivedUsd`, and `changeUsd` to `SaleRepository.createSale`.

### 4. P1 — Preserved Purchase Idempotency & Server-Side Tax Policy
- Stable purchase identity and server-side tax recalculation within 30% cap.

## Active Environment
- **Flutter App**: `e:\Project\flutter\project\mart_pos`
- **Laravel Backend**: `e:\Project\flutter\project\mart_pos\backend`
- **Backend API Server**: `http://localhost:8080`
- **MySQL Application Database**: `mart_pos_db` on `127.0.0.1:3306`
- **MySQL Dedicated Test Database**: `mart_pos_test` on `127.0.0.1:3306`

## Verification & Test Results
- `cd backend; php artisan test`: **All 25 tests passed (132 assertions)!**
  - Concurrency tests verify InnoDB lock wait, unique key collision, and pessimistic row locking under independent connections.
- `flutter analyze lib/`: **No issues found!** (ran in 2.2s)
- `flutter test`: **All 56 tests passed!**
  - Includes tests verifying cart mutation blocking while checkout is unresolved, Cash USD 4,100 exchange rate and change calculation, MoneyUtils, role routes, idempotency recovery, and graceful network failure.

## Remaining Limitations
- Mart POS operates strictly with an authoritative MySQL backend for sales and inventory mutation. When offline, catalog browsing is available via cache, but sales transactions require an authoritative server connection because a full offline durable mutation outbox has not yet been built.
