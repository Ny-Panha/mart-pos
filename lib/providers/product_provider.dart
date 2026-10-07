import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/stock_history_model.dart';
import '../services/firebase_service.dart';

class ProductProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<ProductModel> _products = [];
  final List<StockHistoryModel> _stockHistory = [];
  String _selectedCategory = 'ទាំងអស់';
  String _searchQuery = '';
  bool _isLoading = true;
  StreamSubscription? _subscription;

  ProductProvider() {
    _initStream();
  }

  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  List<StockHistoryModel> get stockHistory => List.unmodifiable(_stockHistory);

  List<String> get categories => [
        'ទាំងអស់',
        'ភេសជ្ជៈ',
        'មី និងអាហារស្រាល',
        'នំបុ័ង និងនំចំណី',
        'សម្ភារៈប្រើប្រាស់',
      ];

  List<ProductModel> get allProducts => _products;
  List<ProductModel> get products => _products;

  ProductModel? findByBarcode(String barcode) {
    try {
      return _products.firstWhere((p) => p.barcode == barcode || p.sku == barcode);
    } catch (_) {
      return null;
    }
  }

  ProductModel? findById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void updateStock(String productId, int delta) {
    adjustStock(
      productId: productId,
      changeQty: delta,
      reason: delta > 0 ? 'នាំចូលស្តុក (Stock In)' : 'កែសម្រួលស្តុក (Stock Adjust)',
      cashierName: 'Admin',
    );
  }

  List<ProductModel> get lowStockProducts =>
      _products.where((p) => p.stockQty <= 5).toList();

  List<ProductModel> get filteredProducts {
    return _products.where((p) {
      final matchesCategory =
          _selectedCategory == 'ទាំងអស់' || p.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.barcode.contains(_searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _initStream() {
    _isLoading = true;
    _subscription = _firebaseService.streamProducts().listen((data) {
      _products = data;
      _isLoading = false;
      notifyListeners();
    }, onError: (err) {
      _isLoading = false;
      notifyListeners();
    });
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> addProduct(ProductModel product) async {
    await _firebaseService.addProduct(product);
  }

  Future<void> updateProduct(ProductModel product) async {
    await _firebaseService.updateProduct(product);
  }

  Future<void> deleteProduct(String productId) async {
    await _firebaseService.deleteProduct(productId);
  }

  // Stock Adjustment with reason (Mart Inventory)
  Future<void> adjustStock({
    required String productId,
    required int changeQty,
    required String reason,
    required String cashierName,
  }) async {
    int idx = _products.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      final product = _products[idx];
      final newQty = product.stockQty + changeQty;
      final updated = product.copyWith(stockQty: newQty < 0 ? 0 : newQty);
      await updateProduct(updated);

      _stockHistory.insert(
        0,
        StockHistoryModel(
          id: 'adj_${DateTime.now().millisecondsSinceEpoch}',
          productId: productId,
          productName: product.name,
          changeQty: changeQty,
          reason: reason,
          createdAt: DateTime.now(),
          cashierName: cashierName,
        ),
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
