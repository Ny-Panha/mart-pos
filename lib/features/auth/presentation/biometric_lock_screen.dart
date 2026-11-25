import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/auth_provider.dart';
import '../providers/biometric_provider.dart';

/// Cold-start biometric lock gate screen.
/// Reuses LoginScreen visual style and AppColors. Back navigation is blocked
/// via [PopScope] so the lock screen cannot be bypassed.
class BiometricLockScreen extends ConsumerWidget {
  const BiometricLockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockState = ref.watch(biometricLockProvider);
    final authState = ref.watch(authProvider);
    final user = authState.value;

    final themeMode = ref.watch(themeModeProvider);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);

    final isChecking = lockState.status == BiometricLockStatus.checking;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 36,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App Logo matching LoginScreen
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Text(
                              'M',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MINI-MART POS',
                                style: AppTextStyles.titleLG.copyWith(
                                  letterSpacing: 0.8,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.darkText
                                      : AppColors.lightText,
                                ),
                              ),
                              Text(
                                user?.email ?? user?.name ?? 'Locked Session',
                                style: AppTextStyles.caption.copyWith(
                                  color: isDark
                                      ? AppColors.darkMutedText
                                      : AppColors.lightMutedText,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    if (isChecking) ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ] else ...[
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.fingerprint_rounded,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'ផ្ទៀងផ្ទាត់អត្តសញ្ញាណ (Unlock App)',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleXL.copyWith(
                          color: isDark
                              ? AppColors.darkText
                              : AppColors.lightText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'សូមប្រើម្រាមដៃ ឬ ផ្ទៃមុខ ដើម្បីចូលប្រើប្រាស់បន្ត',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkMutedText
                              : AppColors.lightMutedText,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (lockState.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            lockState.errorMessage!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      AppButton(
                        text: 'Unlock with fingerprint / face',
                        icon: Icons.fingerprint_rounded,
                        isLoading: lockState.isAuthenticating,
                        onPressed: () {
                          ref
                              .read(biometricLockProvider.notifier)
                              .unlockWithBiometrics();
                        },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: lockState.isAuthenticating
                            ? null
                            : () {
                                ref
                                    .read(biometricLockProvider.notifier)
                                    .usePasswordInstead();
                              },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: const Text('Use password instead'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
