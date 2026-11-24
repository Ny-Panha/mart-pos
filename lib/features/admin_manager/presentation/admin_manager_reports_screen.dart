import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../models/admin_manager_models.dart';
import '../providers/admin_manager_providers.dart';
import 'manager_widgets.dart';

class AdminManagerReportsScreen extends ConsumerStatefulWidget {
  const AdminManagerReportsScreen({super.key});

  @override
  ConsumerState<AdminManagerReportsScreen> createState() =>
      _AdminManagerReportsScreenState();
}

class _AdminManagerReportsScreenState
    extends ConsumerState<AdminManagerReportsScreen> {

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(managerDashboardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ManagerPage(
      title: 'របាយការណ៍រួម (System Reports)',
      description: 'វិភាគចំណូល ការលក់ និងដំណើរការប្រតិបត្តិការតាមហាងទាំងអស់',
      actions: [
        OutlinedButton.icon(
          onPressed: () => ref.invalidate(managerDashboardProvider),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Refresh'),
        ),
      ],
      child: dashboard.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(60),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, _) =>
            managerError(error, () => ref.invalidate(managerDashboardProvider)),
        data: (data) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Summary Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final isCompact = width < 650;
                final columns = width >= 1050
                    ? 4
                    : (width >= 700 ? 3 : (width >= 340 ? 2 : 1));

                return GridView.count(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: isCompact ? 116 : 88,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    ManagerMetricCard(
                      compact: isCompact,
                      label: '30-Day Revenue',
                      value: managerMoney(data.revenue),
                      icon: Icons.payments_rounded,
                      color: AppColors.success,
                    ),
                    ManagerMetricCard(
                      compact: isCompact,
                      label: 'Total Orders',
                      value: '${data.orders}',
                      icon: Icons.receipt_long_rounded,
                      color: AppColors.primary,
                    ),
                    ManagerMetricCard(
                      compact: isCompact,
                      label: 'Products Cataloged',
                      value: '${data.products}',
                      icon: Icons.inventory_2_rounded,
                      color: AppColors.info,
                    ),
                    ManagerMetricCard(
                      compact: isCompact,
                      label: 'Low Stock Items',
                      value: '${data.lowStock}',
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.danger,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),

            // Revenue Chart Card
            ManagerSectionCard(
              title: 'Revenue Analytics (និន្នាការចំណូល)',
              subtitle: 'Daily gross revenue reported across all connected mini-marts',
              child: _buildChart(data.revenueSeries, isDark),
            ),

            const SizedBox(height: 18),

            // Daily Revenue Breakdown Table
            if (data.revenueSeries.isNotEmpty)
              ManagerSectionCard(
                title: 'Daily Performance Ledger',
                subtitle: 'Day-by-day revenue entries recorded in the current period',
                child: _buildBreakdownList(data.revenueSeries, isDark),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<PlatformMetricPoint> points, bool isDark) {
    if (points.isEmpty) {
      return const ManagerEmptyState(
        icon: Icons.show_chart_rounded,
        title: 'No sales recorded yet',
        description: 'Revenue points will chart dynamically once orders are committed.',
      );
    }

    final maxVal = points
        .map((p) => p.value.toDouble())
        .fold<double>(0.0, (a, b) => a > b ? a : b);

    final spots = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].value.toDouble()));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxVal > 0 ? maxVal / 4 : 1000,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDark ? const Color(0xFF262C3A) : const Color(0xFFE2E8F0),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 54,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const Text('0 ៛', style: TextStyle(fontSize: 10));
                          final kVal = (value / 1000).toStringAsFixed(0);
                          return Text('$kVal k៛', style: const TextStyle(fontSize: 10, color: Colors.grey));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                          final label = points[idx].label;
                          final shortLabel = label.length > 5 ? label.substring(label.length - 5) : label;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              shortLabel,
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          );
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
                      getTooltipColor: (_) => isDark ? const Color(0xFF1E2433) : const Color(0xFF0F172A),
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
                      color: AppColors.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: AppColors.primary,
                            strokeWidth: 2,
                            strokeColor: isDark ? const Color(0xFF1A1F2B) : Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.28),
                            AppColors.primary.withValues(alpha: 0.0),
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
        );
      },
    );
  }

  Widget _buildBreakdownList(List<PlatformMetricPoint> points, bool isDark) {
    return Column(
      children: points.reversed.map((point) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131722) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? const Color(0xFF262C3A) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    point.label,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
              Text(
                managerMoney(point.value),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
