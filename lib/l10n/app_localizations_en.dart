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
  String get allCategories => 'All';

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
}
