import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_header.dart';
import '../providers/admin_shop_provider.dart';

class AdminNotificationsScreen extends ConsumerWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(adminNotificationsProvider);
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              eyebrow: 'Shop admin',
              title: 'Notification channels',
              description: 'Review operational messages and notification channels for your shop.',
            ),
            notifications.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Text(
                'Unable to load notifications: $error',
                style: const TextStyle(color: AppColors.danger),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const SizedBox(
                    height: 280,
                    child: EmptyState(
                      icon: Icons.notifications_none_outlined,
                      title: 'No notifications',
                      subtitle: 'New channel messages will appear here.',
                    ),
                  );
                }
                return AppCard(
                  padding: EdgeInsets.zero,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final item = items[index];
                      return ListTile(
                        isThreeLine: true,
                        leading: Icon(
                          item.read
                              ? Icons.notifications_none
                              : Icons.notifications_active_outlined,
                          color: item.read ? Colors.grey : AppColors.primary,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Chip(
                              label: Text(
                                item.channel,
                                style: const TextStyle(fontSize: 10),
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${item.body}\n${DateUtilsHelper.formatDateTime(item.createdAt)}',
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
