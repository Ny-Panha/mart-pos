import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/firestore/models/sale_model.dart';

class CashierInvoiceScreen extends StatelessWidget {
  final SaleModel sale;
  const CashierInvoiceScreen({super.key, required this.sale});

  void _copyInvoice(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _receiptText()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invoice copied for printing')),
    );
  }

  String _receiptText() {
    final lines = <String>[
      'Invoice ${sale.invoiceNumber}',
      DateUtilsHelper.formatDateTime(sale.createdAt),
      '',
    ];
    lines.addAll(
      sale.items.map(
        (item) =>
            '${item.name} x${item.qty}  ${MoneyUtils.formatRiel(item.totalPrice)}',
      ),
    );
    lines.add('TOTAL: ${MoneyUtils.formatRiel(sale.total)}');
    lines.add('Payment: ${sale.paymentMethod.toUpperCase()}');
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${sale.invoiceNumber}'),
        actions: [
          IconButton(
            tooltip: 'Reprint',
            onPressed: () => _copyInvoice(context),
            icon: const Icon(Icons.print_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'INVOICE',
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: AppColors.primary, letterSpacing: 2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sale.invoiceNumber,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    DateUtilsHelper.formatDateTime(sale.createdAt),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const Divider(height: 32),
                  ...sale.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(child: Text('${item.name} × ${item.qty}')),
                          Text(
                            MoneyUtils.formatRiel(item.totalPrice),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 28),
                  _line('Subtotal', sale.subtotal),
                  if (sale.discount > 0) _line('Discount', -sale.discount),
                  if (sale.totalTax > 0) _line('Tax', sale.totalTax),
                  const SizedBox(height: 8),
                  _line('TOTAL', sale.total, emphasize: true),
                  _line('Paid', sale.paidAmount),
                  _line('Change', sale.changeAmount),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () => _copyInvoice(context),
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Copy receipt for printing'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _line(String label, int amount, {bool emphasize = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          MoneyUtils.formatRiel(amount),
          style: TextStyle(
            fontWeight: emphasize ? FontWeight.bold : FontWeight.w500,
            color: emphasize ? AppColors.primary : null,
          ),
        ),
      ],
    ),
  );
}
