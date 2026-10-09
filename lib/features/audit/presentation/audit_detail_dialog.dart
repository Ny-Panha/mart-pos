import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/firestore/models/audit_log_model.dart';

class AuditDetailDialog extends StatelessWidget {
  final AuditLogModel log;

  const AuditDetailDialog({super.key, required this.log});

  static Future<void> show(BuildContext context, {required AuditLogModel log}) {
    if (Responsive.isDesktop(context) || Responsive.isTablet(context)) {
      return showDialog<void>(
        context: context,
        builder: (_) => AuditDetailDialog(log: log),
      );
    } else {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AuditDetailDialog(log: log),
      );
    }
  }

  static Color getActionColor(String action) {
    if (action.startsWith('sale.')) return AppColors.success;
    if (action.startsWith('product.')) return AppColors.primary;
    if (action.startsWith('stock.')) return AppColors.warning;
    if (action.startsWith('purchase.')) return AppColors.secondary;
    if (action.startsWith('user.')) return Colors.indigo;
    if (action.startsWith('shift.')) return Colors.deepOrange;
    return Colors.grey;
  }

  static IconData getActionIcon(String action) {
    if (action.startsWith('sale.')) return Icons.receipt_long_rounded;
    if (action.startsWith('product.')) return Icons.inventory_2_outlined;
    if (action.startsWith('stock.')) return Icons.swap_vert_circle_outlined;
    if (action.startsWith('purchase.')) return Icons.shopping_bag_outlined;
    if (action.startsWith('user.')) return Icons.badge_outlined;
    if (action.startsWith('shift.')) return Icons.punch_clock_outlined;
    return Icons.history_toggle_off_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = Responsive.isDesktop(context) || Responsive.isTablet(context);
    final color = getActionColor(log.action);
    final icon = getActionIcon(log.action);

    final dateStr =
        '${log.createdAt.day.toString().padLeft(2, '0')}/${log.createdAt.month.toString().padLeft(2, '0')}/${log.createdAt.year} '
        '${log.createdAt.hour.toString().padLeft(2, '0')}:${log.createdAt.minute.toString().padLeft(2, '0')}:${log.createdAt.second.toString().padLeft(2, '0')}';

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          log.action.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: color,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: AppTextStyles.caption.copyWith(
                      color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Info container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            children: [
              _buildDetailItem(
                context,
                icon: Icons.person_outline,
                label: 'ប្រតិបត្តិការដោយ (Performed By):',
                value: '${log.userName} (${log.userId})',
              ),
              const Divider(height: 18),
              _buildDetailItem(
                context,
                icon: Icons.category_outlined,
                label: 'ប្រភេទ & លេខសម្គាល់ (Entity):',
                value: '${log.entityType.toUpperCase()} #${log.entityId}',
              ),
              const Divider(height: 18),
              _buildDetailItem(
                context,
                icon: Icons.notes_rounded,
                label: 'ព័ត៌មានលម្អិត (Details):',
                value: log.details.isNotEmpty ? log.details : 'None',
                isHighlight: true,
                color: color,
              ),
              const Divider(height: 18),
              _buildDetailItem(
                context,
                icon: Icons.fingerprint_rounded,
                label: 'លេខសម្គាល់ Log (Log ID):',
                value: log.id,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('បិទ (Close)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );

    if (isDesktop) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(child: content),
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(child: content),
      );
    }
  }

  Widget _buildDetailItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isHighlight = false,
    Color? color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              SelectableText(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                  color: isHighlight && color != null ? color : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
