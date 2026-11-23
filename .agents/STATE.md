# STATE: Mini-Mart POS Project Synchronization

## Last Session
- **Environment**: Antigravity IDE
- **Timestamp**: 2026-11-23 20:55 (ICT)
- **Branch**: `fix/p0-p1-regressions`
- **Base Branch**: `fix/safe-backend-integration` (Commit: `18819911be23bc8e3c54e37b245dd4854618b9c1`)
- **Author**: Ny Panha & Antigravity

## Summary: Post-Fix P0/P1 Regression Repair & Authoritative Verification

### 1. P0 Checkout Correctness & Concurrency Guards
- **Aggregate Quantity Calculation**: `OrderController::store` now calculates total quantity demanded per `product_id` prior to checking inventory. Prevents negative stock when identical products appear in multiple order lines.
- **Deterministic Row-Locking**: Product IDs are sorted in ascending order before row-level locking (`Product::lockForUpdate()`) to prevent database transaction deadlocks under concurrent checkout requests.
- **Trusted Server-side Totals Recalculation**: Server independently validates and recalculates item subtotals, order subtotal, discount, and tax. Rejects manipulated totals with HTTP 422.
- **Role Permission Enforcement for Pricing/Discounts**: Restricts discounts and custom pricing overrides to `ADMIN` / `ADMIN_MANAGER` roles. Cashiers attempting price discounts receive HTTP 403.
- **Strict Payment Validation**:
  - `khqr`: Requires `received_riel == total_riel` and `change_riel == 0`.
  - `cash`: Requires `received_riel >= total_riel` and exact `change_riel == received_riel - total_riel`.

### 2. P0 Idempotency & Security Isolation
- **Stable Operation ID**: Enforces `client_operation_id` (min 8 characters) for all orders.
- **User-bound Scope**: Binds each operation ID to the authenticated cashier (`cashier_id == $user->id`). Cross-user reuse is rejected with HTTP 403.
- **Payload Equivalence & Conflict Guard**: Verifies matching order totals, payment method, and item quantities. A retry with identical payload returns HTTP 200 idempotent recovery; an altered payload returns HTTP 409 Conflict.
- **Concurrent Duplicate Protection**: In-flight concurrent duplicate submissions are trapped gracefully without unhandled 500 database errors.

### 3. P0 Role-Based Authorization
- **Server-side Middleware**: Added `CheckRole` middleware registered as `'role'` in `bootstrap/app.php`.
- **Protected Routes**:
  - Cashier: Authorized POS checkout (`/orders`) and catalog read access (`/products`, `/categories`).
  - Admin/Manager: Products & Categories CRUD, Inventory adjustments (`/inventory/stock-in`, `/inventory/stock-out`, `/inventory/adjust`, `/inventory/purchase`), and Reports (`/reports/summary`).
  - Cashier attempts to access Admin endpoints return HTTP 403.

### 4. P1 Product & Category Consistency
- **Product Code Uniqueness**: `ProductController::update` validates code uniqueness excluding the current product ID (`unique:products,code,$id`).
- **Fresh Authoritative Data**: Product and category mutations return freshly refreshed server models loaded with relations.
- **Category Usage Guard**: In-use category deletion is rejected with HTTP 422.

### 5. P1 Inventory, Purchases & Cache
- **Idempotency on Inventory Mutations**: Added `client_operation_id` support and idempotent recovery for Stock In, Stock Out, Adjust, and Purchases.
- **Safe Note Access**: Resolved null/missing `note` in `InventoryController::purchase`.
- **Client Cache Reconciliation**: `InventoryRepository` uses server-confirmed `stock_qty` from response to update local Firestore documents.

### 6. P1 Authentication & API Responses
- **Sanctum Authoritative Session**: `AuthRepository` strictly verifies active Sanctum token and rejects treating Firebase-only sessions as authenticated Laravel sessions.
- **Strict JSON Parsing**: `ApiService` rejects non-JSON HTTP responses with clear exceptions instead of generating synthetic success objects.
- **Credential & Config Hardening**: Removed hardcoded default DB password `'123456'` in `backend/config/database.php` (`env('DB_PASSWORD', '')`). Removed hardcoded IP address in `api_service.dart`.

## Active Environment
- **Flutter App**: `e:\Project\flutter\project\mart_pos`
- **Laravel Backend**: `e:\Project\flutter\project\mart_pos\backend`
- **Backend API Server**: `http://localhost:8080` (or `API_BASE_URL` env variable)
- **MySQL Database**: `mart_pos_db` on `127.0.0.1:3306`

## Verification & Test Results
- `flutter analyze lib/`: **No issues found!** (Passed cleanly in 0 errors/warnings)
- `flutter test`: **All 50 tests passed!** (Including MoneyUtils, Role guards, Code uniqueness, Profit math, Sale guards, and ApiService JSON error rejection)
- `cd backend; php artisan test`: **All 16 tests passed (72 assertions)!** (Covering authentication, aggregate stock, cashier pricing guards, cross-user idempotency, 409 conflict, role middleware, category CRUD, inventory idempotency, and product code update uniqueness)

## Next Steps
- Verify Git diff and push `fix/p0-p1-regressions` branch to origin.
- Do NOT merge into `main` without review.
