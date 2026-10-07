import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/firestore/models/product_model.dart';
import '../providers/category_provider.dart';
import '../providers/product_provider.dart';

class ProductFormDialog extends ConsumerStatefulWidget {
  final ProductModel? product;
  final bool isBottomSheet;

  const ProductFormDialog({
    super.key,
    this.product,
    this.isBottomSheet = false,
  });

  static Future<void> show(BuildContext context, {ProductModel? product}) {
    final isDesktop = Responsive.isDesktop(context);
    if (isDesktop) {
      return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => ProductFormDialog(product: product, isBottomSheet: false),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => ProductFormDialog(product: product, isBottomSheet: true),
      );
    }
  }

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _barcodeController;
  late TextEditingController _skuController;
  late TextEditingController _costPriceController;
  late TextEditingController _salePriceController;
  late TextEditingController _stockQtyController;
  late TextEditingController _lowStockThresholdController;

  String? _selectedCategoryId;
  String _selectedUnit = 'កំប៉ុង';
  double _selectedTax = 0.0;
  bool _isActive = true;

  bool _isLoading = false;
  String? _codeError;

  final List<String> _commonUnits = [
    'កំប៉ុង',
    'ដប',
    'កញ្ចប់',
    'ប្រអប់',
    'គីឡូ',
    'ដុំ',
    'កេស',
    'កែវ',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _codeController = TextEditingController(text: p?.code ?? '');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _costPriceController = TextEditingController(text: p != null ? '${p.costPrice}' : '0');
    _salePriceController = TextEditingController(text: p != null ? '${p.salePrice}' : '');
    _stockQtyController = TextEditingController(text: p != null ? '${p.stockQty}' : '0');
    _lowStockThresholdController = TextEditingController(text: p != null ? '${p.lowStockThreshold}' : '5');

    _selectedCategoryId = p?.categoryId;
    _selectedUnit = p?.unit ?? 'កំប៉ុង';
    _selectedTax = p?.tax ?? 0.0;
    _isActive = p?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _barcodeController.dispose();
    _skuController.dispose();
    _costPriceController.dispose();
    _salePriceController.dispose();
    _stockQtyController.dispose();
    _lowStockThresholdController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.product != null;

  Future<void> _handleSubmit() async {
    setState(() => _codeError = null);

    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('សូមជ្រើសរើសប្រភេទទំនិញ (Please select a category)'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final code = _codeController.text.trim().toUpperCase();
    final repo = ref.read(productRepositoryProvider);

    setState(() => _isLoading = true);

    try {
      // 1. Check code uniqueness
      final isTaken = await repo.isProductCodeTaken(
        code,
        excludeProductId: widget.product?.id,
      );

      if (isTaken) {
        setState(() {
          _codeError = 'លេខកូដ "$code" ត្រូវបានប្រើប្រាស់រួចហើយ (Code already used)';
          _isLoading = false;
        });
        return;
      }

      // 2. Parse numbers
      final costPrice = int.tryParse(_costPriceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final salePrice = int.tryParse(_salePriceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final stockQty = int.tryParse(_stockQtyController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final lowStock = int.tryParse(_lowStockThresholdController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 5;

      if (_isEditing) {
        // Update product
        final updated = widget.product!.copyWith(
          name: _nameController.text.trim(),
          code: code,
          barcode: _barcodeController.text.trim(),
          sku: _skuController.text.trim(),
          categoryId: _selectedCategoryId!,
          costPrice: costPrice,
          salePrice: salePrice,
          stockQty: stockQty,
          unit: _selectedUnit,
          lowStockThreshold: lowStock,
          tax: _selectedTax,
          status: _isActive ? 'active' : 'inactive',
          updatedAt: DateTime.now(),
        );

        await repo.updateProduct(updated, oldCode: widget.product!.code);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('បានកែប្រែ "${updated.name}" រួចរាល់!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        // Create new product
        final newId = const Uuid().v4();
        final newProduct = ProductModel(
          id: newId,
          name: _nameController.text.trim(),
          code: code,
          barcode: _barcodeController.text.trim(),
          sku: _skuController.text.trim(),
          categoryId: _selectedCategoryId!,
          costPrice: costPrice,
          salePrice: salePrice,
          stockQty: stockQty,
          unit: _selectedUnit,
          lowStockThreshold: lowStock,
          tax: _selectedTax,
          status: _isActive ? 'active' : 'inactive',
          updatedAt: DateTime.now(),
        );

        await repo.createProduct(newProduct);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('បានបង្កើតទំនិញថ្មី "${newProduct.name}" រួចរាល់!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('បរាជ័យ (Failed): $e'), backgroundColor: AppColors.danger),
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
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    final formContent = Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing ? 'កែប្រែទំនិញ (Edit Product)' : 'បន្ថែមទំនិញថ្មី (New Product)',
                      style: AppTextStyles.titleLG,
                    ),
                    Text(
                      _isEditing ? 'Update retail info, stock and code' : 'Fill details below to register product',
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

            // 1. Basic Info Section
            const Text('ព័ត៌មានទូទៅ (Basic Info)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
            const SizedBox(height: 10),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'ឈ្មោះទំនិញ (Product Name) *',
                hintText: 'e.g. Coca Cola 330ml',
                isDense: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'សូមបញ្ចូលឈ្មោះទំនិញ (Name is required)';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Code & Category Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'លេខកូដទំនិញ (Code) *',
                      hintText: 'e.g. PROD-009',
                      isDense: true,
                      errorText: _codeError,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Code is required';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: categoriesAsync.when(
                    data: (categories) {
                      // Validate if selected category exists
                      final exists = categories.any((c) => c.id == _selectedCategoryId);
                      final currentValue = exists ? _selectedCategoryId : (categories.isNotEmpty ? categories.first.id : null);

                      return DropdownButtonFormField<String>(
                        initialValue: currentValue,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'ប្រភេទទំនិញ (Category) *',
                          isDense: true,
                        ),
                        items: categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat.id,
                            child: Text(cat.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedCategoryId = val);
                        },
                        validator: (v) => v == null ? 'Category is required' : null,
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (_, _) => const Text('Error loading categories'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Barcode & SKU Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _barcodeController,
                    decoration: const InputDecoration(
                      labelText: 'បារកូដ (Barcode)',
                      hintText: 'e.g. 884000109',
                      isDense: true,
                      prefixIcon: Icon(Icons.qr_code, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextFormField(
                    controller: _skuController,
                    decoration: const InputDecoration(
                      labelText: 'SKU / Batch Ref',
                      hintText: 'e.g. COCA-330',
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 2. Pricing & Financials Section
            const Text('តម្លៃ និងពន្ធ (Pricing & Tax)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
            const SizedBox(height: 10),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cost Price
                Expanded(
                  child: TextFormField(
                    controller: _costPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'តម្លៃដើម (Cost Price)',
                      suffixText: '៛',
                      isDense: true,
                    ),
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        final val = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
                        if (val == null || val < 0) return 'Invalid amount';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 14),
                // Sale Price
                Expanded(
                  child: TextFormField(
                    controller: _salePriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'តម្លៃលក់ (Sale Price) *',
                      suffixText: '៛',
                      isDense: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Sale price is required';
                      final val = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
                      if (val == null || val <= 0) return 'Must be > 0៛';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Tax Rate Dropdown
            DropdownButtonFormField<double>(
              initialValue: _selectedTax,
              decoration: const InputDecoration(
                labelText: 'អត្រាពន្ធ (Tax / VAT Rate)',
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 0.0, child: Text('0% - គ្មានពន្ធ (No Tax)')),
                DropdownMenuItem(value: 0.05, child: Text('5% - ពន្ធសេវា (Service Tax)')),
                DropdownMenuItem(value: 0.10, child: Text('10% - អាករលើតម្លៃបន្ថែម (VAT)')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedTax = val);
              },
            ),
            const SizedBox(height: 20),

            // 3. Inventory & Units Section
            const Text('ស្តុក និងខ្នាត (Inventory & Units)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
            const SizedBox(height: 10),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stock Qty
                Expanded(
                  child: TextFormField(
                    controller: _stockQtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ចំនួនក្នុងស្តុក (Stock Qty)',
                      isDense: true,
                    ),
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        final val = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
                        if (val == null || val < 0) return 'Invalid qty';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 14),
                // Unit Dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _commonUnits.contains(_selectedUnit) ? _selectedUnit : _commonUnits.first,
                    decoration: const InputDecoration(
                      labelText: 'ខ្នាត (Unit)',
                      isDense: true,
                    ),
                    items: _commonUnits.map((u) {
                      return DropdownMenuItem(value: u, child: Text(u));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedUnit = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                // Low Stock Threshold
                Expanded(
                  child: TextFormField(
                    controller: _lowStockThresholdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'កម្រិតប្រកាសអាសន្ន (Low Stock Alert)',
                      hintText: 'default 5',
                      isDense: true,
                    ),
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        final val = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
                        if (val == null || val < 0) return 'Invalid threshold';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 14),
                // Status Active Switch
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isActive ? 'សកម្ម (Active)' : 'អសកម្ម (Inactive)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _isActive ? AppColors.success : Colors.grey,
                          ),
                        ),
                        Switch(
                          value: _isActive,
                          activeThumbColor: AppColors.success,
                          onChanged: (val) => setState(() => _isActive = val),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Actions (Cancel / Save)
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
                    text: _isEditing ? 'រក្សាទុកការកែប្រែ (SAVE)' : '+ បង្កើតទំនិញ (CREATE)',
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
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: formContent,
      ),
    );
  }
}
