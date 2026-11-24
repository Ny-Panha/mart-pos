import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mart_pos/core/theme/app_theme.dart';
import 'package:mart_pos/core/utils/money.dart';
import 'package:mart_pos/core/widgets/main_shell.dart';
import 'package:mart_pos/core/widgets/product_thumbnail.dart';
import 'package:mart_pos/core/widgets/qty_stepper.dart';
import 'package:mart_pos/data/firestore/models/category_model.dart';
import 'package:mart_pos/data/firestore/models/customer_model.dart';
import 'package:mart_pos/features/customers/providers/customer_provider.dart';
import 'package:mart_pos/data/firestore/models/daily_close_model.dart';
import 'package:mart_pos/data/firestore/models/product_model.dart';
import 'package:mart_pos/data/firestore/models/user_model.dart';
import 'package:mart_pos/features/auth/providers/auth_provider.dart';
import 'package:mart_pos/features/pos/presentation/payment_dialog.dart';
import 'package:mart_pos/features/pos/presentation/pos_product_card.dart';
import 'package:mart_pos/features/pos/presentation/pos_screen.dart';
import 'package:mart_pos/features/pos/providers/pos_cart_provider.dart';
import 'package:mart_pos/features/products/providers/category_provider.dart';
import 'package:mart_pos/features/products/providers/product_provider.dart';
import 'package:mart_pos/features/shifts/providers/shift_provider.dart';

class _Cashier extends AuthNotifier {
  @override
  Future<UserModel?> build() async => UserModel(
    id: 'cashier',
    name: 'Cashier',
    role: UserModel.cashierRole,
    shopId: 'shop',
  );
}

class _PendingCart extends PosCartNotifier {
  _PendingCart(this.product);
  final ProductModel product;
  final attempts = <(String, int?, int?, double?, double?)>[];
  @override
  Future<String> checkout({
    required String cashierId,
    String paymentMethod = 'cash',
    int? paidAmount,
    int? changeAmount,
    double? receivedUsd,
    double? changeUsd,
  }) async {
    attempts.add((
      paymentMethod,
      paidAmount,
      changeAmount,
      receivedUsd,
      changeUsd,
    ));
    throw StateError('Server outcome unknown');
  }

