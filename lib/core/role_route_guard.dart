import '../data/firestore/models/user_model.dart';

/// Pure role routing policy shared by GoRouter and role access tests.
class RoleRouteGuard {
  const RoleRouteGuard._();

  static String _mapManagerPathToAdmin(String path) {
    if (path == '/manager/products') return '/admin/products';
    if (path == '/manager/stock') return '/admin/inventory';
    if (path == '/manager/reports') return '/admin/reports';
    if (path == '/manager/settings' || path == '/manager/system') {
      return '/admin/settings';
    }
    return '/admin';
  }

  static String? redirect(UserModel user, String path) {
    if (!user.active) {
      return path == '/login' ? null : '/login?error=deactivated';
    }

    if (path == '/login' || path == '/' || path == '/dashboard') {
      if (user.canManageShop) return '/admin';
      if (user.isCashier) return '/pos';
      return null;
    }

    final isManagerRoute = path == '/manager' || path.startsWith('/manager/');
    final isAdminRoute = path == '/admin' || path.startsWith('/admin/');
    final isCashierRoute = path == '/cashier' || path.startsWith('/cashier/');
    final isPosRoute = path == '/pos';

    if (user.canManageShop) {
      if (isManagerRoute) return _mapManagerPathToAdmin(path);
      if (isCashierRoute) return '/admin';
      return null;
    }
    if (user.isCashier) {
      if (isManagerRoute || isAdminRoute) return '/pos';
      return isPosRoute || isCashierRoute ? null : '/pos';
    }
    return '/login';
  }
}
