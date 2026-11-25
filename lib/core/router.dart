import 'package:mart_pos/core/motion/app_motion.dart';
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
  final scrollBuckets = <String, PageStorageBucket>{};
  final authSubscription = ref.listen(authProvider, (previous, next) {
    final oldUser = previous?.value;
    final user = next.value;
    if (oldUser?.id != user?.id || oldUser?.shopId != user?.shopId ||
        oldUser?.role != user?.role) {
      scrollBuckets.clear();
    }
    refreshNotifier.refresh();
  });

  CustomTransitionPage<void> motionPage(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) {
    final duration = AppMotionTokens.time(
      context,
      const Duration(milliseconds: 240),
    );
    return CustomTransitionPage(
      key: state.pageKey,
      child: PageStorage(
        bucket: scrollBuckets.putIfAbsent(
          state.fullPath ?? state.uri.path,
          PageStorageBucket.new,
        ),
        child: child,
      ),
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (_, animation, secondary, child) =>
          DirectionalPageTransition(animation: animation, child: child),
    );
  }

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
          GoRoute(path: '/', redirect: (context, state) => '/admin'),
          GoRoute(path: '/dashboard', redirect: (context, state) => '/admin'),
          GoRoute(
            path: '/admin',
            pageBuilder: (context, state) =>
                motionPage(context, state, const DashboardScreen()),
          ),
          GoRoute(
            path: '/pos',
            pageBuilder: (context, state) =>
                motionPage(context, state, const PosScreen()),
          ),
          GoRoute(
            path: '/admin/products',
            pageBuilder: (context, state) =>
                motionPage(context, state, const ProductsScreen()),
          ),
          GoRoute(
            path: '/admin/inventory',
            pageBuilder: (context, state) =>
                motionPage(context, state, const InventoryScreen()),
          ),
          GoRoute(
            path: '/admin/purchases',
            pageBuilder: (context, state) =>
                motionPage(context, state, const PurchasesScreen()),
          ),
          GoRoute(
            path: '/admin/suppliers',
            pageBuilder: (context, state) =>
                motionPage(context, state, const SuppliersScreen()),
          ),
          GoRoute(
            path: '/admin/customers',
            pageBuilder: (context, state) =>
                motionPage(context, state, const CustomersScreen()),
          ),
          GoRoute(
            path: '/admin/reports',
            pageBuilder: (context, state) =>
                motionPage(context, state, const ReportsScreen()),
          ),
          GoRoute(
            path: '/admin/users',
            pageBuilder: (context, state) =>
                motionPage(context, state, const UsersScreen()),
          ),
          GoRoute(
            path: '/admin/audit-log',
            pageBuilder: (context, state) =>
                motionPage(context, state, const AuditLogsScreen()),
          ),
          GoRoute(
            path: '/admin/settings',
            pageBuilder: (context, state) =>
                motionPage(context, state, const AdminShopSettingsScreen()),
          ),
          GoRoute(
            path: '/admin/attendance',
            pageBuilder: (context, state) =>
                motionPage(context, state, const AdminAttendanceScreen()),
          ),
          GoRoute(
            path: '/admin/notifications',
            pageBuilder: (context, state) =>
                motionPage(context, state, const AdminNotificationsScreen()),
          ),
          GoRoute(
            path: '/admin/reports/details',
            pageBuilder: (context, state) =>
                motionPage(context, state, const AdminReportsScreen()),
          ),
          GoRoute(
            path: '/cashier/history',
            pageBuilder: (context, state) =>
                motionPage(context, state, const CashierSalesHistoryScreen()),
          ),
          GoRoute(
            path: '/cashier/stock',
            pageBuilder: (context, state) =>
                motionPage(context, state, const CashierStockScreen()),
          ),
          GoRoute(
            path: '/cashier/shift',
            pageBuilder: (context, state) =>
                motionPage(context, state, const CashierDailyCloseScreen()),
          ),
          GoRoute(
            path: '/cashier/invoice/:id',
            pageBuilder: (context, state) {
              final sale = state.extra;
              return motionPage(
                context,
                state,
                sale is SaleModel
                    ? CashierInvoiceScreen(sale: sale)
                    : const CashierSalesHistoryScreen(),
              );
            },
          ),
          GoRoute(
            path: '/manager',
            pageBuilder: (context, state) =>
                motionPage(context, state, const AdminManagerDashboardScreen()),
          ),
          GoRoute(
            path: '/manager/shops',
            redirect: (context, state) => '/manager',
          ),
          GoRoute(
            path: '/manager/admins',
            redirect: (context, state) => '/manager',
          ),
          GoRoute(
            path: '/manager/locations',
            redirect: (context, state) => '/manager',
          ),
          GoRoute(
            path: '/manager/subscriptions',
            redirect: (context, state) => '/manager',
          ),
          GoRoute(
            path: '/manager/products',
            pageBuilder: (context, state) =>
                motionPage(context, state, const AdminManagerCatalogScreen()),
          ),
          GoRoute(
            path: '/manager/stock',
            pageBuilder: (context, state) =>
                motionPage(context, state, const AdminManagerStockScreen()),
          ),
          GoRoute(
            path: '/manager/reports',
            pageBuilder: (context, state) =>
                motionPage(context, state, const AdminManagerReportsScreen()),
          ),
          GoRoute(
            path: '/manager/system',
            pageBuilder: (context, state) =>
                motionPage(context, state, const AdminManagerSystemScreen()),
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
