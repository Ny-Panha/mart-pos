import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/theme_mode_provider.dart';
import '../utils/responsive.dart';
import 'ios_theme_toggle.dart';
export 'ios_theme_toggle.dart';

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
          path: '/pos',
          label: 'POS Checkout',
          khmerLabel: 'បញ្ជរគិតលុយ',
          icon: Icons.point_of_sale_rounded,
          category: 'ចម្បង (CORE)',
        ),
        _NavItem(
          path: '/admin',
          label: 'Dashboard',
          khmerLabel: 'ផ្ទាំងគ្រប់គ្រង',
          icon: Icons.dashboard_rounded,
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
    final user = ref.watch(authProvider).value;
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
            Expanded(child: child),
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
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: activeTabIndex >= 0 ? activeTabIndex : primaryTabs.length,
        onDestinationSelected: (index) {
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

            return Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
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
                                    (user?.email?.isNotEmpty ?? false)
                                        ? user!.email[0].toUpperCase()
                                        : 'M',
                                    style: const TextStyle(
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
                                      user?.name ?? user?.email ?? 'Mart User',
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
                                      '${user?.normalizedRole ?? "Staff"} • Mart POS',
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
    required this.user,
    required this.manager,
    required this.admin,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Group items by category
    final Map<String, List<_NavItem>> groups = {};
    for (final item in items) {
      groups.putIfAbsent(item.category, () => []).add(item);
    }

    return Container(
      width: 250,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Column(
        children: [
          // Branding Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'M',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
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
                        manager ? 'PLATFORM ADMIN' : 'MINI-MART POS',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Text(
                        'Management System',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // User Info Pill Card
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.15),
                      child: Text(
                        (user.email?.isNotEmpty ?? false)
                            ? user.email[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkPrimary : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name ?? user.email ?? 'User',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user.normalizedRole,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 8),
          const Divider(height: 1),

          // Scrollable Navigation Groups
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              children: [
                for (final entry in groups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.9,
                        color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                      ),
                    ),
                  ),
                  for (final item in entry.value) ...[
                    _buildDesktopNavItem(
                      context: context,
                      item: item,
                      isActive: currentPath == item.path ||
                          (item.path != '/' && currentPath.startsWith('${item.path}/')),
                    ),
                    const SizedBox(height: 2),
                  ],
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // Footer (iPhone-style Theme Switch & Logout)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
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
                    color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).signOut();
                    if (context.mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.danger),
                  label: const Text('Log out', style: TextStyle(color: AppColors.danger, fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
  }) {
    final activeBg = isDark
        ? AppColors.darkPrimary.withValues(alpha: 0.16)
        : AppColors.primary.withValues(alpha: 0.10);
    final activeBorder = (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.35);

    return InkWell(
      onTap: () => context.go(item.path),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? activeBorder : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 19,
              color: isActive
                  ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                  : (isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
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
                          ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                          : (isDark ? AppColors.darkText : AppColors.lightText),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item.khmerLabel,
                    style: GoogleFonts.notoSansKhmer(
                      fontSize: 10,
                      color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isActive)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                ),
              ),
          ],
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



