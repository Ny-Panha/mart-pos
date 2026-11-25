import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/biometric_provider.dart';

/// Reusable biometric unlock toggle for Settings (Admin) and My Shift (Cashier).
/// Automatically hides itself when the device/platform does not support biometrics.
class BiometricToggleTile extends ConsumerWidget {
  const BiometricToggleTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    if (user == null) return const SizedBox.shrink();

    final availableAsync = ref.watch(biometricAvailableProvider);
    final available = availableAsync.value ?? false;
    if (!available) return const SizedBox.shrink();

    final enabledAsync = ref.watch(biometricEnabledProvider(user.id));
    final isEnabled = enabledAsync.value ?? false;

    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      secondary: const Icon(
        Icons.fingerprint_rounded,
        color: AppColors.primary,
      ),
      title: const Text(
        'Biometric unlock (Fingerprint / Face)',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: const Text(
        'Require device biometrics when reopening the app',
        style: TextStyle(fontSize: 12),
      ),
      value: isEnabled,
      activeTrackColor: AppColors.primary,
      onChanged: enabledAsync.isLoading
          ? null
          : (value) {
              ref
                  .read(biometricLockProvider.notifier)
                  .setEnabledForUser(user.id, value);
            },
    );
  }
}
