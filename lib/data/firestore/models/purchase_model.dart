import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseItem {
  final String productId;
  final String name; // snapshot of product name at purchase time
  final int qty;
  final int costPrice; // in Riel

  const PurchaseItem({
    required this.productId,
    required this.name,
    required this.qty,
    required this.costPrice,
  });

  int get subtotal => qty * costPrice;

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      productId: map['productId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      qty: (map['qty'] is num) ? (map['qty'] as num).toInt() : 0,
      costPrice: (map['costPrice'] is num) ? (map['costPrice'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'qty': qty,
      'costPrice': costPrice,
    };
  }

  PurchaseItem copyWith({
    String? productId,
    String? name,
    int? qty,
    int? costPrice,
  }) {
    return PurchaseItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      qty: qty ?? this.qty,
      costPrice: costPrice ?? this.costPrice,
    );
  }
}

class PurchaseModel {
  final String id;
  final String supplierId;
  final String supplierName; // snapshot of supplier name at purchase time
  final List<PurchaseItem> items;
  final int totalCost; // sum of qty * costPrice in Riel
  final String? note;
  final String createdBy; // uid
  final DateTime createdAt;

  PurchaseModel({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.items,
    required this.totalCost,
    this.note,
    required this.createdBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory PurchaseModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    final rawItems = (data?['items'] is List) ? (data!['items'] as List) : [];
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(PurchaseItem.fromMap)
        .toList();

    return PurchaseModel(
      id: snapshot.id,
      supplierId: data?['supplierId']?.toString() ?? '',
      supplierName: data?['supplierName']?.toString() ?? '',
      items: items,
      totalCost: (data?['totalCost'] is num) ? (data!['totalCost'] as num).toInt() : 0,
      note: data?['note']?.toString(),
      createdBy: data?['createdBy']?.toString() ?? 'System',
      createdAt: (data?['createdAt'] is Timestamp)
          ? (data!['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'supplierId': supplierId,
      'supplierName': supplierName,
      'items': items.map((i) => i.toMap()).toList(),
      'totalCost': totalCost,
      if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  PurchaseModel copyWith({
    String? id,
    String? supplierId,
    String? supplierName,
    List<PurchaseItem>? items,
    int? totalCost,
    String? note,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return PurchaseModel(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      items: items ?? this.items,
      totalCost: totalCost ?? this.totalCost,
      note: note ?? this.note,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
