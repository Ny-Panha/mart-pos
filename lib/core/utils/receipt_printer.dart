import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/firestore/models/sale_model.dart';
import 'date.dart';
import 'money.dart';

/// Supported thermal paper widths.
enum ReceiptPaperSize {
  mm80,
  mm58;

  double get widthPt => switch (this) {
    ReceiptPaperSize.mm80 => 80 * PdfPageFormat.mm,
    ReceiptPaperSize.mm58 => 58 * PdfPageFormat.mm,
  };

  /// Finite fallback page format for printing dialogs (never `double.infinity`).
  PdfPageFormat get pageFormat => PdfPageFormat(
    widthPt,
    200 * PdfPageFormat.mm,
    marginAll: 0,
  );

  String get label => switch (this) {
    ReceiptPaperSize.mm80 => '80mm',
    ReceiptPaperSize.mm58 => '58mm',
  };
}

/// Line item representation for thermal receipt rendering.
class ReceiptItemData {
  final String name;
  final int qty;
  final int unitPrice;
  final int totalPrice;

  const ReceiptItemData({
    required this.name,
    required this.qty,
    required this.unitPrice,
    required this.totalPrice,
  });
}

/// Immutable receipt payload built from a completed transaction.
class ReceiptData {
  final String invoiceNumber;
  final DateTime createdAt;
  final String paymentMethod;
  final List<ReceiptItemData> items;
  final int subtotal;
  final int discount;
  final int tax;
  final int total;
  final int paid;
  final int change;
  final double? receivedUsd;
  final double? changeUsd;

  const ReceiptData({
    required this.invoiceNumber,
    required this.createdAt,
    required this.paymentMethod,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paid,
    required this.change,
    this.receivedUsd,
    this.changeUsd,
  });

  factory ReceiptData.fromSale(SaleModel sale) {
    return ReceiptData(
      invoiceNumber: sale.invoiceNumber,
      createdAt: sale.createdAt,
      paymentMethod: sale.paymentMethod,
      items: sale.items
          .map(
            (i) => ReceiptItemData(
              name: i.name,
              qty: i.qty,
              unitPrice: i.unitPrice,
              totalPrice: i.totalPrice,
            ),
          )
          .toList(),
      subtotal: sale.subtotal,
      discount: sale.discount,
      tax: sale.totalTax,
      total: sale.total,
      paid: sale.paidAmount,
      change: sale.changeAmount,
      receivedUsd: sale.receivedUsd,
      changeUsd: sale.changeUsd,
    );
  }
}

/// Rasterized receipt output with exact physical dimensions in PDF points.
typedef RenderedReceiptImage = ({
  Uint8List pngBytes,
  double widthPt,
  double heightPt,
});

/// Generates and prints 58mm / 80mm thermal receipts with embedded
/// Noto Sans Khmer shaped via Flutter's HarfBuzz text engine so Khmer
/// subscripts ("ជើង") and the `៛` currency symbol render accurately.
class ReceiptPrinter {
  ReceiptPrinter._();

  static const String _khmerFontFamily = 'NotoSansKhmerReceipt';
  static Future<void>? _fontLoadFuture;

  static Future<void> _ensureKhmerFontLoaded() {
    return _fontLoadFuture ??= () async {
      final regularData = await rootBundle.load(
        'assets/fonts/NotoSansKhmer-Regular.ttf',
      );
      final boldData = await rootBundle.load(
        'assets/fonts/NotoSansKhmer-Bold.ttf',
      );
      final loader = FontLoader(_khmerFontFamily)
        ..addFont(Future.value(regularData))
        ..addFont(Future.value(boldData));
      await loader.load();
    }();
  }

  /// Maps internal payment codes to readable bilingual labels.
  static String formatPaymentMethod(String code) {
    switch (code.trim().toUpperCase()) {
      case 'CASH_RIEL':
        return 'សាច់ប្រាក់ (KHR)';
      case 'CASH_USD':
        return 'សាច់ប្រាក់ (USD)';
      case 'KHQR':
        return 'Bakong KHQR';
      default:
        return code;
    }
  }

