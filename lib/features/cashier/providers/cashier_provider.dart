import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/firestore/models/product_model.dart';
import '../../../data/firestore/models/sale_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/cashier_service.dart';

final cashierServiceProvider = Provider<CashierService>(
  (ref) => CashierService(),
);

final cashierSalesProvider = StreamProvider<List<SaleModel>>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return Stream.value(const <SaleModel>[]);
  return ref.watch(cashierServiceProvider).watchOwnSales(user);
});

final cashierStockProvider = StreamProvider<List<ProductModel>>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return Stream.value(const <ProductModel>[]);
  return ref.watch(cashierServiceProvider).watchStock(user);
});

class CashierSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String value) => state = value;
}

final cashierSearchProvider = NotifierProvider<CashierSearchNotifier, String>(
  CashierSearchNotifier.new,
);

final filteredCashierSalesProvider = Provider<List<SaleModel>>((ref) {
  final sales = ref.watch(cashierSalesProvider).value ?? const <SaleModel>[];
  final query = ref.watch(cashierSearchProvider).trim().toLowerCase();
  if (query.isEmpty) return sales;
  return sales
      .where((sale) => sale.invoiceNumber.toLowerCase().contains(query))
      .toList();
});

final filteredCashierStockProvider = Provider<List<ProductModel>>((ref) {
  final products =
      ref.watch(cashierStockProvider).value ?? const <ProductModel>[];
  final query = ref.watch(cashierSearchProvider).trim().toLowerCase();
  if (query.isEmpty) return products;
  return products
      .where(
        (product) =>
            product.name.toLowerCase().contains(query) ||
            product.barcode.toLowerCase().contains(query) ||
            product.sku.toLowerCase().contains(query) ||
            product.code.toLowerCase().contains(query),
      )
      .toList();
});
