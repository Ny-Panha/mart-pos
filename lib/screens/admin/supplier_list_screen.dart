import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class SupplierItem {
  final String id;
  String businessName;
  String contactName;
  String phone;
  String address;
  String note;

  SupplierItem({
    required this.id,
    required this.businessName,
    required this.contactName,
    required this.phone,
    required this.address,
    required this.note,
  });
}

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  final List<SupplierItem> _suppliers = [
    SupplierItem(
      id: 'SUP-001',
      businessName: 'Cambodia Beverage Co., Ltd (Coca-Cola)',
      contactName: 'លោក សុខ ជា',
      phone: '012 345 678',
      address: 'ផ្លូវជាតិលេខ ៤, រាជធានីភ្នំពេញ',
      note: 'ផ្គត់ផ្គង់ភេសជ្ជៈកូកា កូឡា និងទឹកបរិសុទ្ធ ដាសានី',
    ),
    SupplierItem(
      id: 'SUP-002',
      businessName: 'Angkor Dairy Products (Angkormilk)',
      contactName: 'អ្នកស្រី ចាន់ ធីតា',
      phone: '015 889 900',
      address: 'តំបន់សេដ្ឋកិច្ចពិសេសភ្នំពេញ',
      note: 'ទឹកដោះគោស្រស់ ទឹកដោះគោជូរ និងយ៉ាអួ',
    ),
    SupplierItem(
      id: 'SUP-003',
      businessName: 'Khmer Food Distribution Co.',
      contactName: 'លោក វ៉ាន់ សុផល',
      phone: '098 765 432',
      address: 'ក្រុងបាត់ដំបង, ខេត្តបាត់ដំបង',
      note: 'មីជាតិ នំកញ្ចប់ គ្រឿងទេស និងប្រេងឆា',
    ),
    SupplierItem(
      id: 'SUP-004',
      businessName: 'Unilever Cambodia Distribution',
      contactName: 'លោក ហេង វិសាល',
      phone: '023 999 111',
      address: 'ខណ្ឌទួលគោក, រាជធានីភ្នំពេញ',
      note: 'សាប៊ូ ថ្នាំដុសធ្មេញ ផលិតផលប្រើប្រាស់ប្រចាំថ្ងៃ',
    ),
    SupplierItem(
      id: 'SUP-005',
      businessName: 'Mondulkiri Organic Coffee & Tea',
      contactName: 'អ្នកស្រី មុំ ស៊ីណាត',
      phone: '',
      address: 'ខេត្តមណ្ឌលគិរី',
      note: 'កាហ្វេគ្រាប់ និងតែបៃតងធម្មជាតិ',
    ),
  ];

  String _searchQuery = '';
  bool _onlyWithPhone = false;

  List<SupplierItem> get _filteredSuppliers {
    return _suppliers.where((s) {
      final matchesSearch = s.businessName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.contactName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.phone.contains(_searchQuery);
      if (!matchesSearch) return false;
      if (_onlyWithPhone && s.phone.isEmpty) return false;
      return true;
    }).toList();
  }

  void _openAddEditSupplierModal([SupplierItem? existing]) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final businessCtrl = TextEditingController(text: existing?.businessName ?? '');
    final contactCtrl = TextEditingController(text: existing?.contactName ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final noteCtrl = TextEditingController(text: existing?.note ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          existing == null ? '➕ បន្ថែមអ្នកផ្គត់ផ្គង់ថ្មី (Add Supplier)' : '✏️ កែប្រែអ្នកផ្គត់ផ្គង់ (Edit Supplier)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField(isDark, 'ឈ្មោះក្រុមហ៊ុន / អាជីវកម្ម (Business Name)*', businessCtrl),
                const SizedBox(height: 12),
                _buildField(isDark, 'អ្នកទំនាក់ទំនង (Contact Person)', contactCtrl),
                const SizedBox(height: 12),
                _buildField(isDark, 'លេខទូរស័ព្ទ (Phone Number)', phoneCtrl),
                const SizedBox(height: 12),
                _buildField(isDark, 'អាសយដ្ឋាន (Address)', addressCtrl),
                const SizedBox(height: 12),
                _buildField(isDark, 'ចំណាំ (Note)', noteCtrl, maxLines: 2),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('បោះបង់'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (businessCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('សូមបញ្ចូលឈ្មោះអាជីវកម្មរបស់អ្នកផ្គត់ផ្គង់')),
                );
                return;
              }
              setState(() {
                if (existing != null) {
                  existing.businessName = businessCtrl.text.trim();
                  existing.contactName = contactCtrl.text.trim();
                  existing.phone = phoneCtrl.text.trim();
                  existing.address = addressCtrl.text.trim();
                  existing.note = noteCtrl.text.trim();
                } else {
                  _suppliers.insert(
                    0,
                    SupplierItem(
                      id: 'SUP-00${_suppliers.length + 1}',
                      businessName: businessCtrl.text.trim(),
                      contactName: contactCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      address: addressCtrl.text.trim(),
                      note: noteCtrl.text.trim(),
                    ),
                  );
                }
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(existing == null ? 'បានបន្ថែមអ្នកផ្គត់ផ្គង់ដោយជោគជ័យ' : 'បានកែប្រែទិន្នន័យរួចរាល់')),
              );
            },
            child: Text(existing == null ? 'រក្សាទុក' : 'កែប្រែ'),
          ),
        ],
      ),
    );
  }

  Widget _buildField(bool isDark, String label, TextEditingController ctrl, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkText : AppColors.lightText),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: isDark ? AppColors.darkBg : Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final isDark = themeProv.isDarkMode;
    final totalCount = _suppliers.length;
    final withPhoneCount = _suppliers.where((s) => s.phone.isNotEmpty).length;

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
                      'PROCUREMENT / លទ្ធកម្ម',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'បញ្ជីអ្នកផ្គត់ផ្គង់ (Suppliers)',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'គ្រប់គ្រងព័ត៌មានក្រុមហ៊ុន និងដៃគូផ្គត់ផ្គង់ទំនិញចូលម៉ាត',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _openAddEditSupplierModal(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('បន្ថែមអ្នកផ្គត់ផ្គង់ (Add Supplier)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 2 Stat KPI Cards (matching Kambuja-POS SupplierList.jsx)
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    isDark,
                    title: 'អ្នកផ្គត់ផ្គង់សរុប (Total Suppliers)',
                    value: '$totalCount',
                    desc: 'ចំនួនអ្នកផ្គត់ផ្គង់សរុបដែលបានចុះឈ្មោះក្នុងប្រព័ន្ធ។',
                    icon: Icons.business,
                    iconColor: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKpiCard(
                    isDark,
                    title: 'មានលេខទូរស័ព្ទ (With Contact)',
                    value: '$withPhoneCount',
                    desc: 'ចំនួនអ្នកផ្គត់ផ្គង់ដែលមានព័ត៌មានលេខទូរស័ព្ទត្រឹមត្រូវ។',
                    icon: Icons.phone_in_talk,
                    iconColor: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Table Container
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  // Toolbar Filters
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (v) => setState(() => _searchQuery = v),
                            style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkText : AppColors.lightText),
                            decoration: InputDecoration(
                              hintText: 'ស្វែងរកតាមឈ្មោះក្រុមហ៊ុន ឬលេខទូរស័ព្ទ...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              isDense: true,
                              filled: true,
                              fillColor: isDark ? AppColors.darkBg : Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilterChip(
                          selected: _onlyWithPhone,
                          onSelected: (val) => setState(() => _onlyWithPhone = val),
                          label: const Text('មានលេខទូរស័ព្ទ'),
                          avatar: const Icon(Icons.phone, size: 16),
                          selectedColor: AppColors.primary.withValues(alpha: 0.15),
                          checkmarkColor: AppColors.primary,
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
                        dataRowMinHeight: 52,
                        dataRowMaxHeight: 64,
                        columns: const [
                          DataColumn(label: Text('ឈ្មោះក្រុមហ៊ុន / អាជីវកម្ម', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('អ្នកទំនាក់ទំនង', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('លេខទូរស័ព្ទ', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('អាសយដ្ឋាន', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('ចំណាំ', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('សកម្មភាព', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: _filteredSuppliers.map((sup) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      sup.businessName,
                                      style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? AppColors.darkText : AppColors.lightText),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(Text(sup.contactName)),
                              DataCell(
                                sup.phone.isNotEmpty
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.phone_outlined, size: 14, color: Colors.green),
                                          const SizedBox(width: 4),
                                          Text(sup.phone, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      )
                                    : const Text('-', style: TextStyle(color: Colors.grey)),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 200,
                                  child: Text(sup.address, overflow: TextOverflow.ellipsis),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 220,
                                  child: Text(
                                    sup.note.isNotEmpty ? sup.note : '-',
                                    style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                                      tooltip: 'កែប្រែ',
                                      onPressed: () => _openAddEditSupplierModal(sup),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                      tooltip: 'លុប',
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('បញ្ជាក់ការលុប'),
                                            content: Text('តើអ្នកពិតជាចង់លុប "${sup.businessName}" មែនទេ?'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('បោះបង់')),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                onPressed: () {
                                                  setState(() => _suppliers.remove(sup));
                                                  Navigator.pop(ctx);
                                                },
                                                child: const Text('លុបចេញ', style: TextStyle(color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        );
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
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkText : AppColors.lightText),
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
