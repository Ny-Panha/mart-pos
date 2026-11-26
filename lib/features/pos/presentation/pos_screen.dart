import 'package:mart_pos/core/motion/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/receipt_printer.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/receipt_preview_dialog.dart';
import '../../../core/widgets/offline_bar.dart';
import '../../../core/widgets/qty_stepper.dart';
import '../../../data/firestore/models/product_model.dart';

import '../../../data/firestore/models/daily_close_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../products/providers/category_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../shifts/providers/shift_provider.dart';
import '../providers/pos_cart_provider.dart';
import 'payment_dialog.dart';
import 'pos_product_card.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _scanController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  final FocusNode _scanFocusNode = FocusNode();
  late final TabController _mobileTabController;
  final _cartScroll = ScrollController();
  bool _paymentOpen = false;
  bool _online = true;
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    _scanController.text = ref.read(productSearchQueryProvider);
    _syncAdjustments(ref.read(posCartProvider));
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
    _mobileTabController.dispose();
    _cartScroll.dispose();
    super.dispose();
  }

  void _onBarcodeSubmitted(String barcode) {
    if (barcode.trim().isEmpty) return;

    final products = ref.read(productsStreamProvider).value ?? [];
    final match = products.where(
      (p) =>
          p.barcode.toLowerCase() == barcode.trim().toLowerCase() ||
          p.code.toLowerCase() == barcode.trim().toLowerCase() ||
          p.sku.toLowerCase() == barcode.trim().toLowerCase(),
    );

    if (match.isNotEmpty) {
      final product = match.first;
      final error = ref
          .read(posCartProvider.notifier)
          .addProduct(product, isBarcodeScan: true);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: error.contains('Anti-double-scan')
                ? Colors.orange
                : AppColors.danger,
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
    ref.read(productSearchQueryProvider.notifier).setQuery('');
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Scan Product Barcode',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: MobileScanner(
                      onDetect: (capture) {
                        final barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty &&
                            barcodes.first.rawValue != null) {
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

  Future<void> _handleCompleteSale({bool retry = false}) async {
    final cart = ref.read(posCartProvider);
    if (_resolving ||
        _paymentOpen ||
        !_online ||
        cart.items.isEmpty ||
        cart.isCheckingOut ||
        cart.isPendingUnresolved != retry) {
      return;
    }

    final cashierId = ref.read(authProvider).value?.id ?? 'cashier_unknown';
    String? invoice;
    late String method;
    late int paid, change;

    Future<void> submit({
      required String paymentMethod,
      required int paidAmount,
      required int changeAmount,
      double? receivedUsd,
      double? changeUsd,
    }) async {
      if (!_online) throw StateError('Checkout requires a connection.');
      invoice = await ref
          .read(posCartProvider.notifier)
          .checkout(
            cashierId: cashierId,
            paymentMethod: paymentMethod,
            paidAmount: paidAmount,
            changeAmount: changeAmount,
            receivedUsd: receivedUsd,
            changeUsd: changeUsd,
          );
      method = paymentMethod;
      paid = paidAmount;
      change = changeAmount;
    }

    _paymentOpen = true;
    try {
      final saved = cart.activeCheckoutPayload;
      if (retry && saved != null) {
        // Replay the tender already recorded for this operation, including on the receipt.
        final usd = saved['payment_method'] == 'cash_usd';
        await submit(
          paymentMethod: saved['payment_method'] as String,
          paidAmount: saved['received_riel'] as int,
          changeAmount: saved['change_riel'] as int,
          receivedUsd: usd
              ? double.tryParse(saved['received_usd'].toString())
              : null,
          changeUsd: usd
              ? double.tryParse(saved['change_usd'].toString())
              : null,
        );
      } else {
        await showMotionDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => PaymentDialog(
            totalAmount: cart.total,
            customerName: cart.customerName,
            requiresRecovery: () =>
                ref.read(posCartProvider).isPendingUnresolved,
            onConfirmPayment: submit,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Checkout failed: $error')));
      }
    } finally {
      if (mounted) setState(() => _paymentOpen = false);
    }
    if (mounted && invoice != null) {
      _showReceiptDialog(
        invoiceNum: invoice!,
        totalAmount: cart.total,
        paidAmount: paid,
        changeAmount: change,
        paymentMethod: method,
        cart: cart,
      );
    }
  }

  void _showReceiptDialog({
    required String invoiceNum,
    required int totalAmount,
    required int paidAmount,
    required int changeAmount,
    required String paymentMethod,
    required PosCartState cart,
  }) {
    showMotionDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 28),
            SizedBox(width: 10),
            Expanded(child: Text('ការទូទាត់ជោគជ័យ!')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'លេខវិក្កយបត្រ (Invoice): $invoiceNum',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('វិធីទូទាត់: ${paymentMethod.toUpperCase()}'),
            const SizedBox(height: 4),
            Text('ទឹកប្រាក់សរុប: ${MoneyUtils.formatDual(totalAmount)}'),
            const SizedBox(height: 4),
            Text('ប្រាក់ទទួល: ${MoneyUtils.formatDual(paidAmount)}'),
            const SizedBox(height: 4),
            Text(
              'ប្រាក់អាប់: ${MoneyUtils.formatDual(changeAmount)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final receiptData = ReceiptData(
                      invoiceNumber: invoiceNum,
                      createdAt: DateTime.now(),
                      paymentMethod: paymentMethod,
                      items: cart.items
                          .map(
                            (i) => ReceiptItemData(
                              name: i.product.name,
                              qty: i.qty,
                              unitPrice: i.unitPrice,
                              totalPrice: i.lineTotal,
                            ),
                          )
                          .toList(),
                      subtotal: cart.subtotal,
                      discount: cart.discount,
                      tax: cart.totalTax,
                      total: totalAmount,
                      paid: paidAmount,
                      change: changeAmount,
                    );
                    Navigator.pop(ctx);
                    await ReceiptPreviewDialog.show(context, data: receiptData);
                  },
                  icon: const Icon(Icons.print_outlined, size: 16),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('បោះពុម្ព (Print)'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('បិទ (Close)'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).then((_) {
      if (mounted && _mobileTabController.index != 0) {
        _mobileTabController.animateTo(0);
      }
    });
  }

  void _syncAdjustments(PosCartState next) {
    if (next.discount == 0 &&
        _discountController.text.isNotEmpty &&
        _discountController.text != '0') {
      _discountController.text = '';
    } else if (next.discount > 0 &&
        int.tryParse(
              _discountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
            ) !=
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
          nextPct.truncateToDouble() == nextPct ? 0 : 1,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final cart = ref.watch(posCartProvider);
    final openShiftAsync = ref.watch(currentOpenShiftProvider);

    ref.listen<PosCartState>(posCartProvider, (prev, next) {
      _syncAdjustments(next);
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            OfflineBar(
              onConnectivityChanged: (value) => setState(() => _online = value),
            ),
            if (cart.isPendingUnresolved && !cart.isCheckingOut)
              _buildUnresolvedCheckoutBanner(context, cart),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final split = isDesktop && constraints.maxWidth >= 680;
                  final catalog = _buildProductBrowser(
                    cart,
                    openShiftAsync,
                    split,
                  );
                  final panel = _buildCartPanel(cart, split);
                  return split
                      ? Row(
                          children: [
                            Expanded(child: catalog),
                            const VerticalDivider(width: 1),
                            SizedBox(
                              width: constraints.maxWidth >= 960 ? 384 : 320,
                              child: panel,
                            ),
                          ],
                        )
                      : TabBarView(
                          controller: _mobileTabController,
                          children: [catalog, panel],
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _add(ProductModel product) {
    final error = ref.read(posCartProvider.notifier).addProduct(product);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _viewCart(bool split) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (split) {
      _cartScroll.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } else {
      _mobileTabController.animateTo(1);
    }
  }

  Widget _buildProductBrowser(
    PosCartState cart,
    AsyncValue<DailyCloseModel?> shift,
    bool split,
  ) {
    final products = ref.watch(filteredProductsProvider);
    final catalog = ref.watch(productsStreamProvider);
    final colors = Theme.of(context).colorScheme;
    final locked = cart.isCheckingOut || cart.isPendingUnresolved;
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            key: const PageStorageKey('catalog'),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverList.list(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'បញ្ជីទំនិញ',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          tooltip: 'View cart',
                          onPressed: () => _viewCart(split),
                          icon: Badge(
                            label: Text('${cart.totalItemCount}'),
                            backgroundColor: colors.primary,
                            textColor: colors.onPrimary,
                            child: const Icon(Icons.shopping_bag_outlined),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _scanController,
                      focusNode: _scanFocusNode,
                      onChanged: (v) => ref
                          .read(productSearchQueryProvider.notifier)
                          .setQuery(v),
                      onSubmitted: _onBarcodeSubmitted,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'ស្វែងរក ឬស្កេនបារកូដ',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          tooltip: 'Scan barcode',
                          icon: const Icon(Icons.qr_code_scanner),
                          onPressed: _openCameraScanner,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCategoryChips(catalog.value ?? []),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${products.length} products',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ),
                          if (cart.recentScans.isNotEmpty)
                            TextButton.icon(
                              icon: const Icon(Icons.history, size: 16),
                              label: const Text('Recent scans'),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () => _showRecentScans(cart),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (catalog.isLoading && products.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (products.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        catalog.hasError
                            ? 'Catalog unavailable'
                            : 'រកមិនឃើញទំនិញ',
                      ),
                    ),
                  ),
                )
              else
                _buildProductGrid(products, cart, locked),
            ],
          ),
        ),
        if (!split && cart.items.isNotEmpty)
          _ActionFooter(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${cart.totalItemCount} ${cart.totalItemCount == 1 ? 'item' : 'items'}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      Text(
                        MoneyUtils.formatRiel(cart.total),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _viewCart(false),
                  icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                  label: const Text('View cart'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryChips(List<ProductModel> catalog) {
    final categories = ref.watch(categoriesStreamProvider).value ?? [];
    final selected = ref.watch(selectedCategoryProvider);
    final ids = {
      for (final p in catalog)
        if (p.categoryId.isNotEmpty) p.categoryId,
      if (selected != 'all') selected,
    };
    final names = {for (final c in categories) c.id: c.name};
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (id, label) in [
            ('all', 'ទាំងអស់'),
            for (final c in categories)
              if (ids.contains(c.id)) (c.id, c.name),
            for (final id in ids)
              if (!names.containsKey(id)) (id, id),
          ])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                shape: const StadiumBorder(),
                side: BorderSide.none,
                showCheckmark: false,
                label: Text(label),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected == id ? colors.onPrimary : colors.onSurface,
                ),
                selectedColor: colors.primary,
                backgroundColor: colors.surfaceContainerHigh,
                selected: selected == id,
                onSelected: (_) =>
                    ref.read(selectedCategoryProvider.notifier).setCategory(id),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(
    List<ProductModel> products,
    PosCartState cart,
    bool locked,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final columns = width < 248 ? 1 : (width / 174).floor().clamp(2, 8);
          final cardWidth = (width - (columns - 1) * 12) / columns;
          return SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent:
                  cardWidth + 16 + MediaQuery.textScalerOf(context).scale(108),
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final qty = cart.getQtyForProduct(product.id);
              return PosProductCard(
                product: product,
                quantity: qty,
                onAdd: locked || qty >= product.stockQty
                    ? null
                    : () => _add(product),
              );
            },
          );
        },
      ),
    );
  }

  void _showRecentScans(PosCartState cart) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text('Recent scans', style: Theme.of(ctx).textTheme.titleLarge),
          for (final product in cart.recentScans)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: PosProductPhoto(product: product, size: 48),
              title: Text(product.name),
              subtitle: Text(
                [
                  if (cart.lastScannedProduct?.id == product.id) 'Last scanned',
                  product.barcode,
                  product.sku,
                  '${product.stockQty} ${product.unit}',
                  MoneyUtils.formatDual(product.salePrice),
                ].where((s) => s.isNotEmpty).join(' · '),
              ),
              trailing: IconButton(
                tooltip: 'Add ${product.name}',
                icon: const Icon(Icons.add_circle_outline),
                onPressed:
                    cart.isPendingUnresolved ||
                        cart.getQtyForProduct(product.id) >= product.stockQty
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _add(product);
                      },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCartPanel(PosCartState cart, bool split) {
    final theme = Theme.of(context);
    final locked = cart.isCheckingOut || cart.isPendingUnresolved;
    final notifier = ref.read(posCartProvider.notifier);
    return Material(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _cartScroll,
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    if (!split)
                      IconButton(
                        tooltip: 'Back to catalog',
                        onPressed: () => _mobileTabController.animateTo(0),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    Expanded(
                      child: Text(
                        'កន្ត្រកទំនិញ',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (cart.items.isNotEmpty)
                      TextButton(
                        onPressed: locked ? null : notifier.clearCart,
                        child: const Text('Clear'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (cart.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text('កន្ត្រកនៅទំនេរ (Cart is empty)'),
                    ),
                  ),
                for (final item in cart.items)
                  _CartItemTile(
                    key: ValueKey(item.product.id),
                    item: item,
                    locked: locked,
                  ),
                const SizedBox(height: 16),
                Text(
                  'Order summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'Subtotal',
                  value: Text(MoneyUtils.formatRiel(cart.subtotal)),
                ),
                _SummaryRow(
                  label: 'បញ្ចុះតម្លៃ',
                  value: _NumberField(
                    label: 'Discount',
                    suffix: '៛',
                    controller: _discountController,
                    enabled: !locked,
                    onChanged: (v) => notifier.setDiscount(
                      int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
                    ),
                  ),
                ),
                _SummaryRow(
                  label: 'អាករ · ${MoneyUtils.formatRiel(cart.totalTax)}',
                  value: _NumberField(
                    label: 'Tax',
                    suffix: '%',
                    decimal: true,
                    controller: _taxController,
                    enabled: !locked,
                    onChanged: (v) {
                      final percent =
                          double.tryParse(
                            v.replaceAll(RegExp(r'[^0-9.]'), ''),
                          ) ??
                          0;
                      notifier.setTaxRate((percent / 100).clamp(0, 1));
                    },
                  ),
                ),
                const Divider(height: 24),
                _SummaryRow(
                  label: 'សរុប',
                  value: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        MoneyUtils.formatRiel(cart.total),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        MoneyUtils.formatUSD(MoneyUtils.rielToUsd(cart.total)),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _ActionFooter(
            child: FilledButton(
              key: const ValueKey('checkout'),
              onPressed: !_online || locked || cart.items.isEmpty
                  ? null
                  : _handleCompleteSale,
              child: cart.isCheckingOut
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('ទូទាត់ · ${MoneyUtils.formatRiel(cart.total)}'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnresolvedCheckoutBanner(
    BuildContext context,
    PosCartState cart,
  ) {
    final colors = Theme.of(context).colorScheme;
    final available = _online && !_resolving && !_paymentOpen;
    return Material(
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Checkout awaiting verification · ${cart.activeInvoiceNumber ?? cart.activeOperationId}',
              style: TextStyle(
                color: colors.onErrorContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            Wrap(
              spacing: 4,
              children: [
                TextButton(
                  onPressed: available
                      ? () => _resolveCheckout(dismiss: false)
                      : null,
                  child: const Text('Reconcile'),
                ),
                TextButton(
                  onPressed: available && cart.items.isNotEmpty
                      ? () => _handleCompleteSale(retry: true)
                      : null,
                  child: const Text('Retry'),
                ),
                TextButton(
                  onPressed: available
                      ? () => _resolveCheckout(dismiss: true)
                      : null,
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resolveCheckout({required bool dismiss}) async {
    if (_resolving || _paymentOpen) return;
    setState(() => _resolving = true);
    final notifier = ref.read(posCartProvider.notifier);
    String message;
    try {
      if (dismiss) {
        await notifier.cancelOrDismissUnresolvedCheckout();
        message = 'Checkout resolved.';
      } else {
        final invoice = await notifier.reconcileActiveCheckout();
        if (!mounted) return;
        message = invoice != null
            ? 'Order confirmed · $invoice'
            : ref.read(posCartProvider).isPendingUnresolved
            ? 'Checkout is still unresolved.'
            : 'Checkout resolved and cleared.';
      }
    } catch (error) {
      message = 'Verification: $error';
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _CartItemTile extends ConsumerStatefulWidget {
  final CartItemState item;
  final bool locked;

  const _CartItemTile({super.key, required this.item, required this.locked});

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
        ref
            .read(posCartProvider.notifier)
            .updateItemPrice(widget.item.product.id, null);
        _priceController.text = '${widget.item.product.salePrice}';
      } else {
        ref
            .read(posCartProvider.notifier)
            .updateItemPrice(
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
    if (!_focusNode.hasFocus &&
        widget.item.unitPrice != oldWidget.item.unitPrice) {
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
    final notifier = ref.read(posCartProvider.notifier);
    final theme = Theme.of(context);
    void setQuantity(int qty) {
      final error = notifier.updateQty(item.product.id, qty);
      if (error != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              PosProductPhoto(product: item.product, size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      MoneyUtils.formatRiel(item.lineTotal),
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove ${item.product.name}',
                onPressed: widget.locked
                    ? null
                    : () => notifier.removeItem(item.product.id),
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NumberField(
                label: 'Unit price',
                suffix: '៛',
                controller: _priceController,
                focus: _focusNode,
                enabled: !widget.locked,
                onChanged: (v) {
                  final price = int.tryParse(
                    v.replaceAll(RegExp(r'[^0-9]'), ''),
                  );
                  if (price != null) {
                    notifier.updateItemPrice(
                      item.product.id,
                      price == item.product.salePrice ? null : price,
                    );
                  }
                },
              ),
              IgnorePointer(
                ignoring: widget.locked,
                child: ExcludeFocus(
                  excluding: widget.locked,
                  child: Opacity(
                    opacity: widget.locked ? 0.5 : 1,
                    child: QtyStepper(
                      qty: item.qty,
                      maxQty: item.product.stockQty,
                      onIncrease: () => setQuantity(item.qty + 1),
                      onDecrease: () => setQuantity(item.qty - 1),
                      onQtyChanged: setQuantity,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (item.customPrice != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: widget.locked
                    ? null
                    : () => notifier.updateItemPrice(item.product.id, null),
                child: Text(
                  'Reset to ${MoneyUtils.formatRiel(item.product.salePrice)}',
                ),
              ),
            ),
          const SizedBox(height: 12),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.suffix,
    required this.controller,
    required this.enabled,
    required this.onChanged,
    this.focus,
    this.decimal = false,
  });
  final String label, suffix;
  final TextEditingController controller;
  final FocusNode? focus;
  final bool enabled, decimal;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 108,
    child: TextField(
      controller: controller,
      focusNode: focus,
      enabled: enabled,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      textAlign: TextAlign.end,
      style: const TextStyle(fontSize: 14),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixText: suffix,
        hintText: '0',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final Widget value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        value,
      ],
    ),
  );
}

class _ActionFooter extends StatelessWidget {
  const _ActionFooter({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(
        top: BorderSide(
          color:
              Theme.of(context).dividerTheme.color ??
              Theme.of(context).dividerColor,
        ),
      ),
    ),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: child,
    ),
  );
}
