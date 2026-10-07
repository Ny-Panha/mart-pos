class ShiftModel {
  final String id;
  final String cashierName;
  final DateTime openedAt;
  final DateTime? closedAt;
  final double openingCash;
  final double totalSales;
  final double countedCash;
  final double difference; // countedCash - (openingCash + totalSales)
  final String note;
  final bool isClosed;

  ShiftModel({
    required this.id,
    required this.cashierName,
    required this.openedAt,
    this.closedAt,
    this.openingCash = 50.0,
    this.totalSales = 0.0,
    this.countedCash = 0.0,
    this.difference = 0.0,
    this.note = '',
    this.isClosed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cashierName': cashierName,
      'openedAt': openedAt.toIso8601String(),
      'closedAt': closedAt?.toIso8601String(),
      'openingCash': openingCash,
      'totalSales': totalSales,
      'countedCash': countedCash,
      'difference': difference,
      'note': note,
      'isClosed': isClosed,
    };
  }

  factory ShiftModel.fromMap(Map<String, dynamic> map, String docId) {
    return ShiftModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      cashierName: map['cashierName'] ?? 'Cashier',
      openedAt: map['openedAt'] != null
          ? DateTime.tryParse(map['openedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      closedAt: map['closedAt'] != null
          ? DateTime.tryParse(map['closedAt'].toString())
          : null,
      openingCash: (map['openingCash'] is num) ? (map['openingCash'] as num).toDouble() : 50.0,
      totalSales: (map['totalSales'] is num) ? (map['totalSales'] as num).toDouble() : 0.0,
      countedCash: (map['countedCash'] is num) ? (map['countedCash'] as num).toDouble() : 0.0,
      difference: (map['difference'] is num) ? (map['difference'] as num).toDouble() : 0.0,
      note: map['note'] ?? '',
      isClosed: map['isClosed'] ?? false,
    );
  }
}
