import 'package:cloud_firestore/cloud_firestore.dart';

class DailyCloseModel {
  final String id;
  final String cashierId;
  final DateTime openedAt;
  final DateTime? closedAt;
  final int openingCash; // int Riel
  final int totalSales; // int Riel
  final int salesCount;
  final int? actualCash; // int Riel
  final int? difference; // int Riel

  DailyCloseModel({
    required this.id,
    required this.cashierId,
    required this.openedAt,
    this.closedAt,
    required this.openingCash,
    this.totalSales = 0,
    this.salesCount = 0,
    this.actualCash,
    this.difference,
  });

  factory DailyCloseModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    return DailyCloseModel(
      id: snapshot.id,
      cashierId: data?['cashierId']?.toString() ?? '',
      openedAt: (data?['openedAt'] is Timestamp)
          ? (data!['openedAt'] as Timestamp).toDate()
          : DateTime.now(),
      closedAt: (data?['closedAt'] is Timestamp)
          ? (data!['closedAt'] as Timestamp).toDate()
          : null,
      openingCash: (data?['openingCash'] is num) ? (data!['openingCash'] as num).toInt() : 0,
      totalSales: (data?['totalSales'] is num) ? (data!['totalSales'] as num).toInt() : 0,
      salesCount: (data?['salesCount'] is num) ? (data!['salesCount'] as num).toInt() : 0,
      actualCash: (data?['actualCash'] is num) ? (data!['actualCash'] as num).toInt() : null,
      difference: (data?['difference'] is num) ? (data!['difference'] as num).toInt() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'cashierId': cashierId,
      'openedAt': Timestamp.fromDate(openedAt),
      if (closedAt != null) 'closedAt': Timestamp.fromDate(closedAt!),
      'openingCash': openingCash,
      'totalSales': totalSales,
      'salesCount': salesCount,
      if (actualCash != null) 'actualCash': actualCash,
      if (difference != null) 'difference': difference,
    };
  }
}
