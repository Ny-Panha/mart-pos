import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_header.dart';
import '../../../data/firestore/models/product_model.dart';
import '../../../data/firestore/models/sale_model.dart';
import '../providers/admin_shop_provider.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref.watch(adminReportSalesProvider);
    final products = ref.watch(adminReportProductsProvider);
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              eyebrow: 'Shop admin',
              title: 'Shop reports',
              description: 'Sales, stock, estimated profit and best sellers.',
              actions: [
                Wrap(
                  spacing: 8,
                  children: [
                    const ChoiceChip(
                      label: Text('Today'),
                      selected: true,
                      onSelected: null,
                    ),
                    ChoiceChip(
                      label: const Text('7 days'),
                      selected: false,
                      onSelected: (_) => ref
                          .read(adminReportRangeProvider.notifier)
                          .setDays(7),
                    ),
                    ChoiceChip(
                      label: const Text('30 days'),
                      selected: false,
                      onSelected: (_) => ref
                          .read(adminReportRangeProvider.notifier)
                          .setDays(30),
                    ),
                  ],
                ),
              ],
            ),
            sales.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(
                'Unable to load report: $e',
                style: const TextStyle(color: AppColors.danger),
              ),
              data: (saleList) => products.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(
                  'Unable to load products: $e',
                  style: const TextStyle(color: AppColors.danger),
                ),
                data: (productList) => _reportBody(saleList, productList),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportBody(List<SaleModel> sales, List<ProductModel> products) {
    final productsMap = {for (final product in products) product.id: product};
    final revenue = sales.fold<int>(0, (sum, sale) => sum + sale.total);
    final profit = sales.fold<int>(
      0,
      (sum, sale) =>
          sum +
          sale.items.fold<int>(
            0,
            (itemSum, item) =>
                itemSum +
                item.totalPrice -
                ((productsMap[item.productId]?.costPrice ?? 0) * item.qty),
          ),
    );
    final bestSellers = <String, int>{};
    for (final sale in sales) {
      for (final item in sale.items) {
        bestSellers[item.name] = (bestSellers[item.name] ?? 0) + item.qty;
      }
    }
    final sorted = bestSellers.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (_, constraints) => GridView.count(
            crossAxisCount: constraints.maxWidth > 780 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _metric(
                'Revenue',
                MoneyUtils.formatRiel(revenue),
                AppColors.primary,
              ),
              _metric(
                'Profit',
                MoneyUtils.formatRiel(profit),
                AppColors.success,
              ),
              _metric('Sales', '${sales.length}', AppColors.secondary),
              _metric('Products', '${products.length}', AppColors.warning),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Best sellers',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (sorted.isEmpty)
                const EmptyState(
                  icon: Icons.insights_outlined,
                  title: 'No sales in this period',
                  subtitle: 'Best sellers will appear after checkout.',
                )
              else
                ...sorted
                    .take(10)
                    .map(
                      (entry) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.trending_up),
                        title: Text(entry.key),
                        trailing: Text(
                          '${entry.value} sold',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metric(String title, String value, Color color) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: color,
          ),
        ),
      ],
    ),
  );
}
