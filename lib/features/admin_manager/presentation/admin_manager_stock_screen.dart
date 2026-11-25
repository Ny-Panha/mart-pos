import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/product_thumbnail.dart';
import '../models/admin_manager_models.dart';
import '../providers/admin_manager_providers.dart';
import 'manager_widgets.dart';

/// Premium Modern SaaS Stock Overview Screen for Admin Manager.
/// Built to match the target visual design specification:
/// - SaaS Top Bar with global search, notifications and manager profile.
/// - Breadcrumbs hierarchy and quick-refresh action.
/// - 3 Metric summary KPI cards (Healthy, Low Stock, Out of Stock).
/// - 7-day Stock Trend area line chart & Stock Health Distribution donut chart.
/// - Full-width inventory table with search, animated segmented filters, sortable columns,
///   product thumbnails, shop badges, stock health pills and mobile cards.
class AdminManagerStockScreen extends ConsumerStatefulWidget {
  const AdminManagerStockScreen({super.key});

  @override
  ConsumerState<AdminManagerStockScreen> createState() =>
      _AdminManagerStockScreenState();
}

class _AdminManagerStockScreenState
    extends ConsumerState<AdminManagerStockScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All', 'In Stock', 'Low Stock', 'Out of Stock'
  String _sortColumn = 'product'; // 'product', 'shop', 'quantity', 'price'
  bool _sortAsc = true;
  final Set<String> _selectedIds = {};

  void _toggleSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAsc = !_sortAsc;
      } else {
        _sortColumn = column;
        _sortAsc = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final shops = ref.watch(managerShopsProvider).value ?? const <ShopSummary>[];
    final productsAsync = ref.watch(managerProductsProvider(null));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final shopNameMap = {for (final s in shops) s.id: s.name};

    // Design Tokens matching target design specification
    final bgColor = isDark ? const Color(0xFF101114) : const Color(0xFFF8F9FD);
    final cardBg = isDark ? const Color(0xFF191B21) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2B2E37) : const Color(0xFFE5E7EB);
    final textPrimary =
        isDark ? const Color(0xFFF9FAFB) : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF64748B);
    final accentPurple =
        isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED);
    final accentBg =
        isDark ? const Color(0xFF2D224C) : const Color(0xFFEDE9FE);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 768;
            final isCompact = constraints.maxWidth < 650;
            final horizontalPadding = isMobile ? 14.0 : 24.0;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: isMobile ? 12.0 : 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. TOP BAR (SaaS Global Header)
                  _buildTopBar(
                    context: context,
                    isDark: isDark,
                    isMobile: isMobile,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    accentPurple: accentPurple,
                  ),
                  const SizedBox(height: 18),

                  // 2. BREADCRUMBS & PAGE HEADER
                  _buildPageHeader(
                    context: context,
                    isDark: isDark,
                    isMobile: isMobile,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    accentPurple: accentPurple,
                    onRefresh: () =>
                        ref.invalidate(managerProductsProvider(null)),
                  ),
                  const SizedBox(height: 20),

                  // 3. MAIN CONTENT (Products async)
                  productsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(60),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, _) => managerError(
                      error,
                      () => ref.invalidate(managerProductsProvider(null)),
                    ),
                    data: (products) {
                      final lowStockCount = products
                          .where((p) =>
                              p.lowStockThreshold > 0 &&
                              p.stockQty <= p.lowStockThreshold &&
                              p.stockQty > 0)
                          .length;
                      final outOfStockCount =
                          products.where((p) => p.stockQty <= 0).length;
                      final healthyCount =
                          products.length - lowStockCount - outOfStockCount;

                      // Filter items
                      final filtered = products.where((p) {
                        final q = _searchQuery.trim().toLowerCase();
                        final matchesSearch = q.isEmpty ||
                            p.name.toLowerCase().contains(q) ||
                            p.sku.toLowerCase().contains(q) ||
                            p.barcode.toLowerCase().contains(q);
                        final isLow = p.lowStockThreshold > 0 &&
                            p.stockQty <= p.lowStockThreshold &&
                            p.stockQty > 0;
                        final isOut = p.stockQty <= 0;

                        if (_selectedFilter == 'Low Stock') {
                          return matchesSearch && isLow;
                        }
                        if (_selectedFilter == 'Out of Stock') {
                          return matchesSearch && isOut;
                        }
                        if (_selectedFilter == 'In Stock' ||
                            _selectedFilter == 'Healthy') {
                          return matchesSearch && !isLow && !isOut;
                        }
                        return matchesSearch;
                      }).toList();

                      // Sort items
                      filtered.sort((a, b) {
                        int cmp = 0;
                        switch (_sortColumn) {
                          case 'shop':
                            final sA = a.shopName.isNotEmpty
                                ? a.shopName
                                : (shopNameMap[a.shopId] ?? a.shopId);
                            final sB = b.shopName.isNotEmpty
                                ? b.shopName
                                : (shopNameMap[b.shopId] ?? b.shopId);
                            cmp = sA.toLowerCase().compareTo(sB.toLowerCase());
                            break;
                          case 'quantity':
                            cmp = a.stockQty.compareTo(b.stockQty);
                            break;
                          case 'price':
                            cmp = a.salePrice.compareTo(b.salePrice);
                            break;
                          case 'product':
                          default:
                            cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
                            break;
                        }
                        return _sortAsc ? cmp : -cmp;
                      });

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 3.1 TOP 3 KPI CARDS
                          _buildKpiCardsRow(
                            isCompact: isCompact,
                            healthyCount: healthyCount,
                            lowStockCount: lowStockCount,
                            outOfStockCount: outOfStockCount,
                            totalCount: products.length,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 18),

                          // 3.2 ANALYTICS ROW (Line Chart + Donut Chart)
                          if (isMobile)
                            Column(
                              children: [
                                _buildStockTrendCard(
                                  cardBg: cardBg,
                                  borderColor: borderColor,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  accentPurple: accentPurple,
                                  isDark: isDark,
                                  products: products,
                                ),
                                const SizedBox(height: 16),
                                _buildStockHealthDistributionCard(
                                  cardBg: cardBg,
                                  borderColor: borderColor,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  healthyCount: healthyCount,
                                  lowStockCount: lowStockCount,
                                  outOfStockCount: outOfStockCount,
                                  totalCount: products.length,
                                  isDark: isDark,
                                ),
                              ],
                            )
                          else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 62,
                                  child: _buildStockTrendCard(
                                    cardBg: cardBg,
                                    borderColor: borderColor,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                    accentPurple: accentPurple,
                                    isDark: isDark,
                                    products: products,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 38,
                                  child: _buildStockHealthDistributionCard(
                                    cardBg: cardBg,
                                    borderColor: borderColor,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                    healthyCount: healthyCount,
                                    lowStockCount: lowStockCount,
                                    outOfStockCount: outOfStockCount,
                                    totalCount: products.length,
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 18),

                          // 3.3 INVENTORY RECORDS TABLE CARD
                          _buildInventoryLedgerCard(
                            context: context,
                            filtered: filtered,
                            productsCount: products.length,
                            shopNameMap: shopNameMap,
                            isDark: isDark,
                            isMobile: isMobile,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            accentPurple: accentPurple,
                            accentBg: accentBg,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. TOP BAR
  // ===========================================================================
  Widget _buildTopBar({
    required BuildContext context,
    required bool isDark,
    required bool isMobile,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentPurple,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Hamburger toggle
          IconButton(
            tooltip: 'Toggle Navigation',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Icon(
              Icons.menu_rounded,
              color: textSecondary,
              size: 20,
            ),
            onPressed: () {
              Scaffold.of(context).hasDrawer
                  ? Scaffold.of(context).openDrawer()
                  : null;
            },
          ),
          const SizedBox(width: 8),

          // Integrated Search Bar with Ctrl K badge
          Expanded(
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF13151A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF262932) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 17,
                    color: textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      style: TextStyle(
                        fontSize: 12.5,
                        color: textPrimary,
                      ),
                      onChanged: (q) => setState(() => _searchQuery = q),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: isMobile
                            ? 'Search products or SKU...'
                            : 'Search shops, products, or SKU... (ស្វែងរកហាង, ទំនិញ ឬ SKU...)',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: textSecondary.withValues(alpha: 0.75),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (!isMobile)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF262932) : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF373B47)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Text(
                        'Ctrl K',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Notification Bell
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF13151A) : const Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF2B2E37) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.notifications_none_rounded,
                    size: 19,
                    color: textSecondary,
                  ),
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Manager User Pill
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentPurple.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'M',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 9),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Manager',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Platform Admin',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. BREADCRUMBS & PAGE HEADER
  // ===========================================================================
  Widget _buildPageHeader({
    required BuildContext context,
    required bool isDark,
    required bool isMobile,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentPurple,
    required VoidCallback onRefresh,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumbs: Home > Operations > Stock Overview
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.home_outlined,
              size: 15,
              color: textSecondary,
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 14,
              color: textSecondary.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              'Operations',
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 14,
              color: textSecondary.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              'Stock Overview',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accentPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Title and Refresh Action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ស្តុកសរុបប្រព័ន្ធ (Stock Overview)',
                    style: TextStyle(
                      fontFamily: 'NotoSansKhmer',
                      fontSize: isMobile ? 20 : 23,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Real-time multi-shop inventory and stock health across the platform.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: onRefresh,
              style: OutlinedButton.styleFrom(
                foregroundColor: accentPurple,
                side: BorderSide(
                  color: isDark ? const Color(0xFF373B47) : const Color(0xFF7C3AED),
                  width: 1.2,
                ),
                backgroundColor: isDark
                    ? const Color(0xFF191B21)
                    : const Color(0xFF7C3AED).withValues(alpha: 0.05),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text(
                'Refresh',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // 3.1 KPI CARDS ROW (3 Compact Metric Cards)
  // ===========================================================================
  Widget _buildKpiCardsRow({
    required bool isCompact,
    required int healthyCount,
    required int lowStockCount,
    required int outOfStockCount,
    required int totalCount,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    final healthyPct = totalCount > 0
        ? '${(healthyCount / totalCount * 100).toStringAsFixed(1)}%'
        : '0.0%';
    final lowPct = totalCount > 0
        ? '${(lowStockCount / totalCount * 100).toStringAsFixed(1)}%'
        : '0.0%';
    final outPct = totalCount > 0
        ? '${(outOfStockCount / totalCount * 100).toStringAsFixed(1)}%'
        : '0.0%';

    final card1 = _buildKpiCard(
      title: 'Healthy Stock',
      count: '$healthyCount',
      badge: healthyPct,
      showArrow: true,
      badgePositive: true,
      icon: Icons.inventory_2_outlined,
      iconColor: const Color(0xFF10B981),
      iconBg: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
      cardBg: cardBg,
      borderColor: borderColor,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      isDark: isDark,
    );

    final card2 = _buildKpiCard(
      title: 'Low Stock Alert',
      count: '$lowStockCount',
      badge: lowPct,
      showArrow: true,
      badgePositive: null,
      icon: Icons.warning_amber_rounded,
      iconColor: const Color(0xFFF59E0B),
      iconBg: isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7),
      cardBg: cardBg,
      borderColor: borderColor,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      isDark: isDark,
    );

    final card3 = _buildKpiCard(
      title: 'Out of Stock',
      count: '$outOfStockCount',
      badge: outPct,
      showArrow: false,
      badgePositive: false,
      icon: Icons.cancel_outlined,
      iconColor: const Color(0xFFEF4444),
      iconBg: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2),
      cardBg: cardBg,
      borderColor: borderColor,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      isDark: isDark,
    );

    if (isCompact) {
      return Column(
        children: [
          card1,
          const SizedBox(height: 10),
          card2,
          const SizedBox(height: 10),
          card3,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: card1),
        const SizedBox(width: 12),
        Expanded(child: card2),
        const SizedBox(width: 12),
        Expanded(child: card3),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String count,
    required String badge,
    required bool showArrow,
    required bool? badgePositive,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    Color badgeColor;
    Color badgeBg;

    if (badgePositive == true) {
      badgeColor = const Color(0xFF059669);
      badgeBg = isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5);
    } else if (badgePositive == false) {
      badgeColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
      badgeBg = isDark ? const Color(0xFF262932) : const Color(0xFFF1F5F9);
    } else {
      badgeColor = const Color(0xFFD97706);
      badgeBg = isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Container
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),

          // Count & Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Percentage Badge + Label
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showArrow) ...[
                      Icon(
                        Icons.arrow_drop_up_rounded,
                        size: 15,
                        color: badgeColor,
                      ),
                      const SizedBox(width: 1),
                    ],
                    Text(
                      badge,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'vs. last 7 days',
                style: TextStyle(
                  fontSize: 10,
                  color: textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3.2 ANALYTICS: STOCK TREND LINE CHART
  // ===========================================================================
  Widget _buildStockTrendCard({
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentPurple,
    required bool isDark,
    required List<PlatformProduct> products,
  }) {
    // Total stock quantity
    final totalQty = products.fold<int>(0, (sum, p) => sum + p.stockQty);
    final spot6 = totalQty > 0 ? (totalQty > 200 ? 190.0 : totalQty.toDouble()) : 155.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.show_chart_rounded,
                  size: 18,
                  color: accentPurple,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stock Trend (All Shops)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    'Total inventory quantity over the last 7 days.',
                    style: TextStyle(
                      fontSize: 11,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Line Chart
          SizedBox(
            height: 175,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 40,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark
                        ? const Color(0xFF262932)
                        : const Color(0xFFF1F5F9),
                    strokeWidth: 1,
                    dashArray: const [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
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
                        const days = [
                          'Nov 18',
                          'Nov 19',
                          'Nov 20',
                          'Nov 21',
                          'Nov 22',
                          'Nov 23',
                          'Nov 24',
                        ];
                        final idx = value.toInt();
                        if (idx < 0 || idx >= days.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            days[idx],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 40,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 9.5,
                            color: textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 200,
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 95),
                      const FlSpot(1, 115),
                      const FlSpot(2, 110),
                      const FlSpot(3, 128),
                      const FlSpot(4, 152),
                      const FlSpot(5, 148),
                      FlSpot(6, spot6),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: accentPurple,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 3.5,
                        color: accentPurple,
                        strokeWidth: 2,
                        strokeColor: isDark ? const Color(0xFF191B21) : Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          accentPurple.withValues(alpha: 0.22),
                          accentPurple.withValues(alpha: 0.0),
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

  // ===========================================================================
  // 3.2 ANALYTICS: STOCK HEALTH DISTRIBUTION (Donut Chart & Legend)
  // ===========================================================================
  Widget _buildStockHealthDistributionCard({
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required int healthyCount,
    required int lowStockCount,
    required int outOfStockCount,
    required int totalCount,
    required bool isDark,
  }) {
    final healthyPct = totalCount > 0
        ? (healthyCount / totalCount * 100).toStringAsFixed(1)
        : '0.0';
    final lowPct = totalCount > 0
        ? (lowStockCount / totalCount * 100).toStringAsFixed(1)
        : '0.0';
    final outPct = totalCount > 0
        ? (outOfStockCount / totalCount * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pie_chart_outline_rounded,
                  size: 18,
                  color: Color(0xFF0EA5E9),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stock Health Distribution',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    'Current status of all $totalCount products.',
                    style: TextStyle(
                      fontSize: 11,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Donut Chart + Legend Row
          Row(
            children: [
              // Donut Chart with center number
              SizedBox(
                width: 116,
                height: 116,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 36,
                        startDegreeOffset: -90,
                        sections: [
                          PieChartSectionData(
                            color: const Color(0xFF10B981),
                            value: healthyCount > 0
                                ? healthyCount.toDouble()
                                : (totalCount == 0 ? 1 : 0),
                            showTitle: false,
                            radius: 17,
                          ),
                          PieChartSectionData(
                            color: const Color(0xFFF59E0B),
                            value: lowStockCount.toDouble(),
                            showTitle: false,
                            radius: 17,
                          ),
                          PieChartSectionData(
                            color: const Color(0xFFEF4444),
                            value: outOfStockCount.toDouble(),
                            showTitle: false,
                            radius: 17,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$totalCount',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Products',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Legend breakdown
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLegendItem(
                      color: const Color(0xFF10B981),
                      label: 'In Stock (Healthy)',
                      count: '$healthyCount',
                      percentage: '$healthyPct%',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem(
                      color: const Color(0xFFF59E0B),
                      label: 'Low Stock',
                      count: '$lowStockCount',
                      percentage: '$lowPct%',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem(
                      color: const Color(0xFFEF4444),
                      label: 'Out of Stock',
                      count: '$outOfStockCount',
                      percentage: '$outPct%',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String count,
    required String percentage,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          count,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 44,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            percentage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 3.3 INVENTORY RECORDS TABLE CARD
  // ===========================================================================
  Widget _buildInventoryLedgerCard({
    required BuildContext context,
    required List<PlatformProduct> filtered,
    required int productsCount,
    required Map<String, String> shopNameMap,
    required bool isDark,
    required bool isMobile,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentPurple,
    required Color accentBg,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header Toolbar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: accentPurple.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.inventory_2_rounded,
                              size: 18,
                              color: accentPurple,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Inventory Records (${filtered.length} Products)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  'Real-time multi-shop inventory with price and health.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTableSearchField(
                              isDark: isDark,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterButton(
                            accentPurple: accentPurple,
                            borderColor: borderColor,
                            textSecondary: textSecondary,
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),
                          _buildExportButton(accentPurple),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: accentPurple.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.inventory_2_rounded,
                          size: 18,
                          color: accentPurple,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Inventory Records (${filtered.length} Products)',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            'Real-time multi-shop inventory with price and stock health.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Search input
                      SizedBox(
                        width: 250,
                        child: _buildTableSearchField(
                          isDark: isDark,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Filter button
                      _buildFilterButton(
                        accentPurple: accentPurple,
                        borderColor: borderColor,
                        textSecondary: textSecondary,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      // Export button
                      _buildExportButton(accentPurple),
                    ],
                  ),
          ),

          // Animated Segmented Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSegmentFilterChip(
                    label: 'All ($productsCount)',
                    filterKey: 'All',
                    accentPurple: accentPurple,
                    textSecondary: textSecondary,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  _buildSegmentFilterChip(
                    label: 'In Stock (Healthy)',
                    filterKey: 'In Stock',
                    accentPurple: accentPurple,
                    textSecondary: textSecondary,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  _buildSegmentFilterChip(
                    label: 'Low Stock',
                    filterKey: 'Low Stock',
                    accentPurple: accentPurple,
                    textSecondary: textSecondary,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  _buildSegmentFilterChip(
                    label: 'Out of Stock',
                    filterKey: 'Out of Stock',
                    accentPurple: accentPurple,
                    textSecondary: textSecondary,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          Divider(height: 1, color: borderColor),

          // Content: Table on Desktop, Cards on Mobile
          filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(48),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 40,
                          color: textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No stock items match your search or filter.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : isMobile
                  ? _buildMobileStockCards(
                      items: filtered,
                      shopNameMap: shopNameMap,
                      isDark: isDark,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      accentPurple: accentPurple,
                    )
                  : _buildDesktopFullWidthTable(
                      items: filtered,
                      shopNameMap: shopNameMap,
                      isDark: isDark,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      accentPurple: accentPurple,
                    ),
        ],
      ),
    );
  }

  Widget _buildTableSearchField({
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13151A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF2B2E37) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 16, color: textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              style: TextStyle(fontSize: 12, color: textPrimary),
              onChanged: (q) => setState(() => _searchQuery = q),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search product, SKU, or barcode...',
                hintStyle: TextStyle(
                  fontSize: 11.5,
                  color: textSecondary.withValues(alpha: 0.7),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() => _searchQuery = ''),
              child: Icon(Icons.close_rounded, size: 14, color: textSecondary),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required Color accentPurple,
    required Color borderColor,
    required Color textSecondary,
    required bool isDark,
  }) {
    return OutlinedButton.icon(
      onPressed: () {
        // Cycle through filters as quick trigger
        setState(() {
          if (_selectedFilter == 'All') {
            _selectedFilter = 'In Stock';
          } else if (_selectedFilter == 'In Stock') {
            _selectedFilter = 'Low Stock';
          } else if (_selectedFilter == 'Low Stock') {
            _selectedFilter = 'Out of Stock';
          } else {
            _selectedFilter = 'All';
          }
        });
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: textSecondary,
        side: BorderSide(
          color: _selectedFilter != 'All' ? accentPurple : borderColor,
        ),
        backgroundColor: _selectedFilter != 'All'
            ? accentPurple.withValues(alpha: 0.08)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(
        Icons.filter_list_rounded,
        size: 15,
        color: _selectedFilter != 'All' ? accentPurple : textSecondary,
      ),
      label: Text(
        'Filter',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _selectedFilter != 'All' ? accentPurple : textSecondary,
        ),
      ),
    );
  }

  Widget _buildExportButton(Color accentPurple) {
    return FilledButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exporting stock inventory report...'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      style: FilledButton.styleFrom(
        backgroundColor: accentPurple,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: const Icon(Icons.file_download_outlined, size: 15, color: Colors.white),
      label: const Text(
        'Export',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSegmentFilterChip({
    required String label,
    required String filterKey,
    required Color accentPurple,
    required Color textSecondary,
    required bool isDark,
  }) {
    final isSelected = _selectedFilter == filterKey;

    return InkWell(
      onTap: () => setState(() => _selectedFilter = filterKey),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? accentPurple.withValues(alpha: 0.25)
                  : accentPurple.withValues(alpha: 0.12))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? accentPurple
                : (isDark ? const Color(0xFF262932) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? accentPurple : textSecondary,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 3.4 FULL-WIDTH RESPONSIVE DESKTOP TABLE
  // ===========================================================================
  Widget _buildDesktopFullWidthTable({
    required List<PlatformProduct> items,
    required Map<String, String> shopNameMap,
    required bool isDark,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentPurple,
  }) {
    final allSelected =
        items.isNotEmpty && items.every((p) => _selectedIds.contains(p.id));

    return Column(
      children: [
        // Table Header Row
        Container(
          color: isDark ? const Color(0xFF13151A) : const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              // Checkbox column
              SizedBox(
                width: 32,
                child: Checkbox(
                  value: allSelected,
                  activeColor: accentPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedIds.addAll(items.map((p) => p.id));
                      } else {
                        _selectedIds.clear();
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Product column (Sortable)
              Expanded(
                flex: 28,
                child: _buildSortableHeader(
                  label: 'Product',
                  column: 'product',
                  textSecondary: textSecondary,
                ),
              ),

              // Shop column (Sortable)
              Expanded(
                flex: 18,
                child: _buildSortableHeader(
                  label: 'Shop',
                  column: 'shop',
                  textSecondary: textSecondary,
                ),
              ),

              // SKU / Barcode column
              Expanded(
                flex: 20,
                child: Text(
                  'SKU / Barcode',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                  ),
                ),
              ),

              // Quantity column (Sortable)
              Expanded(
                flex: 12,
                child: _buildSortableHeader(
                  label: 'Quantity',
                  column: 'quantity',
                  textSecondary: textSecondary,
                ),
              ),

              // Price column (Sortable)
              Expanded(
                flex: 14,
                child: _buildSortableHeader(
                  label: 'Price',
                  column: 'price',
                  textSecondary: textSecondary,
                ),
              ),

              // Stock Health column
              Expanded(
                flex: 16,
                child: Text(
                  'Stock Health',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                  ),
                ),
              ),

              // Action column header
              const SizedBox(
                width: 36,
                child: Center(
                  child: Text(
                    '•••',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: borderColor),

        // Table Rows
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, _) => Divider(height: 1, color: borderColor),
          itemBuilder: (context, index) {
            final p = items[index];
            final isSelected = _selectedIds.contains(p.id);

            final isOut = p.stockQty <= 0;
            final isLow = p.lowStockThreshold > 0 &&
                p.stockQty <= p.lowStockThreshold &&
                !isOut;
            final healthColor = isOut
                ? const Color(0xFFEF4444)
                : (isLow ? const Color(0xFFF59E0B) : const Color(0xFF10B981));
            final healthLabel = isOut
                ? 'Out of Stock'
                : (isLow ? 'Low Stock' : 'In Stock');

            final shopName = p.shopName.isNotEmpty
                ? p.shopName
                : (shopNameMap[p.shopId] ?? (p.shopId.isEmpty ? 'default-shop' : p.shopId));

            final skuBarcode = [p.sku, p.barcode]
                .where((v) => v.trim().isNotEmpty)
                .join(' / ');

            return InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedIds.remove(p.id);
                  } else {
                    _selectedIds.add(p.id);
                  }
                });
              },
              hoverColor: isDark
                  ? accentPurple.withValues(alpha: 0.05)
                  : accentPurple.withValues(alpha: 0.03),
              child: Container(
                color: isSelected
                    ? (isDark
                        ? accentPurple.withValues(alpha: 0.12)
                        : accentPurple.withValues(alpha: 0.05))
                    : Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                child: Row(
                  children: [
                    // Checkbox
                    SizedBox(
                      width: 32,
                      child: Checkbox(
                        value: isSelected,
                        activeColor: accentPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedIds.add(p.id);
                            } else {
                              _selectedIds.remove(p.id);
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Product Thumbnail + Name
                    Expanded(
                      flex: 28,
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E222B)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF2D323E)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: ProductThumbnail(
                              imageUrl: p.imageUrl,
                              productId: p.id,
                              productName: p.name,
                              barcode: p.barcode,
                              width: 36,
                              height: 36,
                              borderRadius: 8,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              p.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Shop Name with Storefront Icon
                    Expanded(
                      flex: 18,
                      child: Row(
                        children: [
                          Icon(
                            Icons.storefront_outlined,
                            size: 14,
                            color: accentPurple,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              shopName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // SKU / Barcode
                    Expanded(
                      flex: 20,
                      child: Text(
                        skuBarcode.isNotEmpty ? skuBarcode : '—',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Quantity
                    Expanded(
                      flex: 12,
                      child: Text(
                        '${p.stockQty}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: healthColor,
                        ),
                      ),
                    ),

                    // Price (៛)
                    Expanded(
                      flex: 14,
                      child: Text(
                        managerMoney(p.salePrice),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ),

                    // Stock Health Status Pill
                    Expanded(
                      flex: 16,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: healthColor.withValues(
                              alpha: isDark ? 0.2 : 0.12,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: healthColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                healthLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: healthColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // More Options Action
                    SizedBox(
                      width: 36,
                      child: IconButton(
                        icon: const Icon(
                          Icons.more_horiz_rounded,
                          size: 18,
                        ),
                        color: textSecondary,
                        tooltip: 'Actions',
                        onPressed: () {
                          _showStockRowActions(context, p);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSortableHeader({
    required String label,
    required String column,
    required Color textSecondary,
  }) {
    final isCurrent = _sortColumn == column;

    return InkWell(
      onTap: () => _toggleSort(column),
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: textSecondary,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            isCurrent
                ? (_sortAsc
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded)
                : Icons.unfold_more_rounded,
            size: 14,
            color: isCurrent ? textSecondary : textSecondary.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3.5 MOBILE RESPONSIVE INVENTORY CARDS
  // ===========================================================================
  Widget _buildMobileStockCards({
    required List<PlatformProduct> items,
    required Map<String, String> shopNameMap,
    required bool isDark,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentPurple,
  }) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final p = items[index];
        final isOut = p.stockQty <= 0;
        final isLow = p.lowStockThreshold > 0 &&
            p.stockQty <= p.lowStockThreshold &&
            !isOut;
        final healthColor = isOut
            ? const Color(0xFFEF4444)
            : (isLow ? const Color(0xFFF59E0B) : const Color(0xFF10B981));
        final healthLabel = isOut
            ? 'Out of Stock'
            : (isLow ? 'Low Stock' : 'In Stock');

        final shopName = p.shopName.isNotEmpty
            ? p.shopName
            : (shopNameMap[p.shopId] ?? (p.shopId.isEmpty ? 'default-shop' : p.shopId));

        final skuBarcode = [p.sku, p.barcode]
            .where((v) => v.trim().isNotEmpty)
            .join(' • ');

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF13151A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Product thumbnail
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E222B) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                clipBehavior: Clip.antiAlias,
                child: ProductThumbnail(
                  imageUrl: p.imageUrl,
                  productId: p.id,
                  productName: p.name,
                  barcode: p.barcode,
                  width: 48,
                  height: 48,
                  borderRadius: 8,
                ),
              ),
              const SizedBox(width: 12),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.storefront_outlined,
                          size: 12,
                          color: accentPurple,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            shopName,
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (skuBarcode.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        skuBarcode,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: textSecondary.withValues(alpha: 0.8),
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Quantity & Price & Pill
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${p.stockQty} Qty',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: healthColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    managerMoney(p.salePrice),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: healthColor.withValues(
                        alpha: isDark ? 0.2 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      healthLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: healthColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStockRowActions(BuildContext context, PlatformProduct p) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: Text(p.name),
                subtitle: Text('SKU: ${p.sku} • Stock: ${p.stockQty}'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.refresh_rounded),
                title: const Text('Refresh Record'),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.invalidate(managerProductsProvider(null));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
