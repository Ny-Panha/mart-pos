import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../models/admin_manager_models.dart';
import '../providers/admin_manager_providers.dart';
import 'manager_widgets.dart';

class AdminManagerReportsScreen extends ConsumerWidget {
  const AdminManagerReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(managerDashboardProvider);
    return ManagerPage(
      title: 'Platform reports',
      description:
          'Review revenue and operational performance across every shop.',
      actions: [
        OutlinedButton.icon(
          onPressed: () => ref.invalidate(managerDashboardProvider),
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
      ],
      child: dashboard.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            managerError(error, () => ref.invalidate(managerDashboardProvider)),
        data: (data) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              crossAxisCount: MediaQuery.sizeOf(context).width > 850
                  ? 4
                  : (MediaQuery.sizeOf(context).width < 550 ? 1 : 2),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: MediaQuery.sizeOf(context).width < 550 ? 2.5 : 2.3,
              children: [
                ManagerMetricCard(
                  label: 'Revenue',
                  value: managerMoney(data.revenue),
                  icon: Icons.payments_outlined,
                  color: AppColors.success,
                ),
                ManagerMetricCard(
                  label: 'Orders',
                  value: '${data.orders}',
                  icon: Icons.receipt_long_outlined,
                  color: AppColors.primary,
                ),
                ManagerMetricCard(
                  label: 'Products',
                  value: '${data.products}',
                  icon: Icons.inventory_2_outlined,
                  color: AppColors.info,
                ),
                ManagerMetricCard(
                  label: 'Low stock',
                  value: '${data.lowStock}',
                  icon: Icons.warning_amber_outlined,
                  color: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 18),
            ManagerSectionCard(
              title: 'Revenue trend',
              subtitle: 'The callable dashboard contract returns the period selected by the platform API.',
              child: _RevenueChart(points: data.revenueSeries),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final List<PlatformMetricPoint> points;
  const _RevenueChart({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('No report series returned yet.')),
      );
    }
    final max = points
        .map((point) => point.value)
        .fold<int>(0, (a, b) => a > b ? a : b);
    return SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: points.map((point) {
          final height = max == 0 ? 4.0 : 150 * point.value / max;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Tooltip(
                    message: '${point.label}: ${managerMoney(point.value)}',
                    child: Container(
                      height: height.clamp(4, 150),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    point.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
