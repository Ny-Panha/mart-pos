import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/audit/presentation/audit_logs_screen.dart';
import '../features/admin_manager/admin_manager.dart';
import '../features/cashier/cashier.dart';
import '../features/shop_admin/shop_admin.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/customers/presentation/customers_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/inventory/presentation/inventory_screen.dart';
import '../features/pos/presentation/pos_screen.dart';
import '../features/products/presentation/products_screen.dart';
import '../features/purchases/presentation/purchases_screen.dart';
import '../features/reports/presentation/reports_screen.dart';
import '../features/suppliers/presentation/suppliers_screen.dart';
import '../features/users/presentation/users_screen.dart';
import '../data/firestore/models/sale_model.dart';
import 'role_route_guard.dart';
import 'widgets/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  // Keep one router instance alive for the lifetime of this provider. Rebuilding
  // GoRouter on every auth state transition reuses the navigator keys above and
  // can leave two router trees competing for the same GlobalKeys during a web
  // rebuild.
  final refreshNotifier = _RouterRefreshNotifier();
  final authSubscription = ref.listen(authProvider, (_, _) {
    refreshNotifier.refresh();
  });

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      if (authState.isLoading) return null;

      final user = authState.value;
      final path = state.uri.path;
      final isLoggingIn = path == '/login';

      // 1. Unauthenticated -> force login
      if (user == null) {
        return isLoggingIn ? null : '/login';
      }

      return RoleRouteGuard.redirect(user, path);
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/pos', builder: (context, state) => const PosScreen()),
          GoRoute(
            path: '/admin',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/admin/products',
            builder: (context, state) => const ProductsScreen(),
          ),
          GoRoute(
            path: '/admin/inventory',
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: '/admin/purchases',
            builder: (context, state) => const PurchasesScreen(),
          ),
          GoRoute(
            path: '/admin/suppliers',
            builder: (context, state) => const SuppliersScreen(),
          ),
          GoRoute(
            path: '/admin/customers',
            builder: (context, state) => const CustomersScreen(),
          ),
          GoRoute(
            path: '/admin/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const UsersScreen(),
          ),
          GoRoute(
            path: '/admin/audit-log',
            builder: (context, state) => const AuditLogsScreen(),
          ),
          GoRoute(
            path: '/admin/settings',
            builder: (context, state) => const AdminShopSettingsScreen(),
          ),
          GoRoute(
            path: '/admin/attendance',
            builder: (context, state) => const AdminAttendanceScreen(),
          ),
          GoRoute(
            path: '/admin/notifications',
            builder: (context, state) => const AdminNotificationsScreen(),
          ),
          GoRoute(
            path: '/admin/reports/details',
            builder: (context, state) => const AdminReportsScreen(),
          ),
          GoRoute(
            path: '/cashier/history',
            builder: (context, state) => const CashierSalesHistoryScreen(),
          ),
          GoRoute(
            path: '/cashier/stock',
            builder: (context, state) => const CashierStockScreen(),
          ),
          GoRoute(
            path: '/cashier/shift',
            builder: (context, state) => const CashierDailyCloseScreen(),
          ),
          GoRoute(
            path: '/cashier/invoice/:id',
            builder: (context, state) {
              final sale = state.extra;
              if (sale is SaleModel) return CashierInvoiceScreen(sale: sale);
              return const CashierSalesHistoryScreen();
            },
          ),
          GoRoute(
            path: '/manager',
            builder: (context, state) => const AdminManagerDashboardScreen(),
          ),
          GoRoute(
            path: '/manager/shops',
            builder: (context, state) => const AdminManagerShopsScreen(),
          ),
          GoRoute(
            path: '/manager/admins',
            builder: (context, state) => const AdminManagerAdminsScreen(),
          ),
          GoRoute(
            path: '/manager/locations',
            builder: (context, state) => const AdminManagerLocationsScreen(),
          ),
          GoRoute(
            path: '/manager/subscriptions',
            builder: (context, state) =>
                const AdminManagerSubscriptionsScreen(),
          ),
          GoRoute(
            path: '/manager/products',
            builder: (context, state) => const AdminManagerCatalogScreen(),
          ),
          GoRoute(
            path: '/manager/stock',
            builder: (context, state) => const AdminManagerCatalogScreen(),
          ),
          GoRoute(
            path: '/manager/reports',
            builder: (context, state) => const AdminManagerReportsScreen(),
          ),
          GoRoute(
            path: '/manager/system',
            builder: (context, state) => const AdminManagerSystemScreen(),
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    authSubscription.close();
    router.dispose();
    refreshNotifier.dispose();
  });

  return router;
});
