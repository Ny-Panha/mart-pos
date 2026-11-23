import 'package:flutter/foundation.dart';

import '../firestore/firestore_collections.dart';
import '../firestore/models/product_model.dart';
import '../firestore/models/sale_model.dart';
import '../firestore/shop_scope.dart';
import '../services/api_service.dart';

class ReportRepository {
  /// Fetch authoritative sales and profit summary from Laravel/MySQL backend
  Future<Map<String, dynamic>?> getAuthoritativeSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String>[];
      if (startDate != null) {
        queryParams.add('start_date=${startDate.toIso8601String().substring(0, 10)}');
      }
      if (endDate != null) {
        queryParams.add('end_date=${endDate.toIso8601String().substring(0, 10)}');
      }
      final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      final res = await ApiService.get('/reports/summary$queryString');
      if (res != null && res['success'] == true && res['data'] != null) {
        return res['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('ReportRepository.getAuthoritativeSummary notice: $e');
    }
    return null;
  }

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
