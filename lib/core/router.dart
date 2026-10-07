import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/customers/presentation/customers_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/inventory/presentation/inventory_screen.dart';
import '../features/pos/presentation/pos_screen.dart';
import '../features/products/presentation/products_screen.dart';
import '../features/reports/presentation/reports_screen.dart';
import '../features/users/presentation/users_screen.dart';
import 'widgets/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final user = authState.value;
      final isLoggingIn = state.uri.toString() == '/login';

      // 1. Unauthenticated -> force login
      if (user == null) {
        return isLoggingIn ? null : '/login';
      }

      // 2. Authenticated user accessing login page
      if (isLoggingIn) {
        return '/pos';
      }

      // 3. Role-based Guard: Cashiers cannot access /admin routes
      final isGoingToAdmin = state.uri.toString().startsWith('/admin');
      if (isGoingToAdmin && !user.isAdmin) {
        return '/pos';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/pos',
            builder: (context, state) => const PosScreen(),
          ),
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
        ],
      ),
    ],
  );
});
