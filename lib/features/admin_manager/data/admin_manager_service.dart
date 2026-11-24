import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/admin_manager_models.dart';

/// The names and payloads used by the privileged manager endpoints.
///
/// The app deliberately keeps these calls behind an interface. This lets the
/// UI be shipped before the callable Functions package is wired into the
/// client, without ever falling back to unrestricted client-side writes.
abstract interface class AdminManagerFunctionClient {
  Future<Map<String, dynamic>> call(
    String functionName,
    Map<String, dynamic> payload,
  );
}

class CloudFunctionContractUnavailable implements AdminManagerFunctionClient {
  const CloudFunctionContractUnavailable();

  @override
  Future<Map<String, dynamic>> call(
    String functionName,
    Map<String, dynamic> payload,
  ) {
    return Future.error(
      UnsupportedError(
        'Cloud Function "$functionName" is not configured in this client. '
        'Connect the callable Firebase Functions adapter before using this action.',
      ),
    );
  }
}

/// Production adapter for the manager-only callable Functions.
///
/// All privileged mutations go through this adapter. The Firestore service
/// never writes manager-owned documents directly, so security remains in the
/// Functions authorization layer as well as Firestore rules.
class FirebaseAdminManagerFunctionClient implements AdminManagerFunctionClient {
  final FirebaseFunctions functions;

  FirebaseAdminManagerFunctionClient({FirebaseFunctions? functions})
    : functions = functions ?? FirebaseFunctions.instance;

  @override
  Future<Map<String, dynamic>> call(
    String functionName,
    Map<String, dynamic> payload,
  ) async {
    final callable = functions.httpsCallable(functionName);
    final result = await callable.call<Map<String, dynamic>>(payload);
    return Map<String, dynamic>.from(result.data);
  }
}

class AdminManagerService {
  final FirebaseFirestore firestore;
  final AdminManagerFunctionClient functions;

  const AdminManagerService({required this.firestore, required this.functions});

  CollectionReference<Map<String, dynamic>> get _shops =>
      firestore.collection('shops');
  CollectionReference<Map<String, dynamic>> get _users =>
      firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _locations =>
      firestore.collection('locations');
  CollectionReference<Map<String, dynamic>> get _subscriptions =>
      firestore.collection('subscriptions');
  CollectionReference<Map<String, dynamic>> get _logs =>
      firestore.collection('managerLogs');
  CollectionReference<Map<String, dynamic>> get _alerts =>
      firestore.collection('platformAlerts');
  CollectionReference<Map<String, dynamic>> get _products =>
      firestore.collection('products');

  /// These streams intentionally use collection-level queries only. Firestore
  /// rules decide which manager claims may read them; no client-side
  /// `get()` is used to bypass those rules.
  Stream<List<ShopSummary>> watchShops() => _shops.snapshots().map(
    (snapshot) => snapshot.docs.map(ShopSummary.fromDocument).toList(),
  );

  Stream<List<AdminOwner>> watchAdmins({String? shopId}) {
    Query<Map<String, dynamic>> query = _users.where(
      'role',
      whereIn: const ['ADMIN', 'ADMIN_MANAGER'],
    );
    if (shopId != null && shopId.isNotEmpty) {
      query = query.where('shopId', isEqualTo: shopId);
    }
    return query.snapshots().map(
      (snapshot) => snapshot.docs.map(AdminOwner.fromDocument).toList(),
    );
  }

  Stream<List<ShopLocation>> watchLocations({String? shopId}) {
    Query<Map<String, dynamic>> query = _locations;
    if (shopId != null && shopId.isNotEmpty) {
      query = query.where('shopId', isEqualTo: shopId);
    }
    return query.snapshots().map(
      (snapshot) => snapshot.docs.map(ShopLocation.fromDocument).toList(),
    );
  }

  Stream<List<SubscriptionSummary>> watchSubscriptions() =>
      _subscriptions.snapshots().map(
        (snapshot) =>
            snapshot.docs.map(SubscriptionSummary.fromDocument).toList(),
      );

