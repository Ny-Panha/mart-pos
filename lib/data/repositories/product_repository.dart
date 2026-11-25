import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/widgets/product_thumbnail.dart';
import '../firestore/firestore_collections.dart';
import '../firestore/models/product_code_model.dart';
import '../firestore/models/product_model.dart';
import '../firestore/shop_scope.dart';
import '../services/api_service.dart';

class ProductRepository {
  final FirebaseFirestore? _dbInstance;
  FirebaseFirestore get _db => _dbInstance ?? FirebaseFirestore.instance;

  ProductRepository({FirebaseFirestore? db}) : _dbInstance = db;
  final StreamController<List<ProductModel>> _productsController =
      StreamController<List<ProductModel>>.broadcast();

  String _productCodeDocumentId(String code) =>
      '${ShopScope.requireShopId()}__${Uri.encodeComponent(code.trim().toUpperCase())}';

  final List<ProductModel> _fallbackProducts = [
    ProductModel(
      id: '1',
      code: 'PROD-001',
      barcode: '884000101',
      sku: 'COCA-330',
      name: 'Coca Cola 330ml',
      categoryId: '1',
      costPrice: 1600,
      salePrice: 2500,
      stockQty: 48,
      unit: 'កំប៉ុង',
      lowStockThreshold: 10,
      imageUrl: 'assets/products/coca_cola.jpg',
    ),
    ProductModel(
      id: '2',
      code: 'PROD-002',
      barcode: '884000102',
      sku: 'STING-330',
      name: 'Sting Energy Drink 330ml',
      categoryId: '1',
      costPrice: 1800,
      salePrice: 3000,
      stockQty: 36,
      unit: 'ដប',
      lowStockThreshold: 10,
      imageUrl: 'assets/products/sting_energy.jpg',
    ),
    ProductModel(
      id: '3',
      code: 'PROD-003',
      barcode: '884000103',
      sku: 'REDBULL-250',
      name: 'Red Bull Energy 250ml',
      categoryId: '1',
      costPrice: 2400,
      salePrice: 3600,
      stockQty: 24,
      unit: 'កំប៉ុង',
      lowStockThreshold: 10,
      imageUrl: 'assets/products/red_bull.jpg',
    ),
    ProductModel(
      id: '4',
      code: 'PROD-004',
      barcode: '884000104',
      sku: 'CARABAO-250',
      name: 'Carabao Energy 250ml',
      categoryId: '1',
      costPrice: 1600,
      salePrice: 2500,
      stockQty: 30,
      unit: 'កំប៉ុង',
      lowStockThreshold: 10,
      imageUrl: 'assets/products/carabao.jpg',
    ),
    ProductModel(
      id: '5',
      code: 'PROD-005',
      barcode: '884000105',
      sku: 'WATER-500',
      name: 'Pure Drinking Water 500ml',
      categoryId: '1',
      costPrice: 600,
      salePrice: 1000,
      stockQty: 60,
      unit: 'ដប',
      lowStockThreshold: 15,
      imageUrl: 'assets/products/water.jpg',
    ),
    ProductModel(
      id: '6',
      code: 'PROD-006',
      barcode: '884000106',
      sku: 'MAMA-TOMYUM',
      name: 'Mama Instant Noodles Tom Yum',
      categoryId: '3',
      costPrice: 1000,
      salePrice: 1500,
      stockQty: 50,
      unit: 'កញ្ចប់',
      lowStockThreshold: 10,
      imageUrl: 'assets/products/mama.jpg',
    ),
    ProductModel(
      id: '7',
      code: 'PROD-007',
      barcode: '884000107',
      sku: 'INDOMIE-GORENG',
      name: 'Indomie Mi Goreng 85g',
      categoryId: '3',
      costPrice: 1300,
      salePrice: 2000,
      stockQty: 45,
      unit: 'កញ្ចប់',
      lowStockThreshold: 10,
      imageUrl: 'assets/products/indomie.jpg',
    ),
    ProductModel(
      id: '8',
      code: 'PROD-008',
      barcode: '884000108',
      sku: 'LAYS-CLASSIC',
      name: 'Lays Classic Potato Chips 50g',
      categoryId: '2',
      costPrice: 2800,
      salePrice: 4000,
      stockQty: 20,
      unit: 'កញ្ចប់',
      lowStockThreshold: 5,
      imageUrl: 'assets/products/lays.jpg',
    ),
  ];

  /// Refresh products list from authoritative Laravel API
  Future<List<ProductModel>> refreshProducts() async {
    try {
      final res = await ApiService.get('/products');
      if (res != null && res['success'] == true && res['data'] is List) {
        final list = (res['data'] as List).map((item) {
          final model = ProductModel.fromJson(item as Map<String, dynamic>);
          final local = ProductThumbnail.getAssetForProduct(
            id: model.id,
            name: model.name,
            barcode: model.barcode,
          );
          return local != null ? model.copyWith(imageUrl: local) : model;
        }).toList();
        _productsController.add(list);
        return list;
      }
    } catch (e) {
      debugPrint('refreshProducts error: $e');
    }
    return [];
  }

