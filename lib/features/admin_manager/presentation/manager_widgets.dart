import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/money.dart';

class ManagerPage extends StatelessWidget {
  final String title;
  final String description;
  final List<Widget> actions;
  final Widget child;

  const ManagerPage({
    super.key,
    required this.title,
    this.description = '',
    this.actions = const [],
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.all(constraints.maxWidth < 600 ? 16 : 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KAMBUJA PLATFORM',
                            style: AppTextStyles.eyebrow.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(title, style: AppTextStyles.title2XL),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              description,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (actions.isNotEmpty)
                      Wrap(spacing: 8, runSpacing: 8, children: actions),
                  ],
                ),
                const SizedBox(height: 24),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ManagerMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? footnote;

  const ManagerMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: AppRadius.mdBorder,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(value, style: AppTextStyles.titleLG),
                  if (footnote != null)
                    Text(
                      footnote!,
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: color),
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

class ManagerSectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const ManagerSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.titleLG),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class ManagerStatusChip extends StatelessWidget {
  final String label;
  final bool positive;

  const ManagerStatusChip({
    super.key,
    required this.label,
    this.positive = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = positive ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: AppRadius.pillBorder,
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

String managerDate(DateTime? date) => date == null
    ? '—'
    : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String managerMoney(int value) => MoneyUtils.formatRiel(value);

void showManagerError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(error.toString().replaceFirst('Exception: ', '')),
      backgroundColor: AppColors.danger,
    ),
  );
}

Widget managerError(Object error, VoidCallback retry) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.cloud_off_outlined,
          size: 40,
          color: AppColors.warning,
        ),
        const SizedBox(height: 12),
        const Text('Unable to load platform data'),
        const SizedBox(height: 8),
        Text(
          error.toString(),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: retry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    ),
  );
}
