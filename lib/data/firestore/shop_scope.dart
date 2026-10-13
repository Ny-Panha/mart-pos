import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/user_model.dart';

/// Current shop context used to scope every shop-owned Firestore query.
/// Security is still enforced by Firestore Rules; this only builds compliant queries.
class ShopScope {
  ShopScope._();

  static String? _shopId;
  static String? _userId;
  static bool _isManager = false;
  static bool _isCashier = false;

  static String? get shopId => _shopId;
  static bool get isManager => _isManager;
  static bool get isCashier => _isCashier;
  static String? get userId => _userId;

  static String requireShopId() {
    final id = _shopId ?? UserModel.defaultShopId;
    if (id.isEmpty) {
      throw StateError('A shop account is required for this operation.');
    }
    return id;
  }

  static void setUser(UserModel? user) {
    _shopId = user?.shopId;
    _userId = user?.id;
    _isManager = user?.isManager ?? false;
    _isCashier = user?.isCashier ?? false;
  }

  static Query<T> query<T>(CollectionReference<T> collection) {
    return collection.where('shopId', isEqualTo: requireShopId());
  }
}
