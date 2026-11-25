import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';

class PaymentDialog extends StatefulWidget {
  final int totalAmount; // int Riel
  final String customerName;
  final bool Function()? requiresRecovery;
  final Future<void> Function({
    required String paymentMethod,
    required int paidAmount,
    required int changeAmount,
    double? receivedUsd,
    double? changeUsd,
  })
  onConfirmPayment;

  const PaymentDialog({
    super.key,
    required this.totalAmount,
    required this.customerName,
    this.requiresRecovery,
    required this.onConfirmPayment,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _usdController = TextEditingController();

  int _receivedAmount = 0;
  double _receivedUsd = 0.0;
  bool _isProcessing = false;

  double get _totalUsd =>
      double.parse((widget.totalAmount / 4100.0).toStringAsFixed(2));

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _receivedAmount = widget.totalAmount;
    _cashController.text = '$_receivedAmount';

    _receivedUsd = _totalUsd;
    _usdController.text = _totalUsd.toStringAsFixed(2);

    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cashController.dispose();
    _usdController.dispose();
    super.dispose();
  }

  // KHR Calculations
  int get _changeAmount => _receivedAmount >= widget.totalAmount
      ? _receivedAmount - widget.totalAmount
      : 0;
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

  // USD Calculations
  double get _changeUsd => _receivedUsd >= _totalUsd
      ? double.parse((_receivedUsd - _totalUsd).toStringAsFixed(2))
      : 0.0;
  int get _changeRielFromUsd => (_changeUsd * 4100).round();
  bool get _isUsdValid => _receivedUsd >= _totalUsd && _receivedUsd > 0;

  void _setUsd(double amount) {
    setState(() {
      _receivedUsd = double.parse(amount.toStringAsFixed(2));
      _usdController.text = _receivedUsd.toStringAsFixed(2);
    });
  }

  Future<void> _submit(String method) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      if (method == 'khqr') {
        await widget.onConfirmPayment(
          paymentMethod: 'khqr',
          paidAmount: widget.totalAmount,
          changeAmount: 0,
        );
      } else if (method == 'cash_usd') {
        await widget.onConfirmPayment(
          paymentMethod: 'cash_usd',
          paidAmount: (_receivedUsd * 4100).round(),
          changeAmount: _changeRielFromUsd,
          receivedUsd: _receivedUsd,
          changeUsd: _changeUsd,
        );
      } else {
        await widget.onConfirmPayment(
          paymentMethod: 'cash_riel',
          paidAmount: _receivedAmount,
          changeAmount: _changeAmount,
        );
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout failed: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
        if (widget.requiresRecovery?.call() == true) Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tab = _tabController.index;
    final valid = tab == 0
        ? _isCashValid
        : tab == 1
        ? _isUsdValid
        : true;
    return PopScope(
      canPop: !_isProcessing,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 432),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'ការទូទាត់',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Cancel payment',
                              onPressed: _isProcessing
                                  ? null
                                  : () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        Text(
                          widget.customerName,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: .08),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total due',
                                  style: theme.textTheme.labelLarge,
                                ),
                                Text(
                                  MoneyUtils.formatRiel(widget.totalAmount),
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        color: colors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  '${MoneyUtils.formatUSD(_totalUsd)}  ·  4,100 ៛ / USD',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        IgnorePointer(
                          ignoring: _isProcessing,
                          child: ExcludeFocus(
                            excluding: _isProcessing,
                            child: TabBar(
                              controller: _tabController,
                              dividerColor: Colors.transparent,
                              labelPadding: EdgeInsets.zero,
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicator: BoxDecoration(
                                color: colors.primary,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              labelColor: colors.onPrimary,
                              unselectedLabelColor: colors.onSurfaceVariant,
                              tabs: const [
                                Tab(text: 'Cash KHR'),
                                Tab(text: 'Cash USD'),
                                Tab(text: 'KHQR'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (tab < 2)
                          _cashForm(tab == 1)
                        else
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    'assets/qr.png',
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  Icons.qr_code_rounded,
                                  color: colors.primary,
                                ),
                                title: const Text('Bakong KHQR'),
                                subtitle: const Text(
                                  'ផ្ទៀងផ្ទាត់ប្រាក់ចូលក្នុងគណនីមុនបញ្ជាក់។',
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const ValueKey('confirm-payment'),
                  onPressed: !valid || _isProcessing
                      ? null
                      : () => _submit(['cash_riel', 'cash_usd', 'khqr'][tab]),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  child: _isProcessing
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('បញ្ជាក់ការទូទាត់'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cashForm(bool usd) {
    final theme = Theme.of(context);
    final valid = usd ? _isUsdValid : _isCashValid;
    final change = usd
        ? (valid
              ? '${MoneyUtils.formatUSD(_changeUsd)} (${MoneyUtils.formatRiel(_changeRielFromUsd)})'
              : MoneyUtils.formatUSD(_totalUsd - _receivedUsd))
        : (valid
              ? MoneyUtils.formatDual(_changeAmount)
              : MoneyUtils.formatRiel(widget.totalAmount - _receivedAmount));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: ValueKey(usd),
          enabled: !_isProcessing,
          controller: usd ? _usdController : _cashController,
          keyboardType: TextInputType.numberWithOptions(decimal: usd),
          onChanged: (v) => setState(() {
            if (usd) {
              _receivedUsd = double.tryParse(v.trim()) ?? 0;
            } else {
              _receivedAmount =
                  int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            }
          }),
          decoration: InputDecoration(
            labelText: usd ? 'ប្រាក់ទទួល (USD)' : 'ប្រាក់ទទួល (KHR)',
            suffixText: usd ? r'$' : '៛',
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _quickCash(
              'Exact',
              () => usd ? _setUsd(_totalUsd) : _setCash(widget.totalAmount),
            ),
            if (usd)
              for (final amount in [if (_totalUsd <= 5) 5, 10, 20, 50, 100])
                _quickCash('\$$amount', () => _setUsd(amount.toDouble()))
            else
              for (final amount in [5000, 10000, 20000, 50000, 100000])
                _quickCash(
                  '+${MoneyUtils.formatRiel(amount)}',
                  () => _addCash(amount),
                ),
          ],
        ),
        const Divider(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                valid ? 'ប្រាក់អាប់' : 'នៅខ្វះ',
                style: theme.textTheme.labelLarge,
              ),
            ),
            Flexible(
              child: Text(
                change,
                textAlign: TextAlign.end,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: valid
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickCash(String label, VoidCallback action) => ActionChip(
    visualDensity: VisualDensity.compact,
    label: Text(label),
    onPressed: _isProcessing ? null : action,
  );
}
