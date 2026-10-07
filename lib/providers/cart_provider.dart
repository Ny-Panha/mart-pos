import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../models/customer_model.dart';
import '../models/product_model.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItemModel> _items = [];
  final List<List<CartItemModel>> _heldBills = []; // Hold bill / Resume bill
  
  static const double khrExchangeRate = 4100.0; // 1 USD = 4,100 KHR

  CustomerModel? _selectedCustomer;
  int _redeemedPoints = 0;
  double _globalTaxPercent = 0.0; // Tax percentage (e.g. 10%)

  List<CartItemModel> get items => List.unmodifiable(_items);
  List<List<CartItemModel>> get heldBills => List.unmodifiable(_heldBills);
  CustomerModel? get selectedCustomer => _selectedCustomer;
  int get redeemedPoints => _redeemedPoints;
  double get globalTaxPercent => _globalTaxPercent;

  int get totalItemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotalUSD => _items.fold(0.0, (sum, item) => sum + item.subtotal);

  double get itemDiscountUSD => _items.fold(0.0, (sum, item) => sum + item.discountAmount);

  // Loyalty points discount ($0.01 per point)
  double get pointsDiscountUSD => _redeemedPoints * 0.01;

  double get totalDiscountUSD => itemDiscountUSD + pointsDiscountUSD;

  double get taxUSD => (subtotalUSD - totalDiscountUSD > 0)
      ? ((subtotalUSD - totalDiscountUSD) * _globalTaxPercent / 100)
      : 0.0;

  double get totalUSD {
    double finalVal = subtotalUSD - totalDiscountUSD + taxUSD;
    return finalVal > 0 ? finalVal : 0.0;
  }

  double get totalKHR => (totalUSD * khrExchangeRate).roundToDouble();

  void setSelectedCustomer(CustomerModel? customer) {
    _selectedCustomer = customer;
    _redeemedPoints = 0;
    notifyListeners();
  }

  void setRedeemedPoints(int points) {
    if (_selectedCustomer != null && points <= _selectedCustomer!.points) {
      _redeemedPoints = points;
      notifyListeners();
    }
  }

  void setGlobalTaxPercent(double percent) {
    _globalTaxPercent = percent;
    notifyListeners();
  }

  // Add product to cart with strict stock checking
  bool addToCart(ProductModel product) {
    int existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    if (existingIndex != -1) {
      if (_items[existingIndex].quantity < product.stockQty) {
        _items[existingIndex].quantity++;
        notifyListeners();
        return true;
      } else {
        return false; // Stock limit reached
      }
    } else {
      if (product.stockQty > 0) {
        _items.add(CartItemModel(product: product, quantity: 1));
        notifyListeners();
        return true;
      }
      return false; // Out of stock
    }
  }

  // Quick Barcode Scan addition
  bool addByBarcode(String barcode, List<ProductModel> products) {
    try {
      final product = products.firstWhere(
        (p) => p.barcode.trim() == barcode.trim(),
      );
      addToCart(product);
      return true;
    } catch (_) {
      return false;
    }
  }

  void incrementQuantity(String productId) {
    int index = _items.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      if (_items[index].quantity < _items[index].product.stockQty) {
        _items[index].quantity++;
        notifyListeners();
      }
    }
  }

  void decrementQuantity(String productId) {
    int index = _items.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void setItemDiscount(String productId, double percentage) {
    int index = _items.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      _items[index].discountPercentage = percentage;
      notifyListeners();
    }
  }

  // Hold current bill
  void holdCurrentBill() {
    if (_items.isNotEmpty) {
      _heldBills.add(List.from(_items));
      _items.clear();
      _selectedCustomer = null;
      _redeemedPoints = 0;
      notifyListeners();
    }
  }

  // Resume a held bill
  void resumeHeldBill(int index) {
    if (index >= 0 && index < _heldBills.length) {
      _items.clear();
      _items.addAll(_heldBills.removeAt(index));
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _selectedCustomer = null;
    _redeemedPoints = 0;
    notifyListeners();
  }
}
