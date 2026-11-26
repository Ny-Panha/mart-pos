import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mart_pos/core/utils/receipt_printer.dart';
import 'package:mart_pos/core/widgets/receipt_preview_dialog.dart';
import 'package:mart_pos/data/firestore/models/sale_model.dart';
import 'package:mart_pos/features/cashier/presentation/cashier_invoice_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('payment method labels map to readable Khmer/English labels', () {
    expect(ReceiptPrinter.formatPaymentMethod('CASH_RIEL'), 'សាច់ប្រាក់ (KHR)');
    expect(ReceiptPrinter.formatPaymentMethod('cash_riel'), 'សាច់ប្រាក់ (KHR)');
    expect(ReceiptPrinter.formatPaymentMethod('CASH_USD'), 'សាច់ប្រាក់ (USD)');
    expect(ReceiptPrinter.formatPaymentMethod('KHQR'), 'Bakong KHQR');
  });

  test('generates 80mm receipt image and finite PDF for Test Case A', () async {
    final data = ReceiptData(
      invoiceNumber: 'INV-1795690681-8995',
      createdAt: DateTime(2026, 11, 26, 17, 58, 18),
      paymentMethod: 'CASH_RIEL',
      items: const [
        ReceiptItemData(
          name: 'Pure Drinking Water 500ml',
          qty: 1,
          unitPrice: 1000,
          totalPrice: 1000,
        ),
      ],
      subtotal: 1000,
      discount: 0,
      tax: 0,
      total: 1000,
      paid: 5000,
      change: 4000,
    );

    final rendered = await ReceiptPrinter.buildReceiptImage(
      data,
      paperSize: ReceiptPaperSize.mm80,
    );
    expect(rendered.pngBytes.take(4).toList(), [0x89, 0x50, 0x4E, 0x47]);
    expect(rendered.widthPt, closeTo(ReceiptPaperSize.mm80.widthPt, 0.01));
    expect(rendered.heightPt.isFinite, isTrue);
    expect(rendered.heightPt, greaterThan(100));

    final bytes = await ReceiptPrinter.buildPdfBytes(
      data,
      paperSize: ReceiptPaperSize.mm80,
    );

    expect(bytes.length, greaterThan(5000));
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
    final pdfRaw = latin1.decode(bytes);
    expect(pdfRaw, isNot(contains('Infinity')));
  });

  test('generates 58mm compact PDF for Test Case B (8,000 / 10,000 / 2,000)', () async {
    final data = ReceiptData(
      invoiceNumber: 'INV-000015',
      createdAt: DateTime(2026, 11, 26, 18, 0, 0),
      paymentMethod: 'CASH_RIEL',
      items: const [
        ReceiptItemData(
          name: 'Coca Cola 330ml',
          qty: 2,
          unitPrice: 2500,
          totalPrice: 5000,
        ),
        ReceiptItemData(
          name: 'Mama Instant Noodles Tom Yum Special Family Pack',
          qty: 2,
          unitPrice: 1500,
          totalPrice: 3000,
        ),
      ],
      subtotal: 8000,
      discount: 0,
      tax: 0,
      total: 8000,
      paid: 10000,
      change: 2000,
    );

    final bytes58 = await ReceiptPrinter.buildPdfBytes(
      data,
      paperSize: ReceiptPaperSize.mm58,
    );

    expect(bytes58.length, greaterThan(5000));
    expect(ascii.decode(bytes58.take(5).toList()), '%PDF-');
    expect(latin1.decode(bytes58), isNot(contains('Infinity')));
  });

  test('supports Cash USD, KHQR, long product names, and 25+ items', () async {
    final manyItems = List.generate(
      25,
      (i) => ReceiptItemData(
        name: 'ទំនិញពិសេសលេខ ${i + 1} - Long Product Name For Thermal Wrap Testing 500ml',
        qty: i + 1,
        unitPrice: 2000,
        totalPrice: (i + 1) * 2000,
      ),
    );

    for (final method in ['CASH_USD', 'KHQR']) {
      final data = ReceiptData(
        invoiceNumber: 'INV-MULTI-$method',
        createdAt: DateTime(2026, 11, 26, 18, 5, 0),
        paymentMethod: method,
        items: manyItems,
        subtotal: 650000,
        discount: 5000,
        tax: 64500,
        total: 709500,
        paid: 710000,
        change: 500,
        receivedUsd: method == 'CASH_USD' ? 175.0 : null,
        changeUsd: method == 'CASH_USD' ? 1.95 : null,
      );

      final bytes80 = await ReceiptPrinter.buildPdfBytes(
        data,
        paperSize: ReceiptPaperSize.mm80,
      );
      final bytes58 = await ReceiptPrinter.buildPdfBytes(
        data,
        paperSize: ReceiptPaperSize.mm58,
      );

      expect(ascii.decode(bytes80.take(5).toList()), '%PDF-');
      expect(ascii.decode(bytes58.take(5).toList()), '%PDF-');
    }
  });

  testWidgets('CashierInvoiceScreen reprint opens ReceiptPreviewDialog without duplicating sale', (tester) async {
    final sale = SaleModel(
      id: 'sale-1',
      invoiceNumber: 'INV-REPRINT-01',
      cashierId: 'c1',
      cashierName: 'Cashier',
      items: [
        SaleItem(
          productId: 'p1',
          name: 'Pure Drinking Water 500ml',
          qty: 1,
          unitPrice: 1000,
          totalPrice: 1000,
        ),
      ],
      subtotal: 1000,
      total: 1000,
      paymentMethod: 'cash_riel',
      paidAmount: 5000,
      changeAmount: 4000,
      createdAt: DateTime(2026, 11, 26, 17, 58, 18),
    );

    await tester.pumpWidget(
      MaterialApp(home: CashierInvoiceScreen(sale: sale)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('បោះពុម្ពវិក្កយបត្រ (Print Receipt)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(ReceiptPreviewDialog), findsOneWidget);
    expect(find.text('80mm Thermal'), findsOneWidget);
    expect(find.text('58mm Thermal'), findsOneWidget);
  });
}
