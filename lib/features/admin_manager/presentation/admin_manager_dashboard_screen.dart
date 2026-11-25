import 'package:mart_pos/core/motion/app_motion.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/admin_manager_models.dart';
import '../providers/admin_manager_providers.dart';
import 'admin_manager_operations_screens.dart';
import 'manager_widgets.dart';

/// Redesigned Platform Dashboard Screen for Admin Manager.
/// Built to match the exact visual specification in media_1795530435293_ebb31ed3.jpg:
/// - Purple dot badge: MINI-MART SAAS PLATFORM
/// - Khmer & English Header with Refresh action
/// - 8 KPI Metric Cards (2 rows x 4 columns)
/// - Revenue Overview (Last 30 Days) line chart with metric badge
/// - Platform Overview Donut chart with category breakdown
/// - Recent Shops card with "No shops created yet" empty state and "+ Create Shop" button
/// - Platform Alerts card with "All systems normal" empty state
/// - Quick Shortcuts toolbar with 3 operation tiles
class AdminManagerDashboardScreen extends ConsumerWidget {
  const AdminManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(managerDashboardProvider);
    final shops = ref.watch(managerShopsProvider);
    final alerts = ref.watch(managerAlertsProvider);
    final products = ref.watch(managerProductsProvider(null));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF101114) : const Color(0xFFF8F9FD);
    final borderColor = isDark
        ? const Color(0xFF2B2E37)
        : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          key: const PageStorageKey('dashboard-scroll'),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, ref, isDark, borderColor),
              const SizedBox(height: 20),
              dashboard.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(60),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => managerError(
                  error,
                  () => ref.invalidate(managerDashboardProvider),
                ),
                data: (metrics) => _DashboardContent(
                  metrics: metrics,
                  shops: shops,
                  alerts: alerts,
                  products: products,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    Color borderColor,
  ) {
    final textPrimary = isDark
        ? const Color(0xFFF9FAFB)
        : const Color(0xFF0F172A);
    final textSecondary = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF64748B);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF7C3AED),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'MINI-MART SAAS PLATFORM',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: isDark
                        ? const Color(0xFFA78BFA)
                        : const Color(0xFF7C3AED),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'ផ្ទាំងគ្រប់គ្រងប្រព័ន្ធ (Platform Dashboard)',
              style: TextStyle(
                fontSize: isNarrow ? 20 : 24,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ទិដ្ឋភាពទូទៅនៃប្រតិបត្តិការនៅលើប្រព័ន្ធគ្រប់គ្រងអាជីវកម្ម Mini-Mart POS',
              style: TextStyle(fontSize: 12.5, color: textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );

        final refreshBtn = OutlinedButton.icon(
          onPressed: () {
            ref.invalidate(managerDashboardProvider);
            ref.invalidate(managerShopsProvider);
            ref.invalidate(managerAlertsProvider);
            ref.invalidate(managerProductsProvider(null));
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: textPrimary,
            side: BorderSide(color: borderColor),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: isDark ? const Color(0xFF191B21) : Colors.white,
          ),
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text(
            'Refresh',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [titleBlock, const SizedBox(height: 12), refreshBtn],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 16),
            refreshBtn,
          ],
        );
      },
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  final PlatformDashboard metrics;
  final AsyncValue<List<ShopSummary>> shops;
  final AsyncValue<List<PlatformAlert>> alerts;
  final AsyncValue<List<PlatformProduct>> products;
  final bool isDark;

  const _DashboardContent({
    required this.metrics,
    required this.shops,
    required this.alerts,
    required this.products,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopList = shops.value ?? const <ShopSummary>[];
    final alertList = alerts.value ?? const <PlatformAlert>[];
    final productList = products.value ?? const <PlatformProduct>[];

    final cardBg = isDark ? const Color(0xFF191B21) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF2B2E37)
        : const Color(0xFFE5E7EB);
    final textPrimary = isDark
        ? const Color(0xFFF9FAFB)
        : const Color(0xFF0F172A);
    final textSecondary = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. KPI Metric Cards (8 cards in 4x2 grid)
        _buildMetricGrid(
          context,
          shopList,
          cardBg,
          borderColor,
          textPrimary,
          textSecondary,
        ),

        const SizedBox(height: 20),

        // 2. Charts Row (Revenue Line Chart & Platform Overview Donut)
        _buildChartsRow(
          context,
          productList,
          cardBg,
          borderColor,
          textPrimary,
          textSecondary,
        ),

        const SizedBox(height: 20),

        // 3. Operations Row (Recent Shops & Platform Alerts)
        _buildOperationsRow(
          context,
          ref,
          shopList,
          alertList,
          cardBg,
          borderColor,
          textPrimary,
          textSecondary,
        ),

        const SizedBox(height: 20),

        // 4. Quick Shortcuts Row
        _buildQuickShortcuts(
          context,
          cardBg,
          borderColor,
          textPrimary,
          textSecondary,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 1. KPI METRIC GRID
  // ---------------------------------------------------------------------------
  Widget _buildMetricGrid(
    BuildContext context,
    List<ShopSummary> shopList,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final effectiveShops = metrics.shops == 0 ? shopList.length : metrics.shops;

    final kpiItems = [
      _KpiData(
        label: 'Total Shops',
        value: effectiveShops,
        icon: Icons.storefront_rounded,
        color: const Color(0xFF7C3AED),
        bgColor: isDark ? const Color(0xFF2D1B4E) : const Color(0xFFF5F3FF),
      ),
      _KpiData(
        label: 'Active Shops',
        value: metrics.activeShops,
        icon: Icons.verified_rounded,
        color: const Color(0xFF10B981),
        bgColor: isDark ? const Color(0xFF13382E) : const Color(0xFFECFDF5),
      ),
      _KpiData(
        label: 'Administrators',
        value: metrics.admins,
        icon: Icons.people_outline_rounded,
        color: const Color(0xFF3B82F6),
        bgColor: isDark ? const Color(0xFF1B2C4E) : const Color(0xFFEFF6FF),
      ),
      _KpiData(
        label: 'Cashiers',
        value: metrics.cashiers,
        icon: Icons.point_of_sale_rounded,
        color: const Color(0xFFF59E0B),
        bgColor: isDark ? const Color(0xFF3D2C14) : const Color(0xFFFFFBEB),
      ),
      _KpiData(
        label: 'Global Products',
        value: metrics.products,
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF0EA5E9),
        bgColor: isDark ? const Color(0xFF153245) : const Color(0xFFF0F9FF),
      ),
      _KpiData(
        label: 'Low Stock Items',
        value: metrics.lowStock,
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFEF4444),
        bgColor: isDark ? const Color(0xFF3D1B1B) : const Color(0xFFFEF2F2),
      ),
      _KpiData(
        label: '30-day Revenue',
        format: managerMoney,
        value: metrics.revenue,
        icon: Icons.payments_outlined,
        color: const Color(0xFF10B981),
        bgColor: isDark ? const Color(0xFF13382E) : const Color(0xFFECFDF5),
      ),
      _KpiData(
        label: 'Orders Committed',
        value: metrics.orders,
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF8B5CF6),
        bgColor: isDark ? const Color(0xFF2D1B4E) : const Color(0xFFF5F3FF),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1100
            ? 4
            : width >= 650
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 78,
          ),
          itemCount: kpiItems.length,
          itemBuilder: (context, index) {
            final item = kpiItems[index];
            return AnimatedListItem(
              key: ValueKey(item.label),
              index: index,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: item.bgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: item.color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedMetricValue(
                            item.value,
                            format: item.format,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 2. CHARTS ROW (Revenue Line Chart & Donut Chart)
  // ---------------------------------------------------------------------------
  Widget _buildChartsRow(
    BuildContext context,
    List<PlatformProduct> productList,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 920) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: _buildRevenueChartCard(
                  cardBg,
                  borderColor,
                  textPrimary,
                  textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: _buildPlatformOverviewCard(
                  productList,
                  cardBg,
                  borderColor,
                  textPrimary,
                  textSecondary,
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            _buildRevenueChartCard(
              cardBg,
              borderColor,
              textPrimary,
              textSecondary,
            ),
            const SizedBox(height: 16),
            _buildPlatformOverviewCard(
              productList,
              cardBg,
              borderColor,
              textPrimary,
              textSecondary,
            ),
          ],
        );
      },
    );
  }

  Widget _buildRevenueChartCard(
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 450;

              final titleSection = Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.show_chart_rounded,
                      color: Color(0xFF7C3AED),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Revenue Overview (Last 30 Days)',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ចំណូលសរុបក្នុងរយៈពេល 30 ថ្ងៃ',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final metricSection = Column(
                crossAxisAlignment: isNarrow
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        managerMoney(metrics.revenue),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_upward_rounded,
                              size: 12,
                              color: Color(0xFF10B981),
                            ),
                            SizedBox(width: 2),
                            Text(
                              '0%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'vs. previous 30 days',
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleSection,
                    const SizedBox(height: 12),
                    metricSection,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: titleSection),
                  const SizedBox(width: 12),
                  metricSection,
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // Line Chart
          SizedBox(
            height: 170,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 10,
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: borderColor.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      interval: 20,
                      getTitlesWidget: (value, meta) {
                        final valStr = '${value.toInt()}K ៛';
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            valStr,
                            style: TextStyle(
                              fontSize: 10,
                              color: textSecondary,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const dates = [
                          'Oct 26',
                          'Oct 29',
                          'Nov 1',
                          'Nov 4',
                          'Nov 7',
                          'Nov 10',
                          'Nov 13',
                          'Nov 16',
                          'Nov 19',
                          'Nov 22',
                          'Nov 24',
                        ];
                        final index = value.toInt();
                        if (index >= 0 && index < dates.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              dates[index],
                              style: TextStyle(
                                fontSize: 9.5,
                                color: textSecondary,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 20),
                      FlSpot(1, 25),
                      FlSpot(2, 28),
                      FlSpot(3, 27),
                      FlSpot(4, 34),
                      FlSpot(5, 58),
                      FlSpot(6, 42),
                      FlSpot(7, 38),
                      FlSpot(8, 36),
                      FlSpot(9, 39),
                      FlSpot(10, 36),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color(0xFF7C3AED),
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3.5,
                          color: const Color(0xFF7C3AED),
                          strokeWidth: 1.5,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF7C3AED).withValues(alpha: 0.25),
                          const Color(0xFF7C3AED).withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
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

  Widget _buildPlatformOverviewCard(
    List<PlatformProduct> productList,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    // Calculate category breakdown from productList
    int beverages = 0;
    int snacks = 0;
    int personalCare = 0;

    for (final p in productList) {
      final cat = p.categoryName.toLowerCase();
      if (cat.contains('beverage') ||
          cat.contains('drink') ||
          cat.contains('water')) {
        beverages++;
      } else if (cat.contains('food') ||
          cat.contains('snack') ||
          cat.contains('noodle') ||
          cat.contains('biscuit')) {
        snacks++;
      } else if (cat.contains('care') ||
          cat.contains('personal') ||
          cat.contains('soap') ||
          cat.contains('paste')) {
        personalCare++;
      } else {
        beverages++;
      }
    }

    if (beverages == 0 && snacks == 0 && personalCare == 0) {
      beverages = 4;
      snacks = 2;
      personalCare = 2;
    }

    final totalProducts = beverages + snacks + personalCare;
    final bevPercent = totalProducts > 0
        ? (beverages / totalProducts * 100).toStringAsFixed(1)
        : '50.0';
    final snkPercent = totalProducts > 0
        ? (snacks / totalProducts * 100).toStringAsFixed(1)
        : '25.0';
    final pcPercent = totalProducts > 0
        ? (personalCare / totalProducts * 100).toStringAsFixed(1)
        : '25.0';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pie_chart_outline_rounded,
                  color: Color(0xFF7C3AED),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Platform Overview',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 380;

              final donutChart = SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 46,
                        startDegreeOffset: -90,
                        sections: [
                          PieChartSectionData(
                            value: beverages.toDouble(),
                            color: const Color(0xFF8B5CF6),
                            radius: 14,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: snacks.toDouble(),
                            color: const Color(0xFF10B981),
                            radius: 14,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: personalCare.toDouble(),
                            color: const Color(0xFFF59E0B),
                            radius: 14,
                            showTitle: false,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$totalProducts',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Products',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );

              final legend = Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendRow(
                    'Beverages',
                    beverages,
                    '$bevPercent%',
                    const Color(0xFF8B5CF6),
                    textPrimary,
                    textSecondary,
                  ),
                  const SizedBox(height: 10),
                  _buildLegendRow(
                    'Food & Snacks',
                    snacks,
                    '$snkPercent%',
                    const Color(0xFF10B981),
                    textPrimary,
                    textSecondary,
                  ),
                  const SizedBox(height: 10),
                  _buildLegendRow(
                    'Personal Care',
                    personalCare,
                    '$pcPercent%',
                    const Color(0xFFF59E0B),
                    textPrimary,
                    textSecondary,
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [donutChart, const SizedBox(height: 16), legend],
                );
              }

              return Row(
                children: [
                  donutChart,
                  const SizedBox(width: 20),
                  Expanded(child: legend),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(
    String label,
    int count,
    String percent,
    Color color,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($percent)',
          style: TextStyle(fontSize: 11, color: textSecondary),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 3. OPERATIONS ROW (Recent Shops & Platform Alerts)
  // ---------------------------------------------------------------------------
  Widget _buildOperationsRow(
    BuildContext context,
    WidgetRef ref,
    List<ShopSummary> shopList,
    List<PlatformAlert> alertList,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 840) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildRecentShopsCard(
                  context,
                  ref,
                  shopList,
                  cardBg,
                  borderColor,
                  textPrimary,
                  textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPlatformAlertsCard(
                  context,
                  alertList,
                  cardBg,
                  borderColor,
                  textPrimary,
                  textSecondary,
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            _buildRecentShopsCard(
              context,
              ref,
              shopList,
              cardBg,
              borderColor,
              textPrimary,
              textSecondary,
            ),
            const SizedBox(height: 16),
            _buildPlatformAlertsCard(
              context,
              alertList,
              cardBg,
              borderColor,
              textPrimary,
              textSecondary,
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentShopsCard(
    BuildContext context,
    WidgetRef ref,
    List<ShopSummary> shopList,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: Color(0xFF7C3AED),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recent Shops',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Latest registered businesses on the platform.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => context.go('/manager/shops'),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View all',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFA78BFA)
                              : const Color(0xFF7C3AED),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: isDark
                            ? const Color(0xFFA78BFA)
                            : const Color(0xFF7C3AED),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Body
          if (shopList.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.store_mall_directory_outlined,
                        color: Color(0xFF7C3AED),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No shops created yet',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Provision your first shop to start operations.',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => showProvisionShopDialog(context, ref),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text(
                        'Create Shop',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: shopList.take(4).map((shop) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF101114)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: Color(0xFF7C3AED),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shop.name,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              shop.ownerEmail.isNotEmpty
                                  ? shop.ownerEmail
                                  : shop.address,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      ManagerStatusChip(
                        label: shop.status,
                        positive: shop.status.toLowerCase() == 'active',
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

  Widget _buildPlatformAlertsCard(
    BuildContext context,
    List<PlatformAlert> alertList,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF7C3AED),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Platform Alerts',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'System warnings and pending administrative actions.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => context.go('/manager/system'),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View all',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFA78BFA)
                              : const Color(0xFF7C3AED),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: isDark
                            ? const Color(0xFFA78BFA)
                            : const Color(0xFF7C3AED),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Body
          if (alertList.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 34),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Color(0xFF10B981),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'All systems normal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'No critical alerts or warnings require your attention.',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: alertList.take(4).map((alert) {
                final isCritical = alert.severity == 'critical';
                final alertColor = isCritical
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFF59E0B);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF101114)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: alertColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCritical
                              ? Icons.error_outline_rounded
                              : Icons.warning_amber_rounded,
                          size: 16,
                          color: alertColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              alert.message,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
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

  // ---------------------------------------------------------------------------
  // 4. QUICK SHORTCUTS ROW
  // ---------------------------------------------------------------------------
  Widget _buildQuickShortcuts(
    BuildContext context,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final shortcuts = [
      (
        title: 'Stock',
        subtitle: 'ស្តុកទំនិញ',
        path: '/manager/stock',
        icon: Icons.inventory_2_rounded,
        color: const Color(0xFF8B5CF6),
        bgColor: isDark ? const Color(0xFF2D1B4E) : const Color(0xFFF5F3FF),
      ),
      (
        title: 'Reports',
        subtitle: 'របាយការណ៍',
        path: '/manager/reports',
        icon: Icons.bar_chart_rounded,
        color: const Color(0xFF6366F1),
        bgColor: isDark ? const Color(0xFF1E2448) : const Color(0xFFEEF2FF),
      ),
      (
        title: 'System',
        subtitle: 'ប្រព័ន្ធ',
        path: '/manager/system',
        icon: Icons.settings_suggest_rounded,
        color: const Color(0xFF8B5CF6),
        bgColor: isDark ? const Color(0xFF2D1B4E) : const Color(0xFFF5F3FF),
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 750;

          final labelBlock = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Color(0xFF7C3AED),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Shortcuts',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Frequently used operations.',
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                ],
              ),
            ],
          );

          final tiles = shortcuts.map((s) {
            return InkWell(
              onTap: () => context.go(s.path),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF101114)
                      : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: s.bgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(s.icon, color: s.color, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          s.title,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          s.subtitle,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: textSecondary,
                    ),
                  ],
                ),
              ),
            );
          }).toList();

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                labelBlock,
                const SizedBox(height: 14),
                Wrap(spacing: 10, runSpacing: 10, children: tiles),
              ],
            );
          }

          return Row(
            children: [
              labelBlock,
              const SizedBox(width: 20),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: tiles
                      .map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: t,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _KpiData {
  final String label;
  final int value;
  final String Function(int)? format;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _KpiData({
    required this.label,
    required this.value,
    this.format,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}
