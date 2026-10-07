import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceCounterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate next invoice number:
  /// Attempts atomic transaction when online: e.g. "INV-000142"
  /// Falls back to offline random timestamp pattern: "INV-179136-7491"
  Future<String> getNextInvoiceNumber() async {
    try {
      final counterRef = _firestore.collection('counters').doc('invoices');
      final newSeq = await _firestore.runTransaction<int>((transaction) async {
        final snapshot = await transaction.get(counterRef);
        int currentSeq = 0;
        if (snapshot.exists && snapshot.data() != null) {
          currentSeq = (snapshot.data()!['seq'] is num)
              ? (snapshot.data()!['seq'] as num).toInt()
              : 0;
        }
        final nextSeq = currentSeq + 1;
        transaction.set(counterRef, {'seq': nextSeq}, SetOptions(merge: true));
        return nextSeq;
      }).timeout(const Duration(seconds: 2));

      return 'INV-${newSeq.toString().padLeft(6, '0')}';
    } catch (_) {
      // Offline fallback: INV-<timestamp>-<rand>
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final rand = Random().nextInt(9000) + 1000;
      return 'INV-$timestamp-$rand';
    }
  }
}
