import '../firestore/firestore_collections.dart';
import '../firestore/models/user_model.dart';

class UserRepository {
  Stream<List<UserModel>> watchUsers() {
    return FirestoreCollections.users
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => d.data()).toList());
  }

  Future<void> createUserDoc({
    required String uid,
    required String name,
    required String role,
  }) async {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) {
      throw Exception('UID cannot be empty');
    }

    final user = UserModel(
      id: cleanUid,
      name: name.trim(),
      role: role.trim().toLowerCase(),
      active: true,
      createdAt: DateTime.now(),
    );

    await FirestoreCollections.users.doc(cleanUid).set(user);
  }

  Future<void> updateUserRole(String uid, String role) async {
    await FirestoreCollections.users.doc(uid).update({
      'role': role.trim().toLowerCase(),
    });
  }

  Future<void> updateUserName(String uid, String name) async {
    await FirestoreCollections.users.doc(uid).update({
      'name': name.trim(),
    });
  }

  Future<void> setUserActive(String uid, bool active) async {
    if (!active) {
      // Check if user is the last active admin
      final targetDoc = await FirestoreCollections.users.doc(uid).get();
      if (!targetDoc.exists || targetDoc.data() == null) {
        throw Exception('User not found');
      }

      final targetUser = targetDoc.data()!;
      if (targetUser.isAdmin) {
        final allUsersSnap = await FirestoreCollections.users.get();
        final allUsers = allUsersSnap.docs.map((d) => d.data()).toList();

        if (!canDeactivateUser(allUsers: allUsers, targetUid: uid)) {
          throw Exception('Cannot deactivate the last active admin');
        }
      }
    }

    await FirestoreCollections.users.doc(uid).update({
      'active': active,
    });
  }

  /// Pure helper for checking whether a user can be safely deactivated.
  /// If the target is the only active admin remaining, returns false.
  static bool canDeactivateUser({
    required List<UserModel> allUsers,
    required String targetUid,
  }) {
    final target = allUsers.firstWhere(
      (u) => u.id == targetUid,
      orElse: () => UserModel(id: '', name: '', role: 'cashier', active: false),
    );

    // Cashiers or non-admin roles can always be deactivated
    if (!target.isAdmin) return true;

    // Check if there are other active admins in the list
    final otherActiveAdmins = allUsers.where((u) => u.id != targetUid && u.isAdmin && u.active);
    return otherActiveAdmins.isNotEmpty;
  }
}
