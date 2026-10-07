import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id; // auth uid
  final String name;
  final String role; // 'admin' | 'cashier'
  final bool active;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.role,
    this.active = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isCashier => role.toLowerCase() == 'cashier';

  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    return UserModel(
      id: snapshot.id,
      name: data?['name']?.toString() ?? '',
      role: data?['role']?.toString().toLowerCase() ?? 'cashier',
      active: data?['active'] ?? true,
      createdAt: (data?['createdAt'] is Timestamp)
          ? (data!['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'role': role.toLowerCase(),
      'active': active,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? role,
    bool? active,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
