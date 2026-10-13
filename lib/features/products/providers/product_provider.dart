import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/firestore/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';

import '../../auth/providers/auth_provider.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

final productsStreamProvider = StreamProvider<List<ProductModel>>((ref) {
  ref.watch(authProvider);
  final repo = ref.watch(productRepositoryProvider);
  return repo.watchProducts();
});

class ProductSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final productSearchQueryProvider =
    NotifierProvider<ProductSearchQueryNotifier, String>(ProductSearchQueryNotifier.new);

class SelectedCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setCategory(String category) => state = category;
}

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, String>(SelectedCategoryNotifier.new);

final filteredProductsProvider = Provider<List<ProductModel>>((ref) {
  final productsAsync = ref.watch(productsStreamProvider);
  final query = ref.watch(productSearchQueryProvider).toLowerCase().trim();
  final category = ref.watch(selectedCategoryProvider);

  return productsAsync.when(
    data: (products) {
      return products.where((p) {
        final matchesQuery = query.isEmpty ||
            p.name.toLowerCase().contains(query) ||
            p.barcode.toLowerCase().contains(query) ||
            p.sku.toLowerCase().contains(query) ||
            p.code.toLowerCase().contains(query);

        final matchesCategory = category == 'all' || p.categoryId == category;

        return matchesQuery && matchesCategory;
      }).toList();
    },
    loading: () => [],
    error: (_, _) => [],
  );
});
