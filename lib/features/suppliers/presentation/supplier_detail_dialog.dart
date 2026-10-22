import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/firestore/models/supplier_model.dart';
import '../../purchases/presentation/purchase_detail_dialog.dart';
import '../../purchases/providers/purchase_provider.dart';

class SupplierDetailDialog extends ConsumerWidget {
  final SupplierModel supplier;

  const SupplierDetailDialog({super.key, required this.supplier});

  static Future<void> show(BuildContext context, {required SupplierModel supplier}) {
    if (Responsive.isDesktop(context) || Responsive.isTablet(context)) {
      return showDialog<void>(
        context: context,
        builder: (_) => SupplierDetailDialog(supplier: supplier),
      );
    } else {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => SupplierDetailDialog(supplier: supplier),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = Responsive.isDesktop(context) || Responsive.isTablet(context);
    final purchasesAsync = ref.watch(purchasesBySupplierProvider(supplier.id));

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
                Icons.storefront_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          supplier.name,
                          style: AppTextStyles.titleLG.copyWith(
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: supplier.active
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.lightMutedText.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          supplier.active ? 'សកម្ម (Active)' : 'ផ្អាក (Inactive)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: supplier.active ? AppColors.success : AppColors.lightMutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ប្រវត្តិបញ្ជាទិញចូលស្តុកពីអ្នកផ្គត់ផ្គង់នេះ',
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

        // Contact info card
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
              if (supplier.phone != null && supplier.phone!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('ទូរស័ព្ទ: ${supplier.phone}', style: AppTextStyles.body),
                    ],
                  ),
                ),
              if (supplier.address != null && supplier.address!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('អាសយដ្ឋាន: ${supplier.address}', style: AppTextStyles.body),
                      ),
                    ],
                  ),
                ),
              if (supplier.note != null && supplier.note!.isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note_alt_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('ចំណាំ: ${supplier.note}', style: AppTextStyles.body),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Purchases Section Title
        Text(
          'ប្រវត្តិវិក្កយបត្រទិញចូល (Purchase History)',
          style: AppTextStyles.bodyBold,
        ),
        const SizedBox(height: 10),

        // Purchases List
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: purchasesAsync.when(
            data: (purchases) {
              if (purchases.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'មិនទាន់មានប្រវត្តិទិញចូលទេ',
                    subtitle: 'មិនទាន់មានការកត់ត្រាការទិញចូលពីអ្នកផ្គត់ផ្គង់នេះនៅឡើយទេ',
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                itemCount: purchases.length,
                separatorBuilder: (_, _) => const Divider(height: 12),
                itemBuilder: (context, index) {
                  final p = purchases[index];
                  final totalRiel = MoneyUtils.formatRiel(p.totalCost);
                  final totalUsd = MoneyUtils.formatUSD(MoneyUtils.rielToUsd(p.totalCost));
                  final dateStr =
                      '${p.createdAt.day.toString().padLeft(2, '0')}/${p.createdAt.month.toString().padLeft(2, '0')}/${p.createdAt.year}';

                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: AppColors.secondary,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      'វិក្កយបត្រ #${p.id.length > 8 ? p.id.substring(0, 8) : p.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text(
                      '$dateStr • ${p.items.length} មុខទំនិញ',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          totalRiel,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          totalUsd,
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    onTap: () => PurchaseDetailDialog.show(context, purchase: p),
                  );
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error loading purchases: $err', style: const TextStyle(color: AppColors.danger)),
            ),
          ),
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
      return Material(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(child: content),
        ),
      );
    }
  }
}
