// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mini-Mart POS';

  @override
  String get loginTitle => 'Welcome Back';

  @override
  String get loginSubtitle =>
      'Sign in to start your cashier or management shift';

  @override
  String get emailOrUsername => 'Email or Username';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get signInButton => 'SIGN IN';

  @override
  String get signingIn => 'Signing in...';

  @override
  String get offlineMode => 'Offline Mode';

  @override
  String get onlineSync => 'Online - Sync Active';

  @override
  String get posTitle => 'Point of Sale';

  @override
  String get scanPlaceholder => 'Scan barcode or enter code (Enter to add)...';

  @override
  String get cameraScan => 'Camera Scan';

  @override
  String get lastScanned => 'Last Scanned Product';

  @override
  String get noScanYet => 'Scan a barcode or tap a product to begin';

  @override
  String get recentScans => 'Recent Scans';

  @override
  String get searchProducts => 'Search products by name or category...';

  @override
  String get allCategories => 'All Categories';

  @override
  String get cartTitle => 'Current Order';

  @override
  String get customer => 'Customer';

  @override
  String get walkInCustomer => 'Walk-in Customer';

  @override
  String get cartEmpty => 'Cart is empty';

  @override
  String get cartEmptyHint =>
      'Scan barcodes or select products to add to this order';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get tax => 'Tax';

  @override
  String get discount => 'Discount';

  @override
  String get total => 'Total Amount';

  @override
  String get completeSale => 'COMPLETE SALE';

  @override
  String get outOfStock => 'Out of stock';

  @override
  String get lowStock => 'Low stock';

  @override
  String get stockExceeded => 'Requested quantity exceeds available stock';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get products => 'Products';

  @override
  String get inventory => 'Inventory';

  @override
  String get customers => 'Customers';

  @override
  String get reports => 'Reports';

  @override
  String get users => 'Staff & Users';

  @override
  String get logout => 'Log Out';

  @override
  String get newProduct => 'New Product';

  @override
  String get editProduct => 'Edit Product';

  @override
  String get deleteProduct => 'Delete Product';

  @override
  String get productName => 'Product Name';

  @override
  String get productCode => 'Product Code';

  @override
  String get barcode => 'Barcode';

  @override
  String get sku => 'SKU';

  @override
  String get category => 'Category';

  @override
  String get costPrice => 'Cost Price';

  @override
  String get salePrice => 'Sale Price';

  @override
  String get stockQty => 'Stock Quantity';

  @override
  String get unit => 'Unit';

  @override
  String get lowStockThreshold => 'Low Stock Alert';

  @override
  String get taxRate => 'Tax Rate';

  @override
  String get status => 'Status';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get categories => 'Categories';

  @override
  String get manageCategories => 'Manage Categories';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get codeAlreadyUsed => 'Product code already used';

  @override
  String get categoryInUse => 'Cannot delete category in use by products';

  @override
  String get deleteProductConfirm =>
      'Are you sure you want to delete this product?';

  @override
  String get actions => 'Actions';
}
