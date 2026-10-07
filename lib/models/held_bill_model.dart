import 'cart_item_model.dart';

class HeldBillModel {
  final String id;
  final String cashierId;
  final List<CartItemModel> items;
  final String? note;
  final DateTime createdAt;

  HeldBillModel({
    required this.id,
    required this.cashierId,
    required this.items,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cashierId': cashierId,
      'items': items.map((i) => i.toMap()).toList(),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HeldBillModel.fromMap(Map<String, dynamic> map, String docId) {
    return HeldBillModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      cashierId: map['cashierId'] ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => CartItemModel.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      note: map['note'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
