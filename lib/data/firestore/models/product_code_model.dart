import 'package:cloud_firestore/cloud_firestore.dart';

class ProductCodeModel {
  final String code; // Doc id in productCodes
  final String productId;

  ProductCodeModel({
    required this.code,
    required this.productId,
  });

  factory ProductCodeModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    return ProductCodeModel(
      code: snapshot.id,
      productId: data?['productId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
    };
  }
}
