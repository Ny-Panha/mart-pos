import 'package:mart_pos/core/motion/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/firestore/models/supplier_model.dart';
import '../../products/providers/category_provider.dart';
import '../../products/providers/product_provider.dart';
import '../providers/supplier_provider.dart';

class SupplierFormDialog extends ConsumerStatefulWidget {
  final SupplierModel? supplier;

  const SupplierFormDialog({super.key, this.supplier});

  static Future<void> show(BuildContext context, {SupplierModel? supplier}) {
    if (Responsive.isDesktop(context) || Responsive.isTablet(context)) {
      return showMotionDialog<void>(
        context: context,
        builder: (_) => SupplierFormDialog(supplier: supplier),
      );
    } else {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => SupplierFormDialog(supplier: supplier),
      );
    }
  }

  @override
  ConsumerState<SupplierFormDialog> createState() => _SupplierFormDialogState();
}

class _SupplierFormDialogState extends ConsumerState<SupplierFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _noteController;
  late final Set<String> _selectedProductIds;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isEditing => widget.supplier != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supplier?.name ?? '');
    _phoneController = TextEditingController(text: widget.supplier?.phone ?? '');
    _addressController = TextEditingController(text: widget.supplier?.address ?? '');
    _noteController = TextEditingController(text: widget.supplier?.note ?? '');
    _selectedProductIds = Set<String>.from(widget.supplier?.productIds ?? const []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(supplierRepositoryProvider);
      if (isEditing) {
        await repo.updateSupplier(
          id: widget.supplier!.id,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          note: _noteController.text.trim(),
          productIds: _selectedProductIds.toList(),
        );
      } else {
        await repo.createSupplier(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          note: _noteController.text.trim(),
          productIds: _selectedProductIds.toList(),
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'បានកែប្រែអ្នកផ្គត់ផ្គង់ដោយជោគជ័យ' : 'បានបន្ថែមអ្នកផ្គត់ផ្គង់ដោយជោគជ័យ',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = Responsive.isDesktop(context) || Responsive.isTablet(context);

    final formContent = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'កែប្រែអ្នកផ្គត់ផ្គង់ (Edit Supplier)' : 'បន្ថែមអ្នកផ្គត់ផ្គង់ថ្មី (New Supplier)',
                      style: AppTextStyles.titleLG.copyWith(
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ព័ត៌មានលម្អិតរបស់អ្នកផ្គត់ផ្គង់សម្រាប់បញ្ជាទិញទំនិញចូលស្តុក',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Error banner
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.danger, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Supplier Name
          Text(
            'ឈ្មោះអ្នកផ្គត់ផ្គង់ / ក្រុមហ៊ុន (Supplier Name) *',
            style: AppTextStyles.bodyBold,
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'ឧ. ក្រុមហ៊ុន ខេមបូឌា ប៊ីវេរេជ',
              prefixIcon: Icon(Icons.storefront_outlined),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'សូមបញ្ចូលឈ្មោះអ្នកផ្គត់ផ្គង់';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Phone
          Text(
            'លេខទូរស័ព្ទ (Phone Number)',
            style: AppTextStyles.bodyBold,
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: 'ឧ. 012 345 678',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // Address
          Text(
            'អាសយដ្ឋាន (Address)',
            style: AppTextStyles.bodyBold,
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              hintText: 'ឧ. ក្រុងបាត់ដំបង ខេត្តបាត់ដំបង',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // Supplied Products
          Text(
            'ទំនិញដែលផ្គត់ផ្គង់ (Supplied Products)',
            style: AppTextStyles.bodyBold,
          ),
          const SizedBox(height: 6),
          Consumer(
            builder: (context, ref, _) {
              final products = ref.watch(productsStreamProvider).value ?? const [];
              if (products.isEmpty) {
                return const Text(
                  'មិនទាន់មានទំនិញក្នុងប្រព័ន្ធទេ',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                );
              }
              final selectedProducts = products.where((p) => _selectedProductIds.contains(p.id)).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: () => _openProductsPicker(products),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBg : AppColors.lightBg,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 20,
                            color: selectedProducts.isNotEmpty
                                ? AppColors.primary
                                : (isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              selectedProducts.isEmpty
                                  ? 'ជ្រើសរើសទំនិញ... (Select Products)'
                                  : 'បានជ្រើសរើស ${selectedProducts.length} មុខ (${selectedProducts.length} selected)',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: selectedProducts.isEmpty ? FontWeight.normal : FontWeight.w600,
                                color: selectedProducts.isEmpty
                                    ? (isDark ? AppColors.darkMutedText : AppColors.lightMutedText)
                                    : (isDark ? AppColors.darkText : AppColors.lightText),
                              ),
                            ),
                          ),
                          const Icon(Icons.search_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                  if (selectedProducts.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: selectedProducts.map((p) {
                        return Chip(
                          label: Text(p.name, style: const TextStyle(fontSize: 11.5)),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () => setState(() => _selectedProductIds.remove(p.id)),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Note
          Text(
            'កំណត់ចំណាំ (Note)',
            style: AppTextStyles.bodyBold,
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _noteController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'ព័ត៌មានបន្ថែម ឬលក្ខខណ្ឌទូទាត់...',
              prefixIcon: Icon(Icons.note_alt_outlined),
            ),
          ),
          const SizedBox(height: 24),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(80, 44),
                ),
                child: const Text('បោះបង់'),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 130,
                child: AppButton(
                  text: isEditing ? 'រក្សាទុក' : 'បន្ថែម',
                  isLoading: _isLoading,
                  onPressed: _handleSave,
                  icon: isEditing ? Icons.check : Icons.add,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (isDesktop) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(child: formContent),
        ),
      );
    } else {
      return SafeArea(
        bottom: false,
        child: Material(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom +
                  MediaQuery.of(context).padding.bottom +
                  20,
            ),
            child: SingleChildScrollView(child: formContent),
          ),
        ),
      );
    }
  }

  Future<void> _openProductsPicker(List<dynamic> products) async {
    final tempSelected = Set<String>.from(_selectedProductIds);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = ref.read(categoriesStreamProvider).value ?? const [];
    final categoryNames = <String, String>{
      for (final c in categories) c.id: c.name,
    };
    String query = '';
    String selectedCategoryId = 'all';

    final confirmed = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final q = query.trim().toLowerCase();
            final filtered = products.where((p) {
              final catId = (p.categoryId as String?) ?? '';
              final matchesCategory =
                  selectedCategoryId == 'all' || catId == selectedCategoryId;
              if (!matchesCategory) return false;
              if (q.isEmpty) return true;
              final name = (p.name as String).toLowerCase();
              final code = (p.code as String?)?.toLowerCase() ?? '';
              final barcode = (p.barcode as String?)?.toLowerCase() ?? '';
              final catName = (categoryNames[catId] ?? '').toLowerCase();
              return name.contains(q) ||
                  code.contains(q) ||
                  barcode.contains(q) ||
                  catName.contains(q);
            }).toList();

            return SafeArea(
              bottom: false,
              child: Material(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  height: MediaQuery.of(ctx).size.height * 0.72,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                        child: Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'ជ្រើសរើសទំនិញផ្គត់ផ្គង់ (${tempSelected.length})',
                                style: AppTextStyles.titleLG.copyWith(
                                  color: isDark ? AppColors.darkText : AppColors.lightText,
                                ),
                              ),
                            ),
                            if (tempSelected.isNotEmpty)
                              TextButton(
                                onPressed: () => setSheetState(() => tempSelected.clear()),
                                child: const Text('សម្អាត'),
                              ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(sheetCtx).pop(),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          autofocus: false,
                          decoration: InputDecoration(
                            hintText: 'ស្វែងរកឈ្មោះទំនិញ ឬបារកូដ...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            suffixIcon: query.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () => setSheetState(() => query = ''),
                                  )
                                : null,
                            isDense: true,
                          ),
                          onChanged: (v) => setSheetState(() => query = v),
                        ),
                      ),
                      if (categories.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 36,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: const Text('ទាំងអស់ (All)', style: TextStyle(fontSize: 12)),
                                  selected: selectedCategoryId == 'all',
                                  onSelected: (_) => setSheetState(() => selectedCategoryId = 'all'),
                                ),
                              ),
                              for (final cat in categories)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(cat.name, style: const TextStyle(fontSize: 12)),
                                    selected: selectedCategoryId == cat.id,
                                    onSelected: (_) => setSheetState(() => selectedCategoryId = cat.id),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(
                                child: Text(
                                  'រកមិនឃើញទំនិញទេ',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (_, idx) {
                                  final p = filtered[idx];
                                  final checked = tempSelected.contains(p.id);
                                  final code = (p.code as String?) ?? '';
                                  final catName = categoryNames[(p.categoryId as String?) ?? ''] ?? '';
                                  final subtitleText = [
                                    if (code.isNotEmpty) code,
                                    if (catName.isNotEmpty) catName,
                                  ].join(' • ');
                                  return CheckboxListTile(
                                    value: checked,
                                    dense: true,
                                    activeColor: AppColors.primary,
                                    title: Text(
                                      p.name as String,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                                    ),
                                    subtitle: subtitleText.isNotEmpty
                                        ? Text(subtitleText, style: const TextStyle(fontSize: 11.5))
                                        : null,
                                    onChanged: (val) {
                                      setSheetState(() {
                                        if (val == true) {
                                          tempSelected.add(p.id as String);
                                        } else {
                                          tempSelected.remove(p.id as String);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          MediaQuery.of(ctx).padding.bottom + 12,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            text: 'រួចរាល់ (Done - ${tempSelected.length})',
                            icon: Icons.check,
                            onPressed: () => Navigator.of(sheetCtx).pop(tempSelected),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed != null && mounted) {
      setState(() {
        _selectedProductIds
          ..clear()
          ..addAll(confirmed);
      });
    }
  }
}
