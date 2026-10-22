import 'package:cloud_firestore/cloud_firestore.dart';
import 'sale_model.dart';

class HeldBillModel {
  final String id;
  final String cashierId;
  final List<SaleItem> items;
  final String? note;
  final DateTime createdAt;

  HeldBillModel({
    required this.id,
    required this.cashierId,
    required this.items,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory HeldBillModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    final rawItems = (data?['items'] is List) ? (data!['items'] as List) : [];
    final items = <SaleItem>[];
    for (final raw in rawItems) {
      if (raw is Map) {
        try {
          items.add(SaleItem.fromMap(raw));
        } catch (_) {}
      }
    }

    return HeldBillModel(
      id: snapshot.id,
      cashierId: data?['cashierId']?.toString() ?? '',
      items: items,
      note: data?['note']?.toString(),
      createdAt: (data?['createdAt'] is Timestamp)
          ? (data!['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'cashierId': cashierId,
      'items': items.map((i) => i.toMap()).toList(),
      if (note != null) 'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
