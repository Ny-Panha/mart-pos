import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/page_header.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              eyebrow: 'Access Control',
              title: 'បុគ្គលិក និងអ្នកប្រើប្រាស់ (Staff & Users)',
              description: 'Manage staff accounts with role-based access: Admin and Cashier',
              actions: [
                SizedBox(
                  width: 160,
                  child: AppButton(
                    text: '+ ADD STAFF',
                    onPressed: () {},
                    icon: Icons.person_add_alt_rounded,
                  ),
                ),
              ],
            ),
            AppCard(
              padding: const EdgeInsets.all(20),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                separatorBuilder: (_, _) => const Divider(height: 20),
                itemBuilder: (context, index) {
                  final staff = [
                    {'name': 'នី បញ្ញា', 'role': 'ADMIN', 'email': 'admin@bbu.edu.kh', 'status': 'Active'},
                    {'name': 'គក់ ស្រីផ្កាយ', 'role': 'CASHIER', 'email': 'pkay.cashier@bbu.edu.kh', 'status': 'Active'},
                    {'name': 'គុយ ដាលី', 'role': 'CASHIER', 'email': 'daly.cashier@bbu.edu.kh', 'status': 'Active'},
                  ];

                  final s = staff[index];
                  final isAdmin = s['role'] == 'ADMIN';

                  return Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: (isAdmin ? AppColors.primary : AppColors.secondary).withValues(alpha: 0.1),
                        child: Icon(
                          isAdmin ? Icons.admin_panel_settings_rounded : Icons.point_of_sale_rounded,
                          color: isAdmin ? AppColors.primary : AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(s['email']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isAdmin ? AppColors.primary : AppColors.secondary).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s['role']!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isAdmin ? AppColors.primary : AppColors.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.check_circle, color: AppColors.success, size: 18),
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
