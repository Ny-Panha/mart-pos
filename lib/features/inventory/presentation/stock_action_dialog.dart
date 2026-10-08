import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/firestore/models/product_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../products/providers/product_provider.dart';
import '../providers/inventory_provider.dart';

enum StockActionType { stockIn, stockOut, adjust }

class StockActionDialog extends ConsumerStatefulWidget {
  final StockActionType actionType;
  final ProductModel? preselectedProduct;
  final bool isBottomSheet;

  const StockActionDialog({
    super.key,
    required this.actionType,
    this.preselectedProduct,
    this.isBottomSheet = false,
  });

  static Future<void> show(
    BuildContext context, {
    required StockActionType actionType,
    ProductModel? preselectedProduct,
  }) {
    final isDesktop = Responsive.isDesktop(context);
    if (isDesktop) {
      return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StockActionDialog(
          actionType: actionType,
          preselectedProduct: preselectedProduct,
          isBottomSheet: false,
        ),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => StockActionDialog(
          actionType: actionType,
          preselectedProduct: preselectedProduct,
          isBottomSheet: true,
        ),
      );
    }
  }

  @override
  ConsumerState<StockActionDialog> createState() => _StockActionDialogState();
}

class _StockActionDialogState extends ConsumerState<StockActionDialog> {
  final _formKey = GlobalKey<FormState>();

