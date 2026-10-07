import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String id;
  final String name;
  final String? phone;
  final int totalSpent; // Stored in int Riel
  final DateTime createdAt;

  CustomerModel({
    required this.id,
    required this.name,
    this.phone,
    this.totalSpent = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CustomerModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    return CustomerModel(
      id: snapshot.id,
      name: data?['name']?.toString() ?? '',
      phone: data?['phone']?.toString(),
      totalSpent: (data?['totalSpent'] is num) ? (data!['totalSpent'] as num).toInt() : 0,
      createdAt: (data?['createdAt'] is Timestamp)
          ? (data!['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      if (phone != null) 'phone': phone,
      'totalSpent': totalSpent,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
