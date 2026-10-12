import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/firestore/firestore_collections.dart';
import '../../../data/firestore/models/product_model.dart';
import '../../../data/firestore/models/sale_model.dart';
import '../../../data/firestore/models/user_model.dart';
import '../../../data/firestore/shop_scope.dart';

DateTime _dateValue(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

class AttendanceRecord {
  final String id;
  final String userId;
  final String userName;
  final String status;
  final DateTime date;
  final DateTime? checkIn;
  final DateTime? checkOut;

  const AttendanceRecord({
    required this.id,
    required this.userId,
    required this.userName,
    required this.status,
    required this.date,
    this.checkIn,
    this.checkOut,
  });

  factory AttendanceRecord.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return AttendanceRecord(
      id: snapshot.id,
      userId: data['userId']?.toString() ?? '',
      userName: data['userName']?.toString() ?? data['name']?.toString() ?? '',
      status: data['status']?.toString() ?? 'present',
      date: _dateValue(data['date'] ?? data['createdAt']),
      checkIn: data['checkIn'] == null ? null : _dateValue(data['checkIn']),
      checkOut: data['checkOut'] == null ? null : _dateValue(data['checkOut']),
    );
  }
}

class AdminNotificationRecord {
  final String id;
  final String title;
  final String body;
  final String channel;
  final bool read;
  final DateTime createdAt;

  const AdminNotificationRecord({
    required this.id,
    required this.title,
    required this.body,
    required this.channel,
    required this.read,
    required this.createdAt,
  });

  factory AdminNotificationRecord.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return AdminNotificationRecord(
      id: snapshot.id,
      title: data['title']?.toString() ?? '',
      body: data['body']?.toString() ?? '',
      channel: data['channel']?.toString() ?? 'general',
      read: data['read'] == true,
      createdAt: _dateValue(data['createdAt']),
    );
  }
}

class ShopSettingsModel {
  final String shopId;
  final String shopName;
  final String phone;
  final String address;
  final String currency;
  final bool taxEnabled;

  const ShopSettingsModel({
    required this.shopId,
    this.shopName = '',
    this.phone = '',
    this.address = '',
    this.currency = 'KHR',
    this.taxEnabled = false,
  });

  factory ShopSettingsModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    String fallbackShopId,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return ShopSettingsModel(
      shopId: data['shopId']?.toString() ?? fallbackShopId,
      shopName: data['shopName']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      currency: data['currency']?.toString() ?? 'KHR',
      taxEnabled: data['taxEnabled'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
    'shopId': shopId,
    'shopName': shopName,
    'phone': phone,
    'address': address,
    'currency': currency,
    'taxEnabled': taxEnabled,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

class AdminShopService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Query<Map<String, dynamic>> _scoped(
    CollectionReference<Map<String, dynamic>> collection,
  ) {
    return ShopScope.query(collection);
  }

  Stream<List<AttendanceRecord>> watchAttendance(UserModel user) {
    return _scoped(_db.collection('attendance'))
        .orderBy('date', descending: true)
        .limit(300)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(AttendanceRecord.fromSnapshot).toList(),
        );
  }

  Stream<List<AdminNotificationRecord>> watchNotifications(UserModel user) {
    return _scoped(_db.collection('notificationLogs'))
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(AdminNotificationRecord.fromSnapshot).toList(),
        );
  }

  Stream<ShopSettingsModel> watchSettings(UserModel user) {
    final id = ShopScope.requireShopId();
    return _db
        .collection('settings')
        .doc(id)
        .snapshots()
        .map((snapshot) => ShopSettingsModel.fromSnapshot(snapshot, id));
  }

  Future<void> saveSettings(UserModel user, ShopSettingsModel settings) async {
    final id = ShopScope.requireShopId();
    await _db
        .collection('settings')
        .doc(id)
        .set(settings.toMap(), SetOptions(merge: true));
  }

  Stream<List<SaleModel>> watchSales(
    UserModel user, {
    required DateTime start,
    required DateTime end,
  }) {
    Query<SaleModel> query = ShopScope.query(FirestoreCollections.sales)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end));
    return query
        .orderBy('createdAt', descending: true)
        .limit(1000)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<ProductModel>> watchProducts(UserModel user) {
    Query<ProductModel> query = ShopScope.query(FirestoreCollections.products);
    return query
        .limit(1000)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
