import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/widgets/product_thumbnail.dart';
import '../firestore/firestore_collections.dart';
import '../firestore/models/product_code_model.dart';
import '../firestore/models/product_model.dart';
import '../firestore/shop_scope.dart';

class ProductRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _productCodeDocumentId(String code) =>
      '${ShopScope.requireShopId()}__${Uri.encodeComponent(code.trim().toUpperCase())}';

  final List<ProductModel> _fallbackProducts = [
    ProductModel(
      id: 'p1',
      code: 'PROD-001',
      barcode: '884000101',
      sku: 'COCA-330',
      name: 'Coca Cola 330ml',
      categoryId: 'cat_drinks',
      costPrice: 1600, // 1,600 ៛ ($0.39)
      salePrice: 2500, // 2,500 ៛ ($0.61)
      stockQty: 48,
      unit: 'កំប៉ុង',
      lowStockThreshold: 10,
      imageUrl: 'assets/products/coca_cola.jpg',
    ),
    ProductModel(
      id: 'p2',
      code: 'PROD-002',
      barcode: '884000102',
      sku: 'STING-330',
      name: 'Sting Energy Drink 330ml',
      categoryId: 'cat_drinks',
      costPrice: 1800,
      salePrice: 3000,
      stockQty: 36,
      unit: 'ដប',
      lowStockThreshold: 10,
      imageUrl: 'assets/products/sting_energy.jpg',
    ),
    ProductModel(
      id: 'p3',
      code: 'PROD-003',
      barcode: '884000103',
      sku: 'REDBULL-250',
      name: 'Red Bull Energy 250ml',
      categoryId: 'cat_drinks',
      costPrice: 2400,
      salePrice: 3600,
      stockQty: 24,
      unit: 'កំប៉ុង',
      lowStockThreshold: 10,
      imageUrl: 'assets/products/red_bull.jpg',
    ),
    ProductModel(
      id: 'p4',
      code: 'PROD-004',
      barcode: '884000104',
      sku: 'WATER-500',
      name: 'Angkor Puro Water 500ml',
      categoryId: 'cat_drinks',
      costPrice: 600,
      salePrice: 1500,
      stockQty: 80,
      unit: 'ដប',
      lowStockThreshold: 20,
      imageUrl: 'assets/products/angkor_water.jpg',
    ),
    ProductModel(
      id: 'p5',
      code: 'PROD-005',
      barcode: '884000201',
      sku: 'MAMA-TOMYUM',
      name: 'MAMA Noodles Tom Yum 60g',
      categoryId: 'cat_food',
      costPrice: 1200,
      salePrice: 2000,
      stockQty: 50,
      unit: 'កញ្ចប់',
      lowStockThreshold: 15,
      imageUrl: 'assets/products/mama_noodles.jpg',
    ),
    ProductModel(
      id: 'p6',
      code: 'PROD-006',
      barcode: '884000202',
      sku: 'OREO-120',
      name: 'Oreo Biscuits 120g',
      categoryId: 'cat_snacks',
      costPrice: 2800,
      salePrice: 4500,
      stockQty: 18,
      unit: 'ប្រអប់',
      lowStockThreshold: 5,
      imageUrl: 'assets/products/oreo_cookies.jpg',
    ),
    ProductModel(
      id: 'p7',
      code: 'PROD-007',
      barcode: '884000301',
      sku: 'COLGATE-150',
      name: 'Colgate Toothpaste 150g',
      categoryId: 'cat_daily',
      costPrice: 4800,
      salePrice: 7200,
      stockQty: 12,
      unit: 'ប្រអប់',
      lowStockThreshold: 5,
      imageUrl: 'assets/products/colgate_toothpaste.jpg',
    ),
    ProductModel(
      id: 'p8',
      code: 'PROD-008',
      barcode: '884000302',
      sku: 'LIFEBUOY-90',
      name: 'Lifebuoy Soap 90g',
      categoryId: 'cat_daily',
      costPrice: 1600,
      salePrice: 2800,
      stockQty: 4, // low stock test
      unit: 'ដុំ',
      lowStockThreshold: 5,
      imageUrl: 'assets/products/lifebuoy_soap.jpg',
    ),
  ];

  Stream<List<ProductModel>> watchProducts() {
    return ShopScope.query(FirestoreCollections.products)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            seedDefaultProducts();
            return _fallbackProducts;
          }
          final list = snapshot.docs.map((d) {
            final model = d.data();
            if (model.imageUrl == null ||
                model.imageUrl!.isEmpty ||
                model.imageUrl!.contains('unsplash.com')) {
              final local = ProductThumbnail.getAssetForProduct(
                id: model.id,
                name: model.name,
                barcode: model.barcode,
              );
              if (local != null) {
                return model.copyWith(imageUrl: local);
              }
            }
            return model;
          }).toList();
          return list;
        })
        .handleError((error) {
          debugPrint('Firestore watchProducts error: $error');
          return _fallbackProducts;
        });
  }

  Future<void> seedDefaultProducts() async {
    try {
      final batch = _db.batch();
      for (var product in _fallbackProducts) {
        batch.set(FirestoreCollections.products.doc(product.id), product);
        batch.set(
          FirestoreCollections.productCodes.doc(
            _productCodeDocumentId(product.code),
          ),
          ProductCodeModel(code: product.code, productId: product.id),
        );
      }
      await batch.commit();
      debugPrint('Default products seeded successfully!');
    } catch (e) {
      debugPrint('Default products seed skipped: $e');
    }
  }

  static bool validateCodeUniqueness(
    String code,
    Iterable<String> existingCodes, {
    String? currentCode,
  }) {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return false;
    for (final c in existingCodes) {
      final normC = c.trim().toUpperCase();
      if (normC == normalized) {
        if (currentCode != null &&
            currentCode.trim().toUpperCase() == normalized) {
          continue;
        }
        return false;
      }
    }
    return true;
  }

  Future<bool> isProductCodeTaken(
    String code, {
    String? excludeProductId,
  }) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return false;
    final doc = await FirestoreCollections.productCodes
        .doc(_productCodeDocumentId(cleanCode))
        .get();
    if (!doc.exists) return false;
    final data = doc.data();
    if (excludeProductId != null && data?.productId == excludeProductId) {
      return false;
    }
    return true;
  }

  Future<void> createProduct(ProductModel product) async {
    final cleanCode = product.code.trim().toUpperCase();
    final taken = await isProductCodeTaken(cleanCode);
    if (taken) {
      throw Exception('Product code "$cleanCode" is already in use.');
    }

    final batch = _db.batch();
    final normalized = product.copyWith(code: cleanCode);
    final docRef = FirestoreCollections.products.doc(normalized.id);
    batch.set(docRef, normalized);

    final codeRef = FirestoreCollections.productCodes.doc(
      _productCodeDocumentId(cleanCode),
    );
    batch.set(
      codeRef,
      ProductCodeModel(code: cleanCode, productId: normalized.id),
    );

    await batch.commit();
  }

  Future<void> updateProduct(ProductModel product, {String? oldCode}) async {
    final cleanCode = product.code.trim().toUpperCase();
    final normalizedOldCode = oldCode?.trim().toUpperCase();

    if (normalizedOldCode != null && normalizedOldCode != cleanCode) {
      final taken = await isProductCodeTaken(
        cleanCode,
        excludeProductId: product.id,
      );
      if (taken) {
        throw Exception('Product code "$cleanCode" is already in use.');
      }

      final batch = _db.batch();
      final normalized = product.copyWith(code: cleanCode);
      batch.set(
        FirestoreCollections.products.doc(normalized.id),
        normalized,
        SetOptions(merge: true),
      );
      batch.delete(
        FirestoreCollections.productCodes.doc(
          _productCodeDocumentId(normalizedOldCode),
        ),
      );
      batch.set(
        FirestoreCollections.productCodes.doc(
          _productCodeDocumentId(cleanCode),
        ),
        ProductCodeModel(code: cleanCode, productId: normalized.id),
      );
      await batch.commit();
    } else {
      final normalized = product.copyWith(code: cleanCode);
      await FirestoreCollections.products
          .doc(normalized.id)
          .set(normalized, SetOptions(merge: true));
    }
  }

  Future<void> deleteProduct(String id, String code) async {
    final batch = _db.batch();
    batch.delete(FirestoreCollections.products.doc(id));
    batch.delete(
      FirestoreCollections.productCodes.doc(_productCodeDocumentId(code)),
    );
    await batch.commit();
  }
}
