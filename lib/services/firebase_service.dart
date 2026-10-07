import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/sale_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _productsRef => _firestore.collection('products');
  CollectionReference get _salesRef => _firestore.collection('sales');

  // Fallback in-memory store in case device is offline during classroom presentation
  final List<ProductModel> _mockProducts = [
    ProductModel(
      id: 'p1',
      barcode: '884000101',
      name: 'Coca Cola 330ml',
      category: 'ភេសជ្ជៈ',
      costPrice: 0.40,
      sellingPrice: 0.65,
      stockQty: 48,
      unit: 'កំប៉ុង',
      icon: 'local_drink',
    ),
    ProductModel(
      id: 'p2',
      barcode: '884000102',
      name: 'Sting Energy Drink 330ml',
      category: 'ភេសជ្ជៈ',
      costPrice: 0.45,
      sellingPrice: 0.75,
      stockQty: 36,
      unit: 'ដប',
      icon: 'bolt',
    ),
    ProductModel(
      id: 'p3',
      barcode: '884000103',
      name: 'Red Bull Energy 250ml',
      category: 'ភេសជ្ជៈ',
      costPrice: 0.60,
      sellingPrice: 0.90,
      stockQty: 24,
      unit: 'កំប៉ុង',
      icon: 'local_drink',
    ),
    ProductModel(
      id: 'p4',
      barcode: '884000104',
      name: 'Angkor Puro Water 500ml',
      category: 'ភេសជ្ជៈ',
      costPrice: 0.15,
      sellingPrice: 0.35,
      stockQty: 80,
      unit: 'ដប',
      icon: 'water_drop',
    ),
    ProductModel(
      id: 'p5',
      barcode: '884000201',
      name: 'MAMA Noodles Tom Yum 60g',
      category: 'មី និងអាហារស្រាល',
      costPrice: 0.30,
      sellingPrice: 0.50,
      stockQty: 50,
      unit: 'កញ្ចប់',
      icon: 'ramen_dining',
    ),
    ProductModel(
      id: 'p6',
      barcode: '884000202',
      name: 'Oreo Biscuits 120g',
      category: 'នំបុ័ង និងនំចំណី',
      costPrice: 0.70,
      sellingPrice: 1.10,
      stockQty: 18,
      unit: 'ប្រអប់',
      icon: 'cookie',
    ),
    ProductModel(
      id: 'p7',
      barcode: '884000301',
      name: 'Colgate Toothpaste 150g',
      category: 'សម្ភារៈប្រើប្រាស់',
      costPrice: 1.20,
      sellingPrice: 1.80,
      stockQty: 12,
      unit: 'ប្រអប់',
      icon: 'clean_hands',
    ),
    ProductModel(
      id: 'p8',
      barcode: '884000302',
      name: 'Lifebuoy Soap 90g',
      category: 'សម្ភារៈប្រើប្រាស់',
      costPrice: 0.40,
      sellingPrice: 0.70,
      stockQty: 4, // low stock test
      unit: 'ដុំ',
      icon: 'soap',
    ),
  ];

  final List<SaleModel> _mockSales = [];

  // Stream products from Firestore with fallback
  Stream<List<ProductModel>> streamProducts() {
    try {
      return _productsRef.snapshots().map((snapshot) {
        if (snapshot.docs.isEmpty) {
          // If empty, auto-seed with mock products
          _seedDefaultProducts();
          return _mockProducts;
        }
        return snapshot.docs.map((doc) {
          return ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
      }).handleError((error) {
        debugPrint('Firestore stream error (fallback to local): $error');
        return _mockProducts;
      });
    } catch (e) {
      debugPrint('Firestore error: $e');
      return Stream.value(_mockProducts);
    }
  }

  // Seed default items into Firestore if collection is empty
  Future<void> _seedDefaultProducts() async {
    try {
      for (var product in _mockProducts) {
        await _productsRef.doc(product.id).set(product.toMap());
      }
    } catch (e) {
      debugPrint('Seed skipped: $e');
    }
  }

  // Add new product
  Future<void> addProduct(ProductModel product) async {
    try {
      await _productsRef.doc(product.id).set(product.toMap());
    } catch (e) {
      debugPrint('Firebase add error: $e. Saving locally.');
    }
    _mockProducts.removeWhere((p) => p.id == product.id);
    _mockProducts.add(product);
  }

  // Update existing product
  Future<void> updateProduct(ProductModel product) async {
    try {
      await _productsRef.doc(product.id).update(product.toMap());
    } catch (e) {
      debugPrint('Firebase update error: $e. Updating locally.');
    }
    int idx = _mockProducts.indexWhere((p) => p.id == product.id);
    if (idx != -1) {
      _mockProducts[idx] = product;
    }
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      await _productsRef.doc(productId).delete();
    } catch (e) {
      debugPrint('Firebase delete error: $e. Removing locally.');
    }
    _mockProducts.removeWhere((p) => p.id == productId);
  }

  // Record a Sale Transaction using Firestore WriteBatch (Works offline, queues in cache)
  Future<void> recordSale(SaleModel sale) async {
    try {
      final batch = _firestore.batch();

      // 1. set sales/{newId} (បង្កើត sale)
      batch.set(_salesRef.doc(sale.id), sale.toMap());

      // 2. update products/{id} (stockQty: FieldValue.increment(-qty))
      // 3. set stockMovements/{newId} (type: "out", refId: sale.id)
      for (var item in sale.items) {
        batch.update(_productsRef.doc(item.product.id), {
          'stockQty': FieldValue.increment(-item.quantity),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        final movementRef = _firestore.collection('stockMovements').doc();
        batch.set(movementRef, {
          'productId': item.product.id,
          'type': 'out',
          'qty': item.quantity,
          'refId': sale.id,
          'note': 'Sale: ${sale.invoiceNumber}',
          'createdBy': sale.cashierName,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      // Commit atomic batch
      await batch.commit();
    } catch (e) {
      debugPrint('Firebase recordSale WriteBatch error: $e. Processing locally.');
    }

    // Local fallback sync
    _mockSales.insert(0, sale);
    for (var item in sale.items) {
      int idx = _mockProducts.indexWhere((p) => p.id == item.product.id);
      if (idx != -1) {
        int newQty = _mockProducts[idx].stockQty - item.quantity;
        _mockProducts[idx] = _mockProducts[idx].copyWith(stockQty: newQty < 0 ? 0 : newQty);
      }
    }
  }

  // Stream sales history
  Stream<List<SaleModel>> streamSales() {
    try {
      return _salesRef
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isEmpty) {
          return _mockSales;
        }
        return snapshot.docs.map((doc) {
          return SaleModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
      }).handleError((error) {
        debugPrint('Firestore sales error: $error');
        return _mockSales;
      });
    } catch (e) {
      return Stream.value(_mockSales);
    }
  }
}
