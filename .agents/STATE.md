# MART POS shared state

## Last Session

- Antigravity IDE · 2026-11-26 19:00 ICT
- Active Branch: `main`

## Summary: Thermal Receipt Print UI Redesign & Khmer Shaping Fix

- **Root Cause Fixed**:
  1. `package:pdf` (`pw.Text`) lacks an OpenType/HarfBuzz shaper, causing Khmer subscripts ("ដាច់ជើង") and `៛` glyphs to break or detach in PDF output.
  2. `PdfPageFormat.roll80` / `roll57` use `height: double.infinity`, triggering `multi_page.dart:252` (`pageFormat.height < double.infinity`) assertion inside `PdfPreview`.
- **Changed Files**:
  - `lib/core/utils/receipt_printer.dart`: Rewrote receipt generator to load bundled `NotoSansKhmer-Regular.ttf` and `NotoSansKhmer-Bold.ttf` via `FontLoader` and render via Flutter's HarfBuzz `TextPainter` + `Canvas` (`buildReceiptImage`), embedded into a finite-height `PdfPageFormat` PDF (`buildPdfBytes`, `printReceipt`). Supports 80mm (5-column) and 58mm (compact) layouts, bilingual payment labels (`CASH_RIEL -> សាច់ប្រាក់ (KHR)`, `CASH_USD -> សាច់ប្រាក់ (USD)`, `KHQR -> Bakong KHQR`), shaded Total, bold Change, and bilingual footer.
  - `lib/core/widgets/receipt_preview_dialog.dart`: Live print preview dialog with `80mm Thermal` / `58mm Thermal` toggle rendering `ReceiptPrinter.buildReceiptImage` inside `InteractiveViewer` (1:1 match with printed output, no `double.infinity` assertion).
  - `lib/features/pos/presentation/pos_screen.dart`: Wired `ReceiptPreviewDialog.show(...)` with `unitPrice` on Print.
  - `lib/features/cashier/presentation/cashier_invoice_screen.dart`: Wired `ReceiptPreviewDialog.show(...)` for Cashier reprint without duplicating sale.
  - `lib/features/reports/presentation/widgets/sale_detail_dialog.dart`: Added `បោះពុម្ព (Print)` button opening `ReceiptPreviewDialog.show(...)` for Admin reprint.
  - `test/receipt_printer_test.dart`: Added 5 acceptance tests covering payment labels, 80mm Test Case A, 58mm Test Case B, Cash USD / KHQR / 25+ items / long names, and Cashier reprint.
- **Verified**:
  - `flutter analyze --no-pub`: 0 issues.
  - `flutter test --no-pub`: 122/122 passed.
  - Visual PNG verification of 80mm & 58mm receipt output confirmed intact Khmer subscripts and `៛`.
  - Confirmed `ProductFormDialog` (`lib/features/products/presentation/product_form_dialog.dart`) already uses `TextFormField` (`_categoryController`) for Category input.

## Active Environment

- Branch: `main`
- Laravel backend (`php artisan serve --host=0.0.0.0 --port=8080`) running as background task.

## Next Steps

- Hot-restart / rebuild app on device to pick up the updated `ReceiptPrinter` and `ReceiptPreviewDialog`.
