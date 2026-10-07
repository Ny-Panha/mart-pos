import 'package:cloud_firestore/cloud_firestore.dart';

class StockMovementModel {
  final String id;
  final String productId;
  final String type; // "in" | "out" | "adjust"
  final int qty;
  final String? note;
  final String? refId; // Reference to saleId or purchaseId
  final String createdBy;
  final DateTime createdAt;

  StockMovementModel({
    required this.id,
    required this.productId,
    required this.type,
    required this.qty,
    this.note,
    this.refId,
    required this.createdBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory StockMovementModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    return StockMovementModel(
      id: snapshot.id,
      productId: data?['productId']?.toString() ?? '',
      type: data?['type']?.toString() ?? 'out',
      qty: (data?['qty'] is num) ? (data!['qty'] as num).toInt() : 0,
      note: data?['note']?.toString(),
      refId: data?['refId']?.toString(),
      createdBy: data?['createdBy']?.toString() ?? 'System',
      createdAt: (data?['createdAt'] is Timestamp)
          ? (data!['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'type': type,
      'qty': qty,
      if (note != null) 'note': note,
      if (refId != null) 'refId': refId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
