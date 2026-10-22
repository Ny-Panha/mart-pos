import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mart_pos/data/firestore/models/sale_model.dart';
import 'package:mart_pos/data/firestore/models/product_model.dart';
import 'package:mart_pos/data/firestore/models/customer_model.dart';
import 'package:mart_pos/data/firestore/models/user_model.dart';
import 'package:mart_pos/features/auth/providers/auth_provider.dart';
import 'package:mart_pos/features/customers/providers/customer_provider.dart';
import 'package:mart_pos/features/products/providers/product_provider.dart';
import 'package:mart_pos/features/reports/presentation/reports_screen.dart';
import 'package:mart_pos/features/reports/providers/report_provider.dart';
import 'package:mart_pos/features/users/providers/user_provider.dart';

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this.user);
  final UserModel user;

  @override
  Future<UserModel?> build() async => user;
}

void main() {
  testWidgets('ReportsScreen renders without error with sales data', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final testUser = UserModel(
      id: 'cashier-1',
      name: 'Cashier Panha',
      role: UserModel.cashierRole,
      shopId: 'shop-test',
    );

    final testCustomer = CustomerModel(
      id: 'cust-1',
      name: 'Bona',
      createdAt: DateTime.now(),
    );

    final testProduct = ProductModel(
      id: 'prod-1',
      name: 'Sting Energy Drink',
      code: 'P001',
      costPrice: 1800,
      salePrice: 2500,
      stockQty: 50,
      categoryId: 'cat-1',
    );

    final testSale = SaleModel(
      id: 'sale-1',
      invoiceNumber: 'INV-20261022-0001',
      cashierId: 'cashier-1',
      cashierName: 'Cashier Panha',
      customerId: 'cust-1',
      customerName: 'Bona',
      items: [
        SaleItem(
          productId: 'prod-1',
          name: 'Sting Energy Drink',
          qty: 2,
          unitPrice: 2000,
          originalPrice: 2500,
          totalPrice: 4000,
        ),
      ],
      subtotal: 4000,
      total: 4000,
      paidAmount: 5000,
      changeAmount: 1000,
      paymentMethod: 'cash',
      paymentStatus: 'paid',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => _FakeAuthNotifier(testUser)),
          reportSalesProvider.overrideWith((ref) => Stream.value([testSale])),
          productsStreamProvider.overrideWith((ref) => Stream.value([testProduct])),
          customersStreamProvider.overrideWith((ref) => Stream.value([testCustomer])),
          usersStreamProvider.overrideWith((ref) => Stream.value([testUser])),
        ],
        child: const MaterialApp(
          home: ReportsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('របាយការណ៍លក់ (Sales Analytics & Reports)'), findsOneWidget);
    expect(find.text('INV-20261022-0001'), findsOneWidget);
  });
}
