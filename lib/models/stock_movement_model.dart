class StockMovementModel {
  final String id;
  final String productId;
  final String type; // 'in', 'out', 'adjust'
  final int qty; // positive or negative int
  final String? note;
  final String? refId; // saleId or purchaseId
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
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'type': type,
      'qty': qty,
      'note': note,
      'refId': refId,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StockMovementModel.fromMap(Map<String, dynamic> map, String docId) {
    return StockMovementModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      productId: map['productId'] ?? '',
      type: map['type'] ?? 'adjust',
      qty: (map['qty'] is num) ? (map['qty'] as num).toInt() : 0,
      note: map['note'],
      refId: map['refId'],
      createdBy: map['createdBy'] ?? 'system',
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}
