import 'package:mart_pos/core/motion/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/product_thumbnail.dart';
import '../models/admin_manager_models.dart';
import '../providers/admin_manager_providers.dart';
import 'manager_widgets.dart';

/// Premium Minimal SaaS Global Products Catalog Screen for Admin Manager.
/// Built to reproduce the target visual specification combining Ecomiq and VNDLY:
/// - Minimal outline sidebar with Sage Green active state.
/// - Breadcrumbs hierarchy and quick-refresh action.
/// - Compact catalog overview metrics (Catalog Items, Total Valuation, Active Shop, Categories).
/// - Unified search input, Shop filter dropdown, Category dropdown, Sort dropdown, and Grid/Table toggle.
/// - Segmented category navigation pills (All, Beverages, Food & Snacks, Personal Care).
/// - Full-width responsive product inventory table with product thumbnails, category badges,
///   shop, SKU/Barcode, stock health indicator pills, formatted price, and Details button.
/// - Responsive grid view toggle option with compact cards.
/// - Animated product details slide-in side panel on desktop and bottom sheet on mobile (150-250ms).
/// - Comprehensive Light and Dark mode support with Sage Green color palette.
class AdminManagerCatalogScreen extends ConsumerStatefulWidget {
  const AdminManagerCatalogScreen({super.key});

  @override
  ConsumerState<AdminManagerCatalogScreen> createState() =>
      _AdminManagerCatalogScreenState();
}