  Stream<List<PlatformLogEntry>> watchLogs({int limit = 50}) => _logs
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(PlatformLogEntry.fromDocument).toList(),
      );

  Stream<List<PlatformAlert>> watchAlerts({bool unresolvedOnly = false}) {
    Query<Map<String, dynamic>> query = _alerts.orderBy(
      'createdAt',
      descending: true,
    );
    if (unresolvedOnly) query = query.where('resolved', isEqualTo: false);
    return query.snapshots().map(
      (snapshot) => snapshot.docs.map(PlatformAlert.fromDocument).toList(),
    );
  }

  Stream<List<PlatformProduct>> watchProducts({String? shopId}) {
    final Query<Map<String, dynamic>> query =
        shopId != null && shopId.isNotEmpty
        ? _products.where('shopId', isEqualTo: shopId)
        : _products;
    return query.snapshots().map(
      (snapshot) => snapshot.docs.map(PlatformProduct.fromDocument).toList(),
    );
  }

  Future<PlatformDashboard> getPlatformDashboard({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final result = await functions.call('getPlatformDashboard', {
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
      });
      return PlatformDashboard.fromMap(result);
    } catch (e) {
      // Do not silently hide authentication, permission, or argument validation errors.
      if (e is FirebaseFunctionsException) {
        if (e.code == 'unauthenticated' ||
            e.code == 'permission-denied' ||
            e.code == 'invalid-argument') {
          rethrow;
        }
      }

      // Fallback directly to Firestore collections if Cloud Functions are not deployed, unauthenticated on endpoint, or unreachable
      try {
        final shopsSnap = await _shops.get();
        final usersSnap = await _users.get();
        final productsSnap = await _products.get();
        final salesSnap = await firestore.collection('sales').get();

        final shops = shopsSnap.docs.map((d) => d.data()).toList();
        final users = usersSnap.docs.map((d) => d.data()).toList();
        final products = productsSnap.docs.map((d) => d.data()).toList();
        final sales = salesSnap.docs.map((d) => d.data()).toList();

        final activeShops = shops
            .where((s) => (s['status'] ?? 'active').toString().toLowerCase() == 'active')
            .length;
        final admins = users
            .where((u) => u['role']?.toString().toUpperCase() == 'ADMIN')
            .length;
        final cashiers = users
            .where((u) => u['role']?.toString().toUpperCase() == 'CASHIER')
            .length;
        final lowStock = products.where((p) {
          final stock = (p['stockQty'] is num) ? (p['stockQty'] as num).toInt() : 0;
          final threshold = (p['lowStockThreshold'] is num) ? (p['lowStockThreshold'] as num).toInt() : 5;
          return stock <= threshold;
        }).length;

        int totalRevenue = 0;
        final Map<String, int> revenueMap = {};

        for (final s in sales) {
          final total = (s['total'] is num) ? (s['total'] as num).toInt() : 0;

          DateTime? date;
          final createdAt = s['createdAt'];
          if (createdAt is Timestamp) {
            date = createdAt.toDate();
          } else if (createdAt is String) {
            date = DateTime.tryParse(createdAt);
          }
          if (date != null) {
            if (from != null && date.isBefore(from)) continue;
            if (to != null && date.isAfter(to)) continue;

            totalRevenue += total;
            final key =
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            revenueMap[key] = (revenueMap[key] ?? 0) + total;
          } else {
            totalRevenue += total;
          }
        }

        final sortedKeys = revenueMap.keys.toList()..sort();
        final series = sortedKeys
            .map((k) => PlatformMetricPoint(label: k, value: revenueMap[k]!))
            .toList();

        return PlatformDashboard(
          shops: shops.length,
          activeShops: activeShops,
          admins: admins,
          cashiers: cashiers,
          products: products.length,
          lowStock: lowStock,
          revenue: totalRevenue,
          orders: sales.length,
          revenueSeries: series,
        );
      } catch (fallbackError) {
        throw Exception(
          'Failed to load platform data: $e (Firestore fallback error: $fallbackError)',
        );
      }
    }
  }

  Future<Map<String, dynamic>> provisionShop({
    required String name,
    required String ownerName,
    required String ownerEmail,
    String phone = '',
    String address = '',
  }) {
    return functions.call('provisionShop', {
      'name': name.trim(),
      'ownerName': ownerName.trim(),
      'ownerEmail': ownerEmail.trim(),
      if (phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (address.trim().isNotEmpty) 'address': address.trim(),
    });
  }

  Future<Map<String, dynamic>> provisionShopAdmin({
    required String shopId,
    required String displayName,
    required String email,
    String temporaryPassword = '',
  }) {
    return functions.call('provisionShopAdmin', {
      'shopId': shopId,
      'displayName': displayName.trim(),
      'email': email.trim(),
      if (temporaryPassword.trim().isNotEmpty)
        'temporaryPassword': temporaryPassword.trim(),
    });
  }

  Future<Map<String, dynamic>> setShopSubscription({
    required String shopId,
    required String plan,
    required String status,
    required int seats,
  }) {
    return functions.call('setShopSubscription', {
      'shopId': shopId,
      'plan': plan,
      'status': status,
      'seats': seats,
    });
  }

  Future<Map<String, dynamic>> createLocation({
    required String shopId,
    required String name,
    String address = '',
    String phone = '',
  }) {
    return functions.call('createShopLocation', {
      'shopId': shopId,
      'name': name.trim(),
      'address': address.trim(),
      'phone': phone.trim(),
    });
  }

  Future<Map<String, dynamic>> updateLocation({
    required String locationId,
    required String name,
    String address = '',
    String phone = '',
    bool active = true,
  }) {
    return functions.call('updateShopLocation', {
      'locationId': locationId,
      'name': name.trim(),
      'address': address.trim(),
      'phone': phone.trim(),
      'active': active,
    });
  }

  Future<Map<String, dynamic>> deleteLocation(String locationId) =>
      functions.call('deleteShopLocation', {'locationId': locationId});

  Future<Map<String, dynamic>> updatePlatformSettings(
    Map<String, dynamic> settings,
  ) => functions.call('updatePlatformSettings', {'settings': settings});

  Future<Map<String, dynamic>> resolveAlert(String alertId) =>
      functions.call('resolvePlatformAlert', {'alertId': alertId});

  Future<Map<String, dynamic>> setPosAccess({
    required String shopId,
    required bool enabled,
  }) => functions.call('setShopPosAccess', {
    'shopId': shopId,
    'enabled': enabled,
  });
}
