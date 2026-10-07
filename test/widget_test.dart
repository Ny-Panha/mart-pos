import 'package:flutter_test/flutter_test.dart';
import 'package:mart_pos/core/utils/money.dart';
import 'package:mart_pos/data/firestore/models/product_model.dart';

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
}
