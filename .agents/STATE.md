# MART POS — Project State

- **Last Session**: Antigravity IDE — 2026-11-26 19:03 (+07:00)
- **Active Branch**: `main`
- **Summary**:
  - Redesigned thermal receipt (`ReceiptPrinter` in `lib/core/utils/receipt_printer.dart`) to match the MINI-MART POS / Build Bright University layout with 58mm and 80mm thermal paper support.
  - Fixed P0 Khmer font, subscript ("ជើង"), and `៛` currency glyph rendering by rendering the receipt through Flutter's HarfBuzz text shaper (`TextPainter` + `Canvas` + bundled `NotoSansKhmer-Regular.ttf` / `NotoSansKhmer-Bold.ttf`) into a high-DPI image embedded on a finite-height `PdfPageFormat` (eliminating `multi_page.dart:252` `double.infinity` assertion).
  - Updated `ReceiptPreviewDialog` (`lib/core/widgets/receipt_preview_dialog.dart`) to display the exact rasterized 80mm/58mm receipt preview with zoom/scroll and print action.
  - Verified reprint flows for both Cashier (`CashierInvoiceScreen`) and Admin (`SaleDetailDialog`) without duplicating sales or deducting stock.
  - Confirmed `ProductFormDialog` Category field uses `TextFormField` (`_categoryController`) instead of a dropdown.
  - Added 5 acceptance tests in `test/receipt_printer_test.dart`; `flutter analyze --no-pub` and `flutter test --no-pub` passed (122/122).
- **Active Environment**:
  - Flutter 3.47.7 / Dart 3.13.5 (`.fvm/flutter_sdk`)
  - Backend: Laravel API on `http://localhost:8080`
- **Next Steps**:
  - Hot-restart / rebuild app on target device to test live thermal printing and Category input.
