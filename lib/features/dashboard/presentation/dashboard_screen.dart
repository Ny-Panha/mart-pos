import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/money.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/hover_card.dart';
import '../../../data/firestore/models/sale_model.dart';
import '../../inventory/providers/inventory_provider.dart';
import '../../products/presentation/product_form_dialog.dart';
import '../../products/providers/product_provider.dart';
import '../../reports/presentation/widgets/sale_detail_dialog.dart';
import '../../reports/providers/report_provider.dart';

/// Tavola 1:1 Inspired Operations Dashboard for Mart POS
/// - Header with compact horizontal pill metrics
/// - "Live Service" card with large amount, spline curve, and Revenue/Tickets toggle
/// - "On the pass" 2-column ticket cards grid with Mint/Coral pastel tickets
/// - "The room" Donut ring gauge for inventory capacity
/// - "Still to come" Quick actions & pending queue
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedChartDays = 30; // 7, 14, or 30 days
  bool _isSplineView = true; // Spline Wave vs Bar Rods view
  bool _isRevenueMode = true; // Revenue ($/៛) vs Tickets (Order counts)

  @override
  Widget build(BuildContext context) {
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
    final avgTicket = todayTransactions > 0
        ? (todayRevenue / todayTransactions).round()
        : 0;

    // 2. Prepare daily aggregated chart data for selected timeframe
    final numDays = _selectedChartDays;
    final dailyTotals = List<int>.filled(numDays, 0);
    final dailyCounts = List<int>.filled(numDays, 0);
    final dailyDates = List<DateTime>.generate(numDays, (i) {
      final day = now.subtract(Duration(days: (numDays - 1) - i));
      return DateTime(day.year, day.month, day.day);
    });

    for (final sale in allSales) {
      final saleDay = DateTime(
        sale.createdAt.year,
        sale.createdAt.month,
        sale.createdAt.day,
      );
      for (int i = 0; i < numDays; i++) {
        if (saleDay.year == dailyDates[i].year &&
            saleDay.month == dailyDates[i].month &&
            saleDay.day == dailyDates[i].day) {
          dailyTotals[i] += sale.total;
          dailyCounts[i] += 1;
          break;
        }
      }
    }

    final recentSales = allSales.take(6).toList();

    // 3. Stock Health Stats
    final outOfStockCount = products.where((p) => p.isOutOfStock).length;
    final lowStockCount = lowStockProducts.length;
    final healthyCount = (products.length - outOfStockCount - lowStockCount)
        .clamp(0, products.length);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A1222) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width < 600 ? 14.0 : 22.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // 1. Tavola Header Row: Big Service Title + Horizontal Metric Pills
            _buildTavolaHeader(
              context: context,
              isDark: isDark,
              todayRevenue: todayRevenue,
              todayOrders: todayTransactions,
              avgTicket: avgTicket,
              totalProducts: products.length,
              lowStockCount: lowStockCount,
            ),
            const SizedBox(height: 20),

            // 2. Main Dashboard Grid (Left: Live Service & Rooms, Right: On The Pass Tickets)
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Live Service Chart + Bottom Insights (Flex 7)
                  Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLiveServiceCard(
                          context: context,
                          isDark: isDark,
                          todayRevenue: todayRevenue,
                          todayOrders: todayTransactions,
                          dailyDates: dailyDates,
                          dailyTotals: dailyTotals,
                          dailyCounts: dailyCounts,
                        ),
                        const SizedBox(height: 20),
                        // Bottom Insights Row: "The room" Donut + "Still to come" Quick Actions
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildTheRoomInventoryCard(
                                context: context,
                                isDark: isDark,
                                total: products.length,
                                healthy: healthyCount,
                                low: lowStockCount,
                                outOfStock: outOfStockCount,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _buildStillToComeActionsCard(
                                context: context,
                                isDark: isDark,
                                todayOrders: todayTransactions,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Right Column: "On the pass" (Recent Orders Ticket Grid) (Flex 5)
                  Expanded(
                    flex: 5,
                    child: _buildOnThePassCard(
                      context: context,
                      isDark: isDark,
                      recentSales: recentSales,
                    ),
                  ),
                ],
              )
            else
              // Mobile / Tablet Vertical Flow
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLiveServiceCard(
                    context: context,
                    isDark: isDark,
                    todayRevenue: todayRevenue,
                    todayOrders: todayTransactions,
                    dailyDates: dailyDates,
                    dailyTotals: dailyTotals,
                    dailyCounts: dailyCounts,
                  ),
                  const SizedBox(height: 20),
                  _buildOnThePassCard(
                    context: context,
                    isDark: isDark,
                    recentSales: recentSales,
                  ),
                  const SizedBox(height: 20),
                  _buildTheRoomInventoryCard(
                    context: context,
                    isDark: isDark,
                    total: products.length,
                    healthy: healthyCount,
                    low: lowStockCount,
                    outOfStock: outOfStockCount,
                  ),
                  const SizedBox(height: 20),
                  _buildStillToComeActionsCard(
                    context: context,
                    isDark: isDark,
                    todayOrders: todayTransactions,
                  ),
                ],
              ),
          ],
        ),
      ),
    ),
    );
  }

  // =========================================================================
  // 1. Tavola Top Header: Big Service Title + Compact Horizontal Stat Pills
  // =========================================================================
  Widget _buildTavolaHeader({
    required BuildContext context,
    required bool isDark,
    required int todayRevenue,
    required int todayOrders,
    required int avgTicket,
    required int totalProducts,
    required int lowStockCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF34D399),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF34D399),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'LIVE OPERATIONS & ANALYTICS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "Tonight's Service",
              style: TextStyle(
                fontSize: isWide ? 28 : 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Text(
              "ប្រតិបត្តិការថ្ងៃនេះ • Mart Sales & Inventory Radar",
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        );

        final statsRow = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pill 1: Revenue
              _buildHeaderPill(
                isDark: isDark,
                icon: Icons.receipt_long_rounded,
                iconBg: const Color(0xFF6366F1).withValues(alpha: 0.18),
                iconColor: const Color(0xFF818CF8),
                value: MoneyUtils.formatRiel(todayRevenue),
                badgeText: todayRevenue > 0 ? '+12% vs last week' : '0%',
                badgePositive: true,
                subtitle: 'Revenue today',
              ),
              const SizedBox(width: 10),

              // Pill 2: Orders Count
              _buildHeaderPill(
                isDark: isDark,
                icon: Icons.people_alt_rounded,
                iconBg: const Color(0xFF10B981).withValues(alpha: 0.18),
                iconColor: const Color(0xFF34D399),
                value: '$todayOrders',
                badgeText: 'Orders of 50 goal',
                badgePositive: null,
                subtitle: 'Completed sales',
              ),
              const SizedBox(width: 10),

              // Pill 3: Average Ticket
              _buildHeaderPill(
                isDark: isDark,
                icon: Icons.auto_graph_rounded,
                iconBg: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                iconColor: const Color(0xFFFBBF24),
                value: MoneyUtils.formatRiel(avgTicket),
                badgeText: MoneyUtils.formatUSD(MoneyUtils.rielToUsd(avgTicket)),
                badgePositive: null,
                subtitle: 'Average check per order',
              ),
              const SizedBox(width: 10),

              // Pill 4: Catalog & Stock
              _buildHeaderPill(
                isDark: isDark,
                icon: Icons.inventory_2_rounded,
                iconBg: lowStockCount > 0
                    ? const Color(0xFFEF4444).withValues(alpha: 0.18)
                    : const Color(0xFF10B981).withValues(alpha: 0.18),
                iconColor: lowStockCount > 0
                    ? const Color(0xFFF87171)
                    : const Color(0xFF34D399),
                value: '$totalProducts',
                badgeText: lowStockCount > 0 ? '$lowStockCount Low' : 'Optimal',
                badgePositive: lowStockCount == 0,
                subtitle: 'Active products',
                onTap: () => context.go('/admin/inventory'),
              ),
            ],
          ),
        );

        if (isWide) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              titleBlock,
              const SizedBox(width: 16),
              Flexible(child: statsRow),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titleBlock,
            const SizedBox(height: 14),
            statsRow,
          ],
        );
      },
    );
  }

  Widget _buildHeaderPill({
    required bool isDark,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String? badgeText,
    required bool? badgePositive,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF121C2F).withValues(alpha: 0.85)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xFF1E2D4A)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBg,
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    if (badgeText != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgePositive == true
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : (badgePositive == false
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                                  : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06))),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: badgePositive == true
                                ? const Color(0xFF34D399)
                                : (badgePositive == false
                                    ? const Color(0xFFF87171)
                                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 2. Tavola Left: "Live service" Big Spline Area Chart Card
  // =========================================================================
  Widget _buildLiveServiceCard({
    required BuildContext context,
    required bool isDark,
    required int todayRevenue,
    required int todayOrders,
    required List<DateTime> dailyDates,
    required List<int> dailyTotals,
    required List<int> dailyCounts,
  }) {
    final activeData = _isRevenueMode ? dailyTotals : dailyCounts;
    final maxVal = activeData.isEmpty
        ? 0
        : activeData.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal > 0 ? (maxVal * 1.30).toDouble() : 10000.0;
    final avgVal = activeData.isEmpty
        ? 0.0
        : (activeData.reduce((a, b) => a + b) / activeData.length);

    return AppCard(
      isFrosted: true,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header of Live Service Card (Responsive on Mobile & Desktop)
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 620;

              final titleAndAction = Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Live service',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => context.go('/admin/reports'),
                    icon: const Icon(Icons.north_east_rounded, size: 18),
                    tooltip: 'Open Reports & Analytics',
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                      foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              );

              final amountAndBadge = Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    _isRevenueMode
                        ? MoneyUtils.formatRiel(todayRevenue)
                        : '$todayOrders Orders',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    _isRevenueMode
                        ? 'taken today • -8% vs last week'
                        : 'receipts today',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFFB923C),
                    ),
                  ),
                ],
              );

              final legend = Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 14,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFF5C8BC),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tonight (ថ្ងៃនេះ)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 2,
                        color: isDark ? Colors.white30 : Colors.black26,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Baseline (មធ្យមភាគ)',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              );

              final controls = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Revenue vs Tickets Switcher
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSegmentBtn(
                          label: 'Revenue',
                          isActive: _isRevenueMode,
                          isDark: isDark,
                          onTap: () => setState(() => _isRevenueMode = true),
                        ),
                        _buildSegmentBtn(
                          label: 'Tickets',
                          isActive: !_isRevenueMode,
                          isDark: isDark,
                          onTap: () => setState(() => _isRevenueMode = false),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Spline vs Bar Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSegmentBtn(
                          label: 'Wave',
                          isActive: _isSplineView,
                          isDark: isDark,
                          onTap: () => setState(() => _isSplineView = true),
                        ),
                        _buildSegmentBtn(
                          label: 'Bar',
                          isActive: !_isSplineView,
                          isDark: isDark,
                          onTap: () => setState(() => _isSplineView = false),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleAndAction,
                    const SizedBox(height: 10),
                    amountAndBadge,
                    const SizedBox(height: 8),
                    legend,
                    const SizedBox(height: 14),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: controls,
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Live service',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        amountAndBadge,
                        const SizedBox(height: 6),
                        legend,
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      controls,
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => context.go('/admin/reports'),
                        icon: const Icon(Icons.north_east_rounded, size: 18),
                        tooltip: 'Open Reports & Analytics',
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                          foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Chart Display (Spline Wave vs Bar)
          SizedBox(
            height: 240,
            child: _isSplineView
                ? _buildTavolaSplineChart(
                    isDark: isDark,
                    dailyDates: dailyDates,
                    activeData: activeData,
                    maxY: maxY,
                    avgVal: avgVal,
                  )
                : _buildTavolaBarChart(
                    isDark: isDark,
                    dailyDates: dailyDates,
                    activeData: activeData,
                    maxY: maxY,
                  ),
          ),
          const SizedBox(height: 12),

          // Timeframe selection buttons (7D, 14D, 30D)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildTimeframeBtn(7, '7D', isDark),
              const SizedBox(width: 6),
              _buildTimeframeBtn(14, '14D', isDark),
              const SizedBox(width: 6),
              _buildTimeframeBtn(30, '30D', isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentBtn({
    required String label,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? const Color(0xFF1E293B) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive
                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeframeBtn(int days, String label, bool isDark) {
    final active = _selectedChartDays == days;
    return InkWell(
      onTap: () => setState(() => _selectedChartDays = days),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF6366F1)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: active
                ? Colors.white
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildTavolaSplineChart({
    required bool isDark,
    required List<DateTime> dailyDates,
    required List<int> activeData,
    required double maxY,
    required double avgVal,
  }) {
    final spots = List.generate(
      dailyDates.length,
      (i) => FlSpot(i.toDouble(), activeData[i].toDouble()),
    );

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (dailyDates.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                final date = dailyDates[idx];
                final formattedDate = DateFormat('dd MMM').format(date);
                final val = spot.y.toInt();
                final text = _isRevenueMode
                    ? '${MoneyUtils.formatRiel(val)}\n${MoneyUtils.formatUSD(MoneyUtils.rielToUsd(val))}'
                    : '$val Orders';
                return LineTooltipItem(
                  '$formattedDate\n',
                  const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                  children: [
                    TextSpan(
                      text: text,
                      style: const TextStyle(
                        color: Color(0xFFF5C8BC),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                final axisColor = isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8);
                if (_isRevenueMode) {
                  if (value >= 1000000) {
                    return Text('${(value / 1000000).toStringAsFixed(1)}M',
                        style: TextStyle(fontSize: 10, color: axisColor));
                  }
                  if (value >= 1000) {
                    return Text('${(value / 1000).toStringAsFixed(0)}k',
                        style: TextStyle(fontSize: 10, color: axisColor));
                  }
                }
                return Text('${value.toInt()}',
                    style: TextStyle(fontSize: 10, color: axisColor));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                final step = _selectedChartDays <= 7
                    ? 1
                    : (_selectedChartDays <= 14 ? 2 : 5);
                if (idx >= 0 &&
                    idx < dailyDates.length &&
                    (idx % step == 0 || idx == dailyDates.length - 1)) {
                  final date = dailyDates[idx];
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      DateFormat('d/M').format(date),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
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
            color: (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))
                .withValues(alpha: 0.5),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // 1. Tavola Multi-Color Glowing Spline Wave
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.38,
            preventCurveOverShooting: true,
            gradient: const LinearGradient(
              colors: [
                Color(0xFFF5C8BC), // Tavola soft peach coral
                Color(0xFFECD29A), // Tavola champagne amber
                Color(0xFF38BDF8), // Electric cyan
              ],
            ),
            barWidth: 3.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: dailyDates.length <= 7,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 3.5,
                color: const Color(0xFFECD29A),
                strokeWidth: 1.5,
                strokeColor: isDark ? const Color(0xFF0A1222) : Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFF5C8BC).withValues(alpha: isDark ? 0.30 : 0.20),
                  const Color(0xFFECD29A).withValues(alpha: isDark ? 0.10 : 0.06),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.65, 1.0],
              ),
            ),
          ),
          // 2. Dashed Moving Average Baseline
          if (avgVal > 0)
            LineChartBarData(
              spots: List.generate(
                dailyDates.length,
                (i) => FlSpot(i.toDouble(), avgVal),
              ),
              isCurved: true,
              curveSmoothness: 0.38,
              color: isDark ? Colors.white24 : Colors.black12,
              barWidth: 1.5,
              dashArray: [5, 5],
              dotData: const FlDotData(show: false),
            ),
        ],
      ),
    );
  }

  Widget _buildTavolaBarChart({
    required bool isDark,
    required List<DateTime> dailyDates,
    required List<int> activeData,
    required double maxY,
  }) {
    return BarChart(
      BarChartData(
        maxY: maxY,
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                final axisColor = isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8);
                return Text('${value.toInt()}',
                    style: TextStyle(fontSize: 10, color: axisColor));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                final step = _selectedChartDays <= 7 ? 1 : 5;
                if (idx >= 0 && idx < dailyDates.length && (idx % step == 0)) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      DateFormat('d/M').format(dailyDates[idx]),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
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
            color: (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))
                .withValues(alpha: 0.5),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(dailyDates.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: activeData[i].toDouble(),
                gradient: const LinearGradient(
                  colors: [Color(0xFFF5C8BC), Color(0xFF38BDF8)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: _selectedChartDays <= 7 ? 18 : 8,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
              ),
            ],
          );
        }),
      ),
    );
  }

  // =========================================================================
  // 3. Tavola Left-Bottom: "The room" 3/4 Donut Ring Gauge Inventory Radar
  // =========================================================================
  Widget _buildTheRoomInventoryCard({
    required BuildContext context,
    required bool isDark,
    required int total,
    required int healthy,
    required int low,
    required int outOfStock,
  }) {
    final healthyPct = total > 0 ? (healthy / total) : 1.0;

    return AppCard(
      isFrosted: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'The room',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'សុខភាពស្តុកទំនិញ (Capacity)',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => context.go('/admin/inventory'),
                icon: const Icon(Icons.north_east_rounded, size: 16),
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  padding: const EdgeInsets.all(6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Custom Painted Donut Ring Gauge
          Center(
            child: SizedBox(
              width: 130,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(130, 120),
                    painter: _DonutGaugePainter(
                      percent: healthyPct,
                      activeColor: const Color(0xFF34D399),
                      warningColor: const Color(0xFFFBBF24),
                      dangerColor: const Color(0xFFF87171),
                      trackColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(healthyPct * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Optimal',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF34D399),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 3 Category Dots Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRoomLegendDot(
                label: 'ល្អ',
                count: healthy,
                color: const Color(0xFF34D399),
                isDark: isDark,
              ),
              _buildRoomLegendDot(
                label: 'ស្តុកទាប',
                count: low,
                color: const Color(0xFFFBBF24),
                isDark: isDark,
              ),
              _buildRoomLegendDot(
                label: 'អស់ស្តុក',
                count: outOfStock,
                color: const Color(0xFFF87171),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoomLegendDot({
    required String label,
    required int count,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(
          '$label: $count',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 4. Tavola Left-Bottom: "Still to come" Fast Launch Operations Card
  // =========================================================================
  Widget _buildStillToComeActionsCard({
    required BuildContext context,
    required bool isDark,
    required int todayOrders,
  }) {
    return AppCard(
      isFrosted: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Still to come',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'កិច្ចការបន្ទាន់ & បញ្ជរលក់',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Shift Active',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF818CF8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Primary Big POS Launch Card Button
          InkWell(
            onTap: () => context.go('/pos'),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.point_of_sale_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚡ បើកបញ្ជរលក់ (Open POS)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Checkout, Barcode scan, & Cash',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Quick Action Sub-buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ProductFormDialog.show(context),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 14),
                  label: const Text('+ ទំនិញថ្មី', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/admin/inventory'),
                  icon: const Icon(Icons.swap_vert_rounded, size: 14),
                  label: const Text('ចលនាស្តុក', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 5. Tavola Right: "On the pass" (Recent Orders 2-Column Ticket Grid)
  // =========================================================================
  Widget _buildOnThePassCard({
    required BuildContext context,
    required bool isDark,
    required List<SaleModel> recentSales,
  }) {
    return AppCard(
      isFrosted: true,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: "On the pass" + Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'On the pass',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'វិក្កយបត្រថ្មីៗ (Recent Orders)',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${recentSales.length} open • Realtime',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF34D399),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: () => context.go('/pos'),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    tooltip: 'New Order',
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                      padding: const EdgeInsets.all(6),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => context.go('/admin/reports'),
                    icon: const Icon(Icons.north_east_rounded, size: 16),
                    tooltip: 'All Reports',
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                      padding: const EdgeInsets.all(6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Ticket Cards Grid (2-columns on tablet/desktop, 1 on narrow phone)
          if (recentSales.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'មិនទាន់មានការលក់ទេ',
                subtitle: 'វិក្កយបត្រថ្មីៗនឹងចេញមកទីនេះពេលលក់តាម POS',
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isTwoCol = constraints.maxWidth >= 380;
                if (isTwoCol) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.92,
                    ),
                    itemCount: recentSales.length,
                    itemBuilder: (context, index) {
                      return _buildTavolaPassTicket(
                        context: context,
                        isDark: isDark,
                        sale: recentSales[index],
                        cardIndex: index,
                        isTwoCol: true,
                      );
                    },
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentSales.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildTavolaPassTicket(
                        context: context,
                        isDark: isDark,
                        sale: recentSales[index],
                        cardIndex: index,
                        isTwoCol: false,
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  /// Signature Tavola Ticket Card:
  /// - Mint Green card (#A8DCC8 tint) for Cash/Done
  /// - Peach Coral card (#F5C8BC tint) for KHQR/Bank/Debt
  /// - Ticket header with invoice number, time badge, table/customer title
  /// - Itemized rows (1x ..., 2x ...)
  /// - Big bottom price with white checkmark button
  Widget _buildTavolaPassTicket({
    required BuildContext context,
    required bool isDark,
    required SaleModel sale,
    required int cardIndex,
    bool isTwoCol = true,
  }) {
    final isKhqr = sale.paymentMethod.toLowerCase() == 'khqr';
    // Alternate or use payment method to give Tavola pastel look
    final isPeach = isKhqr || (cardIndex % 2 == 1 && sale.paymentMethod.toLowerCase() != 'cash');

    // Tavola Signature Pastel Surface Colors
    final cardBg = isPeach
        ? (isDark
            ? const Color(0xFF281717).withValues(alpha: 0.85)
            : const Color(0xFFFFF1EC))
        : (isDark
            ? const Color(0xFF132A24).withValues(alpha: 0.85)
            : const Color(0xFFF0FAF5));

    final cardBorder = isPeach
        ? const Color(0xFFF5C8BC).withValues(alpha: isDark ? 0.40 : 0.75)
        : const Color(0xFFA8DCC8).withValues(alpha: isDark ? 0.40 : 0.75);

    final titleColor = isPeach
        ? (isDark ? const Color(0xFFFFD5CB) : const Color(0xFF8A3022))
        : (isDark ? const Color(0xFFB4E7D5) : const Color(0xFF155E45));

    final checkBtnBg = isPeach
        ? (isDark ? const Color(0xFFE06D53) : Colors.white)
        : (isDark ? const Color(0xFF2E8B67) : Colors.white);

    final checkIconColor = isPeach
        ? (isDark ? Colors.white : const Color(0xFFE06D53))
        : (isDark ? Colors.white : const Color(0xFF2E8B67));

    final relativeTime = _formatRelativeDate(sale.createdAt);
    final shortInvoice = sale.invoiceNumber.length > 8
        ? sale.invoiceNumber.substring(sale.invoiceNumber.length - 8)
        : sale.invoiceNumber;

    return HoverCard(
      liftOffset: 3.0,
      child: InkWell(
        onTap: () => SaleDetailDialog.show(context, sale),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ticket Top Row: #Invoice & Timer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#$shortInvoice',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '⏱ $relativeTime',
                        style: TextStyle(
                          fontSize: 10,
                          color: titleColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.more_horiz_rounded,
                    size: 16,
                    color: titleColor.withValues(alpha: 0.6),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Customer / Walk-in Header
              Text(
                'Walk-in Customer',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),

              // Itemized Preview (1x ..., 2x ...)
              if (isTwoCol)
                Expanded(
                  child: ListView(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      if (sale.items.isEmpty)
                        Text(
                          'No item detail',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        )
                      else
                        ...sale.items.take(3).map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 3.0),
                            child: Text(
                              '${item.qty}x ${item.name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? const Color(0xFFE2E8F0)
                                    : const Color(0xFF334155),
                              ),
                            ),
                          );
                        }),
                      if (sale.items.length > 3)
                        Text(
                          '+ ${sale.items.length - 3} more items',
                          style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: titleColor,
                          ),
                        ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (sale.items.isEmpty)
                        Text(
                          'No item detail',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        )
                      else
                        ...sale.items.take(3).map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 3.0),
                            child: Text(
                              '${item.qty}x ${item.name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? const Color(0xFFE2E8F0)
                                    : const Color(0xFF334155),
                              ),
                            ),
                          );
                        }),
                      if (sale.items.length > 3)
                        Text(
                          '+ ${sale.items.length - 3} more items',
                          style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: titleColor,
                          ),
                        ),
                    ],
                  ),
                ),

              const Divider(height: 12, thickness: 0.8),

              // Ticket Footer: Big Price & Circular Checkmark Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        MoneyUtils.formatRiel(sale.total),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Ready • ${sale.items.length} items',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: checkBtnBg,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: checkIconColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatRelativeDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

/// Custom Donut Ring Gauge Painter for Tavola "The room" widget
class _DonutGaugePainter extends CustomPainter {
  final double percent;
  final Color activeColor;
  final Color warningColor;
  final Color dangerColor;
  final Color trackColor;

  _DonutGaugePainter({
    required this.percent,
    required this.activeColor,
    required this.warningColor,
    required this.dangerColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 6);
    final radius = (size.width - 24) / 2;
    const strokeWidth = 12.0;

    // Background 270 degree track (from 135 to 405 deg)
    const startAngle = 135 * math.pi / 180;
    const maxSweep = 270 * math.pi / 180;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      maxSweep,
      false,
      trackPaint,
    );

    // Active progress arc
    final sweep = (maxSweep * percent.clamp(0.0, 1.0));
    final activePaint = Paint()
      ..color = percent >= 0.7 ? activeColor : (percent >= 0.3 ? warningColor : dangerColor)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (sweep > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutGaugePainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.trackColor != trackColor;
  }
}
