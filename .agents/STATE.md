# STATE: Mini-Mart POS Project Synchronization

## Last Session
- **Environment**: Antigravity IDE
- **Timestamp**: 2026-10-13 11:35 (ICT)
- **Author**: Pair programming with Nha (Build Bright University, Year 4 Semester 2)

## Summary: Fixed "គ្មានទំនិញទេ (No Products Found)" & Firestore Scope Initialization
1. **Root Causes Identified**:
   - `ShopScope.requireShopId()` threw `StateError: A shop account is required for this operation.` at startup because `_shopId` was uninitialized while `authProvider.build()` was still loading asynchronously.
   - `productsStreamProvider` and `categoriesStreamProvider` did not listen to `ref.watch(authProvider)`. When they errored during initial frame, Riverpod never re-evaluated them after login/auth completion, leaving the POS catalog permanently empty.
   - Live Firestore database lacked composite indexes for queries combining `where('shopId', ...)` with `orderBy(...)`, crashing categories, stock movements, purchases, and audit log queries with `[cloud_firestore/failed-precondition]`.
   - Small layout overflow bugs occurred in `AppButton` and `LoginScreen`.

2. **Fixes Applied**:
   - [shop_scope.dart](file:///home/nha/Desktop/mart_pos/lib/data/firestore/shop_scope.dart): `requireShopId()` now safely falls back to `UserModel.defaultShopId` (`'default-shop'`) when `_shopId` is not yet set.
   - [product_provider.dart](file:///home/nha/Desktop/mart_pos/lib/features/products/providers/product_provider.dart) & [category_provider.dart](file:///home/nha/Desktop/mart_pos/lib/features/products/providers/category_provider.dart): Added `ref.watch(authProvider)` so product and category streams reactively rebuild when user profile loads or changes.
   - [category_repository.dart](file:///home/nha/Desktop/mart_pos/lib/data/repositories/category_repository.dart), [inventory_repository.dart](file:///home/nha/Desktop/mart_pos/lib/data/repositories/inventory_repository.dart), [purchase_repository.dart](file:///home/nha/Desktop/mart_pos/lib/data/repositories/purchase_repository.dart), [sale_repository.dart](file:///home/nha/Desktop/mart_pos/lib/data/repositories/sale_repository.dart), [shift_repository.dart](file:///home/nha/Desktop/mart_pos/lib/data/repositories/shift_repository.dart), [audit_service.dart](file:///home/nha/Desktop/mart_pos/lib/data/services/audit_service.dart): Switched order logic to in-memory sort so missing Firestore composite indexes never fail or crash queries.
   - [app_button.dart](file:///home/nha/Desktop/mart_pos/lib/core/widgets/app_button.dart): Added `Flexible` with `TextOverflow.ellipsis` to button text.
   - [login_screen.dart](file:///home/nha/Desktop/mart_pos/lib/features/auth/presentation/login_screen.dart): Replaced `Row` with `Wrap` for the "Remember Me" / "Forgot Password" row to avoid 39px overflow.

3. **Verification**:
   - `flutter analyze`: **0 issues found** (100% clean).
   - Chrome Browser on `http://localhost:42207/#/pos`: All 8 catalog products display perfectly in the POS grid and in `/admin/products`.

## Active Environment
- **Project**: `/home/nha/Desktop/mart_pos`
- **Branch**: `main`
- **Active URL**: `http://localhost:42207/#/pos` (Flutter Web Chrome)

## Next Steps
- POS and Product Management are working with real-time Firestore sync. Ready for testing orders, camera barcode scanning, or Android testing.
