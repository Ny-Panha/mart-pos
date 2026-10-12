import 'package:flutter/foundation.dart';

import '../firestore/firestore_collections.dart';
import '../firestore/models/product_model.dart';
import '../firestore/models/sale_model.dart';
import '../firestore/shop_scope.dart';

class ReportRepository {
  /// Pure profit calculation helper (tested in unit tests)
  /// profit = sale.total - Σ(item.qty * product.costPrice)
  static int calculateProfit({
    required List<SaleModel> sales,
    required Map<String, ProductModel> productsMap,
  }) {
    int totalProfit = 0;
    for (final sale in sales) {
      int saleCost = 0;
      for (final item in sale.items) {
        final product = productsMap[item.productId];
        final costPrice = product?.costPrice ?? 0;
        saleCost += costPrice * item.qty;
      }
      totalProfit += (sale.total - saleCost);
    }
    return totalProfit;
  }

  /// Watch sales within a specific date range
  Stream<List<SaleModel>> watchSalesRange(DateTime start, DateTime end) {
    return ShopScope.query(FirestoreCollections.sales)
        .where('createdAt', isGreaterThanOrEqualTo: start)
        .where('createdAt', isLessThanOrEqualTo: end)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => d.data()).toList())
        .handleError((error) {
          debugPrint('watchSalesRange error: $error');
          return <SaleModel>[];
        });
  }

  /// Watch latest recent sales (default 200) for general dashboard and reporting
  Stream<List<SaleModel>> watchAllRecentSales({int limit = 200}) {
    return ShopScope.query(FirestoreCollections.sales)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => d.data()).toList())
        .handleError((error) {
          debugPrint('watchAllRecentSales error: $error');
          return <SaleModel>[];
        });
  }
}
