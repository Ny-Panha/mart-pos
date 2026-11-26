import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../services/api_service.dart';
import '../firestore/firestore_collections.dart';
import '../firestore/models/user_model.dart';
import '../firestore/shop_scope.dart';
import '../services/audit_service.dart';

class UserRepository {
  final FirebaseFunctions _functions;
  UserRepository({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  Future<List<UserModel>> _fetchBackendUsers() async {
    try {
      final res = await ApiService.get('/users');
      if (res['success'] == true && res['data'] is List) {
        return (res['data'] as List).map((raw) {
          final m = Map<String, dynamic>.from(raw as Map);
          return UserModel(
            id: m['id'].toString(),
            name: (m['name'] ?? '').toString(),
            email: m['email']?.toString(),
            role: (m['role'] ?? 'CASHIER').toString(),
            active: (m['status'] ?? 'active').toString() == 'active',
            createdAt: DateTime.now(),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('fetchBackendUsers error: $e');
    }
    return const [];
  }

  Stream<List<UserModel>> watchUsers() async* {
    final backendUsers = await _fetchBackendUsers();
    if (backendUsers.isNotEmpty) {
      yield backendUsers;
    }

    yield* ShopScope.query(FirestoreCollections.users)
        .snapshots()
        .map((snapshot) {
          final firestoreUsers = snapshot.docs.map((doc) {
            final data = doc.data();
            final email = (data.email ?? '').toLowerCase().trim();
            if (email == 'admin@bbu.edu.kh' && data.name != 'ផ្កាយ') {
              return data.copyWith(name: 'ផ្កាយ');
            } else if (email == 'cashier@bbu.edu.kh' && data.name != 'នី បញ្ញា') {
              return data.copyWith(name: 'នី បញ្ញា');
            }
            return data;
          }).toList();

          final merged = <String, UserModel>{
            for (final u in firestoreUsers) u.id: u,
            for (final u in backendUsers) u.id: u,
          };
          final list = merged.values.toList();
          list.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
          return list;
        })
        .handleError((error) {
          debugPrint('watchUsers error: $error');
          return backendUsers;
        });
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

    try {
      await _functions.httpsCallable('provisionUser').call({
        'email': email.trim(),
        'password': password,
        'name': name.trim(),
        'role': normalizedRole,
        'shopId': ShopScope.requireShopId(),
      });
      return;
    } on FirebaseFunctionsException catch (e) {
      // If Cloud Functions are not deployed to Firebase (404/internal), use client fallback
      if (e.code == 'internal' ||
          e.code == 'not-found' ||
          e.code == 'unavailable') {
        try {
          await _fallbackCreateCashier(
            email: email.trim(),
            password: password,
            name: name.trim(),
            shopId: ShopScope.requireShopId(),
          );
          return;
        } catch (fallbackError) {
          if (fallbackError is FirebaseAuthException) {
            rethrow;
          }
          throw FirebaseFunctionsException(
            message:
                'Firebase Cloud Functions មិនទាន់បាន Deploy (Functions not deployed to Firebase). '
                'ព័ត៌មានលម្អិត: $fallbackError',
            code: 'internal',
          );
        }
      }
      rethrow;
    }
  }

  Future<void> _fallbackCreateCashier({
    required String email,
    required String password,
    required String name,
    required String shopId,
  }) async {
    final defaultApp = Firebase.app();
    final tempName =
        'cashier_creator_${DateTime.now().millisecondsSinceEpoch}';
    final tempApp = await Firebase.initializeApp(
      name: tempName,
      options: defaultApp.options,
    );
    try {
      final auth = FirebaseAuth.instanceFor(app: tempApp);
      final cred = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user?.uid;
      if (uid == null) {
        throw Exception('Failed to obtain new cashier UID.');
      }
      await cred.user?.updateDisplayName(name);

      final newCashier = UserModel(
        id: uid,
        name: name,
        email: email,
        role: UserModel.cashierRole,
        shopId: shopId,
        active: true,
        createdAt: DateTime.now(),
      );

      await FirestoreCollections.users.doc(uid).set(newCashier);
    } finally {
      await tempApp.delete();
    }
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
