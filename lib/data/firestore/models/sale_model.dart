import 'package:cloud_firestore/cloud_firestore.dart';

class SaleItem {
  final String productId;
  final String name; // Name snapshot at time of purchase
  final int qty;
  final int unitPrice; // int Riel
  final int totalPrice; // int Riel
  final double tax;

  SaleItem({
    required this.productId,
    required this.name,
    required this.qty,
    required this.unitPrice,
    required this.totalPrice,
    this.tax = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'qty': qty,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'tax': tax,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      productId: map['productId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      qty: (map['qty'] is num) ? (map['qty'] as num).toInt() : 1,
      unitPrice: (map['unitPrice'] is num) ? (map['unitPrice'] as num).toInt() : 0,
      totalPrice: (map['totalPrice'] is num) ? (map['totalPrice'] as num).toInt() : 0,
      tax: (map['tax'] is num) ? (map['tax'] as num).toDouble() : 0.0,
    );
  }
}

class SaleModel {
  final String id;
  final String invoiceNumber;
  final String cashierId;
  final String? customerId;
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
    this.customerId,
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
    final data = snapshot.data();
    final rawItems = (data?['items'] as List<dynamic>?) ?? [];

    return SaleModel(
      id: snapshot.id,
      invoiceNumber: data?['invoiceNumber']?.toString() ?? '',
      cashierId: data?['cashierId']?.toString() ?? '',
      customerId: data?['customerId']?.toString(),
      items: rawItems
          .map((item) => SaleItem.fromMap(item as Map<String, dynamic>))
          .toList(),
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
  }

  Map<String, dynamic> toFirestore() {
    return {
      'invoiceNumber': invoiceNumber,
      'cashierId': cashierId,
      if (customerId != null) 'customerId': customerId,
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
