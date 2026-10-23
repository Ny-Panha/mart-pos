import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  static const String adminManagerRole = 'ADMIN_MANAGER';
  static const String adminRole = 'ADMIN';
  static const String cashierRole = 'CASHIER';
  static const String defaultShopId = 'default-shop';

  final String id; // auth uid
  final String name;
  final String? email;
  final String role; // ADMIN_MANAGER | ADMIN | CASHIER
  final String? shopId; // null only for platform managers
  final bool active;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    this.email,
    required this.role,
    this.shopId,
    this.active = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get normalizedRole {
    return normalizeRole(role);
  }

  bool get isManager => normalizedRole == adminManagerRole;
  bool get isAdmin => normalizedRole == adminRole;
  bool get isCashier => normalizedRole == cashierRole;
  bool get canManageShop => isAdmin || isManager;

  static String normalizeRole(String value) {
    final normalized = value.trim().toUpperCase();
    if (normalized == 'MANAGER' || normalized == 'SUPER') {
      return adminManagerRole;
    }
    return normalized;
  }

  static String? shopIdForProfile({required String role, String? shopId}) {
    if (shopId != null && shopId.isNotEmpty) return shopId;
    return normalizeRole(role) == adminManagerRole ? null : defaultShopId;
  }

  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    return UserModel(
      id: snapshot.id,
      name: data?['name']?.toString() ?? '',
      email: data?['email']?.toString(),
      role: normalizeRole(data?['role']?.toString() ?? cashierRole),
      shopId: shopIdForProfile(
        role: data?['role']?.toString() ?? cashierRole,
        shopId: data?['shopId']?.toString(),
      ),
      active: data?['active'] ?? true,
      createdAt: (data?['createdAt'] is Timestamp)
          ? (data!['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final roleStr = json['role']?.toString() ?? cashierRole;
    return UserModel(
      id: (json['id'] ?? '').toString(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      role: normalizeRole(roleStr),
      shopId: shopIdForProfile(
        role: roleStr,
        shopId: json['shop_id']?.toString() ?? json['shopId']?.toString(),
      ),
      active: (json['status'] == 'active') || (json['active'] ?? true),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': normalizedRole,
      'shop_id': shopId,
      'active': active,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      if (email != null && email!.isNotEmpty) 'email': email,
      'role': normalizedRole,
      if (shopId != null) 'shopId': shopId,
      'active': active,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? shopId,
    bool? active,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      shopId: shopId ?? this.shopId,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
