import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../admin/stock_adjustment_dialog.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _onlyLowStock = false;
  final currencyUSD = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddEditDialog([ProductModel? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final barcodeCtrl = TextEditingController(text: existing?.barcode ?? '');
    final costCtrl = TextEditingController(text: existing != null ? existing.costPrice.toString() : '');
    final priceCtrl = TextEditingController(text: existing != null ? existing.sellingPrice.toString() : '');
    final stockCtrl = TextEditingController(text: existing != null ? existing.stockQty.toString() : '20');
    String selectedCat = existing?.category ?? 'ភេសជ្ជៈ';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(existing == null ? 'បន្ថែមទំនិញថ្មី' : 'កែសម្រួលទំនិញ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'ឈ្មោះទំនិញ *'),
                ),
                TextField(
                  controller: barcodeCtrl,
                  decoration: const InputDecoration(labelText: 'លេខកូដបាកូដ (Barcode) *'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCat,
                  decoration: const InputDecoration(labelText: 'ប្រភេទ (Category)'),
                  items: ['ភេសជ្ជៈ', 'មី និងអាហារស្រាល', 'នំបុ័ង និងនំចំណី', 'សម្ភារៈប្រើប្រាស់']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedCat = val);
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: costCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'តម្លៃដើម (\$)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'តម្លៃលក់ (\$) *'),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'ចំនួនក្នុងស្តុក (Qty) *'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('បោះបង់'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade800,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;

                final prov = Provider.of<ProductProvider>(context, listen: false);
                final prod = ProductModel(
                  id: existing?.id ?? 'p_${DateTime.now().millisecondsSinceEpoch}',
                  barcode: barcodeCtrl.text.isNotEmpty ? barcodeCtrl.text : DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameCtrl.text,
                  category: selectedCat,
                  costPrice: double.tryParse(costCtrl.text) ?? 0.0,
                  sellingPrice: double.tryParse(priceCtrl.text) ?? 0.0,
                  stockQty: int.tryParse(stockCtrl.text) ?? 0,
                );

                if (existing == null) {
                  prov.addProduct(prod);
                } else {
                  prov.updateProduct(prod);
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('រក្សាទុក'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<ProductProvider>(context);
    final products = _onlyLowStock ? prov.lowStockProducts : prov.allProducts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('គ្រប់គ្រងស្តុក (Inventory & Stock)'),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amberAccent,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'បញ្ជីទំនិញ'),
            Tab(icon: Icon(Icons.history), text: 'ប្រវត្តិកែស្តុក (History)'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_onlyLowStock ? Icons.warning : Icons.warning_amber_outlined,
                color: _onlyLowStock ? Colors.orangeAccent : Colors.white),
            tooltip: 'មើលតែទំនិញជិតអស់ស្តុក',
            onPressed: () => setState(() => _onlyLowStock = !_onlyLowStock),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('បន្ថែមទំនិញ'),
        onPressed: () => _showAddEditDialog(),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Product List
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.indigo.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('ទំនិញសរុប', '${prov.allProducts.length}', Colors.black87),
                    _buildStat('ជិតអស់ស្តុក', '${prov.lowStockProducts.length}', Colors.red.shade700),
                    _buildStat('ប្រភេទ', '${prov.categories.length - 1}', Colors.indigo),
                  ],
                ),
              ),
              Expanded(
                child: products.isEmpty
                    ? const Center(child: Text('មិនមានទំនិញទេ'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: products.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = products[index];
                          final isLow = item.stockQty <= 5;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isLow ? Colors.red.shade100 : Colors.indigo.shade50,
                              foregroundColor: isLow ? Colors.red : Colors.indigo,
                              child: Icon(isLow ? Icons.warning_amber_rounded : Icons.inventory_2_outlined),
                            ),
                            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Barcode: ${item.barcode} • ប្រភេទ: ${item.category}\nដើម: ${currencyUSD.format(item.costPrice)} | លក់: ${currencyUSD.format(item.sellingPrice)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ActionChip(
                                  backgroundColor: isLow ? Colors.red.shade100 : Colors.green.shade100,
                                  label: Text(
                                    'ស្តុក: ${item.stockQty}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isLow ? Colors.red.shade900 : Colors.green.shade900,
                                      fontSize: 12,
                                    ),
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => StockAdjustmentDialog(product: item),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                  onPressed: () => _showAddEditDialog(item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                  onPressed: () => prov.deleteProduct(item.id),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),

          // Tab 2: Stock History
          prov.stockHistory.isEmpty
              ? const Center(
                  child: Text('មិនទាន់មានប្រវត្តិកែសម្រួលស្តុកនៅឡើយទេ'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: prov.stockHistory.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, idx) {
                    final h = prov.stockHistory[idx];
                    final isPositive = h.changeQty > 0;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPositive ? Colors.green.shade100 : Colors.red.shade100,
                          foregroundColor: isPositive ? Colors.green.shade800 : Colors.red.shade800,
                          child: Icon(isPositive ? Icons.add : Icons.remove),
                        ),
                        title: Text(h.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('មូលហេតុ: ${h.reason}\nដោយ: ${h.cashierName} • ${dateFormat.format(h.createdAt)}'),
                        trailing: Text(
                          '${isPositive ? "+" : ""}${h.changeQty}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isPositive ? Colors.green.shade800 : Colors.red.shade800,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}
