import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_km.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('km'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Mini-Mart POS'**
  String get appTitle;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to start your cashier or management shift'**
  String get loginSubtitle;

  /// No description provided for @emailOrUsername.
  ///
  /// In en, this message translates to:
  /// **'Email or Username'**
  String get emailOrUsername;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'SIGN IN'**
  String get signInButton;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get signingIn;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineMode;

  /// No description provided for @onlineSync.
  ///
  /// In en, this message translates to:
  /// **'Online - Sync Active'**
  String get onlineSync;

  /// No description provided for @posTitle.
  ///
  /// In en, this message translates to:
  /// **'Point of Sale'**
  String get posTitle;

  /// No description provided for @scanPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode or enter code (Enter to add)...'**
  String get scanPlaceholder;

  /// No description provided for @cameraScan.
  ///
  /// In en, this message translates to:
  /// **'Camera Scan'**
  String get cameraScan;

  /// No description provided for @lastScanned.
  ///
  /// In en, this message translates to:
  /// **'Last Scanned Product'**
  String get lastScanned;

  /// No description provided for @noScanYet.
  ///
  /// In en, this message translates to:
  /// **'Scan a barcode or tap a product to begin'**
  String get noScanYet;

  /// No description provided for @recentScans.
  ///
  /// In en, this message translates to:
  /// **'Recent Scans'**
  String get recentScans;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products by name or category...'**
  String get searchProducts;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @cartTitle.
  ///
  /// In en, this message translates to:
  /// **'Current Order'**
  String get cartTitle;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @walkInCustomer.
  ///
  /// In en, this message translates to:
  /// **'Walk-in Customer'**
  String get walkInCustomer;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Cart is empty'**
  String get cartEmpty;

  /// No description provided for @cartEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Scan barcodes or select products to add to this order'**
  String get cartEmptyHint;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get total;

  /// No description provided for @completeSale.
  ///
  /// In en, this message translates to:
  /// **'COMPLETE SALE'**
  String get completeSale;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get outOfStock;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get lowStock;

  /// No description provided for @stockExceeded.
  ///
  /// In en, this message translates to:
  /// **'Requested quantity exceeds available stock'**
  String get stockExceeded;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Staff & Users'**
  String get users;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @newProduct.
  ///
  /// In en, this message translates to:
  /// **'New Product'**
  String get newProduct;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProduct;

  /// No description provided for @deleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Delete Product'**
  String get deleteProduct;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @productCode.
  ///
  /// In en, this message translates to:
  /// **'Product Code'**
  String get productCode;

  /// No description provided for @barcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcode;

  /// No description provided for @sku.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get sku;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @costPrice.
  ///
  /// In en, this message translates to:
  /// **'Cost Price'**
  String get costPrice;

  /// No description provided for @salePrice.
  ///
  /// In en, this message translates to:
  /// **'Sale Price'**
  String get salePrice;

  /// No description provided for @stockQty.
  ///
  /// In en, this message translates to:
  /// **'Stock Quantity'**
  String get stockQty;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @lowStockThreshold.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Alert'**
  String get lowStockThreshold;

  /// No description provided for @taxRate.
  ///
  /// In en, this message translates to:
  /// **'Tax Rate'**
  String get taxRate;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @manageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get manageCategories;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @codeAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'Product code already used'**
  String get codeAlreadyUsed;

  /// No description provided for @categoryInUse.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete category in use by products'**
  String get categoryInUse;

  /// No description provided for @deleteProductConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this product?'**
  String get deleteProductConfirm;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @stockIn.
  ///
  /// In en, this message translates to:
  /// **'Stock In'**
  String get stockIn;

  /// No description provided for @stockOut.
  ///
  /// In en, this message translates to:
  /// **'Stock Out'**
  String get stockOut;

  /// No description provided for @adjustStock.
  ///
  /// In en, this message translates to:
  /// **'Adjust Stock'**
  String get adjustStock;

  /// No description provided for @stockHistory.
  ///
  /// In en, this message translates to:
  /// **'Stock Movement History'**
  String get stockHistory;

  /// No description provided for @lowStockAlert.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Alert'**
  String get lowStockAlert;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'km'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'km':
      return AppLocalizationsKm();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
