import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../models/admin_manager_models.dart';
import '../providers/admin_manager_providers.dart';
import 'manager_widgets.dart';

class AdminManagerDashboardScreen extends ConsumerWidget {
  const AdminManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(managerDashboardProvider);
    final shops = ref.watch(managerShopsProvider);
    final alerts = ref.watch(managerAlertsProvider);
    return ManagerPage(
      title: 'Platform dashboard',
      description:
          'A cross shop view of operations, subscriptions, and system health.',
      actions: [
        OutlinedButton.icon(
          onPressed: () => ref.invalidate(managerDashboardProvider),
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
      ],
      child: dashboard.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(60),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, _) =>
            managerError(error, () => ref.invalidate(managerDashboardProvider)),
        data: (metrics) =>
            _DashboardBody(metrics: metrics, shops: shops, alerts: alerts),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final PlatformDashboard metrics;
  final AsyncValue<List<ShopSummary>> shops;
  final AsyncValue<List<PlatformAlert>> alerts;

  const _DashboardBody({
    required this.metrics,
    required this.shops,
    required this.alerts,
  });

  @override
  Widget build(BuildContext context) {
    final shopList = shops.value ?? const <ShopSummary>[];
    final alertList = alerts.value ?? const <PlatformAlert>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width >= 1100
              ? 4
              : MediaQuery.sizeOf(context).width >= 650
              ? 2
              : 1,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 2.2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            ManagerMetricCard(
              label: 'Total shops',
              value: '${metrics.shops == 0 ? shopList.length : metrics.shops}',
              icon: Icons.storefront_outlined,
              color: AppColors.primary,
            ),
            ManagerMetricCard(
              label: 'Active shops',
              value: '${metrics.activeShops}',
              icon: Icons.verified_outlined,
              color: AppColors.success,
            ),
            ManagerMetricCard(
              label: 'Administrators',
              value: '${metrics.admins}',
              icon: Icons.manage_accounts_outlined,
              color: AppColors.secondary,
            ),
            ManagerMetricCard(
              label: 'Cashiers',
              value: '${metrics.cashiers}',
              icon: Icons.point_of_sale_outlined,
              color: AppColors.warning,
            ),
            ManagerMetricCard(
              label: 'Products',
              value: '${metrics.products}',
              icon: Icons.inventory_2_outlined,
              color: AppColors.info,
            ),
            ManagerMetricCard(
              label: 'Low stock',
              value: '${metrics.lowStock}',
              icon: Icons.warning_amber_outlined,
              color: AppColors.danger,
            ),
            ManagerMetricCard(
              label: '30 day revenue',
              value: managerMoney(metrics.revenue),
              icon: Icons.payments_outlined,
              color: AppColors.success,
            ),
            ManagerMetricCard(
              label: 'Orders',
              value: '${metrics.orders}',
              icon: Icons.receipt_long_outlined,
              color: AppColors.primaryLight,
            ),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 800) {
              return Column(
                children: [
                  _shopsCard(shopList),
                  const SizedBox(height: 18),
                  _alertsCard(alertList),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _shopsCard(shopList)),
                const SizedBox(width: 18),
                Expanded(child: _alertsCard(alertList)),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _shopsCard(List<ShopSummary> shops) => ManagerSectionCard(
    title: 'Recent shops',
    subtitle: 'Shop records visible to the platform manager',
    child: shops.isEmpty
        ? const Text('No shops are available yet.')
        : Column(
            children: shops
                .take(5)
                .map(
                  (shop) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      child: Icon(Icons.storefront_outlined, size: 18),
                    ),
                    title: Text(shop.name),
                    subtitle: Text(
                      shop.ownerEmail.isEmpty ? shop.address : shop.ownerEmail,
                    ),
                    trailing: ManagerStatusChip(
                      label: shop.status,
                      positive: shop.status == 'active',
                    ),
                  ),
                )
                .toList(),
          ),
  );

  Widget _alertsCard(List<PlatformAlert> alerts) => ManagerSectionCard(
    title: 'System alerts',
    subtitle: 'Unresolved alerts need attention from the platform team',
    child: alerts.isEmpty
        ? const Text('No active alerts.')
        : Column(
            children: alerts
                .take(5)
                .map(
                  (alert) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      alert.severity == 'critical'
                          ? Icons.error_outline
                          : Icons.warning_amber_outlined,
                      color: alert.severity == 'critical'
                          ? AppColors.danger
                          : AppColors.warning,
                    ),
                    title: Text(alert.title),
                    subtitle: Text(
                      alert.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
          ),
  );
}