class _AdminManagerCatalogScreenState
    extends ConsumerState<AdminManagerCatalogScreen> {
  String _searchQuery = '';
  String _selectedShopId = 'All';
  String _selectedCategory = 'All';
  String _selectedSort = 'Name (A-Z)';
  bool _isGridView =
      false; // Default to full-width table layout matching mockup

  void _openDetails(
    PlatformProduct product,
    bool isMobile,
    Map<String, String> shopNameMap,
  ) {
    final duration = AppMotionTokens.time(
      context,
      const Duration(milliseconds: 350),
    );
    Navigator.of(context).push(
      DetailsPageRoute(
        duration: duration,
        barrierLabel: MaterialLocalizations.of(context)
            .modalBarrierDismissLabel,
        pageBuilder: (ctx, animation, _) {
          final dark = Theme.of(ctx).brightness == Brightness.dark;
          void close() => Navigator.of(ctx).pop();
          if (isMobile) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: SlideTransition(
                position: animation
                    .drive(CurveTween(curve: AppMotionTokens.curve))
                    .drive(Tween(begin: const Offset(0, 1), end: Offset.zero)),
                child: BottomSheet(
                  onClosing: () {
                    if (ModalRoute.of(ctx)?.isCurrent == true) close();
                  },
                  enableDrag: true,
                  animationController:
                      (ModalRoute.of(ctx) as DetailsPageRoute).dragController,
                  builder: (ctx) => SingleChildScrollView(
                    child: _mobileDetails(ctx, product, shopNameMap),
                  ),
                ),
              ),
            );
          }
          return Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 420,
              child: AnimatedDetailsPanel(
                animation: animation,
                child: _buildDetailsSidePanel(
                  product: product,
                  shopNameMap: shopNameMap,
                  cardBg: dark ? const Color(0xFF191B21) : Colors.white,
                  neutralSurface: dark
                      ? const Color(0xFF13151A)
                      : const Color(0xFFF8FAFC),
                  borderColor: dark
                      ? const Color(0xFF2B2E37)
                      : const Color(0xFFE5E7EB),
                  textPrimary: dark
                      ? const Color(0xFFF9FAFB)
                      : const Color(0xFF111827),
                  textSecondary: dark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                  primaryGreen: dark
                      ? const Color(0xFF52B788)
                      : const Color(0xFF1E5A44),
                  isDark: dark,
                  onClose: close,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static String _inferCategory(String name) {
    final clean = name.toLowerCase();
    if (clean.contains('water') ||
        clean.contains('coca') ||
        clean.contains('cola') ||
        clean.contains('sting') ||
        clean.contains('drink') ||
        clean.contains('bull') ||
        clean.contains('ទឹក') ||
        clean.contains('កូកា') ||
        clean.contains('ស្តីង')) {
      return 'Beverages';
    }
    if (clean.contains('noodle') ||
        clean.contains('mama') ||
        clean.contains('cookie') ||
        clean.contains('oreo') ||
        clean.contains('snack') ||
        clean.contains('មី') ||
        clean.contains('អូរីអូ')) {
      return 'Food & Snacks';
    }
    if (clean.contains('soap') ||
        clean.contains('toothpaste') ||
        clean.contains('colgate') ||
        clean.contains('lifebuoy') ||
        clean.contains('សាប៊ូ') ||
        clean.contains('ថ្នាំដុសធ្មេញ')) {
      return 'Personal Care';
    }
    return 'General';
  }

  @override
  Widget build(BuildContext context) {
    final shops =
        ref.watch(managerShopsProvider).value ?? const <ShopSummary>[];
    final productsAsync = ref.watch(managerProductsProvider(null));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final shopNameMap = {for (final s in shops) s.id: s.name};

    // Design Tokens matching target Sage Green SaaS design specification
    final primaryGreen = isDark
        ? const Color(0xFF52B788)
        : const Color(0xFF1E5A44);
    final softGreenBg = isDark
        ? const Color(0xFF1E382B)
        : const Color(0xFFEAF5EE);
    final pageBg = isDark ? const Color(0xFF101114) : const Color(0xFFF8F9FA);
    final cardBg = isDark ? const Color(0xFF191B21) : Colors.white;
    final neutralSurface = isDark
        ? const Color(0xFF13151A)
        : const Color(0xFFF8FAFC);
    final borderColor = isDark
        ? const Color(0xFF2B2E37)
        : const Color(0xFFE5E7EB);
    final textPrimary = isDark
        ? const Color(0xFFF9FAFB)
        : const Color(0xFF111827);
    final textSecondary = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 768;

            return Stack(
              children: [
                MotionLayout(
                  revision: (
                    _isGridView,
                    _searchQuery,
                    _selectedShopId,
                    _selectedCategory,
                    _selectedSort,
                  ),
                  child: SingleChildScrollView(
                    key: const PageStorageKey('catalog-scroll'),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 14.0 : 24.0,
                      vertical: isMobile ? 12.0 : 20.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Breadcrumbs & Page Header
                        _buildPageHeader(
                          context: context,
                          isDark: isDark,
                          isMobile: isMobile,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          primaryGreen: primaryGreen,
                          onRefresh: () =>
                              ref.invalidate(managerProductsProvider(null)),
                        ),
                        const SizedBox(height: 18),

                        // 2. Main Content (Products async)
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
                            // Dynamic Category set
                            final categories = <String>{'All'};
                            for (final p in products) {
                              final cat = p.categoryName.isNotEmpty
                                  ? p.categoryName
                                  : _inferCategory(p.name);
                              categories.add(cat);
                            }

                            // Compute KPI metrics
                            int totalValuation = 0;
                            final uniqueShops = <String>{};
                            for (final p in products) {
                              totalValuation += p.salePrice * p.stockQty;
                              if (p.shopId.isNotEmpty) {
                                uniqueShops.add(p.shopId);
                              }
                            }

                            // Filter products
                            var filtered = products.where((p) {
                              final q = _searchQuery.trim().toLowerCase();
                              final matchesSearch =
                                  q.isEmpty ||
                                  p.name.toLowerCase().contains(q) ||
                                  p.barcode.toLowerCase().contains(q) ||
                                  p.sku.toLowerCase().contains(q) ||
                                  p.categoryName.toLowerCase().contains(q);

                              final matchesShop =
                                  _selectedShopId == 'All' ||
                                  p.shopId == _selectedShopId;

                              final cat = p.categoryName.isNotEmpty
                                  ? p.categoryName
                                  : _inferCategory(p.name);
                              final matchesCategory =
                                  _selectedCategory == 'All' ||
                                  cat == _selectedCategory;

                              return matchesSearch &&
                                  matchesShop &&
                                  matchesCategory;
                            }).toList();

                            // Sort products
                            switch (_selectedSort) {
                              case 'Price: Low-High':
                                filtered.sort(
                                  (a, b) => a.salePrice.compareTo(b.salePrice),
                                );
                                break;
                              case 'Price: High-Low':
                                filtered.sort(
                                  (a, b) => b.salePrice.compareTo(a.salePrice),
                                );
                                break;
                              case 'Stock: High-Low':
                                filtered.sort(
                                  (a, b) => b.stockQty.compareTo(a.stockQty),
                                );
                                break;
                              case 'Name (A-Z)':
                              default:
                                filtered.sort(
                                  (a, b) => a.name.toLowerCase().compareTo(
                                    b.name.toLowerCase(),
                                  ),
                                );
                                break;
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 2.1 COMPACT OVERVIEW METRICS STRIP
                                _buildMetricsStrip(
                                  productsCount: products.length,
                                  totalValuation: totalValuation,
                                  activeShopsCount: uniqueShops.isEmpty
                                      ? 1
                                      : uniqueShops.length,
                                  categoriesCount: categories.length > 1
                                      ? categories.length - 1
                                      : 1,
                                  cardBg: cardBg,
                                  borderColor: borderColor,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  primaryGreen: primaryGreen,
                                  softGreenBg: softGreenBg,
                                  isCompact: constraints.maxWidth < 650,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 18),

                                // 2.2 UNIFIED SEARCH, FILTERS & CATEGORY NAVIGATION
                                _buildToolbarAndCategories(
                                  shops: shops,
                                  categories: categories.toList(),
                                  isMobile: isMobile,
                                  cardBg: cardBg,
                                  borderColor: borderColor,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  primaryGreen: primaryGreen,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 18),

                                // 2.3 PRODUCT PRESENTATION (TABLE OR GRID)
                                filtered.isEmpty
                                    ? Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(48),
                                        decoration: BoxDecoration(
                                          color: cardBg,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: borderColor,
                                          ),
                                        ),
                                        child: Center(
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.inventory_2_outlined,
                                                size: 48,
                                                color: textSecondary.withValues(
                                                  alpha: 0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'No products found matching filters',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Try adjusting your search or category filter',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : _isGridView
                                    ? _buildProductGrid(
                                        items: filtered,
                                        shopNameMap: shopNameMap,
                                        cardBg: cardBg,
                                        neutralSurface: neutralSurface,
                                        borderColor: borderColor,
                                        textPrimary: textPrimary,
                                        textSecondary: textSecondary,
                                        primaryGreen: primaryGreen,
                                        softGreenBg: softGreenBg,
                                        isDark: isDark,
                                        isMobile: isMobile,
                                        onSelect: (p) => _openDetails(
                                          p,
                                          isMobile,
                                          shopNameMap,
                                        ),
                                      )
                                    : _buildProductTable(
                                        items: filtered,
                                        shopNameMap: shopNameMap,
                                        cardBg: cardBg,
                                        neutralSurface: neutralSurface,
                                        borderColor: borderColor,
                                        textPrimary: textPrimary,
                                        textSecondary: textSecondary,
                                        primaryGreen: primaryGreen,
                                        softGreenBg: softGreenBg,
                                        isDark: isDark,
                                        isMobile: isMobile,
                                        onSelect: (p) => _openDetails(
                                          p,
                                          isMobile,
                                          shopNameMap,
                                        ),
                                      ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. BREADCRUMBS & PAGE HEADER
  // ===========================================================================
  Widget _buildPageHeader({
    required BuildContext context,
    required bool isDark,
    required bool isMobile,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryGreen,
    required VoidCallback onRefresh,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumbs: Home / Operations / Global Products
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.home_outlined, size: 14, color: textSecondary),
            const SizedBox(width: 6),
            Text(
              '/',
              style: TextStyle(
                fontSize: 12,
                color: textSecondary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Operations',
              style: TextStyle(fontSize: 11.5, color: textSecondary),
            ),
            const SizedBox(width: 6),
            Text(
              '/',
              style: TextStyle(
                fontSize: 12,
                color: textSecondary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Global Products',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: primaryGreen,
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
                    'Global Products',
                    style: TextStyle(
                      fontSize: isMobile ? 22 : 25,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Manage products across all shops.',
                    style: TextStyle(fontSize: 12.5, color: textSecondary),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: onRefresh,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF191B21) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2B2E37)
                        : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 14, color: textPrimary),
                    const SizedBox(width: 6),
                    Text(
                      'Refresh',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // 3. COMPACT OVERVIEW METRICS STRIP (4 CARDS MATCHING REFERENCE)
  // ===========================================================================
  Widget _buildMetricsStrip({
    required int productsCount,
    required int totalValuation,
    required int activeShopsCount,
    required int categoriesCount,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryGreen,
    required Color softGreenBg,
    required bool isCompact,
    required bool isDark,
  }) {
    final cards = [
      _buildMetricCard(
        label: 'Catalog Items',
        value: '$productsCount',
        icon: Icons.inventory_2_outlined,
        cardBg: cardBg,
        borderColor: borderColor,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        primaryGreen: primaryGreen,
        softGreenBg: softGreenBg,
      ),
      _buildMetricCard(
        label: 'Total Valuation',
        value: managerMoney(totalValuation),
        icon: Icons.account_balance_wallet_outlined,
        cardBg: cardBg,
        borderColor: borderColor,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        primaryGreen: primaryGreen,
        softGreenBg: softGreenBg,
      ),
      _buildMetricCard(
        label: 'Active Shop',
        value: '$activeShopsCount',
        icon: Icons.storefront_outlined,
        cardBg: cardBg,
        borderColor: borderColor,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        primaryGreen: primaryGreen,
        softGreenBg: softGreenBg,
      ),
      _buildMetricCard(
        label: 'Categories',
        value: '$categoriesCount',
        icon: Icons.layers_outlined,
        cardBg: cardBg,
        borderColor: borderColor,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        primaryGreen: primaryGreen,
        softGreenBg: softGreenBg,
      ),
    ];

    if (isCompact) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 10),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 10),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: cards[i]),
        ],
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryGreen,
    required Color softGreenBg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: softGreenBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(child: Icon(icon, color: primaryGreen, size: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
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
    );
  }

  // ===========================================================================
  // 4. UNIFIED SEARCH, FILTERS & CATEGORY NAVIGATION
  // ===========================================================================
  Widget _buildToolbarAndCategories({
    required List<ShopSummary> shops,
    required List<String> categories,
    required bool isMobile,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryGreen,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: Search + Shop Filter + Category Filter + Sort Filter + View Toggle
        isMobile
            ? Column(
                children: [
                  _buildSearchInputField(
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildShopDropdown(
                          shops: shops,
                          isDark: isDark,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSortDropdown(
                          isDark: isDark,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildViewModeToggle(primaryGreen, isDark, borderColor),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  // Search
                  Expanded(
                    flex: 4,
                    child: _buildSearchInputField(
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Shop Dropdown
                  Expanded(
                    flex: 2,
                    child: _buildShopDropdown(
                      shops: shops,
                      isDark: isDark,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Category Dropdown
                  Expanded(
                    flex: 2,
                    child: _buildCategoryDropdown(
                      categories: categories,
                      isDark: isDark,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Sort Dropdown
                  Expanded(
                    flex: 2,
                    child: _buildSortDropdown(
                      isDark: isDark,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Grid / Table View Toggle
                  _buildViewModeToggle(primaryGreen, isDark, borderColor),
                ],
              ),
        const SizedBox(height: 12),

        // Row 2: Category Navigation Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: AnimatedFilterBar(
            revision: _selectedCategory,
            child: Row(
              children: categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedCategory = cat),
                    borderRadius: BorderRadius.circular(20),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF191B21) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),

                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isSelected)
                            Positioned.fill(
                              child: AnimatedNavigationIndicator(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryGreen
                                      : (isDark
                                            ? const Color(0xFF191B21)
                                            : Colors.white),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? primaryGreen
                                        : borderColor,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: primaryGreen.withValues(
                                              alpha: 0.25,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6.5,
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchInputField({
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191B21) : Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: isDark ? const Color(0xFF2B2E37) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 16, color: textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              style: TextStyle(fontSize: 12, color: textPrimary),
              onChanged: (q) => setState(() => _searchQuery = q),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search by product name, SKU or barcode...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: textSecondary.withValues(alpha: 0.75),
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

  Widget _buildShopDropdown({
    required List<ShopSummary> shops,
    required bool isDark,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191B21) : Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedShopId,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 17,
            color: textSecondary,
          ),
          dropdownColor: isDark ? const Color(0xFF191B21) : Colors.white,
          items: [
            DropdownMenuItem(
              value: 'All',
              child: Row(
                children: [
                  Icon(
                    Icons.storefront_outlined,
                    size: 14,
                    color: textSecondary,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'All shops',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            ...shops.map(
              (s) => DropdownMenuItem(
                value: s.id,
                child: Row(
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      size: 14,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _selectedShopId = val);
          },
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown({
    required List<String> categories,
    required bool isDark,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191B21) : Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 17,
            color: textSecondary,
          ),
          dropdownColor: isDark ? const Color(0xFF191B21) : Colors.white,
          items: categories.map((cat) {
            final label = cat == 'All' ? 'All categories' : cat;
            return DropdownMenuItem(
              value: cat,
              child: Row(
                children: [
                  Icon(Icons.sell_outlined, size: 14, color: textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedCategory = val);
          },
        ),
      ),
    );
  }

  Widget _buildSortDropdown({
    required bool isDark,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191B21) : Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSort,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 17,
            color: textSecondary,
          ),
          dropdownColor: isDark ? const Color(0xFF191B21) : Colors.white,
          items: [
            DropdownMenuItem(
              value: 'Name (A-Z)',
              child: Row(
                children: [
                  Icon(
                    Icons.sort_by_alpha_rounded,
                    size: 14,
                    color: textSecondary,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Name (A-Z)',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'Price: Low-High',
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_upward_rounded,
                    size: 14,
                    color: textSecondary,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Price: Low → High',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'Price: High-Low',
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_downward_rounded,
                    size: 14,
                    color: textSecondary,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Price: High → Low',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'Stock: High-Low',
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 14,
                    color: textSecondary,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Highest Stock',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _selectedSort = val);
          },
        ),
      ),
    );
  }

  Widget _buildViewModeToggle(
    Color primaryGreen,
    bool isDark,
    Color borderColor,
  ) {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191B21) : Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: 'Grid view',
            child: InkWell(
              onTap: () => setState(() => _isGridView = true),
              borderRadius: BorderRadius.circular(6),
              child: AnimatedContainer(
                duration: AppMotionTokens.time(
                  context,
                  const Duration(milliseconds: 150),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: _isGridView ? primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.grid_view_rounded,
                  size: 16,
                  color: _isGridView
                      ? Colors.white
                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Tooltip(
            message: 'List view',
            child: InkWell(
              onTap: () => setState(() => _isGridView = false),
              borderRadius: BorderRadius.circular(6),
              child: AnimatedContainer(
                duration: AppMotionTokens.time(
                  context,
                  const Duration(milliseconds: 150),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: !_isGridView ? primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.format_list_bulleted_rounded,
                  size: 16,
                  color: !_isGridView
                      ? Colors.white
                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. FULL-WIDTH PRODUCT TABLE (PRIMARY SPECIFICATION MATCHING MOCKUP)
  // ===========================================================================
  Widget _buildProductTable({
    required List<PlatformProduct> items,
    required Map<String, String> shopNameMap,
    required Color cardBg,
    required Color neutralSurface,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryGreen,
    required Color softGreenBg,
    required bool isDark,
    required bool isMobile,
    required ValueChanged<PlatformProduct> onSelect,
  }) {
    if (isMobile) {
      // Mobile Responsive List Cards to prevent horizontal squish
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final p = items[index];
          final shopName = p.shopName.isNotEmpty
              ? p.shopName
              : (shopNameMap[p.shopId] ??
                    (p.shopId.isEmpty ? 'default-shop' : p.shopId));
          final category = p.categoryName.isNotEmpty
              ? p.categoryName
              : _inferCategory(p.name);
          final isLow =
              p.lowStockThreshold > 0 &&
              p.stockQty <= p.lowStockThreshold &&
              p.stockQty > 0;
          final isOut = p.stockQty <= 0;

          return MotionAnchor(
            key: ValueKey((p.shopId, p.id)),
            id: (p.shopId, p.id),
            child: Material(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onSelect(p),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 48,
                          height: 48,
                          color: neutralSurface,
                          child: SharedElementTransition(
                            tag: (p.shopId, p.id),
                            child: ProductThumbnail(
                              imageUrl: p.imageUrl,
                              productId: p.id,
                              productName: p.name,
                              barcode: p.barcode,
                              width: 48,
                              height: 48,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
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
                              'Shop: $shopName • ${p.sku}',
                              style: TextStyle(
                                fontSize: 11,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _buildCategoryBadge(category, isDark),
                                const SizedBox(width: 6),
                                _buildStockBadge(
                                  p.stockQty,
                                  isLow,
                                  isOut,
                                  isDark,
                                  primaryGreen,
                                  softGreenBg,
                                ),
                                const Spacer(),
                                Text(
                                  managerMoney(p.salePrice),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    // Full-Width Desktop / Tablet Table
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF13151A) : const Color(0xFFFAFAFA),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(13),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'PRODUCT',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'CATEGORY',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'SHOP',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'SKU / BARCODE',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'STOCK',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'PRICE',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 85), // Spacer for Action Details button
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),

          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: borderColor.withValues(alpha: 0.6)),
            itemBuilder: (context, index) {
              final p = items[index];
              final shopName = p.shopName.isNotEmpty
                  ? p.shopName
                  : (shopNameMap[p.shopId] ??
                        (p.shopId.isEmpty ? 'default-shop' : p.shopId));
              final category = p.categoryName.isNotEmpty
                  ? p.categoryName
                  : _inferCategory(p.name);
              final isLow =
                  p.lowStockThreshold > 0 &&
                  p.stockQty <= p.lowStockThreshold &&
                  p.stockQty > 0;
              final isOut = p.stockQty <= 0;

              return MotionAnchor(
                key: ValueKey((p.shopId, p.id)),
                id: (p.shopId, p.id),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onSelect(p),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          // 1. PRODUCT
                          Expanded(
                            flex: 4,
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    color: neutralSurface,
                                    child: SharedElementTransition(
                                      tag: (p.shopId, p.id),
                                      child: ProductThumbnail(
                                        imageUrl: p.imageUrl,
                                        productId: p.id,
                                        productName: p.name,
                                        barcode: p.barcode,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    p.name,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 2. CATEGORY
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _buildCategoryBadge(category, isDark),
                            ),
                          ),

                          // 3. SHOP
                          Expanded(
                            flex: 2,
                            child: Text(
                              shopName,
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // 4. SKU / BARCODE
                          Expanded(
                            flex: 3,
                            child: Text(
                              '${p.sku} / ${p.barcode}',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // 5. STOCK
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _buildStockBadge(
                                p.stockQty,
                                isLow,
                                isOut,
                                isDark,
                                primaryGreen,
                                softGreenBg,
                              ),
                            ),
                          ),

                          // 6. PRICE
                          Expanded(
                            flex: 2,
                            child: Text(
                              managerMoney(p.salePrice),
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ),

                          // 7. ACTION BUTTON
                          SizedBox(
                            width: 85,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                side: BorderSide(color: borderColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => onSelect(p),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Details',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 14,
                                    color: textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Divider(height: 1, color: borderColor),

          // Table Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Text(
              '${items.length} products',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(String category, bool isDark) {
    Color bg;
    Color fg;

    switch (category) {
      case 'Beverages':
        bg = isDark ? const Color(0xFF1E382B) : const Color(0xFFEAF5EE);
        fg = isDark ? const Color(0xFF52B788) : const Color(0xFF1E5A44);
        break;
      case 'Food & Snacks':
        bg = isDark ? const Color(0xFF382914) : const Color(0xFFFEF3C7);
        fg = isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
        break;
      case 'Personal Care':
        bg = isDark ? const Color(0xFF162B44) : const Color(0xFFE0F2FE);
        fg = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1);
        break;
      default:
        bg = isDark ? const Color(0xFF222630) : const Color(0xFFF1F5F9);
        fg = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  Widget _buildStockBadge(
    int stockQty,
    bool isLow,
    bool isOut,
    bool isDark,
    Color primaryGreen,
    Color softGreenBg,
  ) {
    Color bg;
    Color fg;
    Color dot;
    String label;

    if (isOut) {
      bg = isDark ? const Color(0xFF3D1616) : const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
      dot = const Color(0xFFEF4444);
      label = '0 in stock';
    } else if (isLow) {
      bg = isDark ? const Color(0xFF382914) : const Color(0xFFFEF3C7);
      fg = isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
      dot = const Color(0xFFF59E0B);
      label = '$stockQty in stock';
    } else {
      bg = softGreenBg;
      fg = primaryGreen;
      dot = const Color(0xFF22C55E);
      label = '$stockQty in stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. RESPONSIVE GRID VIEW (CLEAN FIKRI STORE / VNDLY STYLE)
  // ===========================================================================
  Widget _buildProductGrid({
    required List<PlatformProduct> items,
    required Map<String, String> shopNameMap,
    required Color cardBg,
    required Color neutralSurface,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryGreen,
    required Color softGreenBg,
    required bool isDark,
    required bool isMobile,
    required ValueChanged<PlatformProduct> onSelect,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 3;
        if (constraints.maxWidth < 620) {
          crossAxisCount = 1;
        } else if (constraints.maxWidth < 1000) {
          crossAxisCount = 2;
        } else if (constraints.maxWidth < 1400) {
          crossAxisCount = 3;
        } else {
          crossAxisCount = 4;
        }

        final double itemWidth =
            (constraints.maxWidth - (crossAxisCount - 1) * 14) / crossAxisCount;
        final double targetHeight = crossAxisCount == 1 ? 180.0 : 188.0;
        final double childAspectRatio = itemWidth / targetHeight;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final p = items[index];
            final shopName = p.shopName.isNotEmpty
                ? p.shopName
                : (shopNameMap[p.shopId] ??
                      (p.shopId.isEmpty ? 'default-shop' : p.shopId));
            final category = p.categoryName.isNotEmpty
                ? p.categoryName
                : _inferCategory(p.name);
            final isLow =
                p.lowStockThreshold > 0 &&
                p.stockQty <= p.lowStockThreshold &&
                p.stockQty > 0;
            final isOut = p.stockQty <= 0;

            final stockRatio = p.stockQty > 0
                ? (p.stockQty / 100).clamp(0.08, 1.0)
                : 0.0;
            final stockColor = isOut
                ? const Color(0xFFEF4444)
                : (isLow ? const Color(0xFFF59E0B) : const Color(0xFF22C55E));

            return MotionAnchor(
              key: ValueKey((p.shopId, p.id)),
              id: (p.shopId, p.id),
              child: Material(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onSelect(p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Top Row: Thumbnail + Product Name + SKU + Status Badge + 3-dots
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 40,
                                height: 40,
                                color: neutralSurface,
                                child: SharedElementTransition(
                                  tag: (p.shopId, p.id),
                                  child: ProductThumbnail(
                                    imageUrl: p.imageUrl,
                                    productId: p.id,
                                    productName: p.name,
                                    barcode: p.barcode,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        'SKU ${p.sku}',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: textSecondary.withValues(
                                            alpha: 0.4,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      _buildStockBadge(
                                        p.stockQty,
                                        isLow,
                                        isOut,
                                        isDark,
                                        primaryGreen,
                                        softGreenBg,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.more_horiz_rounded,
                              size: 18,
                              color: textSecondary.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // 2. Metadata Chips: Category + Shop + Barcode
                        Row(
                          children: [
                            _buildCategoryBadge(category, isDark),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E222A)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                shopName,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                p.barcode,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // 3. Pricing Row: Retail & Cost/Valuation
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Retail',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  managerMoney(p.salePrice),
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Wholesale',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  managerMoney(
                                    p.costPrice > 0
                                        ? p.costPrice
                                        : (p.salePrice * 0.8).round(),
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),

                        // 4. Bottom Stock Level Progress & Action
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Level Indicator Line
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: Container(
                                height: 3,
                                width: double.infinity,
                                color: isDark
                                    ? const Color(0xFF2B2E37)
                                    : const Color(0xFFE5E7EB),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: stockRatio,
                                  child: Container(color: stockColor),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Status text + Chevron Action Button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isOut
                                      ? 'Out of Stock'
                                      : '${p.stockQty} stock • ${isLow ? 'Low' : 'High'}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isOut
                                        ? const Color(0xFFDC2626)
                                        : (isLow
                                              ? const Color(0xFFD97706)
                                              : textSecondary),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF222630)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: borderColor.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons
                                            .keyboard_double_arrow_right_rounded,
                                        size: 13,
                                        color: textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // 7. ANIMATED PRODUCT DETAILS SIDE PANEL (DESKTOP)
  // ===========================================================================
  Widget _buildDetailsSidePanel({
    required PlatformProduct product,
    required Map<String, String> shopNameMap,
    required Color cardBg,
    required Color neutralSurface,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryGreen,
    required bool isDark,
    required VoidCallback onClose,
  }) {
    final shopName = product.shopName.isNotEmpty
        ? product.shopName
        : (shopNameMap[product.shopId] ??
              (product.shopId.isEmpty ? 'default-shop' : product.shopId));

    final profitMargin = product.salePrice - product.costPrice;
    final marginPercent = product.costPrice > 0
        ? ((profitMargin / product.costPrice) * 100).toStringAsFixed(1)
        : null;

    return Material(
      color: cardBg,
      elevation: 16,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          border: Border(left: BorderSide(color: borderColor, width: 1)),
        ),
        child: Column(
          children: [
            // Panel Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: primaryGreen,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Product Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: onClose,
                    icon: Icon(
                      Icons.close_rounded,
                      color: textSecondary,
                      size: 18,
                    ),
                    label: Text(
                      'Close',
                      style: TextStyle(fontSize: 13, color: textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: borderColor),

            // Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        height: 180,
                        color: neutralSurface,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: SharedElementTransition(
                            tag: (product.shopId, product.id),
                            child: ProductThumbnail(
                              imageUrl: product.imageUrl,
                              productId: product.id,
                              productName: product.name,
                              barcode: product.barcode,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.contain,
                              borderRadius: 0,
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Title & Shop
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Managed by $shopName',
                      style: TextStyle(fontSize: 12.5, color: textSecondary),
                    ),
                    const SizedBox(height: 14),

                    // Price Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: neutralSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sale Price',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                managerMoney(product.salePrice),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                          if (product.costPrice > 0)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Cost Price',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  managerMoney(product.costPrice),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Specifications
                    Text(
                      'Inventory Specifications',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (marginPercent != null)
                      _buildSpecRow(
                        'Profit Margin',
                        '+$marginPercent%',
                        const Color(0xFF10B981),
                        textSecondary,
                      ),
                    _buildSpecRow(
                      'Stock Level',
                      '${product.stockQty} ${product.unit}',
                      textPrimary,
                      textSecondary,
                    ),
                    _buildSpecRow(
                      'Low Stock Alert',
                      '≤ ${product.lowStockThreshold} ${product.unit}',
                      textPrimary,
                      textSecondary,
                    ),
                    if (product.barcode.isNotEmpty)
                      _buildSpecRow(
                        'Barcode',
                        product.barcode,
                        textPrimary,
                        textSecondary,
                      ),
                    if (product.sku.isNotEmpty)
                      _buildSpecRow(
                        'SKU',
                        product.sku,
                        textPrimary,
                        textSecondary,
                      ),
                    _buildSpecRow(
                      'Product ID',
                      product.id,
                      textPrimary,
                      textSecondary,
                    ),
                    _buildSpecRow(
                      'Shop ID',
                      product.shopId,
                      textPrimary,
                      textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mobile Bottom Sheet
  Widget _mobileDetails(
    BuildContext ctx,
    PlatformProduct p,
    Map<String, String> shopNameMap,
  ) {
    final shopName = p.shopName.isNotEmpty
        ? p.shopName
        : (shopNameMap[p.shopId] ??
              (p.shopId.isEmpty ? 'default-shop' : p.shopId));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: SharedElementTransition(
                tag: (p.shopId, p.id),
                child: ProductThumbnail(
                  imageUrl: p.imageUrl,
                  productId: p.id,
                  productName: p.name,
                  barcode: p.barcode,
                  width: 140,
                  height: 140,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              p.name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Shop: $shopName • Stock: ${p.stockQty}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Text(
              managerMoney(p.salePrice),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(
    String label,
    String value,
    Color textPrimary,
    Color textSecondary, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
              color: isHighlight ? const Color(0xFF10B981) : textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
