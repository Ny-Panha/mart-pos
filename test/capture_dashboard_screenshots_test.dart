import 'dart:async';
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
import 'package:mart_pos/features/admin_manager/presentation/admin_manager_dashboard_screen.dart';
import 'package:mart_pos/features/admin_manager/providers/admin_manager_providers.dart';
import 'package:mart_pos/features/auth/providers/auth_provider.dart';

class _ManagerUser extends AuthNotifier {
  @override
  Future<UserModel?> build() async => UserModel(
        id: 'manager-1',
        name: 'Platform Admin',
        role: UserModel.adminManagerRole,
        shopId: '',
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleDashboard = PlatformDashboard(
    shops: 0,
    activeShops: 0,
    admins: 1,
    cashiers: 1,
    products: 8,
    lowStock: 1,
    revenue: 0,
    orders: 4,
    revenueSeries: [
      PlatformMetricPoint(label: '2026-10-26', value: 0),
      PlatformMetricPoint(label: '2026-10-29', value: 0),
      PlatformMetricPoint(label: '2026-11-01', value: 0),
      PlatformMetricPoint(label: '2026-11-04', value: 0),
      PlatformMetricPoint(label: '2026-11-07', value: 0),
      PlatformMetricPoint(label: '2026-11-10', value: 0),
      PlatformMetricPoint(label: '2026-11-13', value: 0),
      PlatformMetricPoint(label: '2026-11-16', value: 0),
      PlatformMetricPoint(label: '2026-11-19', value: 0),
      PlatformMetricPoint(label: '2026-11-22', value: 0),
      PlatformMetricPoint(label: '2026-11-24', value: 0),
    ],
  );

  final sampleProducts = [
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
      categoryName: 'Beverages',
    ),
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
      categoryName: 'Beverages',
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
      categoryName: 'Personal Care',
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
      categoryName: 'Personal Care',
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
      categoryName: 'Food & Snacks',
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
      categoryName: 'Food & Snacks',
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
      categoryName: 'Beverages',
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
      categoryName: 'Beverages',
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
        managerDashboardProvider.overrideWith((ref) => sampleDashboard),
        managerShopsProvider.overrideWith((ref) => Stream.value([])),
        managerAlertsProvider.overrideWith((ref) => Stream.value([])),
        managerProductsProvider(null).overrideWith((ref) => Stream.value(sampleProducts)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: RepaintBoundary(
          key: boundaryKey,
          child: const AdminManagerDashboardScreen(),
        ),
      ),
    );
  }

  testWidgets('Capture Desktop Light Screenshot of Platform Dashboard',
      (tester) async {
    final desktopKey = GlobalKey();
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 1120);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp(desktopKey));
    await tester.pumpAndSettle();

    // Verify elements from mockup
    expect(find.text('ផ្ទាំងគ្រប់គ្រងប្រព័ន្ធ (Platform Dashboard)'), findsOneWidget);
    expect(find.text('MINI-MART SAAS PLATFORM'), findsOneWidget);
    expect(find.text('Total Shops'), findsOneWidget);
    expect(find.text('Active Shops'), findsOneWidget);
    expect(find.text('Administrators'), findsOneWidget);
    expect(find.text('Cashiers'), findsOneWidget);
    expect(find.text('Global Products'), findsOneWidget);
    expect(find.text('Low Stock Items'), findsOneWidget);
    expect(find.text('30-day Revenue'), findsOneWidget);
    expect(find.text('Orders Committed'), findsOneWidget);
    expect(find.text('Revenue Overview (Last 30 Days)'), findsOneWidget);
    expect(find.text('Platform Overview'), findsOneWidget);
    expect(find.text('Recent Shops'), findsOneWidget);
    expect(find.text('No shops created yet'), findsOneWidget);
    expect(find.text('Create Shop'), findsOneWidget);
    expect(find.text('Platform Alerts'), findsOneWidget);
    expect(find.text('All systems normal'), findsOneWidget);
    expect(find.text('Quick Shortcuts'), findsOneWidget);

    await tester.runAsync(() async {
      final RenderRepaintBoundary boundary =
          desktopKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data != null) {
        final bytes = data.buffer.asUint8List();
        File('docs/screenshots/manager/platform_dashboard_desktop.png').writeAsBytesSync(bytes);
        final artifactDir = Directory('C:/Users/nhastar/.gemini/antigravity/brain/133df4bf-624c-4a4a-802a-c1a02396fe39');
        if (artifactDir.existsSync()) {
          File('${artifactDir.path}/platform_dashboard_desktop.png').writeAsBytesSync(bytes);
        }
      }
    });
  });

  testWidgets('Capture Desktop Dark Screenshot of Platform Dashboard',
      (tester) async {
    final darkKey = GlobalKey();
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 1120);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp(darkKey, dark: true));
    await tester.pumpAndSettle();

    expect(find.text('ផ្ទាំងគ្រប់គ្រងប្រព័ន្ធ (Platform Dashboard)'), findsOneWidget);

    await tester.runAsync(() async {
      final RenderRepaintBoundary boundary =
          darkKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data != null) {
        final bytes = data.buffer.asUint8List();
        File('docs/screenshots/manager/platform_dashboard_dark.png').writeAsBytesSync(bytes);
        final artifactDir = Directory('C:/Users/nhastar/.gemini/antigravity/brain/133df4bf-624c-4a4a-802a-c1a02396fe39');
        if (artifactDir.existsSync()) {
          File('${artifactDir.path}/platform_dashboard_dark.png').writeAsBytesSync(bytes);
        }
      }
    });
  });

  testWidgets('Capture Mobile Screenshot of Platform Dashboard',
      (tester) async {
    final mobileKey = GlobalKey();
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp(mobileKey));
    await tester.pumpAndSettle();

    expect(find.text('ផ្ទាំងគ្រប់គ្រងប្រព័ន្ធ (Platform Dashboard)'), findsOneWidget);

    await tester.runAsync(() async {
      final RenderRepaintBoundary boundary =
          mobileKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data != null) {
        final bytes = data.buffer.asUint8List();
        File('docs/screenshots/manager/platform_dashboard_mobile.png').writeAsBytesSync(bytes);
        final artifactDir = Directory('C:/Users/nhastar/.gemini/antigravity/brain/133df4bf-624c-4a4a-802a-c1a02396fe39');
        if (artifactDir.existsSync()) {
          File('${artifactDir.path}/platform_dashboard_mobile.png').writeAsBytesSync(bytes);
        }
      }
    });
  });
}
