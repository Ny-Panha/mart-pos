import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date.dart';
import '../../../../core/utils/money.dart';
import '../../../../data/firestore/models/sale_model.dart';

class SaleDetailDialog extends StatelessWidget {
  final SaleModel sale;

  const SaleDetailDialog({super.key, required this.sale});

  static void show(BuildContext context, SaleModel sale) {
    showDialog(
      context: context,
      builder: (ctx) => SaleDetailDialog(sale: sale),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isKhqr = sale.paymentMethod.toLowerCase() == 'khqr';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('វិក្កយបត្រ (Invoice Details)', style: AppTextStyles.titleLG),
                    Text(sale.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Meta banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightBg,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('កាលបរិច្ឆេទ (Date/Time):', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(DateUtilsHelper.formatDateTime(sale.createdAt), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('បេឡា (Cashier):', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        sale.cashierId.length > 10 ? '${sale.cashierId.substring(0, 8)}...' : sale.cashierId,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('វិធីទូទាត់ (Payment):', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isKhqr ? AppColors.danger : AppColors.success).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          sale.paymentMethod.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isKhqr ? AppColors.danger : AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Items List
            const Text('ទំនិញដែលបានទិញ (Purchased Items):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),

            Expanded(
              child: ListView.separated(
                itemCount: sale.items.length,
                separatorBuilder: (_, _) => const Divider(height: 12),
                itemBuilder: (context, index) {
                  final item = sale.items[index];
                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(
                              '${item.qty} x ${MoneyUtils.formatRiel(item.unitPrice)}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        MoneyUtils.formatRiel(item.totalPrice),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Summary Totals
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(MoneyUtils.formatRiel(sale.subtotal), style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            if (sale.discount > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Discount:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('-${MoneyUtils.formatRiel(sale.discount)}', style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
            if (sale.totalTax > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tax (VAT):', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(MoneyUtils.formatRiel(sale.totalTax), style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL AMOUNT:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                  MoneyUtils.formatDual(sale.total),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ប្រាក់ទទួល (Paid):', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(MoneyUtils.formatRiel(sale.paidAmount), style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ប្រាក់អាប់ (Change):', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(MoneyUtils.formatRiel(sale.changeAmount), style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 18),

            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('បិទ (Close)'),
            ),
          ],
        ),
      ),
    );
  }
}
