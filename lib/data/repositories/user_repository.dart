import 'package:cloud_functions/cloud_functions.dart';

import '../firestore/firestore_collections.dart';
import '../firestore/models/user_model.dart';
import '../firestore/shop_scope.dart';
import '../services/audit_service.dart';

class UserRepository {
  final FirebaseFunctions _functions;
  UserRepository({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  Stream<List<UserModel>> watchUsers() {
    return ShopScope.query(FirestoreCollections.users)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> createUserDoc({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final normalizedRole = role.trim().toUpperCase();
    if (normalizedRole != UserModel.cashierRole) {
      throw ArgumentError('Shop admins may provision cashier accounts only.');
    }
    await _functions.httpsCallable('provisionUser').call({
      'email': email.trim(),
      'password': password,
      'name': name.trim(),
      'role': normalizedRole,
      'shopId': ShopScope.requireShopId(),
    });
  }

  Future<void> updateUserRole(
    String uid,
    String role, {
    String? adminId,
    String? adminName,
  }) async {
    final normalizedRole = role.trim().toUpperCase();
    await _functions.httpsCallable('setShopUserRole').call({
      'uid': uid,
      'role': normalizedRole,
      'shopId': ShopScope.requireShopId(),
    });
    await AuditService.log(
      userId: adminId ?? 'system',
      userName: adminName ?? 'Admin',
      action: 'user.role_change',
      entityType: 'user',
      entityId: uid,
      details: 'Role changed to $normalizedRole',
    );
  }

  Future<void> updateUserName(String uid, String name) async {
    await _functions.httpsCallable('updateUserAccess').call({
      'uid': uid,
      'name': name.trim(),
    });
  }

  Future<void> setUserActive(
    String uid,
    bool active, {
    String? adminId,
    String? adminName,
    String? targetUserName,
  }) async {
    await _functions.httpsCallable('setShopUserActive').call({
      'uid': uid,
      'active': active,
    });
    await AuditService.log(
      userId: adminId ?? 'system',
      userName: adminName ?? 'Admin',
      action: active ? 'user.activate' : 'user.deactivate',
      entityType: 'user',
      entityId: uid,
      details:
          '${targetUserName ?? 'User $uid'} ${active ? 'activated' : 'deactivated'}',
    );
  }

  /// Pure helper retained for UI feedback; the callable also enforces this rule.
  static bool canDeactivateUser({
    required List<UserModel> allUsers,
    required String targetUid,
  }) {
    final target = allUsers.firstWhere(
      (user) => user.id == targetUid,
      orElse: () => UserModel(
        id: '',
        name: '',
        role: UserModel.cashierRole,
        active: false,
      ),
    );
    if (!target.isAdmin) return true;
    return allUsers.any(
      (user) => user.id != targetUid && user.isAdmin && user.active,
    );
  }
}
