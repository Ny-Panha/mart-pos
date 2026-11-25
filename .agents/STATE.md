# MART POS shared state

## Last Session

- Antigravity IDE · 2026-11-26 02:57 ICT
- Active Branch: `feat/biometric-login` (branched from `fix/two-role-flow` @ `0a691ae`)
- Production Branch: `main` (untouched at `9998bdf`)

## Summary: Biometric Unlock Feature Implemented

- **Added Packages**:
  - `local_auth: ^3.0.2`
  - `flutter_secure_storage: ^11.2.0`
- **Implemented**:
  - `lib/features/auth/services/biometric_auth_service.dart` (`BiometricAuthService`, `LocalBiometricAuthService`)
  - `lib/features/auth/providers/biometric_provider.dart` (`biometricLockProvider`, `biometricAvailableProvider`, `biometricEnabledProvider`)
  - `lib/features/auth/presentation/biometric_lock_screen.dart` (`BiometricLockScreen` with `PopScope(canPop: false)`)
  - `lib/features/auth/presentation/widgets/biometric_toggle_tile.dart` (`BiometricToggleTile`)
  - Wired into `lib/core/router.dart`, `lib/features/auth/presentation/login_screen.dart`, `lib/features/shop_admin/presentation/admin_shop_settings_screen.dart`, `lib/features/cashier/presentation/cashier_daily_close_screen.dart`
  - Native configs: `MainActivity.kt` (`FlutterFragmentActivity`), `AndroidManifest.xml` (`USE_BIOMETRIC`, `USE_FINGERPRINT`), `ios/Runner/Info.plist` (`NSFaceIDUsageDescription`)
- **Tests**:
  - `test/biometric_lock_test.dart` (6 tests) + `test/role_navigation_widget_test.dart` (3 tests) passed.
  - `flutter analyze`: 0 issues.

## Active Environment

- Branch: `feat/biometric-login`
- Note: Pre-existing uncommitted changes from `fix/two-role-flow` working tree were left unstaged and untouched.

## Next Steps

- Manual test on Pixel 7 (enable offer, cold-start fingerprint unlock, cancel fallback, toggle OFF).
