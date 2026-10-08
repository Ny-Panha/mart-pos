import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mart_pos/core/utils/money.dart';
import 'package:mart_pos/data/firestore/models/audit_log_model.dart';
import 'package:mart_pos/data/firestore/models/category_model.dart';
import 'package:mart_pos/data/services/audit_service.dart';
import 'package:mart_pos/data/firestore/models/product_model.dart';
import 'package:mart_pos/data/firestore/models/purchase_model.dart';
import 'package:mart_pos/data/firestore/models/sale_model.dart';
import 'package:mart_pos/data/firestore/models/user_model.dart';
import 'package:mart_pos/data/repositories/inventory_repository.dart';
import 'package:mart_pos/data/repositories/product_repository.dart';
import 'package:mart_pos/data/repositories/purchase_repository.dart';
import 'package:mart_pos/data/repositories/report_repository.dart';
import 'package:mart_pos/data/repositories/shift_repository.dart';
import 'package:mart_pos/data/repositories/supplier_repository.dart';
import 'package:mart_pos/data/repositories/user_repository.dart';
import 'package:mart_pos/features/customers/providers/customer_provider.dart';

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
}


