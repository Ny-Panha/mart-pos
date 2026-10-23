import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final int sortOrder;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    this.sortOrder = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CategoryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    return CategoryModel(
      id: snapshot.id,
      name: data?['name']?.toString() ?? '',
      sortOrder: (data?['sortOrder'] is num) ? (data!['sortOrder'] as num).toInt() : 0,
      createdAt: (data?['createdAt'] is Timestamp)
          ? (data!['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final nameKh = json['name_kh']?.toString();
    final nameEn = json['name']?.toString() ?? '';
    final displayName = (nameKh != null && nameKh.isNotEmpty) ? '$nameKh ($nameEn)' : nameEn;

    return CategoryModel(
      id: (json['id'] ?? '').toString(),
      name: displayName,
      sortOrder: (json['sortOrder'] ?? json['id'] ?? 0) is num
          ? (json['sortOrder'] ?? json['id'] as num).toInt()
          : int.tryParse((json['sortOrder'] ?? json['id'] ?? 0).toString()) ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sortOrder': sortOrder,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'sortOrder': sortOrder,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
