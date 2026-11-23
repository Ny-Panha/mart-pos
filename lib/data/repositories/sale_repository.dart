import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../firestore/firestore_collections.dart';
import '../firestore/models/held_bill_model.dart';
import '../firestore/models/sale_model.dart';
import '../firestore/models/stock_movement_model.dart';
import '../firestore/shop_scope.dart';
import '../services/api_service.dart';

class SaleRepository {
  final FirebaseFirestore? _dbInstance;
  FirebaseFirestore get _db => _dbInstance ?? FirebaseFirestore.instance;

  SaleRepository({FirebaseFirestore? db}) : _dbInstance = db;

  Stream<List<SaleModel>> watchSales() {
    var query = ShopScope.query(FirestoreCollections.sales);
    if (ShopScope.isCashier && ShopScope.userId != null) {
      query = query.where('cashierId', isEqualTo: ShopScope.userId);
    }
    return query
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((d) => d.data()).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        })
        .handleError((error) {
          debugPrint('watchSales error: $error');
          return <SaleModel>[];
        });
  }

  /// Check existing operation with authoritative backend
  Future<Map<String, dynamic>?> checkOperationStatus(String operationId) async {
    try {
      final res = await ApiService.get('/orders/by-operation/$operationId');
      if (res != null && res['success'] == true && res['data'] != null) {
        return res['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('checkOperationStatus notice: $e');
    }
    return null;
  }

  /// Reconcile confirmed order into secondary Firestore cache idempotently
  Future<void> reconcileConfirmedOrder(Map<String, dynamic> serverOrder, SaleModel sale) async {
    try {
      final batch = _db.batch();

      final saleDocRef = FirestoreCollections.sales.doc(sale.id);
      final existingSale = await saleDocRef.get();
      final wasAlreadyConfirmed = existingSale.exists;

      final confirmedSale = (serverOrder['invoice_number'] != null && serverOrder['invoice_number'] != sale.invoiceNumber)
          ? SaleModel(
              id: sale.id,
              invoiceNumber: serverOrder['invoice_number'].toString(),
              cashierId: sale.cashierId,
              cashierName: sale.cashierName,
              customerId: sale.customerId,
              customerName: sale.customerName,
              items: sale.items,
              subtotal: sale.subtotal,
              discount: sale.discount,
              totalTax: sale.totalTax,
              total: sale.total,
              paidAmount: sale.paidAmount,
              changeAmount: sale.changeAmount,
              paymentMethod: sale.paymentMethod,
              paymentStatus: sale.paymentStatus,
              createdAt: sale.createdAt,
            )
          : sale;
      batch.set(saleDocRef, confirmedSale);

      // Record movement in Firestore idempotently with deterministic doc ID
      for (var item in sale.items) {
        final movementRef = FirestoreCollections.stockMovements.doc('${sale.id}_${item.productId}');
        final movement = StockMovementModel(
          id: movementRef.id,
          productId: item.productId,
          type: 'sale',
          qty: -item.qty,
          note: 'POS Sale: ${serverOrder['invoice_number'] ?? sale.invoiceNumber}',
          refId: sale.id,
          createdBy: sale.cashierId,
          createdAt: DateTime.now(),
        );
        batch.set(movementRef, movement);
      }

      // Customer spending: only increment if this sale was not already confirmed!
      if (!wasAlreadyConfirmed && sale.customerId != null && sale.customerId!.isNotEmpty) {
        final customerDocRef = _db.collection('customers').doc(sale.customerId);
        batch.set(customerDocRef, {
          'totalSpent': FieldValue.increment(sale.total),
        }, SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Firestore sale cache reconciliation notice: $e');
    }
  }

  /// Authoritative Checkout:
  /// 1. Validates Product IDs (never guesses or falls back to ID 1).
  /// 2. Performs authoritative checkout against Laravel REST API (MySQL).
  /// 3. Propagates all errors (insufficient stock, unauthorized, validation, network) to caller.
  /// 4. Once confirmed by MySQL, updates secondary cache in Firestore for reporting/offline view.
  Future<void> checkoutSale(SaleModel sale, {String? clientOperationId}) async {
    // 1. Explicit and validated product ID mapping
    final itemsPayload = <Map<String, dynamic>>[];
    for (final item in sale.items) {
      final prodId = int.tryParse(item.productId);
      if (prodId == null || prodId <= 0) {
        throw Exception(
          'Invalid product ID "${item.productId}" for "${item.name}". An authoritative MySQL Product ID is required.',
        );
      }
      itemsPayload.add({
        'product_id': prodId,
        'qty': item.qty,
        if (item.originalPrice != null && item.unitPrice != item.originalPrice)
          'custom_price': item.unitPrice,
      });
    }

    final rawOpId = clientOperationId ?? (sale.id.length >= 8 ? sale.id : 'op_sale_${sale.id}_${sale.invoiceNumber}');
    if (rawOpId.length < 8) {
      throw ArgumentError('client_operation_id must be at least 8 characters long.');
    }
    final opId = rawOpId;

    final payload = <String, dynamic>{
      'client_operation_id': opId,
      'invoice_number': sale.invoiceNumber,
      'items': itemsPayload,
      'discount_riel': sale.discount,
      'tax_riel': sale.totalTax,
      'total_riel': sale.total,
      'total_usd': (sale.total / 4100).toStringAsFixed(2),
      'received_riel': sale.paidAmount,
      'received_usd': '0.00',
      'change_riel': sale.changeAmount,
      'change_usd': '0.00',
      'payment_method': sale.paymentMethod == 'khqr'
          ? 'khqr'
          : (sale.paymentMethod == 'cash_usd' ? 'cash_usd' : 'cash_riel'),
      'notes': 'Invoice: ${sale.invoiceNumber}',
    };

    // 2. Authoritative request to Laravel REST API
    final res = await ApiService.post('/orders', payload);
    if (res == null || res['success'] != true) {
      final msg = res?['message'] ?? 'Authoritative checkout failed on server.';
      throw Exception(msg);
    }

    // 3. Update secondary cache in Firestore with confirmed status idempotently
    final serverOrder = (res['data'] is Map<String, dynamic>) ? res['data'] as Map<String, dynamic> : <String, dynamic>{};
    await reconcileConfirmedOrder(serverOrder, sale);
  }

  // Held Bills
  Stream<List<HeldBillModel>> watchHeldBills() {
    var query = ShopScope.query(FirestoreCollections.heldBills);
    if (ShopScope.isCashier && ShopScope.userId != null) {
      query = query.where('cashierId', isEqualTo: ShopScope.userId);
    }
    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => d.data()).toList());
  }

  Future<void> saveHeldBill(HeldBillModel heldBill) async {
    await FirestoreCollections.heldBills.doc(heldBill.id).set(heldBill);
  }

  Future<void> deleteHeldBill(String id) async {
    await FirestoreCollections.heldBills.doc(id).delete();
  }
}
