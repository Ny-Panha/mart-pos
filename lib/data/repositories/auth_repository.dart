import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../firestore/firestore_collections.dart';
import '../firestore/models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await FirestoreCollections.users.doc(user.uid).get();
    if (!doc.exists || doc.data() == null) {
      throw Exception('Account not set up — contact admin');
    }

    final profile = doc.data()!;
    if (!profile.isManager &&
        (profile.shopId == null || profile.shopId!.isEmpty)) {
      await signOut();
      throw Exception(
        'Your account is not assigned to a shop. Contact the platform manager.',
      );
    }
    if (!profile.active) {
      await signOut();
      throw Exception('Account deactivated');
    }

    return profile;
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;

    final doc = await FirestoreCollections.users.doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      await _auth.signOut();
      throw Exception('Account not set up — contact admin');
    }

    final profile = doc.data()!;
    if (!profile.isManager &&
        (profile.shopId == null || profile.shopId!.isEmpty)) {
      await _auth.signOut();
      throw Exception(
        'Your account is not assigned to a shop. Contact the platform manager.',
      );
    }
    if (!profile.active) {
      await _auth.signOut();
      throw Exception('Account deactivated');
    }

    return profile;
  }

  /// Completes the one-time manager bootstrap for the UID allowlisted by the
  /// deployed callable. The client cannot choose its role or shop assignment.
  Future<UserModel> bootstrapFirstManager({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    try {
      await FirebaseFunctions.instance
          .httpsCallable('bootstrapFirstManager')
          .call({'name': name.trim()});
      final profile = await getCurrentUserProfile();
      if (profile == null || !profile.isManager) {
        throw Exception('Manager profile was not created.');
      }
      return profile;
    } catch (_) {
      // Keep the Firebase session only when the callable provisioned a profile.
      final doc = await FirestoreCollections.users
          .doc(credential.user!.uid)
          .get();
      if (!doc.exists || doc.data()?.isManager != true) await signOut();
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
