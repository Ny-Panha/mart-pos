import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class PurchaseOrder {
  final String id;
  final String reference;
  final String supplierName;
  final DateTime orderDate;
  final double totalCost;
  double paidAmount;
  String paymentStatus; // 'paid', 'partial', 'due'
  String purchaseStatus; // 'received', 'pending', 'ordered'
  final List<String> itemsSummary;

  PurchaseOrder({
    required this.id,
    required this.reference,
    required this.supplierName,
    required this.orderDate,
    required this.totalCost,
    required this.paidAmount,
    required this.paymentStatus,
    required this.purchaseStatus,
    required this.itemsSummary,
  });

  double get dueAmount => totalCost - paidAmount;
}

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({super.key});

  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> {
  final List<PurchaseOrder> _purchases = [
    PurchaseOrder(
      id: 'PO-1001',
      reference: 'INV-COCA-902',
      supplierName: 'Cambodia Beverage Co., Ltd (Coca-Cola)',
      orderDate: DateTime.now().subtract(const Duration(days: 1)),
      totalCost: 450.00,
      paidAmount: 450.00,
      paymentStatus: 'paid',
      purchaseStatus: 'received',
      itemsSummary: ['Coca-Cola Can 330ml x 10 កេស', 'Dasani Water 500ml x 20 កេស'],
    ),
    PurchaseOrder(
      id: 'PO-1002',
      reference: 'INV-MILK-441',
      supplierName: 'Angkor Dairy Products (Angkormilk)',
      orderDate: DateTime.now().subtract(const Duration(days: 3)),
      totalCost: 280.50,
      paidAmount: 150.00,
      paymentStatus: 'partial',
      purchaseStatus: 'received',
      itemsSummary: ['ទឹកដោះគោស្រស់ 1L x 5 កេស', 'យ៉ាអួធម្មជាតិ x 4 កេស'],
    ),
    PurchaseOrder(
      id: 'PO-1003',
      reference: 'INV-FOOD-118',
      supplierName: 'Khmer Food Distribution Co.',
      orderDate: DateTime.now().subtract(const Duration(days: 4)),
      totalCost: 620.00,
      paidAmount: 0.0,
      paymentStatus: 'due',
      purchaseStatus: 'pending',
      itemsSummary: ['មីជាតិសាច់ជ្រូកចិញ្ច្រាំ x 15 កេស', 'ប្រេងឆា 1L x 8 កេស'],
    ),
    PurchaseOrder(
      id: 'PO-1004',
      reference: 'INV-UNIL-009',
      supplierName: 'Unilever Cambodia Distribution',
      orderDate: DateTime.now().subtract(const Duration(days: 7)),
      totalCost: 340.00,
      paidAmount: 340.00,
      paymentStatus: 'paid',
      purchaseStatus: 'received',
      itemsSummary: ['សាប៊ូកក់សក់ Clear x 6 កេស', 'ថ្នាំដុសធ្មេញ CloseUp x 5 កេស'],
    ),
  ];

  String _search = '';
  String _statusFilter = 'ALL';

  List<PurchaseOrder> get _filteredOrders {
    return _purchases.where((p) {
      final matchesSearch = p.reference.toLowerCase().contains(_search.toLowerCase()) ||
          p.supplierName.toLowerCase().contains(_search.toLowerCase()) ||
          p.id.toLowerCase().contains(_search.toLowerCase());
      if (!matchesSearch) return false;
      if (_statusFilter == 'DUE' && p.paymentStatus != 'due') return false;
      if (_statusFilter == 'PENDING' && p.purchaseStatus != 'pending') return false;
      return true;
    }).toList();
  }

  void _openCreatePurchaseDialog() {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final refCtrl = TextEditingController(text: 'PO-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final supplierCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final itemDescCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '🛒 បង្កើតការបញ្ជាទិញទំនិញថ្មី (New Purchase)',
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
                _buildField(isDark, 'លេខកូដបញ្ជាទិញ (Reference / PO Number)*', refCtrl),
                const SizedBox(height: 12),
                _buildField(isDark, 'ឈ្មោះអ្នកផ្គត់ផ្គង់ (Supplier)*', supplierCtrl),
                const SizedBox(height: 12),
                _buildField(isDark, 'តម្លៃទិញសរុប (\$ Total Cost)*', costCtrl, isNumber: true),
                const SizedBox(height: 12),
                _buildField(isDark, 'មុខទំនិញដែលបានបញ្ជាទិញ (Items Description)', itemDescCtrl, maxLines: 2),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('បោះបង់')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final cost = double.tryParse(costCtrl.text.trim()) ?? 0;
              if (supplierCtrl.text.trim().isEmpty || cost <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('សូមបញ្ចូលអ្នកផ្គត់ផ្គង់ និងតម្លៃទិញឱ្យបានត្រឹមត្រូវ')),
                );
                return;
              }
              setState(() {
                _purchases.insert(
                  0,
                  PurchaseOrder(
                    id: 'PO-${_purchases.length + 1001}',
                    reference: refCtrl.text.trim(),
                    supplierName: supplierCtrl.text.trim(),
                    orderDate: DateTime.now(),
                    totalCost: cost,
                    paidAmount: 0.0,
                    paymentStatus: 'due',
                    purchaseStatus: 'pending',
                    itemsSummary: [itemDescCtrl.text.trim().isNotEmpty ? itemDescCtrl.text.trim() : 'ទំនិញស្តុកថ្មី'],
                  ),
                );
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('បានបង្កើតការបញ្ជាទិញទំនិញជោគជ័យ')),
              );
            },
            child: const Text('បង្កើតការបញ្ជាទិញ'),
          ),
        ],
      ),
    );
  }

  void _openPaymentDialog(PurchaseOrder order) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final payCtrl = TextEditingController(text: order.dueAmount.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '💳 កត់ត្រាការទូទាត់ប្រាក់ (${order.reference})',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? AppColors.darkText : AppColors.lightText),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('តម្លៃសរុប: \$${order.totalCost.toStringAsFixed(2)} | បានបង់: \$${order.paidAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 6),
            Text(
              'នៅខ្វះ (Due): \$${order.dueAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 16),
            _buildField(isDark, 'ចំនួនទឹកប្រាក់ដែលត្រូវទូទាត់បន្ថែម (\$)', payCtrl, isNumber: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('បោះបង់')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            onPressed: () {
              final amount = double.tryParse(payCtrl.text) ?? 0;
              if (amount <= 0) return;
              setState(() {
                order.paidAmount = (order.paidAmount + amount).clamp(0.0, order.totalCost);
                if (order.paidAmount >= order.totalCost) {
                  order.paymentStatus = 'paid';
                } else {
                  order.paymentStatus = 'partial';
                }
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('បានកត់ត្រាការទូទាត់ប្រាក់ដោយជោគជ័យ')),
              );
            },
            child: const Text('បញ្ជាក់ការបង់ប្រាក់'),
          ),
        ],
      ),
    );
  }

  void _openStatusDialog(PurchaseOrder order) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    String selectedStatus = order.purchaseStatus;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('🚚 ប្តូរស្ថានភាពដឹកជញ្ជូន (${order.reference})'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('បានទទួលទំនិញពេញលេញ (Received)'),
                value: 'received',
                groupValue: selectedStatus,
                onChanged: (v) => setModalState(() => selectedStatus = v!),
              ),
              RadioListTile<String>(
                title: const Text('កំពុងរង់ចាំទំនិញ (Pending)'),
                value: 'pending',
                groupValue: selectedStatus,
                onChanged: (v) => setModalState(() => selectedStatus = v!),
              ),
              RadioListTile<String>(
                title: const Text('បានបញ្ជាទិញរួចរាល់ (Ordered)'),
                value: 'ordered',
                groupValue: selectedStatus,
                onChanged: (v) => setModalState(() => selectedStatus = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('បោះបង់')),
            ElevatedButton(
              onPressed: () {
                setState(() => order.purchaseStatus = selectedStatus);
                Navigator.pop(ctx);
              },
              child: const Text('រក្សាទុក'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(bool isDark, String label, TextEditingController ctrl, {bool isNumber = false, int maxLines = 1}) {
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
          keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
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

    final purchaseCount = _purchases.length;
    final totalCost = _purchases.fold<double>(0, (sum, item) => sum + item.totalCost);
    final dueCount = _purchases.where((item) => item.paymentStatus == 'due').length;
    final pendingCount = _purchases.where((item) => item.purchaseStatus == 'pending').length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROCUREMENT / លទ្ធកម្មទំនិញ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ការបញ្ជាទិញទំនិញចូលស្តុក (Purchases)',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'កត់ត្រាការទិញទំនិញ តាមដានបំណុល និងការដឹកជញ្ជូនចូលឃ្លាំង',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _openCreatePurchaseDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text('បញ្ជាទិញថ្មី (New Purchase)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 4 Stat KPI Cards (matching Kambuja-POS PurchaseList.jsx)
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    isDark,
                    title: 'ការបញ្ជាទិញសរុប (Purchases)',
                    value: '$purchaseCount',
                    desc: 'ចំនួនបញ្ជាទិញសរុបដែលបានកត់ត្រាក្នុងប្រព័ន្ធ។',
                    icon: Icons.shopping_cart_outlined,
                    iconColor: Colors.blue,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildKpiCard(
                    isDark,
                    title: 'ចំណាយសរុប (Total Cost)',
                    value: '\$${totalCost.toStringAsFixed(2)}',
                    desc: 'ទំហំទឹកប្រាក់សរុបនៃការបញ្ជាទិញទាំងអស់។',
                    icon: Icons.attach_money,
                    iconColor: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildKpiCard(
                    isDark,
                    title: 'ជំពាក់មិនទាន់ទូទាត់ (Due)',
                    value: '$dueCount',
                    desc: 'ចំនួនវិក្កយបត្រដែលមិនទាន់ទូទាត់ប្រាក់គ្រប់។',
                    icon: Icons.warning_amber_rounded,
                    iconColor: Colors.red,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildKpiCard(
                    isDark,
                    title: 'កំពុងរង់ចាំទំនិញ (Pending)',
                    value: '$pendingCount',
                    desc: 'ចំនួនបញ្ជាទិញដែលមិនទាន់ទទួលបានទំនិញ។',
                    icon: Icons.hourglass_empty,
                    iconColor: Colors.orange,
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
                  // Filter Toolbar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (v) => setState(() => _search = v),
                            style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkText : AppColors.lightText),
                            decoration: InputDecoration(
                              hintText: 'ស្វែងរកតាមលេខប័ណ្ណទិញ ឬអ្នកផ្គត់ផ្គង់...',
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
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('ទាំងអស់'),
                              selected: _statusFilter == 'ALL',
                              onSelected: (_) => setState(() => _statusFilter = 'ALL'),
                            ),
                            ChoiceChip(
                              label: const Text('ជំពាក់ (Due)'),
                              selected: _statusFilter == 'DUE',
                              onSelected: (_) => setState(() => _statusFilter = 'DUE'),
                            ),
                            ChoiceChip(
                              label: const Text('កំពុងរង់ចាំ (Pending)'),
                              selected: _statusFilter == 'PENDING',
                              onSelected: (_) => setState(() => _statusFilter = 'PENDING'),
                            ),
                          ],
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
                        dataRowMinHeight: 56,
                        dataRowMaxHeight: 70,
                        columns: const [
                          DataColumn(label: Text('លេខបញ្ជាទិញ', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('អ្នកផ្គត់ផ្គង់', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('កាលបរិច្ឆេទ', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('តម្លៃសរុប', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('ស្ថានភាពទូទាត់', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('ស្ថានភាពទំនិញ', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('សកម្មភាព', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: _filteredOrders.map((po) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(po.reference, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(po.id, style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText)),
                                  ],
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 220,
                                  child: Text(po.supplierName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '${po.orderDate.day}/${po.orderDate.month}/${po.orderDate.year}',
                                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
                                ),
                              ),
                              DataCell(
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('\$${po.totalCost.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    if (po.dueAmount > 0)
                                      Text('ជំពាក់: \$${po.dueAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: Colors.red)),
                                  ],
                                ),
                              ),
                              DataCell(_buildPaymentBadge(po.paymentStatus)),
                              DataCell(_buildStatusBadge(po.purchaseStatus)),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.payment, size: 18, color: Color(0xFF10B981)),
                                      tooltip: 'កត់ត្រាការបង់ប្រាក់',
                                      onPressed: () => _openPaymentDialog(po),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.local_shipping, size: 18, color: Colors.blue),
                                      tooltip: 'ប្តូរស្ថានភាពទំនិញ',
                                      onPressed: () => _openStatusDialog(po),
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

  Widget _buildPaymentBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'paid':
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.green;
        label = 'Paid (រួចរាល់)';
        break;
      case 'partial':
        bg = Colors.orange.withValues(alpha: 0.15);
        fg = Colors.orange;
        label = 'Partial (មួយផ្នែក)';
        break;
      default:
        bg = Colors.red.withValues(alpha: 0.15);
        fg = Colors.red;
        label = 'Due (ជំពាក់)';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'received':
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.blue;
        label = 'Received (បានទទួល)';
        break;
      case 'ordered':
        bg = Colors.purple.withValues(alpha: 0.15);
        fg = Colors.purple;
        label = 'Ordered (បានកុម្ម៉ង់)';
        break;
      default:
        bg = Colors.amber.withValues(alpha: 0.15);
        fg = Colors.amber.shade800;
        label = 'Pending (រង់ចាំ)';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
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
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkText : AppColors.lightText),
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
