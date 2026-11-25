import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/biometric_auth_service.dart';
import 'auth_provider.dart';

final biometricAuthServiceProvider = Provider<BiometricAuthService>((ref) {
  return LocalBiometricAuthService();
});

final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(biometricAuthServiceProvider);
  return service.isBiometricAvailable();
});

final biometricEnabledProvider = FutureProvider.family<bool, String>((
  ref,
  uid,
) async {
  final service = ref.watch(biometricAuthServiceProvider);
  final available = await service.isBiometricAvailable();
  if (!available) return false;
  return service.isEnabledForUser(uid);
});

enum BiometricLockStatus {
  checking,
  locked,
  unlocked,
  bypassedToLogin,
}

class BiometricLockState {
  final BiometricLockStatus status;
  final bool isAuthenticating;
  final String? errorMessage;
  final String? activeUid;
  final String? pendingEnableOfferUid;

  const BiometricLockState({
    required this.status,
    this.isAuthenticating = false,
    this.errorMessage,
    this.activeUid,
    this.pendingEnableOfferUid,
  });

  BiometricLockState copyWith({
    BiometricLockStatus? status,
    bool? isAuthenticating,
    String? errorMessage,
    bool clearError = false,
    String? activeUid,
    String? pendingEnableOfferUid,
    bool clearPendingOffer = false,
  }) {
    return BiometricLockState(
      status: status ?? this.status,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      activeUid: activeUid ?? this.activeUid,
      pendingEnableOfferUid: clearPendingOffer
          ? null
          : (pendingEnableOfferUid ?? this.pendingEnableOfferUid),
    );
  }
}

class BiometricLockNotifier extends Notifier<BiometricLockState> {
  String? _evaluatedUid;
  bool _passwordSignInPending = false;

  void beginPasswordSignIn() {
    _passwordSignInPending = true;
  }

  @override
  BiometricLockState build() {
    ref.listen(authProvider, (previous, next) {
      if (next.isLoading) return;
      if (next.hasError) {
        _passwordSignInPending = false;
        return;
      }
      final user = next.value;
      if (user == null) {
        _evaluatedUid = null;
        _passwordSignInPending = false;
        state = const BiometricLockState(status: BiometricLockStatus.unlocked);
        return;
      }
      if (_passwordSignInPending) {
        _passwordSignInPending = false;
        markUnlockedAfterPasswordSignIn(user.id);
        return;
      }
      if (_evaluatedUid != user.id) {
        _evaluatedUid = user.id;
        state = BiometricLockState(
          status: BiometricLockStatus.checking,
          activeUid: user.id,
        );
        _evaluateColdStart(user.id);
      }
    });

    final authState = ref.read(authProvider);
    if (authState.isLoading) {
      return const BiometricLockState(status: BiometricLockStatus.checking);
    }
    final user = authState.value;
    if (user == null) {
      return const BiometricLockState(status: BiometricLockStatus.unlocked);
    }
    if (_evaluatedUid != user.id) {
      _evaluatedUid = user.id;
      Future.microtask(() => _evaluateColdStart(user.id));
      return BiometricLockState(
        status: BiometricLockStatus.checking,
        activeUid: user.id,
      );
    }
    return state;
  }

  Future<void> _evaluateColdStart(String uid) async {
    final service = ref.read(biometricAuthServiceProvider);
    final available = await service.isBiometricAvailable();
    if (!available) {
      state = BiometricLockState(
        status: BiometricLockStatus.unlocked,
        activeUid: uid,
      );
      return;
    }

    final enabled = await service.isEnabledForUser(uid);
    if (_evaluatedUid != uid) return;

    state = BiometricLockState(
      status: enabled
          ? BiometricLockStatus.locked
          : BiometricLockStatus.unlocked,
      activeUid: uid,
    );
  }

  /// Called immediately after a successful email/password sign-in so the user
  /// is not gated by cold-start biometric lock, and schedules the one-time
  /// enable offer if eligible.
  Future<void> markUnlockedAfterPasswordSignIn(String uid) async {
    _evaluatedUid = uid;
    state = BiometricLockState(
      status: BiometricLockStatus.unlocked,
      activeUid: uid,
    );
    final shouldOffer = await shouldOfferEnableAfterLogin(uid);
    if (shouldOffer && _evaluatedUid == uid) {
      state = state.copyWith(pendingEnableOfferUid: uid);
    }
  }

  /// Unlocks an existing session, or enables biometric unlock on first tap
  /// from LoginScreen when biometric is not yet enabled for [uid].
  Future<bool> unlockOrEnableWithBiometrics(String uid) async {
    final ok = await unlockWithBiometrics();
    if (!ok) return false;
    final service = ref.read(biometricAuthServiceProvider);
    final alreadyEnabled = await service.isEnabledForUser(uid);
    if (!alreadyEnabled) {
      await service.setEnabledForUser(uid, true);
      await service.markOfferedForUser(uid);
      ref.invalidate(biometricEnabledProvider(uid));
    }
    state = state.copyWith(clearPendingOffer: true);
    return true;
  }

  /// Triggers device biometric prompt while on the lock screen.
  Future<bool> unlockWithBiometrics() async {
    if (state.isAuthenticating) return false;
    state = state.copyWith(isAuthenticating: true, clearError: true);

    final service = ref.read(biometricAuthServiceProvider);
    final result = await service.authenticate(
      localizedReason: 'Verify your fingerprint or face to unlock Mini-Mart POS',
    );

    if (result.isSuccess) {
      state = BiometricLockState(
        status: BiometricLockStatus.unlocked,
        activeUid: state.activeUid,
      );
      return true;
    }

    state = state.copyWith(
      isAuthenticating: false,
      errorMessage:
          result.message ?? 'Biometric verification failed. Try again or use password.',
    );
    return false;
  }

  /// Switches to the normal password login screen WITHOUT signing out the
  /// underlying Firebase/Laravel session. Deep links remain blocked until
  /// password login succeeds.
  void usePasswordInstead() {
    state = state.copyWith(
      status: BiometricLockStatus.bypassedToLogin,
      isAuthenticating: false,
      clearError: true,
    );
  }

  Future<void> setEnabledForUser(String uid, bool enabled) async {
    final service = ref.read(biometricAuthServiceProvider);
    await service.setEnabledForUser(uid, enabled);
    ref.invalidate(biometricEnabledProvider(uid));
  }

  Future<bool> shouldOfferEnableAfterLogin(String uid) async {
    final service = ref.read(biometricAuthServiceProvider);
    final available = await service.isBiometricAvailable();
    if (!available) return false;
    final enabled = await service.isEnabledForUser(uid);
    if (enabled) return false;
    final offered = await service.hasOfferedForUser(uid);
    return !offered;
  }

  Future<void> acceptEnableOffer(String uid) async {
    final service = ref.read(biometricAuthServiceProvider);
    await service.markOfferedForUser(uid);
    await service.setEnabledForUser(uid, true);
    ref.invalidate(biometricEnabledProvider(uid));
    state = state.copyWith(clearPendingOffer: true);
  }

  Future<void> dismissEnableOffer(String uid) async {
    final service = ref.read(biometricAuthServiceProvider);
    await service.markOfferedForUser(uid);
    state = state.copyWith(clearPendingOffer: true);
  }
}

final biometricLockProvider =
    NotifierProvider<BiometricLockNotifier, BiometricLockState>(
      BiometricLockNotifier.new,
    );
