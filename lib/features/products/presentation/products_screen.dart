import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/page_header.dart';
import '../../../data/firestore/models/product_model.dart';
import '../providers/product_provider.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = Responsive.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final products = ref.watch(filteredProductsProvider);

    return Scaffold(
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              onPressed: () {},
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
                if (isDesktop)
                  SizedBox(
                    width: 170,
                    child: AppButton(
                      text: '+ NEW PRODUCT',
                      onPressed: () {},
                      icon: Icons.add,
                    ),
                  ),
              ],
            ),

            // Toolbar (Search + Category Filter + Page Size)
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
                    value: ref.watch(selectedCategoryProvider),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('ប្រភេទទំនិញទាំងអស់ (All)')),
                      DropdownMenuItem(value: 'cat_drinks', child: Text('ភេសជ្ជៈ (Drinks)')),
                      DropdownMenuItem(value: 'cat_food', child: Text('អាហារ និងមី (Food)')),
                      DropdownMenuItem(value: 'cat_snacks', child: Text('នំចំណី (Snacks)')),
                      DropdownMenuItem(value: 'cat_daily', child: Text('សម្ភារៈប្រើប្រាស់ (Daily)')),
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
            if (isDesktop)
              _buildDesktopTable(products, isDark)
            else
              _buildMobileCards(products, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable(List<ProductModel> products, bool isDark) {
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
                    Text(p.barcode, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger), onPressed: () {}),
                  ],
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileCards(List<ProductModel> products, bool isDark) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollExceptionStream(),
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
                    Text('${p.barcode} • ${p.stockQty} ${p.unit}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Text(
                MoneyUtils.formatRiel(p.salePrice),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 15),
              ),
            ],
          ),
        );
      },
    );
  }
}
class NeverScrollableScrollExceptionStream extends ScrollPhysics {
  const NeverScrollableScrollExceptionStream({super.parent});
  @override
  NeverScrollableScrollExceptionStream applyTo(ScrollPhysics? ancestor) {
    return NeverScrollableScrollExceptionStream(parent: buildParent(ancestor));
  }
  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => false;
}
