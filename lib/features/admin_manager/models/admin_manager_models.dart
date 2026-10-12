import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _date(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

String _text(Object? value, [String fallback = '']) =>
    value?.toString() ?? fallback;

int _number(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

class ShopSummary {
  final String id;
  final String name;
  final String ownerName;
  final String ownerEmail;
  final String status;
  final String subscription;
  final String phone;
  final String address;
  final DateTime? createdAt;
  final int staffCount;
  final int productCount;

  const ShopSummary({
    required this.id,
    required this.name,
    this.ownerName = '',
    this.ownerEmail = '',
    this.status = 'active',
    this.subscription = 'trial',
    this.phone = '',
    this.address = '',
    this.createdAt,
    this.staffCount = 0,
    this.productCount = 0,
  });

  factory ShopSummary.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return ShopSummary(
      id: doc.id,
      name: _text(data['name'], 'Unnamed shop'),
      ownerName: _text(data['ownerName'] ?? data['owner_name']),
      ownerEmail: _text(data['ownerEmail'] ?? data['owner_email']),
      status: _text(data['status'], 'active'),
      subscription: _text(data['subscription'] ?? data['plan'], 'trial'),
      phone: _text(data['phone']),
      address: _text(data['address']),
      createdAt: _date(data['createdAt'] ?? data['created_at']),
      staffCount: _number(data['staffCount']),
      productCount: _number(data['productCount']),
    );
  }
}

class AdminOwner {
  final String id;
  final String displayName;
  final String email;
  final String phone;
  final String shopId;
  final String shopName;
  final String role;
  final bool active;
  final DateTime? lastSeen;

  const AdminOwner({
    required this.id,
    required this.displayName,
    required this.email,
    this.phone = '',
    this.shopId = '',
    this.shopName = '',
    this.role = 'ADMIN',
    this.active = true,
    this.lastSeen,
  });

  factory AdminOwner.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return AdminOwner(
      id: doc.id,
      displayName: _text(data['displayName'] ?? data['name'], 'Unnamed user'),
      email: _text(data['email']),
      phone: _text(data['phone']),
      shopId: _text(data['shopId'] ?? data['shop_id']),
      shopName: _text(data['shopName']),
      role: _text(data['role'], 'ADMIN'),
      active: data['active'] is bool ? data['active'] as bool : true,
      lastSeen: _date(data['lastSeen'] ?? data['last_seen']),
    );
  }
}

class ShopLocation {
  final String id;
  final String shopId;
  final String name;
  final String address;
  final String phone;
  final bool active;
  final DateTime? createdAt;

  const ShopLocation({
    required this.id,
    required this.shopId,
    required this.name,
    this.address = '',
    this.phone = '',
    this.active = true,
    this.createdAt,
  });

  factory ShopLocation.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return ShopLocation(
      id: doc.id,
      shopId: _text(data['shopId'] ?? data['shop_id']),
      name: _text(data['name'], 'Unnamed location'),
      address: _text(data['address']),
      phone: _text(data['phone']),
      active: data['active'] is bool ? data['active'] as bool : true,
      createdAt: _date(data['createdAt'] ?? data['created_at']),
    );
  }
}

class SubscriptionSummary {
  final String shopId;
  final String plan;
  final String status;
  final DateTime? expiresAt;
  final int seats;

  const SubscriptionSummary({
    required this.shopId,
    this.plan = 'trial',
    this.status = 'active',
    this.expiresAt,
    this.seats = 1,
  });

  factory SubscriptionSummary.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return SubscriptionSummary(
      shopId: _text(data['shopId'] ?? doc.id),
      plan: _text(data['plan'], 'trial'),
      status: _text(data['status'], 'active'),
      expiresAt: _date(data['expiresAt'] ?? data['expires_at']),
      seats: _number(data['seats']),
    );
  }
}

class PlatformDashboard {
  final int shops;
  final int activeShops;
  final int admins;
  final int cashiers;
  final int products;
  final int lowStock;
  final int revenue;
  final int orders;
  final List<PlatformMetricPoint> revenueSeries;

