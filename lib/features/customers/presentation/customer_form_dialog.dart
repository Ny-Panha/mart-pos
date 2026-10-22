import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/firestore/models/customer_model.dart';
import '../providers/customer_provider.dart';

class CustomerFormDialog extends ConsumerStatefulWidget {
  final CustomerModel? customer;
  final bool isBottomSheet;

  const CustomerFormDialog({
    super.key,
    this.customer,
    this.isBottomSheet = false,
  });

  static Future<void> show(BuildContext context, {CustomerModel? customer}) {
    final isDesktop = Responsive.isDesktop(context);
    if (isDesktop) {
      return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => CustomerFormDialog(customer: customer, isBottomSheet: false),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => CustomerFormDialog(customer: customer, isBottomSheet: true),
      );
    }
  }

  @override
  ConsumerState<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends ConsumerState<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _phoneController = TextEditingController(text: widget.customer?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.customer != null;

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final repo = ref.read(customerRepositoryProvider);

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        await repo.updateCustomer(
          widget.customer!.id,
          name: name,
          phone: phone.isNotEmpty ? phone : null,
        );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('បានកែប្រែព័ត៌មានអតិថិជន "$name" រួចរាល់!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        await repo.createCustomer(
          name: name,
          phone: phone.isNotEmpty ? phone : null,
        );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('បានបន្ថែមអតិថិជនថ្មី "$name" ជោគជ័យ!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final formContent = Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing ? 'កែប្រែព័ត៌មានអតិថិជន' : 'បន្ថែមអតិថិជនថ្មី',
                      style: AppTextStyles.titleLG,
                    ),
                    Text(
                      _isEditing ? 'Edit Customer Profile' : 'Register New Client',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'ឈ្មោះអតិថិជន (Client Name) *',
                hintText: 'e.g. សុខ ចាន់ដារា',
                isDense: true,
                prefixIcon: Icon(Icons.person_outline, size: 20),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter client name';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'លេខទូរស័ព្ទ (Phone Number - optional)',
                hintText: 'e.g. 012 345 678',
                isDense: true,
                prefixIcon: Icon(Icons.phone_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('បោះបង់ (Cancel)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: AppButton(
                    text: _isEditing ? 'រក្សាទុក (SAVE)' : '+ បញ្ចូល (ADD)',
                    isLoading: _isLoading,
                    onPressed: _handleSubmit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (widget.isBottomSheet) {
      return Material(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(child: formContent),
            ],
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        child: formContent,
      ),
    );
  }
}
