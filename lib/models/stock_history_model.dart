class StockHistoryModel {
  final String id;
  final String productId;
  final String productName;
  final int changeQty; // positive or negative
  final String reason; // 'expired', 'damaged', 'lost', 'physical_count_correction', 'return_from_customer', 'stock_in'
  final DateTime createdAt;
  final String cashierName;

  StockHistoryModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.changeQty,
    required this.reason,
    required this.createdAt,
    required this.cashierName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'changeQty': changeQty,
      'reason': reason,
      'createdAt': createdAt.toIso8601String(),
      'cashierName': cashierName,
    };
  }

  factory StockHistoryModel.fromMap(Map<String, dynamic> map, String docId) {
    return StockHistoryModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      changeQty: (map['changeQty'] is num) ? (map['changeQty'] as num).toInt() : 0,
      reason: map['reason'] ?? 'physical_count_correction',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      cashierName: map['cashierName'] ?? 'Admin',
    );
  }
}
