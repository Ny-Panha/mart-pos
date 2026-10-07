import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/firestore/models/product_model.dart';
import '../../../data/firestore/models/stock_movement_model.dart';
import '../../../data/repositories/inventory_repository.dart';
import '../../products/providers/product_provider.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository();
});

class InventoryProductFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setFilter(String productId) => state = productId;
}

final inventoryProductFilterProvider =
    NotifierProvider<InventoryProductFilterNotifier, String>(
  InventoryProductFilterNotifier.new,
);

final stockMovementsProvider = StreamProvider<List<StockMovementModel>>((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  final filter = ref.watch(inventoryProductFilterProvider);
  return repo.watchStockMovements(productId: filter == 'all' ? null : filter);
});

final lowStockProductsProvider = Provider<List<ProductModel>>((ref) {
  final productsAsync = ref.watch(productsStreamProvider);
  return productsAsync.when(
    data: (products) => products.where((p) => p.isLowStock || p.isOutOfStock).toList(),
    loading: () => [],
    error: (_, _) => [],
  );
});
