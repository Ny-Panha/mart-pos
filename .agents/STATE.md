# STATE: Mini-Mart POS Project Synchronization

## Last Session
- **Environment**: Antigravity IDE
- **Timestamp**: 2026-11-23 21:13 (ICT)
- **Branch**: `fix/targeted-release-blockers`
- **Base Branch**: `fix/p0-p1-regressions` (Commit: `1d8d67c967b510fd21538b634e0cf69a15307523`)
- **Author**: Ny Panha & Antigravity

## Summary: Targeted Release-Blocker Repair

### 1. P0 — Stable Checkout Operation Identity (Flutter)
- **Durable Identity**: `PosCartState` now tracks `activeOperationId` and `activeInvoiceNumber`. These are preserved across network timeouts, application re-renders, and failed checkout attempts.
- **Pre-retry Reconciliation**: In `PosCartNotifier.checkout`, before issuing a checkout mutation, the client queries `GET /orders/by-operation/{opId}`. If the order was already recorded by Laravel (e.g. response was lost due to network drop), the client reconciles the confirmed invoice, updates the local cache idempotently, clears the cart, and completes payment without duplicate orders.
- **Cart & Operation Reset**: Any cart item modification, quantity change, customer update, discount, or tax change automatically clears `activeOperationId` (`clearActiveOperation: true`) to avoid reusing operation IDs for altered payloads.

### 2. P0 — Secure Idempotency Recovery (Laravel)
- **Unified Recovery Path**: In `OrderController.php`, unified all recovery points (pre-transaction lookup, transaction row-lock check, and `QueryException` catch block) through a single `resolveIdempotentOrder` method.
- **Canonical Payload Validation**: `isEquivalentPayload` validates total amount, discount, tax, payment method, tendered amount, change amount, and line item quantities/prices.
- **Strict Ownership & Conflict Handling**: Cross-user operation ID reuse returns HTTP 403 Forbidden. Conflicting payloads return HTTP 409 Conflict. Identical retries return HTTP 200 OK idempotent recovery.

### 3. P1 — Totals and Payment Verification (Laravel)
- **Server-side Tax Policy**: Explicitly validates `tax_rate` (0.0 to 0.30) and calculates expected tax server-side. Arbitrary client-provided tax amounts exceeding policy limits (> 25% of subtotal) are rejected with HTTP 422.
- **Multi-currency & Method Validation**:
  - `khqr`: Requires exact received amount and zero change.
  - `cash_riel` / `cash`: Requires `received_riel >= total_riel` and exact change calculation.
  - `cash_usd`: Converts totals using standard 4100 Riel/USD rate, validates USD tendered and change amounts in USD or Riel.
  - Unsupported payment methods (e.g. `crypto`, `bitcoin`) are rejected with HTTP 422.

### 4. P1 — Inventory Database Idempotency (Laravel & MySQL)
- **Database Unique Constraint**: Created `inventory_operations` migration and model with a unique constraint on `client_operation_id`.
- **Database-level Mutation Guards**: All stock mutations (`stockIn`, `stockOut`, `adjustStock`, `purchase`) require `client_operation_id` (min 8 chars) and record an `InventoryOperation`.
- **Conflict Prevention**: Concurrent retries and reuse with conflicting products, quantities, or operation types are rejected with HTTP 409 Conflict or HTTP 403 Forbidden without mutating stock twice.

### 5. P1 — Cache Reconciliation & Reports (Flutter & Laravel)
- **Idempotent Firestore Reconciliation**: Replaced additive cache writes in `sale_repository.dart` and `purchase_repository.dart`. Customer `totalSpent` is only incremented if the sale was not already confirmed in Firestore.
- **Deterministic Movement IDs**: Uses deterministic Firestore document IDs (`opId` and `po_${purchaseId}_${item.productId}`) to prevent duplicate stock movements upon retry.
- **Server-confirmed Stock Updates**: Reconciles local product cache with exact server-returned `stock_qty`.
- **Authoritative Reports**: `ReportController::summary` calculates authoritative sales, orders, and net profit from MySQL `orders` and `order_items` over requested date periods. Added `ReportRepository.getAuthoritativeSummary`.

## Active Environment
- **Flutter App**: `e:\Project\flutter\project\mart_pos`
- **Laravel Backend**: `e:\Project\flutter\project\mart_pos\backend`
- **Backend API Server**: `http://localhost:8080` (or `API_BASE_URL` env variable)
- **MySQL Database**: `mart_pos_db` on `127.0.0.1:3306`

## Verification & Test Results
- `flutter analyze lib/`: **No issues found!** (ran in 9.4s)
- `flutter test`: **All 52 tests passed!** (Including MoneyUtils, Role guards, Code uniqueness, Profit math, Stable checkout identity preservation, and Graceful network handling)
- `cd backend; php artisan test`: **All 23 tests passed (123 assertions)!**
  - Includes isolated MySQL concurrency & database uniqueness tests: `MysqlConcurrencyAndIdempotencyTest` (testing real MySQL transactions and UNIQUE constraint on `inventory_operations.client_operation_id`).
  - Includes `OrderAndInventoryTest` covering lookup by operation ID, server-side tax limits, cash USD flow, and inventory idempotency.

## Next Steps
- Commit all changes to review branch `fix/targeted-release-blockers`.
- Push branch to origin.
- Do NOT merge into `main`.
