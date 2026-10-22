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
  final String email;
  final String currency;
  final bool taxEnabled;
  final double taxRate;
  final int exchangeRate;
  final String bakongId;
  final String receiptFooter;
  final String paperSize;
  final bool showBarcodeOnReceipt;
  final int lowStockThreshold;
  final bool allowNegativeStock;
  final bool notifLowStock;
  final bool notifNightlyDigest;
  final bool notifShiftAlerts;
  final String openTime;
  final String closeTime;
  final bool is24Hours;
  final String themeMode;
  final Map<String, dynamic>? weeklySchedule;

  const ShopSettingsModel({
    required this.shopId,
    this.shopName = '',
    this.phone = '',
    this.address = '',
    this.email = '',
    this.currency = 'KHR',
    this.taxEnabled = false,
    this.taxRate = 10.0,
    this.exchangeRate = 4100,
    this.bakongId = '',
    this.receiptFooter = 'ទំនិញទិញហើយមិនអាចប្តូរប្រាក់វិញបានទេ • សូមអរគុណ!',
    this.paperSize = '80mm',
    this.showBarcodeOnReceipt = true,
    this.lowStockThreshold = 5,
    this.allowNegativeStock = false,
    this.notifLowStock = true,
    this.notifNightlyDigest = true,
    this.notifShiftAlerts = true,
    this.openTime = '07:00 AM',
    this.closeTime = '10:00 PM',
    this.is24Hours = false,
    this.themeMode = 'Dark',
    this.weeklySchedule,
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
      email: data['email']?.toString() ?? '',
      currency: data['currency']?.toString() ?? 'KHR',
      taxEnabled: data['taxEnabled'] == true,
      taxRate: (data['taxRate'] as num?)?.toDouble() ?? 10.0,
      exchangeRate: (data['exchangeRate'] as num?)?.toInt() ?? 4100,
      bakongId: data['bakongId']?.toString() ?? '',
      receiptFooter: data['receiptFooter']?.toString() ??
          'ទំនិញទិញហើយមិនអាចប្តូរប្រាក់វិញបានទេ • សូមអរគុណ!',
      paperSize: data['paperSize']?.toString() ?? '80mm',
      showBarcodeOnReceipt: data['showBarcodeOnReceipt'] ?? true,
      lowStockThreshold: (data['lowStockThreshold'] as num?)?.toInt() ?? 5,
      allowNegativeStock: data['allowNegativeStock'] == true,
      notifLowStock: data['notifLowStock'] ?? true,
      notifNightlyDigest: data['notifNightlyDigest'] ?? true,
      notifShiftAlerts: data['notifShiftAlerts'] ?? true,
      openTime: data['openTime']?.toString() ?? '07:00 AM',
      closeTime: data['closeTime']?.toString() ?? '10:00 PM',
      is24Hours: data['is24Hours'] == true,
      themeMode: data['themeMode']?.toString() ?? 'Dark',
      weeklySchedule: data['weeklySchedule'] != null
          ? Map<String, dynamic>.from(data['weeklySchedule'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'shopId': shopId,
    'shopName': shopName,
    'phone': phone,
    'address': address,
    'email': email,
    'currency': currency,
    'taxEnabled': taxEnabled,
    'taxRate': taxRate,
    'exchangeRate': exchangeRate,
    'bakongId': bakongId,
    'receiptFooter': receiptFooter,
    'paperSize': paperSize,
    'showBarcodeOnReceipt': showBarcodeOnReceipt,
    'lowStockThreshold': lowStockThreshold,
    'allowNegativeStock': allowNegativeStock,
    'notifLowStock': notifLowStock,
    'notifNightlyDigest': notifNightlyDigest,
    'notifShiftAlerts': notifShiftAlerts,
    'openTime': openTime,
    'closeTime': closeTime,
    'is24Hours': is24Hours,
    'themeMode': themeMode,
    if (weeklySchedule != null) 'weeklySchedule': weeklySchedule,
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
        .limit(300)
        .snapshots()
        .map(
          (snapshot) {
            final list =
                snapshot.docs.map(AttendanceRecord.fromSnapshot).toList();
            list.sort((a, b) => b.date.compareTo(a.date));
            return list;
          },
        );
  }

  Stream<List<AdminNotificationRecord>> watchNotifications(UserModel user) {
    return _scoped(_db.collection('notificationLogs'))
        .limit(200)
        .snapshots()
        .map(
          (snapshot) {
            final list = snapshot.docs
                .map(AdminNotificationRecord.fromSnapshot)
                .toList();
            list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return list;
          },
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
