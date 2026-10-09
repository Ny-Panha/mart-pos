import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/utils/money.dart';
import '../firestore/firestore_collections.dart';
import '../firestore/models/purchase_model.dart';
import '../firestore/models/stock_movement_model.dart';
import '../services/audit_service.dart';

class PurchaseRepository {
  final FirebaseFirestore _db = FirestoreCollections.db;

  /// Pure helper for calculating total purchase cost in Riel.
  static int calculateTotalCost(List<PurchaseItem> items) {
    return items.fold<int>(0, (total, item) => total + (item.qty * item.costPrice));
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
        throw ArgumentError('Quantity must be greater than zero for item "${item.name}"');
      }
      if (item.costPrice < 0) {
        throw ArgumentError('Cost price must be non-negative for item "${item.name}"');
      }
    }
  }

  /// Watch purchases stream (orderBy createdAt desc, limit 100)
  Stream<List<PurchaseModel>> watchPurchases() {
    return FirestoreCollections.purchases
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => d.data()).toList())
        .handleError((error) {
          debugPrint('watchPurchases error: $error');
          return <PurchaseModel>[];
        });
  }

  /// Watch purchases stream for a specific supplier
  Stream<List<PurchaseModel>> watchPurchasesBySupplier(String supplierId) {
    return FirestoreCollections.purchases
        .where('supplierId', isEqualTo: supplierId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => d.data()).toList())
        .handleError((error) {
          debugPrint('watchPurchasesBySupplier error: $error');
          return <PurchaseModel>[];
        });
  }

  /// Create a purchase in ONE WriteBatch (offline-safe):
  /// 1. For each item: increment products.stockQty, update products.costPrice, update updatedAt
  /// 2. For each item: create stockMovements doc (type: "in", refId: purchaseId)
  /// 3. Create purchases doc
  Future<String> createPurchase({
    required String supplierId,
    required List<PurchaseItem> items,
    String? note,
    required String userId,
    String? userName,
  }) async {
    // 1. Verify supplier exists and is active
    final supplierDoc = await FirestoreCollections.suppliers.doc(supplierId).get();
    if (!supplierDoc.exists || supplierDoc.data() == null) {
      throw Exception('Supplier not found');
    }
    final supplier = supplierDoc.data()!;

    // 2. Validate input guards
    validatePurchaseInput(
      isSupplierActive: supplier.active,
      items: items,
    );

    final totalCost = calculateTotalCost(items);
    final now = DateTime.now();

    final batch = _db.batch();
    final purchaseRef = FirestoreCollections.purchases.doc();
    final purchaseId = purchaseRef.id;

    // 3. Update products and stock movements for each item
    for (final item in items) {
      // 3.1 Increment stock and update cost price on product doc
      final productRef = FirestoreCollections.products.doc(item.productId);
      batch.update(productRef, {
        'stockQty': FieldValue.increment(item.qty),
        'costPrice': item.costPrice,
        'updatedAt': Timestamp.now(),
      });

      // 3.2 Create stock movement doc (type "in")
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

    // 4. Create purchase document
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

    // 5. Commit batch atomically
    await batch.commit();

    // Fire-and-forget Audit Log
    AuditService.log(
      userId: userId,
      userName: userName ?? 'User $userId',
      action: 'purchase.create',
      entityType: 'purchase',
      entityId: purchaseId,
      details: '${supplier.name} · ${items.length} items · ${MoneyUtils.formatRiel(totalCost)}',
    );

    return purchaseId;
  }
}
