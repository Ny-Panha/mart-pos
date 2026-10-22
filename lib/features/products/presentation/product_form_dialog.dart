import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/product_thumbnail.dart';
import '../../../data/firestore/models/product_model.dart';
import '../../../data/services/audit_service.dart';
import '../../../data/services/storage_service.dart';
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

  late final TextEditingController _nameController =
      TextEditingController(text: widget.product?.name ?? '');
  late final TextEditingController _codeController =
      TextEditingController(text: widget.product?.code ?? '');
  late final TextEditingController _barcodeController =
      TextEditingController(text: widget.product?.barcode ?? '');
  late final TextEditingController _skuController =
      TextEditingController(text: widget.product?.sku ?? '');
  late final TextEditingController _costPriceController = TextEditingController(
      text: widget.product != null ? '${widget.product!.costPrice}' : '0');
  late final TextEditingController _salePriceController = TextEditingController(
      text: widget.product != null ? '${widget.product!.salePrice}' : '');
  late final TextEditingController _stockQtyController = TextEditingController(
      text: widget.product != null ? '${widget.product!.stockQty}' : '0');
  late final TextEditingController _lowStockThresholdController =
      TextEditingController(
          text: widget.product != null
              ? '${widget.product!.lowStockThreshold}'
              : '5');
  late final TextEditingController _imageUrlController =
      TextEditingController(text: widget.product?.imageUrl ?? '');
  late final TextEditingController _taxController = TextEditingController(
      text: widget.product != null
          ? ((widget.product!.tax > 0)
              ? (widget.product!.tax < 1.0
                  ? ((widget.product!.tax * 100) % 1 == 0
                      ? (widget.product!.tax * 100).toInt().toString()
                      : (widget.product!.tax * 100).toString())
                  : (widget.product!.tax % 1 == 0
                      ? widget.product!.tax.toInt().toString()
                      : widget.product!.tax.toString()))
              : '0')
          : '0');

  String? _selectedCategoryId;
  String _selectedUnit = 'កំប៉ុង';
  bool _isActive = true;

  bool _isLoading = false;
  bool _isUploadingImage = false;
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
    _selectedCategoryId = p?.categoryId;
    _selectedUnit = p?.unit ?? 'កំប៉ុង';
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
    _imageUrlController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.product != null;

  Future<void> _handlePickAndUploadImage() async {
    try {
      final file = await StorageService.pickProductImage();
      if (file == null) return; // User cancelled picker

      setState(() {
        _isUploadingImage = true;
      });

      final code = _codeController.text.trim();
      final customName = code.isNotEmpty
          ? 'prod_${code.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')}_${DateTime.now().millisecondsSinceEpoch}'
          : null;

      final downloadUrl = await StorageService.uploadProductImage(
        file: file,
        customName: customName,
      );

      if (mounted) {
        setState(() {
          _imageUrlController.text = downloadUrl;
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('បាន Upload រូបភាពទៅ Firebase Storage ជោគជ័យ!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('មិនអាច Upload រូបភាពបានទេ: $e'),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _openBarcodeScanner() {
    final isDesktop = Responsive.isDesktop(context);

    Widget scannerBody(BuildContext ctx) {
      return SizedBox(
        width: isDesktop ? 480 : double.infinity,
        height: isDesktop ? 420 : MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'ស្កេនបារកូដទំនិញ (Scan Barcode)',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'បិទ',
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isDesktop ? 16 : 0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    MobileScanner(
                      onDetect: (capture) {
                        final barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                          final scanned = barcodes.first.rawValue!.trim();
                          if (scanned.isNotEmpty) {
                            Navigator.pop(ctx);
                            setState(() {
                              _barcodeController.text = scanned;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('បានស្កេនបារកូដជោគជ័យ: $scanned'),
                                backgroundColor: AppColors.success,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                    ),
                    Container(
                      width: 250,
                      height: 140,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary, width: 2.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'ដាក់កាមេរ៉ាតម្រង់លើបារកូដទំនិញ',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: scannerBody(ctx),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.black,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => scannerBody(ctx),
      );
    }
  }

  Future<void> _handleSubmit() async {
    setState(() => _codeError = null);

    if (!_formKey.currentState!.validate()) return;
    final categories = ref.read(categoriesStreamProvider).value ?? [];
    final categoryIdToUse = _selectedCategoryId ??
        (categories.isNotEmpty ? categories.first.id : 'cat_drinks');

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
      final rawImageUrl = _imageUrlController.text.trim();
      final imageUrl = rawImageUrl.isNotEmpty ? rawImageUrl : null;

      final parsedTax = double.tryParse(_taxController.text.trim()) ?? 0.0;
      final taxRate = parsedTax >= 1.0 ? parsedTax / 100.0 : (parsedTax > 0 ? parsedTax : 0.0);

      if (_isEditing) {
        // Update product
        final updated = widget.product!.copyWith(
          name: _nameController.text.trim(),
          code: code,
          barcode: _barcodeController.text.trim(),
          sku: _skuController.text.trim(),
          categoryId: categoryIdToUse,
          costPrice: costPrice,
          salePrice: salePrice,
          stockQty: stockQty,
          unit: _selectedUnit,
          lowStockThreshold: lowStock,
          tax: taxRate,
          status: _isActive ? 'active' : 'inactive',
          imageUrl: imageUrl,
          clearImageUrl: imageUrl == null,
          updatedAt: DateTime.now(),
        );

        await repo.updateProduct(updated, oldCode: widget.product!.code);

        // Fire-and-forget Audit Log
        AuditService.logFromRef(
          ref,
          action: 'product.update',
          entityType: 'product',
          entityId: updated.id,
          details: '${updated.name} (${updated.code})',
        );

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
          categoryId: categoryIdToUse,
          costPrice: costPrice,
          salePrice: salePrice,
          stockQty: stockQty,
          unit: _selectedUnit,
          lowStockThreshold: lowStock,
          tax: taxRate,
          status: _isActive ? 'active' : 'inactive',
          imageUrl: imageUrl,
          updatedAt: DateTime.now(),
        );

        await repo.createProduct(newProduct);

        // Fire-and-forget Audit Log
        AuditService.logFromRef(
          ref,
          action: 'product.create',
          entityType: 'product',
          entityId: newProduct.id,
          details: '${newProduct.name} (${newProduct.code})',
        );

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
                        validator: (v) => (v == null && (currentValue == null || currentValue.isEmpty)) ? 'Category is required' : null,
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
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'បារកូដ (Barcode)',
                      hintText: 'e.g. 884000109',
                      isDense: true,
                      prefixIcon: const Icon(Icons.qr_code, size: 18),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_barcodeController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              tooltip: 'លុប',
                              onPressed: () {
                                setState(() {
                                  _barcodeController.clear();
                                });
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 20),
                            tooltip: 'ស្កេនបារកូដ (Scan Barcode)',
                            onPressed: _openBarcodeScanner,
                          ),
                        ],
                      ),
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

            // Tax Rate Input Field
            TextFormField(
              controller: _taxController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'អត្រាពន្ធ (Tax / VAT Rate)',
                hintText: 'e.g. 0, 5, 10',
                suffixText: '%',
                isDense: true,
                prefixIcon: Icon(Icons.percent, size: 18),
              ),
              validator: (v) {
                if (v != null && v.trim().isNotEmpty) {
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null || parsed < 0 || parsed > 100) {
                    return 'សូមបញ្ចូលភាគរយពន្ធត្រឹមត្រូវ (0-100%)';
                  }
                }
                return null;
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
            const SizedBox(height: 20),

            // 4. Product Image Section (Upload from Device OR Paste URL)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'រូបភាពទំនិញ (Product Image)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                ),
                if (_imageUrlController.text.isNotEmpty)
                  InkWell(
                    onTap: () => setState(() => _imageUrlController.clear()),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline, size: 14, color: AppColors.danger),
                        SizedBox(width: 4),
                        Text(
                          'លុបរូប (Clear)',
                          style: TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Card container for image actions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkSurface
                    : AppColors.lightBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      // Thumbnail Preview with Loading Overlay
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          ProductThumbnail(
                            imageUrl: _imageUrlController.text,
                            productId: widget.product?.id,
                            productName: _nameController.text,
                            barcode: _barcodeController.text,
                            width: 64,
                            height: 64,
                            borderRadius: AppRadius.md,
                            fallbackIcon: Icons.add_photo_alternate_outlined,
                          ),
                          if (_isUploadingImage)
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),

                      // Option A: Pick & Upload from Storage / Device
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _isUploadingImage ? null : _handlePickAndUploadImage,
                              icon: _isUploadingImage
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.file_upload_outlined, size: 18),
                              label: Text(
                                _isUploadingImage ? 'កំពុង Upload...' : 'Upload ពីរូបភាព (Device)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _imageUrlController.text.isNotEmpty
                                  ? '✓ ភ្ជាប់រូបភាពរួចរាល់'
                                  : 'ជ្រើសរើសរូបពី Gallery / Computer',
                              style: TextStyle(
                                fontSize: 11,
                                color: _imageUrlController.text.isNotEmpty
                                    ? AppColors.success
                                    : Colors.grey,
                                fontWeight: _imageUrlController.text.isNotEmpty
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  // Option B: Paste Direct Link
                  TextFormField(
                    controller: _imageUrlController,
                    decoration: InputDecoration(
                      labelText: 'ឬ បិទភ្ជាប់តំណភ្ជាប់ (Or Paste Image URL)',
                      hintText: 'https://...',
                      prefixIcon: const Icon(Icons.link_rounded, size: 20),
                      suffixIcon: _imageUrlController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() => _imageUrlController.clear()),
                            )
                          : null,
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
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
      return Material(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
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
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: formContent,
      ),
    );
  }
}
