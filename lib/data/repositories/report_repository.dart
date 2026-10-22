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
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((d) => d.data()).toList();
          final filtered = list.where((s) =>
            (s.createdAt.isAfter(start) || s.createdAt.isAtSameMomentAs(start)) &&
            (s.createdAt.isBefore(end) || s.createdAt.isAtSameMomentAs(end))
          ).toList();
          filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return filtered;
        })
        .handleError((error) {
          debugPrint('watchSalesRange error: $error');
          return <SaleModel>[];
        });
  }

  /// Watch latest recent sales (default 200) for general dashboard and reporting
  Stream<List<SaleModel>> watchAllRecentSales({int limit = 200}) {
    return ShopScope.query(FirestoreCollections.sales)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((d) => d.data()).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (list.length > limit) {
            return list.sublist(0, limit);
          }
          return list;
        })
        .handleError((error) {
          debugPrint('watchAllRecentSales error: $error');
          return <SaleModel>[];
        });
  }
}
