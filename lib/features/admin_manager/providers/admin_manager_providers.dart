import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_manager_service.dart';
import '../models/admin_manager_models.dart';

final adminManagerFunctionClientProvider = Provider<AdminManagerFunctionClient>(
  (ref) {
    return FirebaseAdminManagerFunctionClient();
  },
);

final adminManagerServiceProvider = Provider<AdminManagerService>((ref) {
  return AdminManagerService(
    firestore: FirebaseFirestore.instance,
    functions: ref.watch(adminManagerFunctionClientProvider),
  );
});

final managerShopsProvider = StreamProvider<List<ShopSummary>>((ref) {
  return ref.watch(adminManagerServiceProvider).watchShops();
});

final managerAdminsProvider = StreamProvider.family<List<AdminOwner>, String?>((
  ref,
  shopId,
) {
  return ref.watch(adminManagerServiceProvider).watchAdmins(shopId: shopId);
});

final managerLocationsProvider =
    StreamProvider.family<List<ShopLocation>, String?>((ref, shopId) {
      return ref
          .watch(adminManagerServiceProvider)
          .watchLocations(shopId: shopId);
    });

final managerSubscriptionsProvider = StreamProvider<List<SubscriptionSummary>>((
  ref,
) {
  return ref.watch(adminManagerServiceProvider).watchSubscriptions();
});

final managerLogsProvider = StreamProvider<List<PlatformLogEntry>>((ref) {
  return ref.watch(adminManagerServiceProvider).watchLogs();
});

final managerAlertsProvider = StreamProvider<List<PlatformAlert>>((ref) {
  return ref.watch(adminManagerServiceProvider).watchAlerts();
});

final managerProductsProvider =
    StreamProvider.family<List<PlatformProduct>, String?>((ref, shopId) {
      return ref
          .watch(adminManagerServiceProvider)
          .watchProducts(shopId: shopId);
    });

final managerDashboardProvider = FutureProvider<PlatformDashboard>((ref) {
  return ref
      .watch(adminManagerServiceProvider)
      .getPlatformDashboard(
        from: DateTime.now().subtract(const Duration(days: 30)),
        to: DateTime.now(),
      );
});
