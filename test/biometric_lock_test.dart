import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mart_pos/core/role_route_guard.dart';
import 'package:mart_pos/data/firestore/models/user_model.dart';
import 'package:mart_pos/features/auth/presentation/biometric_lock_screen.dart';
import 'package:mart_pos/features/auth/presentation/login_screen.dart';
import 'package:mart_pos/features/auth/providers/auth_provider.dart';
import 'package:mart_pos/features/auth/providers/biometric_provider.dart';
import 'package:mart_pos/features/auth/services/biometric_auth_service.dart';

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this.user);
  final UserModel? user;

  @override
  Future<UserModel?> build() async => user;
}

class _FakeBiometricAuthService implements BiometricAuthService {
  _FakeBiometricAuthService({
    required this.supported,
    Map<String, bool>? enabledByUid,
    this.nextAuthResult = const BiometricAuthResult(
      outcome: BiometricAuthOutcome.success,
    ),
  }) : _enabledByUid = enabledByUid ?? <String, bool>{};

  bool supported;
  final Map<String, bool> _enabledByUid;
  final Set<String> _offeredUids = <String>{};
  BiometricAuthResult nextAuthResult;

  @override
  Future<bool> isBiometricAvailable() async => supported;

  @override
  Future<bool> isEnabledForUser(String uid) async => _enabledByUid[uid] ?? false;

  @override
  Future<void> setEnabledForUser(String uid, bool enabled) async {
    if (enabled) {
      _enabledByUid[uid] = true;
    } else {
      _enabledByUid.remove(uid);
    }
  }

  @override
  Future<bool> hasOfferedForUser(String uid) async => _offeredUids.contains(uid);

  @override
  Future<void> markOfferedForUser(String uid) async {
    _offeredUids.add(uid);
  }

  @override
  Future<BiometricAuthResult> authenticate({
    required String localizedReason,
  }) async {
    return nextAuthResult;
  }
}

class _RefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final _testRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RefreshNotifier();
  final authSub = ref.listen(authProvider, (_, _) => refreshNotifier.refresh());
  final bioSub = ref.listen(
    biometricLockProvider,
    (_, _) => refreshNotifier.refresh(),
  );

  final router = GoRouter(
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      if (authState.isLoading) return null;

      final user = authState.value;
      final path = state.uri.path;
      final isLoggingIn = path == '/login';

      if (user == null) {
        return isLoggingIn ? null : '/login';
      }

      final lockState = ref.read(biometricLockProvider);
      if (lockState.status == BiometricLockStatus.checking ||
          lockState.status == BiometricLockStatus.locked) {
        return path == '/biometric-lock' ? null : '/biometric-lock';
      }
      if (lockState.status == BiometricLockStatus.bypassedToLogin) {
        return isLoggingIn ? null : '/login';
      }
      if (path == '/biometric-lock') {
        return RoleRouteGuard.redirect(user, '/');
      }

      return RoleRouteGuard.redirect(user, path);
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/biometric-lock',
        builder: (_, _) => const BiometricLockScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (_, _) => const Scaffold(body: Text('Admin Shell')),
      ),
      GoRoute(
        path: '/pos',
        builder: (_, _) => const Scaffold(body: Text('POS Shell')),
      ),
    ],
  );

  ref.onDispose(() {
    authSub.close();
    bioSub.close();
    router.dispose();
    refreshNotifier.dispose();
  });

  return router;
});

