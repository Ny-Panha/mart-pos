import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Demo staff accounts list
  final List<Map<String, String>> _staffList = [
    {
      'id': 'u1',
      'username': 'panha',
      'name': 'នី បញ្ញា',
      'role': 'ADMIN',
      'email': 'admin@bbu.edu.kh',
      'status': 'ACTIVE',
    },
    {
      'id': 'u2',
      'username': 'sreyphkay',
      'name': 'គក់ ស្រីផ្កាយ',
      'role': 'CASHIER',
      'email': 'pkay@bbu.edu.kh',
      'status': 'ACTIVE',
    },
    {
      'id': 'u3',
      'username': 'daly',
      'name': 'គុយ ដាលី',
      'role': 'CASHIER',
      'email': 'daly@bbu.edu.kh',
      'status': 'ACTIVE',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditStaffDialog([Map<String, String>? existing]) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final usernameCtrl = TextEditingController(text: existing?['username'] ?? '');
    final emailCtrl = TextEditingController(text: existing?['email'] ?? '');
    String role = existing?['role'] ?? 'CASHIER';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(existing == null ? Icons.person_add : Icons.edit, color: AppColors.cyan),
              const SizedBox(width: 8),
              Text(existing == null ? 'បន្ថែមបុគ្គលិកថ្មី (Add Staff)' : 'កែសម្រួលគណនី (Edit Staff)'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ឈ្មោះពេញ (Full Name) *')),
                const SizedBox(height: 10),
                TextField(controller: usernameCtrl, decoration: const InputDecoration(labelText: 'Username *')),
                const SizedBox(height: 10),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'អ៊ីមែល (Email) *')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'តួនាទី (Role) *'),
                  items: const [
                    DropdownMenuItem(value: 'ADMIN', child: Text('Admin (អ្នកគ្រប់គ្រង)')),
                    DropdownMenuItem(value: 'CASHIER', child: Text('Cashier (អ្នកគិតលុយ)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => role = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('បោះបង់')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.cyan, foregroundColor: Colors.white),
              onPressed: () {
                if (nameCtrl.text.isEmpty || usernameCtrl.text.isEmpty) return;
                setState(() {
                  if (existing == null) {
                    _staffList.add({
                      'id': 'u_${DateTime.now().millisecondsSinceEpoch}',
                      'username': usernameCtrl.text,
                      'name': nameCtrl.text,
                      'role': role,
                      'email': emailCtrl.text,
                      'status': 'ACTIVE',
                    });
                  } else {
                    existing['name'] = nameCtrl.text;
                    existing['username'] = usernameCtrl.text;
                    existing['email'] = emailCtrl.text;
                    existing['role'] = role;
                  }
                });
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('បានរក្សាទុកគណនីបុគ្គលិកដោយជោគជ័យ!'), backgroundColor: AppColors.emerald),
                );
              },
              child: const Text('រក្សាទុក (Save)'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final isDark = themeProv.isDarkMode;

    final bgColor = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedText = isDark ? AppColors.darkMutedText : AppColors.lightMutedText;

    final totalStaff = _staffList.length;
    final activeStaff = _staffList.where((s) => s['status'] == 'ACTIVE').length;

    final filtered = _staffList.where((s) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return (s['name'] ?? '').toLowerCase().contains(q) ||
          (s['username'] ?? '').toLowerCase().contains(q) ||
          (s['email'] ?? '').toLowerCase().contains(q);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header (Matching CashierList.jsx header) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STAFF',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.cyan, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'បុគ្គលិក និងអ្នកគិតលុយ (Staff)',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'គ្រប់គ្រងគណនីអ្នកគិតលុយ និងសិទ្ធិប្រើប្រាស់ប្រព័ន្ធលក់ក្នុងម៉ាត',
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
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('+ បន្ថែមបុគ្គលិកថ្មី (Add Staff)', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _showAddEditStaffDialog(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── 2 Summary Cards (Matching CashierList.jsx stat cards) ──
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 768;
              final cardWidth = isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildStatCard(
                    title: 'បុគ្គលិកសរុប (Total Staff)',
                    value: '$totalStaff នាក់',
                    desc: 'ចំនួនគណនីអ្នកគិតលុយ និង Admin សរុប។',
                    icon: Icons.people_outline,
                    iconColor: Colors.blue,
                    iconBg: Colors.blue.withValues(alpha: 0.15),
                    width: cardWidth,
                    cardBg: bgColor,
                    borderColor: borderColor,
                    textColor: textColor,
                    mutedText: mutedText,
                  ),
                  _buildStatCard(
                    title: 'បុគ្គលិកសកម្ម (Active Staff)',
                    value: '$activeStaff នាក់',
                    desc: 'គណនីដែលកំពុងដំណើរការក្នុងប្រព័ន្ធ។',
                    icon: Icons.verified_user_outlined,
                    iconColor: AppColors.emerald,
                    iconBg: AppColors.emerald.withValues(alpha: 0.15),
                    width: cardWidth,
                    cardBg: bgColor,
                    borderColor: borderColor,
                    textColor: textColor,
                    mutedText: mutedText,
                  ),
                ],
              );
            },
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
                        hintText: 'ស្វែងរកតាមឈ្មោះ, Username...',
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
                        DataColumn(label: Text('ឈ្មោះបុគ្គលិក', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Username', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('តួនាទី (Role)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('អ៊ីមែល', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ស្ថានភាព', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('សកម្មភាព', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: filtered.map((s) {
                        final isAdmin = s['role'] == 'ADMIN';
                        return DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: (isAdmin ? AppColors.cyan : AppColors.amber).withValues(alpha: 0.2),
                                    child: Icon(Icons.person, size: 18, color: isAdmin ? AppColors.cyan : AppColors.amber),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(s['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            DataCell(Text(s['username'] ?? '', style: TextStyle(color: mutedText))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (isAdmin ? AppColors.cyan : AppColors.amber).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  s['role'] ?? '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isAdmin ? AppColors.cyan : AppColors.amber,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text(s['email'] ?? '', style: TextStyle(color: mutedText))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.emerald.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('ACTIVE', style: TextStyle(color: AppColors.emerald, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                                    tooltip: 'កែសម្រួល',
                                    onPressed: () => _showAddEditStaffDialog(s),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                    tooltip: 'លុប',
                                    onPressed: () {
                                      setState(() => _staffList.removeWhere((item) => item['id'] == s['id']));
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

  Widget _buildStatCard({
    required String title,
    required String value,
    required String desc,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required double width,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color mutedText,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: mutedText), maxLines: 1),
                    const SizedBox(height: 2),
                    Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Text(desc, style: TextStyle(fontSize: 11, color: mutedText), maxLines: 1),
        ],
      ),
    );
  }
}
