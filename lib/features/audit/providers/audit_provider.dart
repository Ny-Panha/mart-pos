import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/firestore/models/audit_log_model.dart';
import '../../../data/services/audit_service.dart';

final auditLogsStreamProvider = StreamProvider<List<AuditLogModel>>((ref) {
  return AuditService.watchLogs(limit: 200);
});

/// Action group filter: 'all', 'sale', 'product', 'stock', 'purchase', 'user', 'shift'
class AuditActionFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setFilter(String action) => state = action;
}

final auditActionFilterProvider =
    NotifierProvider<AuditActionFilterNotifier, String>(
  AuditActionFilterNotifier.new,
);

/// Date filter: 'all', 'today', '7d', '30d'
class AuditDateFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setFilter(String date) => state = date;
}

final auditDateFilterProvider =
    NotifierProvider<AuditDateFilterNotifier, String>(
  AuditDateFilterNotifier.new,
);

final filteredAuditLogsProvider = Provider<List<AuditLogModel>>((ref) {
  final logs = ref.watch(auditLogsStreamProvider).value ?? [];
  final actionFilter = ref.watch(auditActionFilterProvider);
  final dateFilter = ref.watch(auditDateFilterProvider);

  final now = DateTime.now();

  return logs.where((log) {
    // 1. Action filter
    if (actionFilter != 'all') {
      if (!log.action.startsWith('$actionFilter.')) {
        return false;
      }
    }

    // 2. Date filter
    if (dateFilter != 'all') {
      if (dateFilter == 'today') {
        final startOfDay = DateTime(now.year, now.month, now.day);
        if (log.createdAt.isBefore(startOfDay)) {
          return false;
        }
      } else if (dateFilter == '7d') {
        final cutoff = now.subtract(const Duration(days: 7));
        if (log.createdAt.isBefore(cutoff)) {
          return false;
        }
      } else if (dateFilter == '30d') {
        final cutoff = now.subtract(const Duration(days: 30));
        if (log.createdAt.isBefore(cutoff)) {
          return false;
        }
      }
    }

    return true;
  }).toList();
});
