import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:mart_pos/core/role_route_guard.dart';
import 'package:mart_pos/core/utils/money.dart';
import 'package:mart_pos/data/firestore/models/audit_log_model.dart';
import 'package:mart_pos/data/firestore/models/category_model.dart';
import 'package:mart_pos/data/services/api_service.dart';
import 'package:mart_pos/data/services/audit_service.dart';
import 'package:mart_pos/data/firestore/models/product_model.dart';
import 'package:mart_pos/data/firestore/models/purchase_model.dart';
import 'package:mart_pos/data/firestore/models/sale_model.dart';
import 'package:mart_pos/data/firestore/models/user_model.dart';
import 'package:mart_pos/data/repositories/inventory_repository.dart';
import 'package:mart_pos/data/repositories/product_repository.dart';
import 'package:mart_pos/data/repositories/purchase_repository.dart';
import 'package:mart_pos/data/repositories/report_repository.dart';
import 'package:mart_pos/data/repositories/sale_repository.dart';
import 'package:mart_pos/data/repositories/shift_repository.dart';
import 'package:mart_pos/data/repositories/supplier_repository.dart';
import 'package:mart_pos/data/repositories/user_repository.dart';
import 'package:mart_pos/features/customers/providers/customer_provider.dart';
import 'package:mart_pos/features/pos/providers/pos_cart_provider.dart';

