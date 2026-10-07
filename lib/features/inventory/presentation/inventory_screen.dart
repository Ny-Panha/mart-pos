import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/page_header.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              eyebrow: 'Stock Control',
              title: 'ស្តុកទំនិញ (Stock Movements)',
              description: 'Track incoming deliveries, stock adjustments, and sale deductions in real-time',
              actions: [
                SizedBox(
                  width: 160,
                  child: AppButton(
                    text: '+ STOCK IN',
                    onPressed: () {},
                    icon: Icons.add_circle_outline,
                  ),
                ),
              ],
            ),
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recent Stock Movements (ចលនាស្តុកចុងក្រោយ)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 4,
                    separatorBuilder: (_, _) => const Divider(height: 20),
                    itemBuilder: (context, index) {
                      final types = ['in', 'out', 'adjust', 'out'];
                      final products = ['Coca Cola 330ml', 'Sting Energy Drink', 'Oreo Biscuits', 'Angkor Puro Water'];
                      final qtys = ['+48 កំប៉ុង', '-2 ដប', '+5 ប្រអប់', '-6 ដប'];
                      final users = ['Admin (បញ្ញា)', 'POS Sale #INV-000142', 'Admin (បញ្ញា)', 'POS Sale #INV-000141'];

                      final isPositive = types[index] == 'in' || types[index] == 'adjust';

                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (isPositive ? AppColors.success : AppColors.secondary).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Icon(
                              isPositive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                              color: isPositive ? AppColors.success : AppColors.secondary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(products[index], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('By: ${users[index]} • Today', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Text(
                            qtys[index],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isPositive ? AppColors.success : AppColors.danger,
                            ),
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
