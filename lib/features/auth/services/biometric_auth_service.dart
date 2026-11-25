import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Result status of a biometric authentication attempt.
enum BiometricAuthOutcome {
  success,
  failed,
  cancelled,
  lockedOut,
  unavailable,
  error,
}

/// Outcome and optional user-facing message from [BiometricAuthService.authenticate].
class BiometricAuthResult {
  final BiometricAuthOutcome outcome;
  final String? message;

  const BiometricAuthResult({
    required this.outcome,
    this.message,
  });

  bool get isSuccess => outcome == BiometricAuthOutcome.success;
}

/// Abstraction over device biometric capability checks, per-user opt-in storage,
/// and local biometric authentication so tests can substitute a fake.
abstract class BiometricAuthService {
  Future<bool> isBiometricAvailable();
  Future<bool> isEnabledForUser(String uid);
  Future<void> setEnabledForUser(String uid, bool enabled);
  Future<bool> hasOfferedForUser(String uid);
  Future<void> markOfferedForUser(String uid);
  Future<BiometricAuthResult> authenticate({required String localizedReason});
}

/// Production implementation backed by `local_auth` and `flutter_secure_storage`.
/// Never stores user passwords; only stores per-UID boolean opt-in flags.
class LocalBiometricAuthService implements BiometricAuthService {
  LocalBiometricAuthService({
    LocalAuthentication? localAuth,
    FlutterSecureStorage? secureStorage,
  })  : _localAuth = localAuth ?? LocalAuthentication(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _secureStorage;

  static String _enabledKey(String uid) => 'biometric_enabled_$uid';
  static String _offeredKey(String uid) => 'biometric_offered_$uid';

  @override
  Future<bool> isBiometricAvailable() async {
    if (kIsWeb) return false;
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      if (!isSupported) return false;

      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return false;

      final available = await _localAuth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isEnabledForUser(String uid) async {
    if (kIsWeb || uid.isEmpty) return false;
    try {
      final value = await _secureStorage.read(key: _enabledKey(uid));
      return value == 'true';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> setEnabledForUser(String uid, bool enabled) async {
    if (kIsWeb || uid.isEmpty) return;
    if (enabled) {
      await _secureStorage.write(key: _enabledKey(uid), value: 'true');
    } else {
      await _secureStorage.delete(key: _enabledKey(uid));
    }
  }

  @override
  Future<bool> hasOfferedForUser(String uid) async {
    if (kIsWeb || uid.isEmpty) return true;
    try {
      final value = await _secureStorage.read(key: _offeredKey(uid));
      return value == 'true';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> markOfferedForUser(String uid) async {
    if (kIsWeb || uid.isEmpty) return;
    await _secureStorage.write(key: _offeredKey(uid), value: 'true');
  }

  @override
  Future<BiometricAuthResult> authenticate({
    required String localizedReason,
  }) async {
    if (kIsWeb) {
      return const BiometricAuthResult(
        outcome: BiometricAuthOutcome.unavailable,
        message: 'Biometric unlock is not supported on web.',
      );
    }

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (authenticated) {
        return const BiometricAuthResult(outcome: BiometricAuthOutcome.success);
      }
      return const BiometricAuthResult(
        outcome: BiometricAuthOutcome.failed,
        message: 'Biometric verification failed. Try again or use password.',
      );
    } on LocalAuthException catch (e) {
      switch (e.code) {
        case LocalAuthExceptionCode.userCanceled:
        case LocalAuthExceptionCode.systemCanceled:
        case LocalAuthExceptionCode.timeout:
        case LocalAuthExceptionCode.userRequestedFallback:
          return const BiometricAuthResult(
            outcome: BiometricAuthOutcome.cancelled,
            message: 'Biometric unlock cancelled. Try again or use password.',
          );
        case LocalAuthExceptionCode.temporaryLockout:
        case LocalAuthExceptionCode.biometricLockout:
          return const BiometricAuthResult(
            outcome: BiometricAuthOutcome.lockedOut,
            message: 'Biometrics temporarily locked. Please use password instead.',
          );
        case LocalAuthExceptionCode.noBiometricsEnrolled:
        case LocalAuthExceptionCode.noBiometricHardware:
        case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
        case LocalAuthExceptionCode.noCredentialsSet:
          return const BiometricAuthResult(
            outcome: BiometricAuthOutcome.unavailable,
            message: 'Biometric authentication is unavailable. Please use password.',
          );
        case LocalAuthExceptionCode.authInProgress:
        case LocalAuthExceptionCode.uiUnavailable:
        case LocalAuthExceptionCode.deviceError:
        case LocalAuthExceptionCode.unknownError:
          return BiometricAuthResult(
            outcome: BiometricAuthOutcome.error,
            message: e.description ?? 'Biometric error. Please use password instead.',
          );
      }
    } catch (e) {
      return BiometricAuthResult(
        outcome: BiometricAuthOutcome.error,
        message: 'Biometric error: $e',
      );
    }
  }
}
