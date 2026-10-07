import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;
  double discountPercentage; // e.g. 0.0 or 10.0

  CartItemModel({
    required this.product,
    this.quantity = 1,
    this.discountPercentage = 0.0,
  });

  double get unitPrice => product.sellingPrice;

  double get subtotal => unitPrice * quantity;

  double get discountAmount => subtotal * (discountPercentage / 100);

  double get total => subtotal - discountAmount;

  Map<String, dynamic> toMap() {
    return {
      'productId': product.id,
      'barcode': product.barcode,
      'name': product.name,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'discountPercentage': discountPercentage,
      'discountAmount': discountAmount,
      'total': total,
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      product: ProductModel(
        id: map['productId'] ?? '',
        barcode: map['barcode'] ?? '',
        name: map['name'] ?? '',
        category: 'ទូទៅ',
        costPrice: 0.0,
        sellingPrice: (map['unitPrice'] is num) ? (map['unitPrice'] as num).toDouble() : 0.0,
        stockQty: 0,
      ),
      quantity: (map['quantity'] is num) ? (map['quantity'] as num).toInt() : 1,
      discountPercentage: (map['discountPercentage'] is num) ? (map['discountPercentage'] as num).toDouble() : 0.0,
    );
  }
}
