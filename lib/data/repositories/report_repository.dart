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

  static int _toInt(dynamic v, [int fallback = 0]) {
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v?.toString() ?? '') ??
        double.tryParse(v?.toString() ?? '')?.round() ??
        fallback;
  }

  static SaleModel _saleFromOrderJson(Map<String, dynamic> map) {
    final rawItems = map['items'] is List ? (map['items'] as List) : const [];
    final items = rawItems.whereType<Map>().map((item) {
      final qty = _toInt(item['qty'] ?? item['quantity'], 1);
      final unitPrice = _toInt(
        item['sale_price'] ?? item['unit_price'] ?? item['unitPrice'],
      );
      final totalPrice = _toInt(
        item['subtotal'] ?? item['total_price'] ?? item['totalPrice'],
        unitPrice * qty,
      );
      return SaleItem(
        productId: (item['product_id'] ?? item['productId'] ?? '').toString(),
        name: (item['product_name'] ?? item['name'] ?? 'Item').toString(),
        qty: qty,
        unitPrice: unitPrice,
        totalPrice: totalPrice,
      );
    }).toList();

    final cashierObj = map['cashier'];
    final cashierName = cashierObj is Map
        ? cashierObj['name']?.toString()
        : map['cashier_name']?.toString();
    final discount = _toInt(map['discount_riel'] ?? map['discount']);
    final totalTax = _toInt(
      map['tax_riel'] ?? map['tax'] ?? map['total_tax'] ?? map['totalTax'],
    );
    final total = _toInt(map['total_riel'] ?? map['total']);
    final itemsSubtotal = items.fold<int>(0, (acc, i) => acc + i.totalPrice);
    final subtotal = _toInt(
      map['subtotal'],
      itemsSubtotal > 0 ? itemsSubtotal : (total + discount - totalTax),
    );
    final paidAmount = _toInt(
      map['received_riel'] ?? map['paid_amount'] ?? map['paidAmount'],
    );
    final changeAmount = _toInt(
      map['change_riel'] ?? map['change_amount'] ?? map['changeAmount'],
    );

    return SaleModel(
      id: (map['id'] ?? '').toString(),
      invoiceNumber:
          (map['invoice_number'] ?? map['invoiceNumber'] ?? 'INV-${map['id']}')
              .toString(),
      cashierId: (map['cashier_id'] ?? map['cashierId'] ?? '').toString(),
      cashierName: cashierName,
      customerId: (map['customer_id'] ?? map['customerId'])?.toString(),
      items: items,
      subtotal: subtotal,
      discount: discount,
      totalTax: totalTax,
      total: total,
      paidAmount: paidAmount,
      changeAmount: changeAmount,
      paymentMethod:
          (map['payment_method'] ?? map['paymentMethod'] ?? 'cash').toString(),
      paymentStatus:
          (map['payment_status'] ?? map['paymentStatus'] ?? 'paid').toString(),
      createdAt:
          DateTime.tryParse(
            (map['created_at'] ?? map['createdAt'] ?? '').toString(),
          )?.toLocal() ??
          DateTime.now(),
    );
  }

  Future<List<SaleModel>?> _fetchApiOrders() async {
    try {
      final res = await ApiService.get('/orders');
      if (res != null && res['success'] == true && res['data'] is List) {
        return (res['data'] as List)
            .whereType<Map>()
            .map((e) => _saleFromOrderJson(Map<String, dynamic>.from(e)))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    } catch (e) {
      debugPrint('ReportRepository._fetchApiOrders fallback: $e');
    }
    return null;
  }

  /// Watch sales within a specific date range
  Stream<List<SaleModel>> watchSalesRange(DateTime start, DateTime end) async* {
    final apiOrders = await _fetchApiOrders();
    if (apiOrders != null) {
      yield apiOrders.where((s) =>
        (s.createdAt.isAfter(start) || s.createdAt.isAtSameMomentAs(start)) &&
        (s.createdAt.isBefore(end) || s.createdAt.isAtSameMomentAs(end))
      ).toList();
      return;
    }

    yield* ShopScope.query(FirestoreCollections.sales)
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
  Stream<List<SaleModel>> watchAllRecentSales({int limit = 200}) async* {
    final apiOrders = await _fetchApiOrders();
    if (apiOrders != null) {
      yield apiOrders.length > limit ? apiOrders.sublist(0, limit) : apiOrders;
      return;
    }

    yield* ShopScope.query(FirestoreCollections.sales)
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
