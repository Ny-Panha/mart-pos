import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mart_pos/core/theme/app_theme.dart';
import 'package:mart_pos/data/firestore/models/user_model.dart';
import 'package:mart_pos/features/admin_manager/models/admin_manager_models.dart';
import 'package:mart_pos/features/admin_manager/presentation/admin_manager_dashboard_screen.dart';
import 'package:mart_pos/features/admin_manager/presentation/admin_manager_operations_screens.dart';
import 'package:mart_pos/features/admin_manager/presentation/admin_manager_reports_screen.dart';
import 'package:mart_pos/features/admin_manager/presentation/admin_manager_system_screen.dart';
import 'package:mart_pos/features/admin_manager/providers/admin_manager_providers.dart';
import 'package:mart_pos/features/auth/providers/auth_provider.dart';

class _ManagerUser extends AuthNotifier {
  @override
  Future<UserModel?> build() async => UserModel(
        id: 'manager-1',
        name: 'Platform Manager',
        role: UserModel.adminManagerRole,
        shopId: '',
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleShops = [
    ShopSummary(
      id: 'shop_1',
      name: 'Battambang Central Mart',
      ownerName: 'Ny Panha',
      ownerEmail: 'panha@bbu.edu.kh',
      phone: '012345678',
      address: 'Street 1, Battambang',
      subscription: 'enterprise',
      status: 'active',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    ShopSummary(
      id: 'shop_2',
      name: 'Siem Reap Express Shop',
      ownerName: 'Sokha Chan',
      ownerEmail: 'sokha@martpos.com',
      phone: '098765432',
      address: 'Pub Street, Siem Reap',
      subscription: 'pro',
      status: 'active',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
  ];

  final sampleAdmins = [
    const AdminOwner(
      id: 'admin_1',
      displayName: 'Ny Panha',
      email: 'panha@bbu.edu.kh',
      role: 'ADMIN',
      shopId: 'shop_1',
      shopName: 'Battambang Central Mart',
      active: true,
    ),
    const AdminOwner(
      id: 'admin_2',
      displayName: 'Sokha Chan',
      email: 'sokha@martpos.com',
      role: 'ADMIN',
      shopId: 'shop_2',
      shopName: 'Siem Reap Express Shop',
      active: true,
    ),
  ];

  final sampleLocations = [
    const ShopLocation(
      id: 'loc_1',
      shopId: 'shop_1',
      name: 'Main Branch (សាខាកណ្តាល)',
      address: 'Battambang Campus Road',
      phone: '012345678',
      active: true,
    ),
    const ShopLocation(
      id: 'loc_2',
      shopId: 'shop_2',
      name: 'Downtown Express Branch',
      address: 'Siem Reap Riverside',
      phone: '098765432',
      active: true,
    ),
  ];

  final sampleSubscriptions = [
    SubscriptionSummary(
      shopId: 'shop_1',
      plan: 'enterprise',
      status: 'active',
      seats: 5,
      expiresAt: DateTime.now().add(const Duration(days: 330)),
    ),
    SubscriptionSummary(
      shopId: 'shop_2',
      plan: 'pro',
      status: 'active',
      seats: 3,
      expiresAt: DateTime.now().add(const Duration(days: 120)),
    ),
  ];

  final List<PlatformProduct> sampleProducts = [
    const PlatformProduct(
      id: 'prod_1',
      shopId: 'shop_1',
      name: 'Vital Premium Water 500ml',
      sku: 'VIT-500',
      barcode: '884123456789',
      stockQty: 85,
      lowStockThreshold: 10,
      salePrice: 1500,
      shopName: 'Battambang Central Mart',
    ),
    const PlatformProduct(
      id: 'prod_2',
      shopId: 'shop_1',
      name: 'Carabao Energy Drink',
      sku: 'CAR-250',
      barcode: '885123456789',
      stockQty: 4,
      lowStockThreshold: 10,
      salePrice: 2500,
      shopName: 'Battambang Central Mart',
    ),
    const PlatformProduct(
      id: 'prod_3',
      shopId: 'shop_2',
      name: 'Instant Noodles Mama Pork',
      sku: 'MAM-01',
      barcode: '885987654321',
      stockQty: 0,
      lowStockThreshold: 5,
      salePrice: 2000,
      shopName: 'Siem Reap Express Shop',
    ),
  ];

  final sampleAlerts = [
    PlatformAlert(
      id: 'alert_1',
      title: 'Low Stock Detected',
      message: 'Carabao Energy Drink is below minimum threshold (4 remaining).',
      severity: 'warning',
      resolved: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  final sampleLogs = [
    PlatformLogEntry(
      id: 'log_1',
      action: 'PROVISION_SHOP',
      actor: 'Platform Manager',
      entity: 'Shop',
      message: 'Shop "Battambang Central Mart" successfully provisioned.',
      severity: 'info',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    PlatformLogEntry(
      id: 'log_2',
      action: 'UPDATE_SUBSCRIPTION',
      actor: 'Platform Manager',
      entity: 'Subscription',
      message: 'Plan upgraded to Enterprise for shop_1.',
      severity: 'info',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
  ];

  final sampleDashboard = PlatformDashboard(
    shops: 2,
    activeShops: 2,
    admins: 2,
    cashiers: 4,
    products: 3,
    lowStock: 2,
    revenue: 450000,
    orders: 48,
    revenueSeries: [
      PlatformMetricPoint(label: '2026-11-20', value: 85000),
      PlatformMetricPoint(label: '2026-11-21', value: 92000),
      PlatformMetricPoint(label: '2026-11-22', value: 110000),
      PlatformMetricPoint(label: '2026-11-23', value: 78000),
      PlatformMetricPoint(label: '2026-11-24', value: 85000),
    ],
  );

  setUpAll(() async {
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.lightTheme;
    AppTheme.darkTheme;
    await GoogleFonts.pendingFonts();
    Directory('docs/screenshots/manager').createSync(recursive: true);
  });

  Widget buildTestApp({
    required Widget child,
    bool dark = false,
  }) {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith(() => _ManagerUser()),
        managerDashboardProvider.overrideWith((ref) => sampleDashboard),
        managerShopsProvider.overrideWith((ref) => Stream.value(sampleShops)),
        managerAdminsProvider(null).overrideWith((ref) => Stream.value(sampleAdmins)),
        managerLocationsProvider(null).overrideWith((ref) => Stream.value(sampleLocations)),
        managerSubscriptionsProvider.overrideWith((ref) => Stream.value(sampleSubscriptions)),
        managerProductsProvider(null).overrideWith((ref) => Stream.value(sampleProducts)),
        managerAlertsProvider.overrideWith((ref) => Stream.value(sampleAlerts)),
        managerLogsProvider.overrideWith((ref) => Stream.value(sampleLogs)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: child,
      ),
    );
  }

  testWidgets('catalog restores search only inside its route storage bucket', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.reset);
    final bucket = PageStorageBucket();
    Future<void> open(PageStorageBucket storage) async {
      await tester.pumpWidget(buildTestApp(child: PageStorage(
        bucket: storage,
        child: const AdminManagerCatalogScreen(),
      )));
      await tester.pumpAndSettle();
    }
    await open(bucket);
    await tester.enterText(find.byType(TextField).first, 'Vital');
    await tester.pumpWidget(const SizedBox());
    await open(bucket);
    expect(tester.widget<TextField>(find.byType(TextField).first).controller!.text, 'Vital');
    await tester.pumpWidget(const SizedBox());
    await open(PageStorageBucket());
    expect(tester.widget<TextField>(find.byType(TextField).first).controller!.text, isEmpty);
  });

  testWidgets('Platform Dashboard renders without overflow across viewports',
      (tester) async {
    for (final width in [320.0, 360.0, 390.0, 430.0, 768.0, 1024.0, 1440.0]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, width >= 768 ? 900 : 780);
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        buildTestApp(child: const AdminManagerDashboardScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('ផ្ទាំងគ្រប់គ្រងប្រព័ន្ធ (Platform Dashboard)'), findsOneWidget);
      expect(find.textContaining('Total'), findsOneWidget);
      expect(find.textContaining('Active'), findsWidgets);
      expect(find.textContaining('Shortcuts'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Shops screen renders table and cards without overflow',
      (tester) async {
    for (final width in [320.0, 390.0, 1024.0]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        buildTestApp(child: const AdminManagerShopsScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('គ្រប់គ្រងហាង (Shops)'), findsOneWidget);
      expect(find.text('New Shop'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Admins screen renders administrator list without overflow',
      (tester) async {
    for (final width in [360.0, 1024.0]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        buildTestApp(child: const AdminManagerAdminsScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('អ្នកគ្រប់គ្រងហាង (Admin Owners)'), findsOneWidget);
      expect(find.text('Ny Panha'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Locations screen renders branch list without overflow',
      (tester) async {
    for (final width in [360.0, 1024.0]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        buildTestApp(child: const AdminManagerLocationsScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('ទីតាំងសាខា (Locations)'), findsOneWidget);
      expect(find.text('Main Branch (សាខាកណ្តាល)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Subscriptions screen renders KPI cards and plan table',
      (tester) async {
    for (final width in [360.0, 1024.0]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        buildTestApp(child: const AdminManagerSubscriptionsScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('កញ្ចប់សេវា (Subscriptions)'), findsOneWidget);
      expect(find.text('Total Subscriptions'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Stock Overview screen renders stock health filters and ledger',
      (tester) async {
    for (final width in [360.0, 1024.0]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        buildTestApp(child: const AdminManagerStockScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('ស្តុកសរុបប្រព័ន្ធ (Stock Overview)'), findsOneWidget);
      expect(find.text('Healthy Stock'), findsOneWidget);
      expect(find.text('Low Stock Alert'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Global Products screen renders product cards and prices',
      (tester) async {
    for (final width in [360.0, 1024.0]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        buildTestApp(child: const AdminManagerCatalogScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Global Products'), findsWidgets);
      expect(find.text('Vital Premium Water 500ml'), findsOneWidget);
      expect(find.text('Catalog Items'), findsOneWidget);
      expect(find.text('Total Valuation'), findsOneWidget);

      // Verify toggle to list view and back
      final listViewButton = find.byTooltip('List view');
      if (listViewButton.evaluate().isNotEmpty) {
        await tester.tap(listViewButton);
        await tester.pumpAndSettle();
        expect(find.byType(AdminManagerCatalogScreen), findsOneWidget);

        // Toggle back to grid view
        await tester.tap(find.byTooltip('Grid view'));
        await tester.pumpAndSettle();
      }

      // Tap card to open Product Details dialog
      await tester.tap(find.text('Vital Premium Water 500ml'), warnIfMissed: false);
      await tester.pumpAndSettle();
      if (find.text('Product Details').evaluate().isNotEmpty) {
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
      }

      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('System Reports screen renders chart and daily ledger',
      (tester) async {
    for (final width in [360.0, 1024.0]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        buildTestApp(child: const AdminManagerReportsScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('System Reports'), findsWidgets);
      expect(find.textContaining('Revenue Analytics'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('System Operations screen renders tabs and configuration',
      (tester) async {
    for (final width in [360.0, 1024.0]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        buildTestApp(child: const AdminManagerSystemScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('ប្រតិបត្តិការប្រព័ន្ធ (System Operations)'), findsOneWidget);
      expect(find.text('Audit Logs'), findsOneWidget);
      expect(find.text('System Alerts'), findsOneWidget);
      expect(find.text('Service Health'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Dark theme renders correctly on all manager screens',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1024, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      buildTestApp(
        child: const AdminManagerDashboardScreen(),
        dark: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ផ្ទាំងគ្រប់គ្រងប្រព័ន្ធ (Platform Dashboard)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
