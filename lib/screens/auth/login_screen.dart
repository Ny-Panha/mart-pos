import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/mart_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController(text: 'admin@bbu.edu.kh');
  final TextEditingController _passwordController = TextEditingController(text: '12345678');
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));

    if (email.contains('pkay') || email.contains('cashier')) {
      auth.switchDemoUser(name: 'គក់ ស្រីផ្កាយ', role: 'CASHIER', email: email);
    } else if (email.contains('daly')) {
      auth.switchDemoUser(name: 'គុយ ដាលី', role: 'CASHIER', email: email);
    } else {
      auth.switchDemoUser(name: 'នី បញ្ញា', role: 'ADMIN', email: email);
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF6E5),
              Colors.white,
              Color(0xFFE5F5F3),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 960),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 700;

                    return Row(
                      children: [
                        // Left Column: Form
                        Expanded(
                          flex: isWide ? 6 : 12,
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Top Logo on Mobile
                                if (!isWide)
                                  const Center(
                                    child: MartLogo(size: 64),
                                  ),
                                if (!isWide) const SizedBox(height: 16),

                                const Text(
                                  'សូមស្វាគមន៍ / Welcome Back',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'ចូលប្រើប្រាស់ប្រព័ន្ធគ្រប់គ្រងការលក់នៅម៉ាត (Mart POS)',
                                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 28),

                                // Email Input
                                const Text('អ៊ីមែល ឬ ឈ្មោះគណនី (Email/Username) *',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                                    hintText: 'name@email.com or username',
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // Password Input
                                const Text('ពាក្យសម្ងាត់ (Password) *',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                    hintText: '••••••••',
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Remember Me & Forgot Password
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: _rememberMe,
                                          activeColor: AppColors.primary,
                                          onChanged: (val) => setState(() => _rememberMe = val ?? false),
                                        ),
                                        const Text('ចងចាំខ្ញុំ (Remember)', style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('សូមទាក់ទង Admin ដើម្បី Reset Password')),
                                        );
                                      },
                                      child: const Text('ភ្លេចលេខសម្ងាត់?', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Submit Button
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F172A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    elevation: 2,
                                  ),
                                  onPressed: _isLoading ? null : _handleSignIn,
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Text(
                                          'ចូលប្រព័ន្ធ (Sign In)',
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                        ),
                                ),
                                const SizedBox(height: 24),

                                // Quick Demo Accounts
                                const Text('គណនីគំរូសម្រាប់ Demo ជូនគ្រូ (Quick Login):',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    ActionChip(
                                      avatar: const Icon(Icons.admin_panel_settings, size: 16, color: AppColors.cyan),
                                      label: const Text('Admin (នី បញ្ញា)'),
                                      onPressed: () {
                                        setState(() {
                                          _emailController.text = 'admin@bbu.edu.kh';
                                          _passwordController.text = '12345678';
                                        });
                                      },
                                    ),
                                    ActionChip(
                                      avatar: const Icon(Icons.person, size: 16, color: AppColors.amber),
                                      label: const Text('Cashier (គក់ ស្រីផ្កាយ)'),
                                      onPressed: () {
                                        setState(() {
                                          _emailController.text = 'pkay@bbu.edu.kh';
                                          _passwordController.text = '12345678';
                                        });
                                      },
                                    ),
                                    ActionChip(
                                      avatar: const Icon(Icons.person, size: 16, color: Colors.teal),
                                      label: const Text('Cashier (គុយ ដាលី)'),
                                      onPressed: () {
                                        setState(() {
                                          _emailController.text = 'daly@bbu.edu.kh';
                                          _passwordController.text = '12345678';
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Right Column: Artwork & Mart POS Branding
                        if (isWide)
                          Expanded(
                            flex: 5,
                            child: Container(
                              height: 600,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                border: Border(left: BorderSide(color: Colors.grey.shade200)),
                              ),
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const MartLogo(size: 96),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'Mart POS',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'ប្រព័ន្ធគ្រប់គ្រងការលក់នៅម៉ាត',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Build Bright University • Battambang\nYear 4, Semester 2',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 22),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Team: Daly • Sreyphkay • Panha',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
