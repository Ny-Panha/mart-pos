import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/utils/money.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/offline_status_bar.dart';
import 'cart_sheet.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode();

  final currencyUSD = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final currencyKHR = NumberFormat.currency(symbol: '៛', decimalDigits: 0);

  ProductModel? _lastScannedProduct;
  final List<ProductModel> _recentScans = [];

  // Anti-double-scan: ignore duplicate barcode within 1.5 seconds
  DateTime? _lastScanTime;
  String? _lastScanCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _searchController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  void _onProductSelected(ProductModel product, CartProvider cart) {
    if (product.stockQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ ទំនិញ "${product.name}" អស់ពីស្តុកហើយ! (Out of stock)'),
          backgroundColor: AppColors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final success = cart.addToCart(product);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ ទំនិញ "${product.name}" ក្នុងស្តុកមិនគ្រប់គ្រាន់ទេ! (Not enough stock)'),
          backgroundColor: AppColors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _lastScannedProduct = product;
      _recentScans.removeWhere((p) => p.id == product.id);
      _recentScans.insert(0, product);
      if (_recentScans.length > 8) {
        _recentScans.removeLast();
      }
    });

    _barcodeFocusNode.requestFocus();
  }

  void _onBarcodeSubmitted(String code, ProductProvider products, CartProvider cart) {
    if (code.trim().isEmpty) return;
    final barcode = code.trim();
    final now = DateTime.now();

    // ── Anti-double-scan: ignore duplicate barcode within 1.5 seconds ──
    if (_lastScanCode == barcode && _lastScanTime != null) {
      final diff = now.difference(_lastScanTime!).inMilliseconds;
      if (diff < 1500) {
        _barcodeController.clear();
        _barcodeFocusNode.requestFocus();
        return; // Ignore rapid duplicate scan
      }
    }

    _lastScanTime = now;
    _lastScanCode = barcode;

    try {
      final product = products.allProducts.firstWhere(
        (p) => p.barcode.trim() == barcode,
      );

      _onProductSelected(product, cart);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('បានស្កេន និងបញ្ចូល: ${product.name} (${MoneyUtils.formatRiel(MoneyUtils.usdToRiel(product.sellingPrice))})'),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(milliseconds: 900),
        ),
      );
      _barcodeController.clear();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('រកមិនឃើញទំនិញដែលមានបាកូដ: $barcode ទេ (Product not found)'),
          backgroundColor: AppColors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    _barcodeFocusNode.requestFocus();
  }

  IconData _getProductIcon(String iconName) {
    switch (iconName) {
      case 'local_drink':
        return Icons.local_drink_outlined;
      case 'bolt':
        return Icons.bolt_outlined;
      case 'water_drop':
        return Icons.water_drop_outlined;
      case 'ramen_dining':
        return Icons.ramen_dining_outlined;
      case 'cookie':
        return Icons.cookie_outlined;
      case 'clean_hands':
        return Icons.clean_hands_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final productProv = Provider.of<ProductProvider>(context);
    final cartProv = Provider.of<CartProvider>(context);
    final isDark = themeProv.isDarkMode;

    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedText = isDark ? AppColors.darkMutedText : AppColors.lightMutedText;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 960;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Left Column: Product Browser & Scanned View ──
            Expanded(
              child: Column(
                children: [
                  // ── 3.1 Offline Status Bar (លើគេបង្អស់) ──
                  const OfflineStatusBar(),

                  // Top Scanner & Search Bar (Portal equivalent to TopMenu in React)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      border: Border(bottom: BorderSide(color: borderColor)),
                    ),
                    child: Row(
                      children: [
                        // Barcode Scan Input (auto-focuses like hardware scanner)
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _barcodeController,
                            focusNode: _barcodeFocusNode,
                            decoration: InputDecoration(
                              hintText: 'ស្កេនបាកូដទំនិញ (Scan Barcode)...',
                              prefixIcon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                              filled: true,
                              fillColor: isDark ? AppColors.darkBg : const Color(0xFFF1F5F9),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                              ),
                            ),
                            onSubmitted: (val) => _onBarcodeSubmitted(val, productProv, cartProv),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Camera Scan Button (Simulated Modal)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          label: const Text('CAMERA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            _showCameraScannerDialog(context, productProv, cartProv);
                          },
                        ),
                      ],
                    ),
                  ),

                  // Main Scrollable Left Panel
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Last Scanned Product Box (Matching POS.jsx lastScannedProduct)
                          _buildLastScannedSection(cartProv, cardBg, borderColor, textColor, mutedText, isDark),
                          const SizedBox(height: 16),

                          // 2. Recent Scans Row (Matching POS.jsx recentScans)
                          if (_recentScans.length > 1) ...[
                            _buildRecentScansSection(cartProv, cardBg, borderColor, textColor, mutedText, isDark),
                            const SizedBox(height: 16),
                          ],

                          // 3. Category Filter Chips
                          Container(
                            height: 44,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: productProv.categories.length,
                              itemBuilder: (context, idx) {
                                final cat = productProv.categories[idx];
                                final isSelected = cat == productProv.selectedCategory;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ChoiceChip(
                                    label: Text(cat),
                                    selected: isSelected,
                                    selectedColor: AppColors.primary,
                                    backgroundColor: cardBg,
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.white : textColor,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: isSelected ? AppColors.primary : borderColor,
                                      ),
                                    ),
                                    onSelected: (_) => productProv.selectCategory(cat),
                                  ),
                                );
                              },
                            ),
                          ),

                          // 4. All Products Header & Search Box (Matching POS.jsx allProducts)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ទំនិញទាំងអស់ (ALL PRODUCTS)',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: mutedText),
                              ),
                              SizedBox(
                                width: 220,
                                height: 36,
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'ស្វែងរកឈ្មោះ ឬកូដ...',
                                    hintStyle: TextStyle(fontSize: 12, color: mutedText),
                                    prefixIcon: const Icon(Icons.search, size: 16),
                                    filled: true,
                                    fillColor: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
                                    contentPadding: EdgeInsets.zero,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: borderColor),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: borderColor),
                                    ),
                                  ),
                                  onChanged: (val) => productProv.setSearchQuery(val),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 5. Products Grid
                          _buildProductsGrid(productProv, cartProv, cardBg, borderColor, textColor, mutedText, isDark),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Right Column: Sticky Cart Panel (Matching POS.jsx Right Cart Panel) ──
            if (isDesktop)
              Container(
                width: 390,
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: borderColor)),
                  color: cardBg,
                ),
                child: const CartSheet(),
              ),
          ],
        );
      },
    );
  }

  // ── Last Scanned Product Card ──
  Widget _buildLastScannedSection(
    CartProvider cart,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color mutedText,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ទំនិញស្កេនចុងក្រោយ (LAST SCANNED)',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: mutedText),
        ),
        const SizedBox(height: 8),
        if (_lastScannedProduct != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Product Thumbnail box (96x96 matching h-24 w-24 in POS.jsx)
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBg : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Center(
                    child: Icon(
                      _getProductIcon(_lastScannedProduct!.icon),
                      size: 44,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _lastScannedProduct!.name,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkBg : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'បាកូដ: ${_lastScannedProduct!.barcode}',
                              style: TextStyle(fontSize: 11, color: mutedText, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkBg : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ស្តុក: ${_lastScannedProduct!.stockQty}',
                              style: TextStyle(fontSize: 11, color: AppColors.emerald, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            currencyUSD.format(_lastScannedProduct!.sellingPrice),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'ក្នុងកន្ត្រក: ${cart.items.where((i) => i.product.id == _lastScannedProduct!.id).fold(0, (sum, i) => sum + i.quantity)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          // Empty State: Dashed style box
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: cardBg.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, style: BorderStyle.solid),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.qr_code_scanner, size: 36, color: mutedText.withValues(alpha: 0.5)),
                  const SizedBox(height: 8),
                  Text(
                    'រង់ចាំការស្កេនបាកូដ (Waiting for scan)...',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: mutedText),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ── Recent Scans Section ──
  Widget _buildRecentScansSection(
    CartProvider cart,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color mutedText,
    bool isDark,
  ) {
    final recentList = _recentScans.where((p) => p.id != _lastScannedProduct?.id).toList();
    if (recentList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'បានស្កេនមុននេះ (RECENT SCANS)',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: mutedText),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recentList.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, idx) {
              final prod = recentList[idx];
              final inCartQty = cart.items.where((i) => i.product.id == prod.id).fold(0, (sum, i) => sum + i.quantity);

              return InkWell(
                onTap: () => _onProductSelected(prod, cart),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 130,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(_getProductIcon(prod.icon), size: 28, color: AppColors.primary),
                      const SizedBox(height: 4),
                      Text(
                        prod.name,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            currencyUSD.format(prod.sellingPrice),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkBg : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'x$inCartQty',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: mutedText),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Products Grid ──
  Widget _buildProductsGrid(
    ProductProvider productProv,
    CartProvider cartProv,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color mutedText,
    bool isDark,
  ) {
    final products = productProv.filteredProducts;

    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off, size: 48, color: mutedText),
              const SizedBox(height: 8),
              Text('រកមិនឃើញទំនិញទេ', style: TextStyle(color: mutedText)),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, idx) {
        final product = products[idx];
        final bool isOutOfStock = product.stockQty <= 0;

        return InkWell(
          onTap: () => _onProductSelected(product, cartProv),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isOutOfStock ? Colors.red.withValues(alpha: 0.2) : borderColor,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Aspect Ratio Thumbnail container
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBg : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        _getProductIcon(product.icon),
                        size: 38,
                        color: isOutOfStock ? Colors.grey : AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Name
                Text(
                  product.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isOutOfStock ? mutedText : textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Price & Stock badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currencyUSD.format(product.sellingPrice),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isOutOfStock ? Colors.grey : AppColors.primary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOutOfStock
                            ? Colors.red.withValues(alpha: 0.12)
                            : AppColors.emerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isOutOfStock ? 'អស់ស្តុក' : '${product.stockQty} សល់',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isOutOfStock ? Colors.red : AppColors.emerald,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCameraScannerDialog(BuildContext context, ProductProvider productProv, CartProvider cartProv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.camera_alt, color: AppColors.cyan),
            SizedBox(width: 8),
            Text('Camera Barcode Scanner'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner, size: 60, color: Colors.greenAccent),
                    SizedBox(height: 10),
                    Text(
                      'តម្រង់កាមេរ៉ាទៅលើ Barcode ទំនិញ',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ជ្រើសរើសទំនិញគំរូដើម្បីតេស្តការស្កេន:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: productProv.allProducts.take(4).map((p) {
                return ActionChip(
                  label: Text('${p.name} (${p.barcode})'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _onBarcodeSubmitted(p.barcode, productProv, cartProv);
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('បិទ'),
          ),
        ],
      ),
    );
  }
}
