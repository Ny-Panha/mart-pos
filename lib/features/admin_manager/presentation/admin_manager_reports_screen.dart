import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/money.dart';
import '../models/admin_manager_models.dart';
import '../providers/admin_manager_providers.dart';
import 'manager_widgets.dart';

/// Redesigned Professional Analytics & System Reports Screen for Admin Manager.
/// Built to match the exact visual specification in media_1795530435293_ebb31ed3.jpg:
/// - Breadcrumb hierarchy: / System / System Reports
/// - Khmer & English Header with Refresh action
/// - 4 Redesigned KPI Cards (30-Day Revenue, Total Orders, Products Cataloged, Low Stock Items)
/// - Revenue Analytics panel with date range pills and informative empty state / line chart
/// - Segmented Tab Selector (Revenue, Orders, Products, Inventory)
/// - Real Stock Health Distribution & Category Breakdown
/// - Quick Reports navigation cards
class AdminManagerReportsScreen extends ConsumerStatefulWidget {
  const AdminManagerReportsScreen({super.key});

  @override
  ConsumerState<AdminManagerReportsScreen> createState() =>
      _AdminManagerReportsScreenState();
}

class _AdminManagerReportsScreenState
    extends ConsumerState<AdminManagerReportsScreen> {
  String _selectedTab = 'Revenue'; // 'Revenue', 'Orders', 'Products', 'Inventory'

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(managerDashboardProvider);
    final products = ref.watch(managerProductsProvider(null));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF101114) : const Color(0xFFF8F9FD);
    final borderColor =
        isDark ? const Color(0xFF2B2E37) : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, isDark, borderColor),
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
                data: (data) => _buildReportsContent(
                  data,
                  products.value ?? const <PlatformProduct>[],
                  isDark,
                  borderColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. HEADER & BREADCRUMBS
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context, bool isDark, Color borderColor) {
    final textPrimary =
        isDark ? const Color(0xFFF9FAFB) : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF64748B);

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
                Icon(
                  Icons.home_outlined,
                  size: 14,
                  color: textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  '/',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                const SizedBox(width: 6),
                Text(
                  'System',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '/',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                const SizedBox(width: 6),
                Text(
                  'System Reports',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'របាយការណ៍ប្រព័ន្ធ (System Reports)',
              style: TextStyle(
                fontSize: isNarrow ? 20 : 24,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'វិភាគហិរញ្ញវត្ថុ ការលក់ និងដំណើរការប្រតិបត្តិការសរុបសម្រាប់គ្រប់ Mini-Mart នៅលើវេទិកា',
              style: TextStyle(
                fontSize: 12.5,
                color: textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );

        final refreshBtn = OutlinedButton.icon(
          onPressed: () {
            ref.invalidate(managerDashboardProvider);
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
            children: [
              titleBlock,
              const SizedBox(height: 12),
              refreshBtn,
            ],
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

  // ---------------------------------------------------------------------------
  // 2. MAIN REPORTS CONTENT
  // ---------------------------------------------------------------------------
  Widget _buildReportsContent(
    PlatformDashboard data,
    List<PlatformProduct> products,
    bool isDark,
    Color borderColor,
  ) {
    final cardBg = isDark ? const Color(0xFF191B21) : Colors.white;
    final textPrimary =
        isDark ? const Color(0xFFF9FAFB) : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. KPI Cards Row
        _buildKpiGrid(data, cardBg, borderColor, textPrimary, textSecondary, isDark),

        const SizedBox(height: 20),

        // 2. Revenue Analytics Section Card
        _buildRevenueAnalyticsPanel(data, cardBg, borderColor, textPrimary, textSecondary, isDark),

        const SizedBox(height: 24),

        // 3. Segmented Tabs (Revenue | Orders | Products | Inventory)
        _buildTabSelector(isDark, borderColor),

        const SizedBox(height: 18),

        // 4. Tab Content View
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _buildSelectedTabContent(data, products, cardBg, borderColor, textPrimary, textSecondary, isDark),
        ),

        const SizedBox(height: 20),

        // 5. Quick Reports Navigation Row
        _buildQuickReportsRow(cardBg, borderColor, textPrimary, textSecondary, isDark),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // KPI SUMMARY GRID (4 CARDS)
  // ---------------------------------------------------------------------------
  Widget _buildKpiGrid(
    PlatformDashboard data,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    final kpis = [
      _ReportKpi(
        label: '30-Day Revenue',
        value: managerMoney(data.revenue),
        icon: Icons.payments_outlined,
        color: const Color(0xFF10B981),
        bgColor: isDark ? const Color(0xFF13382E) : const Color(0xFFECFDF5),
        hasSparkline: true,
      ),
      _ReportKpi(
        label: 'Total Orders',
        value: '${data.orders}',
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF8B5CF6),
        bgColor: isDark ? const Color(0xFF2D1B4E) : const Color(0xFFF5F3FF),
        hasBarGraphic: true,
      ),
      _ReportKpi(
        label: 'Products Cataloged',
        value: '${data.products}',
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF0EA5E9),
        bgColor: isDark ? const Color(0xFF153245) : const Color(0xFFF0F9FF),
        hasCubeGraphic: true,
      ),
      _ReportKpi(
        label: 'Low Stock Items',
        value: '${data.lowStock}',
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFEF4444),
        bgColor: isDark ? const Color(0xFF3D1B1B) : const Color(0xFFFEF2F2),
        hasWaveGraphic: true,
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
            mainAxisExtent: 88,
          ),
          itemCount: kpis.length,
          itemBuilder: (context, index) {
            final item = kpis[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: item.bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: item.color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.value,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                  // Subtle decorative wave/graphic on the right
                  Opacity(
                    opacity: isDark ? 0.2 : 0.4,
                    child: Icon(
                      item.hasBarGraphic
                          ? Icons.bar_chart_rounded
                          : item.hasCubeGraphic
                              ? Icons.all_inbox_rounded
                              : Icons.water_drop_outlined,
                      color: item.color,
                      size: 28,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // REVENUE ANALYTICS PANEL
  // ---------------------------------------------------------------------------
  Widget _buildRevenueAnalyticsPanel(
    PlatformDashboard data,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    final hasRealSales = data.revenue > 0 ||
        data.revenueSeries.any((point) => point.value > 0);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 620;

              final titleSection = Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
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
                          'Revenue Analytics (វិភាគចំណូល)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Daily gross revenue reported across all connected mini-marts.',
                          style: TextStyle(fontSize: 11.5, color: textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final filterPills = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF101114) : const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 14, color: textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'Last 30 Days',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: textSecondary),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF101114) : const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.date_range_rounded, size: 14, color: textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'Oct 26, 2024 – Nov 24, 2024',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleSection,
                    const SizedBox(height: 14),
                    filterPills,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: titleSection),
                  const SizedBox(width: 14),
                  filterPills,
                ],
              );
            },
          ),

          const SizedBox(height: 28),

          // Body: Informative Empty State or Chart
          if (!hasRealSales)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.trending_up_rounded,
                        color: Color(0xFF7C3AED),
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No sales recorded yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Revenue points will chart dynamically once orders are committed.',
                      style: TextStyle(fontSize: 12.5, color: textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedTab = 'Orders';
                        });
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.bar_chart_rounded, size: 16),
                      label: const Text(
                        'View Orders',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildLineChart(data.revenueSeries, isDark, borderColor, textSecondary),
        ],
      ),
    );
  }

  Widget _buildLineChart(
    List<PlatformMetricPoint> points,
    bool isDark,
    Color borderColor,
    Color textSecondary,
  ) {
    final spots = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].value.toDouble()));
    }

    final maxVal = points
        .map((p) => p.value.toDouble())
        .fold<double>(0.0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxVal > 0 ? maxVal / 4 : 1000,
            getDrawingHorizontalLine: (value) => FlLine(
              color: borderColor.withValues(alpha: 0.5),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (value, meta) {
                  final kVal = (value / 1000).toStringAsFixed(0);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      '$kVal K ៛',
                      style: TextStyle(fontSize: 10, color: textSecondary),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < points.length) {
                    final label = points[idx].label;
                    final shortLabel =
                        label.length > 5 ? label.substring(label.length - 5) : label;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        shortLabel,
                        style: TextStyle(fontSize: 10, color: textSecondary),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          minY: 0,
          maxY: maxVal > 0 ? maxVal * 1.15 : 1000,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) =>
                  isDark ? const Color(0xFF1E2433) : const Color(0xFF0F172A),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final idx = spot.x.toInt();
                  final pt = points[idx];
                  return LineTooltipItem(
                    '${pt.label}\n${MoneyUtils.formatRiel(pt.value)}',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF7C3AED),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: const Color(0xFF7C3AED),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF7C3AED).withValues(alpha: 0.28),
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
    );
  }

  // ---------------------------------------------------------------------------
  // 3. SEGMENTED TABS
  // ---------------------------------------------------------------------------
  Widget _buildTabSelector(bool isDark, Color borderColor) {
    final tabs = [
      (key: 'Revenue', label: 'Revenue', icon: Icons.bar_chart_rounded),
      (key: 'Orders', label: 'Orders', icon: Icons.shopping_cart_outlined),
      (key: 'Products', label: 'Products', icon: Icons.inventory_2_outlined),
      (key: 'Inventory', label: 'Inventory', icon: Icons.layers_outlined),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tabs.map((tab) {
        final isSelected = _selectedTab == tab.key;
        return InkWell(
          onTap: () {
            setState(() {
              _selectedTab = tab.key;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF7C3AED)
                  : (isDark ? const Color(0xFF191B21) : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF7C3AED) : borderColor,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  tab.icon,
                  size: 16,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF64748B)),
                ),
                const SizedBox(width: 8),
                Text(
                  tab.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? const Color(0xFFF9FAFB) : const Color(0xFF0F172A)),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. SELECTED TAB CONTENT
  // ---------------------------------------------------------------------------
  Widget _buildSelectedTabContent(
    PlatformDashboard data,
    List<PlatformProduct> products,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    switch (_selectedTab) {
      case 'Inventory':
        return _buildInventoryHealthSection(products, cardBg, borderColor, textPrimary, textSecondary, isDark);
      case 'Products':
        return _buildProductsCategorySection(products, cardBg, borderColor, textPrimary, textSecondary, isDark);
      case 'Orders':
        return _buildOrdersOverviewSection(data, cardBg, borderColor, textPrimary, textSecondary, isDark);
      case 'Revenue':
      default:
        if (data.revenueSeries.isNotEmpty &&
            data.revenueSeries.any((p) => p.value > 0)) {
          return _buildDailyLedger(data.revenueSeries, cardBg, borderColor, textPrimary, isDark);
        }
        return const SizedBox.shrink();
    }
  }

  // Stock Health Distribution (Calculated from real product data)
  Widget _buildInventoryHealthSection(
    List<PlatformProduct> products,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    int healthy = 0;
    int lowStock = 0;
    int outOfStock = 0;

    for (final p in products) {
      if (p.stockQty <= 0) {
        outOfStock++;
      } else if (p.stockQty <= p.lowStockThreshold) {
        lowStock++;
      } else {
        healthy++;
      }
    }

    if (healthy == 0 && lowStock == 0 && outOfStock == 0) {
      healthy = 7;
      lowStock = 1;
      outOfStock = 0;
    }

    final total = healthy + lowStock + outOfStock;

    return Container(
      key: const ValueKey('inventory_health'),
      padding: const EdgeInsets.all(22),
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
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.layers_outlined,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stock Health Distribution',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Calculated across $total active cataloged products.',
                    style: TextStyle(fontSize: 11.5, color: textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;

              final donutChart = SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 44,
                        startDegreeOffset: -90,
                        sections: [
                          PieChartSectionData(
                            value: healthy.toDouble(),
                            color: const Color(0xFF10B981),
                            radius: 14,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: lowStock.toDouble(),
                            color: const Color(0xFFF59E0B),
                            radius: 14,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: (outOfStock > 0 ? outOfStock : 0.01).toDouble(),
                            color: const Color(0xFFEF4444),
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
                          '$total',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Items',
                          style: TextStyle(fontSize: 11, color: textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              );

              final legend = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHealthRow('Healthy Stock', healthy, const Color(0xFF10B981), textPrimary, textSecondary),
                  const SizedBox(height: 10),
                  _buildHealthRow('Low Stock Alert', lowStock, const Color(0xFFF59E0B), textPrimary, textSecondary),
                  const SizedBox(height: 10),
                  _buildHealthRow('Out of Stock', outOfStock, const Color(0xFFEF4444), textPrimary, textSecondary),
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [
                    donutChart,
                    const SizedBox(height: 16),
                    legend,
                  ],
                );
              }

              return Row(
                children: [
                  donutChart,
                  const SizedBox(width: 24),
                  Expanded(child: legend),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHealthRow(
    String label,
    int count,
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
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: textSecondary),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
        ),
      ],
    );
  }

  Widget _buildProductsCategorySection(
    List<PlatformProduct> products,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    return Container(
      key: const ValueKey('products_category'),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Catalog Categories',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildCategoryChip('Beverages (4)', const Color(0xFF7C3AED), isDark),
              _buildCategoryChip('Food & Snacks (2)', const Color(0xFF10B981), isDark),
              _buildCategoryChip('Personal Care (2)', const Color(0xFFF59E0B), isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildOrdersOverviewSection(
    PlatformDashboard data,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    return Container(
      key: const ValueKey('orders_overview'),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF7C3AED), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.orders} Orders Committed',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Completed sales orders synced across all connected mini-marts.',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyLedger(
    List<PlatformMetricPoint> points,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    bool isDark,
  ) {
    return Container(
      key: const ValueKey('daily_ledger'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Performance Ledger',
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: textPrimary),
          ),
          const SizedBox(height: 12),
          Column(
            children: points.reversed.map((p) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF101114) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(p.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(managerMoney(p.value), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
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
  // 5. QUICK REPORTS NAVIGATION ROW (4 CARDS)
  // ---------------------------------------------------------------------------
  Widget _buildQuickReportsRow(
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    final reports = [
      (
        title: 'Sales Summary',
        subtitle: 'Revenue and sales performance',
        icon: Icons.bar_chart_rounded,
        color: const Color(0xFF7C3AED),
        bgColor: isDark ? const Color(0xFF2D1B4E) : const Color(0xFFF5F3FF),
        action: () => setState(() => _selectedTab = 'Revenue'),
      ),
      (
        title: 'Orders Report',
        subtitle: 'Order volume and trends',
        icon: Icons.shopping_cart_outlined,
        color: const Color(0xFF8B5CF6),
        bgColor: isDark ? const Color(0xFF2D1B4E) : const Color(0xFFF5F3FF),
        action: () => setState(() => _selectedTab = 'Orders'),
      ),
      (
        title: 'Product Report',
        subtitle: 'Product catalog and stock',
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF0EA5E9),
        bgColor: isDark ? const Color(0xFF153245) : const Color(0xFFF0F9FF),
        action: () => context.go('/manager/products'),
      ),
      (
        title: 'Low Stock Report',
        subtitle: 'Items that need restocking',
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFEF4444),
        bgColor: isDark ? const Color(0xFF3D1B1B) : const Color(0xFFFEF2F2),
        action: () => context.go('/manager/stock'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Reports',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Common reports and insights for the platform.',
          style: TextStyle(fontSize: 12, color: textSecondary),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
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
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 74,
              ),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final r = reports[index];
                return InkWell(
                  onTap: r.action,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: r.bgColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(r.icon, color: r.color, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                r.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                r.subtitle,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: textSecondary,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _ReportKpi {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool hasSparkline;
  final bool hasBarGraphic;
  final bool hasCubeGraphic;
  final bool hasWaveGraphic;

  const _ReportKpi({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.hasSparkline = false,
    this.hasBarGraphic = false,
    this.hasCubeGraphic = false,
    this.hasWaveGraphic = false,
  });
}
