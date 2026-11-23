import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/money.dart';
import '../../../data/firestore/models/product_model.dart';
import '../../../data/firestore/models/sale_model.dart';
import '../../../data/repositories/sale_repository.dart';
import '../../../data/services/audit_service.dart';
import '../../../data/services/invoice_counter_service.dart';
import '../../auth/providers/auth_provider.dart';

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  return SaleRepository();
});

class CartItemState {
  final ProductModel product;
  final int qty;
  final int? customPrice;

  CartItemState({
    required this.product,
    required this.qty,
    this.customPrice,
  });

  int get unitPrice => customPrice ?? product.salePrice;
  int get lineTotal => unitPrice * qty;

  CartItemState copyWith({
    int? qty,
    int? customPrice,
    bool clearCustomPrice = false,
  }) {
    return CartItemState(
      product: product,
      qty: qty ?? this.qty,
      customPrice: clearCustomPrice ? null : (customPrice ?? this.customPrice),
    );
  }
}

class PosCartState {
  final List<CartItemState> items;
  final String? customerId;
  final String customerName;
  final int discount; // int Riel
  final double taxRate; // e.g. 0.05 = 5%
  final ProductModel? lastScannedProduct;
  final List<ProductModel> recentScans;
  final bool isCheckingOut;
  final String? lastCompletedInvoice;
  final String? activeOperationId;
  final String? activeInvoiceNumber;

  PosCartState({
    this.items = const [],
    this.customerId,
    this.customerName = 'អតិថិជនទូទៅ (Walk-in)',
    this.discount = 0,
    this.taxRate = 0.0,
    this.lastScannedProduct,
    this.recentScans = const [],
    this.isCheckingOut = false,
    this.lastCompletedInvoice,
    this.activeOperationId,
    this.activeInvoiceNumber,
  });

  int get subtotal => items.fold(0, (sum, i) => sum + i.lineTotal);
  int get totalTax => ((subtotal - discount) > 0 ? ((subtotal - discount) * taxRate).round() : 0);
  int get total => (subtotal - discount + totalTax) > 0 ? (subtotal - discount + totalTax) : 0;
  int get totalItemCount => items.fold(0, (sum, i) => sum + i.qty);

  int getQtyForProduct(String productId) {
    final found = items.where((i) => i.product.id == productId);
    return found.isEmpty ? 0 : found.first.qty;
  }

  PosCartState copyWith({
    List<CartItemState>? items,
    String? customerId,
    String? customerName,
    int? discount,
    double? taxRate,
    ProductModel? lastScannedProduct,
    List<ProductModel>? recentScans,
    bool? isCheckingOut,
    String? lastCompletedInvoice,
    String? activeOperationId,
    String? activeInvoiceNumber,
    bool clearLastScan = false,
    bool clearActiveOperation = false,
  }) {
    return PosCartState(
      items: items ?? this.items,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      discount: discount ?? this.discount,
      taxRate: taxRate ?? this.taxRate,
      lastScannedProduct: clearLastScan ? null : (lastScannedProduct ?? this.lastScannedProduct),
      recentScans: recentScans ?? this.recentScans,
      isCheckingOut: isCheckingOut ?? this.isCheckingOut,
      lastCompletedInvoice: lastCompletedInvoice ?? this.lastCompletedInvoice,
      activeOperationId: clearActiveOperation ? null : (activeOperationId ?? this.activeOperationId),
      activeInvoiceNumber: clearActiveOperation ? null : (activeInvoiceNumber ?? this.activeInvoiceNumber),
    );
  }
}

class PosCartNotifier extends Notifier<PosCartState> {
  final InvoiceCounterService _invoiceService = InvoiceCounterService();

  // Anti-double-scan: ignore the same barcode scanned twice within 1.5 seconds (1500ms)
  String? _lastScannedBarcode;
  DateTime? _lastScannedTime;

  @override
  PosCartState build() {
    return PosCartState();
  }

  /// Returns null on success, or an error message if stock exceeded or double scanned
  String? addProduct(ProductModel product, {bool isBarcodeScan = false}) {
    // 1. Anti-double-scan validation (1.5 seconds)
    final now = DateTime.now();
    if (isBarcodeScan && product.barcode.isNotEmpty) {
      if (_lastScannedBarcode == product.barcode &&
          _lastScannedTime != null &&
          now.difference(_lastScannedTime!).inMilliseconds < 1500) {
        return 'Anti-double-scan: Barcode ignored within 1.5s';
      }
      _lastScannedBarcode = product.barcode;
      _lastScannedTime = now;
    }

    // 2. Strict Stock check
    final currentQtyInCart = state.getQtyForProduct(product.id);
    if (currentQtyInCart + 1 > product.stockQty) {
      return 'Requested quantity exceeds available stock (${product.stockQty} ${product.unit})';
    }

    // 3. Add or increment in cart
    final updatedList = List<CartItemState>.from(state.items);
    final index = updatedList.indexWhere((i) => i.product.id == product.id);

    if (index >= 0) {
      updatedList[index] = updatedList[index].copyWith(qty: updatedList[index].qty + 1);
    } else {
      updatedList.add(CartItemState(product: product, qty: 1));
    }

    // 4. Update recent scans list (keep max 6 unique)
    final updatedRecent = List<ProductModel>.from(state.recentScans);
    updatedRecent.removeWhere((p) => p.id == product.id);
    updatedRecent.insert(0, product);
    if (updatedRecent.length > 6) {
      updatedRecent.removeLast();
    }

    state = state.copyWith(
      items: updatedList,
      lastScannedProduct: product,
      recentScans: updatedRecent,
      clearActiveOperation: true,
    );

    return null;
  }

