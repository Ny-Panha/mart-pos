import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/page_header.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              eyebrow: 'Customer Relationship',
              title: 'អតិថិជន (Customer Directory)',
              description: 'Manage regular clients, track total spent and purchase history in Riel',
              actions: [
                SizedBox(
                  width: 170,
                  child: AppButton(
                    text: '+ NEW CUSTOMER',
                    onPressed: () {},
                    icon: Icons.person_add_alt_1_outlined,
                  ),
                ),
              ],
            ),
            AppCard(
              padding: const EdgeInsets.all(20),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                separatorBuilder: (_, _) => const Divider(height: 20),
                itemBuilder: (context, index) {
                  final names = ['សុខ ចាន់ដារា', 'លាង គឹមសួរ', 'ម៉ៅ ចិន្តា', 'ហេង វីរៈ'];
                  final phones = ['012 889 900', '098 765 432', '077 123 456', '085 456 789'];
                  final spent = [128000, 345000, 52000, 890000];

                  return Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(names[index].substring(0, 1), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(names[index], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('Phone: ${phones[index]}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Total Spent:', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(MoneyUtils.formatRiel(spent[index]), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
