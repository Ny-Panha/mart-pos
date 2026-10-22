import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/inventory/providers/inventory_provider.dart';
import '../theme/app_colors.dart';
import '../theme/theme_mode_provider.dart';
import '../utils/responsive.dart';
import 'ios_theme_toggle.dart';
import 'mesh_background.dart';
export 'ios_theme_toggle.dart';
export 'mesh_background.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  List<_NavItem> _items(bool manager, bool admin) {
    if (manager) {
      return const [
        _NavItem(
          path: '/manager',
          label: 'Dashboard',
          khmerLabel: 'ទិដ្ឋភាពទូទៅ',
          icon: Icons.dashboard_rounded,
          category: 'ទិដ្ឋភាពទូទៅ (OVERVIEW)',
        ),
        _NavItem(
          path: '/manager/shops',
          label: 'Shops',
          khmerLabel: 'បញ្ជីហាងទាំងអស់',
          icon: Icons.storefront_rounded,
          category: 'ទិដ្ឋភាពទូទៅ (OVERVIEW)',
        ),
        _NavItem(
          path: '/manager/admins',
          label: 'Admin Owners',
          khmerLabel: 'ម្ចាស់ហាង',
          icon: Icons.manage_accounts_rounded,
          category: 'ទិដ្ឋភាពទូទៅ (OVERVIEW)',
        ),
        _NavItem(
          path: '/manager/locations',
          label: 'Locations',
          khmerLabel: 'ទីតាំងសាខា',
          icon: Icons.location_on_rounded,
          category: 'ប្រតិបត្តិការ (OPERATIONS)',
        ),
        _NavItem(
          path: '/manager/subscriptions',
          label: 'Subscriptions',
          khmerLabel: 'កញ្ចប់សេវា & បង់ប្រាក់',
          icon: Icons.card_membership_rounded,
          category: 'ប្រតិបត្តិការ (OPERATIONS)',
        ),
        _NavItem(
          path: '/manager/stock',
          label: 'Stock Overview',
          khmerLabel: 'ស្តុកសរុបប្រព័ន្ធ',
          icon: Icons.inventory_2_rounded,
          category: 'ប្រតិបត្តិការ (OPERATIONS)',
        ),
        _NavItem(
          path: '/manager/products',
          label: 'Global Products',
          khmerLabel: 'កាតាឡុកទំនិញ',
          icon: Icons.category_rounded,
          category: 'ប្រតិបត្តិការ (OPERATIONS)',
        ),
        _NavItem(
          path: '/manager/reports',
          label: 'System Reports',
          khmerLabel: 'របាយការណ៍រួម',
          icon: Icons.analytics_rounded,
          category: 'ប្រព័ន្ធ (SYSTEM)',
        ),
        _NavItem(
          path: '/manager/system',
          label: 'Settings',
          khmerLabel: 'ការកំណត់ប្រព័ន្ធ',
          icon: Icons.settings_rounded,
          category: 'ប្រព័ន្ធ (SYSTEM)',
        ),
      ];
    }
    if (admin) {
      return const [
        _NavItem(
          path: '/admin',
          label: 'Dashboard',
          khmerLabel: 'ផ្ទាំងគ្រប់គ្រង',
          icon: Icons.dashboard_rounded,
          category: 'ចម្បង (CORE)',
        ),
        _NavItem(
          path: '/pos',
          label: 'POS Checkout',
          khmerLabel: 'បញ្ជរគិតលុយ',
          icon: Icons.point_of_sale_rounded,
          category: 'ចម្បង (CORE)',
        ),
        _NavItem(
          path: '/admin/products',
          label: 'Products & Category',
          khmerLabel: 'ទំនិញ & ប្រភេទ',
          icon: Icons.inventory_2_rounded,
          category: 'ទំនិញ & ស្តុក (INVENTORY)',
        ),
        _NavItem(
          path: '/admin/inventory',
          label: 'Stock Movements',
          khmerLabel: 'ចលនាស្តុក',
          icon: Icons.swap_vert_circle_rounded,
          category: 'ទំនិញ & ស្តុក (INVENTORY)',
        ),
        _NavItem(
          path: '/admin/purchases',
          label: 'Purchases',
          khmerLabel: 'បញ្ជាទិញចូល',
          icon: Icons.shopping_bag_rounded,
          category: 'ទំនិញ & ស្តុក (INVENTORY)',
        ),
        _NavItem(
          path: '/admin/suppliers',
          label: 'Suppliers',
          khmerLabel: 'អ្នកផ្គត់ផ្គង់',
          icon: Icons.local_shipping_rounded,
          category: 'ទំនិញ & ស្តុក (INVENTORY)',
        ),
        _NavItem(
          path: '/admin/reports',
          label: 'Reports & Analytics',
          khmerLabel: 'របាយការណ៍លក់',
          icon: Icons.analytics_rounded,
          category: 'ការលក់ & អតិថិជន (SALES)',
        ),
        _NavItem(
          path: '/admin/customers',
          label: 'Customers',
          khmerLabel: 'អតិថិជន',
          icon: Icons.people_alt_rounded,
          category: 'ការលក់ & អតិថិជន (SALES)',
        ),
        _NavItem(
          path: '/admin/users',
          label: 'Staff & Shifts',
          khmerLabel: 'បុគ្គលិក & វេនលក់',
          icon: Icons.badge_rounded,
          category: 'ការគ្រប់គ្រង (MANAGEMENT)',
        ),
        _NavItem(
          path: '/admin/attendance',
          label: 'Attendance',
          khmerLabel: 'វត្តមានបុគ្គលិក',
          icon: Icons.schedule_rounded,
          category: 'ការគ្រប់គ្រង (MANAGEMENT)',
        ),
        _NavItem(
          path: '/admin/notifications',
          label: 'Notifications',
          khmerLabel: 'ការជូនដំណឹង',
          icon: Icons.notifications_active_rounded,
          category: 'ការគ្រប់គ្រង (MANAGEMENT)',
        ),
        _NavItem(
          path: '/admin/audit-log',
          label: 'Audit Log',
          khmerLabel: 'កំណត់ហេតុតាមដាន',
          icon: Icons.shield_rounded,
          category: 'ការគ្រប់គ្រង (MANAGEMENT)',
        ),
        _NavItem(
          path: '/admin/settings',
          label: 'Shop Settings',
          khmerLabel: 'ការកំណត់ហាង',
          icon: Icons.settings_rounded,
          category: 'ការគ្រប់គ្រង (MANAGEMENT)',
        ),
      ];
    }
    return const [
      _NavItem(
        path: '/pos',
        label: 'POS',
        khmerLabel: 'បញ្ជរគិតលុយ',
        icon: Icons.point_of_sale_rounded,
        category: 'កិច្ចការលក់ (CASHIER)',
      ),
      _NavItem(
        path: '/cashier/history',
        label: 'Sales History',
        khmerLabel: 'ប្រវត្តិវិក្កយបត្រ',
        icon: Icons.receipt_long_rounded,
        category: 'កិច្ចការលក់ (CASHIER)',
      ),
      _NavItem(
        path: '/cashier/stock',
        label: 'Stock Check',
        khmerLabel: 'ពិនិត្យស្តុក',
        icon: Icons.inventory_2_rounded,
        category: 'កិច្ចការលក់ (CASHIER)',
      ),
      _NavItem(
        path: '/cashier/shift',
        label: 'My Shift',
        khmerLabel: 'វេនរបស់ខ្ញុំ',
        icon: Icons.lock_clock_rounded,
        category: 'កិច្ចការលក់ (CASHIER)',
      ),
    ];
  }

  int _findActiveIndex(List<_NavItem> items, String location) {
    final exact = items.indexWhere((item) => item.path == location);
    if (exact >= 0) return exact;
    int best = -1;
    int longest = 0;
    for (int i = 0; i < items.length; i++) {
      final p = items[i].path;
      if (p != '/' && location.startsWith('$p/') && p.length > longest) {
        best = i;
        longest = p.length;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    final user = authState.value;
    final manager = user?.isManager ?? false;
    final admin = user?.isAdmin ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allItems = _items(manager, admin);
    final location = GoRouterState.of(context).uri.path;
    final isDesktop = Responsive.isDesktop(context);

    // Desktop/Tablet Sidebar Layout
    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _DesktopSidebar(
              items: allItems,
              currentPath: location,
              user: user,
              manager: manager,
              admin: admin,
              isDark: isDark,
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: MeshBackground(child: child)),
          ],
        ),
      );
    }

    // Mobile Bottom Navigation Tabs (4 main items)
    final primaryTabs = admin
        ? [allItems[0], allItems[1], allItems[2]] // POS, Dashboard, Products
        : (manager ? [allItems[0], allItems[1], allItems[6]] : allItems.take(3).toList());

    final activeTabIndex = _findActiveIndex(primaryTabs, location);

    return Scaffold(
      body: MeshBackground(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: activeTabIndex >= 0 ? activeTabIndex : primaryTabs.length,
        onDestinationSelected: (index) {
          FocusManager.instance.primaryFocus?.unfocus();
          if (index < primaryTabs.length) {
            context.go(primaryTabs[index].path);
          } else {
            _showMobileMenu(context, ref, allItems, location, user);
          }
        },
        destinations: [
          for (final item in primaryTabs)
            NavigationDestination(
              icon: Icon(item.icon),
              label: item.label.split(' ').first,
            ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'All Menu',
          ),
        ],
      ),
    );
  }

  void _showMobileMenu(
    BuildContext context,
    WidgetRef ref,
    List<_NavItem> items,
    String currentPath,
    dynamic user,
  ) {
    // Group items by category
    final Map<String, List<_NavItem>> groups = {};
    for (final item in items) {
      groups.putIfAbsent(item.category, () => []).add(item);
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final themeMode = ref.watch(themeModeProvider);
            final isDark = themeMode == ThemeMode.dark;
            final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
            final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
            final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
            final textColor = isDark ? AppColors.darkText : AppColors.lightText;
            final mutedColor = isDark ? AppColors.darkMutedText : AppColors.lightMutedText;
            final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
            final liveUser = ref.watch(authProvider).value ?? user;

            return Material(
              color: surfaceColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              clipBehavior: Clip.antiAlias,
              child: DraggableScrollableSheet(
                initialChildSize: 0.85,
                maxChildSize: 0.95,
                minChildSize: 0.5,
                expand: false,
                builder: (_, scrollController) {
                  return SafeArea(
                    child: Column(
                      children: [
                        // Drag Handle
                        Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: borderColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        // Header with User Info
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.primary, AppColors.secondary],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    (liveUser?.name != null && liveUser!.name.isNotEmpty)
                                        ? liveUser.name[0]
                                        : ((liveUser?.email?.isNotEmpty ?? false)
                                            ? liveUser!.email![0].toUpperCase()
                                            : 'M'),
                                    style: GoogleFonts.notoSansKhmer(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
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
                                      (liveUser?.name != null && liveUser!.name.isNotEmpty)
                                          ? liveUser.name
                                          : (liveUser?.email ?? 'Mart User'),
                                      style: GoogleFonts.notoSansKhmer(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: textColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${liveUser?.normalizedRole ?? "Staff"} • Mart POS',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: mutedColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(sheetContext),
                                icon: Icon(Icons.close_rounded, color: textColor),
                              ),
                            ],
                          ),
                        ),

                        Divider(height: 16, color: borderColor),

                        // Categorized Menu Items
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            children: [
                              for (final entry in groups.entries) ...[
                                Padding(
                                  padding: const EdgeInsets.only(top: 14, bottom: 8, left: 4),
                                  child: Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                                for (final item in entry.value) ...[
                                  _buildMobileMenuItem(
                                    context: sheetContext,
                                    item: item,
                                    isActive: currentPath == item.path ||
                                        (item.path != '/' && currentPath.startsWith('${item.path}/')),
                                    isDark: isDark,
                                  ),
                                  const SizedBox(height: 6),
                                ],
                              ],

                              const SizedBox(height: 16),
                              Divider(color: borderColor),

                              // System Actions: iPhone-style Theme Toggle
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: borderColor,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                        size: 20,
                                        color: primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isDark ? 'Dark Mode' : 'Light Mode',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                          ),
                                          Text(
                                            isDark ? 'ផ្ទៃងងឹត (កំពុងបើក)' : 'ផ្ទៃភ្លឺ (កំពុងបិទ)',
                                            style: GoogleFonts.notoSansKhmer(
                                              fontSize: 11,
                                              color: mutedColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IosThemeToggle(
                                      value: isDark,
                                      onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.logout_rounded,
                                    size: 20,
                                    color: AppColors.danger,
                                  ),
                                ),
                                title: Text(
                                  'ចាកចេញពីគណនី (Log Out)',
                                  style: GoogleFonts.notoSansKhmer(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.danger,
                                  ),
                                ),
                                onTap: () async {
                                  Navigator.pop(sheetContext);
                                  await ref.read(authProvider.notifier).signOut();
                                  if (context.mounted) context.go('/login');
                                },
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMobileMenuItem({
    required BuildContext context,
    required _NavItem item,
    required bool isActive,
    required bool isDark,
  }) {
    final activeBg = isDark
        ? AppColors.darkPrimary.withValues(alpha: 0.16)
        : AppColors.primary.withValues(alpha: 0.10);
    final activeBorder = (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.35);

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        context.go(item.path);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? activeBg : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? activeBorder : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isActive
                        ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder))
                    .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item.icon,
                size: 20,
                color: isActive
                    ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                    : (isDark ? AppColors.darkText : AppColors.lightText),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                      fontSize: 13,
                      color: isActive
                          ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                          : (isDark ? AppColors.darkText : AppColors.lightText),
                    ),
                  ),
                  Text(
                    item.khmerLabel,
                    style: GoogleFonts.notoSansKhmer(
                      fontSize: 11,
                      color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
              ),
          ],
        ),
      ),
    );
  }
}

class SidebarCollapsedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final sidebarCollapsedProvider =
    NotifierProvider<SidebarCollapsedNotifier, bool>(SidebarCollapsedNotifier.new);

class CollapsedNavGroupsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggle(String group) {
    final next = Set<String>.from(state);
    if (next.contains(group)) {
      next.remove(group);
    } else {
      next.add(group);
    }
    state = next;
  }
}

final collapsedNavGroupsProvider =
    NotifierProvider<CollapsedNavGroupsNotifier, Set<String>>(
  CollapsedNavGroupsNotifier.new,
);

class _DesktopSidebar extends ConsumerWidget {
  final List<_NavItem> items;
  final String currentPath;
  final dynamic user;
  final bool manager;
  final bool admin;
  final bool isDark;

  const _DesktopSidebar({
    required this.items,
    required this.currentPath,
    this.user,
    this.manager = false,
    this.admin = false,
    required this.isDark,
  });

  bool _isItemActive(_NavItem item, String currentPath) {
    if (currentPath == item.path) return true;
    if (item.path == '/admin' ||
        item.path == '/manager' ||
        item.path == '/' ||
        item.path == '/pos') {
      return false;
    }
    return currentPath.startsWith('${item.path}/');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCollapsed = ref.watch(sidebarCollapsedProvider);
    final collapsedGroups = ref.watch(collapsedNavGroupsProvider);
    final lowStockCount = ref.watch(lowStockProductsProvider).length;

    // Group items by category
    final Map<String, List<_NavItem>> groups = {};
    for (final item in items) {
      groups.putIfAbsent(item.category, () => []).add(item);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOutCubic,
      width: isCollapsed ? 74 : 260,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1526) : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? const Color(0xFF1E2D4A) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Branding Header
          Padding(
            padding: EdgeInsets.fromLTRB(isCollapsed ? 8 : 14, 16, isCollapsed ? 8 : 12, 12),
            child: isCollapsed
                ? Center(
                    child: Tooltip(
                      message: 'Mart POS (ចុចដើម្បីពង្រីកមឺនុយ)',
                      child: InkWell(
                        onTap: () => ref.read(sidebarCollapsedProvider.notifier).toggle(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'M',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'M',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
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
                              'Mart POS',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'ប្រព័ន្ធគ្រប់គ្រងម៉ាត',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        tooltip: 'បង្រួមមឺនុយ (Collapse Menu)',
                        icon: Icon(
                          Icons.menu_open_rounded,
                          size: 19,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        onPressed: () {
                          ref.read(sidebarCollapsedProvider.notifier).toggle();
                        },
                      ),
                    ],
                  ),
          ),

          const Divider(height: 1),

          // Scrollable Navigation Groups (Collapsible Accordion)
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 8 : 10, vertical: 8),
              children: [
                for (final entry in groups.entries) ...[
                  if (isCollapsed) ...[
                    // Collapsed mode: icon-only items
                    const SizedBox(height: 6),
                    for (final item in entry.value) ...[
                      Builder(builder: (context) {
                        String? badgeText;
                        Color? badgeColor;
                        if (item.path == '/admin/inventory' && lowStockCount > 0) {
                          badgeText = '$lowStockCount';
                          badgeColor = const Color(0xFFE06D53); // Tavola coral
                        } else if (item.path == '/admin/reports') {
                          badgeText = 'LIVE';
                          badgeColor = const Color(0xFF10B981); // Mint green
                        }
                        return _buildDesktopNavItem(
                          context: context,
                          item: item,
                          isActive: _isItemActive(item, currentPath),
                          isCollapsed: isCollapsed,
                          isDark: isDark,
                          badgeText: badgeText,
                          badgeColor: badgeColor,
                        );
                      }),
                      const SizedBox(height: 2),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Divider(height: 1),
                    ),
                  ] else ...[
                    // Expanded mode: Clickable Collapsible Section Group (បិទបើក)
                    Builder(
                      builder: (context) {
                        final isGroupCollapsed = collapsedGroups.contains(entry.key);
                        final hasActiveItem = entry.value.any((item) => _isItemActive(item, currentPath));

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  ref.read(collapsedNavGroupsProvider.notifier).toggle(entry.key);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(10, 12, 8, 6),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          entry.key,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.9,
                                            color: hasActiveItem
                                                ? (isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5))
                                                : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      AnimatedRotation(
                                        turns: isGroupCollapsed ? 0.0 : 0.25,
                                        duration: const Duration(milliseconds: 200),
                                        child: Icon(
                                          Icons.chevron_right_rounded,
                                          size: 16,
                                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            ClipRect(
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOutCubic,
                                child: isGroupCollapsed
                                    ? const SizedBox.shrink()
                                    : Column(
                                        children: [
                                          for (final item in entry.value) ...[
                                            Builder(builder: (context) {
                                              String? badgeText;
                                              Color? badgeColor;
                                              if (item.path == '/admin/inventory' && lowStockCount > 0) {
                                                badgeText = '$lowStockCount';
                                                badgeColor = const Color(0xFFE06D53);
                                              } else if (item.path == '/admin/reports') {
                                                badgeText = 'LIVE';
                                                badgeColor = const Color(0xFF10B981);
                                              }
                                              return _buildDesktopNavItem(
                                                context: context,
                                                item: item,
                                                isActive: _isItemActive(item, currentPath),
                                                isCollapsed: isCollapsed,
                                                isDark: isDark,
                                                badgeText: badgeText,
                                                badgeColor: badgeColor,
                                              );
                                            }),
                                            const SizedBox(height: 2),
                                          ],
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // Footer (Theme Switch & Logout)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 8 : 12, vertical: 10),
            child: isCollapsed
                ? Column(
                    children: [
                      IconButton(
                        tooltip: isDark ? 'ប្តូរទៅ Light Mode' : 'ប្តូរទៅ Dark Mode',
                        icon: Icon(
                          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          size: 18,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
                      ),
                      const SizedBox(height: 4),
                      IconButton(
                        tooltip: 'ចាកចេញពីគណនី (Log Out)',
                        icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFEF4444)),
                        onPressed: () async {
                          await ref.read(authProvider.notifier).signOut();
                          if (context.mounted) context.go('/login');
                        },
                      ),
                    ],
                  )
                : Row(
                    children: [
                      IosThemeToggle(
                        value: isDark,
                        onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isDark ? 'Dark' : 'Light',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      const Spacer(),
                      Tooltip(
                        message: 'ចាកចេញពីគណនី (Log Out)',
                        child: InkWell(
                          onTap: () async {
                            await ref.read(authProvider.notifier).signOut();
                            if (context.mounted) context.go('/login');
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.logout_rounded, size: 16, color: Color(0xFFEF4444)),
                                SizedBox(width: 4),
                                Text(
                                  'Logout',
                                  style: TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopNavItem({
    required BuildContext context,
    required _NavItem item,
    required bool isActive,
    required bool isCollapsed,
    required bool isDark,
    String? badgeText,
    Color? badgeColor,
  }) {
    final activeBg = isDark
        ? const Color(0xFF1E2D4A)
        : const Color(0xFFEEF2FF);
    final activeBorder = isDark
        ? const Color(0xFF818CF8)
        : const Color(0xFF6366F1);

    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Tooltip(
          message: '${item.label}\n${item.khmerLabel}',
          child: InkWell(
            onTap: () => context.go(item.path),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isActive ? activeBg : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? activeBorder : Colors.transparent,
                  width: 1.2,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: (isDark ? const Color(0xFF6366F1) : const Color(0xFF818CF8))
                              .withValues(alpha: 0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    item.icon,
                    size: 20,
                    color: isActive
                        ? (isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5))
                        : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                  ),
                  if (badgeText != null)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: badgeColor ?? const Color(0xFFE06D53),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? const Color(0xFF0D1526) : Colors.white,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: InkWell(
        onTap: () => context.go(item.path),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? activeBorder.withValues(alpha: 0.5) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 19,
                color: isActive
                    ? (isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5))
                    : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        color: isActive
                            ? (isDark ? Colors.white : const Color(0xFF0F172A))
                            : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item.khmerLabel,
                      style: GoogleFonts.notoSansKhmer(
                        fontSize: 10,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (badgeText != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? const Color(0xFFE06D53)).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: badgeColor ?? const Color(0xFFE06D53),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (isActive)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFECD29A),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFECD29A),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String path;
  final String label;
  final String khmerLabel;
  final IconData icon;
  final String category;

  const _NavItem({
    required this.path,
    required this.label,
    required this.khmerLabel,
    required this.icon,
    required this.category,
  });
}



