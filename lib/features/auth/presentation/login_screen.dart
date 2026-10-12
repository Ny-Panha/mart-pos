import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/ios_theme_toggle.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController(
    text: 'admin@bbu.edu.kh',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: '12345678',
  );
  bool _obscurePassword = true;
  bool _rememberMe = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    setState(() => _errorMessage = null);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter email and password');
      return;
    }

    try {
      await ref
          .read(authProvider.notifier)
          .signIn(email: email, password: password);
      if (mounted) {
        context.go('/pos');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Sign in failed: ${e.toString()}');
    }
  }

  Future<void> _handleManagerBootstrap() async {
    setState(() => _errorMessage = null);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(
        () => _errorMessage =
            'Enter the allowlisted manager email and password first.',
      );
      return;
    }
    try {
      await ref
          .read(authProvider.notifier)
          .bootstrapFirstManager(
            email: email,
            password: password,
            name: email.split('@').first,
          );
      if (mounted) context.go('/manager');
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Manager setup failed: $error');
      }
    }
  }

  void _fillDemoUser(String email, String role) {
    _emailController.text = email;
    _passwordController.text = '12345678';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    final routerState = GoRouterState.of(context);
    final isDeactivated =
        routerState.uri.queryParameters['error'] == 'deactivated';
    final effectiveError =
        _errorMessage ??
        (isDeactivated
            ? 'គណនីត្រូវបានផ្អាកដំណើរការ — សូមទាក់ទង Admin (Account deactivated — please contact admin)'
            : null);

    final formContent = Container(
      constraints: const BoxConstraints(maxWidth: 480),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo, Title & Theme Toggle
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
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    Text(
                      'Build Bright University - Year 4',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark
                            ? AppColors.darkMutedText
                            : AppColors.lightMutedText,
                      ),
                    ),
                  ],
                ),
              ),
              IosThemeToggle(
                value: isDark,
                onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'សូមស្វាគមន៍មកកាន់ប្រព័ន្ធ',
            style: AppTextStyles.titleXL.copyWith(
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ចូលប្រើប្រាស់ដើម្បីគ្រប់គ្រងការលក់ និងស្តុកទំនិញ',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkMutedText
                  : AppColors.lightMutedText,
            ),
          ),
          const SizedBox(height: 28),

          if (effectiveError != null) ...[
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
                effectiveError,
                style: const TextStyle(color: AppColors.danger, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Email field
          const Text(
            'អ៊ីមែល ឬ ឈ្មោះគណនី (Email / Username)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.email_outlined, size: 20),
              hintText: 'admin@bbu.edu.kh',
            ),
          ),
          const SizedBox(height: 18),

          // Password field
          const Text(
            'ពាក្យសម្ងាត់ (Password)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              hintText: '••••••••',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Remember Me & Forgot Password
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _rememberMe,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _rememberMe = v ?? true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('ចងចាំគណនី', style: TextStyle(fontSize: 13)),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'ភ្លេចពាក្យសម្ងាត់?',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Sign In Button
          AppButton(
            text: 'ចូលប្រព័ន្ធ (SIGN IN)',
            isLoading: isLoading,
            onPressed: _handleSignIn,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: isLoading ? null : _handleManagerBootstrap,
            icon: const Icon(Icons.admin_panel_settings_outlined),
            label: const Text('Initialize first platform manager'),
          ),
          const SizedBox(height: 4),
          const Text(
            'Works only for the allowlisted UID, once, while no manager profile exists.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Quick Demo Users
          const Divider(),
          const SizedBox(height: 12),
          Text(
            'គណនីសាកល្បងសម្រាប់ការបង្ហាញ (Demo Roles):',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkMutedText
                  : AppColors.lightMutedText,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _fillDemoUser('admin@bbu.edu.kh', 'admin'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: const Text(
                    'Admin (បញ្ញា)',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      _fillDemoUser('cashier@bbu.edu.kh', 'cashier'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: const Text(
                    'Cashier (ស្រីផ្កាយ)',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // Branding panel for Tablet & Desktop
    final brandingPanel = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5300B7), Color(0xFF2E0854), Color(0xFF0F172A)],
        ),
      ),
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'MINI-MART POS v1.0',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ប្រព័ន្ធគ្រប់គ្រងការលក់\nមីនីម៉ាត និងស្តុកទំនិញ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'គម្រោងបញ្ចប់ការសិក្សាថ្នាក់បរិញ្ញាបត្រ វិទ្យាសាស្ត្រកុំព្យូទ័រ និងព័ត៌មានវិទ្យា\nសាកលវិទ្យាល័យ បៀលប្រាយ (Build Bright University - BBU) សាខាខេត្តបាត់ដំបង',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'សមាជិកក្រុមស្រាវជ្រាវ (Team Members):',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '១. នី បញ្ញា (Team Lead & Full-Stack Developer)\n'
                      '២. គក់ ស្រីផ្កាយ (UI/UX & Frontend Developer)\n'
                      '៣. គុយ ដាលី (Database & QA Engineer)',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Text(
            '© 2026 Mini-Mart POS. Offline-First Cloud Architecture.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );

    if (isDesktop || isTablet) {
      return Scaffold(
        body: Row(
          children: [
            Expanded(
              flex: 5,
              child: Center(child: SingleChildScrollView(child: formContent)),
            ),
            Expanded(flex: 6, child: brandingPanel),
          ],
        ),
      );
    }

    // Mobile layout
    return Scaffold(
      body: SafeArea(
        child: Center(child: SingleChildScrollView(child: formContent)),
      ),
    );
  }
}