Widget _buildTestApp({
  required UserModel user,
  required _FakeBiometricAuthService fakeBiometric,
}) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(() => _FakeAuthNotifier(user)),
      biometricAuthServiceProvider.overrideWithValue(fakeBiometric),
    ],
    child: Consumer(
      builder: (context, ref, _) {
        final router = ref.watch(_testRouterProvider);
        return MaterialApp.router(routerConfig: router);
      },
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final adminUser = UserModel(
    id: 'uid-admin-1',
    name: 'Admin',
    email: 'admin@bbu.edu.kh',
    role: UserModel.adminRole,
    shopId: 'shop-1',
  );

  final cashierUser = UserModel(
    id: 'uid-cashier-1',
    name: 'Cashier',
    email: 'cashier@bbu.edu.kh',
    role: UserModel.cashierRole,
    shopId: 'shop-1',
  );

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  testWidgets(
    'supported + enabled -> lock screen shown & direct /admin deep-link blocked',
    (tester) async {
      configureViewport(tester);
      final fake = _FakeBiometricAuthService(
        supported: true,
        enabledByUid: {adminUser.id: true},
      );

      await tester.pumpWidget(
        _buildTestApp(user: adminUser, fakeBiometric: fake),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BiometricLockScreen), findsOneWidget);
      expect(find.text('Unlock with fingerprint / face'), findsOneWidget);

      // Attempt direct deep-link to /admin while locked
      final container = ProviderScope.containerOf(
        tester.element(find.byType(BiometricLockScreen)),
      );
      container.read(_testRouterProvider).go('/admin');
      await tester.pumpAndSettle();

      expect(find.byType(BiometricLockScreen), findsOneWidget);
      expect(find.text('Admin Shell'), findsNothing);
    },
  );

  testWidgets('not supported -> lock screen never shown, enters guard route', (
    tester,
  ) async {
    configureViewport(tester);
    final fake = _FakeBiometricAuthService(
      supported: false,
      enabledByUid: {cashierUser.id: true},
    );

    await tester.pumpWidget(
      _buildTestApp(user: cashierUser, fakeBiometric: fake),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BiometricLockScreen), findsNothing);
    expect(find.text('POS Shell'), findsOneWidget);
  });

  testWidgets('auth success -> unlocks and enters RoleRouteGuard destination', (
    tester,
  ) async {
    configureViewport(tester);
    final fake = _FakeBiometricAuthService(
      supported: true,
      enabledByUid: {adminUser.id: true},
      nextAuthResult: const BiometricAuthResult(
        outcome: BiometricAuthOutcome.success,
      ),
    );

    await tester.pumpWidget(
      _buildTestApp(user: adminUser, fakeBiometric: fake),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BiometricLockScreen), findsOneWidget);

    await tester.tap(find.text('Unlock with fingerprint / face'));
    await tester.pumpAndSettle();

    expect(find.byType(BiometricLockScreen), findsNothing);
    expect(find.text('Admin Shell'), findsOneWidget);
  });

  testWidgets('auth fail -> stays locked and shows inline error', (
    tester,
  ) async {
    configureViewport(tester);
    final fake = _FakeBiometricAuthService(
      supported: true,
      enabledByUid: {cashierUser.id: true},
      nextAuthResult: const BiometricAuthResult(
        outcome: BiometricAuthOutcome.failed,
        message: 'Fingerprint not recognized',
      ),
    );

    await tester.pumpWidget(
      _buildTestApp(user: cashierUser, fakeBiometric: fake),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Unlock with fingerprint / face'));
    await tester.pumpAndSettle();

    expect(find.byType(BiometricLockScreen), findsOneWidget);
    expect(find.text('Fingerprint not recognized'), findsOneWidget);
  });

  testWidgets(
    'use password instead -> routes to LoginScreen without signing out & blocks /pos deep-link',
    (tester) async {
      configureViewport(tester);
      final fake = _FakeBiometricAuthService(
        supported: true,
        enabledByUid: {cashierUser.id: true},
      );

      await tester.pumpWidget(
        _buildTestApp(user: cashierUser, fakeBiometric: fake),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Use password instead'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(LoginScreen)),
      );
      // Session is still present (not signed out)
      expect(container.read(authProvider).value?.id, cashierUser.id);

      // Deep-link to /pos must still redirect to /login
      container.read(_testRouterProvider).go('/pos');
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('POS Shell'), findsNothing);
    },
  );

  test('toggling biometric OFF clears per-user flag', () async {
    final fake = _FakeBiometricAuthService(
      supported: true,
      enabledByUid: {adminUser.id: true},
    );
    expect(await fake.isEnabledForUser(adminUser.id), isTrue);

    await fake.setEnabledForUser(adminUser.id, false);
    expect(await fake.isEnabledForUser(adminUser.id), isFalse);
  });
}
