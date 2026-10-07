class DailyCloseModel {
  final String id;
  final String cashierId;
  final DateTime openedAt;
  final DateTime? closedAt;
  final int openingCash; // int riel
  final int totalSales; // int riel
  final int salesCount;
  final int? actualCash; // int riel
  final int? difference; // int riel (+ or -)
  final String? note;

  DailyCloseModel({
    required this.id,
    required this.cashierId,
    required this.openedAt,
    this.closedAt,
    required this.openingCash,
    required this.totalSales,
    required this.salesCount,
    this.actualCash,
    this.difference,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cashierId': cashierId,
      'openedAt': openedAt.toIso8601String(),
      'closedAt': closedAt?.toIso8601String(),
      'openingCash': openingCash,
      'totalSales': totalSales,
      'salesCount': salesCount,
      'actualCash': actualCash,
      'difference': difference,
      'note': note,
    };
  }

  factory DailyCloseModel.fromMap(Map<String, dynamic> map, String docId) {
    return DailyCloseModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      cashierId: map['cashierId'] ?? '',
      openedAt: map['openedAt'] != null
          ? DateTime.tryParse(map['openedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      closedAt: map['closedAt'] != null
          ? DateTime.tryParse(map['closedAt'].toString())
          : null,
      openingCash: (map['openingCash'] is num) ? (map['openingCash'] as num).toInt() : 0,
      totalSales: (map['totalSales'] is num) ? (map['totalSales'] as num).toInt() : 0,
      salesCount: (map['salesCount'] is num) ? (map['salesCount'] as num).toInt() : 0,
      actualCash: (map['actualCash'] is num) ? (map['actualCash'] as num).toInt() : null,
      difference: (map['difference'] is num) ? (map['difference'] as num).toInt() : null,
      note: map['note'],
    );
  }
}
