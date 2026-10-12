import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_header.dart';
import '../providers/cashier_provider.dart';
import 'cashier_invoice_screen.dart';

class CashierSalesHistoryScreen extends ConsumerWidget {
  const CashierSalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref.watch(cashierSalesProvider);
    final filtered = ref.watch(filteredCashierSalesProvider);
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              eyebrow: 'Cashier',
              title: 'Sales history',
              description: 'Review your completed invoices and open a printable receipt.',
            ),
            TextField(
              onChanged: (value) =>
                  ref.read(cashierSearchProvider.notifier).setQuery(value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search invoice number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            sales.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Text(
                'Unable to load sales: $error',
                style: const TextStyle(color: AppColors.danger),
              ),
              data: (_) {
                if (filtered.isEmpty) {
                  return const SizedBox(
                    height: 280,
                    child: EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No sales found',
                      subtitle: 'Completed invoices will appear here.',
                    ),
                  );
                }
                return AppCard(
                  padding: EdgeInsets.zero,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final sale = filtered[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.receipt_long_outlined),
                        ),
                        title: Text(
                          sale.invoiceNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${DateUtilsHelper.formatDateTime(sale.createdAt)} • ${sale.items.length} items',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              MoneyUtils.formatRiel(sale.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              sale.paymentMethod.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CashierInvoiceScreen(sale: sale),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
