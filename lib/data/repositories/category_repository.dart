import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../firestore/firestore_collections.dart';
import '../firestore/models/category_model.dart';
import '../firestore/shop_scope.dart';

class CategoryRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<CategoryModel> _defaultCategories = [
    CategoryModel(id: 'cat_drinks', name: 'ភេសជ្ជៈ (Drinks)', sortOrder: 1),
    CategoryModel(id: 'cat_food', name: 'អាហារ និងមី (Food)', sortOrder: 2),
    CategoryModel(id: 'cat_snacks', name: 'នំចំណី (Snacks)', sortOrder: 3),
    CategoryModel(
      id: 'cat_daily',
      name: 'សម្ភារៈប្រើប្រាស់ (Daily)',
      sortOrder: 4,
    ),
  ];

  Stream<List<CategoryModel>> watchCategories() {
    return ShopScope.query(FirestoreCollections.categories)
        .orderBy('sortOrder')
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            seedDefaultCategories();
            return _defaultCategories;
          }
          return snapshot.docs.map((d) => d.data()).toList();
        })
        .handleError((error) {
          debugPrint('Firestore watchCategories error: $error');
          return _defaultCategories;
        });
  }

  Future<void> seedDefaultCategories() async {
    try {
      final batch = _db.batch();
      for (final cat in _defaultCategories) {
        batch.set(FirestoreCollections.categories.doc(cat.id), cat);
      }
      await batch.commit();
      debugPrint('Default categories seeded successfully!');
    } catch (e) {
      debugPrint('Default categories seed skipped: $e');
    }
  }

  Future<CategoryModel> createCategory({
    required String name,
    int sortOrder = 0,
    String? id,
  }) async {
    final docRef = id != null
        ? FirestoreCollections.categories.doc(id)
        : FirestoreCollections.categories.doc();

    final category = CategoryModel(
      id: docRef.id,
      name: name.trim(),
      sortOrder: sortOrder,
      createdAt: DateTime.now(),
    );

    await docRef.set(category);
    return category;
  }

  Future<void> updateCategory(
    String id, {
    required String name,
    int? sortOrder,
  }) async {
    final updateData = <String, dynamic>{'name': name.trim()};
    if (sortOrder != null) {
      updateData['sortOrder'] = sortOrder;
    }
    await FirestoreCollections.categories.doc(id).update(updateData);
  }

  Future<bool> isCategoryInUse(String categoryId) async {
    final snap = await ShopScope.query(FirestoreCollections.products)
        .where('categoryId', isEqualTo: categoryId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<int> countProductsInCategory(String categoryId) async {
    final snap = await ShopScope.query(FirestoreCollections.products)
        .where('categoryId', isEqualTo: categoryId)
        .get();
    return snap.docs.length;
  }

  Future<void> deleteCategory(String id) async {
    final inUse = await isCategoryInUse(id);
    if (inUse) {
      throw Exception(
        'Category is currently assigned to one or more products and cannot be deleted.',
      );
    }
    await FirestoreCollections.categories.doc(id).delete();
  }
}