  static Future<void> printSaleReceipt({
    required String invoiceNumber,
    required DateTime createdAt,
    required String paymentMethod,
    required List<({String name, int qty, int unitPrice, int totalPrice})>
    items,
    required int subtotal,
    required int discount,
    required int tax,
    required int total,
    required int paid,
    required int change,
    ReceiptPaperSize paperSize = ReceiptPaperSize.mm80,
  }) async {
    await printReceipt(
      ReceiptData(
        invoiceNumber: invoiceNumber,
        createdAt: createdAt,
        paymentMethod: paymentMethod,
        items: items
            .map(
              (i) => ReceiptItemData(
                name: i.name,
                qty: i.qty,
                unitPrice: i.unitPrice,
                totalPrice: i.totalPrice,
              ),
            )
            .toList(),
        subtotal: subtotal,
        discount: discount,
        tax: tax,
        total: total,
        paid: paid,
        change: change,
      ),
      paperSize: paperSize,
    );
  }

  static Future<void> printReceipt(
    ReceiptData data, {
    ReceiptPaperSize paperSize = ReceiptPaperSize.mm80,
  }) async {
    final rendered = await buildReceiptImage(data, paperSize: paperSize);
    final pdfBytes = await _wrapImageInPdf(rendered);
    await Printing.layoutPdf(
      name: 'Receipt_${data.invoiceNumber}',
      format: PdfPageFormat(
        rendered.widthPt,
        rendered.heightPt,
        marginAll: 0,
      ),
      onLayout: (_) async => pdfBytes,
    );
  }

  /// Builds the actual PDF bytes for thermal printing and verification.
  static Future<Uint8List> buildPdfBytes(
    ReceiptData data, {
    ReceiptPaperSize paperSize = ReceiptPaperSize.mm80,
  }) async {
    final rendered = await buildReceiptImage(data, paperSize: paperSize);
    return _wrapImageInPdf(rendered);
  }

