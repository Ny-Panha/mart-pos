import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditCategoryDialog([String? existingCategory]) {
    final nameCtrl = TextEditingController(text: existingCategory ?? '');
    final descCtrl = TextEditingController(text: existingCategory != null ? 'ប្រភេទមុខទំនិញសម្រាប់លក់ក្នុងម៉ាត' : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(existingCategory == null ? Icons.add_circle : Icons.edit, color: AppColors.cyan),
            const SizedBox(width: 8),
            Text(existingCategory == null ? 'បន្ថែមប្រភេទថ្មី (Add Category)' : 'កែសម្រួលប្រភេទ (Edit Category)'),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'ឈ្មោះប្រភេទ (Category Name) *', hintText: 'ឧ. ភេសជ្ជៈ'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'ការពិពណ៌នា (Description)', hintText: 'ព័ត៌មានលម្អិត...'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('បោះបង់')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.cyan, foregroundColor: Colors.white),
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('បានរក្សាទុកប្រភេទដោយជោគជ័យ!'), backgroundColor: AppColors.emerald),
              );
            },
            child: const Text('រក្សាទុក (Save)'),
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

    final categories = productProv.categories.where((c) => c != 'ទាំងអស់').toList();
    final int totalCategories = categories.length;
    final int activeCategories = categories.length;
    final int productsLinked = productProv.allProducts.length;

    final filtered = categories.where((c) => _searchQuery.isEmpty || c.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header (Matching CategoryList.jsx header) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CATALOG',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.cyan, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ប្រភេទមុខទំនិញ (Categories)',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'គ្រប់គ្រង និងបែងចែកប្រភេទមុខទំនិញក្នុងម៉ាតដើម្បីងាយស្រួលស្វែងរក',
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
                label: const Text('បន្ថែមប្រភេទថ្មី (Add Category)', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _showAddEditCategoryDialog(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── 3 Summary Cards (Matching CategoryList.jsx stat cards) ──
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 768;
              final cardWidth = isWide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildStatCard(
                    title: 'ប្រភេទសរុប (Total Categories)',
                    value: '$totalCategories ប្រភេទ',
                    desc: 'ចំនួនប្រភេទផលិតផលសរុបទាំងអស់។',
                    icon: Icons.category_outlined,
                    iconColor: Colors.blue,
                    iconBg: Colors.blue.withValues(alpha: 0.15),
                    width: cardWidth,
                    cardBg: bgColor,
                    borderColor: borderColor,
                    textColor: textColor,
                    mutedText: mutedText,
                  ),
                  _buildStatCard(
                    title: 'ប្រភេទសកម្ម (Active Categories)',
                    value: '$activeCategories សកម្ម',
                    desc: 'ប្រភេទផលិតផលដែលកំពុងប្រើប្រាស់សកម្ម។',
                    icon: Icons.check_circle_outline,
                    iconColor: AppColors.emerald,
                    iconBg: AppColors.emerald.withValues(alpha: 0.15),
                    width: cardWidth,
                    cardBg: bgColor,
                    borderColor: borderColor,
                    textColor: textColor,
                    mutedText: mutedText,
                  ),
                  _buildStatCard(
                    title: 'ទំនិញភ្ជាប់ (Products Linked)',
                    value: '$productsLinked មុខ',
                    desc: 'ចំនួនផលិតផលដែលបានភ្ជាប់ទៅកាន់ប្រភេទទាំងនេះ។',
                    icon: Icons.link,
                    iconColor: Colors.indigo,
                    iconBg: Colors.indigo.withValues(alpha: 0.15),
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
                        hintText: 'ស្វែងរកឈ្មោះប្រភេទ...',
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
                        DataColumn(label: Text('ឈ្មោះប្រភេទ', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ចំនួនទំនិញក្នុងប្រភេទ', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ស្ថានភាព', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('សកម្មភាព', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: filtered.map((cat) {
                        final count = productProv.allProducts.where((p) => p.category == cat).length;
                        return DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  const Icon(Icons.folder_outlined, size: 20, color: AppColors.cyan),
                                  const SizedBox(width: 8),
                                  Text(cat, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            DataCell(Text('$count មុខទំនិញ', style: TextStyle(color: mutedText))),
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
                                    onPressed: () => _showAddEditCategoryDialog(cat),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                    tooltip: 'លុប',
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('មិនអាចលុបប្រភេទ "$cat" ព្រោះមានទំនិញកំពុងប្រើប្រាស់')),
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
