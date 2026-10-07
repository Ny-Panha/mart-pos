class ProductModel {
  final String id;
  final String barcode;
  final String sku;
  final String name;
  final String category;
  final double costPrice;
  final double sellingPrice;
  final int stockQty;
  final String unit;
  final String icon;
  final String? imageUrl;

  ProductModel({
    required this.id,
    required this.barcode,
    this.sku = '',
    required this.name,
    required this.category,
    required this.costPrice,
    required this.sellingPrice,
    required this.stockQty,
    this.unit = 'កំប៉ុង',
    this.icon = 'inventory_2',
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'sku': sku,
      'name': name,
      'category': category,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'stockQty': stockQty,
      'unit': unit,
      'icon': icon,
      'imageUrl': imageUrl,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String docId) {
    return ProductModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      barcode: map['barcode']?.toString() ?? '',
      sku: map['sku']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? 'ភេសជ្ជៈ',
      costPrice: (map['costPrice'] is num) ? (map['costPrice'] as num).toDouble() : 0.0,
      sellingPrice: (map['sellingPrice'] is num) ? (map['sellingPrice'] as num).toDouble() : 0.0,
      stockQty: (map['stockQty'] is num) ? (map['stockQty'] as num).toInt() : 0,
      unit: map['unit']?.toString() ?? 'កំប៉ុង',
      icon: map['icon']?.toString() ?? 'inventory_2',
      imageUrl: map['imageUrl']?.toString(),
    );
  }

  int get stock => stockQty;
  double get sellPrice => sellingPrice;
  bool get isOutOfStock => stockQty <= 0;
  bool get isLowStock => stockQty > 0 && stockQty <= 10;

  ProductModel copyWith({
    String? id,
    String? barcode,
    String? sku,
    String? name,
    String? category,
    double? costPrice,
    double? sellingPrice,
    int? stockQty,
    String? unit,
    String? icon,
    String? imageUrl,
  }) {
    return ProductModel(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      category: category ?? this.category,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stockQty: stockQty ?? this.stockQty,
      unit: unit ?? this.unit,
      icon: icon ?? this.icon,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
