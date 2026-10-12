import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/firestore/models/product_model.dart';
import '../../../data/firestore/models/sale_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/admin_shop_service.dart';

final adminShopServiceProvider = Provider<AdminShopService>(
  (ref) => AdminShopService(),
);

final adminAttendanceProvider = StreamProvider<List<AttendanceRecord>>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return Stream.value(const <AttendanceRecord>[]);
  return ref.watch(adminShopServiceProvider).watchAttendance(user);
});

final adminNotificationsProvider =
    StreamProvider<List<AdminNotificationRecord>>((ref) {
      final user = ref.watch(authProvider).value;
      if (user == null) return Stream.value(const <AdminNotificationRecord>[]);
      return ref.watch(adminShopServiceProvider).watchNotifications(user);
    });

final adminShopSettingsProvider = StreamProvider<ShopSettingsModel>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) {
    return Stream.value(const ShopSettingsModel(shopId: 'default'));
  }
  return ref.watch(adminShopServiceProvider).watchSettings(user);
});

class AdminReportRangeNotifier extends Notifier<DateTimeRange> {
  @override
  DateTimeRange build() {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
    );
  }

  void setDays(int days) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days - 1));
    state = DateTimeRange(
      start: DateTime(start.year, start.month, start.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
    );
  }
}

final adminReportRangeProvider =
    NotifierProvider<AdminReportRangeNotifier, DateTimeRange>(
      AdminReportRangeNotifier.new,
    );

final adminReportSalesProvider = StreamProvider<List<SaleModel>>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return Stream.value(const <SaleModel>[]);
  final range = ref.watch(adminReportRangeProvider);
  return ref
      .watch(adminShopServiceProvider)
      .watchSales(user, start: range.start, end: range.end);
});

final adminReportProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return Stream.value(const <ProductModel>[]);
  return ref.watch(adminShopServiceProvider).watchProducts(user);
});
