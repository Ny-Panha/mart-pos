import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mart_pos/core/widgets/product_thumbnail.dart';
import 'package:mart_pos/data/firestore/models/product_model.dart';
import 'package:mart_pos/data/firestore/models/user_model.dart';
import 'package:mart_pos/data/firestore/shop_scope.dart';
import 'package:mart_pos/data/services/api_service.dart';
import 'package:mart_pos/features/products/presentation/products_screen.dart';
import 'package:mart_pos/features/products/providers/category_provider.dart';
import 'package:mart_pos/features/products/providers/product_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() {
    ApiService.client = null;
    ShopScope.setUser(null);
  });

  test(
    'simultaneous catalog reads share transport only within one scope',
    () async {
      var reads = 0;
      final gate = Completer<void>();
      ApiService.client = MockClient((request) async {
        final id = ++reads;
        await gate.future;
        return http.Response('{"id":$id}', 200);
      });
      final first = ApiService.get('/products');
      final same = ApiService.get('/products');
      ShopScope.setUser(
        UserModel(id: 'admin', name: 'Admin', shopId: 'other', role: 'ADMIN'),
      );
      final other = ApiService.get('/products');
      gate.complete();
      expect(await first, await same);
      expect(await other, isNot(await first));
      expect(reads, 2);
      await ApiService.get('/products');
      expect(reads, 3);
    },
  );

  test('writes separate pending catalog reads and recovery lookups stay independent', () async {
    var reads = 0;
    final gate = Completer<void>();
    ApiService.client = MockClient((request) async {
      if (request.method == 'GET') {
        reads++;
        await gate.future;
      }
      return http.Response('{}', 200);
    });
    final old = ApiService.get('/products');
    await ApiService.post('/orders', {});
    final pending = [
      old,
      ApiService.get('/products'),
      ApiService.get('/orders/by-operation/x'),
      ApiService.get('/orders/by-operation/x'),
    ];
    gate.complete();
    await Future.wait(pending);
    expect(reads, 4);
  });

  test('a failed catalog read can be retried', () async {
    var reads = 0;
    ApiService.client = MockClient(
      (_) async => http.Response('{}', ++reads == 1 ? 503 : 200),
    );
    await expectLater(
      ApiService.get('/categories'),
      throwsA(isA<ApiException>()),
    );
    expect(await ApiService.get('/categories'), isEmpty);
    expect(reads, 2);
  });

  testWidgets('mobile catalog mounts only cards near the viewport', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(500, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final products = List.generate(
      1000,
      (i) => ProductModel.fromJson({'id': i, 'name': 'Product $i'}),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productsStreamProvider.overrideWith((_) => Stream.value(products)),
          categoriesStreamProvider.overrideWith((_) => Stream.value([])),
        ],
        child: const MaterialApp(home: ProductsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final mounted = find
        .byType(ProductThumbnail, skipOffstage: false)
        .evaluate()
        .length;
    expect(mounted, inInclusiveRange(1, 30));
    expect(find.textContaining('1000 Items'), findsOneWidget);
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    scroll.position.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(find.text('Product 999'), findsOneWidget);
  });
}
