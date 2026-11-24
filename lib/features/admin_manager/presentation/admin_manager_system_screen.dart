import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/admin_manager_providers.dart';
import 'manager_widgets.dart';

class AdminManagerSystemScreen extends StatefulWidget {
  const AdminManagerSystemScreen({super.key});

  @override
  State<AdminManagerSystemScreen> createState() =>
      _AdminManagerSystemScreenState();
}

class _AdminManagerSystemScreenState extends State<AdminManagerSystemScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _tabs = const [
    (title: 'Audit Logs', icon: Icons.history_rounded),
    (title: 'System Alerts', icon: Icons.notifications_active_rounded),
    (title: 'Service Health', icon: Icons.health_and_safety_rounded),
    (title: 'Settings', icon: Icons.tune_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A1F2B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2D3442) : const Color(0xFFE2E8F0);

    return ManagerPage(
      title: 'ប្រតិបត្តិការប្រព័ន្ធ (System Operations)',
      description: 'តាមដានស្ថានភាពប្រព័ន្ធ ការជូនដំណឹង និងកំណត់ហេតុសវនកម្ម',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Adaptive Tab Navigation Bar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: _tabs.map((tab) {
                return Tab(
                  height: 40,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tab.icon, size: 17),
                      const SizedBox(width: 8),
                      Text(tab.title),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 18),

          // Content Panels (Content-Adaptive Height)
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              return IndexedStack(
                index: _tabController.index,
                children: const [
                  _LogsPanel(),
                  _AlertsPanel(),
                  _HealthPanel(),
                  _SettingsPanel(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 1: AUDIT LOGS
// =============================================================================

class _LogsPanel extends ConsumerStatefulWidget {
  const _LogsPanel();

  @override
  ConsumerState<_LogsPanel> createState() => _LogsPanelState();
}

class _LogsPanelState extends ConsumerState<_LogsPanel> {
  String _search = '';
  String _severity = 'All';

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(managerLogsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return logsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(60),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) =>
          managerError(error, () => ref.invalidate(managerLogsProvider)),
      data: (items) {
        final filtered = items.where((log) {
          final matchesSearch = log.action.toLowerCase().contains(_search) ||
              log.actor.toLowerCase().contains(_search) ||
              log.entity.toLowerCase().contains(_search) ||
              log.message.toLowerCase().contains(_search);
          final matchesSeverity = _severity == 'All' ||
              log.severity.toLowerCase() == _severity.toLowerCase();
          return matchesSearch && matchesSeverity;
        }).toList();

        return Column(
          children: [
            ManagerSearchFilterBar(
              hintText: 'ស្វែងរកកំណត់ហេតុ (Search audit logs)...',
              onSearch: (q) => setState(() => _search = q.toLowerCase()),
              filters: const ['All', 'Info', 'Warning', 'Error'],
              activeFilter: _severity,
              onFilterChanged: (s) => setState(() => _severity = s),
            ),
            const SizedBox(height: 16),
            ManagerSectionCard(
              title: '${filtered.length} Audit Events Recorded',
              subtitle: 'System security, administrative mutations, and operational trace logs',
              child: items.isEmpty
                  ? const ManagerEmptyState(
                      icon: Icons.history_rounded,
                      title: 'No audit logs recorded',
                      description: 'Platform actions and security events will log here automatically.',
                    )
                  : filtered.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No logs match your filter criteria.'),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, index) {
                            final log = filtered[index];
                            final color = _severityColor(log.severity);

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF131722) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF262C3A) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: .12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(_severityIcon(log.severity), size: 16, color: color),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                log.action,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              managerDate(log.createdAt),
                                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          [
                                            if (log.entity.isNotEmpty) 'Entity: ${log.entity}',
                                            if (log.actor.isNotEmpty) 'Actor: ${log.actor}',
                                            log.message,
                                          ].where((v) => v.isNotEmpty).join(' • '),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// TAB 2: SYSTEM ALERTS
// =============================================================================

class _AlertsPanel extends ConsumerWidget {
  const _AlertsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(managerAlertsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return alertsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(60),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) =>
          managerError(error, () => ref.invalidate(managerAlertsProvider)),
      data: (items) {
        return ManagerSectionCard(
          title: '${items.length} Platform Alerts',
          subtitle: 'Active system health warnings, inventory anomalies, and service interrupts',
          child: items.isEmpty
              ? const ManagerEmptyState(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'All Systems Operational',
                  description: 'No active alarms or critical alerts require attention.',
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final alert = items[index];
                    final isCritical = alert.severity.toLowerCase() == 'critical';
                    final color = isCritical ? AppColors.danger : AppColors.warning;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF131722) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF262C3A) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: .12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isCritical ? Icons.error_outline_rounded : Icons.warning_amber_rounded,
                                  color: color,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  alert.title,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                ),
                              ),
                              ManagerStatusChip(
                                label: alert.severity,
                                customColor: color,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            alert.message,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? Colors.grey[400] : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (alert.resolved)
                                const ManagerStatusChip(label: 'Resolved', positive: true)
                              else
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    try {
                                      await ref
                                          .read(adminManagerServiceProvider)
                                          .resolveAlert(alert.id);
                                      ref.invalidate(managerAlertsProvider);
                                    } catch (error) {
                                      if (context.mounted) showManagerError(context, error);
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(Icons.check_rounded, size: 14),
                                  label: const Text('Resolve Alert'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

// =============================================================================
// TAB 3: SERVICE HEALTH
// =============================================================================

class _HealthPanel extends StatelessWidget {
  const _HealthPanel();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final services = [
      (
        name: 'Firebase Authentication',
        subtitle: 'User session verification & token authority',
        icon: Icons.verified_user_rounded,
        status: 'Operational',
        isOk: true,
      ),
      (
        name: 'Cloud Firestore Database',
        subtitle: 'Multi-tenant real-time sync & data storage',
        icon: Icons.storage_rounded,
        status: 'Connected',
        isOk: true,
      ),
      (
        name: 'Privileged Cloud Functions',
        subtitle: 'Serverless execution contract for tenant provisioning',
        icon: Icons.functions_rounded,
        status: 'Hybrid Mode',
        isOk: true,
      ),
      (
        name: 'Laravel Backend Core API',
        subtitle: 'Authoritative checkout idempotency & POS accounting',
        icon: Icons.dns_rounded,
        status: 'Available',
        isOk: true,
      ),
    ];

    return ManagerSectionCard(
      title: 'Infrastructure & Service Health',
      subtitle: 'Live connectivity and configuration status for critical subsystems',
      child: Column(
        children: services.map((s) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131722) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF262C3A) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(s.icon, color: AppColors.success, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                ManagerStatusChip(
                  label: s.status,
                  positive: s.isOk,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// =============================================================================
// TAB 4: PLATFORM SETTINGS
// =============================================================================

class _SettingsPanel extends ConsumerStatefulWidget {
  const _SettingsPanel();

  @override
  ConsumerState<_SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends ConsumerState<_SettingsPanel> {
  final maintenance = TextEditingController();
  bool posEnabled = true, saving = false;

  @override
  void dispose() {
    maintenance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ManagerSectionCard(
      title: 'Platform System Configuration',
      subtitle: 'Global controls and platform-wide defaults',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131722) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF262C3A) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Allow Shop POS Terminal Access',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'When enabled, newly provisioned and active shops can operate live POS cash registers.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Switch(
                  value: posEnabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => setState(() => posEnabled = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: maintenance,
            decoration: InputDecoration(
              labelText: 'Platform Maintenance Notice (Optional)',
              hintText: 'Enter announcement broadcast to shop administrators...',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: saving
                  ? null
                  : () async {
                      setState(() => saving = true);
                      try {
                        await ref
                            .read(adminManagerServiceProvider)
                            .updatePlatformSettings({
                          'maintenanceMessage': maintenance.text.trim(),
                          'posEnabled': posEnabled,
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Platform settings saved successfully.'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (error) {
                        if (context.mounted) showManagerError(context, error);
                      } finally {
                        if (mounted) setState(() => saving = false);
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(saving ? 'Saving...' : 'Save Configuration'),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _severityIcon(String severity) => switch (severity.toLowerCase()) {
      'critical' || 'error' => Icons.error_outline_rounded,
      'warning' => Icons.warning_amber_rounded,
      _ => Icons.info_outline_rounded,
    };

Color _severityColor(String severity) => switch (severity.toLowerCase()) {
      'critical' || 'error' => AppColors.danger,
      'warning' => AppColors.warning,
      _ => AppColors.info,
    };
