import 'package:cloud_firestore/cloud_firestore.dart';

class ProductCodeModel {
  final String code; // Normalized product code
  final String productId;

  ProductCodeModel({required this.code, required this.productId});

  factory ProductCodeModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    final idParts = snapshot.id.split('__');
    return ProductCodeModel(
      code:
          data?['code']?.toString() ??
          (idParts.length > 1 ? idParts.skip(1).join('__') : snapshot.id),
      productId: data?['productId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'code': code, 'productId': productId};
  }
}
