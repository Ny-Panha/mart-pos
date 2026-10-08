import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/firestore/models/supplier_model.dart';
import '../../../data/repositories/supplier_repository.dart';

final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  return SupplierRepository();
});

final suppliersStreamProvider = StreamProvider<List<SupplierModel>>((ref) {
  final repo = ref.watch(supplierRepositoryProvider);
  return repo.watchSuppliers();
});

class SupplierSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final supplierSearchQueryProvider =
    NotifierProvider<SupplierSearchQueryNotifier, String>(SupplierSearchQueryNotifier.new);

final filteredSuppliersProvider = Provider<List<SupplierModel>>((ref) {
  final suppliers = ref.watch(suppliersStreamProvider).value ?? [];
  final query = ref.watch(supplierSearchQueryProvider).trim().toLowerCase();

  if (query.isEmpty) return suppliers;

  return suppliers.where((s) {
    final nameMatch = s.name.toLowerCase().contains(query);
    final phoneMatch = s.phone?.toLowerCase().contains(query) ?? false;
    final addressMatch = s.address?.toLowerCase().contains(query) ?? false;
    return nameMatch || phoneMatch || addressMatch;
  }).toList();
});

final activeSuppliersProvider = Provider<List<SupplierModel>>((ref) {
  final suppliers = ref.watch(suppliersStreamProvider).value ?? [];
  return suppliers.where((s) => s.active).toList();
});
