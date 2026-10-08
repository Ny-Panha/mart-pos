import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/firestore/models/product_model.dart';
import '../../../data/firestore/models/purchase_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../suppliers/providers/supplier_provider.dart';
import '../providers/purchase_provider.dart';

class PurchaseFormDialog extends ConsumerStatefulWidget {
  final ProductModel? preselectedProduct;

  const PurchaseFormDialog({super.key, this.preselectedProduct});

  static Future<void> show(BuildContext context, {ProductModel? preselectedProduct}) {
    if (Responsive.isDesktop(context) || Responsive.isTablet(context)) {
      return showDialog<void>(
        context: context,
        builder: (_) => PurchaseFormDialog(preselectedProduct: preselectedProduct),
      );
    } else {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PurchaseFormDialog(preselectedProduct: preselectedProduct),
      );
    }
  }

  @override
  ConsumerState<PurchaseFormDialog> createState() => _PurchaseFormDialogState();
}

class _ItemDraft {
  ProductModel? product;
  final TextEditingController qtyController;
  final TextEditingController costController;

  _ItemDraft({
    this.product,
    int qty = 10,
    int? costPrice,
  })  : qtyController = TextEditingController(text: qty.toString()),
        costController = TextEditingController(text: (costPrice ?? product?.costPrice ?? 0).toString());

  int get qty => int.tryParse(qtyController.text) ?? 0;
  int get costPrice => int.tryParse(costController.text) ?? 0;
  int get subtotal => qty * costPrice;

  void dispose() {
    qtyController.dispose();
    costController.dispose();
  }
}