  @override
  PosCartState build() => PosCartState(
    items: [CartItemState(product: product, qty: 1)],
    activeOperationId: 'pending-operation',
    activeCheckoutPayload: const {
      'payment_method': 'cash_usd',
      'received_riel': 41000,
      'change_riel': 38499,
      'received_usd': '10.00',
      'change_usd': '9.39',
    },
    checkoutStatus: CheckoutStatus.failed,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = jsonDecode(
    File('test/fixtures/pos_catalog.json').readAsStringSync(),
  );
  final categories = (fixture['categories'] as List)
      .map((c) => CategoryModel.fromJson(c))
      .toList();
  final products = (fixture['products'] as List).map((row) {
    final p = ProductModel.fromJson(row);
    final photo = ProductThumbnail.getAssetForProduct(
      id: p.id,
      name: p.name,
      barcode: p.barcode,
    );
    return photo == null ? p : p.copyWith(imageUrl: photo);
  }).toList();
  final first = products.first;
  const frame = ValueKey('pos-app-frame');
  final checkout = find.byKey(const ValueKey('checkout'));
  final confirm = find.byKey(const ValueKey('confirm-payment'));

  setUpAll(() async {
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    GoogleFonts.config.allowRuntimeFetching = false;
    // Load the same bundled Khmer and Latin glyphs the application uses.
    AppTheme.lightTheme;
    AppTheme.darkTheme;
    await GoogleFonts.pendingFonts();
  });

  Future<ProviderContainer> open(
    WidgetTester tester,
    double width, {
    bool dark = false,
    bool pending = false,
    List<ProductModel>? catalog,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(
      width,
      width >= 768
          ? 900
          : width == 320
          ? 640
          : 844,
    );
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (_) async => ['wifi'],
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
      (_) async => null,
    );
    final router = GoRouter(
      initialLocation: '/pos',
      routes: [
        ShellRoute(
          builder: (_, _, child) => MainShell(child: child),
          routes: [GoRoute(path: '/pos', builder: (_, _) => const PosScreen())],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      RepaintBoundary(
        key: frame,
        child: ProviderScope(
          overrides: [
            authProvider.overrideWith(_Cashier.new),
            customersStreamProvider.overrideWith(
              (_) =>
                  Stream.value([CustomerModel(id: 'customer', name: 'សុភា')]),
            ),

            productsStreamProvider.overrideWith(
              (_) => Stream.value(catalog ?? products),
            ),
            categoriesStreamProvider.overrideWith(
              (_) => Stream.value(categories),
            ),
            currentOpenShiftProvider.overrideWith(
              (_) => Stream.value(
                DailyCloseModel(
                  id: 'shift',
                  cashierId: 'cashier',
                  openedAt: DateTime(2026, 11, 24, 8),
                  openingCash: 0,
                ),
              ),
            ),
            if (pending)
              posCartProvider.overrideWith(() => _PendingCart(first)),
          ],
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(PosScreen));
    await tester.runAsync(() async {
      await Future.wait(
        products
            .where((p) => p.imageUrl != null && File(p.imageUrl!).existsSync())
            .map((p) => precacheImage(AssetImage(p.imageUrl!), context)),
      );
    });
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(context);
  }

  Future<void> capture(String name) async {
    if (autoUpdateGoldenFiles) {
      await expectLater(
        find.byKey(frame),
        matchesGoldenFile('../docs/screenshots/pos/$name.png'),
      );
    }
  }

  Future<void> add(WidgetTester tester, ProductModel p) async {
    await tester.tap(find.byTooltip('Add ${p.name}').first);
    await tester.pumpAndSettle();
  }

  for (final width in [320, 360, 390, 430, 768, 1024, 1440]) {
    testWidgets('Catalog, cart and payment fit the cashier shell at $width', (
      tester,
    ) async {
      await open(tester, width.toDouble());
      final grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
      final columns =
          (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
              .crossAxisCount;
      expect(columns, width <= 430 ? equals(2) : greaterThanOrEqualTo(2));
      await add(tester, first);
      expect(find.text('1 in cart'), findsOneWidget);
      if (width == 390) await capture('mobile-catalog-light');
      if (width == 390 || width == 1440) {
        await add(tester, products[1]);
      }
      if (width == 1440) await capture('desktop-pos');
      if (width < 1024) {
        await tester.tap(find.text('View cart'));
        await tester.pumpAndSettle();
      }
      expect(checkout.hitTestable(), findsOneWidget);
      if (width == 390) await capture('mobile-checkout');
      await tester.tap(checkout);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cash USD'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(r'$10'));
      await tester.pumpAndSettle();
      expect(confirm.hitTestable(), findsOneWidget);
      if (width == 390) await capture('cash-usd');
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      await tester.pumpAndSettle();
      expect(
        tester.getBottomRight(confirm).dy,
        lessThanOrEqualTo(tester.view.physicalSize.height - 240),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Dark catalog uses the same product photos, prices and cart', (
    tester,
  ) async {
    await open(tester, 390, dark: true);
    await add(tester, first);
    expect(
      find.text(MoneyUtils.formatUSD(MoneyUtils.rielToUsd(first.salePrice))),
      findsWidgets,
    );
    await capture('mobile-catalog-dark');
  });

  testWidgets(
    'Filters, barcode submission, quantity controls and remove share one cart',
    (tester) async {
      final container = await open(tester, 360);
      await tester.ensureVisible(find.text(categories.last.name));
      await tester.tap(find.text(categories.last.name));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Add ${first.name}'), findsNothing);
      await tester.ensureVisible(find.text('ទាំងអស់'));
      await tester.tap(find.text('ទាំងអស់'));
      final search = find.byType(TextField).first;
      await tester.enterText(search, first.sku);
      await tester.pumpAndSettle();
      expect(find.byType(PosProductCard), findsOneWidget);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(container.read(posCartProvider).totalItemCount, 1);
      await tester.tap(find.byTooltip('View cart'));
      await tester.pumpAndSettle();
      final stepper = find.byType(QtyStepper);
      await tester.tap(
        find.descendant(of: stepper, matching: find.byIcon(Icons.add)),
      );
      await tester.pumpAndSettle();
      expect(container.read(posCartProvider).total, first.salePrice * 2);
      await tester.tap(
        find.descendant(of: stepper, matching: find.byIcon(Icons.remove)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remove ${first.name}'));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(checkout).onPressed, isNull);
    },
  );

  testWidgets(
    'Cashier can select a customer and edit order adjustments at 320px',
    (tester) async {
      final container = await open(tester, 320);
      await add(tester, first);
      await tester.tap(find.text('View cart'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Walk-in'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('សុភា'));
      await tester.tap(find.text('សុភា'));
      await tester.pumpAndSettle();
      expect(container.read(posCartProvider).customerId, 'customer');
      final discount = find.widgetWithText(TextField, 'Discount');
      await tester.ensureVisible(discount);
      await tester.enterText(discount, '500');
      final tax = find.widgetWithText(TextField, 'Tax');
      await tester.ensureVisible(tax);
      await tester.enterText(tax, '10');
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      await tester.pumpAndSettle();
      expect(container.read(posCartProvider).total, 2200);
      expect(checkout.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Unresolved checkout locks cart edits and leaves recovery actions available',
    (tester) async {
      final container = await open(
        tester,
        320,
        pending: true,
        catalog: [first.copyWith(stockQty: 0)],
      );
      expect(find.text('អស់ពីស្តុក'), findsOneWidget);
      expect(
        tester.widget<PosProductCard>(find.byType(PosProductCard)).onAdd,
        isNull,
      );
      await tester.tap(find.byTooltip('View cart'));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(checkout).onPressed, isNull);
      expect(find.textContaining('Reconcile'), findsOneWidget);
      expect(find.textContaining('Dismiss'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      final notifier = container.read(posCartProvider.notifier) as _PendingCart;
      expect(notifier.attempts, [('cash_usd', 41000, 38499, 10.0, 9.39)]);
      expect(
        container.read(posCartProvider).activeOperationId,
        'pending-operation',
      );
      expect(find.byType(PaymentDialog), findsNothing);
      expect(find.textContaining('ជោគជ័យ'), findsNothing);
    },
  );

  testWidgets('An out-of-stock product cannot enter an open cart', (
    tester,
  ) async {
    final container = await open(
      tester,
      390,
      catalog: [first.copyWith(stockQty: 0)],
    );
    expect(
      tester.widget<PosProductCard>(find.byType(PosProductCard)).onAdd,
      isNull,
    );
    await tester.tap(find.byTooltip('Add ${first.name}'));
    expect(container.read(posCartProvider).items, isEmpty);
  });

  testWidgets(
    'Offline disables checkout and resuming makes the retained cart payable',
    (tester) async {
      await open(tester, 390);
      await add(tester, first);
      await tester.tap(find.text('View cart'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test offline'));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(checkout).onPressed, isNull);
      await tester.tap(find.text('Resume online'));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(checkout).onPressed, isNotNull);
    },
  );

  testWidgets(
    'Payment validates both cash methods and sends one submission while processing',
    (tester) async {
      final gate = Completer<void>();
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => PaymentDialog(
                    totalAmount: 4100,
                    customerName: 'Walk-in',
                    onConfirmPayment:
                        ({
                          required paymentMethod,
                          required paidAmount,
                          required changeAmount,
                          receivedUsd,
                          changeUsd,
                        }) async {
                          calls++;
                          expect(
                            (
                              paymentMethod,
                              paidAmount,
                              changeAmount,
                              receivedUsd,
                              changeUsd,
                            ),
                            ('cash_usd', 41000, 36900, 10.0, 9.0),
                          );
                          await gate.future;
                        },
                  ),
                ),
                child: const Text('Pay'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Pay'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '1');
      await tester.pump();
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      await tester.tap(find.text('Exact'));
      await tester.pump();
      expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
      await tester.tap(find.text('KHQR'));
      await tester.pumpAndSettle();
      expect(find.text('Bakong KHQR'), findsOneWidget);
      await tester.tap(find.text('Cash USD'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '0.50');
      await tester.pump();
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      await tester.tap(find.text(r'$10'));
      await tester.pump();
      await tester.tap(confirm);
      await tester.tap(confirm);
      await tester.pump();
      expect(calls, 1);
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.byType(PaymentDialog), findsNothing);
    },
  );
}
