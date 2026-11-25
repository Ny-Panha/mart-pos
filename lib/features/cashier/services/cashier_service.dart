import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../data/firestore/firestore_collections.dart';
import '../../../data/firestore/models/product_model.dart';
import '../../../data/firestore/models/sale_model.dart';
import '../../../data/firestore/models/user_model.dart';
import '../../../data/firestore/shop_scope.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/services/api_service.dart';

class CashierService {
  final ProductRepository _productRepo = ProductRepository();

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

  Query<SaleModel> _salesQuery(UserModel user) {
    return ShopScope.query(
      FirestoreCollections.sales,
    ).where('cashierId', isEqualTo: user.id).limit(200);
  }

  Stream<List<SaleModel>> watchOwnSales(UserModel user) async* {
    try {
      final res = await ApiService.get('/orders');
      if (res != null && res['success'] == true && res['data'] is List) {
        final list = (res['data'] as List)
            .whereType<Map>()
            .map((e) => _saleFromOrderJson(Map<String, dynamic>.from(e)))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        yield list;
        return;
      }
    } catch (e) {
      debugPrint('CashierService.watchOwnSales API fallback: $e');
    }

    yield* _salesQuery(user)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) => doc.data()).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        })
        .handleError((error) {
          debugPrint('CashierService.watchOwnSales Firestore notice: $error');
          return <SaleModel>[];
        });
  }

  Stream<List<ProductModel>> watchStock(UserModel user) {
    return _productRepo.watchProducts();
  }

  Future<SaleModel?> findOwnSale(UserModel user, String saleId) async {
    try {
      final res = await ApiService.get('/orders');
      if (res != null && res['success'] == true && res['data'] is List) {
        for (final raw in (res['data'] as List).whereType<Map>()) {
          final sale = _saleFromOrderJson(Map<String, dynamic>.from(raw));
          if (sale.id == saleId || sale.invoiceNumber == saleId) {
            return sale;
          }
        }
      }
    } catch (e) {
      debugPrint('CashierService.findOwnSale API fallback: $e');
    }

    final snapshot = await _salesQuery(user).get();
    for (final doc in snapshot.docs) {
      if (doc.id == saleId || doc.data().invoiceNumber == saleId) {
        return doc.data();
      }
    }
    return null;
  }
}
