import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/utils/date.dart';
import '../../../../core/utils/money.dart';
import '../../../../data/firestore/models/sale_model.dart';
import 'sale_detail_dialog.dart';

class SaleListTile extends StatelessWidget {
  final SaleModel sale;

  const SaleListTile({super.key, required this.sale});

  String _formatRelativeDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday, ${DateUtilsHelper.formatTime(dt)}';
    return '${DateUtilsHelper.formatDate(dt)} • ${DateUtilsHelper.formatTime(dt)}';
  }

  @override
  Widget build(BuildContext context) {
    final isKhqr = sale.paymentMethod.toLowerCase() == 'khqr';
    final cashierShort = sale.cashierId.length > 8
        ? '${sale.cashierId.substring(0, 6)}...'
        : sale.cashierId;

    return InkWell(
      onTap: () => SaleDetailDialog.show(context, sale),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isKhqr ? AppColors.danger : AppColors.success).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                isKhqr ? Icons.qr_code_rounded : Icons.payments_outlined,
                color: isKhqr ? AppColors.danger : AppColors.success,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        sale.invoiceNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isKhqr ? AppColors.danger : AppColors.success).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          sale.paymentMethod.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isKhqr ? AppColors.danger : AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${sale.items.length} items • By: $cashierShort • ${_formatRelativeDate(sale.createdAt)}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  MoneyUtils.formatRiel(sale.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  MoneyUtils.formatUSD(MoneyUtils.rielToUsd(sale.total)),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
