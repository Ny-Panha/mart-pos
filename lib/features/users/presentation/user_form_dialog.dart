import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/firestore/models/user_model.dart';
import '../providers/user_provider.dart';

class UserFormDialog extends ConsumerStatefulWidget {
  final UserModel? user; // null when creating new user

  const UserFormDialog({super.key, this.user});

  static Future<void> show(BuildContext context, {UserModel? user}) {
    if (Responsive.isDesktop(context) || Responsive.isTablet(context)) {
      return showDialog<void>(
        context: context,
        builder: (_) => UserFormDialog(user: user),
      );
    } else {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => UserFormDialog(user: user),
      );
    }
  }

  @override
  ConsumerState<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _nameController;
  final String _role = UserModel.cashierRole;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  bool get isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _passwordController = TextEditingController();
    _passwordController.addListener(() => setState(() {}));
    _nameController = TextEditingController(text: widget.user?.name ?? '');
  }

  int _calculateStrength(String pwd) {
    if (pwd.isEmpty) return 0;
    int score = 0;
    if (pwd.length >= 8) score++;
    if (RegExp(r'[A-Za-z]').hasMatch(pwd)) score++;
    if (RegExp(r'[0-9]').hasMatch(pwd)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(pwd) || pwd.length >= 12) score++;
    return score;
  }

  Widget _buildRequirementCheck({
    required String label,
    required bool isMet,
    required bool isDark,
  }) {
    final color = isMet
        ? AppColors.success
        : (isDark ? AppColors.darkMutedText : AppColors.lightMutedText);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 13,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(userRepositoryProvider);
      if (isEditing) {
        final targetUid = widget.user!.id;
        await repo.updateUserName(targetUid, _nameController.text.trim());
      } else {
        await repo.createUserDoc(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          role: _role,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'បានកែប្រែគណនីជោគជ័យ (User updated successfully)'
                  : 'បានបង្កើតគណនីជោគជ័យ (User profile created)',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      String message = e.toString();
      if (e is FirebaseFunctionsException) {
        if (e.code == 'already-exists') {
          message = 'Email នេះត្រូវបានចុះឈ្មោះរួចហើយ (Email already registered).';
        } else if (e.code == 'permission-denied') {
          message = 'គ្មានសិទ្ធិបង្កើតគណនីបុគ្គលិកទេ (Permission denied).';
        } else if (e.code == 'invalid-argument') {
          message = 'ព័ត៌មានមិនត្រឹមត្រូវ: ${e.message ?? e.toString()}';
        } else if (e.code == 'internal') {
          message = e.message ?? 'Cloud Functions មិនទាន់ដំណើរការ ឬមិនទាន់ Deploy ទៅកាន់ Firebase [internal 0]';
        } else {
          message = e.message ?? e.toString();
        }
      } else if (e is FirebaseAuthException) {
        if (e.code == 'email-already-in-use') {
          message = 'Email នេះត្រូវបានចុះឈ្មោះរួចហើយ (Email already registered).';
        } else if (e.code == 'weak-password') {
          message = 'ពាក្យសម្ងាត់ខ្សោយពេក (Password is too weak).';
        } else {
          message = e.message ?? e.toString();
        }
      }
      setState(() => _errorMessage = message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = Responsive.isDesktop(context);

    final content = Material(
      color: isDark ? AppColors.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(isDesktop ? AppRadius.card : 20),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24),
        child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isEditing
                        ? Icons.manage_accounts_rounded
                        : Icons.person_add_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing
                            ? 'កែប្រែបុគ្គលិក (Edit Staff)'
                            : 'បន្ថែមបុគ្គលិកថ្មី (Create Cashier Account)',
                        style: AppTextStyles.titleLG,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isEditing
                            ? 'Manage staff role and details'
                            : 'Create a sign-in account for this shop cashier',
                        style: AppTextStyles.caption.copyWith(
                          color: isDark
                              ? AppColors.darkMutedText
                              : AppColors.lightMutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (!isEditing) ...[
              Text(
                'Email *',
                style: AppTextStyles.bodyBold.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'cashier@example.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) =>
                    value == null || !value.trim().contains('@')
                    ? 'Enter a valid email address'
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                'ពាក្យសម្ងាត់បណ្តោះអាសន្ន (Temporary password) *',
                style: AppTextStyles.bodyBold.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final obscure = _obscurePassword != false;
                  return TextFormField(
                    controller: _passwordController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      hintText: 'យ៉ាងហោច 8 តួអក្សរ (At least 8 characters)',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !obscure),
                      ),
                    ),
                    validator: (value) =>
                        !isEditing && (value == null || value.length < 8)
                        ? 'សូមប្រើប្រាស់យ៉ាងតិច 8 តួអក្សរ (At least 8 characters)'
                        : null,
                  );
                },
              ),
              if (!isEditing && _passwordController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Builder(
                  builder: (_) {
                    final pwd = _passwordController.text;
                    final strength = _calculateStrength(pwd);
                    Color barColor = AppColors.danger;
                    String label = 'ខ្សោយ (Weak)';
                    if (strength == 2) {
                      barColor = Colors.orange;
                      label = 'មធ្យម (Fair)';
                    } else if (strength == 3) {
                      barColor = Colors.blue;
                      label = 'ល្អ (Good)';
                    } else if (strength >= 4) {
                      barColor = AppColors.success;
                      label = 'រឹងមាំ (Strong)';
                    }

                    return Row(
                      children: [
                        for (int i = 1; i <= 4; i++) ...[
                          if (i > 1) const SizedBox(width: 4),
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: strength >= i
                                    ? barColor
                                    : (isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 10),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: barColor,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
              if (!isEditing) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _buildRequirementCheck(
                      label: '≥ 8 តួអក្សរ (8+ chars)',
                      isMet: _passwordController.text.length >= 8,
                      isDark: isDark,
                    ),
                    _buildRequirementCheck(
                      label: 'មានអក្សរ (Letters)',
                      isMet:
                          RegExp(r'[A-Za-z]').hasMatch(_passwordController.text),
                      isDark: isDark,
                    ),
                    _buildRequirementCheck(
                      label: 'មានលេខ (Numbers)',
                      isMet: RegExp(r'[0-9]').hasMatch(_passwordController.text),
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
            ],

            // Staff Name field
            Text(
              'ឈ្មោះបុគ្គលិក (Staff Name) *',
              style: AppTextStyles.bodyBold.copyWith(
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'ឧ. នី បញ្ញា, ផ្កាយ...',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter staff name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            if (!isEditing)
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.point_of_sale_rounded,
                  color: AppColors.secondary,
                ),
                title: Text('Role'),
                subtitle: Text('Cashier'),
              ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    child: const Text('បោះបង់ (Cancel)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: AppButton(
                    text: isEditing ? 'រក្សាទុក (SAVE)' : 'បង្កើតគណនី (CREATE)',
                    icon: Icons.check_circle_outline_rounded,
                    isLoading: _isLoading,
                    onPressed: _handleSave,
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
      ),
    );

    if (isDesktop || Responsive.isTablet(context)) {
      return Dialog(backgroundColor: Colors.transparent, child: content);
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: content,
    );
  }
}
