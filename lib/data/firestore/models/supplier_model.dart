import 'package:cloud_firestore/cloud_firestore.dart';

class SupplierModel {
  final String id;
  final String name;
  final String? phone;
  final String? address;
  final String? note;
  final bool active;
  final DateTime createdAt;

  SupplierModel({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.note,
    this.active = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory SupplierModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    return SupplierModel(
      id: snapshot.id,
      name: data?['name']?.toString() ?? '',
      phone: data?['phone']?.toString(),
      address: data?['address']?.toString(),
      note: data?['note']?.toString(),
      active: data?['active'] ?? true,
      createdAt: (data?['createdAt'] is Timestamp)
          ? (data!['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      if (phone != null && phone!.trim().isNotEmpty) 'phone': phone!.trim(),
      if (address != null && address!.trim().isNotEmpty) 'address': address!.trim(),
      if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
      'active': active,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  SupplierModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? note,
    bool? active,
    DateTime? createdAt,
  }) {
    return SupplierModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      note: note ?? this.note,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
