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
    final result = await functions.call('getPlatformDashboard', {
      if (from != null) 'from': Timestamp.fromDate(from),
      if (to != null) 'to': Timestamp.fromDate(to),
    });
    return PlatformDashboard.fromMap(result);
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
