import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_header.dart';
import '../providers/cashier_provider.dart';

class CashierStockScreen extends ConsumerWidget {
  const CashierStockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stock = ref.watch(cashierStockProvider);
    final products = ref.watch(filteredCashierStockProvider);
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              eyebrow: 'Cashier Operations',
              title: 'ពិនិត្យស្តុកទំនិញ (Stock Check)',
              description: 'ស្វែងរកចំនួនស្តុកទំនិញជាក់ស្តែងក្នុងហាង មុនពេលទទួលការកុម្ម៉ង់',
            ),
            TextField(
              onChanged: (value) =>
                  ref.read(cashierSearchProvider.notifier).setQuery(value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Product, barcode or SKU',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            stock.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Text(
                'Unable to load stock: $error',
                style: const TextStyle(color: AppColors.danger),
              ),
              data: (_) => products.isEmpty
                  ? const SizedBox(
                      height: 280,
                      child: EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'No matching products',
                        subtitle: 'Try another name or barcode.',
                      ),
                    )
                  : AppCard(
                      padding: EdgeInsets.zero,
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final product = products[index];
                          final color = product.isOutOfStock
                              ? AppColors.danger
                              : product.isLowStock
                              ? AppColors.warning
                              : AppColors.success;
                          return ListTile(
                            leading: const Icon(Icons.inventory_2_outlined),
                            title: Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${product.barcode.isEmpty ? product.sku : product.barcode} • ${product.unit}',
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${product.stockQty}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  product.isOutOfStock
                                      ? 'OUT'
                                      : product.isLowStock
                                      ? 'LOW'
                                      : 'IN STOCK',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
