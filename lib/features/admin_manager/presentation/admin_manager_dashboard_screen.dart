import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      title: 'ផ្ទាំងគ្រប់គ្រងប្រព័ន្ធ (Platform Dashboard)',
      description:
          'ទិដ្ឋភាពទូទៅនៃប្រតិបត្តិការហាងទាំងអស់ កញ្ចប់សេវា និងស្ថានភាពប្រព័ន្ធ',
      actions: [
        OutlinedButton.icon(
          onPressed: () {
            ref.invalidate(managerDashboardProvider);
            ref.invalidate(managerShopsProvider);
            ref.invalidate(managerAlertsProvider);
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.refresh, size: 16),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shopList = shops.value ?? const <ShopSummary>[];
    final alertList = alerts.value ?? const <PlatformAlert>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Metric Cards Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isCompact = width < 650;
            final columns = width >= 1100
                ? 4
                : width >= 750
                    ? 3
                    : width >= 320
                        ? 2
                        : 1;

            return GridView.count(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: isCompact ? 116 : 88,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ManagerMetricCard(
                  compact: isCompact,
                  label: 'Total shops',
                  value: '${metrics.shops == 0 ? shopList.length : metrics.shops}',
                  icon: Icons.storefront_rounded,
                  color: AppColors.primary,
                ),
                ManagerMetricCard(
                  compact: isCompact,
                  label: 'Active shops',
                  value: '${metrics.activeShops}',
                  icon: Icons.verified_rounded,
                  color: AppColors.success,
                ),
                ManagerMetricCard(
                  compact: isCompact,
                  label: 'Administrators',
                  value: '${metrics.admins}',
                  icon: Icons.manage_accounts_rounded,
                  color: const Color(0xFF6366F1),
                ),
                ManagerMetricCard(
                  compact: isCompact,
                  label: 'Cashiers',
                  value: '${metrics.cashiers}',
                  icon: Icons.point_of_sale_rounded,
                  color: AppColors.warning,
                ),
                ManagerMetricCard(
                  compact: isCompact,
                  label: 'Global products',
                  value: '${metrics.products}',
                  icon: Icons.inventory_2_rounded,
                  color: AppColors.info,
                ),
                ManagerMetricCard(
                  compact: isCompact,
                  label: 'Low stock items',
                  value: '${metrics.lowStock}',
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.danger,
                ),
                ManagerMetricCard(
                  compact: isCompact,
                  label: '30-day revenue',
                  value: managerMoney(metrics.revenue),
                  icon: Icons.payments_rounded,
                  color: AppColors.success,
                ),
                ManagerMetricCard(
                  compact: isCompact,
                  label: 'Orders committed',
                  value: '${metrics.orders}',
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.primaryLight,
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 18),

        // 2. Quick Action Shortcuts Row
        _buildQuickActions(context, isDark),

        const SizedBox(height: 18),

        // 3. Operations Overview (Recent Shops & System Alerts)
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 840) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _shopsCard(context, shopList, isDark),
                  const SizedBox(height: 16),
                  _alertsCard(context, alertList, isDark),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _shopsCard(context, shopList, isDark)),
                const SizedBox(width: 16),
                Expanded(child: _alertsCard(context, alertList, isDark)),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    final actions = [
      (
        icon: Icons.storefront_rounded,
        label: 'Shops (បញ្ជីហាង)',
        path: '/manager/shops',
        color: AppColors.primary,
      ),
      (
        icon: Icons.inventory_2_rounded,
        label: 'Stock (ស្តុកទំនិញ)',
        path: '/manager/stock',
        color: AppColors.info,
      ),
      (
        icon: Icons.analytics_rounded,
        label: 'Reports (របាយការណ៍)',
        path: '/manager/reports',
        color: AppColors.success,
      ),
      (
        icon: Icons.settings_suggest_rounded,
        label: 'System (ប្រព័ន្ធ)',
        path: '/manager/system',
        color: AppColors.warning,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 650;
        final cardBg = isDark ? const Color(0xFF1A1F2B) : Colors.white;
        final borderColor =
            isDark ? const Color(0xFF2D3442) : const Color(0xFFE2E8F0);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'QUICK SHORTCUTS',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark ? const Color(0xFFA78BFA) : AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: actions.map((a) {
                  return ActionChip(
                    avatar: Icon(a.icon, size: 16, color: a.color),
                    label: Text(
                      a.label,
                      style: TextStyle(
                        fontSize: isCompact ? 11.5 : 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    backgroundColor: isDark
                        ? const Color(0xFF131722)
                        : const Color(0xFFF1F5F9),
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onPressed: () => context.go(a.path),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shopsCard(
    BuildContext context,
    List<ShopSummary> shops,
    bool isDark,
  ) {
    return ManagerSectionCard(
      title: 'Recent shops',
      subtitle: 'Latest registered businesses on the platform',
      trailing: TextButton(
        onPressed: () => context.go('/manager/shops'),
        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
        child: const Text('View all'),
      ),
      child: shops.isEmpty
          ? const ManagerEmptyState(
              icon: Icons.storefront_outlined,
              title: 'No shops created yet',
              description: 'Provision your first shop to start operations.',
            )
          : Column(
              children: shops.take(5).map((shop) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF131722)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF262C3A)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.store_mall_directory_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shop.name,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              shop.ownerEmail.isEmpty
                                  ? (shop.address.isEmpty
                                      ? 'No email recorded'
                                      : shop.address)
                                  : shop.ownerEmail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ManagerStatusChip(
                        label: shop.status,
                        positive: shop.status.toLowerCase() == 'active',
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _alertsCard(
    BuildContext context,
    List<PlatformAlert> alerts,
    bool isDark,
  ) {
    return ManagerSectionCard(
      title: 'Platform alerts',
      subtitle: 'System warnings and pending administrative actions',
      trailing: TextButton(
        onPressed: () => context.go('/manager/system'),
        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
        child: const Text('View all'),
      ),
      child: alerts.isEmpty
          ? const ManagerEmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'All systems normal',
              description:
                  'No critical alerts or warnings require your attention.',
            )
          : Column(
              children: alerts.take(5).map((alert) {
                final isCritical = alert.severity == 'critical';
                final color = isCritical ? AppColors.danger : AppColors.warning;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF131722)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF262C3A)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCritical
                              ? Icons.error_outline_rounded
                              : Icons.warning_amber_rounded,
                          size: 16,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              alert.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}
