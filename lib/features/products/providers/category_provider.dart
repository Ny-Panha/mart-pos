import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/firestore/models/category_model.dart';
import '../../../data/repositories/category_repository.dart';

import '../../auth/providers/auth_provider.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

final categoriesStreamProvider = StreamProvider<List<CategoryModel>>((ref) {
  ref.watch(authProvider);
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchCategories();
});