class _PurchaseFormDialogState extends ConsumerState<PurchaseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSupplierId;
  final TextEditingController _noteController = TextEditingController();
  final List<_ItemDraft> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedProduct != null) {
      _items.add(_ItemDraft(
        product: widget.preselectedProduct,
        qty: 10,
        costPrice: widget.preselectedProduct!.costPrice,
      ));
    } else {
      _items.add(_ItemDraft());
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItemRow() {
    setState(() {
      _items.add(_ItemDraft());
    });
  }

  void _removeItemRow(int index) {
    if (_items.length <= 1) return;
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSupplierId == null) {
      setState(() => _errorMessage = 'សូមជ្រើសរើសអ្នកផ្គត់ផ្គង់ (Please select a supplier)');
      return;
    }

    if (_items.isEmpty) {
      setState(() => _errorMessage = 'សូមបន្ថែមមុខទំនិញយ៉ាងតិច ១ មុខ');
      return;
    }

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.product == null) {
        setState(() => _errorMessage = 'សូមជ្រើសរើសទំនិញសម្រាប់ជួរទី ${i + 1}');
        return;
      }
      if (item.qty <= 0) {
        setState(() => _errorMessage = 'ចំនួនទំនិញ "${item.product!.name}" ត្រូវតែធំជាង ០');
        return;
      }
      if (item.costPrice < 0) {
        setState(() => _errorMessage = 'ថ្លៃដើមទំនិញ "${item.product!.name}" មិនអាចអវិជ្ជមានបានទេ');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(purchaseRepositoryProvider);
      final user = ref.read(authProvider).value;

      final purchaseItems = _items.map((i) {
        return PurchaseItem(
          productId: i.product!.id,
          name: i.product!.name,
          qty: i.qty,
          costPrice: i.costPrice,
        );
      }).toList();

      await repo.createPurchase(
        supplierId: _selectedSupplierId!,
        items: purchaseItems,
        note: _noteController.text.trim(),
        userId: user?.id ?? 'admin',
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('បានកត់ត្រាការទិញចូល និងបញ្ចូលស្តុកដោយជោគជ័យ!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '').replaceFirst('ArgumentError: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = Responsive.isDesktop(context) || Responsive.isTablet(context);
    final activeSuppliers = ref.watch(activeSuppliersProvider);
    final allProducts = ref.watch(productsStreamProvider).value ?? [];

    final totalRiel = _items.fold<int>(0, (sum, i) => sum + i.subtotal);
    final totalUsd = MoneyUtils.rielToUsd(totalRiel);

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
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.shopping_cart_checkout_rounded,
                  color: AppColors.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'កត់ត្រាការទិញចូល (New Stock Purchase)',
                      style: AppTextStyles.titleLG.copyWith(
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'កត់ត្រាទំនិញទិញចូលពីអ្នកផ្គត់ផ្គង់ (បន្ថែមស្តុក និងកែប្រែថ្លៃដើម)',
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

          // Supplier Selection
          Text(
            'ជ្រើសរើសអ្នកផ្គត់ផ្គង់ (Supplier) *',
            style: AppTextStyles.bodyBold,
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedSupplierId,
            hint: const Text('ជ្រើសរើសអ្នកផ្គត់ផ្គង់...'),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.storefront_outlined),
            ),
            items: activeSuppliers.map((s) {
              return DropdownMenuItem<String>(
                value: s.id,
                child: Text(s.name, style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedSupplierId = val;
                _errorMessage = null;
              });
            },
            validator: (val) => val == null ? 'សូមជ្រើសរើសអ្នកផ្គត់ផ្គង់' : null,
          ),
          const SizedBox(height: 20),

          // Items Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'បញ្ជីមុខទំនិញទិញចូល (${_items.length} មុខ):',
                style: AppTextStyles.bodyBold,
              ),
              TextButton.icon(
                onPressed: _addItemRow,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('បន្ថែមមុខទំនិញ'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Dynamic Item Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final draft = _items[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Product Picker Dropdown
                        Expanded(
                          flex: 5,
                          child: DropdownButtonFormField<String>(
                            initialValue: draft.product?.id,
                            isExpanded: true,
                            hint: const Text('ជ្រើសរើសទំនិញ...', style: TextStyle(fontSize: 12)),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              isDense: true,
                            ),
                            items: allProducts.map((p) {
                              return DropdownMenuItem<String>(
                                value: p.id,
                                child: Text(
                                  '${p.name} (ស្តុក: ${p.stockQty})',
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (selectedId) {
                              if (selectedId == null) return;
                              final prod = allProducts.firstWhere((p) => p.id == selectedId);
                              setState(() {
                                draft.product = prod;
                                draft.costController.text = prod.costPrice.toString();
                              });
                            },
                          ),
                        ),
                        if (_items.length > 1) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                            tooltip: 'Remove Row',
                            onPressed: () => _removeItemRow(index),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Quantity
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: draft.qtyController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              labelText: 'ចំនួន (Qty)',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Cost Price (Riel)
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: draft.costController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              labelText: 'ថ្លៃដើម/ឯកតា (៛)',
                              suffixText: '៛',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Subtotal
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('សរុប (Subtotal)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              Text(
                                MoneyUtils.formatRiel(draft.subtotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Note
          TextFormField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'កំណត់ចំណាំបន្ថែម (Note)',
              hintText: 'លេខវិក្កយបត្រក្រដាស ឬព័ត៌មានដឹកជញ្ជូន...',
              prefixIcon: Icon(Icons.description_outlined),
              isDense: true,
            ),
          ),
          const SizedBox(height: 20),

          // Total Cost Live Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'សរុបថ្លៃដើមការទិញ (Total Cost):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      'អត្រាប្តូរប្រាក់ 1\$ = 4,100 ៛',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      MoneyUtils.formatRiel(totalRiel),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      MoneyUtils.formatUSD(totalUsd),
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
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
                width: 170,
                child: AppButton(
                  text: 'កត់ត្រាការទិញ',
                  isLoading: _isLoading,
                  onPressed: _handleSubmit,
                  icon: Icons.check_circle_outline,
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
          width: 640,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(child: formContent),
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(child: formContent),
      );
    }
  }
}
