import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/customer_model.dart';
import '../../providers/customer_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditCustomerDialog(BuildContext context, [CustomerModel? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? 'បាត់ដំបង');
    final pointsCtrl = TextEditingController(text: existing != null ? existing.points.toString() : '50');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(existing == null ? Icons.person_add : Icons.edit, color: AppColors.cyan),
            const SizedBox(width: 8),
            Text(existing == null ? 'បន្ថែមអតិថិជនថ្មី (Add Customer)' : 'កែសម្រួលអតិថិជន (Edit Customer)'),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ឈ្មោះអតិថិជន (Name) *')),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'លេខទូរស័ព្ទ (Phone) *')),
              const SizedBox(height: 10),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'អាសយដ្ឋាន (Address)')),
              const SizedBox(height: 10),
              TextField(controller: pointsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ពិន្ទុសន្សំ (Loyalty Points)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('បោះបង់')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.cyan, foregroundColor: Colors.white),
            onPressed: () {
              if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) return;
              final prov = Provider.of<CustomerProvider>(context, listen: false);
              final model = CustomerModel(
                id: existing?.id ?? 'c_${DateTime.now().millisecondsSinceEpoch}',
                name: nameCtrl.text,
                phone: phoneCtrl.text,
                points: int.tryParse(pointsCtrl.text) ?? 0,
                address: addressCtrl.text,
              );
              if (existing == null) {
                prov.addCustomer(model);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('បានបន្ថែមអតិថិជនថ្មីដោយជោគជ័យ!'), backgroundColor: AppColors.emerald),
                );
              } else {
                prov.updateCustomer(model);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('បានកែសម្រួលទិន្នន័យអតិថិជនដោយជោគជ័យ!'), backgroundColor: AppColors.emerald),
                );
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('រក្សាទុក (Save)'),
          ),
        ],
      ),
    );
  }

  Widget _buildTierBadge(int points) {
    if (points >= 150) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
        child: const Text('GOLD TIER', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
      );
    } else if (points >= 50) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: Colors.blueGrey.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
        child: const Text('SILVER TIER', style: TextStyle(color: Colors.blueGrey, fontSize: 10, fontWeight: FontWeight.bold)),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: Colors.brown.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
        child: const Text('BRONZE TIER', style: TextStyle(color: Colors.brown, fontSize: 10, fontWeight: FontWeight.bold)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerProv = Provider.of<CustomerProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final isDark = themeProv.isDarkMode;

    final bgColor = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedText = isDark ? AppColors.darkMutedText : AppColors.lightMutedText;

    final filtered = customerProv.customers.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) || c.phone.contains(q);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header (Matching CustomerList.jsx) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CRM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.cyan, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text('អតិថិជន និងពិន្ទុសន្សំ (Customers)', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 4),
                  Text('គ្រប់គ្រងទិន្នន័យអតិថិជន ពិន្ទុសន្សំ និងប្រវត្តិទិញទំនិញ', style: TextStyle(fontSize: 13, color: mutedText)),
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
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('+ បន្ថែមអតិថិជន (Add Customer)', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _showAddEditCustomerDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Search & Table ──
          Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 300,
                    height: 42,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'ស្វែងរកតាមឈ្មោះ ឬលេខទូរស័ព្ទ...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                ),
                const Divider(height: 1),

                ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        isDark ? AppColors.darkBg : Colors.grey.shade50,
                      ),
                      columns: const [
                        DataColumn(label: Text('ឈ្មោះអតិថិជន', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('លេខទូរស័ព្ទ', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ពិន្ទុសន្សំ (Points)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('កម្រិតសមាជិក', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('អាសយដ្ឋាន', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('សកម្មភាព', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: filtered.map((c) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.cyan.withValues(alpha: 0.15),
                                    child: const Icon(Icons.person, size: 18, color: AppColors.cyan),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            DataCell(Text(c.phone, style: TextStyle(color: mutedText))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('${c.points} pts', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12)),
                              ),
                            ),
                            DataCell(_buildTierBadge(c.points)),
                            DataCell(Text(c.address, style: TextStyle(color: mutedText))),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                                    tooltip: 'កែសម្រួល',
                                    onPressed: () => _showAddEditCustomerDialog(context, c),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                    tooltip: 'លុប',
                                    onPressed: () {
                                      customerProv.deleteCustomer(c.id);
                                    },
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
    );
  }
}