  const PlatformDashboard({
    this.shops = 0,
    this.activeShops = 0,
    this.admins = 0,
    this.cashiers = 0,
    this.products = 0,
    this.lowStock = 0,
    this.revenue = 0,
    this.orders = 0,
    this.revenueSeries = const [],
  });

  factory PlatformDashboard.fromMap(Map<String, dynamic> data) {
    final rawSeries = data['revenueSeries'] ?? data['revenue_series'];
    final points = rawSeries is Iterable
        ? rawSeries.whereType<Map>().map((point) {
            return PlatformMetricPoint(
              label: _text(point['label'] ?? point['date']),
              value: _number(point['value'] ?? point['revenue']),
            );
          }).toList()
        : const <PlatformMetricPoint>[];
    return PlatformDashboard(
      shops: _number(data['shops'] ?? data['shopCount']),
      activeShops: _number(data['activeShops']),
      admins: _number(data['admins'] ?? data['adminCount']),
      cashiers: _number(data['cashiers'] ?? data['cashierCount']),
      products: _number(data['products'] ?? data['productCount']),
      lowStock: _number(data['lowStock']),
      revenue: _number(data['revenue'] ?? data['totalRevenue']),
      orders: _number(data['orders'] ?? data['orderCount']),
      revenueSeries: points,
    );
  }
}

class PlatformMetricPoint {
  final String label;
  final int value;

  const PlatformMetricPoint({required this.label, required this.value});
}

class PlatformLogEntry {
  final String id;
  final String action;
  final String actor;
  final String entity;
  final String severity;
  final String message;
  final DateTime? createdAt;

  const PlatformLogEntry({
    required this.id,
    required this.action,
    required this.actor,
    required this.entity,
    this.severity = 'info',
    this.message = '',
    this.createdAt,
  });

  factory PlatformLogEntry.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return PlatformLogEntry(
      id: doc.id,
      action: _text(data['action'], 'event'),
      actor: _text(data['actorName'] ?? data['actor'] ?? data['performedBy']),
      entity: _text(data['entity']),
      severity: _text(data['severity'], 'info'),
      message: _text(data['message'] ?? data['details']),
      createdAt: _date(data['createdAt'] ?? data['timestamp']),
    );
  }
}

class PlatformAlert {
  final String id;
  final String title;
  final String message;
  final String severity;
  final bool resolved;
  final DateTime? createdAt;

  const PlatformAlert({
    required this.id,
    required this.title,
    required this.message,
    this.severity = 'warning',
    this.resolved = false,
    this.createdAt,
  });

  factory PlatformAlert.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return PlatformAlert(
      id: doc.id,
      title: _text(data['title'], 'System alert'),
      message: _text(data['message']),
      severity: _text(data['severity'], 'warning'),
      resolved: data['resolved'] is bool ? data['resolved'] as bool : false,
      createdAt: _date(data['createdAt'] ?? data['timestamp']),
    );
  }
}

class PlatformProduct {
  final String id;
  final String shopId;
  final String shopName;
  final String name;
  final String sku;
  final String barcode;
  final int stockQty;
  final int salePrice;
  final int lowStockThreshold;

  const PlatformProduct({
    required this.id,
    required this.shopId,
    required this.name,
    this.shopName = '',
    this.sku = '',
    this.barcode = '',
    this.stockQty = 0,
    this.salePrice = 0,
    this.lowStockThreshold = 0,
  });

  factory PlatformProduct.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return PlatformProduct(
      id: doc.id,
      shopId: _text(data['shopId'] ?? data['shop_id']),
      shopName: _text(data['shopName']),
      name: _text(data['name'], 'Unnamed product'),
      sku: _text(data['sku']),
      barcode: _text(data['barcode']),
      stockQty: _number(data['stockQty'] ?? data['stock_qty']),
      salePrice: _number(data['salePrice'] ?? data['sale_price']),
      lowStockThreshold: _number(
        data['lowStockThreshold'] ?? data['low_stock_threshold'],
      ),
    );
  }
}
