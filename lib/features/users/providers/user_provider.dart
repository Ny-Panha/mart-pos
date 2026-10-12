import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/firestore/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final usersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.watchUsers();
});

class UserSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final userSearchQueryProvider =
    NotifierProvider<UserSearchQueryNotifier, String>(
      UserSearchQueryNotifier.new,
    );

final filteredUsersProvider = Provider<List<UserModel>>((ref) {
  final users = ref.watch(usersStreamProvider).value ?? [];
  final query = ref.watch(userSearchQueryProvider).trim().toLowerCase();

  final staff = users.where((user) => user.isCashier).toList();
  if (query.isEmpty) return staff;

  return staff.where((u) {
    return u.name.toLowerCase().contains(query) ||
        u.id.toLowerCase().contains(query) ||
        u.role.toLowerCase().contains(query);
  }).toList();
});
