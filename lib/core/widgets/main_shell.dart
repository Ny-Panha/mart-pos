import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/pos')) return 0;
    if (location.startsWith('/admin/products')) return 2;
    if (location.startsWith('/admin/inventory')) return 3;
    if (location.startsWith('/admin/purchases')) return 4;
    if (location.startsWith('/admin/suppliers')) return 5;
    if (location.startsWith('/admin/customers')) return 6;
    if (location.startsWith('/admin/reports')) return 7;
    if (location.startsWith('/admin/users')) return 8;
    if (location.startsWith('/admin/audit-log')) return 9;
    if (location.startsWith('/admin')) return 1;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context, bool isAdmin) {
    switch (index) {
      case 0:
        context.go('/pos');
        break;
      case 1:
        if (isAdmin) context.go('/admin');
        break;
      case 2:
        if (isAdmin) context.go('/admin/products');
        break;
      case 3:
        if (isAdmin) context.go('/admin/inventory');
        break;
      case 4:
        if (isAdmin) context.go('/admin/purchases');
        break;
      case 5:
        if (isAdmin) context.go('/admin/suppliers');
        break;
      case 6:
        if (isAdmin) context.go('/admin/customers');
        break;
      case 7:
        if (isAdmin) context.go('/admin/reports');
        break;
      case 8:
        if (isAdmin) context.go('/admin/users');
        break;
      case 9:
        if (isAdmin) context.go('/admin/audit-log');
        break;
    }
  }

  int _calculateBottomNavIndex(BuildContext context, bool isAdmin) {
    if (!isAdmin) return 0;
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/pos')) return 0;
    if (location.startsWith('/admin/products')) return 2;
    if (location.startsWith('/admin/inventory')) return 3;
    if (location.startsWith('/admin/reports')) return 4;
    if (location.startsWith('/admin')) return 1;
    return 0;
  }

  void _onBottomNavTapped(int index, BuildContext context, bool isAdmin) {
    switch (index) {
      case 0:
        context.go('/pos');
        break;
      case 1:
        if (isAdmin) context.go('/admin');
        break;
      case 2:
        if (isAdmin) context.go('/admin/products');
        break;
      case 3:
        if (isAdmin) context.go('/admin/inventory');
        break;
      case 4:
        if (isAdmin) context.go('/admin/reports');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    final isAdmin = user?.isAdmin ?? false;
    final selectedIndex = _calculateSelectedIndex(context);
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);

    // Desktop/Tablet: Side Navigation Rail
    if (isDesktop || isTablet) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (idx) => _onItemTapped(idx, context, isAdmin),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
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
                    const SizedBox(height: 6),
                    const Text(
                      'MINI-MART',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: IconButton(
                      tooltip: 'Log Out',
                      icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
                      onPressed: () {
                        ref.read(authProvider.notifier).signOut();
                        context.go('/login');
                      },
                    ),
                  ),
                ),
              ),
              destinations: [
                const NavigationRailDestination(
                  icon: Icon(Icons.point_of_sale_outlined),
                  selectedIcon: Icon(Icons.point_of_sale, color: AppColors.primary),
                  label: Text('POS'),
                ),
                if (isAdmin) ...[
                  const NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
                    label: Text('Dashboard'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.inventory_2_outlined),
                    selectedIcon: Icon(Icons.inventory_2, color: AppColors.primary),
                    label: Text('Products'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.swap_vert_circle_outlined),
                    selectedIcon: Icon(Icons.swap_vert_circle, color: AppColors.primary),
                    label: Text('Stock'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.shopping_bag_outlined),
                    selectedIcon: Icon(Icons.shopping_bag, color: AppColors.primary),
                    label: Text('Purchases'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.local_shipping_outlined),
                    selectedIcon: Icon(Icons.local_shipping, color: AppColors.primary),
                    label: Text('Suppliers'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.people_outline),
                    selectedIcon: Icon(Icons.people, color: AppColors.primary),
                    label: Text('Customers'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.analytics_outlined),
                    selectedIcon: Icon(Icons.analytics, color: AppColors.primary),
                    label: Text('Reports'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.badge_outlined),
                    selectedIcon: Icon(Icons.badge, color: AppColors.primary),
                    label: Text('Staff'),
                  ),
                  const NavigationRailDestination(
                    icon: Icon(Icons.shield_outlined),
                    selectedIcon: Icon(Icons.shield, color: AppColors.primary),
                    label: Text('Audit Log'),
                  ),
                ],
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    // Mobile: Bottom Navigation Bar
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateBottomNavIndex(context, isAdmin),
        onTap: (idx) => _onBottomNavTapped(idx, context, isAdmin),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.lightMutedText,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale),
            label: 'POS',
          ),
          if (isAdmin) ...[
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              label: 'Dashboard',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              label: 'Products',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.swap_vert_circle_outlined),
              label: 'Stock',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              label: 'Reports',
            ),
          ],
        ],
      ),
    );
  }
}
