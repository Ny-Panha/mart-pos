# MART POS shared state

## Last Session

- Antigravity IDE · 2026-11-26 01:03 ICT
- Active Branch: `ui/full-frontend-rebuild`
- Production Branch: `main`

## Summary: Mobile & Cashier Fixes Ready for Team Clone

- **Physical Phone & Network**:
  - Added automatic `10.0.2.2` -> `127.0.0.1` fallback in `lib/data/services/api_service.dart` (works on both Android Emulator and USB `adb reverse tcp:8080 tcp:8080`).
  - Enabled `android:usesCleartextTraffic="true"` in `android/app/src/main/AndroidManifest.xml`.
- **Admin Manager UI**:
  - Removed `Shops` tile from Quick Shortcuts (`admin_manager_dashboard_screen.dart`).
  - Fixed `BOTTOM OVERFLOWED BY 7.0 PIXELS` on Global Products mobile cards, cleaned up search bar inner fill (`admin_manager_catalog_screen.dart`, `admin_manager_stock_screen.dart`), removed unused `All shops` dropdown, and added `Categories` + `Add Product` buttons on Global Products.
- **POS & Cashier**:
  - Added Bakong KHQR asset (`assets/qr.png`) to KHQR tab in `payment_dialog.dart`.
  - Fixed success dialog button layout and added real `Printing.layoutPdf` receipt preview in `pos_screen.dart`.
  - Fixed Cashier `Sales History` and `Stock Check` (`cashier_service.dart`, `cashier_sales_history_screen.dart`, `cashier_stock_screen.dart`) to load from Laravel API (`/orders`, `/products`), map Laravel `total_riel` / `sale_price` fields, and support `RefreshIndicator` + Refresh button.
- **Verification**:
  - `fvm flutter analyze`: No issues found (exit 0).
  - `fvm flutter test`: 113/113 passed (exit 0).

## Active Environment

- Remote: `origin` (https://github.com/Ny-Panha/mart-pos.git)
- Branch: `ui/full-frontend-rebuild`
- Pinned SDK: Flutter `3.47.7`, Dart `3.13.5`, FVM `4.3.2`

## Next Steps

- Team can clone `https://github.com/Ny-Panha/mart-pos.git` on branch `ui/full-frontend-rebuild` and run `fvm install`.
