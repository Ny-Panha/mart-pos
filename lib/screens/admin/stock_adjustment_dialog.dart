import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';

class StockAdjustmentDialog extends StatefulWidget {
  final ProductModel product;

  const StockAdjustmentDialog({super.key, required this.product});

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  final TextEditingController _qtyController = TextEditingController();
  bool _isAddition = true; // true = Add, false = Remove
  String _selectedReason = 'physical_count_correction';

  final Map<String, String> _reasons = {
    'physical_count_correction': 'កែតម្រូវការរាប់ផ្ទាល់',
    'stock_in': 'ទទួលស្តុកចូលបន្ថែម (Stock In)',
    'damaged': 'ទំនិញខូចខាត (Damaged)',
    'expired': 'ទំនិញផុតកំណត់ (Expired)',
    'lost': 'ទំនិញបាត់បង់ (Lost)',
    'return_from_customer': 'អតិថិជនយកមកដូរវិញ (Return)',
  };

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProv = Provider.of<ProductProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('កែសម្រួលស្តុក (Stock Adjustment)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(
            '${widget.product.name} (ស្តុកបច្ចុប្បន្ន: ${widget.product.stockQty})',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode toggle: Add or Remove
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('បន្ថែម (+)')),
                    selected: _isAddition,
                    selectedColor: Colors.green.shade100,
                    onSelected: (_) => setState(() => _isAddition = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('កាត់ដក (-)')),
                    selected: !_isAddition,
                    selectedColor: Colors.red.shade100,
                    onSelected: (_) => setState(() => _isAddition = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'ចំនួនកែប្រែ (Quantity) *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              initialValue: _selectedReason,
              decoration: InputDecoration(
                labelText: 'មូលហេតុ (Reason) *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _reasons.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedReason = val);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('បោះបង់'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _isAddition ? Colors.green.shade700 : Colors.red.shade700,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final qty = int.tryParse(_qtyController.text) ?? 0;
            if (qty <= 0) return;

            final int change = _isAddition ? qty : -qty;
            productProv.adjustStock(
              productId: widget.product.id,
              changeQty: change,
              reason: _reasons[_selectedReason] ?? _selectedReason,
              cashierName: auth.currentUser.name,
            );

            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('បានកែប្រែស្តុកជោគជ័យ! (${_isAddition ? "+$qty" : "-$qty"})'),
                backgroundColor: _isAddition ? Colors.green : Colors.red,
              ),
            );
          },
          child: const Text('បញ្ជាក់ការកែស្តុក'),
        ),
      ],
    );
  }
}
