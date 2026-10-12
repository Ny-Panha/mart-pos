import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_header.dart';
import '../../../data/firestore/models/sale_model.dart';
import '../../inventory/providers/inventory_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../reports/presentation/widgets/sale_list_tile.dart';
import '../../reports/providers/report_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = Responsive.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final products = ref.watch(productsStreamProvider).value ?? [];
    final lowStockProducts = ref.watch(lowStockProductsProvider);
    final allSales = ref.watch(allRecentSalesProvider).value ?? [];

    // 1. Calculate Today's Stats
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final todaySales = allSales
        .where((s) => s.createdAt.isAfter(startOfToday))
        .toList();
    final todayRevenue = todaySales.fold<int>(0, (sum, s) => sum + s.total);
    final todayTransactions = todaySales.length;

    // 2. Prepare 30-day aggregated bar chart data
    final dailyTotals = List<int>.filled(30, 0);
    final dailyDates = List<DateTime>.generate(30, (i) {
      final day = now.subtract(Duration(days: 29 - i));
      return DateTime(day.year, day.month, day.day);
    });

    for (final sale in allSales) {
      final saleDay = DateTime(
        sale.createdAt.year,
        sale.createdAt.month,
        sale.createdAt.day,
      );
      for (int i = 0; i < 30; i++) {
        if (saleDay.year == dailyDates[i].year &&
            saleDay.month == dailyDates[i].month &&
            saleDay.day == dailyDates[i].day) {
          dailyTotals[i] += sale.total;
          break;
        }
      }
    }

    final recent5Sales = allSales.take(5).toList();

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 600 ? 16.0 : 24.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            PageHeader(
              eyebrow: 'System Overview',
              title: 'ផ្ទាំងគ្រប់គ្រង (Admin Dashboard)',
              description: 'Real-time sales analytics, inventory status, and shop performance in Riel',
              actions: [
                OutlinedButton.icon(
                  onPressed: () => context.go('/admin/reports'),
                  icon: const Icon(Icons.analytics_outlined, size: 18),
                  label: const Text('មើលរបាយការណ៍ (REPORTS)'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),

            // 4 Metric Cards Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isPhone = constraints.maxWidth <= 550;
                final crossAxisCount = constraints.maxWidth > 900
                    ? 4
                    : (isPhone ? 1 : 2);
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: constraints.maxWidth > 900
                      ? 2.1
                      : (isPhone ? 3.4 : 2.3),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildMetricCard(
                      title: 'ចំណូលថ្ងៃនេះ (Today Revenue)',
                      value: MoneyUtils.formatRiel(todayRevenue),
                      subValue: MoneyUtils.formatUSD(
                        MoneyUtils.rielToUsd(todayRevenue),
                      ),
                      icon: Icons.monetization_on_outlined,
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                      isDark: isDark,
                    ),
                    _buildMetricCard(
                      title: 'ការលក់ថ្ងៃនេះ (Today Orders)',
                      value: '$todayTransactions Orders',
                      subValue: 'Completed receipts',
                      icon: Icons.receipt_long_outlined,
                      color: isDark
                          ? AppColors.darkSecondary
                          : AppColors.secondary,
                      isDark: isDark,
                    ),
                    _buildMetricCard(
                      title: 'ទំនិញសកម្ម (Active Products)',
                      value: '${products.length} Items',
                      subValue: 'In catalog directory',
                      icon: Icons.inventory_2_outlined,
                      color: isDark ? AppColors.darkSuccess : AppColors.success,
                      isDark: isDark,
                    ),
                    _buildMetricCard(
                      title: 'ស្តុកទាប / អស់ (Low Stock Alert)',
                      value: '${lowStockProducts.length} Items',
                      subValue: 'ចុចដើម្បីចូលស្តុក (Tap to fix)',
                      icon: Icons.warning_amber_rounded,
                      color: lowStockProducts.isEmpty
                          ? (isDark ? AppColors.darkSuccess : AppColors.success)
                          : (isDark
                                ? AppColors.darkWarning
                                : AppColors.warning),
                      isDark: isDark,
                      onTap: () => context.go('/admin/inventory'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            // 30-Day Bar Chart & Recent 5 Sales Layout
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: _buildRevenueBarChartCard(
                      isDark,
                      dailyDates,
                      dailyTotals,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 5,
                    child: _buildRecentSalesCard(context, isDark, recent5Sales),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _buildRevenueBarChartCard(isDark, dailyDates, dailyTotals),
                  const SizedBox(height: 20),
                  _buildRecentSalesCard(context, isDark, recent5Sales),
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
    required bool isDark,
    VoidCallback? onTap,
  }) {
    final textColor = isDark
        ? color
        : color == AppColors.secondary
        ? const Color(0xFF0E7490)
        : color == AppColors.success
        ? const Color(0xFF047857)
        : color == AppColors.warning
        ? const Color(0xFF92400E)
        : color;

    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
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
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkMutedText
                        : AppColors.lightMutedText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subValue,
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueBarChartCard(
    bool isDark,
    List<DateTime> dailyDates,
    List<int> dailyTotals,
  ) {
    final maxDaily = dailyTotals.isEmpty
        ? 0
        : dailyTotals.reduce((a, b) => a > b ? a : b);
    final maxY = maxDaily > 0 ? (maxDaily * 1.25).toDouble() : 10000.0;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'ចំណូល ៣០ ថ្ងៃចុងក្រោយ (30-Day Revenue)',
                  style: AppTextStyles.titleLG.copyWith(
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkPrimary : AppColors.primary)
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Daily (៛ Riel)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        isDark ? AppColors.darkSurface : AppColors.lightText,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final date = dailyDates[group.x.toInt()];
                      final formattedDate = DateFormat('dd MMM').format(date);
                      final amount = rod.toY.toInt();
                      return BarTooltipItem(
                        '$formattedDate\n',
                        TextStyle(
                          color: isDark ? AppColors.darkText : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: MoneyUtils.formatRiel(amount),
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkWarning
                                  : AppColors.warning,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        final axisColor = isDark
                            ? AppColors.darkMutedText
                            : AppColors.lightMutedText;
                        if (value >= 1000000) {
                          return Text(
                            '${(value / 1000000).toStringAsFixed(1)}M',
                            style: TextStyle(fontSize: 10, color: axisColor),
                          );
                        }
                        if (value >= 1000) {
                          return Text(
                            '${(value / 1000).toStringAsFixed(0)}k',
                            style: TextStyle(fontSize: 10, color: axisColor),
                          );
                        }
                        return Text(
                          '${value.toInt()}',
                          style: TextStyle(fontSize: 10, color: axisColor),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        // Show label every 5 days
                        if (idx >= 0 &&
                            idx < 30 &&
                            (idx % 6 == 0 || idx == 29)) {
                          final date = dailyDates[idx];
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              DateFormat('d/M').format(date),
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.darkMutedText
                                    : AppColors.lightMutedText,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color:
                        (isDark
                                ? AppColors.darkMutedText
                                : AppColors.lightBorder)
                            .withValues(alpha: 0.45),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(30, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: dailyTotals[i].toDouble(),
                        color: dailyTotals[i] > 0
                            ? (isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.primary)
                            : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder),
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSalesCard(
    BuildContext context,
    bool isDark,
    List<SaleModel> recentSales,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'ប្រតិបត្តិការថ្មីៗ (Recent Sales)',
                  style: AppTextStyles.titleLG.copyWith(
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => context.go('/admin/reports'),
                child: const Text(
                  'មើលទាំងអស់ (See All)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recentSales.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30.0),
              child: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'មិនទាន់មានការលក់ទេ (No Recent Sales)',
                subtitle: 'វិក្កយបត្រថ្មីៗនឹងបង្ហាញនៅទីនេះពេលលក់តាម POS',
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentSales.length,
              separatorBuilder: (_, _) => const Divider(height: 8),
              itemBuilder: (context, index) {
                return SaleListTile(sale: recentSales[index]);
              },
            ),
        ],
      ),
    );
  }
}
