import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../firestore/firestore_collections.dart';
import '../firestore/models/stock_movement_model.dart';

class InventoryRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Pure helper for adjustment diff calculation (tested in unit tests)
  static int calculateAdjustmentDiff({required int currentQty, required int newQty}) {
    return newQty - currentQty;
  }

  /// Stream stock movements, optionally filtered by productId. Limit to latest 100 entries.
  Stream<List<StockMovementModel>> watchStockMovements({String? productId}) {
    Query<StockMovementModel> query = FirestoreCollections.stockMovements;

    if (productId != null && productId.isNotEmpty && productId != 'all') {
      query = query.where('productId', isEqualTo: productId);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList())
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
  }) async {
    if (qty <= 0) {
      throw ArgumentError('Stock In quantity must be greater than zero.');
    }

    final batch = _db.batch();

    // 1. Increment product stock
    final productDocRef = _db.collection('products').doc(productId);
    batch.update(productDocRef, {
      'stockQty': FieldValue.increment(qty),
      'updatedAt': Timestamp.now(),
    });

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
  }

  /// Stock Out: For damage, loss, or waste (offline-safe WriteBatch)
  Future<void> stockOut({
    required String productId,
    required int currentQty,
    required int qty,
    required String note,
    required String userId,
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
    batch.update(productDocRef, {
      'stockQty': FieldValue.increment(-qty),
      'updatedAt': Timestamp.now(),
    });

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
  }

  /// Adjust Stock: Reconcile physical inventory count (offline-safe WriteBatch)
  Future<void> adjustStock({
    required String productId,
    required int currentQty,
    required int newQty,
    required String note,
    required String userId,
  }) async {
    if (newQty < 0) {
      throw ArgumentError('New stock quantity cannot be negative.');
    }
    if (note.trim().isEmpty) {
      throw ArgumentError('A reason note is required for Stock Adjustment.');
    }

    final diff = calculateAdjustmentDiff(currentQty: currentQty, newQty: newQty);

    final batch = _db.batch();

    // 1. Set explicit new stockQty
    final productDocRef = _db.collection('products').doc(productId);
    batch.update(productDocRef, {
      'stockQty': newQty,
      'updatedAt': Timestamp.now(),
    });

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
  }
}
