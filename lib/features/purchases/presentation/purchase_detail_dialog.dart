import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/firestore/models/purchase_model.dart';

class PurchaseDetailDialog extends StatelessWidget {
  final PurchaseModel purchase;

  const PurchaseDetailDialog({super.key, required this.purchase});

  static Future<void> show(BuildContext context, {required PurchaseModel purchase}) {
    if (Responsive.isDesktop(context) || Responsive.isTablet(context)) {
      return showDialog<void>(
        context: context,
        builder: (_) => PurchaseDetailDialog(purchase: purchase),
      );
    } else {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PurchaseDetailDialog(purchase: purchase),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = Responsive.isDesktop(context) || Responsive.isTablet(context);

    final totalRiel = MoneyUtils.formatRiel(purchase.totalCost);
    final totalUsd = MoneyUtils.formatUSD(MoneyUtils.rielToUsd(purchase.totalCost));
    final dateStr =
        '${purchase.createdAt.day.toString().padLeft(2, '0')}/${purchase.createdAt.month.toString().padLeft(2, '0')}/${purchase.createdAt.year} ${purchase.createdAt.hour.toString().padLeft(2, '0')}:${purchase.createdAt.minute.toString().padLeft(2, '0')}';

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'វិក្កយបត្រទិញចូល (Purchase #${purchase.id.length > 8 ? purchase.id.substring(0, 8) : purchase.id})',
                    style: AppTextStyles.titleLG.copyWith(
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'កាលបរិច្ឆេទ: $dateStr',
                    style: AppTextStyles.caption.copyWith(
                      color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Info Summary Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('អ្នកផ្គត់ផ្គង់ (Supplier):', style: AppTextStyles.caption),
                  Text(
                    purchase.supplierName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('កត់ត្រាដោយ (Created By):', style: AppTextStyles.caption),
                  Text(
                    purchase.createdBy,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              if (purchase.note != null && purchase.note!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('កំណត់ចំណាំ (Note):', style: AppTextStyles.caption),
                    Flexible(
                      child: Text(
                        purchase.note!,
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Items Breakdown
        Text(
          'មុខទំនិញបានទិញចូល (${purchase.items.length} មុខ):',
          style: AppTextStyles.bodyBold,
        ),
        const SizedBox(height: 10),

        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: purchase.items.length,
            separatorBuilder: (_, _) => const Divider(height: 10),
            itemBuilder: (context, index) {
              final item = purchase.items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            '@ ${MoneyUtils.formatRiel(item.costPrice)} / unit',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'x ${item.qty}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        MoneyUtils.formatRiel(item.subtotal),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),

        // Total Cost Footer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'សរុបថ្លៃដើម (Total Cost):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  totalRiel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  totalUsd,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    if (isDesktop) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: Container(
          width: 580,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(child: content),
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(child: content),
      );
    }
  }
}
