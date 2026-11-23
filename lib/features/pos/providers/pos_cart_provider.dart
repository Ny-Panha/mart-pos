import 'package:flutter/foundation.dart';
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

enum CheckoutStatus { idle, pending, confirmed, failed }

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
  final Map<String, dynamic>? activeCheckoutPayload;
  final CheckoutStatus checkoutStatus;

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
    this.activeCheckoutPayload,
    this.checkoutStatus = CheckoutStatus.idle,
  });

  int get subtotal => items.fold(0, (sum, i) => sum + i.lineTotal);
  int get totalTax => ((subtotal - discount) > 0 ? ((subtotal - discount) * taxRate).round() : 0);
  int get total => (subtotal - discount + totalTax) > 0 ? (subtotal - discount + totalTax) : 0;
  int get totalItemCount => items.fold(0, (sum, i) => sum + i.qty);

  bool get isPendingUnresolved =>
      (checkoutStatus == CheckoutStatus.pending || checkoutStatus == CheckoutStatus.failed) &&
      activeOperationId != null;

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
    Map<String, dynamic>? activeCheckoutPayload,
    CheckoutStatus? checkoutStatus,
    bool clearLastScan = false,
    bool clearActiveOperation = false,
  }) {
    final effectiveStatus = checkoutStatus ?? this.checkoutStatus;
    final isUnresolved = effectiveStatus == CheckoutStatus.pending || effectiveStatus == CheckoutStatus.failed;
    // Do not reset unresolved operation identity merely because cart items change
    final shouldClearOp = clearActiveOperation && !isUnresolved;

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
      activeOperationId: shouldClearOp ? null : (activeOperationId ?? this.activeOperationId),
      activeInvoiceNumber: shouldClearOp ? null : (activeInvoiceNumber ?? this.activeInvoiceNumber),
      activeCheckoutPayload: shouldClearOp ? null : (activeCheckoutPayload ?? this.activeCheckoutPayload),
      checkoutStatus: effectiveStatus,
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
    Future.microtask(() => restorePendingCheckout());
    return PosCartState();
  }

  Map<String, dynamic> _serializeCartDraft() {
    return {
      'items': state.items.map((i) => {
        'product': {
          'id': i.product.id,
          ...i.product.toJson(),
        },
        'qty': i.qty,
        'customPrice': i.customPrice,
      }).toList(),
      'customerId': state.customerId,
      'customerName': state.customerName,
      'discount': state.discount,
      'taxRate': state.taxRate,
      'activeOperationId': state.activeOperationId,
      'activeInvoiceNumber': state.activeInvoiceNumber,
    };
  }

  /// Restores unresolved checkout identity and cart payload from durable local storage upon application start
  Future<void> restorePendingCheckout() async {
    try {
      final saleRepo = ref.read(saleRepositoryProvider);
      final pending = await saleRepo.getPendingCheckout();
      if (pending != null && pending['operation_id'] != null) {
        final opId = pending['operation_id'] as String;
        final inv = pending['invoice_number'] as String? ?? '';
        final statusStr = pending['status'] as String? ?? 'pending';
        final status = statusStr == 'confirmed'
            ? CheckoutStatus.confirmed
            : (statusStr == 'failed' ? CheckoutStatus.failed : CheckoutStatus.pending);

        // 1. Restore complete cart draft and items if available
        final restoredItems = <CartItemState>[];
        if (pending['cart_draft'] is Map && pending['cart_draft']['items'] is List) {
          for (final raw in pending['cart_draft']['items']) {
            if (raw is Map) {
              try {
                final productMap = Map<String, dynamic>.from(raw['product'] as Map);
                final product = ProductModel.fromJson(productMap);
                final qty = (raw['qty'] is num) ? (raw['qty'] as num).toInt() : 1;
                final customPrice = (raw['customPrice'] is num) ? (raw['customPrice'] as num).toInt() : null;
                restoredItems.add(CartItemState(product: product, qty: qty, customPrice: customPrice));
              } catch (e) {
                debugPrint('Failed to deserialize cart item draft: $e');
              }
            }
          }
        }

        final draft = (pending['cart_draft'] is Map) ? pending['cart_draft'] as Map<String, dynamic> : null;
        final persistedPayload = (pending['payload'] is Map)
            ? Map<String, dynamic>.from(pending['payload'] as Map)
            : null;

        state = state.copyWith(
          items: restoredItems.isNotEmpty ? restoredItems : state.items,
          customerId: draft?['customerId'] ?? state.customerId,
          customerName: draft?['customerName'] ?? state.customerName,
          discount: (draft?['discount'] is num) ? (draft!['discount'] as num).toInt() : state.discount,
          taxRate: (draft?['taxRate'] is num) ? (draft!['taxRate'] as num).toDouble() : state.taxRate,
          activeOperationId: opId,
          activeInvoiceNumber: inv.isNotEmpty ? inv : null,
          activeCheckoutPayload: persistedPayload,
          checkoutStatus: status,
        );

        // 2. Perform background reconciliation with backend
        final resolution = await saleRepo.resolveOperationStatus(opId);
        if (resolution.status == OperationResolution.confirmed && resolution.orderData != null) {
          final existingOrder = resolution.orderData!;
          final confirmedInvoice = (existingOrder['invoice_number'] as String?) ?? inv;

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

          final user = ref.read(authProvider).value;
          final sale = SaleModel(
            id: opId,
            invoiceNumber: confirmedInvoice,
            cashierId: user?.id ?? 'cashier',
            cashierName: user?.name,
            customerId: state.customerId,
            customerName: state.customerName,
            items: saleItems,
            subtotal: state.subtotal,
            discount: state.discount,
            totalTax: state.totalTax,
            taxRate: state.taxRate > 0 ? state.taxRate : null,
            total: state.total,
            paidAmount: state.total,
            changeAmount: 0,
            paymentMethod: (existingOrder['payment_method'] as String?) ?? 'cash_riel',
            paymentStatus: 'paid',
            createdAt: DateTime.now(),
          );

          // Reconcile the authoritative order into Firestore cache BEFORE clearing pending state!
          await saleRepo.reconcileConfirmedOrder(existingOrder, sale);

          // Clear pending state ONLY AFTER successful reconciliation
          await saleRepo.clearPendingCheckout();

          state = PosCartState(
            recentScans: state.recentScans,
            lastCompletedInvoice: confirmedInvoice,
            checkoutStatus: CheckoutStatus.confirmed,
          );
        }
      }
    } catch (e) {
      debugPrint('Background restorePendingCheckout error: $e');
    }
  }

  /// Cancels or dismisses an unresolved pending checkout ONLY after authoritative resolution
  Future<void> cancelOrDismissUnresolvedCheckout() async {
    final opId = state.activeOperationId;
    if (opId == null) {
      state = PosCartState(
        recentScans: state.recentScans,
        checkoutStatus: CheckoutStatus.idle,
      );
      return;
    }

    final saleRepo = ref.read(saleRepositoryProvider);

    // Authoritative cancellation procedure:
    // Calling abortOperation guarantees that even if an earlier POST timed out and is still in flight,
    // the server either:
    // 1) Atomically tombstones the operation so the in-flight POST cannot commit, OR
    // 2) Detects that the in-flight POST already committed, returning the order for reconciliation.
    final abortResult = await saleRepo.abortOperation(opId);

    if (abortResult['committed'] == true && abortResult['data'] != null) {
      // It actually committed! Must reconcile and confirm, NOT dismiss!
      await reconcileActiveCheckout(preloadedOrder: abortResult['data'] as Map<String, dynamic>);
      return;
    }

    if (abortResult['aborted'] == true) {
      // Authoritatively aborted on server: in-flight POST can never commit.
      await saleRepo.clearPendingCheckout();
      state = PosCartState(
        recentScans: state.recentScans,
        checkoutStatus: CheckoutStatus.idle,
      );
      return;
    }

    // Network failure, unknown response, or abort failed: FAIL CLOSED!
    throw Exception(
      'Cannot dismiss unresolved checkout ($opId): Authoritative abort failed (${abortResult['message']}). An unresolved checkout cannot be dismissed while server outcome is unknown or in flight.',
    );
  }

  /// Manually triggers reconciliation of the active unresolved checkout with the backend
  Future<String?> reconcileActiveCheckout({Map<String, dynamic>? preloadedOrder}) async {
    if (state.activeOperationId == null) return null;
    final opId = state.activeOperationId!;
    final saleRepo = ref.read(saleRepositoryProvider);
    final existingOrder = preloadedOrder ?? (await saleRepo.resolveOperationStatus(opId)).orderData;
    if (existingOrder != null) {
      final confirmedInvoice = (existingOrder['invoice_number'] as String?) ?? state.activeInvoiceNumber ?? opId;

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

      final user = ref.read(authProvider).value;
      final sale = SaleModel(
        id: opId,
        invoiceNumber: confirmedInvoice,
        cashierId: user?.id ?? 'cashier',
        cashierName: user?.name,
        customerId: state.customerId,
        customerName: state.customerName,
        items: saleItems,
        subtotal: state.subtotal,
        discount: state.discount,
        totalTax: state.totalTax,
        taxRate: state.taxRate > 0 ? state.taxRate : null,
        total: state.total,
        paidAmount: state.total,
        changeAmount: 0,
        paymentMethod: (existingOrder['payment_method'] as String?) ?? 'cash_riel',
        paymentStatus: 'paid',
        createdAt: DateTime.now(),
      );

      await saleRepo.reconcileConfirmedOrder(existingOrder, sale);
      await saleRepo.clearPendingCheckout();

      state = PosCartState(
        recentScans: state.recentScans,
        lastCompletedInvoice: confirmedInvoice,
        checkoutStatus: CheckoutStatus.confirmed,
      );
      return confirmedInvoice;
    }
    return null;
  }

  /// Returns null on success, or an error message if stock exceeded or double scanned
  String? addProduct(ProductModel product, {bool isBarcodeScan = false}) {
    // Lock cart mutation if an operation is pending resolution
    if (state.isPendingUnresolved) {
      return 'Cannot modify cart: an active checkout attempt (${state.activeInvoiceNumber}) is unresolved. Please reconcile or resolve it first.';
    }

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
    if (state.isPendingUnresolved) {
      return 'Cannot update quantity: checkout (${state.activeInvoiceNumber}) is unresolved.';
    }

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
    if (state.isPendingUnresolved) return;

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
    if (state.isPendingUnresolved) return;

    final updatedList = List<CartItemState>.from(state.items)
      ..removeWhere((i) => i.product.id == productId);
    state = state.copyWith(items: updatedList, clearActiveOperation: true);
  }

  void setCustomer(String? id, String name) {
    if (state.isPendingUnresolved) return;

    state = state.copyWith(
      customerId: id,
      customerName: name,
      clearActiveOperation: true,
    );
  }

  void setDiscount(int discountRiel) {
    if (state.isPendingUnresolved) return;

    state = state.copyWith(discount: discountRiel, clearActiveOperation: true);
  }

  void setTaxRate(double rate) {
    if (state.isPendingUnresolved) return;

    state = state.copyWith(taxRate: rate, clearActiveOperation: true);
  }

  void clearCart() {
    if (state.isPendingUnresolved) return;

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

  /// Critical Checkout using atomic WriteBatch & Authoritative REST API
  Future<String> checkout({
    required String cashierId,
    String paymentMethod = 'cash',
    int? paidAmount,
    int? changeAmount,
    double? receivedUsd,
    double? changeUsd,
  }) async {
    // 0. Strict synchronous concurrency lock before ANY asynchronous operation
    if (state.isCheckingOut) {
      throw Exception('Checkout already in progress. Please wait.');
    }

    if (state.items.isEmpty) {
      throw Exception('Cart is empty');
    }

    // Immediately acquire concurrency lock synchronously before any await,
    // ensuring simultaneous checkout calls cannot create separate operation IDs!
    state = state.copyWith(
      isCheckingOut: true,
      checkoutStatus: CheckoutStatus.pending,
    );

    final saleRepo = ref.read(saleRepositoryProvider);

    try {
      // 1. Establish stable, durable operation identity for this checkout attempt
      final invoiceNum = state.activeInvoiceNumber ?? await _invoiceService.getNextInvoiceNumber();
      final opId = state.activeOperationId ??
          'op_pos_${DateTime.now().millisecondsSinceEpoch}_${invoiceNum.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}';

      state = state.copyWith(
        activeOperationId: opId,
        activeInvoiceNumber: invoiceNum,
      );

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
        taxRate: state.taxRate > 0 ? state.taxRate : null,
        total: state.total,
        paidAmount: actualPaid,
        changeAmount: actualChange,
        receivedUsd: receivedUsd,
        changeUsd: changeUsd,
        paymentMethod: paymentMethod,
        paymentStatus: 'paid',
        createdAt: DateTime.now(),
      );

      // 2. Before retrying, reconcile previous operation with Laravel to prevent duplicate sales
      final existingOrder = await saleRepo.checkOperationStatus(opId);
      if (existingOrder != null) {
        final confirmedInvoice = (existingOrder['invoice_number'] as String?) ?? invoiceNum;
        await saleRepo.reconcileConfirmedOrder(existingOrder, sale);
        await saleRepo.clearPendingCheckout();

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
          checkoutStatus: CheckoutStatus.confirmed,
        );

        return confirmedInvoice;
      }

      // 3. Authoritative checkout request to Laravel API using original immutable payload if retrying
      final Map<String, dynamic> immutablePayload;
      if (state.activeCheckoutPayload != null && state.activeCheckoutPayload!['client_operation_id'] == opId) {
        immutablePayload = Map<String, dynamic>.from(state.activeCheckoutPayload!);
      } else {
        immutablePayload = saleRepo.buildCheckoutPayload(
          sale: sale,
          clientOperationId: opId,
        );
        state = state.copyWith(activeCheckoutPayload: immutablePayload);
      }

      await saleRepo.checkoutSale(
        sale,
        clientOperationId: opId,
        cartDraft: _serializeCartDraft(),
        immutablePayload: immutablePayload,
      );

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
        checkoutStatus: CheckoutStatus.confirmed,
      );

      return invoiceNum;
    } catch (e) {
      // Preserve cart items, activeOperationId, and activeInvoiceNumber on failure
      state = state.copyWith(
        isCheckingOut: false,
        checkoutStatus: CheckoutStatus.failed,
      );
      rethrow;
    }
  }
}

final posCartProvider = NotifierProvider<PosCartNotifier, PosCartState>(PosCartNotifier.new);
