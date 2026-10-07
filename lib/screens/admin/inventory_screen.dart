import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _barcodeInputCtrl = TextEditingController();
  final TextEditingController _quickQtyCtrl = TextEditingController(text: '10');
  ProductModel? _scannedProduct;

  String _searchQuery = '';
  String _selectedCategory = 'ALL';
  String _statusFilter = 'ALL';

  void _onBarcodeScanSubmit(String barcode) {
    if (barcode.trim().isEmpty) return;
    final prov = Provider.of<ProductProvider>(context, listen: false);
    final match = prov.findByBarcode(barcode.trim());
    if (match != null) {
      setState(() {
        _scannedProduct = match;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('បានរកឃើញ: ${match.name}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('មិនមានទំនិញលេខកូដ "$barcode" ក្នុងស្តុកទេ')),
      );
    }
  }

  void _openStockAdjustmentDialog(ProductModel product, {String defaultType = 'IN'}) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final qtyCtrl = TextEditingController(text: '5');
    final reasonCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String adjType = defaultType; // 'IN', 'OUT', 'DAMAGED', 'EXPIRED'

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.tune, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'កែសម្រួលស្តុក (Stock Adjustment) - ${product.name}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBg : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ស្តុកបច្ចុប្បន្ន (Current Stock):', style: TextStyle(color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText)),
                        Text('${product.stock} ${product.unit}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('ប្រភេទនៃការកែតម្រូវ (Adjustment Type):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('➕ នាំចូលស្តុក (Stock In)'),
                        selected: adjType == 'IN',
                        onSelected: (_) => setModalState(() => adjType = 'IN'),
                      ),
                      ChoiceChip(
                        label: const Text('➖ ដកចេញពីស្តុក (Stock Out)'),
                        selected: adjType == 'OUT',
                        onSelected: (_) => setModalState(() => adjType = 'OUT'),
                      ),
                      ChoiceChip(
                        label: const Text('⚠️ ខូចខាត (Damaged)'),
                        selected: adjType == 'DAMAGED',
                        onSelected: (_) => setModalState(() => adjType = 'DAMAGED'),
                      ),
                      ChoiceChip(
                        label: const Text('⌛ ហួសដឺឡេ (Expired)'),
                        selected: adjType == 'EXPIRED',
                        onSelected: (_) => setModalState(() => adjType = 'EXPIRED'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Text('ចំនួនដែលត្រូវកែតម្រូវ (Quantity)*', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkText : AppColors.lightText),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: isDark ? AppColors.darkBg : Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      hintText: 'ចំនួនឯកតា...',
                    ),
                  ),

                  const SizedBox(height: 14),
                  Text('មូលហេតុ (Reason)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reasonCtrl,
                    style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkText : AppColors.lightText),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: isDark ? AppColors.darkBg : Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      hintText: 'ឧ. ទំនិញបាក់បែក, ទិញបំពេញបន្ថែម...',
                    ),
                  ),

                  const SizedBox(height: 14),
                  Text('សម្គាល់បន្ថែម (Note)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 2,
                    style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkText : AppColors.lightText),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: isDark ? AppColors.darkBg : Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      hintText: 'កំណត់ចំណាំរបស់បុគ្គលិក...',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('បោះបង់')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: adjType == 'IN' ? const Color(0xFF10B981) : (adjType == 'OUT' ? Colors.orange : Colors.red),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                if (qty <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('សូមបញ្ចូលចំនួនធំជាង 0')));
                  return;
                }
                final prov = Provider.of<ProductProvider>(context, listen: false);
                if (adjType == 'IN') {
                  prov.updateStock(product.id, qty);
                } else {
                  if (qty > product.stock) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ចំនួនដកចេញមិនអាចលើសពីស្តុកដែលមានទេ')));
                    return;
                  }
                  prov.updateStock(product.id, -qty);
                }
                Navigator.pop(ctx);
                setState(() {
                  if (_scannedProduct?.id == product.id) {
                    _scannedProduct = prov.findById(product.id);
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('បានកែប្រែស្តុក ${product.name} រួចរាល់')),
                );
              },
              child: const Text('អនុវត្តការកែសម្រួល'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prodProv = Provider.of<ProductProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final isDark = themeProv.isDarkMode;

    final allProducts = prodProv.products;
    final totalUnits = allProducts.fold<int>(0, (sum, p) => sum + p.stock);
    final lowStockCount = allProducts.where((p) => p.isLowStock && p.stock > 0).length;
    final outOfStockCount = allProducts.where((p) => p.isOutOfStock).length;

    final categories = ['ALL', ...prodProv.categories];

    final filtered = allProducts.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.barcode.contains(_searchQuery) ||
          p.sku.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;
      if (_selectedCategory != 'ALL' && p.category != _selectedCategory) return false;
      if (_statusFilter == 'LOW' && (!p.isLowStock || p.stock == 0)) return false;
      if (_statusFilter == 'OUT' && !p.isOutOfStock) return false;
      if (_statusFilter == 'IN' && (p.isLowStock || p.isOutOfStock)) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INVENTORY / ឃ្លាំង និងស្តុកទំនិញ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'គ្រប់គ្រងស្តុក និងកែសម្រួល (Inventory)',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ត្រួតពិនិត្យចំនួនទំនិញក្នុងស្តុក បញ្ចូលស្តុកថ្មី ដកទំនិញខូច និងតាមដានទំនិញជិតអស់',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 4 Stat KPI Cards (matching Kambuja-POS Inventory.jsx)
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    isDark,
                    title: 'មុខទំនិញសរុប (Products)',
                    value: '${allProducts.length}',
                    desc: 'ចំនួនមុខទំនិញដែលបានចុះបញ្ជីក្នុងប្រព័ន្ធ។',
                    icon: Icons.inventory_2_outlined,
                    iconColor: Colors.blue,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildKpiCard(
                    isDark,
                    title: 'បរិមាណស្តុកសរុប (Stock Units)',
                    value: '$totalUnits',
                    desc: 'ចំនួនឯកតាទំនិញទាំងអស់ដែលកំពុងមានក្នុងឃ្លាំង។',
                    icon: Icons.layers_outlined,
                    iconColor: Colors.purple,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildKpiCard(
                    isDark,
                    title: 'ជិតអស់ពីស្តុក (Low Stock)',
                    value: '$lowStockCount',
                    desc: 'ទំនិញដែលមានចំនួនតិចជាងកម្រិតប្រកាសអាសន្ន។',
                    icon: Icons.warning_amber_rounded,
                    iconColor: Colors.orange,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildKpiCard(
                    isDark,
                    title: 'អស់ពីស្តុក (Out of Stock)',
                    value: '$outOfStockCount',
                    desc: 'ទំនិញដែលអស់ពីឃ្លាំងទាំងស្រុង (Stock 0)។',
                    icon: Icons.highlight_off_rounded,
                    iconColor: Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Quick Scan Barcode Bar (matching Inventory.jsx quick scan)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'ស្កេនបាកូដរហ័ស (Quick Barcode Scan & Adjust)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _barcodeInputCtrl,
                          onSubmitted: _onBarcodeScanSubmit,
                          style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkText : AppColors.lightText),
                          decoration: InputDecoration(
                            hintText: 'បញ្ចូល ឬស្កេន Barcode / SKU នៅទីនេះ ហើយចុច Enter...',
                            prefixIcon: const Icon(Icons.barcode_reader, size: 20),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.arrow_forward),
                              onPressed: () => _onBarcodeScanSubmit(_barcodeInputCtrl.text),
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: isDark ? AppColors.darkBg : Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_scannedProduct != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _scannedProduct!.imageUrl ?? '',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.image_not_supported, size: 24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_scannedProduct!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 2),
                                Text('Barcode: ${_scannedProduct!.barcode} | SKU: ${_scannedProduct!.sku}', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('ស្តុកបច្ចុប្បន្ន', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText)),
                              Text('${_scannedProduct!.stock} ${_scannedProduct!.unit}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                            ],
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: _quickQtyCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                isDense: true,
                                filled: true,
                                fillColor: isDark ? AppColors.darkBg : Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                hintText: 'ចំនួន',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                            onPressed: () {
                              final qty = int.tryParse(_quickQtyCtrl.text.trim()) ?? 0;
                              if (qty > 0) {
                                prodProv.updateStock(_scannedProduct!.id, qty);
                                setState(() {
                                  _scannedProduct = prodProv.findById(_scannedProduct!.id);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('បានបន្ថែមស្តុក $qty ${_scannedProduct!.unit}')));
                              }
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Stock In'),
                          ),
                          const SizedBox(width: 6),
                          OutlinedButton.icon(
                            onPressed: () => _openStockAdjustmentDialog(_scannedProduct!),
                            icon: const Icon(Icons.tune, size: 16),
                            label: const Text('កែសម្រួលលម្អិត'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Inventory Table Container
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  // Filter bar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (v) => setState(() => _searchQuery = v),
                            style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkText : AppColors.lightText),
                            decoration: InputDecoration(
                              hintText: 'ស្វែងរកទំនិញតាមឈ្មោះ Barcode ឬ SKU...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              isDense: true,
                              filled: true,
                              fillColor: isDark ? AppColors.darkBg : Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: _selectedCategory,
                          underline: const SizedBox(),
                          items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat == 'ALL' ? 'គ្រប់ប្រភេទ (All Categories)' : cat))).toList(),
                          onChanged: (v) => setState(() => _selectedCategory = v!),
                        ),
                        const SizedBox(width: 12),
                        Wrap(
                          spacing: 6,
                          children: [
                            ChoiceChip(
                              label: const Text('ទាំងអស់'),
                              selected: _statusFilter == 'ALL',
                              onSelected: (_) => setState(() => _statusFilter = 'ALL'),
                            ),
                            ChoiceChip(
                              label: const Text('ជិតអស់ (Low)'),
                              selected: _statusFilter == 'LOW',
                              onSelected: (_) => setState(() => _statusFilter = 'LOW'),
                            ),
                            ChoiceChip(
                              label: const Text('អស់ស្តុក (Out)'),
                              selected: _statusFilter == 'OUT',
                              onSelected: (_) => setState(() => _statusFilter = 'OUT'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Data Table
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 300),
                      child: DataTable(
                        headingRowHeight: 44,
                        dataRowMinHeight: 60,
                        dataRowMaxHeight: 74,
                        columns: const [
                          DataColumn(label: Text('មុខទំនិញ (Product)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('ប្រភេទ (Category)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('តម្លៃដើម (Cost)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('តម្លៃលក់ (Price)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('ស្តុកបច្ចុប្បន្ន', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('ស្ថានភាព', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('សកម្មភាព', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: filtered.map((p) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        p.imageUrl ?? '',
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          width: 44,
                                          height: 44,
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.image, size: 20),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(
                                          '${p.barcode} • SKU: ${p.sku}',
                                          style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                  child: Text(p.category, style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              DataCell(Text('\$${p.costPrice.toStringAsFixed(2)}')),
                              DataCell(Text('\$${p.sellPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(
                                Text(
                                  '${p.stock} ${p.unit}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: p.isOutOfStock ? Colors.red : (p.isLowStock ? Colors.orange : Colors.green),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: p.isOutOfStock
                                        ? Colors.red.withValues(alpha: 0.15)
                                        : (p.isLowStock ? Colors.orange.withValues(alpha: 0.15) : Colors.green.withValues(alpha: 0.15)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    p.isOutOfStock ? 'អស់ពីស្តុក' : (p.isLowStock ? 'ជិតអស់' : 'ក្នុងស្តុក'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: p.isOutOfStock ? Colors.red : (p.isLowStock ? Colors.orange : Colors.green),
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, color: Color(0xFF10B981), size: 20),
                                      tooltip: 'បញ្ចូលស្តុក (Stock In)',
                                      onPressed: () => _openStockAdjustmentDialog(p, defaultType: 'IN'),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.tune, color: AppColors.primary, size: 20),
                                      tooltip: 'កែសម្រួលស្តុក (Adjust)',
                                      onPressed: () => _openStockAdjustmentDialog(p),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(
    bool isDark, {
    required String title,
    required String value,
    required String desc,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkText : AppColors.lightText),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Text(
            desc,
            style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
          ),
        ],
      ),
    );
  }
}
