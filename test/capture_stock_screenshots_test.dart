import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mart_pos/core/theme/app_theme.dart';
import 'package:mart_pos/data/firestore/models/user_model.dart';
import 'package:mart_pos/features/admin_manager/models/admin_manager_models.dart';
import 'package:mart_pos/features/admin_manager/presentation/admin_manager_stock_screen.dart';
import 'package:mart_pos/features/admin_manager/providers/admin_manager_providers.dart';
import 'package:mart_pos/features/auth/providers/auth_provider.dart';

class _ManagerUser extends AuthNotifier {
  @override
  Future<UserModel?> build() async => UserModel(
        id: 'manager-1',
        name: 'Manager',
        role: UserModel.adminManagerRole,
        shopId: '',
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleShops = [
    ShopSummary(
      id: 'default-shop',
      name: 'default-shop',
      ownerName: 'Platform Admin',
      ownerEmail: 'admin@martpos.com',
      status: 'active',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
  ];

  final sampleProducts = [
    const PlatformProduct(
      id: 'p1',
      shopId: 'default-shop',
      shopName: 'default-shop',
      name: 'Coca Cola 330ml',
      sku: 'COCA-330',
      barcode: '884000101',
      stockQty: 46,
      salePrice: 2500,
      lowStockThreshold: 5,
    ),
    const PlatformProduct(
      id: 'p2',
      shopId: 'default-shop',
      shopName: 'default-shop',
      name: 'Sting Energy Drink 330ml',
      sku: 'STING-330',
      barcode: '884000102',
      stockQty: 34,
      salePrice: 3000,
      lowStockThreshold: 5,
    ),
    const PlatformProduct(
      id: 'p3',
      shopId: 'default-shop',
      shopName: 'default-shop',
      name: 'Red Bull Energy 250ml',
      sku: 'REDBULL-250',
      barcode: '884000103',
      stockQty: 23,
      salePrice: 3600,
      lowStockThreshold: 5,
    ),
    const PlatformProduct(
      id: 'p4',
      shopId: 'default-shop',
      shopName: 'default-shop',
      name: 'Angkor Puro Water 500ml',
      sku: 'WATER-500',
      barcode: '884000104',
      stockQty: 79,
      salePrice: 1500,
      lowStockThreshold: 10,
    ),
    const PlatformProduct(
      id: 'p5',
      shopId: 'default-shop',
      shopName: 'default-shop',
      name: 'MAMA Noodles Tom Yum 60g',
      sku: 'MAMA-TOMYUM',
      barcode: '884000201',
      stockQty: 50,
      salePrice: 2000,
      lowStockThreshold: 10,
    ),
    const PlatformProduct(
      id: 'p6',
      shopId: 'default-shop',
      shopName: 'default-shop',
      name: 'Oreo Biscuits 120g',
      sku: 'OREO-120',
      barcode: '884000202',
      stockQty: 17,
      salePrice: 4500,
      lowStockThreshold: 5,
    ),
    const PlatformProduct(
      id: 'p7',
      shopId: 'default-shop',
      shopName: 'default-shop',
      name: 'Colgate Toothpaste 150g',
      sku: 'COLGATE-150',
      barcode: '884000301',
      stockQty: 12,
      salePrice: 7200,
      lowStockThreshold: 5,
    ),
    const PlatformProduct(
      id: 'p8',
      shopId: 'default-shop',
      shopName: 'default-shop',
      name: 'Lifebuoy Soap 90g',
      sku: 'LIFEBUOY-90',
      barcode: '884000302',
      stockQty: 4,
      salePrice: 2800,
      lowStockThreshold: 5,
    ),
  ];

  setUpAll(() async {
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();

    if (File('assets/fonts/NotoSansKhmer-Bold.ttf').existsSync()) {
      final khmerLoader = FontLoader('NotoSansKhmer')
        ..addFont(File('assets/fonts/NotoSansKhmer-Bold.ttf')
            .readAsBytes()
            .then((b) => ByteData.sublistView(b)))
        ..addFont(File('assets/fonts/NotoSansKhmer-Regular.ttf')
            .readAsBytes()
            .then((b) => ByteData.sublistView(b)));
      await khmerLoader.load();
    }

    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.lightTheme;
    AppTheme.darkTheme;
    await GoogleFonts.pendingFonts();
    Directory('docs/screenshots/manager').createSync(recursive: true);
  });

  Widget buildApp(GlobalKey boundaryKey, {bool dark = false}) {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith(() => _ManagerUser()),
        managerShopsProvider.overrideWith((ref) => Stream.value(sampleShops)),
        managerProductsProvider(null).overrideWith((ref) => Stream.value(sampleProducts)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: RepaintBoundary(
          key: boundaryKey,
          child: const AdminManagerStockScreen(),
        ),
      ),
    );
  }

  testWidgets('Capture Desktop Screenshot of Rebuilt Stock Overview',
      (tester) async {
    final desktopKey = GlobalKey();
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 950);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp(desktopKey));
    await tester.pumpAndSettle();

    expect(find.text('ស្តុកសរុបប្រព័ន្ធ (Stock Overview)'), findsOneWidget);
    expect(find.text('Healthy Stock'), findsWidgets);
    expect(find.text('Low Stock Alert'), findsWidgets);
    expect(find.text('Out of Stock'), findsWidgets);
    expect(find.text('Stock Trend (All Shops)'), findsOneWidget);
    expect(find.text('Stock Health Distribution'), findsOneWidget);
    expect(find.text('Coca Cola 330ml'), findsWidgets);
    expect(find.text('Lifebuoy Soap 90g'), findsWidgets);

    await tester.runAsync(() async {
      final RenderRepaintBoundary boundary =
          desktopKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data != null) {
        final bytes = data.buffer.asUint8List();
        File('docs/screenshots/manager/stock_overview_desktop.png').writeAsBytesSync(bytes);
        final artifactDir = Directory('C:/Users/nhastar/.gemini/antigravity/brain/133df4bf-624c-4a4a-802a-c1a02396fe39');
        if (artifactDir.existsSync()) {
          File('${artifactDir.path}/stock_overview_desktop.png').writeAsBytesSync(bytes);
        }
      }
    });
  });

  testWidgets('Capture Mobile Screenshot of Rebuilt Stock Overview',
      (tester) async {
    final mobileKey = GlobalKey();
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp(mobileKey));
    await tester.pumpAndSettle();

    expect(find.text('ស្តុកសរុបប្រព័ន្ធ (Stock Overview)'), findsOneWidget);

    await tester.runAsync(() async {
      final RenderRepaintBoundary boundary =
          mobileKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data != null) {
        final bytes = data.buffer.asUint8List();
        File('docs/screenshots/manager/stock_overview_mobile.png').writeAsBytesSync(bytes);
        final artifactDir = Directory('C:/Users/nhastar/.gemini/antigravity/brain/133df4bf-624c-4a4a-802a-c1a02396fe39');
        if (artifactDir.existsSync()) {
          File('${artifactDir.path}/stock_overview_mobile.png').writeAsBytesSync(bytes);
        }
      }
    });
  });
}
