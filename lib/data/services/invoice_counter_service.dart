import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore/shop_scope.dart';

class InvoiceCounterService {
  final FirebaseFirestore? _firestoreInstance;

  InvoiceCounterService({FirebaseFirestore? firestore}) : _firestoreInstance = firestore;

  FirebaseFirestore? get _firestore {
    if (_firestoreInstance != null) return _firestoreInstance;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Generate next invoice number:
  /// Attempts atomic transaction when online: e.g. "INV-000142"
  /// Falls back to offline random timestamp pattern: "INV-179136-7491"
  Future<String> getNextInvoiceNumber() async {
    try {
      final db = _firestore;
      if (db == null) throw Exception('Firestore not available');
      final shopId = ShopScope.requireShopId();
      final counterRef = db
          .collection('counters')
          .doc('${shopId}_invoices');
      final newSeq = await db
          .runTransaction<int>((transaction) async {
            final snapshot = await transaction.get(counterRef);
            int currentSeq = 0;
            if (snapshot.exists && snapshot.data() != null) {
              currentSeq = (snapshot.data()!['seq'] is num)
                  ? (snapshot.data()!['seq'] as num).toInt()
                  : 0;
            }
            final nextSeq = currentSeq + 1;
            transaction.set(counterRef, {
              'seq': nextSeq,
              'shopId': shopId,
            }, SetOptions(merge: true));
            return nextSeq;
          })
          .timeout(const Duration(seconds: 2));

      return 'INV-${newSeq.toString().padLeft(6, '0')}';
    } catch (_) {
      // Offline fallback: INV-<timestamp>-<rand>
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final rand = Random().nextInt(9000) + 1000;
      return 'INV-$timestamp-$rand';
    }
  }
}
