import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/offline_bar.dart';
import '../../../core/widgets/qty_stepper.dart';
import '../../../data/firestore/models/product_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../products/providers/product_provider.dart';
import '../providers/pos_cart_provider.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _scanController = TextEditingController();
  final FocusNode _scanFocusNode = FocusNode();
  TabController? _mobileTabController;

  @override
  void initState() {
    super.initState();
    _mobileTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _scanController.dispose();
    _scanFocusNode.dispose();
    _mobileTabController?.dispose();
    super.dispose();
  }

  void _onBarcodeSubmitted(String barcode) {
    if (barcode.trim().isEmpty) return;

    final products = ref.read(productsStreamProvider).value ?? [];
    final match = products.where((p) =>
        p.barcode.toLowerCase() == barcode.trim().toLowerCase() ||
        p.code.toLowerCase() == barcode.trim().toLowerCase() ||
        p.sku.toLowerCase() == barcode.trim().toLowerCase());

    if (match.isNotEmpty) {
      final product = match.first;
      final error = ref.read(posCartProvider.notifier).addProduct(product, isBarcodeScan: true);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: error.contains('Anti-double-scan') ? Colors.orange : AppColors.danger,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${product.name} to order'),
            backgroundColor: AppColors.success,
            duration: const Duration(milliseconds: 1000),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No product found for code: $barcode'),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    _scanController.clear();
    _scanFocusNode.requestFocus();
  }

  void _openCameraScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Scan Product Barcode',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: MobileScanner(
                    onDetect: (capture) {
                      final barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                        final scanned = barcodes.first.rawValue!;
                        Navigator.pop(ctx);
                        _onBarcodeSubmitted(scanned);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleCompleteSale() async {
    final cart = ref.read(posCartProvider);
    if (cart.items.isEmpty) return;

    final user = ref.read(authProvider).value;
    final cashierId = user?.name ?? 'Cashier';

    try {
      final invoiceNum = await ref.read(posCartProvider.notifier).checkout(
            cashierId: cashierId,
            paymentMethod: 'cash',
          );

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 28),
                SizedBox(width: 10),
                Text('ការទូទាត់ជោគជ័យ!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('លេខវិក្កយបត្រ (Invoice): $invoiceNum', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('ទឹកប្រាក់សរុប: ${MoneyUtils.formatDual(cart.total)}'),
                const SizedBox(height: 8),
                const Text('ទិន្នន័យត្រូវបានកត់ត្រា និងកាត់ស្តុកដោយស្វ័យប្រវត្តិ (WriteBatch Offline-First).'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('បិទ (Close)'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout failed: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cart = ref.watch(posCartProvider);

    return Scaffold(
      body: Column(
        children: [
          // 1. Top Offline Status Bar
          const OfflineBar(),

          // 2. Main Content Area
          Expanded(
            child: isDesktop
                ? Row(
                    children: [
                      // Left Pane: Product Browser
                      Expanded(
                        child: _buildProductBrowser(context, isDark),
                      ),
                      // Right Pane: Sticky Cart Panel (400px)
                      Container(
                        width: 400,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          border: Border(
                            left: BorderSide(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                        ),
                        child: _buildCartPanel(context, isDark, cart),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      TabBar(
                        controller: _mobileTabController,
                        tabs: [
                          const Tab(icon: Icon(Icons.grid_view), text: 'Products'),
                          Tab(
                            icon: Badge(
                              isLabelVisible: cart.totalItemCount > 0,
                              label: Text('${cart.totalItemCount}'),
                              child: const Icon(Icons.shopping_cart),
                            ),
                            text: 'Cart (${MoneyUtils.formatRiel(cart.total)})',
                          ),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _mobileTabController,
                          children: [
                            _buildProductBrowser(context, isDark),
                            _buildCartPanel(context, isDark, cart),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductBrowser(BuildContext context, bool isDark) {
    final filteredProducts = ref.watch(filteredProductsProvider);
    final cart = ref.watch(posCartProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Scan Bar in top area
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _scanController,
                  focusNode: _scanFocusNode,
                  autofocus: true,
                  onSubmitted: _onBarcodeSubmitted,
                  decoration: InputDecoration(
                    hintText: 'ស្កេនបារកូដ ឬវាយលេខកូដ (Enter to add)...',
                    prefixIcon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
                      onPressed: () => _onBarcodeSubmitted(_scanController.text),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _openCameraScanner,
                  icon: const Icon(Icons.camera_alt_outlined, size: 20),
                  label: const Text('CAMERA SCAN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. "Last Scanned" Hero Card
          _buildLastScannedHero(cart.lastScannedProduct, cart, isDark),
          const SizedBox(height: 20),

          // 3. "Recent Scans" Grid
          if (cart.recentScans.isNotEmpty) ...[
            Text('ទំនិញស្កេនថ្មីៗ (Recent Scans)', style: AppTextStyles.titleLG),
            const SizedBox(height: 12),
            _buildRecentScansGrid(cart.recentScans, isDark),
            const SizedBox(height: 24),
          ],

          // 4. Product Catalog Header & Filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('បញ្ជីទំនិញទាំងអស់ (All Products)', style: AppTextStyles.titleLG),
              SizedBox(
                width: 240,
                child: TextField(
                  onChanged: (v) => ref.read(productSearchQueryProvider.notifier).setQuery(v),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'ស្វែងរកឈ្មោះទំនិញ...',
                    prefixIcon: Icon(Icons.search, size: 18),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 5. Product Grid
          _buildProductGrid(filteredProducts, cart, isDark),
        ],
      ),
    );
  }

  Widget _buildLastScannedHero(ProductModel? product, PosCartState cart, bool isDark) {
    if (product == null) {
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            style: BorderStyle.solid,
            width: 1.5,
          ),
          color: (isDark ? AppColors.darkCard : Colors.white).withValues(alpha: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_2_rounded,
              size: 44,
              color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ទំនិញទើបស្កេន (Last Scanned Product)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                Text(
                  'សូមស្កេនបារកូដ ឬចុចលើទំនិញដើម្បីបញ្ចូលក្នុងវិក្កយបត្រ',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final inCartQty = cart.getQtyForProduct(product.id);

    return AppCard(
      padding: const EdgeInsets.all(18),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Center(
              child: Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 40),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'LAST SCANNED',
                        style: AppTextStyles.eyebrow.copyWith(color: AppColors.primary, fontSize: 10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (inCartQty > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'In Cart: $inCartQty ${product.unit}',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(product.name, style: AppTextStyles.titleLG),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    Text('Barcode: ${product.barcode}', style: AppTextStyles.caption),
                    Text('SKU: ${product.sku}', style: AppTextStyles.caption),
                    Text(
                      'Stock: ${product.stockQty} ${product.unit}',
                      style: AppTextStyles.caption.copyWith(
                        color: product.isLowStock ? AppColors.warning : AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                MoneyUtils.formatRiel(product.salePrice),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                MoneyUtils.formatUSD(MoneyUtils.rielToUsd(product.salePrice)),
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 32,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final err = ref.read(posCartProvider.notifier).addProduct(product);
                    if (err != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(err), backgroundColor: AppColors.danger),
                      );
                    }
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('+1 ADD', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentScansGrid(List<ProductModel> products, bool isDark) {
    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = constraints.maxWidth > 700 ? 4 : 2;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollExceptionStream(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.2,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final p = products[index];
          return AppCard(
            padding: const EdgeInsets.all(10),
            onTap: () {
              final err = ref.read(posCartProvider.notifier).addProduct(p);
              if (err != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err), backgroundColor: AppColors.danger),
                );
              }
            },
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.inventory_2_outlined, size: 20, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        MoneyUtils.formatRiel(p.salePrice),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildProductGrid(List<ProductModel> products, PosCartState cart, bool isDark) {
    if (products.isEmpty) {
      return const EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'គ្មានទំនិញទេ (No Products Found)',
        subtitle: 'សាកល្បងស្វែងរកឈ្មោះផ្សេង ឬបន្ថែមទំនិញថ្មី',
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 500 ? 3 : 2);
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollExceptionStream(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.05,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final p = products[index];
          final inCart = cart.getQtyForProduct(p.id);

          return AppCard(
            padding: const EdgeInsets.all(14),
            onTap: p.isOutOfStock
                ? null
                : () {
                    final err = ref.read(posCartProvider.notifier).addProduct(p);
                    if (err != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(err), backgroundColor: AppColors.danger),
                      );
                    }
                  },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: p.isOutOfStock
                            ? AppColors.danger.withValues(alpha: 0.1)
                            : (p.isLowStock
                                ? AppColors.warning.withValues(alpha: 0.1)
                                : AppColors.success.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        p.isOutOfStock
                            ? 'អស់ពីស្តុក'
                            : '${p.stockQty} ${p.unit}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: p.isOutOfStock
                              ? AppColors.danger
                              : (p.isLowStock ? AppColors.warning : AppColors.success),
                        ),
                      ),
                    ),
                    if (inCart > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$inCart',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.fastfood_outlined, color: AppColors.primary, size: 28),
                const SizedBox(height: 8),
                Text(
                  p.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  MoneyUtils.formatRiel(p.salePrice),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildCartPanel(BuildContext context, bool isDark, PosCartState cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Cart Header & Customer Selector
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('កន្ត្រកទំនិញ (Order Cart)', style: AppTextStyles.titleLG),
                    ],
                  ),
                  if (cart.items.isNotEmpty)
                    TextButton(
                      onPressed: () => ref.read(posCartProvider.notifier).clearCart(),
                      child: const Text('Clear', style: TextStyle(color: AppColors.danger, fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(cart.customerName, style: const TextStyle(fontSize: 13)),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // 2. Cart Items List
        Expanded(
          child: cart.items.isEmpty
              ? const EmptyState(
                  icon: Icons.remove_shopping_cart_outlined,
                  title: 'កន្ត្រកនៅទំនេរ (Cart is empty)',
                  subtitle: 'ស្កេនបារកូដ ឬជ្រើសរើសទំនិញដើម្បីបញ្ចូលក្នុងវិក្កយបត្រ',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return AppCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Row 1: Name + Remove
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.product.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              InkWell(
                                onTap: () => ref.read(posCartProvider.notifier).removeItem(item.product.id),
                                child: const Icon(Icons.close, size: 18, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Row 2: Unit Price
                          Text(
                            MoneyUtils.formatRiel(item.product.salePrice),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Row 3: Stepper + Line Total
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              QtyStepper(
                                qty: item.qty,
                                maxQty: item.product.stockQty,
                                onDecrease: () => ref.read(posCartProvider.notifier).updateQty(item.product.id, item.qty - 1),
                                onIncrease: () {
                                  final err = ref.read(posCartProvider.notifier).updateQty(item.product.id, item.qty + 1);
                                  if (err != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(err), backgroundColor: AppColors.danger),
                                    );
                                  }
                                },
                              ),
                              Text(
                                MoneyUtils.formatRiel(item.lineTotal),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // 3. Sticky Summary at bottom
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
            border: Border(
              top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal:', style: TextStyle(fontSize: 13)),
                  Text(MoneyUtils.formatRiel(cart.subtotal), style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Discount:', style: TextStyle(fontSize: 13)),
                  Text(MoneyUtils.formatRiel(cart.discount), style: const TextStyle(color: AppColors.danger)),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL AMOUNT:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        MoneyUtils.formatRiel(cart.total),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        MoneyUtils.formatUSD(MoneyUtils.rielToUsd(cart.total)),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppButton(
                text: 'COMPLETE SALE (${MoneyUtils.formatRiel(cart.total)})',
                isLoading: cart.isCheckingOut,
                onPressed: cart.items.isEmpty ? null : _handleCompleteSale,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
class NeverScrollableScrollExceptionStream extends ScrollPhysics {
  const NeverScrollableScrollExceptionStream({super.parent});
  @override
  NeverScrollableScrollExceptionStream applyTo(ScrollPhysics? ancestor) {
    return NeverScrollableScrollExceptionStream(parent: buildParent(ancestor));
  }
  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => false;
}