  static Future<Uint8List> _wrapImageInPdf(RenderedReceiptImage rendered) async {
    final doc = pw.Document();
    final pageFormat = PdfPageFormat(
      rendered.widthPt,
      rendered.heightPt,
      marginAll: 0,
    );
    final image = pw.MemoryImage(rendered.pngBytes);
    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.SizedBox(
          width: rendered.widthPt,
          height: rendered.heightPt,
          child: pw.Image(image, fit: pw.BoxFit.fill),
        ),
      ),
    );
    return doc.save();
  }

  /// Renders the thermal receipt to a high-DPI PNG using Flutter's HarfBuzz
  /// text shaper so Khmer subscripts, vowels, and `៛` render identically
  /// across preview and printed PDF output.
  static Future<RenderedReceiptImage> buildReceiptImage(
    ReceiptData data, {
    ReceiptPaperSize paperSize = ReceiptPaperSize.mm80,
    double scale = 3.0,
  }) async {
    await _ensureKhmerFontLoaded();

    final is58 = paperSize == ReceiptPaperSize.mm58;
    final pageWidth = paperSize.widthPt;
    final marginX = is58 ? 6.0 : 10.0;
    final marginY = is58 ? 8.0 : 12.0;
    final contentWidth = pageWidth - marginX * 2;

    final dateText = DateUtilsHelper.formatDateTime(data.createdAt);
    final methodLabel = formatPaymentMethod(data.paymentMethod);

    TextStyle style({
      double size = 8.5,
      FontWeight weight = FontWeight.w400,
      Color color = const Color(0xFF000000),
      double height = 1.25,
    }) {
      return TextStyle(
        fontFamily: _khmerFontFamily,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );
    }

    TextPainter makePainter(
      String text, {
      required double maxWidth,
      required TextStyle textStyle,
      TextAlign align = TextAlign.left,
    }) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.ltr,
        textAlign: align,
      )..layout(minWidth: 0, maxWidth: maxWidth);
      return tp;
    }

    final drawOps = <void Function(Canvas)>[];
    double y = marginY;

    void addSolidDivider({double thickness = 0.8}) {
      final lineY = y + thickness / 2;
      drawOps.add((canvas) {
        final paint = Paint()
          ..color = const Color(0xFF000000)
          ..strokeWidth = thickness;
        canvas.drawLine(
          Offset(marginX, lineY),
          Offset(marginX + contentWidth, lineY),
          paint,
        );
      });
      y += thickness;
    }

    void addDashedDivider() {
      final lineY = y + 0.4;
      drawOps.add((canvas) {
        final paint = Paint()
          ..color = const Color(0xFF666666)
          ..strokeWidth = 0.6;
        const dash = 3.0;
        const gap = 3.0;
        var dx = marginX;
        final endX = marginX + contentWidth;
        while (dx < endX) {
          canvas.drawLine(
            Offset(dx, lineY),
            Offset(math.min(dx + dash, endX), lineY),
            paint,
          );
          dx += dash + gap;
        }
      });
      y += 0.8;
    }

    // 1. Receipt Header (Logo M | MINI-MART POS / Build Bright University)
    final logoSize = is58 ? 22.0 : 28.0;
    final logoFontSize = is58 ? 13.0 : 16.0;
    final brandTp = makePainter(
      'MINI-MART POS',
      maxWidth: contentWidth - logoSize - 24,
      textStyle: style(
        size: is58 ? 11.0 : 13.0,
        weight: FontWeight.w700,
        height: 1.15,
      ),
    );
    final subBrandTp = makePainter(
      'Build Bright University',
      maxWidth: contentWidth - logoSize - 24,
      textStyle: style(
        size: is58 ? 7.2 : 8.5,
        color: const Color(0xFF333333),
        height: 1.2,
      ),
    );
    final mTp = makePainter(
      'M',
      maxWidth: logoSize,
      textStyle: style(
        size: logoFontSize,
        weight: FontWeight.w700,
        color: const Color(0xFFFFFFFF),
        height: 1.0,
      ),
      align: TextAlign.center,
    );

    final textBlockW = math.max(brandTp.width, subBrandTp.width);
    final headerTotalW = logoSize + 13.0 + textBlockW;
    final headerStartX = marginX + (contentWidth - headerTotalW) / 2;
    final headerHeight = math.max(logoSize, brandTp.height + subBrandTp.height);
    final headerY = y;

    drawOps.add((canvas) {
      final logoTop = headerY + (headerHeight - logoSize) / 2;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(headerStartX, logoTop, logoSize, logoSize),
        const Radius.circular(5),
      );
      canvas.drawRRect(rrect, Paint()..color = const Color(0xFF000000));
      mTp.paint(
        canvas,
        Offset(
          headerStartX + (logoSize - mTp.width) / 2,
          logoTop + (logoSize - mTp.height) / 2,
        ),
      );

      final divX = headerStartX + logoSize + 6.0;
      canvas.drawLine(
        Offset(divX, headerY + (headerHeight - logoSize) / 2),
        Offset(divX, headerY + (headerHeight + logoSize) / 2),
        Paint()
          ..color = const Color(0xFF888888)
          ..strokeWidth = 0.8,
      );

      final textX = divX + 7.0;
      final textTop = headerY + (headerHeight - (brandTp.height + subBrandTp.height)) / 2;
      brandTp.paint(canvas, Offset(textX, textTop));
      subBrandTp.paint(canvas, Offset(textX, textTop + brandTp.height));
    });

    y += headerHeight + 7;
    addSolidDivider(thickness: 0.9);
    y += 7;

    // 2. Khmer Title + Invoice + Date
    final titleTp = makePainter(
      'វិក្កយបត្រ (Receipt)',
      maxWidth: contentWidth,
      textStyle: style(size: is58 ? 10.5 : 12.0, weight: FontWeight.w700),
      align: TextAlign.center,
    );
    final titleY = y;
    drawOps.add((c) => titleTp.paint(c, Offset(marginX + (contentWidth - titleTp.width) / 2, titleY)));
    y += titleTp.height + 3;

    final invTp = makePainter(
      'លេខវិក្កយបត្រ (Invoice): ${data.invoiceNumber}',
      maxWidth: contentWidth,
      textStyle: style(size: is58 ? 7.2 : 8.2),
      align: TextAlign.center,
    );
    final invY = y;
    drawOps.add((c) => invTp.paint(c, Offset(marginX + (contentWidth - invTp.width) / 2, invY)));
    y += invTp.height + 1.5;

    final dateTp = makePainter(
      'កាលបរិច្ឆេទ (Date): $dateText',
      maxWidth: contentWidth,
      textStyle: style(size: is58 ? 7.2 : 8.2),
      align: TextAlign.center,
    );
    final dateY = y;
    drawOps.add((c) => dateTp.paint(c, Offset(marginX + (contentWidth - dateTp.width) / 2, dateY)));
    y += dateTp.height + 7;

    addSolidDivider(thickness: 0.9);
    y += 5;

    // 3. Product Table
    if (is58) {
      final leftW = contentWidth * 0.64;
      final rightW = contentWidth - leftW;
      final hLeft = makePainter(
        'ល.រ / ទំនិញ (Product)',
        maxWidth: leftW - 4,
        textStyle: style(size: 7.2, weight: FontWeight.w700),
      );
      final hRight = makePainter(
        'សរុប (Amount)',
        maxWidth: rightW - 4,
        textStyle: style(size: 7.2, weight: FontWeight.w700),
        align: TextAlign.right,
      );
      final hdrH = math.max(hLeft.height, hRight.height) + 6;
      final hdrY = y;
      drawOps.add((canvas) {
        canvas.drawRect(
          Rect.fromLTWH(marginX, hdrY, contentWidth, hdrH),
          Paint()..color = const Color(0xFFF2F2F2),
        );
        hLeft.paint(canvas, Offset(marginX + 3, hdrY + 3));
        hRight.paint(canvas, Offset(marginX + contentWidth - hRight.width - 3, hdrY + 3));
      });
      y += hdrH + 4;

      for (var i = 0; i < data.items.length; i++) {
        final item = data.items[i];
        final nameTp = makePainter(
          '${i + 1}. ${item.name}',
          maxWidth: leftW - 4,
          textStyle: style(size: 7.6, weight: FontWeight.w700),
        );
        final amtTp = makePainter(
          MoneyUtils.formatRiel(item.totalPrice),
          maxWidth: rightW - 4,
          textStyle: style(size: 7.6, weight: FontWeight.w700),
          align: TextAlign.right,
        );
        final subTp = makePainter(
          '  x${item.qty} × ${MoneyUtils.formatRiel(item.unitPrice)}',
          maxWidth: leftW - 4,
          textStyle: style(size: 6.9, color: const Color(0xFF444444)),
        );
        final rowY = y;
        final topH = math.max(nameTp.height, amtTp.height);
        drawOps.add((canvas) {
          nameTp.paint(canvas, Offset(marginX + 2, rowY));
          amtTp.paint(canvas, Offset(marginX + contentWidth - amtTp.width - 2, rowY));
          subTp.paint(canvas, Offset(marginX + 2, rowY + topH + 1));
        });
        y += topH + 1 + subTp.height + 4;
      }
    } else {
      // 80mm 5-column layout
      final colNoW = 22.0;
      final colQtyW = 24.0;
      final colPriceW = 46.0;
      final colAmtW = 48.0;
      final colProdW = contentWidth - colNoW - colQtyW - colPriceW - colAmtW;

      final xNo = marginX;
      final xProd = xNo + colNoW;
      final xQty = xProd + colProdW;
      final xPrice = xQty + colQtyW;
      final xAmt = xPrice + colPriceW;

      TextPainter headerCell(String kh, String en, double w, TextAlign align) {
        final tp = TextPainter(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$kh\n',
                style: style(size: 7.3, weight: FontWeight.w700, height: 1.2),
              ),
              TextSpan(
                text: en,
                style: style(
                  size: 6.7,
                  color: const Color(0xFF444444),
                  height: 1.2,
                ),
              ),
            ],
          ),
          textDirection: TextDirection.ltr,
          textAlign: align,
        )..layout(minWidth: 0, maxWidth: w - 4);
        return tp;
      }

      final hNo = headerCell('ល.រ', 'No.', colNoW, TextAlign.center);
      final hProd = headerCell('ទំនិញ', 'Product', colProdW, TextAlign.left);
      final hQty = headerCell('ចំនួន', 'Qty', colQtyW, TextAlign.center);
      final hPrice = headerCell('តម្លៃឯកតា', 'Unit Price', colPriceW, TextAlign.right);
      final hAmt = headerCell('សរុប', 'Amount', colAmtW, TextAlign.right);

      final hdrH = [hNo.height, hProd.height, hQty.height, hPrice.height, hAmt.height]
              .reduce(math.max) +
          6;
      final hdrY = y;
      drawOps.add((canvas) {
        canvas.drawRect(
          Rect.fromLTWH(marginX, hdrY, contentWidth, hdrH),
          Paint()..color = const Color(0xFFF2F2F2),
        );
        hNo.paint(canvas, Offset(xNo + (colNoW - hNo.width) / 2, hdrY + 3));
        hProd.paint(canvas, Offset(xProd + 2, hdrY + 3));
        hQty.paint(canvas, Offset(xQty + (colQtyW - hQty.width) / 2, hdrY + 3));
        hPrice.paint(canvas, Offset(xPrice + colPriceW - hPrice.width - 2, hdrY + 3));
        hAmt.paint(canvas, Offset(xAmt + colAmtW - hAmt.width - 2, hdrY + 3));
      });
      y += hdrH + 4;

      for (var i = 0; i < data.items.length; i++) {
        final item = data.items[i];
        final cNo = makePainter(
          '${i + 1}',
          maxWidth: colNoW - 4,
          textStyle: style(size: 7.8),
          align: TextAlign.center,
        );
        final cProd = makePainter(
          item.name,
          maxWidth: colProdW - 4,
          textStyle: style(size: 7.8, weight: FontWeight.w700),
        );
        final cQty = makePainter(
          'x${item.qty}',
          maxWidth: colQtyW - 4,
          textStyle: style(size: 7.8),
          align: TextAlign.center,
        );
        final cPrice = makePainter(
          MoneyUtils.formatRiel(item.unitPrice),
          maxWidth: colPriceW - 4,
          textStyle: style(size: 7.8),
          align: TextAlign.right,
        );
        final cAmt = makePainter(
          MoneyUtils.formatRiel(item.totalPrice),
          maxWidth: colAmtW - 4,
          textStyle: style(size: 7.8, weight: FontWeight.w700),
          align: TextAlign.right,
        );

        final rowH = [cNo.height, cProd.height, cQty.height, cPrice.height, cAmt.height]
            .reduce(math.max);
        final rowY = y;
        drawOps.add((canvas) {
          cNo.paint(canvas, Offset(xNo + (colNoW - cNo.width) / 2, rowY));
          cProd.paint(canvas, Offset(xProd + 2, rowY));
          cQty.paint(canvas, Offset(xQty + (colQtyW - cQty.width) / 2, rowY));
          cPrice.paint(canvas, Offset(xPrice + colPriceW - cPrice.width - 2, rowY));
          cAmt.paint(canvas, Offset(xAmt + colAmtW - cAmt.width - 2, rowY));
        });
        y += rowH + 4;
      }
    }

    y += 2;
    addDashedDivider();
    y += 6;

    // 4. Payment Summary
    void addSummaryRow(
      String label,
      String value, {
      bool bold = false,
      bool shaded = false,
      double? fontSize,
    }) {
      final fs = fontSize ?? (is58 ? 7.8 : 8.5);
      final labelW = contentWidth * 0.58;
      final valueW = contentWidth - labelW - 6;
      final lTp = makePainter(
        label,
        maxWidth: labelW,
        textStyle: style(
          size: fs,
          weight: bold ? FontWeight.w700 : FontWeight.w400,
        ),
      );
      final vTp = makePainter(
        value,
        maxWidth: valueW,
        textStyle: style(
          size: fs,
          weight: bold ? FontWeight.w700 : FontWeight.w400,
        ),
        align: TextAlign.right,
      );
      final rowH = math.max(lTp.height, vTp.height) + (shaded ? 8 : 2);
      final rowY = y;
      drawOps.add((canvas) {
        if (shaded) {
          canvas.drawRect(
            Rect.fromLTWH(marginX, rowY, contentWidth, rowH),
            Paint()..color = const Color(0xFFEDEDED),
          );
        }
        final padX = shaded ? 4.0 : 0.0;
        final padY = shaded ? 4.0 : 1.0;
        lTp.paint(canvas, Offset(marginX + padX, rowY + padY));
        vTp.paint(
          canvas,
          Offset(marginX + contentWidth - vTp.width - padX, rowY + padY),
        );
      });
      y += rowH + (shaded ? 4 : 2.5);
    }

    addSummaryRow('សរុបរង (Subtotal)', MoneyUtils.formatRiel(data.subtotal));
    if (data.discount > 0) {
      addSummaryRow(
        'បញ្ចុះតម្លៃ (Discount)',
        '-${MoneyUtils.formatRiel(data.discount)}',
      );
    }
    if (data.tax > 0) {
      addSummaryRow('ពន្ធ (Tax)', MoneyUtils.formatRiel(data.tax));
    }
    addSummaryRow(
      'ប្រាក់ត្រូវទូទាត់ (Total)',
      MoneyUtils.formatRiel(data.total),
      bold: true,
      shaded: true,
      fontSize: is58 ? 8.8 : 10.0,
    );

    final receivedLabel = data.receivedUsd != null
        ? '${MoneyUtils.formatRiel(data.paid)} (${MoneyUtils.formatUSD(data.receivedUsd!)})'
        : MoneyUtils.formatRiel(data.paid);
    addSummaryRow('ប្រាក់ទទួល (Received)', receivedLabel);

    final changeLabel = data.changeUsd != null
        ? '${MoneyUtils.formatRiel(data.change)} (${MoneyUtils.formatUSD(data.changeUsd!)})'
        : MoneyUtils.formatRiel(data.change);
    addSummaryRow(
      'ប្រាក់អាប់ (Change)',
      changeLabel,
      bold: true,
      fontSize: is58 ? 8.2 : 9.2,
    );
    addSummaryRow('វិធីទូទាត់ (Payment Method)', methodLabel);

    y += 5;
    addSolidDivider(thickness: 0.9);
    y += 7;

    // 5. Footer
    final footerKh = makePainter(
      'សូមអរគុណសម្រាប់ការទិញទំនិញ!',
      maxWidth: contentWidth,
      textStyle: style(size: is58 ? 8.2 : 9.2, weight: FontWeight.w700),
      align: TextAlign.center,
    );
    final fkY = y;
    drawOps.add((c) => footerKh.paint(c, Offset(marginX + (contentWidth - footerKh.width) / 2, fkY)));
    y += footerKh.height + 2;

    final footerEn = makePainter(
      'Thank you for shopping with us!',
      maxWidth: contentWidth,
      textStyle: style(size: is58 ? 7.6 : 8.5, color: const Color(0xFF222222)),
      align: TextAlign.center,
    );
    final feY = y;
    drawOps.add((c) => footerEn.paint(c, Offset(marginX + (contentWidth - footerEn.width) / 2, feY)));
    y += footerEn.height + marginY;

    final pageHeight = y;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(scale, scale);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, pageWidth, pageHeight),
      Paint()..color = const Color(0xFFFFFFFF),
    );

    for (final op in drawOps) {
      op(canvas);
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(
      (pageWidth * scale).ceil(),
      (pageHeight * scale).ceil(),
    );
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();

    return (
      pngBytes: byteData!.buffer.asUint8List(),
      widthPt: pageWidth,
      heightPt: pageHeight,
    );
  }
}
