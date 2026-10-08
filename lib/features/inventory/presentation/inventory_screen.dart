import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/utils/date.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_header.dart';
import '../../../data/firestore/models/product_model.dart';
import '../../../data/firestore/models/stock_movement_model.dart';
import '../../products/providers/product_provider.dart';
import '../../purchases/presentation/purchase_form_dialog.dart';
import '../providers/inventory_provider.dart';
import 'stock_action_dialog.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = Responsive.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final movementsAsync = ref.watch(stockMovementsProvider);
    final lowStockProducts = ref.watch(lowStockProductsProvider);
    final allProducts = ref.watch(productsStreamProvider).value ?? [];
    final selectedFilter = ref.watch(inventoryProductFilterProvider);

    // Map productId -> ProductModel for fast lookups
    final productMap = {for (var p in allProducts) p.id: p};

    return Scaffold(
      floatingActionButton: !isDesktop
          ? FloatingActionButton.extended(
              onPressed: () => StockActionDialog.show(
                context,
                actionType: StockActionType.stockIn,
              ),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label: const Text('STOCK IN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Page Header
            PageHeader(
              eyebrow: 'Stock Control',
              title: 'ស្តុកទំនិញ (Stock Movements)',
              description: 'Track incoming deliveries, stock adjustments, and sale deductions in real-time',
              actions: [
                OutlinedButton.icon(
                  onPressed: () => StockActionDialog.show(
                    context,
                    actionType: StockActionType.stockOut,
                  ),
                  icon: const Icon(Icons.remove_circle_outline, size: 16, color: AppColors.danger),
                  label: const Text('STOCK OUT', style: TextStyle(color: AppColors.danger)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => StockActionDialog.show(
                    context,
                    actionType: StockActionType.adjust,
                  ),
                  icon: const Icon(Icons.tune_rounded, size: 16),
                  label: const Text('ADJUST'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                if (isDesktop) ...[
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 160,
                    child: AppButton(
                      text: '+ STOCK IN',
                      onPressed: () => StockActionDialog.show(
                        context,
                        actionType: StockActionType.stockIn,
                      ),
                      icon: Icons.add_circle_outline,
                    ),
                  ),
                ],
              ],
            ),

            // 2. Low-Stock Alert Card (if any low/out of stock products exist)
            if (lowStockProducts.isNotEmpty) ...[
              _buildLowStockAlertCard(context, lowStockProducts, isDark),
              const SizedBox(height: 20),
            ],

            // 3. Filter Toolbar
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.filter_list_rounded, size: 20, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'តម្រងតាមទំនិញ (Filter by Product):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 280,
                    child: DropdownButton<String>(
                      value: (selectedFilter == 'all' || allProducts.any((p) => p.id == selectedFilter))
                          ? selectedFilter
                          : 'all',
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: [
                        const DropdownMenuItem(value: 'all', child: Text('ចលនាទាំងអស់ (All Products)')),
                        ...allProducts.map((p) {
                          return DropdownMenuItem(
                            value: p.id,
                            child: Text(
                              '${p.name} (${p.stockQty} ${p.unit})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(inventoryProductFilterProvider.notifier).setFilter(val);
                        }
                      },
                    ),
                  ),
                  if (selectedFilter != 'all')
                    TextButton.icon(
                      onPressed: () => ref.read(inventoryProductFilterProvider.notifier).setFilter('all'),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reset'),
                    ),
                  const Spacer(),
                  movementsAsync.maybeWhen(
                    data: (list) => Text(
                      'Total: ${list.length} Movements',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                      ),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. Movement History Card
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ប្រវត្តិចលនាស្តុក (Stock Movement History)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Latest 100 entries',
                          style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  movementsAsync.when(
                    data: (movements) {
                      if (movements.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.0),
                          child: EmptyState(
                            icon: Icons.history_toggle_off_rounded,
                            title: 'គ្មានប្រវត្តិចលនាស្តុកទេ (No Stock Movements)',
                            subtitle: 'ចុច "+ STOCK IN" ដើម្បីកត់ត្រាទំនិញចូល ឬរៀបចំការលក់ចេញតាម POS',
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: movements.length,
                        separatorBuilder: (_, _) => const Divider(height: 20),
                        itemBuilder: (context, index) {
                          final movement = movements[index];
                          final product = productMap[movement.productId];
                          return _buildMovementRow(movement, product, isDark);
                        },
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text('Error loading movements: $e', style: const TextStyle(color: AppColors.danger)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockAlertCard(
    BuildContext context,
    List<ProductModel> lowStockProducts,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 22),
              const SizedBox(width: 8),
              Text(
                'ការប្រកាសអាសន្នស្តុក (Low Stock Alert: ${lowStockProducts.length} Items)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: lowStockProducts.map((p) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: p.isOutOfStock
                        ? AppColors.danger.withValues(alpha: 0.5)
                        : AppColors.warning.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          p.isOutOfStock
                              ? 'អស់ពីស្តុក (0 ${p.unit})'
                              : 'សល់ ${p.stockQty} ${p.unit} (កម្រិត ${p.lowStockThreshold})',
                          style: TextStyle(
                            fontSize: 11,
                            color: p.isOutOfStock ? AppColors.danger : AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        side: const BorderSide(color: AppColors.secondary),
                        foregroundColor: AppColors.secondary,
                      ),
                      onPressed: () => PurchaseFormDialog.show(
                        context,
                        preselectedProduct: p,
                      ),
                      icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 14),
                      label: const Text('ORDER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () => StockActionDialog.show(
                        context,
                        actionType: StockActionType.stockIn,
                        preselectedProduct: p,
                      ),
                      icon: const Icon(Icons.add, size: 14, color: Colors.white),
                      label: const Text('STOCK IN', style: TextStyle(fontSize: 11, color: Colors.white)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementRow(
    StockMovementModel movement,
    ProductModel? product,
    bool isDark,
  ) {
    // Type styling
    IconData icon;
    Color color;
    String sign;
    String typeLabel;

    switch (movement.type) {
      case 'in':
        icon = Icons.arrow_downward_rounded; // Incoming into stock
        color = AppColors.success;
        sign = '+';
        typeLabel = 'Stock In';
        break;
      case 'out':
        icon = Icons.arrow_upward_rounded; // Outgoing from stock
        color = AppColors.danger;
        sign = '-';
        typeLabel = 'Stock Out';
        break;
      case 'adjust':
      default:
        icon = Icons.tune_rounded;
        color = movement.qty >= 0 ? AppColors.success : AppColors.danger;
        sign = movement.qty >= 0 ? '+' : '';
        typeLabel = 'Adjust';
        break;
    }

    final unit = product?.unit ?? 'Units';
    final productName = product?.name ?? 'Product #${movement.productId}';
    final userShort = movement.createdBy.length > 8
        ? '${movement.createdBy.substring(0, 6)}...'
        : movement.createdBy;

    return Row(
      children: [
        // Movement Icon Badge
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),

        // Movement Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    productName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      typeLabel,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '${movement.note ?? "No notes"} • By: $userShort • ${_formatRelativeDate(movement.createdAt)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Movement Qty
        Text(
          '$sign${movement.qty.abs()} $unit',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }
}
