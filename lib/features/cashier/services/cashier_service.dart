import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/firestore/firestore_collections.dart';
import '../../../data/firestore/models/product_model.dart';
import '../../../data/firestore/models/sale_model.dart';
import '../../../data/firestore/models/user_model.dart';
import '../../../data/firestore/shop_scope.dart';

class CashierService {
  Query<SaleModel> _salesQuery(UserModel user) {
    Query<SaleModel> query = ShopScope.query(FirestoreCollections.sales)
        .where('cashierId', isEqualTo: user.id);
    return query.orderBy('createdAt', descending: true).limit(200);
  }

  Stream<List<SaleModel>> watchOwnSales(UserModel user) {
    return _salesQuery(user)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<ProductModel>> watchStock(UserModel user) {
    Query<ProductModel> query = ShopScope.query(FirestoreCollections.products);
    return query
        .orderBy('name')
        .limit(500)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<SaleModel?> findOwnSale(UserModel user, String saleId) async {
    final snapshot = await _salesQuery(user).get();
    for (final doc in snapshot.docs) {
      if (doc.id == saleId || doc.data().invoiceNumber == saleId) {
        return doc.data();
      }
    }
    return null;
  }
}
