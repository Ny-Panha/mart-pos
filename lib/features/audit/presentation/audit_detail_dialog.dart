import 'package:mart_pos/core/motion/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/product_thumbnail.dart';
import '../../../data/firestore/models/audit_log_model.dart';
import '../../../data/firestore/models/category_model.dart';
import '../../../data/firestore/models/product_model.dart';
import '../../../data/firestore/models/sale_model.dart';
import '../../products/providers/category_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../reports/providers/report_provider.dart';

class AuditDetailDialog extends ConsumerWidget {
  final AuditLogModel log;

  const AuditDetailDialog({super.key, required this.log});

  static Future<void> show(BuildContext context, {required AuditLogModel log}) {
    if (Responsive.isDesktop(context) || Responsive.isTablet(context)) {
      return showMotionDialog<void>(
        context: context,
        builder: (_) => AuditDetailDialog(log: log),
      );
    } else {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AuditDetailDialog(log: log),
      );
    }
  }

  static Color getActionColor(String action) {
    if (action.startsWith('sale.')) return AppColors.success;
    if (action.startsWith('product.')) return AppColors.primary;
    if (action.startsWith('stock.')) return AppColors.warning;
    if (action.startsWith('purchase.')) return AppColors.secondary;
    if (action.startsWith('user.')) return Colors.indigo;
    if (action.startsWith('shift.')) return Colors.deepOrange;
    return Colors.grey;
  }

  static IconData getActionIcon(String action) {
    if (action.startsWith('sale.')) return Icons.receipt_long_rounded;
    if (action.startsWith('product.')) return Icons.inventory_2_outlined;
    if (action.startsWith('stock.')) return Icons.swap_vert_circle_outlined;
    if (action.startsWith('purchase.')) return Icons.shopping_bag_outlined;
    if (action.startsWith('user.')) return Icons.badge_outlined;
    if (action.startsWith('shift.')) return Icons.punch_clock_outlined;
    return Icons.history_toggle_off_rounded;
  }

  static String _friendlyEntityLabel(String entityType) {
    switch (entityType.toLowerCase()) {
      case 'sale':
        return 'ការលក់ (Sale)';
      case 'product':
        return 'ទំនិញ (Product)';
      case 'stock':
        return 'ស្តុក (Stock)';
      case 'purchase':
        return 'ការទិញចូល (Purchase)';
      case 'user':
        return 'បុគ្គលិក (User)';
      case 'shift':
        return 'វេនលក់ (Shift)';
      case 'category':
        return 'ប្រភេទទំនិញ (Category)';
      default:
        return entityType.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = Responsive.isDesktop(context) || Responsive.isTablet(context);
    final color = getActionColor(log.action);
    final icon = getActionIcon(log.action);

    final products = ref.watch(productsStreamProvider).asData?.value ?? const <ProductModel>[];
    final categories = ref.watch(categoriesStreamProvider).asData?.value ?? const <CategoryModel>[];
    final sales = ref.watch(allRecentSalesProvider).asData?.value ?? const <SaleModel>[];
    final productMap = {for (final p in products) p.id: p};
    final categoryMap = {for (final c in categories) c.id: c.name};

    SaleModel? matchedSale;
    if (log.entityType.toLowerCase() == 'sale') {
      for (final s in sales) {
        if (s.id == log.entityId ||
            (s.invoiceNumber.isNotEmpty && log.details.contains(s.invoiceNumber))) {
          matchedSale = s;
          break;
        }
      }
    }
    final ProductModel? matchedProduct = productMap[log.entityId];

    final dateStr =
        '${log.createdAt.day.toString().padLeft(2, '0')}/${log.createdAt.month.toString().padLeft(2, '0')}/${log.createdAt.year} '
        '${log.createdAt.hour.toString().padLeft(2, '0')}:${log.createdAt.minute.toString().padLeft(2, '0')}:${log.createdAt.second.toString().padLeft(2, '0')}';

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
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          log.action.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: color,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
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
        const SizedBox(height: 20),

        // Info container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            children: [
              _buildDetailItem(
                context,
                icon: Icons.person_outline,
                label: 'ប្រតិបត្តិការដោយ (Performed By):',
                value: log.userName,
              ),
              const Divider(height: 18),
              _buildDetailItem(
                context,
                icon: Icons.category_outlined,
                label: 'ប្រភេទប្រតិបត្តិការ (Type):',
                value: _friendlyEntityLabel(log.entityType),
              ),
              const Divider(height: 18),
              _buildDetailItem(
                context,
                icon: Icons.notes_rounded,
                label: 'ព័ត៌មានលម្អិត (Details):',
                value: log.details.isNotEmpty ? log.details : 'None',
                isHighlight: true,
                color: color,
              ),
            ],
          ),
        ),
        if (matchedSale != null && matchedSale.items.isNotEmpty) ...[
          const SizedBox(height: 14),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ទំនិញពាក់ព័ន្ធ (Products & Category):',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...matchedSale.items.map((item) {
                  final prod = productMap[item.productId];
                  final catName = prod != null
                      ? (categoryMap[prod.categoryId] ?? 'General')
                      : 'General';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ProductThumbnail(
                            imageUrl: prod?.imageUrl ?? '',
                            productId: item.productId,
                            productName: item.name,
                            barcode: prod?.barcode ?? '',
                            width: 36,
                            height: 36,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '$catName • ${item.qty} × ${MoneyUtils.formatRiel(item.unitPrice)}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          MoneyUtils.formatRiel(item.totalPrice),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ] else if (matchedProduct != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ProductThumbnail(
                    imageUrl: matchedProduct.imageUrl,
                    productId: matchedProduct.id,
                    productName: matchedProduct.name,
                    barcode: matchedProduct.barcode,
                    width: 40,
                    height: 40,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        matchedProduct.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        categoryMap[matchedProduct.categoryId] ?? 'General',
                        style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),

        // Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('បិទ (Close)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );

    if (isDesktop) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: Container(
          width: 520,
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
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(child: content),
        ),
      );
    }
  }

  Widget _buildDetailItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isHighlight = false,
    Color? color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              SelectableText(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                  color: isHighlight && color != null ? color : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
