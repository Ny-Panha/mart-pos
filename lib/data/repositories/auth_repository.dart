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
    if (email == 'admin@bbu.edu.kh' || email == 'admin@martpos.com') {
      if (updated.name != 'ផ្កាយ' && email == 'admin@bbu.edu.kh') {
        try {
          await FirestoreCollections.users.doc(user.uid).update({'name': 'ផ្កាយ'});
        } catch (_) {}
        updated = updated.copyWith(name: 'ផ្កាយ');
      }
    } else if (email == 'cashier@bbu.edu.kh' || email == 'cashier@martpos.com') {
      if (updated.name != 'បញ្ញា' && email == 'cashier@bbu.edu.kh') {
        try {
          await FirestoreCollections.users.doc(user.uid).update({'name': 'បញ្ញា'});
        } catch (_) {}
        updated = updated.copyWith(name: 'បញ្ញា');
      }
    }
    return updated;
  }

  /// Authoritative Session Restoration:
  /// 1. Validates stored Laravel Sanctum token with `GET /me`.
  /// 2. If valid, restores authoritative user profile and permissions.
  /// 3. Falls back to Firebase session if available.
  Future<UserModel?> getCurrentUserProfile() async {
    // 1. Check Laravel Sanctum session
    if (ApiService.token != null && ApiService.token!.isNotEmpty) {
      try {
        final res = await ApiService.get('/me');
        if (res != null && res['success'] == true && res['data'] != null) {
          final userData = res['data'] as Map<String, dynamic>;
          final laravelUser = UserModel.fromJson(userData);
          debugPrint('Restored authoritative session via Laravel API: ${laravelUser.name} (${laravelUser.role})');
          return laravelUser;
        }
      } catch (e) {
        debugPrint('Laravel session validation notice: $e');
        if (e.toString().contains('401') || e.toString().contains('Unauthenticated')) {
          await ApiService.clearToken();
        }
      }
    }

    // 2. Fall back to Firebase session
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await FirestoreCollections.users.doc(user.uid).get();
      if (!doc.exists || doc.data() == null) {
        return null;
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
    } catch (_) {
      return null;
    }
  }

  /// Sign In with unified Laravel + Firebase authentication
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    UserModel? laravelUser;

    // 1. Authoritative login on Laravel REST API
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
        laravelUser = UserModel.fromJson(userData);
        debugPrint('Signed in via Laravel REST API: ${laravelUser.name} (${laravelUser.role})');
      }
    } catch (e) {
      debugPrint('Laravel API login notice: $e');
    }

    // 2. Also authenticate to Firebase if configured
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      final uid = user.uid;

      final doc = await FirestoreCollections.users.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        var profile = doc.data()!;
        profile = await _syncUserProfile(profile, user);
        return profile;
      }
    } catch (e) {
      debugPrint('Firebase signIn notice: $e');
    }

    // If Laravel authentication was successful, return the authoritative profile
    if (laravelUser != null) {
      return laravelUser;
    }

    throw Exception('ចូលប្រើប្រាស់បរាជ័យ (Invalid email/password or server connection failed)');
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
      final doc = await FirestoreCollections.users
          .doc(credential.user!.uid)
          .get();
      if (!doc.exists || doc.data()?.isManager != true) await signOut();
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      if (ApiService.token != null) {
        await ApiService.post('/logout', {});
      }
    } catch (_) {}
    await ApiService.clearToken();
    try {
      await _auth.signOut();
    } catch (_) {}
  }
}
