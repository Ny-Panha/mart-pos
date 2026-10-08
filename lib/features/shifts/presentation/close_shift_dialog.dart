import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/firestore/models/daily_close_model.dart';
import '../../../data/repositories/shift_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/shift_provider.dart';

class CloseShiftDialog extends ConsumerStatefulWidget {
  final DailyCloseModel shift;

  const CloseShiftDialog({super.key, required this.shift});

  static Future<void> show(BuildContext context, DailyCloseModel shift) {
    if (Responsive.isDesktop(context) || Responsive.isTablet(context)) {
      return showDialog<void>(
        context: context,
        builder: (_) => CloseShiftDialog(shift: shift),
      );
    } else {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => CloseShiftDialog(shift: shift),
      );
    }
  }

  @override
  ConsumerState<CloseShiftDialog> createState() => _CloseShiftDialogState();
}

class _CloseShiftDialogState extends ConsumerState<CloseShiftDialog> {
  final TextEditingController _actualCashController = TextEditingController();
  int _actualCash = 0;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _actualCashController.addListener(() {
      final val = int.tryParse(_actualCashController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      if (val != _actualCash) {
        setState(() => _actualCash = val);
      }
    });
  }

  @override
  void dispose() {
    _actualCashController.dispose();
    super.dispose();
  }

  Future<void> _handleCloseShift(int totalSales, int salesCount) async {
    final user = ref.read(authProvider).value;
    if (user == null) {
      setState(() => _errorMessage = 'No authenticated user found');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final closedShift = await ref.read(shiftRepositoryProvider).closeShift(
            shiftId: widget.shift.id,
            cashierId: user.id,
            actualCash: _actualCash,
          );

      if (mounted) {
        Navigator.of(context).pop();
        final diff = closedShift.difference ?? 0;
        final diffStr = diff >= 0
            ? '+${MoneyUtils.formatRiel(diff)}'
            : MoneyUtils.formatRiel(diff);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('បានបិទវេនលក់ជោគជ័យ (Shift closed. Difference: $diffStr)'),
            backgroundColor: diff < 0 ? Colors.orange.shade800 : AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authProvider).value;
    final isDesktop = Responsive.isDesktop(context);
    final summaryAsync = ref.watch(shiftSalesSummaryFutureProvider(widget.shift));

    final timeFormatter = DateFormat('dd/MM/yyyy HH:mm');

    final content = Container(
      constraints: const BoxConstraints(maxWidth: 520),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(isDesktop ? AppRadius.card : 20),
      ),
      child: summaryAsync.when(
        loading: () => const SizedBox(
          height: 250,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error loading shift sales: $err', style: const TextStyle(color: AppColors.danger)),
        ),
        data: (summary) {
          final totalSales = summary.totalSales;
          final salesCount = summary.salesCount;
          final expectedCash = ShiftRepository.calculateExpectedCash(
            openingCash: widget.shift.openingCash,
            totalSales: totalSales,
          );
          final difference = ShiftRepository.calculateDifference(
            openingCash: widget.shift.openingCash,
            totalSales: totalSales,
            actualCash: _actualCash,
          );

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('បិទវេនលក់ (Close Shift)', style: AppTextStyles.titleLG),
                          const SizedBox(height: 2),
                          Text(
                            'បើកតាំងពី: ${timeFormatter.format(widget.shift.openedAt)}',
                            style: AppTextStyles.caption.copyWith(
                              color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.danger, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Shift Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBg : AppColors.lightBg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow(
                        label: 'អ្នកគិតលុយ (Cashier)',
                        value: user?.name ?? 'Unknown',
                        isDark: isDark,
                      ),
                      const Divider(height: 16),
                      _buildSummaryRow(
                        label: 'ប្រាក់ដើមវេន (Opening Float)',
                        value: MoneyUtils.formatDual(widget.shift.openingCash),
                        isDark: isDark,
                      ),
                      const Divider(height: 16),
                      _buildSummaryRow(
                        label: 'ការលក់ក្នុងវេន (Sales Total)',
                        value: '${MoneyUtils.formatDual(totalSales)} ($salesCount វិក្កយបត្រ)',
                        isDark: isDark,
                        valueColor: AppColors.primary,
                      ),
                      const Divider(height: 16),
                      _buildSummaryRow(
                        label: 'សរុបសាច់ប្រាក់រំពឹងទុក (Expected Cash)',
                        value: MoneyUtils.formatDual(expectedCash),
                        isDark: isDark,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Actual Cash input
                Text(
                  'សាច់ប្រាក់រាប់បានជាក់ស្តែង (Actual Cash in Drawer)',
                  style: AppTextStyles.bodyBold.copyWith(
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _actualCashController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: '0',
                    prefixIcon: const Icon(Icons.attach_money_rounded),
                    suffixText: '៛ Riel',
                    suffixStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'សរុបស្មើនឹង: ${MoneyUtils.formatDual(_actualCash)}',
                  style: const TextStyle(fontSize: 13, color: AppColors.primary),
                ),
                const SizedBox(height: 16),

                // Live Difference Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: (difference == 0
                            ? AppColors.success
                            : (difference > 0 ? AppColors.primary : AppColors.danger))
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: (difference == 0
                              ? AppColors.success
                              : (difference > 0 ? AppColors.primary : AppColors.danger))
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ប្រាក់ខុសគ្នា (Difference):',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                      ),
                      Text(
                        difference == 0
                            ? 'ត្រឹមត្រូវ (Balanced) 0 ៛'
                            : (difference > 0
                                ? 'លើស (Surplus) +${MoneyUtils.formatRiel(difference)}'
                                : 'ខ្វះ (Shortage) ${MoneyUtils.formatRiel(difference)}'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: difference < 0 ? AppColors.danger : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.button),
                          ),
                        ),
                        child: const Text('បោះបង់ (Cancel)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        text: 'បិទវេនលក់ (CONFIRM CLOSE)',
                        icon: Icons.check_circle_rounded,
                        isLoading: _isLoading,
                        onPressed: () => _handleCloseShift(totalSales, salesCount),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    if (isDesktop || Responsive.isTablet(context)) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: content,
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: content,
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    required bool isDark,
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? (isDark ? AppColors.darkText : AppColors.lightText),
          ),
        ),
      ],
    );
  }
}
