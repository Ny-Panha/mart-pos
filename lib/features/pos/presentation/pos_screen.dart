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
import '../../../core/widgets/capsule_tab_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/offline_bar.dart';
import '../../../core/widgets/product_thumbnail.dart';
import '../../../core/widgets/qty_stepper.dart';
import '../../../data/firestore/models/product_model.dart';
import 'package:intl/intl.dart';
import '../../../data/firestore/models/daily_close_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customers/providers/customer_provider.dart';
import '../../products/providers/category_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../shifts/presentation/close_shift_dialog.dart';
import '../../shifts/presentation/open_shift_dialog.dart';
import '../../shifts/providers/shift_provider.dart';
import '../providers/pos_cart_provider.dart';
import 'payment_dialog.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _scanController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  final FocusNode _scanFocusNode = FocusNode();
  TabController? _mobileTabController;

  @override
  void initState() {
    super.initState();
    _mobileTabController = TabController(length: 2, vsync: this);
  }

  @override
  void deactivate() {
    _scanFocusNode.unfocus();
    super.deactivate();
  }

  @override
  void dispose() {
    _scanController.dispose();
    _discountController.dispose();
    _taxController.dispose();
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
    if (Responsive.isDesktop(context)) {
      _scanFocusNode.requestFocus();
    }
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
        return Material(
          color: Colors.black,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
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
          ),
        );
      },
    );
  }

  Future<void> _handleCompleteSale() async {
    final cart = ref.read(posCartProvider);
    if (cart.items.isEmpty) return;

    final user = ref.read(authProvider).value;
    final cashierId = user?.id ?? 'cashier_unknown';
    final totalAmount = cart.total;

    String? completedInvoice;
    int? finalPaidAmount;
    int? finalChangeAmount;
    String? finalPaymentMethod;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PaymentDialog(
        totalAmount: totalAmount,
        customerName: cart.customerName,
        onConfirmPayment: ({
          required String paymentMethod,
          required int paidAmount,
          required int changeAmount,
        }) async {
          final invoiceNum = await ref.read(posCartProvider.notifier).checkout(
                cashierId: cashierId,
                paymentMethod: paymentMethod,
                paidAmount: paidAmount,
                changeAmount: changeAmount,
              );
          completedInvoice = invoiceNum;
          finalPaidAmount = paidAmount;
          finalChangeAmount = changeAmount;
          finalPaymentMethod = paymentMethod;
        },
      ),
    );

    if (mounted && completedInvoice != null) {
      _showReceiptDialog(
        invoiceNum: completedInvoice!,
        totalAmount: totalAmount,
        paidAmount: finalPaidAmount ?? totalAmount,
        changeAmount: finalChangeAmount ?? 0,
        paymentMethod: finalPaymentMethod ?? 'cash',
      );
    }
  }

  void _showReceiptDialog({
    required String invoiceNum,
    required int totalAmount,
    required int paidAmount,
    required int changeAmount,
    required String paymentMethod,
  }) {
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
            Text('វិធីទូទាត់: ${paymentMethod.toUpperCase()}'),
            const SizedBox(height: 4),
            Text('ទឹកប្រាក់សរុប: ${MoneyUtils.formatDual(totalAmount)}'),
            const SizedBox(height: 4),
            Text('ប្រាក់ទទួល: ${MoneyUtils.formatDual(paidAmount)}'),
            const SizedBox(height: 4),
            Text(
              'ប្រាក់អាប់: ${MoneyUtils.formatDual(changeAmount)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '✓ បានកត់ត្រា និងកាត់ស្តុកដោយស្វ័យប្រវត្តិ (WriteBatch Offline-First)',
                style: TextStyle(fontSize: 11, color: Colors.green),
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Receipt #$invoiceNum sent to printer')),
              );
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.print_outlined, size: 16),
            label: const Text('បោះពុម្ព (Print)'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('បិទ (Close)'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCustomerSelectorDialog() async {
    final customersAsync = ref.read(customersStreamProvider);
    final customers = customersAsync.value ?? [];

    await showDialog(
      context: context,
      builder: (ctx) {
        String filter = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = customers.where((c) {
              if (filter.isEmpty) return true;
              return c.name.toLowerCase().contains(filter.toLowerCase()) ||
                  (c.phone != null && c.phone!.contains(filter));
            }).toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ជ្រើសរើសអតិថិជន (Select Customer)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'ស្វែងរកឈ្មោះ ឬលេខទូរស័ព្ទ...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (val) {
                        setDialogState(() => filter = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                      title: const Text('អតិថិជនទូទៅ (Walk-in Customer)', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Standard non-member checkout'),
                      onTap: () {
                        ref.read(posCartProvider.notifier).setCustomer(null, 'អតិថិជនទូទៅ (Walk-in)');
                        Navigator.pop(ctx);
                      },
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Flexible(
                      child: filtered.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(16),
                              child: const Text('មិនទាន់មានអតិថិជនក្នុងបញ្ជី (ចុច + បន្ថែមអតិថិជនថ្មី)', style: TextStyle(color: Colors.grey)),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (context, idx) {
                                final cust = filtered[idx];
                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                    child: Text(cust.name.isNotEmpty ? cust.name[0] : 'C', style: const TextStyle(color: AppColors.primary)),
                                  ),
                                  title: Text(cust.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text(cust.phone ?? 'No phone'),
                                  trailing: Text(MoneyUtils.formatRiel(cust.totalSpent), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  onTap: () {
                                    ref.read(posCartProvider.notifier).setCustomer(cust.id, cust.name);
                                    Navigator.pop(ctx);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showAddCustomerDialog();
                  },
                  icon: const Icon(Icons.person_add_alt_1, size: 16),
                  label: const Text('+ បន្ថែមអតិថិជនថ្មី'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAddCustomerDialog() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: const Text('បន្ថែមអតិថិជនថ្មី (New Customer)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'ឈ្មោះ (Name) *', isDense: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'លេខទូរស័ព្ទ (Phone)', isDense: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('បោះបង់'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              try {
                final newCust = await ref.read(customerRepositoryProvider).createCustomer(
                      name: name,
                      phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                    );
                ref.read(posCartProvider.notifier).setCustomer(newCust.id, newCust.name);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Failed to add customer: $e')),
                  );
                }
              }
            },
            child: const Text('រក្សាទុក (Save)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cart = ref.watch(posCartProvider);
    final openShiftAsync = ref.watch(currentOpenShiftProvider);
    final openShift = openShiftAsync.value;

    ref.listen<PosCartState>(posCartProvider, (prev, next) {
      if (next.discount == 0 &&
          _discountController.text.isNotEmpty &&
          _discountController.text != '0') {
        _discountController.text = '';
      } else if (next.discount > 0 &&
          int.tryParse(_discountController.text.replaceAll(RegExp(r'[^0-9]'), '')) !=
              next.discount) {
        _discountController.text = '${next.discount}';
      }

      if (next.taxRate == 0.0 &&
          _taxController.text.isNotEmpty &&
          _taxController.text != '0') {
        _taxController.text = '';
      } else if (next.taxRate > 0) {
        final currentVal = double.tryParse(_taxController.text) ?? -1.0;
        final nextPct = next.taxRate * 100.0;
        if ((currentVal - nextPct).abs() > 0.01) {
          _taxController.text = nextPct.toStringAsFixed(
              nextPct.truncateToDouble() == nextPct ? 0 : 1);
        }
      }
    });

    return Scaffold(
      body: Column(
        children: [
          // 1. Top Offline Status Bar
          const OfflineBar(),

          // 2. Warning banner when no cashier shift is open
          if (openShift == null && !openShiftAsync.isLoading)
            _buildNoShiftWarningBanner(context),

          // 3. Main Content Area
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
    final openShift = ref.watch(currentOpenShiftProvider).value;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Scan Bar & Shift status chip in top area
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 560;
              return Row(
                children: [
                  _buildShiftStatusChip(context, openShift, isDark),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _scanController,
                      focusNode: _scanFocusNode,
                      autofocus: false,
                      onSubmitted: _onBarcodeSubmitted,
                      decoration: InputDecoration(
                        hintText: isNarrow ? 'ស្កេន ឬវាយកូដ...' : 'ស្កេនបារកូដ ឬវាយលេខកូដ (Enter to add)...',
                        prefixIcon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
                          onPressed: () => _onBarcodeSubmitted(_scanController.text),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 48,
                    child: isNarrow
                        ? ElevatedButton(
                            onPressed: _openCameraScanner,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              backgroundColor: AppColors.secondary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.button),
                              ),
                            ),
                            child: const Icon(Icons.camera_alt_outlined, size: 20),
                          )
                        : ElevatedButton.icon(
                            onPressed: _openCameraScanner,
                            icon: const Icon(Icons.camera_alt_outlined, size: 20),
                            label: const Text('CAMERA SCAN'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              backgroundColor: AppColors.secondary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.button),
                              ),
                            ),
                          ),
                  ),
                ],
              );
            },
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
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 560;
              final searchWidget = SizedBox(
                width: isNarrow ? double.infinity : 240,
                child: TextField(
                  onChanged: (v) => ref.read(productSearchQueryProvider.notifier).setQuery(v),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'ស្វែងរកឈ្មោះទំនិញ...',
                    prefixIcon: Icon(Icons.search, size: 18),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('បញ្ជីទំនិញទាំងអស់ (All Products)', style: AppTextStyles.titleLG),
                    const SizedBox(height: 10),
                    searchWidget,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('បញ្ជីទំនិញទាំងអស់ (All Products)', style: AppTextStyles.titleLG),
                  searchWidget,
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          // 5. Category Chips Filter (connected to Admin Products Categories)
          _buildCategoryChips(isDark),
          const SizedBox(height: 14),

          // 6. Product Grid
          _buildProductGrid(filteredProducts, cart, isDark),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(bool isDark) {
    final categories = ref.watch(categoriesStreamProvider).value ?? [];
    final selectedCategory = ref.watch(selectedCategoryProvider);

    final items = [
      const CapsuleTabItem(label: 'ទាំងអស់ (All)', icon: Icons.grid_view_rounded),
      for (final cat in categories)
        CapsuleTabItem(label: cat.name, icon: Icons.category_outlined),
    ];

    int selectedIdx = 0;
    if (selectedCategory != 'all') {
      final found = categories.indexWhere((c) => c.id == selectedCategory);
      if (found >= 0) selectedIdx = found + 1;
    }

    return CapsuleTabBar(
      items: items,
      selectedIndex: selectedIdx,
      isDense: true,
      onTabSelected: (idx) {
        if (idx == 0) {
          ref.read(selectedCategoryProvider.notifier).setCategory('all');
        } else {
          final cat = categories[idx - 1];
          ref.read(selectedCategoryProvider.notifier).setCategory(cat.id);
        }
      },
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 520;
        final thumb = ProductThumbnail(
          imageUrl: product.imageUrl,
          productId: product.id,
          productName: product.name,
          barcode: product.barcode,
          width: isNarrow ? 68 : 88,
          height: isNarrow ? 68 : 88,
          borderRadius: AppRadius.md,
          fallbackIcon: Icons.inventory_2_rounded,
        );

        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
            Text(product.name, style: AppTextStyles.titleLG, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
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
        );

        final priceAndAdd = Column(
          crossAxisAlignment: isNarrow ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              MoneyUtils.formatRiel(product.salePrice),
              style: TextStyle(
                fontSize: isNarrow ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              MoneyUtils.formatUSD(MoneyUtils.rielToUsd(product.salePrice)),
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 6),
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
        );

        if (isNarrow) {
          return AppCard(
            isFrosted: true,
            padding: const EdgeInsets.all(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    thumb,
                    const SizedBox(width: 12),
                    Expanded(child: details),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Price:', style: AppTextStyles.caption),
                    priceAndAdd,
                  ],
                ),
              ],
            ),
          );
        }

        return AppCard(
          isFrosted: true,
          padding: const EdgeInsets.all(18),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
          child: Row(
            children: [
              thumb,
              const SizedBox(width: 16),
              Expanded(child: details),
              const SizedBox(width: 12),
              priceAndAdd,
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentScansGrid(List<ProductModel> products, bool isDark) {
    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = constraints.maxWidth > 700 ? 4 : 2;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
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
                ProductThumbnail(
                  imageUrl: p.imageUrl,
                  productId: p.id,
                  productName: p.name,
                  barcode: p.barcode,
                  width: 44,
                  height: 44,
                  borderRadius: 8,
                  fallbackIcon: Icons.fastfood_outlined,
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
      final ratio = constraints.maxWidth > 900 ? 0.74 : (constraints.maxWidth > 500 ? 0.72 : 0.70);

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: ratio,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final p = products[index];
          final inCart = cart.getQtyForProduct(p.id);

          return AppCard(
            isFrosted: true,
            padding: const EdgeInsets.all(12),
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
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black.withValues(alpha: 0.15) : AppColors.lightBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: ProductThumbnail(
                      imageUrl: p.imageUrl,
                      productId: p.id,
                      productName: p.name,
                      barcode: p.barcode,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                      borderRadius: 8,
                      fallbackIcon: Icons.fastfood_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  p.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.25),
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
                Text(
                  MoneyUtils.formatUSD(MoneyUtils.rielToUsd(p.salePrice)),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
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
              InkWell(
                onTap: _showCustomerSelectorDialog,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
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
                        child: Text(cart.customerName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 18),
                    ],
                  ),
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
                    return _CartItemTile(
                      key: ValueKey(item.product.id),
                      item: item,
                      isDark: isDark,
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
              const SizedBox(height: 8),

              // Direct Input: Discount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Discount (បញ្ចុះតម្លៃ):', style: TextStyle(fontSize: 13)),
                  SizedBox(
                    width: 120,
                    height: 34,
                    child: TextField(
                      controller: _discountController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.danger,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        hintText: '0',
                        suffixText: '៛',
                        suffixStyle: const TextStyle(fontSize: 12, color: AppColors.danger),
                        filled: true,
                        fillColor: isDark ? AppColors.darkCard : AppColors.lightBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                      onChanged: (val) {
                        final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
                        final discount = int.tryParse(clean) ?? 0;
                        ref.read(posCartProvider.notifier).setDiscount(discount);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Direct Input: Tax
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tax / អាករ:', style: TextStyle(fontSize: 13)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 34,
                        child: TextField(
                          controller: _taxController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            hintText: '0',
                            suffixText: '%',
                            suffixStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                            ),
                            filled: true,
                            fillColor: isDark ? AppColors.darkCard : AppColors.lightBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                          ),
                          onChanged: (val) {
                            final clean = val.replaceAll(RegExp(r'[^0-9.]'), '');
                            final parsed = double.tryParse(clean) ?? 0.0;
                            final rate = (parsed / 100.0).clamp(0.0, 1.0);
                            ref.read(posCartProvider.notifier).setTaxRate(rate);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        MoneyUtils.formatRiel(cart.totalTax),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
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

  Widget _buildNoShiftWarningBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.amber.shade800,
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'No open shift — sales won\'t appear in shift report (មិនទាន់បើកវេនលក់)',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.amber.shade900,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
            ),
            icon: const Icon(Icons.lock_open_rounded, size: 16),
            label: const Text('OPEN SHIFT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: () => OpenShiftDialog.show(context),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftStatusChip(BuildContext context, DailyCloseModel? shift, bool isDark) {
    final isOpen = shift != null;
    final timeStr = isOpen ? DateFormat('HH:mm').format(shift.openedAt) : '';

    return InkWell(
      onTap: () {
        if (isOpen) {
          CloseShiftDialog.show(context, shift);
        } else {
          OpenShiftDialog.show(context);
        }
      },
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isOpen
              ? AppColors.success.withValues(alpha: 0.12)
              : (isDark ? AppColors.darkBorder : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(
            color: isOpen
                ? AppColors.success.withValues(alpha: 0.4)
                : (isDark ? AppColors.darkBorder : Colors.grey.shade400),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOpen ? AppColors.success : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                boxShadow: isOpen
                    ? [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isOpen ? 'Shift open · $timeStr' : 'No shift',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isOpen
                    ? AppColors.success
                    : (isDark ? AppColors.darkMutedText : Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemTile extends ConsumerStatefulWidget {
  final CartItemState item;
  final bool isDark;

  const _CartItemTile({
    super.key,
    required this.item,
    required this.isDark,
  });

  @override
  ConsumerState<_CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends ConsumerState<_CartItemTile> {
  late TextEditingController _priceController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: '${widget.item.unitPrice}');
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      final clean = _priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final val = int.tryParse(clean);
      if (val == null || val < 0) {
        // Reset to original sale price if invalid
        ref.read(posCartProvider.notifier).updateItemPrice(widget.item.product.id, null);
        _priceController.text = '${widget.item.product.salePrice}';
      } else {
        ref.read(posCartProvider.notifier).updateItemPrice(
              widget.item.product.id,
              val == widget.item.product.salePrice ? null : val,
            );
        _priceController.text = '$val';
      }
    }
  }

  @override
  void didUpdateWidget(covariant _CartItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && widget.item.unitPrice != oldWidget.item.unitPrice) {
      _priceController.text = '${widget.item.unitPrice}';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = widget.isDark;
    final hasCustomPrice = item.customPrice != null;

    return AppCard(
      isFrosted: true,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductThumbnail(
            imageUrl: item.product.imageUrl,
            productId: item.product.id,
            productName: item.product.name,
            barcode: item.product.barcode,
            width: 48,
            height: 48,
            borderRadius: 8,
            fallbackIcon: Icons.fastfood_outlined,
          ),
          const SizedBox(width: 10),
          Expanded(
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

                // Row 2: Strikethrough original price if modified
                if (hasCustomPrice) ...[
                  Row(
                    children: [
                      Text(
                        'ដើម: ${MoneyUtils.formatRiel(item.product.salePrice)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () {
                          ref.read(posCartProvider.notifier).updateItemPrice(item.product.id, null);
                          _priceController.text = '${item.product.salePrice}';
                        },
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],

                // Row 3: Stepper + Direct Price Input + Line Total
                Row(
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
                      onQtyChanged: (newQty) {
                        final err = ref.read(posCartProvider.notifier).updateQty(item.product.id, newQty);
                        if (err != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err), backgroundColor: AppColors.danger),
                          );
                        }
                      },
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Direct Inline Price Input Field
                        SizedBox(
                          width: 100,
                          height: 32,
                          child: TextField(
                            focusNode: _focusNode,
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: hasCustomPrice
                                  ? AppColors.warning
                                  : (isDark ? AppColors.darkText : AppColors.lightText),
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              suffixText: '៛',
                              suffixStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: hasCustomPrice
                                    ? AppColors.warning
                                    : (isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
                              ),
                              filled: true,
                              fillColor: hasCustomPrice
                                  ? AppColors.warning.withValues(alpha: 0.1)
                                  : (isDark ? AppColors.darkSurface : AppColors.lightBg),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                borderSide: BorderSide(
                                  color: hasCustomPrice
                                      ? AppColors.warning
                                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                borderSide: BorderSide(
                                  color: hasCustomPrice
                                      ? AppColors.warning
                                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                              ),
                            ),
                            onChanged: (val) {
                              final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
                              final newPrice = int.tryParse(clean);
                              if (newPrice != null && newPrice >= 0) {
                                ref.read(posCartProvider.notifier).updateItemPrice(
                                      item.product.id,
                                      newPrice == item.product.salePrice ? null : newPrice,
                                    );
                              }
                            },
                          ),
                        ),
                        if (item.qty > 1) ...[
                          const SizedBox(height: 2),
                          Text(
                            '= ${MoneyUtils.formatRiel(item.lineTotal)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
