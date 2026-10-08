import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/firestore/models/purchase_model.dart';
import '../../../data/repositories/purchase_repository.dart';

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  return PurchaseRepository();
});

final purchasesStreamProvider = StreamProvider<List<PurchaseModel>>((ref) {
  final repo = ref.watch(purchaseRepositoryProvider);
  return repo.watchPurchases();
});

final purchasesBySupplierProvider =
    StreamProvider.family<List<PurchaseModel>, String>((ref, supplierId) {
  final repo = ref.watch(purchaseRepositoryProvider);
  return repo.watchPurchasesBySupplier(supplierId);
});

class PurchaseSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final purchaseSearchQueryProvider =
    NotifierProvider<PurchaseSearchQueryNotifier, String>(PurchaseSearchQueryNotifier.new);

final filteredPurchasesProvider = Provider<List<PurchaseModel>>((ref) {
  final purchases = ref.watch(purchasesStreamProvider).value ?? [];
  final query = ref.watch(purchaseSearchQueryProvider).trim().toLowerCase();

  if (query.isEmpty) return purchases;

  return purchases.where((p) {
    final supplierMatch = p.supplierName.toLowerCase().contains(query);
    final idMatch = p.id.toLowerCase().contains(query);
    final itemMatch = p.items.any((i) => i.name.toLowerCase().contains(query));
    return supplierMatch || idMatch || itemMatch;
  }).toList();
});
