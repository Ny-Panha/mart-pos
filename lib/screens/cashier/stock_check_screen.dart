import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class StockCheckScreen extends StatefulWidget {
  const StockCheckScreen({super.key});

  @override
  State<StockCheckScreen> createState() => _StockCheckScreenState();
}

class _StockCheckScreenState extends State<StockCheckScreen> {
  final TextEditingController _searchController = TextEditingController();
  final currencyUSD = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
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

  Widget _buildStockStatusBadge(int stockQty) {
    if (stockQty <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'អស់ស្តុក',
          style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );
    } else if (stockQty <= 5) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'ជិតអស់ស្តុក',
          style: TextStyle(color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.emerald.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'មានក្នុងស្តុក',
          style: TextStyle(color: AppColors.emerald, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );
    }
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
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) || p.barcode.contains(q);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header (Matching StockCheck.jsx header)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ពិនិត្យស្តុកទំនិញ (Stock Check)',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'តាមដាន និងពិនិត្យចំនួនស្តុកទំនិញជាក់ស្តែងក្នុងម៉ាត',
                    style: TextStyle(fontSize: 13, color: mutedText),
                  ),
                ],
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
                onPressed: () {
                  setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search Bar
          SizedBox(
            width: 320,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ស្វែងរកតាមឈ្មោះ ឬកូដទំនិញ...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: bgColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),
          const SizedBox(height: 20),

          // Data Table Card (Matching StockCheck.jsx table)
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
                    DataColumn(label: Text('តម្លៃលក់', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('ស្តុកបច្ចុប្បន្ន', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('ស្ថានភាព', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: filteredProducts.map((p) {
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
                        DataCell(
                          Text(p.category),
                        ),
                        DataCell(
                          Text(
                            currencyUSD.format(p.sellingPrice),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${p.stockQty} ${p.unit}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: p.stockQty <= 5 ? Colors.red : textColor,
                            ),
                          ),
                        ),
                        DataCell(_buildStockStatusBadge(p.stockQty)),
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