  ProductModel? _selectedProduct;
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedProduct = widget.preselectedProduct;
    if (widget.actionType == StockActionType.adjust && _selectedProduct != null) {
      _qtyController.text = '${_selectedProduct!.stockQty}';
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.actionType) {
      case StockActionType.stockIn:
        return 'បញ្ចូលស្តុកទំនិញ (Stock In)';
      case StockActionType.stockOut:
        return 'ដកទំនិញចេញ (Stock Out - Damage/Loss)';
      case StockActionType.adjust:
        return 'កែតម្រូវចំនួនស្តុក (Adjust Stock)';
    }
  }

  String get _subtitle {
    switch (widget.actionType) {
      case StockActionType.stockIn:
        return 'Receive incoming stock shipment from suppliers';
      case StockActionType.stockOut:
        return 'Record damaged, expired, or lost goods';
      case StockActionType.adjust:
        return 'Reconcile physical inventory count discrepancies';
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('សូមជ្រើសរើសទំនិញជាមុនសិន (Please select a product)'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final user = ref.read(authProvider).value;
    final userId = user?.id ?? 'user_unknown';
    final repo = ref.read(inventoryRepositoryProvider);

    final rawQty = int.tryParse(_qtyController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final note = _noteController.text.trim();

    setState(() => _isLoading = true);

    try {
      switch (widget.actionType) {
        case StockActionType.stockIn:
          await repo.stockIn(
            productId: _selectedProduct!.id,
            qty: rawQty,
            note: note.isNotEmpty ? note : 'Incoming delivery',
            userId: userId,
            productName: _selectedProduct!.name,
            userName: user?.name,
          );
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'បានបញ្ចូលស្តុក +$rawQty ${_selectedProduct!.unit} សម្រាប់ "${_selectedProduct!.name}"!',
                ),
                backgroundColor: AppColors.success,
              ),
            );
          }
          break;

        case StockActionType.stockOut:
          await repo.stockOut(
            productId: _selectedProduct!.id,
            currentQty: _selectedProduct!.stockQty,
            qty: rawQty,
            note: note,
            userId: userId,
            productName: _selectedProduct!.name,
            userName: user?.name,
          );
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'បានកត់ត្រាដកចេញ -$rawQty ${_selectedProduct!.unit} សម្រាប់ "${_selectedProduct!.name}"!',
                ),
                backgroundColor: AppColors.warning,
              ),
            );
          }
          break;

        case StockActionType.adjust:
          await repo.adjustStock(
            productId: _selectedProduct!.id,
            currentQty: _selectedProduct!.stockQty,
            newQty: rawQty,
            note: note,
            userId: userId,
            productName: _selectedProduct!.name,
            userName: user?.name,
          );
          final diff = rawQty - _selectedProduct!.stockQty;
          final diffSign = diff >= 0 ? '+$diff' : '$diff';
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'បានកែតម្រូវស្តុក ($diffSign) ទៅ $rawQty ${_selectedProduct!.unit} សម្រាប់ "${_selectedProduct!.name}"!',
                ),
                backgroundColor: AppColors.success,
              ),
            );
          }
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('បរាជ័យ (Failed): $e'),
            backgroundColor: AppColors.danger,
          ),
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
    final products = ref.watch(productsStreamProvider).value ?? [];

    final formBody = Form(
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
                    Text(_title, style: AppTextStyles.titleLG),
                    const SizedBox(height: 2),
                    Text(_subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 1. Product Picker
            if (widget.preselectedProduct != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedProduct!.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            'Code: ${_selectedProduct!.code} • Current Stock: ${_selectedProduct!.stockQty} ${_selectedProduct!.unit}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedProduct?.id,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'ជ្រើសរើសទំនិញ (Select Product) *',
                  isDense: true,
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
                items: products.map((p) {
                  return DropdownMenuItem(
                    value: p.id,
                    child: Text(
                      '${p.name} (${p.code}) — ស្តុក: ${p.stockQty} ${p.unit}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (id) {
                  final found = products.where((p) => p.id == id).firstOrNull;
                  setState(() {
                    _selectedProduct = found;
                    if (widget.actionType == StockActionType.adjust && found != null) {
                      _qtyController.text = '${found.stockQty}';
                    }
                  });
                },
                validator: (v) => v == null ? 'Please select a product' : null,
              ),

            const SizedBox(height: 16),

            // Current Stock preview badge if product selected
            if (_selectedProduct != null && widget.preselectedProduct == null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ស្តុកបច្ចុប្បន្ន (Current Stock):', style: TextStyle(fontSize: 12)),
                    Text(
                      '${_selectedProduct!.stockQty} ${_selectedProduct!.unit}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 2. Quantity input
            TextFormField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: widget.actionType == StockActionType.adjust
                    ? 'ចំនួនស្តុកពិតប្រាកដថ្មី (New Actual Stock Count) *'
                    : 'ចំនួនទំនិញ (Quantity) *',
                suffixText: _selectedProduct?.unit ?? 'Units',
                isDense: true,
                helperText: widget.actionType == StockActionType.adjust
                    ? 'បញ្ចូលចំនួនទំនិញរាប់ជាក់ស្តែង (Enter actual counted inventory)'
                    : null,
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Quantity is required';
                final parsed = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
                if (parsed == null) return 'Invalid number';

                if (widget.actionType == StockActionType.adjust) {
                  if (parsed < 0) return 'Cannot be negative';
                } else {
                  if (parsed <= 0) return 'Quantity must be > 0';
                }

                if (widget.actionType == StockActionType.stockOut && _selectedProduct != null) {
                  if (parsed > _selectedProduct!.stockQty) {
                    return 'Cannot exceed current stock (${_selectedProduct!.stockQty} ${_selectedProduct!.unit})';
                  }
                }
                return null;
              },
            ),

            // Live Diff Preview for Adjustment
            if (widget.actionType == StockActionType.adjust && _selectedProduct != null) ...[
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final newQ = int.tryParse(_qtyController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? _selectedProduct!.stockQty;
                  final diff = newQ - _selectedProduct!.stockQty;
                  final diffText = diff >= 0 ? '+$diff' : '$diff';
                  final diffColor = diff > 0
                      ? AppColors.success
                      : (diff < 0 ? AppColors.danger : Colors.grey);

                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: diffColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ចលនាស្តុក (Movement Diff):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text(
                          '$diffText ${_selectedProduct!.unit}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: diffColor),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 16),

            // 3. Note field
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: widget.actionType == StockActionType.stockIn
                    ? 'កំណត់សម្គាល់ (Note - optional)'
                    : 'មូលហេតុ (Reason Note) *',
                hintText: widget.actionType == StockActionType.stockIn
                    ? 'e.g. វិក្កយបត្រអ្នកផ្គត់ផ្គង់ Delivery Invoice #...'
                    : (widget.actionType == StockActionType.stockOut
                        ? 'e.g. ខូចខាតបែកបាក់ (Damaged), ហួសកាលបរិច្ឆេទ (Expired)...'
                        : 'e.g. រាប់ស្តុកប្រចាំខែ (Monthly inventory audit)...'),
                isDense: true,
              ),
              validator: (v) {
                if (widget.actionType != StockActionType.stockIn) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Reason note is required for ${widget.actionType == StockActionType.stockOut ? "Stock Out" : "Stock Adjustment"}';
                  }
                }
                return null;
              },
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
                    text: widget.actionType == StockActionType.stockIn
                        ? '+ បញ្ចូលស្តុក (STOCK IN)'
                        : (widget.actionType == StockActionType.stockOut
                            ? '- ដកចេញ (CONFIRM OUT)'
                            : 'កែតម្រូវ (APPLY ADJUST)'),
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
            Expanded(child: formBody),
          ],
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 650),
        child: formBody,
      ),
    );
  }
}
