import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_header.dart';
import '../../shifts/presentation/close_shift_dialog.dart';
import '../../shifts/presentation/open_shift_dialog.dart';
import '../../shifts/providers/shift_provider.dart';

class CashierDailyCloseScreen extends ConsumerWidget {
  const CashierDailyCloseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shift = ref.watch(currentOpenShiftProvider);
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              eyebrow: 'Cashier Shifts',
              title: 'បិទវេនលក់ប្រចាំថ្ងៃ (Daily Shift Close)',
              description: 'បើកវេន, ផ្ទៀងផ្ទាត់ទឹកប្រាក់លក់បាន និងបិទវេនលក់ជាក់ស្តែង',
              actions: [
                OutlinedButton.icon(
                  onPressed: () => OpenShiftDialog.show(context),
                  icon: const Icon(Icons.play_arrow_outlined),
                  label: const Text('បើកវេនថ្មី (Open Shift)'),
                ),
              ],
            ),
            shift.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(
                'Unable to load shift: $e',
                style: const TextStyle(color: AppColors.danger),
              ),
              data: (current) {
                if (current == null) {
                  return const SizedBox(
                    height: 280,
                    child: EmptyState(
                      icon: Icons.schedule_outlined,
                      title: 'No open shift',
                      subtitle: 'Open a shift before taking payments.',
                    ),
                  );
                }
                final summary = ref.watch(
                  shiftSalesSummaryFutureProvider(current),
                );
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Current shift',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _line('Opening float', current.openingCash),
                      summary.when(
                        data: (value) => _line(
                          'Sales (${value.salesCount})',
                          value.totalSales,
                        ),
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: LinearProgressIndicator(),
                        ),
                        error: (e, _) => Text(
                          'Unable to calculate sales: $e',
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                      const Divider(height: 28),
                      summary.when(
                        data: (value) => _line(
                          'Expected cash',
                          current.openingCash + value.totalSales,
                          emphasize: true,
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () =>
                            CloseShiftDialog.show(context, current),
                        icon: const Icon(Icons.lock_outline),
                        label: const Text('Close shift'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, int value, {bool emphasize = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          MoneyUtils.formatRiel(value),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: emphasize ? AppColors.primary : null,
          ),
        ),
      ],
    ),
  );
}
