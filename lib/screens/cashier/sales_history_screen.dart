import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/sale_model.dart';
import '../../providers/theme_provider.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';
import '../pos/receipt_dialog.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  final currencyUSD = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final isDark = themeProv.isDarkMode;

    final bgColor = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedText = isDark ? AppColors.darkMutedText : AppColors.lightMutedText;

    return StreamBuilder<List<SaleModel>>(
      stream: _firebaseService.streamSales(),
      builder: (context, snapshot) {
        final sales = snapshot.data ?? [];

        final filteredSales = sales.where((s) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return s.invoiceNo.toLowerCase().contains(q) ||
              s.cashierName.toLowerCase().contains(q) ||
              s.customerName.toLowerCase().contains(q);
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header (Matching SalesHistory.jsx)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ប្រវត្តិវិក្កយបត្រ (Sales History)',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ពិនិត្យមើលប្រតិបត្តិការលក់ទាំងអស់ដែលបានធ្វើរួច',
                        style: TextStyle(fontSize: 13, color: mutedText),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'សរុប: ${filteredSales.length} វិក្កយបត្រ',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                    ),
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
                    hintText: 'ស្វែងរកតាមលេខវិក្កយបត្រ ឬអ្នកគិតលុយ...',
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

              // Table Card
              Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: filteredSales.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(48.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 48, color: mutedText.withValues(alpha: 0.5)),
                                const SizedBox(height: 12),
                                Text('មិនទាន់មានប្រវត្តិវិក្កយបត្រនៅឡើយទេ', style: TextStyle(color: mutedText)),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              isDark ? AppColors.darkBg : Colors.grey.shade50,
                            ),
                            columns: const [
                              DataColumn(label: Text('លេខវិក្កយបត្រ', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('កាលបរិច្ឆេទ', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('អ្នកគិតលុយ', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('អតិថិជន', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('តម្លៃសរុប', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('វិធីសាស្ត្រ', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('សកម្មភាព', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: filteredSales.map((sale) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      sale.invoiceNo,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ),
                                  DataCell(
                                    Text(dateFormat.format(sale.createdAt), style: const TextStyle(fontSize: 12)),
                                  ),
                                  DataCell(
                                    Text(sale.cashierName),
                                  ),
                                  DataCell(
                                    Text(sale.customerName),
                                  ),
                                  DataCell(
                                    Text(
                                      currencyUSD.format(sale.totalUSD),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.emerald),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        sale.paymentMethod,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(Icons.visibility_outlined, size: 20),
                                      tooltip: 'មើលវិក្កយបត្រ',
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => ReceiptDialog(sale: sale),
                                        );
                                      },
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
      },
    );
  }
}
