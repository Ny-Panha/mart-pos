# STATE: Mini-Mart POS Project Synchronization

## Last Session
- **Environment**: Antigravity IDE
- **Timestamp**: 2026-10-08 11:34 (ICT)
- **Author**: Pair programming with Nha (Build Bright University, Year 4 Semester 2)
- **Team**: នី បញ្ញា, គក់ ស្រីផ្កាយ, គុយ ដាលី

## Summary: Suppliers + Purchases Management with Stock-In Integration
1. **Suppliers Feature (`/admin/suppliers`)**:
   - `SupplierModel` ([supplier_model.dart](file:///home/nha/Desktop/mart_pos/lib/data/firestore/models/supplier_model.dart)): `id`, `name`, `phone`, `address`, `note`, `active`, `createdAt`.
   - `SupplierRepository` ([supplier_repository.dart](file:///home/nha/Desktop/mart_pos/lib/data/repositories/supplier_repository.dart)): `watchSuppliers()` (active first, alphabetical), `createSupplier`, `updateSupplier`, `activateSupplier`, `deactivateSupplier`.
   - **Deactivation Protection**: Blocks deactivating suppliers who have existing purchase records (`canDeactivateSupplier({required int purchaseCount})`).
   - `SuppliersScreen` ([suppliers_screen.dart](file:///home/nha/Desktop/mart_pos/lib/features/suppliers/presentation/suppliers_screen.dart)): List with search, status toggles, responsive `SupplierFormDialog`, and `SupplierDetailDialog` with purchase history stream.
2. **Purchases Feature (`/admin/purchases`)**:
   - `PurchaseModel` ([purchase_model.dart](file:///home/nha/Desktop/mart_pos/lib/data/firestore/models/purchase_model.dart)) & `PurchaseItem`: `id`, `supplierId`, `supplierName`, `items`, `totalCost`, `note`, `createdBy`, `createdAt`.
   - `PurchaseRepository` ([purchase_repository.dart](file:///home/nha/Desktop/mart_pos/lib/data/repositories/purchase_repository.dart)): `watchPurchases()`, `watchPurchasesBySupplier()`.
   - **Single Atomic WriteBatch (`createPurchase`)**:
     1. Increment `products/{id}.stockQty` AND update `costPrice` to keep margins accurate.
     2. Create `stockMovements` entry (`type: "in"`, `refId: purchaseId`, `note: "Purchase from {supplierName}"`).
     3. Create `purchases` doc.
     - Pure validation guards: `validatePurchaseInput` & `calculateTotalCost`.
   - `PurchasesScreen` ([purchases_screen.dart](file:///home/nha/Desktop/mart_pos/lib/features/purchases/presentation/purchases_screen.dart)): Live purchase log cards with supplier name, date, item count, Riel + USD total.
   - `PurchaseFormDialog` ([purchase_form_dialog.dart](file:///home/nha/Desktop/mart_pos/lib/features/purchases/presentation/purchase_form_dialog.dart)): Active suppliers dropdown, dynamic item rows with searchable product picker, qty, cost price (៛), and live total footer.
   - `PurchaseDetailDialog` ([purchase_detail_dialog.dart](file:///home/nha/Desktop/mart_pos/lib/features/purchases/presentation/purchase_detail_dialog.dart)): Item breakdown table with unit cost and subtotals.
3. **Inventory Screen Integration**:
   - `InventoryScreen` ([inventory_screen.dart](file:///home/nha/Desktop/mart_pos/lib/features/inventory/presentation/inventory_screen.dart)): Added "ORDER" action on low-stock alert card items that opens `PurchaseFormDialog` prefilled with the selected product.
4. **Router & Shell Navigation**:
   - `router.dart` ([router.dart](file:///home/nha/Desktop/mart_pos/lib/core/router.dart)): Added `/admin/suppliers` and `/admin/purchases` protected by admin auth guard.
   - `main_shell.dart` ([main_shell.dart](file:///home/nha/Desktop/mart_pos/lib/core/widgets/main_shell.dart)): Added Purchases and Suppliers navigation rail destinations and updated mobile bottom bar handling.
5. **Quality & Verification**:
   - `flutter analyze`: **0 issues found** (clean 100%).
   - `flutter test`: **33/33 tests passed** (including purchase total math, input guards, and supplier deactivation blocker tests).
   - Localization: Added English and Khmer keys in `app_en.arb` and `app_km.arb` and regenerated.

## Active Branch & Git
- **Branch**: `feat/suppliers-purchases`
- **Pull Request**: [#5](https://github.com/Ny-Panha/mart-pos/pull/5) (`feat(suppliers-purchases): Suppliers + Purchases management and stock-in integration`)
- **Status**: Open, ready for review & merge into `main`

## Active Environment
- **Flutter Web Dev Server**: Running on Chrome
- **Tests & Analyzer**: 0 issues, 33/33 tests passing clean

## Next Steps
1. Review PR #5 on GitHub: `https://github.com/Ny-Panha/mart-pos/pull/5`
2. Merge PR #5 into `main` when approved.