  String? updateQty(String productId, int newQty) {
    final updatedList = List<CartItemState>.from(state.items);
    final index = updatedList.indexWhere((i) => i.product.id == productId);

    if (index < 0) return null;

    if (newQty <= 0) {
      updatedList.removeAt(index);
      state = state.copyWith(items: updatedList, clearActiveOperation: true);
      return null;
    }

    final product = updatedList[index].product;
    if (newQty > product.stockQty) {
      return 'Requested quantity exceeds stock (${product.stockQty} ${product.unit})';
    }

    updatedList[index] = updatedList[index].copyWith(qty: newQty);
    state = state.copyWith(items: updatedList, clearActiveOperation: true);
    return null;
  }

  void updateItemPrice(String productId, int? customPrice) {
    final updatedList = List<CartItemState>.from(state.items);
    final index = updatedList.indexWhere((i) => i.product.id == productId);

    if (index >= 0) {
      updatedList[index] = updatedList[index].copyWith(
        customPrice: customPrice,
        clearCustomPrice: customPrice == null,
      );
      state = state.copyWith(items: updatedList, clearActiveOperation: true);
    }
  }

  void removeItem(String productId) {
    final updatedList = List<CartItemState>.from(state.items)
      ..removeWhere((i) => i.product.id == productId);
    state = state.copyWith(items: updatedList, clearActiveOperation: true);
  }

  void setCustomer(String? id, String name) {
    state = state.copyWith(
      customerId: id,
      customerName: name,
      clearActiveOperation: true,
    );
  }

  void setDiscount(int discountRiel) {
    state = state.copyWith(discount: discountRiel, clearActiveOperation: true);
  }

  void setTaxRate(double rate) {
    state = state.copyWith(taxRate: rate, clearActiveOperation: true);
  }

  void clearCart() {
    state = state.copyWith(
      items: [],
      discount: 0,
      taxRate: 0.0,
      clearLastScan: true,
      customerId: null,
      customerName: 'អតិថិជនទូទៅ (Walk-in)',
      clearActiveOperation: true,
    );
  }

  /// Critical Checkout using atomic WriteBatch
  Future<String> checkout({
    required String cashierId,
    String paymentMethod = 'cash',
    int? paidAmount,
    int? changeAmount,
  }) async {
    if (state.items.isEmpty) {
      throw Exception('Cart is empty');
    }

    final saleRepo = ref.read(saleRepositoryProvider);

    // 1. Establish stable, durable operation identity for this checkout attempt
    final invoiceNum = state.activeInvoiceNumber ?? await _invoiceService.getNextInvoiceNumber();
    final opId = state.activeOperationId ??
        'op_pos_${DateTime.now().millisecondsSinceEpoch}_${invoiceNum.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}';

    state = state.copyWith(
      isCheckingOut: true,
      activeOperationId: opId,
      activeInvoiceNumber: invoiceNum,
    );

    try {
      final saleItems = state.items.map((i) {
        return SaleItem(
          productId: i.product.id,
          name: i.product.name,
          qty: i.qty,
          unitPrice: i.unitPrice,
          originalPrice: i.product.salePrice,
          totalPrice: i.lineTotal,
          tax: i.product.tax,
        );
      }).toList();

      final actualPaid = paidAmount ?? state.total;
      final actualChange = changeAmount ?? (actualPaid > state.total ? actualPaid - state.total : 0);

      final user = ref.read(authProvider).value;
      final sale = SaleModel(
        id: opId,
        invoiceNumber: invoiceNum,
        cashierId: cashierId,
        cashierName: user?.name,
        customerId: state.customerId,
        customerName: state.customerName,
        items: saleItems,
        subtotal: state.subtotal,
        discount: state.discount,
        totalTax: state.totalTax,
        total: state.total,
        paidAmount: actualPaid,
        changeAmount: actualChange,
        paymentMethod: paymentMethod,
        paymentStatus: 'paid',
        createdAt: DateTime.now(),
      );

      // 2. Before retrying, reconcile previous operation with Laravel to prevent duplicate sales
      final existingOrder = await saleRepo.checkOperationStatus(opId);
      if (existingOrder != null) {
        final confirmedInvoice = (existingOrder['invoice_number'] as String?) ?? invoiceNum;
        await saleRepo.reconcileConfirmedOrder(existingOrder, sale);

        AuditService.logFromRef(
          ref,
          action: 'sale.reconcile',
          entityType: 'sale',
          entityId: opId,
          details: '$confirmedInvoice (reconciled) · ${MoneyUtils.formatRiel(sale.total)}',
        );

        state = PosCartState(
          recentScans: state.recentScans,
          lastCompletedInvoice: confirmedInvoice,
        );

        return confirmedInvoice;
      }

      // 3. Authoritative checkout request to Laravel API
      await saleRepo.checkoutSale(sale, clientOperationId: opId);

      // Fire-and-forget Audit Log
      AuditService.logFromRef(
        ref,
        action: 'sale.checkout',
        entityType: 'sale',
        entityId: opId,
        details: '$invoiceNum · ${MoneyUtils.formatRiel(sale.total)}',
      );

      state = PosCartState(
        recentScans: state.recentScans,
        lastCompletedInvoice: invoiceNum,
      );

      return invoiceNum;
    } catch (e) {
      // Preserve cart items, activeOperationId, and activeInvoiceNumber on failure
      state = state.copyWith(isCheckingOut: false);
      rethrow;
    }
  }
}

final posCartProvider = NotifierProvider<PosCartNotifier, PosCartState>(PosCartNotifier.new);
