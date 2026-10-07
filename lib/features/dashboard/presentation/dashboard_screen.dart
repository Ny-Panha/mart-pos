import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/page_header.dart';
import '../../products/providers/product_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = Responsive.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final products = ref.watch(filteredProductsProvider);
    final lowStockCount = products.where((p) => p.isLowStock).length;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            PageHeader(
              eyebrow: 'System Overview',
              title: 'ផ្ទាំងគ្រប់គ្រង (Admin Dashboard)',
              description: 'Real-time sales analytics, inventory status, and shop performance',
              actions: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('EXPORT REPORT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                  ),
                ),
              ],
            ),

            // Metric Cards Grid
            LayoutBuilder(builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 550 ? 2 : 1);
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: constraints.maxWidth > 900 ? 2.1 : 2.4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollExceptionStream(),
                children: [
                  _buildMetricCard(
                    title: 'Total Revenue (ចំណូលសរុប)',
                    value: MoneyUtils.formatRiel(15420000), // 15.42M Riel
                    subValue: MoneyUtils.formatUSD(MoneyUtils.rielToUsd(15420000)),
                    icon: Icons.monetization_on_outlined,
                    color: AppColors.primary,
                  ),
                  _buildMetricCard(
                    title: 'Total Orders (ការលក់)',
                    value: '184 Orders',
                    subValue: '+12% from yesterday',
                    icon: Icons.receipt_long_outlined,
                    color: AppColors.secondary,
                  ),
                  _buildMetricCard(
                    title: 'Active Products (ទំនិញ)',
                    value: '${products.length} Items',
                    subValue: '4 Categories',
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.success,
                  ),
                  _buildMetricCard(
                    title: 'Low Stock Alerts (ស្តុកទាប)',
                    value: '$lowStockCount Items',
                    subValue: 'Requires reorder soon',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.warning,
                  ),
                ],
              );
            }),
            const SizedBox(height: 28),

            // Revenue Chart & Recent Sales side-by-side or stacked
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: _buildRevenueChartCard(isDark)),
                  const SizedBox(width: 20),
                  Expanded(flex: 5, child: _buildRecentSalesCard(isDark)),
                ],
              )
            else
              Column(
                children: [
                  _buildRevenueChartCard(isDark),
                  const SizedBox(height: 20),
                  _buildRecentSalesCard(isDark),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subValue,
    required IconData icon,
    required Color color,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, maxLines: 1, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                Text(subValue, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChartCard(bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('30-Day Revenue Trend (ចំណូល ៣០ ថ្ងៃ)', style: AppTextStyles.titleLG),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Monthly (KHR)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(1, 1.2),
                      FlSpot(5, 1.8),
                      FlSpot(10, 2.4),
                      FlSpot(15, 2.1),
                      FlSpot(20, 3.2),
                      FlSpot(25, 2.9),
                      FlSpot(30, 4.1),
                    ],
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3.5,
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSalesCard(bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Transactions', style: AppTextStyles.titleLG),
              const Text('See All', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollExceptionStream(),
            itemCount: 4,
            separatorBuilder: (_, _) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final invoices = ['INV-000142', 'INV-000141', 'INV-000140', 'INV-000139'];
              final amounts = [12500, 8000, 24600, 5000];
              final times = ['10 mins ago', '25 mins ago', '1 hr ago', '2 hrs ago'];

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(invoices[index], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(times[index], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  Text(
                    MoneyUtils.formatRiel(amounts[index]),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 14),
                  ),
                ],
              );
            },
          ),
        ],
      ),
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
