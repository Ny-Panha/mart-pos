import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_header.dart';
import '../../../data/firestore/models/product_model.dart';
import '../../../data/services/audit_service.dart';
import '../providers/category_provider.dart';
import '../providers/product_provider.dart';
import 'category_manager_dialog.dart';
import 'product_form_dialog.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  Future<void> _handleDeleteProduct(
    BuildContext context,
    WidgetRef ref,
    ProductModel product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 24),
            SizedBox(width: 8),
            Text('លុបទំនិញ? (Delete Product)'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'តើអ្នកពិតជាចង់លុបទំនិញ "${product.name}" មែនទេ?',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('លេខកូដ (Code): ${product.code}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text('បារកូដ (Barcode): ${product.barcode.isNotEmpty ? product.barcode : "-"}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            const Text(
              'ទិន្នន័យទំនិញ និងលេខកូដក្នុង Firestore នឹងត្រូវបានលុបជាអចិន្ត្រៃយ៍។ សកម្មភាពនេះមិនអាចត្រឡប់វិញបានទេ។',
              style: TextStyle(fontSize: 12, color: AppColors.danger),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('បោះបង់ (Cancel)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('លុបចេញ (DELETE)', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(productRepositoryProvider).deleteProduct(product.id, product.code);

        // Fire-and-forget Audit Log
        AuditService.logFromRef(
          ref,
          action: 'product.delete',
          entityType: 'product',
          entityId: product.id,
          details: '${product.name} (${product.code})',
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('បានលុបទំនិញ "${product.name}" រួចរាល់!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e'), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = Responsive.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final products = ref.watch(filteredProductsProvider);
    final categories = ref.watch(categoriesStreamProvider).value ?? [];
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              onPressed: () => ProductFormDialog.show(context),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            PageHeader(
              eyebrow: 'Inventory Management',
              title: 'គ្រប់គ្រងទំនិញ (Products & Categories)',
              description: 'Create, update, organize categories, and track retail pricing in Riel',
              actions: [
                OutlinedButton.icon(
                  onPressed: () => CategoryManagerDialog.show(context),
                  icon: const Icon(Icons.category_outlined, size: 16),
                  label: const Text('ប្រភេទ (Categories)'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                if (isDesktop) ...[
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 170,
                    child: AppButton(
                      text: '+ NEW PRODUCT',
                      onPressed: () => ProductFormDialog.show(context),
                      icon: Icons.add,
                    ),
                  ),
                ],
              ],
            ),

            // Toolbar (Search + Category Filter + Total Count)
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 260,
                    child: TextField(
                      onChanged: (v) => ref.read(productSearchQueryProvider.notifier).setQuery(v),
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'ស្វែងរកឈ្មោះទំនិញ ឬបារកូដ...',
                        prefixIcon: Icon(Icons.search, size: 20),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                  DropdownButton<String>(
                    value: (selectedCategory == 'all' || categories.any((c) => c.id == selectedCategory))
                        ? selectedCategory
                        : 'all',
                    underline: const SizedBox(),
                    items: [
                      const DropdownMenuItem(value: 'all', child: Text('ប្រភេទទំនិញទាំងអស់ (All)')),
                      ...categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.name),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(selectedCategoryProvider.notifier).setCategory(val);
                      }
                    },
                  ),
                  const Spacer(),
                  Text(
                    'Total: ${products.length} Items',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Responsive Presentation: Desktop Data Table vs Mobile Card List
            if (products.isEmpty)
              const EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'គ្មានទំនិញទេ (No Products Found)',
                subtitle: 'សាកល្បងស្វែងរកឈ្មោះផ្សេង ឬចុច "+ NEW PRODUCT" ដើម្បីបញ្ចូលទំនិញថ្មី',
              )
            else if (isDesktop)
              _buildDesktopTable(context, ref, products, isDark)
            else
              _buildMobileCards(context, ref, products, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable(
    BuildContext context,
    WidgetRef ref,
    List<ProductModel> products,
    bool isDark,
  ) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            isDark ? AppColors.darkSurface : AppColors.lightBg,
          ),
          columns: const [
            DataColumn(label: Text('CODE / BARCODE', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('PRODUCT NAME', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('COST PRICE', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('SALE PRICE', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('STOCK', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: products.map((p) {
            return DataRow(cells: [
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(p.barcode.isNotEmpty ? p.barcode : '-', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text(MoneyUtils.formatRiel(p.costPrice))),
              DataCell(Text(
                MoneyUtils.formatRiel(p.salePrice),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              )),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: p.isOutOfStock
                        ? AppColors.danger.withValues(alpha: 0.1)
                        : (p.isLowStock
                            ? AppColors.warning.withValues(alpha: 0.1)
                            : AppColors.success.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${p.stockQty} ${p.unit}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: p.isOutOfStock
                          ? AppColors.danger
                          : (p.isLowStock ? AppColors.warning : AppColors.success),
                    ),
                  ),
                ),
              ),
              DataCell(
                Text(
                  p.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: p.isActive ? AppColors.success : Colors.grey,
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'កែប្រែ (Edit)',
                      onPressed: () => ProductFormDialog.show(context, product: p),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                      tooltip: 'លុប (Delete)',
                      onPressed: () => _handleDeleteProduct(context, ref, p),
                    ),
                  ],
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileCards(
    BuildContext context,
    WidgetRef ref,
    List<ProductModel> products,
    bool isDark,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final p = products[index];
        return AppCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      '${p.code} • ${p.barcode.isNotEmpty ? p.barcode : "-"}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      MoneyUtils.formatRiel(p.salePrice),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: p.isOutOfStock
                          ? AppColors.danger.withValues(alpha: 0.1)
                          : (p.isLowStock
                              ? AppColors.warning.withValues(alpha: 0.1)
                              : AppColors.success.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${p.stockQty} ${p.unit}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: p.isOutOfStock
                            ? AppColors.danger
                            : (p.isLowStock ? AppColors.warning : AppColors.success),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => ProductFormDialog.show(context, product: p),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                        onPressed: () => _handleDeleteProduct(context, ref, p),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
