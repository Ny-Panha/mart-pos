import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/firestore/models/category_model.dart';
import '../../../data/repositories/category_repository.dart';

import '../../auth/providers/auth_provider.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  ref.watch(authProvider);
  return CategoryRepository();
});

final categoriesStreamProvider = StreamProvider<List<CategoryModel>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  // Riverpod retains this session's labels while the screen is unobserved.
  // Reconcile them with Laravel when the view becomes active again.
  final age = Stopwatch()..start();
  ref.onResume(() {
    if (age.elapsed >= const Duration(seconds: 30)) {
      age.reset();
      repo.refreshCategories();
    }
  });
  return repo.watchCategories();
});
