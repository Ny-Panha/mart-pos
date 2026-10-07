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
