import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../firestore/firestore_collections.dart';
import '../firestore/models/stock_movement_model.dart';
import '../firestore/shop_scope.dart';
import '../services/audit_service.dart';

class InventoryRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Pure helper for adjustment diff calculation (tested in unit tests)
  static int calculateAdjustmentDiff({
    required int currentQty,
    required int newQty,
  }) {
    return newQty - currentQty;
  }

  /// Stream stock movements, optionally filtered by productId. Limit to latest 100 entries.
  Stream<List<StockMovementModel>> watchStockMovements({String? productId}) {
    return ShopScope.query(FirestoreCollections.stockMovements)
        .snapshots()
        .map((snapshot) {
          var list = snapshot.docs.map((doc) => doc.data()).toList();
          if (productId != null && productId.isNotEmpty && productId != 'all') {
            list = list.where((m) => m.productId == productId).toList();
          }
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (list.length > 100) {
            return list.sublist(0, 100);
          }
          return list;
        })
        .handleError((error) {
          debugPrint('watchStockMovements error: $error');
          return <StockMovementModel>[];
        });
  }

  /// Stock In: WriteBatch increment stockQty and create movement record (offline-safe)
  Future<void> stockIn({
    required String productId,
    required int qty,
    String? note,
    required String userId,
    String? productName,
    String? userName,
  }) async {
    if (qty <= 0) {
      throw ArgumentError('Stock In quantity must be greater than zero.');
    }

    final batch = _db.batch();

    // 1. Increment product stock
    final productDocRef = _db.collection('products').doc(productId);
    batch.set(productDocRef, {
      'stockQty': FieldValue.increment(qty),
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));

    // 2. Add stock movement doc
    final movementRef = FirestoreCollections.stockMovements.doc();
    final movement = StockMovementModel(
      id: movementRef.id,
      productId: productId,
      type: 'in',
      qty: qty,
      note: note?.trim().isEmpty ?? true ? null : note!.trim(),
      createdBy: userId,
      createdAt: DateTime.now(),
    );
    batch.set(movementRef, movement);

    await batch.commit();

    // Fire-and-forget Audit Log
    AuditService.log(
      userId: userId,
      userName: userName ?? 'User $userId',
      action: 'stock.in',
      entityType: 'product',
      entityId: productId,
      details: '${productName ?? "Product #$productId"} · +$qty',
    );
  }

  /// Stock Out: For damage, loss, or waste (offline-safe WriteBatch)
  Future<void> stockOut({
    required String productId,
    required int currentQty,
    required int qty,
    required String note,
    required String userId,
    String? productName,
    String? userName,
  }) async {
    if (qty <= 0) {
      throw ArgumentError('Stock Out quantity must be greater than zero.');
    }
    if (qty > currentQty) {
      throw ArgumentError(
        'Cannot remove $qty units. Available stock is only $currentQty units.',
      );
    }
    if (note.trim().isEmpty) {
      throw ArgumentError('A reason note is required for Stock Out.');
    }

    final batch = _db.batch();

    // 1. Decrement product stock
    final productDocRef = _db.collection('products').doc(productId);
    batch.set(productDocRef, {
      'stockQty': FieldValue.increment(-qty),
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));

    // 2. Add stock movement doc
    final movementRef = FirestoreCollections.stockMovements.doc();
    final movement = StockMovementModel(
      id: movementRef.id,
      productId: productId,
      type: 'out',
      qty: qty,
      note: note.trim(),
      createdBy: userId,
      createdAt: DateTime.now(),
    );
    batch.set(movementRef, movement);

    await batch.commit();

    // Fire-and-forget Audit Log
    AuditService.log(
      userId: userId,
      userName: userName ?? 'User $userId',
      action: 'stock.out',
      entityType: 'product',
      entityId: productId,
      details: '${productName ?? "Product #$productId"} · -$qty',
    );
  }

  /// Adjust Stock: Reconcile physical inventory count (offline-safe WriteBatch)
  Future<void> adjustStock({
    required String productId,
    required int currentQty,
    required int newQty,
    required String note,
    required String userId,
    String? productName,
    String? userName,
  }) async {
    if (newQty < 0) {
      throw ArgumentError('New stock quantity cannot be negative.');
    }
    if (note.trim().isEmpty) {
      throw ArgumentError('A reason note is required for Stock Adjustment.');
    }

    final diff = calculateAdjustmentDiff(
      currentQty: currentQty,
      newQty: newQty,
    );

    final batch = _db.batch();

    // 1. Set explicit new stockQty
    final productDocRef = _db.collection('products').doc(productId);
    batch.set(productDocRef, {
      'stockQty': newQty,
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));

    // 2. Add stock movement doc with diff as qty
    final movementRef = FirestoreCollections.stockMovements.doc();
    final movement = StockMovementModel(
      id: movementRef.id,
      productId: productId,
      type: 'adjust',
      qty: diff,
      note: note.trim(),
      createdBy: userId,
      createdAt: DateTime.now(),
    );
    batch.set(movementRef, movement);

    await batch.commit();

    final diffSign = diff >= 0 ? '+$diff' : '$diff';
    // Fire-and-forget Audit Log
    AuditService.log(
      userId: userId,
      userName: userName ?? 'User $userId',
      action: 'stock.adjust',
      entityType: 'product',
      entityId: productId,
      details:
          '${productName ?? "Product #$productId"} · $diffSign (to $newQty)',
    );
  }
}
