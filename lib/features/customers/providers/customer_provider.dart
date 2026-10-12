import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/firestore/firestore_collections.dart';
import '../../../data/firestore/models/customer_model.dart';
import '../../../data/firestore/shop_scope.dart';

final customersStreamProvider = StreamProvider<List<CustomerModel>>((ref) {
  return ShopScope.query(FirestoreCollections.customers)
      .orderBy('name')
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.data()).toList());
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});

class CustomerRepository {
  /// Pure helper for customer deletion validation (tested in unit tests)
  static bool canDeleteCustomer({required bool hasSales}) {
    return !hasSales;
  }

  Future<CustomerModel> createCustomer({
    required String name,
    String? phone,
  }) async {
    final docRef = FirestoreCollections.customers.doc();
    final newCustomer = CustomerModel(
      id: docRef.id,
      name: name.trim(),
      phone: phone?.trim().isEmpty ?? true ? null : phone!.trim(),
      totalSpent: 0,
      createdAt: DateTime.now(),
    );
    await docRef.set(newCustomer, SetOptions(merge: true));
    return newCustomer;
  }

  Future<void> updateCustomer(
    String id, {
    required String name,
    String? phone,
  }) async {
    await FirestoreCollections.customers.doc(id).update({
      'name': name.trim(),
      'phone': phone?.trim().isEmpty ?? true ? null : phone!.trim(),
    });
  }

  Future<bool> isCustomerInUse(String customerId) async {
    final snap = await ShopScope.query(FirestoreCollections.sales)
        .where('customerId', isEqualTo: customerId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<void> deleteCustomer(String id) async {
    final inUse = await isCustomerInUse(id);
    if (!canDeleteCustomer(hasSales: inUse)) {
      throw Exception('Cannot delete customer with existing sales records.');
    }
    await FirestoreCollections.customers.doc(id).delete();
  }
}
