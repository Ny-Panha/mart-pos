import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_button.dart';

class PaymentDialog extends StatefulWidget {
  final int totalAmount; // int Riel
  final String customerName;
  final Future<void> Function({
    required String paymentMethod,
    required int paidAmount,
    required int changeAmount,
  }) onConfirmPayment;

  const PaymentDialog({
    super.key,
    required this.totalAmount,
    required this.customerName,
    required this.onConfirmPayment,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _cashController = TextEditingController();
  int _receivedAmount = 0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _receivedAmount = widget.totalAmount;
    _cashController.text = '$_receivedAmount';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cashController.dispose();
    super.dispose();
  }

  int get _changeAmount =>
      _receivedAmount >= widget.totalAmount ? _receivedAmount - widget.totalAmount : 0;

  bool get _isCashValid => _receivedAmount >= widget.totalAmount;

  void _setCash(int amount) {
    setState(() {
      _receivedAmount = amount;
      _cashController.text = '$amount';
    });
  }

  void _addCash(int add) {
    setState(() {
      _receivedAmount += add;
      _cashController.text = '$_receivedAmount';
    });
  }

  Future<void> _submit(String method) async {
    setState(() => _isProcessing = true);
    try {
      final paid = method == 'khqr' ? widget.totalAmount : _receivedAmount;
      final change = method == 'khqr' ? 0 : _changeAmount;
      await widget.onConfirmPayment(
        paymentMethod: method,
        paidAmount: paid,
        changeAmount: change,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title & Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ការទូទាត់ប្រាក់ (Checkout)', style: AppTextStyles.titleLG),
                    Text('Customer: ${widget.customerName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Total Amount Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ទឹកប្រាក់សរុប (Total Due):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        MoneyUtils.formatRiel(widget.totalAmount),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        MoneyUtils.formatUSD(MoneyUtils.rielToUsd(widget.totalAmount)),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment Method Tabs
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(icon: Icon(Icons.payments_outlined), text: 'Cash (សាច់ប្រាក់)'),
                Tab(icon: Icon(Icons.qr_code_rounded), text: 'Bakong KHQR'),
              ],
            ),
            const SizedBox(height: 16),

            // Tab Views
            SizedBox(
              height: 240,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Cash Payment
                  _buildCashTab(isDark),

                  // Tab 2: KHQR Payment
                  _buildKhqrTab(isDark),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Submit Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : () => Navigator.pop(context),
                    child: const Text('បោះបង់ (Cancel)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: AppButton(
                    text: 'បញ្ជាក់ការទូទាត់ (CONFIRM)',
                    isLoading: _isProcessing,
                    onPressed: (_tabController.index == 0 && !_isCashValid)
                        ? null
                        : () => _submit(_tabController.index == 0 ? 'cash' : 'khqr'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashTab(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Received Cash Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cashController,
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final parsed = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                    setState(() => _receivedAmount = parsed);
                  },
                  decoration: const InputDecoration(
                    labelText: 'ប្រាក់ទទួល (Cash Received)',
                    suffixText: '៛',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _setCash(widget.totalAmount),
                child: const Text('គ្រប់ល្មម (Exact)'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quick Cash Suggestions
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildQuickCashChip('+5,000៛', () => _addCash(5000)),
              _buildQuickCashChip('+10,000៛', () => _addCash(10000)),
              _buildQuickCashChip('+20,000៛', () => _addCash(20000)),
              _buildQuickCashChip('+50,000៛', () => _addCash(50000)),
              _buildQuickCashChip('\$5 (20,500៛)', () => _setCash(20500)),
              _buildQuickCashChip('\$10 (41,000៛)', () => _setCash(41000)),
              _buildQuickCashChip('\$20 (82,000៛)', () => _setCash(82000)),
            ],
          ),
          const SizedBox(height: 14),

          // Change Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _isCashValid
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isCashValid ? 'ប្រាក់អាប់ជូន (Change Due):' : 'ប្រាក់មិនទាន់គ្រប់ (Still Due):',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _isCashValid ? AppColors.success : AppColors.danger,
                  ),
                ),
                Text(
                  _isCashValid
                      ? MoneyUtils.formatDual(_changeAmount)
                      : MoneyUtils.formatRiel(widget.totalAmount - _receivedAmount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: _isCashValid ? AppColors.success : AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCashChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildKhqrTab(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade700, width: 2),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  color: Colors.red.shade700,
                  child: const Text('KHQR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
                const SizedBox(height: 6),
                const Icon(Icons.qr_code_2_rounded, size: 90, color: Colors.black87),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'ស្កេនទូទាត់តាមរយៈ App ធនាគារណាក៏បាន (Bakong Supported)',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
