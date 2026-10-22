import 'package:cloud_firestore/cloud_firestore.dart';

class SaleItem {
  final String productId;
  final String name; // Name snapshot at time of purchase
  final int qty;
  final int unitPrice; // int Riel (actual price sold at)
  final int? originalPrice; // int Riel (standard price if modified)
  final int totalPrice; // int Riel
  final double tax;

  SaleItem({
    required this.productId,
    required this.name,
    required this.qty,
    required this.unitPrice,
    this.originalPrice,
    required this.totalPrice,
    this.tax = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'qty': qty,
      'unitPrice': unitPrice,
      if (originalPrice != null) 'originalPrice': originalPrice,
      'totalPrice': totalPrice,
      'tax': tax,
    };
  }

  factory SaleItem.fromMap(Map<dynamic, dynamic> map) {
    return SaleItem(
      productId: map['productId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      qty: (map['qty'] is num) ? (map['qty'] as num).toInt() : 1,
      unitPrice: (map['unitPrice'] is num) ? (map['unitPrice'] as num).toInt() : 0,
      originalPrice: (map['originalPrice'] is num) ? (map['originalPrice'] as num).toInt() : null,
      totalPrice: (map['totalPrice'] is num) ? (map['totalPrice'] as num).toInt() : 0,
      tax: (map['tax'] is num) ? (map['tax'] as num).toDouble() : 0.0,
    );
  }
}

class SaleModel {
  final String id;
  final String invoiceNumber;
  final String cashierId;
  final String? cashierName;
  final String? customerId;
  final String? customerName;
  final List<SaleItem> items;
  final int subtotal; // int Riel
  final int discount; // int Riel
  final int totalTax; // int Riel
  final int total; // int Riel
  final int paidAmount; // int Riel
  final int changeAmount; // int Riel
  final String paymentMethod; // "cash" | "khqr"
  final String paymentStatus; // "paid" | "due" | "partial"
  final DateTime createdAt;

  SaleModel({
    required this.id,
    required this.invoiceNumber,
    required this.cashierId,
    this.cashierName,
    this.customerId,
    this.customerName,
    required this.items,
    required this.subtotal,
    this.discount = 0,
    this.totalTax = 0,
    required this.total,
    required this.paidAmount,
    this.changeAmount = 0,
    this.paymentMethod = 'cash',
    this.paymentStatus = 'paid',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory SaleModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    try {
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

      return SaleModel(
        id: snapshot.id,
        invoiceNumber: data?['invoiceNumber']?.toString() ?? '',
        cashierId: data?['cashierId']?.toString() ?? '',
        cashierName: data?['cashierName']?.toString(),
        customerId: data?['customerId']?.toString(),
        customerName: data?['customerName']?.toString(),
        items: items,
        subtotal: (data?['subtotal'] is num) ? (data!['subtotal'] as num).toInt() : 0,
        discount: (data?['discount'] is num) ? (data!['discount'] as num).toInt() : 0,
        totalTax: (data?['totalTax'] is num) ? (data!['totalTax'] as num).toInt() : 0,
        total: (data?['total'] is num) ? (data!['total'] as num).toInt() : 0,
        paidAmount: (data?['paidAmount'] is num) ? (data!['paidAmount'] as num).toInt() : 0,
        changeAmount: (data?['changeAmount'] is num) ? (data!['changeAmount'] as num).toInt() : 0,
        paymentMethod: data?['paymentMethod']?.toString() ?? 'cash',
        paymentStatus: data?['paymentStatus']?.toString() ?? 'paid',
        createdAt: (data?['createdAt'] is Timestamp)
            ? (data!['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
    } catch (_) {
      return SaleModel(
        id: snapshot.id,
        invoiceNumber: snapshot.id,
        cashierId: '',
        items: const [],
        subtotal: 0,
        total: 0,
        paidAmount: 0,
      );
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'invoiceNumber': invoiceNumber,
      'cashierId': cashierId,
      if (cashierName != null) 'cashierName': cashierName,
      if (customerId != null) 'customerId': customerId,
      if (customerName != null) 'customerName': customerName,
      'items': items.map((i) => i.toMap()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'totalTax': totalTax,
      'total': total,
      'paidAmount': paidAmount,
      'changeAmount': changeAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
