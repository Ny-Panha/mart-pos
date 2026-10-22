import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mart_pos/core/widgets/main_shell.dart';
import 'package:mart_pos/data/firestore/models/user_model.dart';
import 'package:mart_pos/features/auth/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> expectNavigationFor(
    WidgetTester tester,
    UserModel user,
    List<String> labels,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(path: '/home', builder: (_, _) => const Text('Home body')),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(() => _FakeAuthNotifier(user))],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    for (final label in labels) {
      expect(find.text(label, skipOffstage: false), findsOneWidget);
    }
    router.dispose();
  }

  testWidgets('manager receives platform navigation', (tester) async {
    await expectNavigationFor(
      tester,
      UserModel(id: 'm1', name: 'Manager', role: UserModel.adminManagerRole),
      [
        'Dashboard',
        'Shops',
        'Admin Owners',
        'Locations',
        'Subscriptions',
        'Stock Overview',
        'Global Products',
        'System Reports',
        'Settings',
      ],
    );
  });

  testWidgets('shop admin receives operations navigation', (tester) async {
    await expectNavigationFor(
      tester,
      UserModel(
        id: 'a1',
        name: 'Admin',
        role: UserModel.adminRole,
        shopId: 'shop-a',
      ),
      [
        'POS Checkout',
        'Dashboard',
        'Products & Category',
        'Stock Movements',
        'Purchases',
        'Suppliers',
        'Reports & Analytics',
        'Customers',
        'Staff & Shifts',
        'Attendance',
        'Notifications',
        'Audit Log',
        'Shop Settings',
      ],
    );
  });

  testWidgets('cashier receives POS navigation', (tester) async {
    await expectNavigationFor(
      tester,
      UserModel(
        id: 'c1',
        name: 'Cashier',
        role: UserModel.cashierRole,
        shopId: 'shop-a',
      ),
      ['POS', 'Sales History', 'Stock Check', 'My Shift'],
    );
  });
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this.user);
  final UserModel user;

  @override
  Future<UserModel?> build() async => user;
}
