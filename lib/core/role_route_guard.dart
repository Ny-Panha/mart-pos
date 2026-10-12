import '../data/firestore/models/user_model.dart';

/// Pure role routing policy shared by GoRouter and role access tests.
class RoleRouteGuard {
  const RoleRouteGuard._();

  static String? redirect(UserModel user, String path) {
    if (!user.active) {
      return path == '/login' ? null : '/login?error=deactivated';
    }

    if (path == '/login') {
      if (user.isManager) return '/manager';
      if (user.isAdmin) return '/admin';
      if (user.isCashier) return '/pos';
      return null;
    }

    final isManagerRoute = path.startsWith('/manager');
    final isAdminRoute = path.startsWith('/admin');
    final isCashierRoute = path.startsWith('/cashier');
    final isPosRoute = path == '/pos';

    if (user.isManager) return isManagerRoute ? null : '/manager';
    if (user.isAdmin) {
      return isManagerRoute || isCashierRoute ? '/admin' : null;
    }
    if (user.isCashier) {
      if (isManagerRoute || isAdminRoute) return '/pos';
      return isPosRoute || isCashierRoute ? null : '/pos';
    }
    return '/login';
  }
}
