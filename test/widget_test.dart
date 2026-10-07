import 'package:flutter_test/flutter_test.dart';
import 'package:mart_pos/core/utils/money.dart';
import 'package:mart_pos/data/firestore/models/category_model.dart';
import 'package:mart_pos/data/firestore/models/product_model.dart';
import 'package:mart_pos/data/repositories/product_repository.dart';

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
}
