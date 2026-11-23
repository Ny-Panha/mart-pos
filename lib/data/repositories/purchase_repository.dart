import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/utils/money.dart';
import '../firestore/firestore_collections.dart';
import '../firestore/models/purchase_model.dart';
import '../firestore/models/stock_movement_model.dart';
import '../services/api_service.dart';
import '../services/audit_service.dart';
import '../firestore/shop_scope.dart';

class PurchaseRepository {
  final FirebaseFirestore _db = FirestoreCollections.db;

  /// Pure helper for calculating total purchase cost in Riel.
  static int calculateTotalCost(List<PurchaseItem> items) {
    return items.fold<int>(
      0,
      (total, item) => total + (item.qty * item.costPrice),
    );
  }

  /// Pure helper for validating purchase input guards.
  static void validatePurchaseInput({
    required bool isSupplierActive,
    required List<PurchaseItem> items,
  }) {
    if (!isSupplierActive) {
      throw ArgumentError('Supplier must exist and be active');
    }
    if (items.isEmpty) {
      throw ArgumentError('Purchase items cannot be empty');
    }
    for (final item in items) {
      if (item.productId.trim().isEmpty) {
        throw ArgumentError('Product ID cannot be empty');
      }
      if (item.qty <= 0) {
        throw ArgumentError(
          'Quantity must be greater than zero for item "${item.name}"',
        );
      }
      if (item.costPrice < 0) {
        throw ArgumentError(
          'Cost price must be non-negative for item "${item.name}"',
        );
      }
    }
  }

  /// Watch purchases stream (orderBy createdAt desc, limit 100)
  Stream<List<PurchaseModel>> watchPurchases() {
    return ShopScope.query(FirestoreCollections.purchases)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((d) => d.data()).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        })
        .handleError((error) {
          debugPrint('watchPurchases error: $error');
          return <PurchaseModel>[];
        });
  }

  /// Watch purchases stream for a specific supplier
  Stream<List<PurchaseModel>> watchPurchasesBySupplier(String supplierId) {
    return ShopScope.query(FirestoreCollections.purchases)
        .where('supplierId', isEqualTo: supplierId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((d) => d.data()).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        })
        .handleError((error) {
          debugPrint('watchPurchasesBySupplier error: $error');
          return <PurchaseModel>[];
        });
  }

  /// Authoritative Purchase:
  /// 1. Updates stock quantities and cost prices in Laravel API (MySQL authoritative).
  /// 2. Propagates any backend failure immediately to caller.
  /// 3. Records confirmed purchase and movements in Firestore cache.
  Future<String> createPurchase({
    required String supplierId,
    required List<PurchaseItem> items,
    String? note,
    required String userId,
    String? userName,
  }) async {
    // 1. Verify supplier exists and is active
    final supplierDoc = await FirestoreCollections.suppliers
        .doc(supplierId)
        .get();
    if (!supplierDoc.exists || supplierDoc.data() == null) {
      throw Exception('Supplier not found');
    }
    final supplier = supplierDoc.data()!;

    // 2. Validate input guards
    validatePurchaseInput(isSupplierActive: supplier.active, items: items);

    // 3. Prepare payload for Laravel API
    final backendItems = items.map((item) {
      final pId = int.tryParse(item.productId);
      if (pId == null || pId <= 0) {
        throw Exception(
          'Invalid Product ID "${item.productId}" for "${item.name}". An authoritative MySQL Product ID is required.',
        );
      }
      return {
        'product_id': pId,
        'qty': item.qty,
        'cost_price': item.costPrice,
      };
    }).toList();

    // 4. Authoritative request to Laravel API
    final res = await ApiService.post('/inventory/purchase', {
      'supplier_name': supplier.name,
      'supplier_id': supplierId,
      'note': note?.trim().isEmpty ?? true ? null : note!.trim(),
      'items': backendItems,
    });

    if (res == null || res['success'] != true) {
      final msg = res?['message'] ?? 'Purchase creation failed on backend.';
      throw Exception(msg);
    }

    final totalCost = calculateTotalCost(items);
    final now = DateTime.now();
    final purchaseRef = FirestoreCollections.purchases.doc();
    final purchaseId = purchaseRef.id;

    // 5. Update products and stock movements in Firestore cache
    try {
      final batch = _db.batch();
      for (final item in items) {
        final productRef = FirestoreCollections.products.doc(item.productId);
        batch.set(productRef, {
          'stockQty': FieldValue.increment(item.qty),
          'costPrice': item.costPrice,
          'updatedAt': Timestamp.now(),
        }, SetOptions(merge: true));

        final movementRef = FirestoreCollections.stockMovements.doc();
        final movement = StockMovementModel(
          id: movementRef.id,
          productId: item.productId,
          type: 'in',
          qty: item.qty,
          note: 'Purchase from ${supplier.name}',
          refId: purchaseId,
          createdBy: userId,
          createdAt: now,
        );
        batch.set(movementRef, movement);
      }

      final purchase = PurchaseModel(
        id: purchaseId,
        supplierId: supplierId,
        supplierName: supplier.name,
        items: items,
        totalCost: totalCost,
        note: note?.trim().isEmpty ?? true ? null : note!.trim(),
        createdBy: userId,
        createdAt: now,
      );
      batch.set(purchaseRef, purchase);
      await batch.commit();
    } catch (e) {
      debugPrint('Firestore purchase cache update notice: $e');
    }

    // Fire-and-forget Audit Log
    AuditService.log(
      userId: userId,
      userName: userName ?? 'User $userId',
      action: 'purchase.create',
      entityType: 'purchase',
      entityId: purchaseId,
      details:
          '${supplier.name} · ${items.length} items · ${MoneyUtils.formatRiel(totalCost)}',
    );

    return purchaseId;
  }
}
