import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../firestore/firestore_collections.dart';
import '../firestore/models/stock_movement_model.dart';
import '../firestore/shop_scope.dart';
import '../services/api_service.dart';
import '../services/audit_service.dart';

class InventoryRepository {
  final FirebaseFirestore? _dbInstance;
  FirebaseFirestore get _db => _dbInstance ?? FirebaseFirestore.instance;

  InventoryRepository({FirebaseFirestore? db}) : _dbInstance = db;

  /// Pure helper for adjustment diff calculation (tested in unit tests)
  static int calculateAdjustmentDiff({
    required int currentQty,
    required int newQty,
  }) {
    return newQty - currentQty;
  }

  /// Stream stock movements, optionally filtered by productId. Limit to latest 100 entries.
  Stream<List<StockMovementModel>> watchStockMovements({String? productId}) async* {
    List<StockMovementModel>? liveMovements;

    // 1. Try authoritative Laravel REST API first
    try {
      final endpoint = (productId != null && productId.isNotEmpty && productId != 'all')
          ? '/inventory/movements?product_id=$productId'
          : '/inventory/movements';
      final res = await ApiService.get(endpoint);
      if (res != null && res['success'] == true && res['data'] is List) {
        liveMovements = (res['data'] as List).map((raw) {
          final m = raw as Map<String, dynamic>;
          return StockMovementModel(
            id: (m['id'] ?? '').toString(),
            productId: (m['product_id'] ?? '').toString(),
            type: m['type']?.toString() ?? 'adjust',
            qty: (m['qty'] is num) ? (m['qty'] as num).toInt() : 0,
            note: m['note']?.toString(),
            refId: m['ref_id']?.toString(),
            createdBy: m['created_by']?.toString() ?? '',
            createdAt: m['created_at'] != null
                ? DateTime.tryParse(m['created_at'].toString()) ?? DateTime.now()
                : DateTime.now(),
          );
        }).toList();
        yield liveMovements;
      }
    } catch (e) {
      debugPrint('Laravel API movements notice (offline fallback): $e');
    }

    // 2. Fall back to Firestore cache if Laravel is unreachable
    if (liveMovements == null) {
      yield* ShopScope.query(FirestoreCollections.stockMovements)
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
  }

  /// Authoritative Stock In:
  /// 1. Updates stock in Laravel API (MySQL).
  /// 2. Propagates errors to UI.
  /// 3. Syncs movement to Firestore cache.
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

    final pId = int.tryParse(productId);
    if (pId == null || pId <= 0) {
      throw ArgumentError('Invalid product ID "$productId". Authoritative MySQL Product ID required.');
    }

    // 1. Authoritative mutation on Laravel API
    final opId = 'op_stockin_${productId}_${DateTime.now().millisecondsSinceEpoch}';
    final res = await ApiService.post('/inventory/stock-in', {
      'client_operation_id': opId,
      'product_id': pId,
      'qty': qty,
      'note': note?.trim().isEmpty ?? true ? null : note!.trim(),
    });

    if (res == null || res['success'] != true) {
      final msg = res?['message'] ?? 'Stock In failed on server.';
      throw Exception(msg);
    }

    // 2. Reconcile Firestore cache using server-confirmed stock quantity
    try {
      final batch = _db.batch();
      final productDocRef = _db.collection('products').doc(productId);
      final serverQty = res['data']?['product']?['stock_qty'];

      if (serverQty is num) {
        batch.set(productDocRef, {
          'stockQty': serverQty.toInt(),
          'updatedAt': Timestamp.now(),
        }, SetOptions(merge: true));
      } else {
        batch.set(productDocRef, {
          'stockQty': FieldValue.increment(qty),
          'updatedAt': Timestamp.now(),
        }, SetOptions(merge: true));
      }

      final movementRef = FirestoreCollections.stockMovements.doc(opId);
      final movement = StockMovementModel(
        id: movementRef.id,
        productId: productId,
        type: 'in',
        qty: qty,
        note: note?.trim().isEmpty ?? true ? null : note!.trim(),
        refId: opId,
        createdBy: userId,
        createdAt: DateTime.now(),
      );
      batch.set(movementRef, movement);
      await batch.commit();
    } catch (e) {
      debugPrint('Firestore stockIn cache notice: $e');
    }

    // Audit Log
    AuditService.log(
      userId: userId,
      userName: userName ?? 'User $userId',
      action: 'stock.in',
      entityType: 'product',
      entityId: productId,
      details: '${productName ?? "Product #$productId"} · +$qty',
    );
  }

