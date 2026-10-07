import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final currencyUSD = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  String _selectedCategory = 'ទាំងអស់';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getProductIcon(String iconName) {
    switch (iconName) {
      case 'local_drink':
        return Icons.local_drink_outlined;
      case 'bolt':
        return Icons.bolt_outlined;
      case 'water_drop':
        return Icons.water_drop_outlined;
      case 'ramen_dining':
        return Icons.ramen_dining_outlined;
      case 'cookie':
        return Icons.cookie_outlined;
      case 'clean_hands':
        return Icons.clean_hands_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  void _showAddEditProductDialog([ProductModel? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final barcodeCtrl = TextEditingController(text: existing?.barcode ?? '');
    final skuCtrl = TextEditingController(text: existing?.sku ?? '');
    final costCtrl = TextEditingController(text: existing != null ? existing.costPrice.toString() : '0.40');
    final priceCtrl = TextEditingController(text: existing != null ? existing.sellingPrice.toString() : '0.65');
    final stockCtrl = TextEditingController(text: existing != null ? existing.stockQty.toString() : '30');
    final unitCtrl = TextEditingController(text: existing?.unit ?? 'កំប៉ុង');
    String selectedCat = existing?.category ?? 'ភេសជ្ជៈ';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Icon(existing == null ? Icons.add_circle : Icons.edit, color: AppColors.cyan),
              const SizedBox(width: 8),
              Text(existing == null ? 'បង្កើតទំនិញថ្មី (New Product)' : 'កែសម្រួលទំនិញ (Edit Product)'),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'ឈ្មោះទំនិញ (Product Name) *', hintText: 'ឧ. Coca Cola 330ml'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: barcodeCtrl,
                          decoration: const InputDecoration(labelText: 'កូដបាកូដ (Barcode) *', hintText: '884000...'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: skuCtrl,
                          decoration: const InputDecoration(labelText: 'SKU (Optional)', hintText: 'SKU-001'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCat,
                    decoration: const InputDecoration(labelText: 'ប្រភេទ (Category) *'),
                    items: const [
                      DropdownMenuItem(value: 'ភេសជ្ជៈ', child: Text('ភេសជ្ជៈ (Beverages)')),
                      DropdownMenuItem(value: 'មី និងអាហារស្រាល', child: Text('មី និងអាហារស្រាល (Food & Noodles)')),
                      DropdownMenuItem(value: 'នំបុ័ង និងនំចំណី', child: Text('នំបុ័ង និងនំចំណី (Bakery & Snacks)')),
                      DropdownMenuItem(value: 'សម្ភារៈប្រើប្រាស់', child: Text('សម្ភារៈប្រើប្រាស់ (Household)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedCat = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: costCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'តម្លៃដើម (\$ Cost) *', prefixText: '\$ '),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'តម្លៃលក់ (\$ Sale) *', prefixText: '\$ '),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: stockCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'ចំនួនស្តុក (Stock Qty) *'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: unitCtrl,
                          decoration: const InputDecoration(labelText: 'ឯកតា (Unit) *', hintText: 'កំប៉ុង, ដប, កញ្ចប់'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('បោះបង់'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.cyan, foregroundColor: Colors.white),
              onPressed: () {
                if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
                final prov = Provider.of<ProductProvider>(context, listen: false);

                final newProd = ProductModel(
                  id: existing?.id ?? 'p_${DateTime.now().millisecondsSinceEpoch}',
                  barcode: barcodeCtrl.text.isNotEmpty ? barcodeCtrl.text : 'BAR-${DateTime.now().millisecondsSinceEpoch}',
                  sku: skuCtrl.text,
                  name: nameCtrl.text,
                  category: selectedCat,
                  costPrice: double.tryParse(costCtrl.text) ?? 0.0,
                  sellingPrice: double.tryParse(priceCtrl.text) ?? 0.0,
                  stockQty: int.tryParse(stockCtrl.text) ?? 0,
                  unit: unitCtrl.text.isNotEmpty ? unitCtrl.text : 'កំប៉ុង',
                );

                if (existing == null) {
                  prov.addProduct(newProd);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('បានបន្ថែមទំនិញថ្មីដោយជោគជ័យ!'), backgroundColor: AppColors.emerald),
                  );
                } else {
                  prov.updateProduct(newProd);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('បានកែប្រែទិន្នន័យទំនិញដោយជោគជ័យ!'), backgroundColor: AppColors.emerald),
                  );
                }

                Navigator.of(ctx).pop();
              },
              child: const Text('រក្សាទុក (Save)'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteProduct(ProductModel product, ProductProvider prov) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('លុបទំនិញ (Delete Product)'),
        content: Text('តើអ្នកប្រាកដជាចង់លុបទំនិញ "${product.name}" នេះចេញពីប្រព័ន្ធមែនទេ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('បោះបង់'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              prov.deleteProduct(product.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('បានលុបទំនិញដោយជោគជ័យ!'), backgroundColor: Colors.red),
              );
            },
            child: const Text('លុបចេញ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final productProv = Provider.of<ProductProvider>(context);
    final isDark = themeProv.isDarkMode;

    final bgColor = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedText = isDark ? AppColors.darkMutedText : AppColors.lightMutedText;

    final filteredProducts = productProv.allProducts.where((p) {
      final matchesCategory = _selectedCategory == 'ទាំងអស់' || p.category == _selectedCategory;
      final q = _searchQuery.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.barcode.contains(q) ||
          p.sku.toLowerCase().contains(q);
      return matchesCategory && matchesSearch;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header (Matching ProductList.jsx header) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INVENTORY',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.cyan, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'គ្រប់គ្រងមុខទំនិញ (Products)',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'គ្រប់គ្រងទិន្នន័យទំនិញទាំងអស់ តម្លៃដើម តម្លៃលក់ និងស្តុកទំនិញ',
                    style: TextStyle(fontSize: 13, color: mutedText),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('បង្កើតទំនិញថ្មី (New Product)', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _showAddEditProductDialog(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Toolbar: Filter by Category & Search Bar ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                // Category Filter
                SizedBox(
                  width: 220,
                  height: 42,
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                    ),
                    items: productProv.categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Search Box
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'ស្វែងរកតាមឈ្មោះ, Barcode, ឬ SKU...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                      ),
                      onChanged: (val) {
                        setState(() => _searchQuery = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Products Table ──
          Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    isDark ? AppColors.darkBg : Colors.grey.shade50,
                  ),
                  columns: const [
                    DataColumn(label: Text('រូបភាព', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('ឈ្មោះទំនិញ', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('កូដបាកូដ', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('ប្រភេទ', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('តម្លៃដើម', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('តម្លៃលក់', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('ស្តុក', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('ឯកតា', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('សកម្មភាព', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: filteredProducts.map((p) {
                    final bool isLowStock = p.stockQty <= 5;
                    return DataRow(
                      cells: [
                        DataCell(
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkBg : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(_getProductIcon(p.icon), size: 20, color: AppColors.primary),
                          ),
                        ),
                        DataCell(
                          Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataCell(
                          Text(p.barcode, style: TextStyle(color: mutedText)),
                        ),
                        DataCell(Text(p.category)),
                        DataCell(Text(currencyUSD.format(p.costPrice), style: TextStyle(color: mutedText))),
                        DataCell(
                          Text(
                            currencyUSD.format(p.sellingPrice),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isLowStock ? Colors.red.withValues(alpha: 0.12) : AppColors.emerald.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${p.stockQty}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isLowStock ? Colors.red : AppColors.emerald,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(p.unit)),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                                tooltip: 'កែសម្រួល',
                                onPressed: () => _showAddEditProductDialog(p),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                tooltip: 'លុប',
                                onPressed: () => _confirmDeleteProduct(p, productProv),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
