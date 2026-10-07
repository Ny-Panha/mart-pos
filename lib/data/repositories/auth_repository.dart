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

    final doc = await FirestoreCollections.users.doc(user.uid).get();
    if (!doc.exists || doc.data() == null) {
      throw Exception('Account not set up — contact admin');
    }

    final profile = doc.data()!;
    if (!profile.active) {
      await signOut();
      throw Exception('Account deactivated');
    }

    return profile;
  }

  Future<UserModel> signIn({required String email, required String password}) async {
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
    if (!profile.active) {
      await _auth.signOut();
      throw Exception('Account deactivated');
    }

    return profile;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
