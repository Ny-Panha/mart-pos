import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_header.dart';
import '../providers/admin_shop_provider.dart';

class AdminAttendanceScreen extends ConsumerWidget {
  const AdminAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendance = ref.watch(adminAttendanceProvider);
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              eyebrow: 'Staff Management',
              title: 'វត្តមានបុគ្គលិក (Attendance Records)',
              description:
                  'តាមដានវត្តមាន ម៉ោងចូល និងចេញបម្រើការងាររបស់បុគ្គលិកក្នុងហាង',
            ),
            attendance.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Text(
                'Unable to load attendance: $error',
                style: const TextStyle(color: AppColors.danger),
              ),
              data: (records) {
                if (records.isEmpty) {
                  return const SizedBox(
                    height: 280,
                    child: EmptyState(
                      icon: Icons.fact_check_outlined,
                      title: 'No attendance records',
                      subtitle:
                          'Attendance entries will appear when staff check in.',
                    ),
                  );
                }
                return AppCard(
                  padding: EdgeInsets.zero,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: records.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final record = records[index];
                      final statusColor =
                          record.status.toLowerCase() == 'absent'
                          ? AppColors.danger
                          : AppColors.success;
                      final name = record.userName.isEmpty
                          ? record.userId
                          : record.userName;
                      final checkIn = record.checkIn == null
                          ? '—'
                          : DateUtilsHelper.formatTime(record.checkIn!);
                      final checkOut = record.checkOut == null
                          ? '—'
                          : DateUtilsHelper.formatTime(record.checkOut!);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withValues(alpha: .12),
                          child: Icon(Icons.person_outline, color: statusColor),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${DateUtilsHelper.formatDate(record.date)} • In $checkIn • Out $checkOut',
                        ),
                        trailing: Text(
                          record.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
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
