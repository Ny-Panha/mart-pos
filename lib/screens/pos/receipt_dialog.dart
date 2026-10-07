import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/sale_model.dart';
import '../../widgets/mart_logo.dart';

class ReceiptDialog extends StatelessWidget {
  final SaleModel sale;

  const ReceiptDialog({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
    final currencyUSD = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final currencyKHR = NumberFormat.currency(symbol: '៛', decimalDigits: 0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Store Header & Logo
              Center(
                child: Column(
                  children: [
                    const MartLogo(size: 48),
                    const SizedBox(height: 6),
                    const Text(
                      '🏪 ម៉ាត សាមគ្គី (BBU MART)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const Text(
                      'Build Bright University • Battambang',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Text(
                      'វិក្កយបត្រ / OFFICIAL RECEIPT',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Divider(thickness: 1.2, height: 24),

              // Invoice Details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('លេខវិក្កយបត្រ: ${sale.invoiceNo}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(dateFormat.format(sale.createdAt), style: const TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('អ្នកគិតលុយ: ${sale.cashierName}', style: const TextStyle(fontSize: 12)),
                  Text('អតិថិជន: ${sale.customerName}', style: const TextStyle(fontSize: 12, color: Colors.indigo)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ការទូទាត់: ${sale.paymentMethod}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  if (sale.redeemedPoints > 0)
                    Text('កាត់ពិន្ទុ: ${sale.redeemedPoints}', style: const TextStyle(fontSize: 12, color: Colors.red)),
                ],
              ),
              const Divider(thickness: 1.2, height: 20),

              // Itemized List Header
              const Row(
                children: [
                  Expanded(flex: 4, child: Text('ទំនិញ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(flex: 2, child: Text('ចំនួន', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(flex: 2, child: Text('តម្លៃ', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(flex: 2, child: Text('សរុប', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
              ),
              const SizedBox(height: 8),

              // Items
              ...sale.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(item.product.name, style: const TextStyle(fontSize: 12)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('x${item.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(currencyUSD.format(item.unitPrice), textAlign: TextAlign.right, style: const TextStyle(fontSize: 12)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(currencyUSD.format(item.total), textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                );
              }),

              const Divider(thickness: 1.2, height: 20),

              // Totals
              _buildSummaryRow('តម្លៃសរុប (USD):', currencyUSD.format(sale.totalUSD), isBold: true),
              _buildSummaryRow('តម្លៃសរុប (KHR):', currencyKHR.format(sale.totalKHR), isBold: true),
              if (sale.discountUSD > 0)
                _buildSummaryRow('បញ្ចុះតម្លៃ (Discount):', '-${currencyUSD.format(sale.discountUSD)}'),
              _buildSummaryRow('ប្រាក់ទទួលបាន (Received):', currencyUSD.format(sale.cashReceived)),
              _buildSummaryRow('ប្រាក់អាប់ (Change):', currencyUSD.format(sale.changeGiven), isHighlight: true),

              const SizedBox(height: 14),

              // QR Code for KHQR
              Center(
                child: Column(
                  children: [
                    QrImageView(
                      data: 'KHQR:MART:${sale.invoiceNo}:${sale.totalUSD}:USD',
                      version: QrVersions.auto,
                      size: 90.0,
                    ),
                    const SizedBox(height: 4),
                    const Text('ស្កេនដើម្បីផ្ទៀងផ្ទាត់ / Bakong KHQR', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              const Center(
                child: Text('🙏 សូមអរគុណ! សូមអញ្ជើញមកម្តងទៀត',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              const Center(
                child: Text('Team Daly • Sreyphkay • Panha (BBU)',
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
              ),
              const SizedBox(height: 14),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.print_rounded),
                      label: const Text('បោះពុម្ព (Print)'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('កំពុងផ្ញើទៅកាន់ម៉ាស៊ីនបោះពុម្ពវិក្កយបត្រ (Thermal Printer)...')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade800,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('រួចរាល់ (Done)'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isHighlight ? Colors.green.shade800 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
