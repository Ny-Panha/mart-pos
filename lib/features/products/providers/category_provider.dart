import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/firestore/models/category_model.dart';
import '../../../data/repositories/category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

final categoriesStreamProvider = StreamProvider<List<CategoryModel>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchCategories();
});
