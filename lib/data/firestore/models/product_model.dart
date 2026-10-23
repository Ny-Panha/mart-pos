import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String code; // Unique via productCodes collection
  final String barcode;
  final String sku;
  final String categoryId;
  final int costPrice; // Stored as int (Riel)
  final int salePrice; // Stored as int (Riel)
  final int stockQty;
  final String unit;
  final int lowStockThreshold; // default 5
  final double tax; // default 0
  final String status; // "active" | "inactive"
  final String? imageUrl;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.code,
    this.barcode = '',
    this.sku = '',
    required this.categoryId,
    required this.costPrice,
    required this.salePrice,
    required this.stockQty,
    this.unit = 'កំប៉ុង',
    this.lowStockThreshold = 5,
    this.tax = 0.0,
    this.status = 'active',
    this.imageUrl,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  bool get isOutOfStock => stockQty <= 0;
  bool get isLowStock => stockQty > 0 && stockQty <= lowStockThreshold;
  bool get isActive => status == 'active';

  factory ProductModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    return ProductModel(
      id: snapshot.id,
      name: data?['name']?.toString() ?? '',
      code: data?['code']?.toString() ?? '',
      barcode: data?['barcode']?.toString() ?? '',
      sku: data?['sku']?.toString() ?? '',
      categoryId: data?['categoryId']?.toString() ?? '',
      costPrice: (data?['costPrice'] is num) ? (data!['costPrice'] as num).toInt() : 0,
      salePrice: (data?['salePrice'] is num) ? (data!['salePrice'] as num).toInt() : 0,
      stockQty: (data?['stockQty'] is num) ? (data!['stockQty'] as num).toInt() : 0,
      unit: data?['unit']?.toString() ?? 'កំប៉ុង',
      lowStockThreshold: (data?['lowStockThreshold'] is num)
          ? (data!['lowStockThreshold'] as num).toInt()
          : 5,
      tax: (data?['tax'] is num) ? (data!['tax'] as num).toDouble() : 0.0,
      status: data?['status']?.toString() ?? 'active',
      imageUrl: (data?['imageUrl'] != null && data!['imageUrl'].toString().trim().isNotEmpty)
          ? data['imageUrl'].toString().trim()
          : null,
      updatedAt: (data?['updatedAt'] is Timestamp)
          ? (data!['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: (json['id'] ?? '').toString(),
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      categoryId: (json['category_id'] ?? json['categoryId'] ?? (json['category'] != null ? json['category']['slug'] : '') ?? '').toString(),
      costPrice: json['cost_price'] is num
          ? (json['cost_price'] as num).toInt()
          : (json['costPrice'] is num
              ? (json['costPrice'] as num).toInt()
              : int.tryParse((json['cost_price'] ?? json['costPrice'] ?? 0).toString()) ?? 0),
      salePrice: json['sale_price'] is num
          ? (json['sale_price'] as num).toInt()
          : (json['salePrice'] is num
              ? (json['salePrice'] as num).toInt()
              : int.tryParse((json['sale_price'] ?? json['salePrice'] ?? 0).toString()) ?? 0),
      stockQty: json['stock_qty'] is num
          ? (json['stock_qty'] as num).toInt()
          : (json['stockQty'] is num
              ? (json['stockQty'] as num).toInt()
              : int.tryParse((json['stock_qty'] ?? json['stockQty'] ?? 0).toString()) ?? 0),
      unit: json['unit']?.toString() ?? 'កំប៉ុង',
      lowStockThreshold: json['low_stock_threshold'] is num
          ? (json['low_stock_threshold'] as num).toInt()
          : (json['lowStockThreshold'] is num
              ? (json['lowStockThreshold'] as num).toInt()
              : int.tryParse((json['low_stock_threshold'] ?? json['lowStockThreshold'] ?? 5).toString()) ?? 5),
      tax: json['tax'] is num
          ? (json['tax'] as num).toDouble()
          : double.tryParse(json['tax']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString() ?? 'active',
      imageUrl: (json['image_url'] ?? json['imageUrl'])?.toString().trim().isNotEmpty == true
          ? (json['image_url'] ?? json['imageUrl']).toString().trim()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'barcode': barcode,
      'sku': sku,
      'category_id': int.tryParse(categoryId) ?? categoryId,
      'cost_price': costPrice,
      'sale_price': salePrice,
      'stock_qty': stockQty,
      'unit': unit,
      'low_stock_threshold': lowStockThreshold,
      'tax': tax,
      'status': status,
      if (imageUrl != null && imageUrl!.trim().isNotEmpty)
        'image_url': imageUrl!.trim(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'code': code,
      'barcode': barcode,
      'sku': sku,
      'categoryId': categoryId,
      'costPrice': costPrice,
      'salePrice': salePrice,
      'stockQty': stockQty,
      'unit': unit,
      'lowStockThreshold': lowStockThreshold,
      'tax': tax,
      'status': status,
      if (imageUrl != null && imageUrl!.trim().isNotEmpty)
        'imageUrl': imageUrl!.trim(),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? code,
    String? barcode,
    String? sku,
    String? categoryId,
    int? costPrice,
    int? salePrice,
    int? stockQty,
    String? unit,
    int? lowStockThreshold,
    double? tax,
    String? status,
    String? imageUrl,
    bool clearImageUrl = false,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      barcode: barcode ?? this.barcode,
      sku: sku ?? this.sku,
      categoryId: categoryId ?? this.categoryId,
      costPrice: costPrice ?? this.costPrice,
      salePrice: salePrice ?? this.salePrice,
      stockQty: stockQty ?? this.stockQty,
      unit: unit ?? this.unit,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      tax: tax ?? this.tax,
      status: status ?? this.status,
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
