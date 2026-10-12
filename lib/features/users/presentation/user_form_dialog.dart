import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  String? _errorMessage;

  bool get isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _passwordController = TextEditingController();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
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
      setState(() => _errorMessage = e.toString());
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

    final content = Container(
      constraints: const BoxConstraints(maxWidth: 480),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(isDesktop ? AppRadius.card : 20),
      ),
      child: Form(
        key: _formKey,
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
                'Temporary password *',
                style: AppTextStyles.bodyBold.copyWith(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'At least 8 characters',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) =>
                    !isEditing && (value == null || value.length < 8)
                    ? 'Use at least 8 characters'
                    : null,
              ),
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
                hintText: 'ឧ. នី បញ្ញា, គក់ ស្រីផ្កាយ...',
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
