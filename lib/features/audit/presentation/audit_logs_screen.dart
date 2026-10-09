import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_header.dart';
import '../../../data/firestore/models/audit_log_model.dart';
import '../providers/audit_provider.dart';
import 'audit_detail_dialog.dart';

class AuditLogsScreen extends ConsumerWidget {
  const AuditLogsScreen({super.key});

  String _formatRelativeDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday, ${DateUtilsHelper.formatTime(dt)}';
    return '${DateUtilsHelper.formatDate(dt)} • ${DateUtilsHelper.formatTime(dt)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = Responsive.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final logsAsync = ref.watch(auditLogsStreamProvider);
    final filteredLogs = ref.watch(filteredAuditLogsProvider);
    final selectedAction = ref.watch(auditActionFilterProvider);
    final selectedDate = ref.watch(auditDateFilterProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Page Header
            PageHeader(
              eyebrow: 'System Tracking & Security',
              title: 'កំណត់ហេតុសវនកម្ម (Audit Log)',
              description: 'Track all administrative, sales, inventory, and system changes in real-time',
              actions: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Total: ${filteredLogs.length} Events',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 2. Filter Toolbar Card
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action group filters
                  Row(
                    children: [
                      const Icon(Icons.filter_list_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'តម្រងតាមសកម្មភាព (Filter by Action):',
                        style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildActionChip(
                        ref: ref,
                        label: 'ទាំងអស់ (All)',
                        actionKey: 'all',
                        currentKey: selectedAction,
                      ),
                      _buildActionChip(
                        ref: ref,
                        label: 'ការលក់ (Sales)',
                        actionKey: 'sale',
                        currentKey: selectedAction,
                        color: AppColors.success,
                      ),
                      _buildActionChip(
                        ref: ref,
                        label: 'ទំនិញ (Products)',
                        actionKey: 'product',
                        currentKey: selectedAction,
                        color: AppColors.primary,
                      ),
                      _buildActionChip(
                        ref: ref,
                        label: 'ស្តុក (Stock)',
                        actionKey: 'stock',
                        currentKey: selectedAction,
                        color: AppColors.warning,
                      ),
                      _buildActionChip(
                        ref: ref,
                        label: 'ទិញចូល (Purchases)',
                        actionKey: 'purchase',
                        currentKey: selectedAction,
                        color: AppColors.secondary,
                      ),
                      _buildActionChip(
                        ref: ref,
                        label: 'បុគ្គលិក (Users)',
                        actionKey: 'user',
                        currentKey: selectedAction,
                        color: Colors.indigo,
                      ),
                      _buildActionChip(
                        ref: ref,
                        label: 'វេនលក់ (Shifts)',
                        actionKey: 'shift',
                        currentKey: selectedAction,
                        color: Colors.deepOrange,
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Date range filters
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'កាលបរិច្ឆេទ (Date Filter):',
                        style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
                      ),
                      const SizedBox(width: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildDateChip(ref: ref, label: 'គ្រប់ពេល (All Time)', dateKey: 'all', currentKey: selectedDate),
                          _buildDateChip(ref: ref, label: 'ថ្ងៃនេះ (Today)', dateKey: 'today', currentKey: selectedDate),
                          _buildDateChip(ref: ref, label: '៧ ថ្ងៃ (7 Days)', dateKey: '7d', currentKey: selectedDate),
                          _buildDateChip(ref: ref, label: '៣០ ថ្ងៃ (30 Days)', dateKey: '30d', currentKey: selectedDate),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Audit Logs List Card
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'បញ្ជីកំណត់ហេតុសកម្មភាព (Audit Log Entries)',
                        style: AppTextStyles.titleLG.copyWith(fontSize: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Latest 200 entries',
                          style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  logsAsync.when(
                    data: (_) {
                      if (filteredLogs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48.0),
                          child: EmptyState(
                            icon: Icons.shield_outlined,
                            title: 'មិនមានកំណត់ហេតុសវនកម្មទេ',
                            subtitle: 'មិនទាន់មានសកម្មភាពដែលត្រូវគ្នានឹងតម្រងនេះនៅឡើយទេ',
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredLogs.length,
                        separatorBuilder: (_, _) => const Divider(height: 16),
                        itemBuilder: (context, index) {
                          final log = filteredLogs[index];
                          return _buildLogRow(context, log, isDark, isDesktop);
                        },
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text('Error loading audit logs: $e', style: const TextStyle(color: AppColors.danger)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required WidgetRef ref,
    required String label,
    required String actionKey,
    required String currentKey,
    Color? color,
  }) {
    final isSelected = currentKey == actionKey;
    final chipColor = color ?? AppColors.primary;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : null,
        ),
      ),
      selected: isSelected,
      selectedColor: chipColor,
      onSelected: (_) {
        ref.read(auditActionFilterProvider.notifier).setFilter(actionKey);
      },
    );
  }

  Widget _buildDateChip({
    required WidgetRef ref,
    required String label,
    required String dateKey,
    required String currentKey,
  }) {
    final isSelected = currentKey == dateKey;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : null,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      onSelected: (_) {
        ref.read(auditDateFilterProvider.notifier).setFilter(dateKey);
      },
    );
  }

  Widget _buildLogRow(
    BuildContext context,
    AuditLogModel log,
    bool isDark,
    bool isDesktop,
  ) {
    final color = AuditDetailDialog.getActionColor(log.action);
    final icon = AuditDetailDialog.getActionIcon(log.action);

    return InkWell(
      onTap: () => AuditDetailDialog.show(context, log: log),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            // Action Icon Avatar
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),

            // Main Info: Action Pill + Details + User
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          log.action.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          log.details.isNotEmpty ? log.details : '${log.entityType} #${log.entityId}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        log.userName,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '• ${_formatRelativeDate(log.createdAt)}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (isDesktop) ...[
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                tooltip: 'View Details',
                onPressed: () => AuditDetailDialog.show(context, log: log),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
