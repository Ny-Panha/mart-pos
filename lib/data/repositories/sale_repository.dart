import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../firestore/firestore_collections.dart';
import '../firestore/models/held_bill_model.dart';
import '../firestore/models/sale_model.dart';
import '../firestore/models/stock_movement_model.dart';

class SaleRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<SaleModel>> watchSales() {
    return FirestoreCollections.sales
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => d.data()).toList())
        .handleError((error) {
      debugPrint('watchSales error: $error');
      return <SaleModel>[];
    });
  }

  /// Critical Rule: Checkout MUST use WriteBatch (works offline, queues in cache):
  /// 1. set sales/{id}
  /// 2. FieldValue.increment(-qty) on each product's stockQty
  /// 3. set stockMovements docs with type "out"
  /// batch.commit()
  /// NEVER use transactions for checkout (they fail when offline)
  Future<void> checkoutSale(SaleModel sale) async {
    final batch = _db.batch();

    // 1. Set sale document
    final saleDocRef = FirestoreCollections.sales.doc(sale.id);
    batch.set(saleDocRef, sale);

    // 2. Decrement stock for each item & 3. Create stock movements
    for (var item in sale.items) {
      final productDocRef = _db.collection('products').doc(item.productId);
      batch.update(productDocRef, {
        'stockQty': FieldValue.increment(-item.qty),
        'updatedAt': Timestamp.now(),
      });

      final movementRef = FirestoreCollections.stockMovements.doc();
      final movement = StockMovementModel(
        id: movementRef.id,
        productId: item.productId,
        type: 'out',
        qty: item.qty,
        note: 'POS Sale: ${sale.invoiceNumber}',
        refId: sale.id,
        createdBy: sale.cashierId,
        createdAt: DateTime.now(),
      );
      batch.set(movementRef, movement);
    }

    // Commit atomic batch
    await batch.commit();
  }

  // Held Bills
  Stream<List<HeldBillModel>> watchHeldBills() {
    return FirestoreCollections.heldBills
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => d.data()).toList());
  }

  Future<void> saveHeldBill(HeldBillModel heldBill) async {
    await FirestoreCollections.heldBills.doc(heldBill.id).set(heldBill);
  }

  Future<void> deleteHeldBill(String id) async {
    await FirestoreCollections.heldBills.doc(id).delete();
  }
}
