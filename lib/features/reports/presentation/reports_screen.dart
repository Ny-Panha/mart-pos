import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/page_header.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              eyebrow: 'Business Intelligence',
              title: 'របាយការណ៍លក់ (Sales & Daily Close)',
              description: 'End-of-day cash counts, sales totals, and shift reconciliation',
              actions: [
                SizedBox(
                  width: 170,
                  child: AppButton(
                    text: 'PRINT CLOSE SLIP',
                    onPressed: () {},
                    icon: Icons.print_outlined,
                  ),
                ),
              ],
            ),
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Daily Shift Closes (ការបិទបញ្ជីប្រចាំថ្ងៃ)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 3,
                    separatorBuilder: (_, _) => const Divider(height: 20),
                    itemBuilder: (context, index) {
                      final dates = ['Today (07 Oct 2026)', 'Yesterday (06 Oct 2026)', '05 Oct 2026'];
                      final cashiers = ['គក់ ស្រីផ្កាយ', 'គុយ ដាលី', 'គក់ ស្រីផ្កាយ'];
                      final salesCounts = [42, 58, 65];
                      final totals = [1420000, 1850000, 2100000];

                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.point_of_sale_rounded, color: AppColors.primary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(dates[index], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('Cashier: ${cashiers[index]} • ${salesCounts[index]} Sales', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(MoneyUtils.formatRiel(totals[index]), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 14)),
                              const Text('Status: Closed', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
