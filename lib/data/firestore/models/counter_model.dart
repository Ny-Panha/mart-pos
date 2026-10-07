import 'package:cloud_firestore/cloud_firestore.dart';

class CounterModel {
  final String id; // e.g. "invoices"
  final int seq;

  CounterModel({
    required this.id,
    required this.seq,
  });

  factory CounterModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    return CounterModel(
      id: snapshot.id,
      seq: (data?['seq'] is num) ? (data!['seq'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'seq': seq,
    };
  }
}
