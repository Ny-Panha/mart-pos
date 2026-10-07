import 'package:firebase_auth/firebase_auth.dart';
import '../firestore/firestore_collections.dart';
import '../firestore/models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await FirestoreCollections.users.doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
    } catch (_) {
      // Fallback
    }

    // Default profile based on email
    final email = user.email ?? '';
    final role = (email.contains('cashier') || email.contains('pkay') || email.contains('daly'))
        ? 'cashier'
        : 'admin';
    final name = email.contains('pkay')
        ? 'គក់ ស្រីផ្កាយ'
        : (email.contains('daly') ? 'គុយ ដាលី' : (user.displayName ?? 'នី បញ្ញា'));

    return UserModel(
      id: user.uid,
      name: name,
      role: role,
      active: true,
    );
  }

  Future<UserModel> signIn({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;

      final doc = await FirestoreCollections.users.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!;
      }

      // If user profile doc doesn't exist yet in Firestore, create it
      final role = (email.contains('cashier') || email.contains('pkay') || email.contains('daly'))
          ? 'cashier'
          : 'admin';
      final name = email.contains('pkay')
          ? 'គក់ ស្រីផ្កាយ'
          : (email.contains('daly') ? 'គុយ ដាលី' : 'នី បញ្ញា');

      final profile = UserModel(
        id: uid,
        name: name,
        role: role,
        active: true,
      );

      await FirestoreCollections.users.doc(uid).set(profile);
      return profile;
    } catch (e) {
      // Allow demo sign-in for classroom presentation if offline or Firebase Auth throws
      final role = (email.contains('cashier') || email.contains('pkay') || email.contains('daly'))
          ? 'cashier'
          : 'admin';
      final name = email.contains('pkay')
          ? 'គក់ ស្រីផ្កាយ'
          : (email.contains('daly') ? 'គុយ ដាលី' : 'នី បញ្ញា');

      return UserModel(
        id: 'demo-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        role: role,
        active: true,
      );
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
