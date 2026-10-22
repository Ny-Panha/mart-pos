import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/admin_manager_providers.dart';
import 'manager_widgets.dart';

class AdminManagerSystemScreen extends ConsumerWidget {
  const AdminManagerSystemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = [
      _SystemTab(
        title: 'Logs',
        icon: Icons.history_outlined,
        child: const _LogsPanel(),
      ),
      _SystemTab(
        title: 'Alerts',
        icon: Icons.notifications_active_outlined,
        child: const _AlertsPanel(),
      ),
      _SystemTab(
        title: 'Health',
        icon: Icons.health_and_safety_outlined,
        child: const _HealthPanel(),
      ),
      _SystemTab(
        title: 'Settings',
        icon: Icons.settings_outlined,
        child: const _SettingsPanel(),
      ),
    ];
    return ManagerPage(
      title: 'ប្រតិបត្តិការប្រព័ន្ធ (System Operations)',
      description: 'តាមដានស្ថានភាពប្រព័ន្ធ ការជូនដំណឹង និងកំណត់ហេតុសវនកម្ម',
      child: DefaultTabController(
        length: tabs.length,
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              tabs: tabs
                  .map((tab) => Tab(icon: Icon(tab.icon), text: tab.title))
                  .toList(),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 560,
              child: TabBarView(
                children: tabs.map((tab) => tab.child).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemTab {
  final String title;
  final IconData icon;
  final Widget child;
  const _SystemTab({
    required this.title,
    required this.icon,
    required this.child,
  });
}

class _LogsPanel extends ConsumerWidget {
  const _LogsPanel();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(managerLogsProvider);
    return logs.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          managerError(error, () => ref.invalidate(managerLogsProvider)),
      data: (items) => ManagerSectionCard(
        title: '${items.length} recent events',
        child: items.isEmpty
            ? const Text('No platform logs are available.')
            : ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final log = items[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _severityIcon(log.severity),
                      color: _severityColor(log.severity),
                    ),
                    title: Text(log.action),
                    subtitle: Text(
                      [
                        log.entity,
                        log.message,
                        log.actor,
                      ].where((value) => value.isNotEmpty).join(' • '),
                    ),
                    trailing: Text(
                      managerDate(log.createdAt),
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _AlertsPanel extends ConsumerWidget {
  const _AlertsPanel();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(managerAlertsProvider);
    return alerts.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          managerError(error, () => ref.invalidate(managerAlertsProvider)),
      data: (items) => ManagerSectionCard(
        title: '${items.length} alerts',
        child: items.isEmpty
            ? const Text('No alerts are available.')
            : ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final alert = items[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _severityIcon(alert.severity),
                      color: _severityColor(alert.severity),
                    ),
                    title: Text(alert.title),
                    subtitle: Text(alert.message),
                    trailing: alert.resolved
                        ? const ManagerStatusChip(label: 'resolved')
                        : TextButton(
                            onPressed: () async {
                              try {
                                await ref
                                    .read(adminManagerServiceProvider)
                                    .resolveAlert(alert.id);
                                ref.invalidate(managerAlertsProvider);
                              } catch (error) {
                                if (context.mounted) {
                                  showManagerError(context, error);
                                }
                              }
                            },
                            child: const Text('Resolve'),
                          ),
                  );
                },
              ),
      ),
    );
  }
}

class _HealthPanel extends StatelessWidget {
  const _HealthPanel();
  @override
  Widget build(BuildContext context) => ManagerSectionCard(
    title: 'Service health',
    subtitle:
        'Live health checks are supplied by the platform Functions contract.',
    child: Column(
      children: const [
        ListTile(
          leading: Icon(Icons.cloud_done_outlined, color: AppColors.success),
          title: Text('Firebase Authentication'),
          trailing: ManagerStatusChip(label: 'configured'),
        ),
        ListTile(
          leading: Icon(Icons.storage_outlined, color: AppColors.success),
          title: Text('Cloud Firestore'),
          trailing: ManagerStatusChip(label: 'configured'),
        ),
        ListTile(
          leading: Icon(Icons.functions_outlined, color: AppColors.warning),
          title: Text('Privileged Cloud Functions'),
          trailing: ManagerStatusChip(
            label: 'contract required',
            positive: false,
          ),
        ),
      ],
    ),
  );
}

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
  Widget build(BuildContext context) => ManagerSectionCard(
    title: 'Platform settings',
    subtitle: 'These controls use manager-only callable Functions and require the backend contract.',
    child: Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Allow shop POS access'),
          subtitle: const Text('Global default for newly provisioned shops'),
          value: posEnabled,
          onChanged: (value) => setState(() => posEnabled = value),
        ),
        TextField(
          controller: maintenance,
          decoration: const InputDecoration(
            labelText: 'Maintenance message',
            hintText: 'Optional message shown to shop admins',
          ),
        ),
        const SizedBox(height: 16),
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
                          const SnackBar(content: Text('Settings saved')),
                        );
                      }
                    } catch (error) {
                      if (context.mounted) showManagerError(context, error);
                    } finally {
                      if (mounted) setState(() => saving = false);
                    }
                  },
            icon: const Icon(Icons.save_outlined),
            label: Text(saving ? 'Saving...' : 'Save settings'),
          ),
        ),
      ],
    ),
  );
}

IconData _severityIcon(String severity) => switch (severity.toLowerCase()) {
  'critical' || 'error' => Icons.error_outline,
  'warning' => Icons.warning_amber_outlined,
  _ => Icons.info_outline,
};
Color _severityColor(String severity) => switch (severity.toLowerCase()) {
  'critical' || 'error' => AppColors.danger,
  'warning' => AppColors.warning,
  _ => AppColors.info,
};
