import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../firestore/firestore_collections.dart';
import '../firestore/models/user_model.dart';
import '../services/api_service.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  Future<UserModel> _syncUserProfile(UserModel profile, User user) async {
    UserModel updated = profile;
    if ((updated.email == null || updated.email!.isEmpty) && user.email != null) {
      updated = updated.copyWith(email: user.email);
    }

    final email = (updated.email ?? user.email ?? '').toLowerCase().trim();
    if (email == 'admin@bbu.edu.kh') {
      if (updated.name != 'ផ្កាយ') {
        try {
          await FirestoreCollections.users.doc(user.uid).update({'name': 'ផ្កាយ'});
        } catch (_) {}
        updated = updated.copyWith(name: 'ផ្កាយ');
      }
    } else if (email == 'cashier@bbu.edu.kh') {
      if (updated.name != 'នី បញ្ញា') {
        try {
          await FirestoreCollections.users.doc(user.uid).update({'name': 'នី បញ្ញា'});
        } catch (_) {}
        updated = updated.copyWith(name: 'នី បញ្ញា');
      }
    }
    return updated;
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await FirestoreCollections.users.doc(user.uid).get();
    if (!doc.exists || doc.data() == null) {
      throw Exception('Account not set up — contact admin');
    }

    var profile = doc.data()!;
    profile = await _syncUserProfile(profile, user);

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
    // 1. Try Laravel REST API login first
    try {
      final res = await ApiService.post('/login', {
        'email': email.trim(),
        'password': password,
      });

      if (res != null && res['success'] == true && res['data'] != null) {
        final token = res['data']['token']?.toString();
        if (token != null) {
          await ApiService.saveToken(token);
        }
        final userData = res['data']['user'] as Map<String, dynamic>;
        final userModel = UserModel.fromJson(userData);
        debugPrint('Signed in via Laravel REST API: ${userModel.name} (${userModel.role})');
        return userModel;
      }
    } catch (e) {
      debugPrint('Laravel API login notice (falling back to Firebase): $e');
    }

    // 2. Fallback to Firebase Auth
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    final uid = user.uid;

    final doc = await FirestoreCollections.users.doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      await _auth.signOut();
      throw Exception('Account not set up — contact admin');
    }

    var profile = doc.data()!;
    profile = await _syncUserProfile(profile, user);

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
    await ApiService.clearToken();
    await _auth.signOut();
  }
}
