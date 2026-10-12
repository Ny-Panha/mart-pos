import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/firestore/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/firestore/shop_scope.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    final repo = ref.watch(authRepositoryProvider);
    try {
      final user = await repo.getCurrentUserProfile();
      ShopScope.setUser(user);
      return user;
    } catch (_) {
      ShopScope.setUser(null);
      return null;
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signIn(email: email, password: password);
      ShopScope.setUser(user);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> bootstrapFirstManager({
    required String email,
    required String password,
    required String name,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .bootstrapFirstManager(email: email, password: password, name: name);
      ShopScope.setUser(user);
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
    ShopScope.setUser(null);
    state = const AsyncValue.data(null);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(
  AuthNotifier.new,
);