  /// Authoritative Stock Out:
  /// 1. Verifies stock and decrements in Laravel API (MySQL).
  /// 2. Propagates insufficient stock errors to UI.
  /// 3. Syncs movement to Firestore cache.
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
    if (note.trim().isEmpty) {
      throw ArgumentError('A reason note is required for Stock Out.');
    }

    final pId = int.tryParse(productId);
    if (pId == null || pId <= 0) {
      throw ArgumentError('Invalid product ID "$productId". Authoritative MySQL Product ID required.');
    }

    // 1. Authoritative mutation on Laravel API
    final opId = 'op_stockout_${productId}_${DateTime.now().millisecondsSinceEpoch}';
    final res = await ApiService.post('/inventory/stock-out', {
      'client_operation_id': opId,
      'product_id': pId,
      'qty': qty,
      'note': note.trim(),
    });

    if (res == null || res['success'] != true) {
      final msg = res?['message'] ?? 'Stock Out failed on server.';
      throw Exception(msg);
    }

    // 2. Reconcile Firestore cache using server-confirmed stock quantity
    try {
      final batch = _db.batch();
      final productDocRef = _db.collection('products').doc(productId);
      final serverQty = res['data']?['product']?['stock_qty'];

      if (serverQty is num) {
        batch.set(productDocRef, {
          'stockQty': serverQty.toInt(),
          'updatedAt': Timestamp.now(),
        }, SetOptions(merge: true));
      } else {
        batch.set(productDocRef, {
          'stockQty': FieldValue.increment(-qty),
          'updatedAt': Timestamp.now(),
        }, SetOptions(merge: true));
      }

      final movementRef = FirestoreCollections.stockMovements.doc(opId);
      final movement = StockMovementModel(
        id: movementRef.id,
        productId: productId,
        type: 'out',
        qty: qty,
        note: note.trim(),
        refId: opId,
        createdBy: userId,
        createdAt: DateTime.now(),
      );
      batch.set(movementRef, movement);
      await batch.commit();
    } catch (e) {
      debugPrint('Firestore stockOut cache notice: $e');
    }

    // Audit Log
    AuditService.log(
      userId: userId,
      userName: userName ?? 'User $userId',
      action: 'stock.out',
      entityType: 'product',
      entityId: productId,
      details: '${productName ?? "Product #$productId"} · -$qty',
    );
  }

  /// Authoritative Adjust Stock:
  /// 1. Updates stock count in Laravel API (MySQL).
  /// 2. Propagates errors to UI.
  /// 3. Syncs adjustment to Firestore cache.
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

    final pId = int.tryParse(productId);
    if (pId == null || pId <= 0) {
      throw ArgumentError('Invalid product ID "$productId". Authoritative MySQL Product ID required.');
    }

    final diff = calculateAdjustmentDiff(
      currentQty: currentQty,
      newQty: newQty,
    );

    // 1. Authoritative mutation on Laravel API
    final opId = 'op_adjust_${productId}_${DateTime.now().millisecondsSinceEpoch}';
    final res = await ApiService.post('/inventory/adjust', {
      'client_operation_id': opId,
      'product_id': pId,
      'new_qty': newQty,
      'note': note.trim(),
    });

    if (res == null || res['success'] != true) {
      final msg = res?['message'] ?? 'Stock Adjustment failed on server.';
      throw Exception(msg);
    }

    // 2. Reconcile Firestore cache using server-confirmed stock quantity
    try {
      final batch = _db.batch();
      final productDocRef = _db.collection('products').doc(productId);
      batch.set(productDocRef, {
        'stockQty': newQty,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));

      final movementRef = FirestoreCollections.stockMovements.doc(opId);
      final movement = StockMovementModel(
        id: movementRef.id,
        productId: productId,
        type: 'adjust',
        qty: diff,
        note: note.trim(),
        refId: opId,
        createdBy: userId,
        createdAt: DateTime.now(),
      );
      batch.set(movementRef, movement);
      await batch.commit();
    } catch (e) {
      debugPrint('Firestore adjustStock cache notice: $e');
    }

    final diffSign = diff >= 0 ? '+$diff' : '$diff';
    // Audit Log
    AuditService.log(
      userId: userId,
      userName: userName ?? 'User $userId',
      action: 'stock.adjust',
      entityType: 'product',
      entityId: productId,
      details: '${productName ?? "Product #$productId"} · $diffSign (to $newQty)',
    );
  }
}
