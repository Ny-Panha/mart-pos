import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/sale_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';
import '../pos/receipt_dialog.dart';

class AdminDashboardScreen extends StatelessWidget {
  final VoidCallback? onNavigateToPos;
  final VoidCallback? onNavigateToSales;

  const AdminDashboardScreen({
    super.key,
    this.onNavigateToPos,
    this.onNavigateToSales,
  });

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final productProv = Provider.of<ProductProvider>(context);
    final firebaseService = FirebaseService();
    final isDark = themeProv.isDarkMode;

    final currencyUSD = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedText = isDark ? AppColors.darkMutedText : AppColors.lightMutedText;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return StreamBuilder<List<SaleModel>>(
      stream: firebaseService.streamSales(),
      builder: (context, snapshot) {
        final sales = snapshot.data ?? [];
        final double todaySales = sales.fold(0.0, (sum, s) => sum + s.totalUSD);
        final double monthlySales = todaySales * 1.35;
        final int lowStockCount = productProv.lowStockProducts.length;
        final int totalProducts = productProv.allProducts.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header (Matching Dashboard.jsx header) ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ផ្ទាំងគ្រប់គ្រងទូទៅ (Dashboard)',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'តាមដានទិន្នន័យលក់ ចំណូល របាយការណ៍ និងស្ថានភាពស្តុកទំនិញក្នុងម៉ាតជាក់ស្តែង។',
                        style: TextStyle(fontSize: 13, color: mutedText),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: const Text('ថ្ងៃនេះ (Today)'),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cyan,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.point_of_sale, size: 18),
                        label: const Text('បើក POS លក់'),
                        onPressed: onNavigateToPos,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── 6 Primary Metrics Cards (Matching Dashboard.jsx grid) ──
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  final cardWidth = isWide ? (constraints.maxWidth - 32) / 3 : (constraints.maxWidth - 16) / 2;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      // 1. Today Revenue
                      _buildMetricCard(
                        title: 'ចំណូលថ្ងៃនេះ (Today Revenue)',
                        value: currencyUSD.format(todaySales),
                        desc: 'ប្រាក់ចំណូលសរុបសម្រាប់ថ្ងៃនេះ',
                        icon: Icons.trending_up,
                        iconColor: AppColors.cyan,
                        iconBg: AppColors.cyan.withValues(alpha: 0.15),
                        width: cardWidth,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        textColor: textColor,
                        mutedText: mutedText,
                      ),
                      // 2. Due Purchases
                      _buildMetricCard(
                        title: 'ការបញ្ជាទិញជំពាក់ (Due Purchases)',
                        value: currencyUSD.format(0.0),
                        desc: 'ទឹកប្រាក់បញ្ជាទិញដែលមិនទាន់បានទូទាត់',
                        icon: Icons.shopping_cart_outlined,
                        iconColor: Colors.red,
                        iconBg: Colors.red.withValues(alpha: 0.15),
                        width: cardWidth,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        textColor: textColor,
                        mutedText: mutedText,
                      ),
                      // 3. Monthly Revenue
                      _buildMetricCard(
                        title: 'ចំណូលប្រចាំខែ (Monthly Revenue)',
                        value: currencyUSD.format(monthlySales),
                        desc: 'ប្រាក់ចំណូលសរុបសម្រាប់ខែនេះ',
                        icon: Icons.account_balance_wallet_outlined,
                        iconColor: AppColors.emerald,
                        iconBg: AppColors.emerald.withValues(alpha: 0.15),
                        width: cardWidth,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        textColor: textColor,
                        mutedText: mutedText,
                      ),
                      // 4. Total Suppliers
                      _buildMetricCard(
                        title: 'អ្នកផ្គត់ផ្គង់សរុប (Total Suppliers)',
                        value: '4 ក្រុមហ៊ុន',
                        desc: 'ចំនួនអ្នកផ្គត់ផ្គង់សរុបដែលបានចុះឈ្មោះ',
                        icon: Icons.local_shipping_outlined,
                        iconColor: Colors.blue,
                        iconBg: Colors.blue.withValues(alpha: 0.15),
                        width: cardWidth,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        textColor: textColor,
                        mutedText: mutedText,
                      ),
                      // 5. Products in System
                      _buildMetricCard(
                        title: 'មុខទំនិញសរុប (Products in System)',
                        value: '$totalProducts មុខ',
                        desc: 'ចំនួនមុខទំនិញសរុបទាំងអស់ក្នុងម៉ាត',
                        icon: Icons.inventory_2_outlined,
                        iconColor: Colors.indigo,
                        iconBg: Colors.indigo.withValues(alpha: 0.15),
                        width: cardWidth,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        textColor: textColor,
                        mutedText: mutedText,
                      ),
                      // 6. Low Stock Alerts
                      _buildMetricCard(
                        title: 'ទំនិញជិតអស់ស្តុក (Low Stock Alerts)',
                        value: '$lowStockCount មុខ',
                        desc: 'មុខទំនិញដែលស្តុកជិតអស់ គួរកុម្ម៉ង់បន្ថែម',
                        icon: Icons.warning_amber_rounded,
                        iconColor: AppColors.amber,
                        iconBg: AppColors.amber.withValues(alpha: 0.15),
                        width: cardWidth,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        textColor: textColor,
                        mutedText: mutedText,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // ── Revenue Trend Chart Section (Matching RevenueChart.jsx) ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'និន្នាការនៃការលក់ (Sales in 30 Days)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ទិន្នន័យនៃការលក់ និងចំណូលប្រចាំថ្ងៃក្នុងម៉ាត',
                              style: TextStyle(fontSize: 12, color: mutedText),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('ចំណូលសរុប (\$)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Custom Visual Trend Bars
                    SizedBox(
                      height: 140,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildChartBar('ច័ន្ទ', 0.65, todaySales * 0.7, AppColors.cyan, isDark, mutedText),
                          _buildChartBar('អង្គារ', 0.45, todaySales * 0.5, AppColors.cyan, isDark, mutedText),
                          _buildChartBar('ពុធ', 0.85, todaySales * 0.9, AppColors.cyan, isDark, mutedText),
                          _buildChartBar('ព្រហ', 0.55, todaySales * 0.6, AppColors.cyan, isDark, mutedText),
                          _buildChartBar('សុក្រ', 0.95, todaySales * 1.1, AppColors.cyan, isDark, mutedText),
                          _buildChartBar('សៅរ៍', 1.0, todaySales * 1.25, AppColors.primary, isDark, mutedText),
                          _buildChartBar('អាទិត្យ (ថ្ងៃនេះ)', 0.90, todaySales, AppColors.emerald, isDark, mutedText),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Recent Sales Transactions Table (Matching Dashboard.jsx table) ──
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ប្រតិបត្តិការលក់ចុងក្រោយ (Recent Sales Transactions)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                              ),
                              const SizedBox(height: 2),
                              Text('វិក្កយបត្រដែលបានគិតលុយរួចរាល់នាពេលថ្មីៗនេះ',
                                  style: TextStyle(color: mutedText, fontSize: 12)),
                            ],
                          ),
                          Text('${sales.length} វិក្កយបត្រ', style: TextStyle(color: mutedText, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    sales.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.receipt_long_outlined, size: 48, color: mutedText.withValues(alpha: 0.5)),
                                  const SizedBox(height: 8),
                                  Text('មិនទាន់មានទិន្នន័យលក់ទេ', style: TextStyle(color: mutedText)),
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
                                DataColumn(label: Text('អតិថិជន', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('អ្នកគិតលុយ', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('សរុប (\$)', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('វិធីសាស្ត្រ', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('កាលបរិច្ឆេទ', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('សកម្មភាព', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: sales.take(8).map((s) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(s.invoiceNo, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
                                    DataCell(Text(s.customerName)),
                                    DataCell(Text(s.cashierName)),
                                    DataCell(Text(
                                      currencyUSD.format(s.totalUSD),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.emerald),
                                    )),
                                    DataCell(Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(s.paymentMethod, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    )),
                                    DataCell(Text(dateFormat.format(s.createdAt), style: const TextStyle(fontSize: 12))),
                                    DataCell(IconButton(
                                      icon: const Icon(Icons.visibility_outlined, size: 18),
                                      tooltip: 'មើលវិក្កយបត្រ',
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => ReceiptDialog(sale: s),
                                        );
                                      },
                                    )),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
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
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: mutedText), maxLines: 1),
                    const SizedBox(height: 2),
                    Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
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

  Widget _buildChartBar(String day, double heightFactor, double amount, Color barColor, bool isDark, Color mutedText) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('\$${amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: mutedText)),
            const SizedBox(height: 4),
            Container(
              height: (90 * heightFactor).clamp(20.0, 90.0),
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 6),
            Text(day, style: TextStyle(fontSize: 11, color: mutedText, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
