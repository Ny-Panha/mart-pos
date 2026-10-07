import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/firestore/firestore_collections.dart';
import '../../../data/firestore/models/customer_model.dart';

final customersStreamProvider = StreamProvider<List<CustomerModel>>((ref) {
  return FirestoreCollections.customers
      .orderBy('name')
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.data()).toList());
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});

class CustomerRepository {
  Future<CustomerModel> createCustomer({
    required String name,
    String? phone,
  }) async {
    final docRef = FirestoreCollections.customers.doc();
    final newCustomer = CustomerModel(
      id: docRef.id,
      name: name,
      phone: phone,
      totalSpent: 0,
      createdAt: DateTime.now(),
    );
    await docRef.set(newCustomer, SetOptions(merge: true));
    return newCustomer;
  }
}
