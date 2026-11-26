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

  /// Watch purchases stream from authoritative Laravel API (with Firestore fallback).
  Stream<List<PurchaseModel>> watchPurchases() async* {
    try {
      final res = await ApiService.get('/inventory/purchases');
      if (res != null && res['success'] == true && res['data'] is List) {
        final list = (res['data'] as List).map((raw) {
          final m = Map<String, dynamic>.from(raw as Map);
          final rawItems = (m['items'] is List) ? m['items'] as List : const [];
          final items = rawItems.map((it) {
            final im = Map<String, dynamic>.from(it as Map);
            return PurchaseItem(
              productId: im['product_id']?.toString() ?? '',
              name: im['name']?.toString() ?? '',
              qty: (im['qty'] is num) ? (im['qty'] as num).toInt() : 0,
              costPrice: (im['cost_price'] is num) ? (im['cost_price'] as num).toInt() : 0,
            );
          }).toList();

          return PurchaseModel(
            id: m['id']?.toString() ?? '',
            supplierId: m['supplier_id']?.toString() ?? '',
            supplierName: m['supplier_name']?.toString() ?? 'Supplier',
            items: items,
            totalCost: (m['total_cost'] is num) ? (m['total_cost'] as num).toInt() : 0,
            note: m['note']?.toString(),
            createdBy: m['created_by']?.toString() ?? 'Admin',
            createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
          );
        }).toList();
        yield list;
        return;
      }
    } catch (e) {
      debugPrint('Laravel watchPurchases notice (fallback to Firestore): $e');
    }

    yield* ShopScope.query(FirestoreCollections.purchases)
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
    String? purchaseId,
    String? clientOperationId,
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

    final pId = purchaseId ?? FirestoreCollections.purchases.doc().id;
    final purchaseRef = FirestoreCollections.purchases.doc(pId);
    final opId = clientOperationId ?? 'op_po_$pId';

    // 4. Authoritative request to Laravel API with stable client_operation_id
    final res = await ApiService.post('/inventory/purchase', {
      'client_operation_id': opId,
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

    // 5. Update products and stock movements in Firestore cache idempotently
    try {
      final existingPurchase = await purchaseRef.get();
      final wasAlreadyRecorded = existingPurchase.exists;

      final confirmedProducts = <String, int>{};
      if (res['data']?['products'] is List) {
        for (final p in res['data']['products']) {
          if (p is Map && p['id'] != null && p['stock_qty'] != null) {
            confirmedProducts[p['id'].toString()] = (p['stock_qty'] as num).toInt();
          }
        }
      }

      final batch = _db.batch();
      for (final item in items) {
        final productRef = FirestoreCollections.products.doc(item.productId);
        final confirmedStock = confirmedProducts[item.productId];

        final updateData = <String, dynamic>{
          'costPrice': item.costPrice,
          'updatedAt': Timestamp.now(),
        };

        if (confirmedStock != null) {
          updateData['stockQty'] = confirmedStock;
        } else if (!wasAlreadyRecorded) {
          // Never use additive increment on a replayed / already-recorded purchase
          updateData['stockQty'] = FieldValue.increment(item.qty);
        }

        batch.set(productRef, updateData, SetOptions(merge: true));

        // Deterministic document ID to prevent duplicate stock movements on retry
        final movementRef = FirestoreCollections.stockMovements.doc('po_${pId}_${item.productId}');
        final movement = StockMovementModel(
          id: movementRef.id,
          productId: item.productId,
          type: 'in',
          qty: item.qty,
          note: 'Purchase from ${supplier.name}',
          refId: pId,
          createdBy: userId,
          createdAt: now,
        );
        batch.set(movementRef, movement);
      }

      final purchase = PurchaseModel(
        id: pId,
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
      entityId: pId,
      details:
          '${supplier.name} · ${items.length} items · ${MoneyUtils.formatRiel(totalCost)}',
    );

    return pId;
  }
}