void main() {
  group('MoneyUtils Tests', () {
    test('Format int riel correctly', () {
      expect(MoneyUtils.formatRiel(15000), '15,000 ៛');
      expect(MoneyUtils.formatRiel(0), '0 ៛');
    });

    test('USD to Riel conversion with 4100 exchange rate', () {
      expect(MoneyUtils.usdToRiel(1.0), 4100);
      expect(MoneyUtils.usdToRiel(0.5), 2050);
    });

    test('Riel to USD conversion', () {
      expect(MoneyUtils.rielToUsd(4100), 1.0);
    });
  });

  group('UserModel role and shop scope', () {
    test('normalizes manager role and identifies access levels', () {
      final manager = UserModel(id: 'm1', name: 'Manager', role: 'manager');
      final admin = UserModel(id: 'a1', name: 'Admin', role: 'ADMIN', shopId: 'shop-a');
      final cashier = UserModel(id: 'c1', name: 'Cashier', role: 'CASHIER', shopId: 'shop-a');
      expect(manager.isManager, true);
      expect(manager.canManageShop, true);
      expect(admin.isAdmin, true);
      expect(admin.canManageShop, true);
      expect(cashier.isCashier, true);
      expect(cashier.canManageShop, false);
    });

    test('uses the migration shop for legacy staff profiles', () {
      expect(UserModel.shopIdForProfile(role: 'ADMIN'), UserModel.defaultShopId);
      expect(UserModel.shopIdForProfile(role: 'SUPER'), isNull);
    });
  });

  group('Role route guard', () {
    test('sends roles home and blocks cross-role destinations', () {
      final manager = UserModel(id: 'm1', name: 'Manager', role: 'ADMIN_MANAGER');
      final admin = UserModel(id: 'a1', name: 'Admin', role: 'ADMIN', shopId: 'shop-a');
      final cashier = UserModel(id: 'c1', name: 'Cashier', role: 'CASHIER', shopId: 'shop-a');
      expect(RoleRouteGuard.redirect(manager, '/login'), '/manager');
      expect(RoleRouteGuard.redirect(manager, '/admin'), '/manager');
      expect(RoleRouteGuard.redirect(admin, '/manager/reports'), '/admin');
      expect(RoleRouteGuard.redirect(admin, '/cashier/history'), '/admin');
      expect(RoleRouteGuard.redirect(cashier, '/manager'), '/pos');
      expect(RoleRouteGuard.redirect(cashier, '/admin'), '/pos');
      expect(RoleRouteGuard.redirect(cashier, '/cashier/history'), isNull);
    });
  });

  group('ProductModel Tests', () {
    test('Product stock and status getters', () {
      final p = ProductModel(
        id: 'p1',
        name: 'Coca Cola',
        code: 'PROD-001',
        categoryId: 'cat_drinks',
        costPrice: 1600,
        salePrice: 2500,
        stockQty: 4,
        lowStockThreshold: 5,
      );

      expect(p.isLowStock, true);
      expect(p.isOutOfStock, false);
      expect(p.isActive, true);
      expect(p.salePrice, 2500); // int riel
    });
  });

  group('Product Code Uniqueness Tests', () {
    final existingCodes = ['PROD-001', 'PROD-002', 'COCA-330'];

    test('Returns true for brand new unique code', () {
      final isUnique = ProductRepository.validateCodeUniqueness(
        'PROD-003',
        existingCodes,
      );
      expect(isUnique, true);
    });

    test('Returns false when code already exists (case-insensitive)', () {
      final isUniqueLower = ProductRepository.validateCodeUniqueness(
        'prod-001',
        existingCodes,
      );
      expect(isUniqueLower, false);

      final isUniqueExact = ProductRepository.validateCodeUniqueness(
        'COCA-330',
        existingCodes,
      );
      expect(isUniqueExact, false);
    });

    test('Returns true when editing existing product and keeping its own code', () {
      final isUniqueOwnCode = ProductRepository.validateCodeUniqueness(
        'PROD-001',
        existingCodes,
        currentCode: 'PROD-001',
      );
      expect(isUniqueOwnCode, true);
    });
  });

  group('CategoryModel Tests', () {
    test('copyWith updates fields correctly', () {
      final cat = CategoryModel(
        id: 'c1',
        name: 'Drinks',
        sortOrder: 1,
      );

      final updated = cat.copyWith(name: 'Beverages', sortOrder: 5);
      expect(updated.id, 'c1');
      expect(updated.name, 'Beverages');
      expect(updated.sortOrder, 5);
    });
  });

  group('InventoryRepository Stock Adjustment Diff Tests', () {
    test('current 10 -> new 15 equals movement qty +5 (positive stock increase)', () {
      final diff = InventoryRepository.calculateAdjustmentDiff(
        currentQty: 10,
        newQty: 15,
      );
      expect(diff, 5);
    });

    test('current 10 -> new 7 equals movement qty -3 (stock decrease discrepancy)', () {
      final diff = InventoryRepository.calculateAdjustmentDiff(
        currentQty: 10,
        newQty: 7,
      );
      expect(diff, -3);
    });

    test('current 10 -> new 10 equals movement qty 0 (no count change)', () {
      final diff = InventoryRepository.calculateAdjustmentDiff(
        currentQty: 10,
        newQty: 10,
      );
      expect(diff, 0);
    });

    test('current 0 -> new 20 equals movement qty +20 (found stock)', () {
      final diff = InventoryRepository.calculateAdjustmentDiff(
        currentQty: 0,
        newQty: 20,
      );
      expect(diff, 20);
    });
  });

  group('ReportRepository Profit Math Tests', () {
    test('Calculates profit correctly: sale total minus cost of all items', () {
      final productsMap = {
        'p1': ProductModel(
          id: 'p1',
          name: 'Coca Cola',
          code: 'PROD-001',
          categoryId: 'cat_drinks',
          costPrice: 1600,
          salePrice: 2500,
          stockQty: 20,
        ),
        'p2': ProductModel(
          id: 'p2',
          name: 'MAMA Noodles',
          code: 'PROD-002',
          categoryId: 'cat_food',
          costPrice: 1200,
          salePrice: 2000,
          stockQty: 30,
        ),
      };

      final sales = [
        SaleModel(
          id: 's1',
          invoiceNumber: 'INV-001',
          cashierId: 'cashier_1',
          items: [
            SaleItem(productId: 'p1', name: 'Coca Cola', qty: 2, unitPrice: 2500, totalPrice: 5000),
            SaleItem(productId: 'p2', name: 'MAMA Noodles', qty: 1, unitPrice: 2000, totalPrice: 2000),
          ],
          subtotal: 7000,
          discount: 0,
          totalTax: 0,
          total: 7000,
          paidAmount: 7000,
          changeAmount: 0,
          paymentMethod: 'cash',
          paymentStatus: 'paid',
          createdAt: DateTime.now(),
        ),
      ];

      // Revenue = 7,000 Riel
      // Cost = (2 * 1,600) + (1 * 1,200) = 3,200 + 1,200 = 4,400 Riel
      // Profit = 7,000 - 4,400 = 2,600 Riel
      final profit = ReportRepository.calculateProfit(
        sales: sales,
        productsMap: productsMap,
      );
      expect(profit, 2600);
    });
  });

  group('CustomerRepository Delete Blocker Tests', () {
    test('Blocks customer deletion when customer has existing sales', () {
      final canDelete = CustomerRepository.canDeleteCustomer(hasSales: true);
      expect(canDelete, false);
    });

    test('Allows customer deletion when customer has zero sales', () {
      final canDelete = CustomerRepository.canDeleteCustomer(hasSales: false);
      expect(canDelete, true);
    });
  });

  group('ShiftRepository Close-Shift Math Tests', () {
    test('Calculates expected cash correctly as opening cash plus total sales', () {
      final expected = ShiftRepository.calculateExpectedCash(
        openingCash: 100000,
        totalSales: 250000,
      );
      expect(expected, 350000);
    });

    test('Difference is 0 when drawer actual cash matches expected cash', () {
      final diff = ShiftRepository.calculateDifference(
        openingCash: 100000,
        totalSales: 250000,
        actualCash: 350000,
      );
      expect(diff, 0);
    });

    test('Difference is negative (shortage) when actual cash is less than opening + sales', () {
      final diff = ShiftRepository.calculateDifference(
        openingCash: 100000,
        totalSales: 250000,
        actualCash: 340000,
      );
      expect(diff, -10000);
    });

    test('Difference is positive (surplus) when actual cash is greater than opening + sales', () {
      final diff = ShiftRepository.calculateDifference(
        openingCash: 100000,
        totalSales: 250000,
        actualCash: 360000,
      );
      expect(diff, 10000);
    });
  });

  group('UserRepository Last Admin Deactivate Blocker Tests', () {
    test('Blocks deactivating the only active admin in the system', () {
      final users = [
        UserModel(id: 'admin_1', name: 'Panha', role: 'admin', active: true),
        UserModel(id: 'cashier_1', name: 'Pkay', role: 'cashier', active: true),
      ];

      final canDeactivate = UserRepository.canDeactivateUser(
        allUsers: users,
        targetUid: 'admin_1',
      );
      expect(canDeactivate, false);
    });

    test('Allows deactivating an admin when another active admin exists', () {
      final users = [
        UserModel(id: 'admin_1', name: 'Panha', role: 'admin', active: true),
        UserModel(id: 'admin_2', name: 'Sokha', role: 'admin', active: true),
        UserModel(id: 'cashier_1', name: 'Pkay', role: 'cashier', active: true),
      ];

      final canDeactivate = UserRepository.canDeactivateUser(
        allUsers: users,
        targetUid: 'admin_1',
      );
      expect(canDeactivate, true);
    });

    test('Blocks deactivating an admin when other admins are already inactive', () {
      final users = [
        UserModel(id: 'admin_1', name: 'Panha', role: 'admin', active: true),
        UserModel(id: 'admin_2', name: 'Sokha', role: 'admin', active: false),
        UserModel(id: 'cashier_1', name: 'Pkay', role: 'cashier', active: true),
      ];

      final canDeactivate = UserRepository.canDeactivateUser(
        allUsers: users,
        targetUid: 'admin_1',
      );
      expect(canDeactivate, false);
    });

    test('Always allows deactivating a cashier', () {
      final users = [
        UserModel(id: 'admin_1', name: 'Panha', role: 'admin', active: true),
        UserModel(id: 'cashier_1', name: 'Pkay', role: 'cashier', active: true),
      ];

      final canDeactivate = UserRepository.canDeactivateUser(
        allUsers: users,
        targetUid: 'cashier_1',
      );
      expect(canDeactivate, true);
    });
  });

  group('SupplierRepository Deactivate Blocker Tests', () {
    test('Blocks supplier deactivation when supplier has existing purchase history', () {
      final canDeactivate = SupplierRepository.canDeactivateSupplier(purchaseCount: 3);
      expect(canDeactivate, false);
    });

    test('Blocks supplier deactivation when supplier has at least 1 purchase', () {
      final canDeactivate = SupplierRepository.canDeactivateSupplier(purchaseCount: 1);
      expect(canDeactivate, false);
    });

    test('Allows supplier deactivation when supplier has 0 purchases', () {
      final canDeactivate = SupplierRepository.canDeactivateSupplier(purchaseCount: 0);
      expect(canDeactivate, true);
    });
  });

  group('PurchaseRepository Math & Input Guard Tests', () {
    test('calculateTotalCost calculates sum of qty * costPrice correctly', () {
      final items = [
        const PurchaseItem(
          productId: 'p1',
          name: 'Coca Cola',
          qty: 24, // 1 case
          costPrice: 1500, // 1500 Riel each -> 36,000
        ),
        const PurchaseItem(
          productId: 'p2',
          name: 'Angkor Beer',
          qty: 12,
          costPrice: 2800, // 2800 Riel each -> 33,600
        ),
      ];

      final total = PurchaseRepository.calculateTotalCost(items);
      expect(total, 69600); // 36,000 + 33,600 = 69,600 Riel
    });

    test('calculateTotalCost returns 0 for empty item list', () {
      final total = PurchaseRepository.calculateTotalCost([]);
      expect(total, 0);
    });

    test('validatePurchaseInput blocks inactive supplier', () {
      final items = [
        const PurchaseItem(
          productId: 'p1',
          name: 'Coca Cola',
          qty: 10,
          costPrice: 1500,
        ),
      ];

      expect(
        () => PurchaseRepository.validatePurchaseInput(
          isSupplierActive: false,
          items: items,
        ),
        throwsArgumentError,
      );
    });

    test('validatePurchaseInput blocks empty items list', () {
      expect(
        () => PurchaseRepository.validatePurchaseInput(
          isSupplierActive: true,
          items: [],
        ),
        throwsArgumentError,
      );
    });

    test('validatePurchaseInput blocks non-positive quantity', () {
      final items = [
        const PurchaseItem(
          productId: 'p1',
          name: 'Coca Cola',
          qty: 0,
          costPrice: 1500,
        ),
      ];

      expect(
        () => PurchaseRepository.validatePurchaseInput(
          isSupplierActive: true,
          items: items,
        ),
        throwsArgumentError,
      );
    });

    test('validatePurchaseInput blocks negative cost price', () {
      final items = [
        const PurchaseItem(
          productId: 'p1',
          name: 'Coca Cola',
          qty: 5,
          costPrice: -100,
        ),
      ];

      expect(
        () => PurchaseRepository.validatePurchaseInput(
          isSupplierActive: true,
          items: items,
        ),
        throwsArgumentError,
      );
    });

    test('validatePurchaseInput succeeds with valid inputs', () {
      final items = [
        const PurchaseItem(
          productId: 'p1',
          name: 'Coca Cola',
          qty: 10,
          costPrice: 1500,
        ),
        const PurchaseItem(
          productId: 'p2',
          name: 'MAMA Noodles',
          qty: 50,
          costPrice: 1200,
        ),
      ];

      expect(
        () => PurchaseRepository.validatePurchaseInput(
          isSupplierActive: true,
          items: items,
        ),
        returnsNormally,
      );
    });
  });

  group('AuditLogModel Serialization & fromMap Tests', () {
    test('Serializes to Firestore map with all expected fields', () {
      final now = DateTime(2026, 10, 8, 12, 0);
      final model = AuditLogModel(
        id: 'log_001',
        userId: 'user_123',
        userName: 'Panha',
        action: 'sale.checkout',
        entityType: 'sale',
        entityId: 'sale_999',
        details: 'INV-0001 · 15,000 ៛',
        createdAt: now,
      );

      final map = model.toFirestore();
      expect(map['userId'], 'user_123');
      expect(map['userName'], 'Panha');
      expect(map['action'], 'sale.checkout');
      expect(map['entityType'], 'sale');
      expect(map['entityId'], 'sale_999');
      expect(map['details'], 'INV-0001 · 15,000 ៛');
      expect((map['createdAt'] as Timestamp).toDate(), now);
    });

    test('AuditLogModel.fromMap correctly parses map data', () {
      final now = DateTime(2026, 10, 8, 12, 0);
      final map = {
        'userId': 'user_456',
        'userName': 'Sokha',
        'action': 'stock.in',
        'entityType': 'product',
        'entityId': 'prod_777',
        'details': 'Coca Cola · +24',
        'createdAt': Timestamp.fromDate(now),
      };

      final model = AuditLogModel.fromMap(map, 'log_002');
      expect(model.id, 'log_002');
      expect(model.userId, 'user_456');
      expect(model.userName, 'Sokha');
      expect(model.action, 'stock.in');
      expect(model.entityType, 'product');
      expect(model.entityId, 'prod_777');
      expect(model.details, 'Coca Cola · +24');
      expect(model.createdAt, now);
    });

    test('AuditLogModel.copyWith preserves unchanged fields and overrides specified fields', () {
      final model = AuditLogModel(
        id: 'log_001',
        userId: 'user_123',
        userName: 'Panha',
        action: 'product.create',
        entityType: 'product',
        entityId: 'prod_1',
        details: 'MAMA Noodles',
      );

      final updated = model.copyWith(details: 'MAMA Noodles (Updated)', action: 'product.update');
      expect(updated.id, 'log_001');
      expect(updated.userId, 'user_123');
      expect(updated.userName, 'Panha');
      expect(updated.action, 'product.update');
      expect(updated.details, 'MAMA Noodles (Updated)');
    });
  });

  group('AuditService Error Swallowing Tests', () {
    test('AuditService.log swallows errors and never throws when underlying operation fails', () async {
      await expectLater(
        AuditService.log(
          userId: 'test_user',
          userName: 'Tester',
          action: 'test.action',
          entityType: 'test',
          entityId: 'test_123',
          details: 'Unit test log swallowing',
        ),
        completes,
      );
    });
  });

  group('Authoritative Backend Integration Tests', () {
    test('ProductModel.fromJson and toJson correctly maps backend MySQL fields', () {
      final json = {
        'id': 15,
        'name': 'Angkor Beer',
        'code': 'BEER-001',
        'barcode': '884111222',
        'sku': 'ANGKOR-330',
        'category_id': 1,
        'cost_price': 2000,
        'sale_price': 3000,
        'stock_qty': 24,
        'unit': 'កំប៉ុង',
        'low_stock_threshold': 5,
        'tax': '0.00',
        'status': 'active',
      };

      final product = ProductModel.fromJson(json);
      expect(product.id, '15');
      expect(product.name, 'Angkor Beer');
      expect(product.costPrice, 2000);
      expect(product.salePrice, 3000);
      expect(product.stockQty, 24);

      final outJson = product.toJson();
      expect(outJson['category_id'], 1);
      expect(outJson['code'], 'BEER-001');
      expect(outJson['cost_price'], 2000);
      expect(outJson['sale_price'], 3000);
      expect(outJson['stock_qty'], 24);
    });

    test('CategoryModel.fromJson correctly maps MySQL category data', () {
      final json = {
        'id': 2,
        'name': 'Snacks',
        'name_kh': 'នំចំណី',
        'slug': 'snacks',
        'icon': 'cookie',
      };

      final category = CategoryModel.fromJson(json);
      expect(category.id, '2');
      expect(category.name, 'នំចំណី (Snacks)');
    });

    test('SaleRepository.checkoutSale rejects non-numeric product ID and never falls back to 1', () async {
      final repo = SaleRepository();
      final invalidSale = SaleModel(
        id: 'sale_invalid_test',
        invoiceNumber: 'INV-TEST-999',
        cashierId: 'cashier-1',
        items: [
          SaleItem(
            productId: 'invalid_firestore_id', // Invalid non-numeric ID
            name: 'Corrupted Item',
            qty: 1,
            unitPrice: 2000,
            totalPrice: 2000,
          ),
        ],
        subtotal: 2000,
        total: 2000,
        paidAmount: 2000,
      );

      expect(
        () => repo.checkoutSale(invalidSale),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('An authoritative MySQL Product ID is required'),
        )),
      );
    });

    test('InventoryRepository stock guards reject invalid inputs', () async {
      final repo = InventoryRepository();

      // Zero or negative Stock In
      expect(
        () => repo.stockIn(productId: '1', qty: 0, userId: 'u1'),
        throwsA(isA<ArgumentError>()),
      );

      // Non-numeric Product ID Stock In
      expect(
        () => repo.stockIn(productId: 'non_numeric', qty: 5, userId: 'u1'),
        throwsA(isA<ArgumentError>()),
      );

      // Zero or negative Stock Out
      expect(
        () => repo.stockOut(productId: '1', currentQty: 10, qty: 0, note: 'Loss', userId: 'u1'),
        throwsA(isA<ArgumentError>()),
      );

      // Empty note Stock Out
      expect(
        () => repo.stockOut(productId: '1', currentQty: 10, qty: 2, note: '', userId: 'u1'),
        throwsA(isA<ArgumentError>()),
      );

      // Negative New Qty Adjust
      expect(
        () => repo.adjustStock(productId: '1', currentQty: 10, newQty: -5, note: 'Audit', userId: 'u1'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('SaleRepository.checkoutSale enforces client_operation_id minimum 8 characters', () async {
      final repo = SaleRepository();
      final validSale = SaleModel(
        id: 's1',
        invoiceNumber: 'INV-TEST-001',
        cashierId: 'cashier-1',
        items: [
          SaleItem(productId: '10', name: 'Item', qty: 1, unitPrice: 1000, totalPrice: 1000),
        ],
        subtotal: 1000,
        total: 1000,
        paidAmount: 1000,
      );

      expect(
        () => repo.checkoutSale(validSale, clientOperationId: 'short'),
        throwsA(isA<ArgumentError>().having(
          (e) => e.toString(),
          'message',
          contains('at least 8 characters'),
        )),
      );
    });

    test('ApiService.processResponse rejects malformed non-JSON HTTP responses and throws Exception', () {
      expect(
        () => ApiService.processResponse(http.Response('<html>Bad Request</html>', 400)),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Malformed server response (HTTP 400): invalid JSON'),
        )),
      );

      expect(
        () => ApiService.processResponse(http.Response('<html>Server Error</html>', 200)),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Malformed server response (HTTP 200): invalid JSON'),
        )),
      );
    });

    test('PosCartState maintains activeOperationId on failure and resets on cart mutation', () {
      final initial = PosCartState(
        activeOperationId: 'op_test_12345678',
        activeInvoiceNumber: 'INV-20261123-0001',
      );

      // On failure, copyWith(isCheckingOut: false, checkoutStatus: CheckoutStatus.failed) preserves operation identity
      final failureState = initial.copyWith(
        isCheckingOut: false,
        checkoutStatus: CheckoutStatus.failed,
      );
      expect(failureState.activeOperationId, 'op_test_12345678');
      expect(failureState.activeInvoiceNumber, 'INV-20261123-0001');

      // When an operation is unresolved (failed or pending), clearActiveOperation preserves operation identity!
      final unresolvedMutatedState = failureState.copyWith(
        discount: 500,
        clearActiveOperation: true,
      );
      expect(unresolvedMutatedState.activeOperationId, 'op_test_12345678');
      expect(unresolvedMutatedState.activeInvoiceNumber, 'INV-20261123-0001');

      // When resolved (idle), clearActiveOperation resets them
      final resolvedState = initial.copyWith(checkoutStatus: CheckoutStatus.idle);
      final mutatedState = resolvedState.copyWith(
        discount: 500,
        clearActiveOperation: true,
      );
      expect(mutatedState.activeOperationId, isNull);
      expect(mutatedState.activeInvoiceNumber, isNull);
    });

    test('SaleModel supports receivedUsd, changeUsd, and taxRate serialization', () {
      final sale = SaleModel(
        id: 's_usd_01',
        invoiceNumber: 'INV-USD-001',
        cashierId: 'cashier_1',
        items: [
          SaleItem(productId: '10', name: 'Item', qty: 2, unitPrice: 2050, totalPrice: 4100),
        ],
        subtotal: 4100,
        total: 4100,
        paidAmount: 4100,
        receivedUsd: 2.00,
        changeUsd: 1.00,
        taxRate: 0.10,
        paymentMethod: 'cash_usd',
      );

      expect(sale.receivedUsd, 2.00);
      expect(sale.changeUsd, 1.00);
      expect(sale.taxRate, 0.10);
      expect(sale.paymentMethod, 'cash_usd');

      final map = sale.toFirestore();
      expect(map['receivedUsd'], 2.00);
      expect(map['changeUsd'], 1.00);
      expect(map['taxRate'], 0.10);
      expect(map['paymentMethod'], 'cash_usd');
    });

    test('PurchaseRepository.validatePurchaseInput validates items and supplier correctly', () {
      expect(
        () => PurchaseRepository.validatePurchaseInput(
          isSupplierActive: false,
          items: [PurchaseItem(productId: 'p1', name: 'Item', qty: 1, costPrice: 1000)],
        ),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('Supplier must exist'))),
      );

      expect(
        () => PurchaseRepository.validatePurchaseInput(
          isSupplierActive: true,
          items: [],
        ),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('cannot be empty'))),
      );
    });

    test('SaleRepository and ReportRepository handle network failure gracefully without throwing unhandled exceptions', () async {
      final saleRepo = SaleRepository();
      final status = await saleRepo.checkOperationStatus('op_non_existent');
      expect(status, isNull);

      final reportRepo = ReportRepository();
      final summary = await reportRepo.getAuthoritativeSummary();
      expect(summary, isNull);
    });

    test('PosCartNotifier blocks addProduct and updateQty when checkout is unresolved', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      final notifier = container.read(posCartProvider.notifier);

      final dummyProduct = ProductModel(
        id: '1',
        name: 'Anchor Beer',
        code: 'P001',
        categoryId: 'cat_drinks',
        costPrice: 2000,
        salePrice: 3000,
        stockQty: 20,
      );

      // Normal state: add product works
      final res1 = notifier.addProduct(dummyProduct);
      expect(res1, isNull);
      expect(container.read(posCartProvider).items.length, 1);

      // Transition to unresolved pending checkout
      container.read(posCartProvider.notifier).state = container.read(posCartProvider).copyWith(
        activeOperationId: 'op_unresolved_001',
        activeInvoiceNumber: 'INV-20261123-9999',
        checkoutStatus: CheckoutStatus.pending,
      );
      expect(container.read(posCartProvider).isPendingUnresolved, isTrue);

      // Mutation while unresolved is strictly blocked!
      final blockedAdd = notifier.addProduct(dummyProduct);
      expect(blockedAdd, contains('Cannot modify cart'));

      final blockedQty = notifier.updateQty('1', 5);
      expect(blockedQty, contains('Cannot update quantity'));

      // Attempting to dismiss while server status is unknown (network down) strictly fails closed!
      expect(
        () => notifier.cancelOrDismissUnresolvedCheckout(),
        throwsA(isA<Exception>()),
      );
      expect(container.read(posCartProvider).isPendingUnresolved, isTrue);
    });

    test('Simultaneous checkout calls acquire synchronous lock before await and reject duplicate execution', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      final notifier = container.read(posCartProvider.notifier);

      final dummyProduct = ProductModel(
        id: '1',
        name: 'Coca Cola',
        code: 'P001',
        categoryId: 'cat_drinks',
        costPrice: 1500,
        salePrice: 2500,
        stockQty: 50,
      );
      notifier.addProduct(dummyProduct);

      // Launch first checkout (synchronously acquires isCheckingOut: true before await)
      final future1 = notifier.checkout(cashierId: 'cashier_1');

      // Simultaneous second checkout call in the same microtask
      expect(
        () => notifier.checkout(cashierId: 'cashier_1'),
        throwsA(predicate((e) => e.toString().contains('Checkout already in progress'))),
      );

      // Await first future (fails gracefully on network since offline)
      try {
        await future1;
      } catch (_) {}
    });

    test('Uncertain network outcome prevents Dismiss from deleting unresolved checkout', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      final notifier = container.read(posCartProvider.notifier);

      final dummyProduct = ProductModel(
        id: '2',
        name: 'Angkor Beer',
        code: 'P002',
        categoryId: 'cat_drinks',
        costPrice: 2000,
        salePrice: 3200,
        stockQty: 30,
      );
      notifier.addProduct(dummyProduct);

      // Put cart into unresolved pending state
      container.read(posCartProvider.notifier).state = container.read(posCartProvider).copyWith(
        activeOperationId: 'op_uncertain_network_999',
        activeInvoiceNumber: 'INV-20261123-UNCERTAIN',
        checkoutStatus: CheckoutStatus.pending,
      );

      // Attempt Dismiss when server is unreachable
      expect(
        () => notifier.cancelOrDismissUnresolvedCheckout(),
        throwsA(predicate((e) => e.toString().contains('unresolved checkout cannot be dismissed'))),
      );

      // Unresolved state and cart items are safely preserved!
      expect(container.read(posCartProvider).isPendingUnresolved, isTrue);
      expect(container.read(posCartProvider).activeOperationId, 'op_uncertain_network_999');
      expect(container.read(posCartProvider).items.length, 1);
    });

    test('Durable pending-checkout persistence fails closed before remote transmission', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final saleRepo = SaleRepository();

      SharedPreferences.setMockInitialValues({});
      await expectLater(
        saleRepo.persistPendingCheckout(
          operationId: 'op_test_persist_1',
          invoiceNumber: 'INV-001',
          payload: {'total_riel': 5000},
          status: 'pending',
        ),
        completes,
      );

      final saved = await saleRepo.getPendingCheckout();
      expect(saved, isNotNull);
      expect(saved!['operation_id'], 'op_test_persist_1');
    });

    test('Operation resolution distinguishes confirmed, 404 notFound, and unknown network states', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final saleRepo = SaleRepository();

      // Unknown network / server error (e.g. HTTP 400 / Connection error)
      final unknownRes = await saleRepo.resolveOperationStatus('op_non_existent_unreachable');
      expect(unknownRes.status, OperationResolution.unknown);
      expect(unknownRes.errorMessage, isNotEmpty);
    });

    test('Cash USD math converts Riel correctly with 4,100 exchange rate and computes change', () {
      final totalRiel = 5000;
      final expectedTotalUsd = double.parse((totalRiel / 4100.0).toStringAsFixed(2)); // 1.22
      expect(expectedTotalUsd, 1.22);

      final receivedUsd = 2.00;
      final changeUsd = double.parse((receivedUsd - expectedTotalUsd).toStringAsFixed(2)); // 0.78
      expect(changeUsd, 0.78);

      final changeRiel = (changeUsd * 4100).round();
      expect(changeRiel, 3198); // ~3200 Riel
    });

    test('Original POST still executing when GET returns 404: Dismiss attempts abort, detects delayed commit, and reconciles instead of deleting', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      final notifier = container.read(posCartProvider.notifier);

      final opId = 'op_inflight_delayed_001';
      container.read(posCartProvider.notifier).state = container.read(posCartProvider).copyWith(
        activeOperationId: opId,
        activeInvoiceNumber: 'INV-INFLIGHT-001',
        checkoutStatus: CheckoutStatus.pending,
      );

      // Setup controllable mock client:
      // GET returns 404 (POST hasn't committed yet)
      // But POST /orders/abort-operation detects the order just committed and returns 409 committed!
      ApiService.client = http_testing.MockClient((request) async {
        if (request.url.path.contains('/orders/by-operation/')) {
          return http.Response(jsonEncode({
            'success': false,
            'message': 'Operation not found',
          }), 404, headers: {'content-type': 'application/json'});
        }
        if (request.url.path.contains('/orders/abort-operation/')) {
          return http.Response(jsonEncode({
            'success': false,
            'committed': true,
            'message': 'Cannot abort: Order has already committed.',
            'data': {
              'id': 101,
              'invoice_number': 'INV-INFLIGHT-001',
              'client_operation_id': opId,
              'total_riel': 5000,
              'payment_method': 'cash_riel',
            },
          }), 409, headers: {'content-type': 'application/json'});
        }
        return http.Response('{"success": false}', 500);
      });

      // Cashier tries to dismiss:
      await notifier.cancelOrDismissUnresolvedCheckout();

      // Assert behavior: it did NOT delete or dismiss the sale!
      // It caught the committed order and completed reconciliation!
      expect(container.read(posCartProvider).checkoutStatus, CheckoutStatus.confirmed);
      expect(container.read(posCartProvider).lastCompletedInvoice, 'INV-INFLIGHT-001');

      ApiService.client = null;
    });

    test('Timeout followed by delayed server commit: reconciliation recovers confirmed order and cleans pending state', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final saleRepo = SaleRepository();

      final opId = 'op_timeout_delayed_commit';
      SharedPreferences.setMockInitialValues({
        'mart_pos_pending_checkout_op_id': opId,
        'mart_pos_pending_checkout_invoice': 'INV-DELAYED-777',
        'mart_pos_pending_checkout_status': 'failed',
      });

      // Controllable mock client: delayed commit is now ready (HTTP 200)
      ApiService.client = http_testing.MockClient((request) async {
        if (request.url.path.contains('/orders/by-operation/$opId')) {
          return http.Response(jsonEncode({
            'success': true,
            'data': {
              'id': 202,
              'invoice_number': 'INV-DELAYED-777',
              'client_operation_id': opId,
              'total_riel': 8200,
              'payment_method': 'cash_usd',
            },
          }), 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('{"success": false}', 404);
      });

      final resolution = await saleRepo.resolveOperationStatus(opId);
      expect(resolution.status, OperationResolution.confirmed);
      expect(resolution.orderData!['invoice_number'], 'INV-DELAYED-777');

      // Now clean up pending checkout upon confirmed completion
      await saleRepo.clearPendingCheckout();
      final pending = await saleRepo.getPendingCheckout();
      expect(pending, isNull);

      ApiService.client = null;
    });

    test('Persisted Cash USD checkout restored after restart transmits exact immutable payload on retry', () async {
      TestWidgetsFlutterBinding.ensureInitialized();

      final opId = 'op_cash_usd_restored_999';
      final persistedPayload = {
        'client_operation_id': opId,
        'invoice_number': 'INV-USD-999',
        'items': [
          {'product_id': 1, 'qty': 2, 'custom_price': 4000}
        ],
        'discount_riel': 500,
        'tax_rate': 0.10,
        'tax_riel': 750,
        'total_riel': 8250,
        'total_usd': '2.01',
        'received_riel': 0,
        'received_usd': '10.00',
        'change_riel': 0,
        'change_usd': '7.99',
        'payment_method': 'cash_usd',
        'notes': 'Invoice: INV-USD-999',
      };

      final persistedDraft = {
        'items': [
          {
            'product': {
              'id': '1',
              'name': 'Tiger Beer',
              'code': 'T01',
              'sale_price': 4100,
              'cost_price': 3000,
              'stock_qty': 50,
              'tax': 0.10,
            },
            'qty': 2,
            'customPrice': 4000,
          }
        ],
        'discount': 500,
        'taxRate': 0.10,
      };

      SharedPreferences.setMockInitialValues({
        'mart_pos_pending_checkout_op_id': opId,
        'mart_pos_pending_checkout_invoice': 'INV-USD-999',
        'mart_pos_pending_checkout_status': 'failed',
        'mart_pos_pending_checkout_payload': jsonEncode(persistedPayload),
        'mart_pos_pending_checkout_cart_draft': jsonEncode(persistedDraft),
      });

      final container = ProviderContainer();
      final notifier = container.read(posCartProvider.notifier);

      // Simulate app restart restoration
      await notifier.restorePendingCheckout();

      expect(container.read(posCartProvider).activeOperationId, opId);
      expect(container.read(posCartProvider).activeCheckoutPayload, isNotNull);

      // Track exact body transmitted during retry
      Map<String, dynamic>? transmittedBody;
      ApiService.client = http_testing.MockClient((request) async {
        if (request.url.path == '/api/orders') {
          transmittedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode({
            'success': true,
            'data': {'id': 303, 'invoice_number': 'INV-USD-999'},
          }), 201, headers: {'content-type': 'application/json'});
        }
        return http.Response('{"success": false}', 404);
      });

      // Retry checkout using default parameters from UI call
      // The provider MUST NOT rebuild from UI defaults; it MUST send the original immutable payload!
      await notifier.checkout(cashierId: 'cashier_test_01');

      expect(transmittedBody, isNotNull);
      expect(transmittedBody!['payment_method'], 'cash_usd');
      expect(transmittedBody!['received_usd'], '10.00');
      expect(transmittedBody!['change_usd'], '7.99');
      expect(transmittedBody!['discount_riel'], 500);
      expect(transmittedBody!['items'][0]['custom_price'], 4000);

      ApiService.client = null;
    });

    test('SharedPreferences write failure fails closed and blocks remote transmission', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final saleRepo = SaleRepository();

      int httpCallsCount = 0;
      ApiService.client = http_testing.MockClient((request) async {
        httpCallsCount++;
        return http.Response('{"success": true}', 201);
      });

      final dummySale = SaleModel(
        id: 'op_persist_fail_01',
        invoiceNumber: 'INV-FAIL-01',
        cashierId: 'c1',
        items: [
          SaleItem(productId: '1', name: 'Item', qty: 1, unitPrice: 1000, totalPrice: 1000)
        ],
        subtotal: 1000,
        discount: 0,
        totalTax: 0,
        total: 1000,
        paidAmount: 1000,
        changeAmount: 0,
        paymentMethod: 'cash_riel',
        paymentStatus: 'paid',
        createdAt: DateTime.now(),
      );

      // Verify that if persistPendingCheckout throws, checkoutSale aborts and post is NEVER called
      final unencodablePayload = <String, dynamic>{
        'client_operation_id': 'op_persist_fail_01',
        'invoice_number': 'INV-FAIL-01',
        'unserializable': Object(), // jsonEncode will throw
      };

      expect(
        () => saleRepo.checkoutSale(
          dummySale,
          clientOperationId: 'op_persist_fail_01',
          immutablePayload: unencodablePayload,
        ),
        throwsA(isA<Exception>()),
      );

      expect(httpCallsCount, 0, reason: 'Remote HTTP POST must NEVER be transmitted if persistence fails!');

      ApiService.client = null;
    });

    test('HTTP 404, confirmed response, and network failure distinct handling in resolveOperationStatus', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final saleRepo = SaleRepository();

      // Case A: 200 Confirmed response
      ApiService.client = http_testing.MockClient((request) async {
        return http.Response(jsonEncode({
          'success': true,
          'data': {'id': 1, 'invoice_number': 'INV-200'}
        }), 200, headers: {'content-type': 'application/json'});
      });
      final res200 = await saleRepo.resolveOperationStatus('op_test_200');
      expect(res200.status, OperationResolution.confirmed);
      expect(res200.orderData!['invoice_number'], 'INV-200');

      // Case B: 404 Not Found (Authoritative proof that order was never committed)
      ApiService.client = http_testing.MockClient((request) async {
        return http.Response(jsonEncode({
          'success': false,
          'message': 'Operation not found'
        }), 404, headers: {'content-type': 'application/json'});
      });
      final res404 = await saleRepo.resolveOperationStatus('op_test_404');
      expect(res404.status, OperationResolution.notFound);
      expect(res404.errorMessage, contains('Operation not found'));

      // Case C: Network Failure / Socket error
      ApiService.client = http_testing.MockClient((request) async {
        throw http.ClientException('Connection refused');
      });
      final resNetwork = await saleRepo.resolveOperationStatus('op_test_network');
      expect(resNetwork.status, OperationResolution.unknown);
      expect(resNetwork.errorMessage, contains('Connection refused'));

      ApiService.client = null;
    });

    test('Correct cache reconciliation and pending-state cleanup', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final saleRepo = SaleRepository();

      final opId = 'op_reconcile_cleanup_001';
      SharedPreferences.setMockInitialValues({
        'mart_pos_pending_checkout_op_id': opId,
        'mart_pos_pending_checkout_invoice': 'INV-CLEAN-001',
        'mart_pos_pending_checkout_status': 'pending',
        'mart_pos_pending_checkout_payload': jsonEncode({'total_riel': 5000}),
        'mart_pos_pending_checkout_cart_draft': jsonEncode({'items': []}),
      });

      // Verify pending checkout exists before cleanup
      final before = await saleRepo.getPendingCheckout();
      expect(before, isNotNull);
      expect(before!['operation_id'], opId);

      // Perform cleanup
      await saleRepo.clearPendingCheckout();

      // Assert that all pending state keys are removed
      final after = await saleRepo.getPendingCheckout();
      expect(after, isNull);
    });
  });
}


