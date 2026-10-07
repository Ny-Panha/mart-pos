import 'cart_item_model.dart';

class SaleModel {
  final String id;
  final String invoiceNo;
  String get invoiceNumber => invoiceNo;
  final String cashierName;
  final List<CartItemModel> items;
  final double subtotalUSD;
  final double discountUSD;
  final double taxUSD;
  final double totalUSD;
  final double totalKHR;
  final String paymentMethod; // 'CASH_USD', 'CASH_KHR', 'KHQR'
  final double cashReceived;
  final double changeGiven;
  final String customerName;
  final int redeemedPoints;
  final DateTime createdAt;

  SaleModel({
    required this.id,
    required this.invoiceNo,
    required this.cashierName,
    required this.items,
    required this.subtotalUSD,
    required this.discountUSD,
    this.taxUSD = 0.0,
    required this.totalUSD,
    required this.totalKHR,
    required this.paymentMethod,
    required this.cashReceived,
    required this.changeGiven,
    this.customerName = 'អតិថិជនទូទៅ',
    this.redeemedPoints = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNo': invoiceNo,
      'cashierName': cashierName,
      'items': items.map((i) => i.toMap()).toList(),
      'subtotalUSD': subtotalUSD,
      'discountUSD': discountUSD,
      'taxUSD': taxUSD,
      'totalUSD': totalUSD,
      'totalKHR': totalKHR,
      'paymentMethod': paymentMethod,
      'cashReceived': cashReceived,
      'changeGiven': changeGiven,
      'customerName': customerName,
      'redeemedPoints': redeemedPoints,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SaleModel.fromMap(Map<String, dynamic> map, String docId) {
    var rawItems = map['items'] as List<dynamic>? ?? [];
    List<CartItemModel> parsedItems = rawItems
        .map((item) => CartItemModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    return SaleModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      invoiceNo: map['invoiceNo'] ?? 'INV-0000',
      cashierName: map['cashierName'] ?? 'Cashier',
      items: parsedItems,
      subtotalUSD: (map['subtotalUSD'] is num) ? (map['subtotalUSD'] as num).toDouble() : 0.0,
      discountUSD: (map['discountUSD'] is num) ? (map['discountUSD'] as num).toDouble() : 0.0,
      taxUSD: (map['taxUSD'] is num) ? (map['taxUSD'] as num).toDouble() : 0.0,
      totalUSD: (map['totalUSD'] is num) ? (map['totalUSD'] as num).toDouble() : 0.0,
      totalKHR: (map['totalKHR'] is num) ? (map['totalKHR'] as num).toDouble() : 0.0,
      paymentMethod: map['paymentMethod'] ?? 'CASH_USD',
      cashReceived: (map['cashReceived'] is num) ? (map['cashReceived'] as num).toDouble() : 0.0,
      changeGiven: (map['changeGiven'] is num) ? (map['changeGiven'] as num).toDouble() : 0.0,
      customerName: map['customerName'] ?? 'អតិថិជនទូទៅ',
      redeemedPoints: (map['redeemedPoints'] is num) ? (map['redeemedPoints'] as num).toInt() : 0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
