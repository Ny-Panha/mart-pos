import 'package:flutter/foundation.dart';

import '../firestore/firestore_collections.dart';
import '../firestore/models/supplier_model.dart';
import '../firestore/shop_scope.dart';

class SupplierRepository {
  /// Pure helper for checking whether a supplier can be safely deactivated.
  /// Blocked if the supplier has any existing purchases.
  static bool canDeactivateSupplier({required int purchaseCount}) {
    return purchaseCount <= 0;
  }

  /// Watch suppliers stream: sorted active first, then alphabetically by name.
  Stream<List<SupplierModel>> watchSuppliers() {
    return ShopScope.query(FirestoreCollections.suppliers)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((d) => d.data()).toList();
          list.sort((a, b) {
            if (a.active != b.active) {
              return a.active ? -1 : 1;
            }
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
          return list;
        })
        .handleError((error) {
          debugPrint('watchSuppliers error: $error');
          return <SupplierModel>[];
        });
  }

  /// Fetch a single supplier by id
  Future<SupplierModel?> getSupplierById(String id) async {
    final doc = await FirestoreCollections.suppliers.doc(id).get();
    return doc.data();
  }

  /// Create a new supplier
  Future<String> createSupplier({
    required String name,
    String? phone,
    String? address,
    String? note,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError('Supplier name cannot be empty');
    }

    final docRef = FirestoreCollections.suppliers.doc();
    final supplier = SupplierModel(
      id: docRef.id,
      name: cleanName,
      phone: phone?.trim().isEmpty ?? true ? null : phone!.trim(),
      address: address?.trim().isEmpty ?? true ? null : address!.trim(),
      note: note?.trim().isEmpty ?? true ? null : note!.trim(),
      active: true,
      createdAt: DateTime.now(),
    );

    await docRef.set(supplier);
    return docRef.id;
  }

  /// Update an existing supplier
  Future<void> updateSupplier({
    required String id,
    required String name,
    String? phone,
    String? address,
    String? note,
    bool? active,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError('Supplier name cannot be empty');
    }

    final data = <String, dynamic>{
      'name': cleanName,
      'phone': phone?.trim().isEmpty ?? true ? null : phone!.trim(),
      'address': address?.trim().isEmpty ?? true ? null : address!.trim(),
      'note': note?.trim().isEmpty ?? true ? null : note!.trim(),
    };

    if (active != null) {
      data['active'] = active;
    }

    await FirestoreCollections.suppliers.doc(id).update(data);
  }

  /// Deactivate a supplier: blocked if any purchase has this supplierId
  Future<void> deactivateSupplier(String id) async {
    final purchaseSnap = await ShopScope.query(FirestoreCollections.purchases)
        .where('supplierId', isEqualTo: id)
        .limit(1)
        .get();

    if (!canDeactivateSupplier(purchaseCount: purchaseSnap.docs.length)) {
      throw Exception(
        'Cannot deactivate supplier with existing purchase history',
      );
    }

    await FirestoreCollections.suppliers.doc(id).update({'active': false});
  }

  /// Activate a supplier
  Future<void> activateSupplier(String id) async {
    await FirestoreCollections.suppliers.doc(id).update({'active': true});
  }
}