  /// Authoritative Stream: Reads from Laravel API first.
  /// If connected, yields live MySQL products and listens to broadcast updates.
  /// If offline/unreachable, falls back to Firestore cache.
  Stream<List<ProductModel>> watchProducts() async* {
    List<ProductModel>? liveProducts;
    try {
      final res = await ApiService.get('/products');
      if (res != null && res['success'] == true && res['data'] is List) {
        liveProducts = (res['data'] as List).map((item) {
          final model = ProductModel.fromJson(item as Map<String, dynamic>);
          final local = ProductThumbnail.getAssetForProduct(
            id: model.id,
            name: model.name,
            barcode: model.barcode,
          );
          return local != null ? model.copyWith(imageUrl: local) : model;
        }).toList();
      }
    } catch (e) {
      debugPrint('Laravel API watchProducts notice (offline fallback active): $e');
    }

    if (liveProducts != null) {
      yield liveProducts;
      yield* _productsController.stream;
    } else {
      // Offline fallback: Use Firestore cache only when Laravel is unreachable
      yield* ShopScope.query(FirestoreCollections.products)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) {
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
          });
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
    try {
      final doc = await FirestoreCollections.productCodes
          .doc(_productCodeDocumentId(cleanCode))
          .get();
      if (!doc.exists) return false;
      final data = doc.data();
      if (excludeProductId != null && data?.productId == excludeProductId) {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Authoritative Create Product:
  /// 1. Sends to Laravel API (MySQL authoritative).
  /// 2. Propagates validation or HTTP errors immediately.
  /// 3. Extracts backend MySQL generated ID and syncs to Firestore cache with consistent ID.
  Future<ProductModel> createProduct(ProductModel product) async {
    final cleanCode = product.code.trim().toUpperCase();
    final normalized = product.copyWith(code: cleanCode);

    // 1. Authoritative request to Laravel API
    final res = await ApiService.post('/products', normalized.toJson());
    if (res == null || res['success'] != true || res['data'] == null) {
      final msg = res?['message'] ?? 'Failed to create product on backend.';
      throw Exception(msg);
    }

    // 2. Extract backend MySQL ID
    final serverData = res['data'] as Map<String, dynamic>;
    final createdProduct = ProductModel.fromJson(serverData).copyWith(
      imageUrl: normalized.imageUrl,
    );

    // 3. Sync to Firestore cache with the same MySQL ID
    try {
      final batch = _db.batch();
      final docRef = FirestoreCollections.products.doc(createdProduct.id);
      batch.set(docRef, createdProduct);

      final codeRef = FirestoreCollections.productCodes.doc(
        _productCodeDocumentId(cleanCode),
      );
      batch.set(
        codeRef,
        ProductCodeModel(code: cleanCode, productId: createdProduct.id),
      );
      await batch.commit();
    } catch (e) {
      debugPrint('Firestore product cache notice: $e');
    }

    await refreshProducts();
    return createdProduct;
  }

  /// Authoritative Update Product:
  /// 1. Updates via Laravel API first.
  /// 2. Propagates errors to UI.
  /// 3. Updates Firestore cache.
  Future<void> updateProduct(ProductModel product, {String? oldCode}) async {
    final cleanCode = product.code.trim().toUpperCase();
    final normalized = product.copyWith(code: cleanCode);

    // 1. Authoritative request to Laravel API
    final res = await ApiService.put('/products/${product.id}', normalized.toJson());
    if (res == null || res['success'] != true) {
      final msg = res?['message'] ?? 'Failed to update product on backend.';
      throw Exception(msg);
    }

    // 2. Update Firestore cache
    try {
      final normalizedOldCode = oldCode?.trim().toUpperCase();
      if (normalizedOldCode != null && normalizedOldCode != cleanCode) {
        final batch = _db.batch();
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
        await FirestoreCollections.products
            .doc(normalized.id)
            .set(normalized, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Firestore product update cache notice: $e');
    }

    await refreshProducts();
  }

  /// Authoritative Delete Product:
  /// 1. Deactivates in Laravel API (soft delete preserving order relationships).
  /// 2. Propagates errors to UI.
  /// 3. Removes from Firestore cache.
  Future<void> deleteProduct(String id, String code) async {
    // 1. Authoritative request to Laravel API
    final res = await ApiService.delete('/products/$id');
    if (res == null || res['success'] != true) {
      final msg = res?['message'] ?? 'Failed to delete product on backend.';
      throw Exception(msg);
    }

    // 2. Update Firestore cache
    try {
      final batch = _db.batch();
      batch.delete(FirestoreCollections.products.doc(id));
      batch.delete(
        FirestoreCollections.productCodes.doc(_productCodeDocumentId(code)),
      );
      await batch.commit();
    } catch (e) {
      debugPrint('Firestore product delete cache notice: $e');
    }

    await refreshProducts();
  }
}
