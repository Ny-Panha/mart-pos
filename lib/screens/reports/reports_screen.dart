import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final isDark = themeProv.isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
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
                      'INSIGHTS & ANALYTICS / របាយការណ៍ និងស្ថិតិ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'របាយការណ៍អាជីវកម្ម (Business Reports)',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'តាមដានការលក់ ស្តុក ចំណេញដុល និងទំនិញលក់ដាច់បំផុត',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Tab Bar matching 4 reports in Kambuja-POS
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.primary,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.receipt_long, size: 18), text: 'របាយការណ៍លក់ (Sales)'),
                  Tab(icon: Icon(Icons.inventory, size: 18), text: 'របាយការណ៍ស្តុក (Stock)'),
                  Tab(icon: Icon(Icons.trending_up, size: 18), text: 'ប្រាក់ចំណេញ (Profit)'),
                  Tab(icon: Icon(Icons.local_fire_department, size: 18), text: 'លក់ដាច់បំផុត (Best Sellers)'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSalesReportTab(isDark),
                  _buildStockReportTab(isDark),
                  _buildProfitReportTab(isDark),
                  _buildBestSellersTab(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Sales Report Tab (SaleReport.jsx)
  Widget _buildSalesReportTab(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildMetricCard(isDark, 'ចំនួនការលក់សរុប (Sales)', '48 ប្រតិបត្តិការ', 'ចំនួនប្រតិបត្តិការលក់សរុបក្នុងថ្ងៃនេះ', Icons.receipt, Colors.blue)),
              const SizedBox(width: 14),
              Expanded(child: _buildMetricCard(isDark, 'ចំណូលសរុប (Total Revenue)', '\$1,245.80', 'ទំហំទឹកប្រាក់សរុបដែលបានមកពីការលក់', Icons.attach_money, const Color(0xFF10B981))),
              const SizedBox(width: 14),
              Expanded(child: _buildMetricCard(isDark, 'ខុសគ្នាបិទវេន (Shift Diff)', '+\$0.00', 'ភាពខុសគ្នារវាងប្រាក់រំពឹងទុក និងរាប់ជាក់ស្តែង', Icons.balance, Colors.orange)),
            ],
          ),
          const SizedBox(height: 20),
          _buildCardContainer(
            isDark,
            title: 'ប្រតិបត្តិការលក់ថ្មីៗ (Recent Transactions)',
            child: DataTable(
              headingRowHeight: 44,
              columns: const [
                DataColumn(label: Text('វិក្កយបត្រ (Invoice)')),
                DataColumn(label: Text('កាលបរិច្ឆេទ')),
                DataColumn(label: Text('បេឡាករ (Cashier)')),
                DataColumn(label: Text('ការទូទាត់ (Method)')),
                DataColumn(label: Text('ទឹកប្រាក់សរុប (\$)')),
              ],
              rows: [
                _buildSaleRow('INV-20261007-001', '16:45', 'នី បញ្ញា', 'ABA KHQR', '\$24.50'),
                _buildSaleRow('INV-20261007-002', '16:20', 'នី បញ្ញា', 'CASH (សាច់ប្រាក់)', '\$12.00'),
                _buildSaleRow('INV-20261007-003', '15:55', 'គក់ ស្រីផ្កាយ', 'ABA KHQR', '\$45.80'),
                _buildSaleRow('INV-20261007-004', '15:10', 'គក់ ស្រីផ្កាយ', 'CASH (សាច់ប្រាក់)', '\$8.25'),
                _buildSaleRow('INV-20261007-005', '14:30', 'នី បញ្ញា', 'ABA KHQR', '\$19.75'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildSaleRow(String inv, String time, String cashier, String method, String total) {
    return DataRow(
      cells: [
        DataCell(Text(inv, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(time)),
        DataCell(Text(cashier)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: method.contains('KHQR') ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              method,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: method.contains('KHQR') ? Colors.red : Colors.green,
              ),
            ),
          ),
        ),
        DataCell(Text(total, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
      ],
    );
  }

  // 2. Stock Report Tab (StockReport.jsx)
  Widget _buildStockReportTab(bool isDark) {
    final prodProv = Provider.of<ProductProvider>(context);
    final products = prodProv.products;
    final totalValue = products.fold<double>(0, (sum, p) => sum + (p.costPrice * p.stock));
    final totalRetailValue = products.fold<double>(0, (sum, p) => sum + (p.sellPrice * p.stock));

    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildMetricCard(isDark, 'តម្លៃទុនស្តុក (Cost Valuation)', '\$${totalValue.toStringAsFixed(2)}', 'ទុនសរុបនៃទំនិញក្នុងស្តុកគិតតាមតម្លៃដើម', Icons.account_balance_wallet, Colors.blue)),
              const SizedBox(width: 14),
              Expanded(child: _buildMetricCard(isDark, 'តម្លៃលក់សរុប (Retail Value)', '\$${totalRetailValue.toStringAsFixed(2)}', 'ទំហំលក់រំពឹងទុកប្រសិនបើលក់អស់ស្តុក', Icons.payments, const Color(0xFF10B981))),
              const SizedBox(width: 14),
              Expanded(child: _buildMetricCard(isDark, 'ទំនិញជិតអស់ (Low Stock Alert)', '${products.where((p) => p.isLowStock).length} មុខ', 'ទំនិញដែលត្រូវបញ្ជាទិញបំពេញបន្ថែម', Icons.warning, Colors.orange)),
            ],
          ),
          const SizedBox(height: 20),
          _buildCardContainer(
            isDark,
            title: 'ស្ថានភាពស្តុកទំនិញតាមមុខទំនិញ (Product Stock Status)',
            child: DataTable(
              headingRowHeight: 44,
              columns: const [
                DataColumn(label: Text('មុខទំនិញ')),
                DataColumn(label: Text('ប្រភេទ')),
                DataColumn(label: Text('ស្តុកនៅសល់')),
                DataColumn(label: Text('តម្លៃដើម')),
                DataColumn(label: Text('ទុនក្នុងស្តុកសរុប')),
              ],
              rows: products.take(6).map((p) {
                return DataRow(
                  cells: [
                    DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(p.category)),
                    DataCell(Text('${p.stock} ${p.unit}', style: TextStyle(fontWeight: FontWeight.bold, color: p.isLowStock ? Colors.orange : Colors.green))),
                    DataCell(Text('\$${p.costPrice.toStringAsFixed(2)}')),
                    DataCell(Text('\$${(p.costPrice * p.stock).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Profit Report Tab (ProfitReport.jsx)
  Widget _buildProfitReportTab(bool isDark) {
    const totalRev = 1245.80;
    const totalCost = 872.00;
    const grossProfit = totalRev - totalCost;
    const margin = (grossProfit / totalRev) * 100;

    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildMetricCard(isDark, 'ចំណូលសរុប (Total Revenue)', '\$${totalRev.toStringAsFixed(2)}', 'ទំហំលក់សរុប', Icons.arrow_upward, Colors.blue)),
              const SizedBox(width: 14),
              Expanded(child: _buildMetricCard(isDark, 'ថ្លៃដើមទំនិញ (Cost of Goods)', '\$${totalCost.toStringAsFixed(2)}', 'ថ្លៃដើមទិញចូលសរុប', Icons.arrow_downward, Colors.orange)),
              const SizedBox(width: 14),
              Expanded(child: _buildMetricCard(isDark, 'ប្រាក់ចំណេញដុល (Gross Profit)', '\$${grossProfit.toStringAsFixed(2)}', 'ចំណេញដុល (Revenue - Cost)', Icons.trending_up, const Color(0xFF10B981))),
              const SizedBox(width: 14),
              Expanded(child: _buildMetricCard(isDark, 'អត្រាចំណេញ (Margin %)', '${margin.toStringAsFixed(1)}%', 'ភាគរយចំណេញធៀបចំណូល', Icons.pie_chart, Colors.purple)),
            ],
          ),
          const SizedBox(height: 20),
          _buildCardContainer(
            isDark,
            title: 'ការវិភាគចំណេញតាមប្រភេទមុខទំនិញ (Profit by Category)',
            child: DataTable(
              headingRowHeight: 44,
              columns: const [
                DataColumn(label: Text('ប្រភេទ (Category)')),
                DataColumn(label: Text('ចំណូលសរុប')),
                DataColumn(label: Text('ថ្លៃដើម')),
                DataColumn(label: Text('ប្រាក់ចំណេញ')),
                DataColumn(label: Text('Margin (%)')),
              ],
              rows: const [
                DataRow(cells: [
                  DataCell(Text('ភេសជ្ជៈ (Beverages)', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text('\$520.00')),
                  DataCell(Text('\$360.00')),
                  DataCell(Text('\$160.00', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                  DataCell(Text('30.8%', style: TextStyle(fontWeight: FontWeight.bold))),
                ]),
                DataRow(cells: [
                  DataCell(Text('អាហារសម្រន់ (Snacks)', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text('\$340.50')),
                  DataCell(Text('\$235.00')),
                  DataCell(Text('\$105.50', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                  DataCell(Text('31.0%', style: TextStyle(fontWeight: FontWeight.bold))),
                ]),
                DataRow(cells: [
                  DataCell(Text('ផលិតផលប្រចាំថ្ងៃ (Daily)', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text('\$385.30')),
                  DataCell(Text('\$277.00')),
                  DataCell(Text('\$108.30', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                  DataCell(Text('28.1%', style: TextStyle(fontWeight: FontWeight.bold))),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. Best Sellers Tab (BestSellerReport.jsx)
  Widget _buildBestSellersTab(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildRankCard(isDark, '🥇 លេខ ១ (Rank 1)', 'Coca-Cola Original 330ml', '142 កំប៉ុង', '\$99.40 ចំណូល', Colors.amber),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildRankCard(isDark, '🥈 លេខ ២ (Rank 2)', 'ទឹកបរិសុទ្ធ Dasani 500ml', '118 ដប', '\$41.30 ចំណូល', Colors.grey.shade400),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildRankCard(isDark, '🥉 លេខ ៣ (Rank 3)', 'មីជាតិ សាច់ជ្រូកចិញ្ច្រាំ', '95 កញ្ចប់', '\$33.25 ចំណូល', Colors.brown.shade400),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildCardContainer(
            isDark,
            title: 'តារាងចំណាត់ថ្នាក់ទំនិញលក់ដាច់បំផុត (Top Selling Products)',
            child: DataTable(
              headingRowHeight: 44,
              columns: const [
                DataColumn(label: Text('ល.រ (Rank)')),
                DataColumn(label: Text('មុខទំនិញ (Product)')),
                DataColumn(label: Text('ប្រភេទ')),
                DataColumn(label: Text('បរិមាណលក់បាន (Units)')),
                DataColumn(label: Text('ចំណូលលក់សរុប (\$)')),
              ],
              rows: const [
                DataRow(cells: [
                  DataCell(Text('🥇 #1', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                  DataCell(Text('Coca-Cola Original 330ml', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text('ភេសជ្ជៈ')),
                  DataCell(Text('142 កំប៉ុង', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                  DataCell(Text('\$99.40', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                ]),
                DataRow(cells: [
                  DataCell(Text('🥈 #2', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                  DataCell(Text('ទឹកបរិសុទ្ធ Dasani 500ml', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text('ភេសជ្ជៈ')),
                  DataCell(Text('118 ដប', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                  DataCell(Text('\$41.30', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                ]),
                DataRow(cells: [
                  DataCell(Text('🥉 #3', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                  DataCell(Text('មីជាតិ សាច់ជ្រូកចិញ្ច្រាំ', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text('អាហារសម្រន់')),
                  DataCell(Text('95 កញ្ចប់', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                  DataCell(Text('\$33.25', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                ]),
                DataRow(cells: [
                  DataCell(Text('#4', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text('ទឹកដោះគោស្រស់ 1L', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text('ភេសជ្ជៈ')),
                  DataCell(Text('64 ប្រអប់', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                  DataCell(Text('\$115.20', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                ]),
                DataRow(cells: [
                  DataCell(Text('#5', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text('នំដំឡូងបារាំង Lay\'s Classic', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text('អាហារសម្រន់')),
                  DataCell(Text('58 កញ្ចប់', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                  DataCell(Text('\$72.50', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankCard(bool isDark, String rank, String name, String units, String revenue, Color badgeColor) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(rank, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              CircleAvatar(radius: 12, backgroundColor: badgeColor.withValues(alpha: 0.2), child: Icon(Icons.star, size: 14, color: badgeColor)),
            ],
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(units, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          Text(revenue, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText)),
        ],
      ),
    );
  }

  Widget _buildCardContainer(bool isDark, {required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 320),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(bool isDark, String title, String value, String desc, IconData icon, Color color) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText)),
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 18)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkText : AppColors.lightText)),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText)),
        ],
      ),
    );
  }
}
