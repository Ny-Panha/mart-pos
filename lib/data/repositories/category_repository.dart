import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../firestore/firestore_collections.dart';
import '../firestore/models/category_model.dart';
import '../firestore/shop_scope.dart';
import '../services/api_service.dart';

class CategoryRepository {
  final StreamController<List<CategoryModel>> _categoriesController =
      StreamController<List<CategoryModel>>.broadcast();

  final List<CategoryModel> _defaultCategories = [
    CategoryModel(id: '1', name: 'ភេសជ្ជៈ (Drinks)', sortOrder: 1),
    CategoryModel(id: '2', name: 'នំចំណី (Snacks)', sortOrder: 2),
    CategoryModel(id: '3', name: 'អាហារ និងមី (Food)', sortOrder: 3),
    CategoryModel(id: '4', name: 'សម្ភារៈប្រើប្រាស់ (Daily)', sortOrder: 4),
  ];

  /// Refresh categories from authoritative Laravel API
  Future<List<CategoryModel>> refreshCategories() async {
    try {
      final res = await ApiService.get('/categories');
      if (res != null && res['success'] == true && res['data'] is List) {
        final list = (res['data'] as List)
            .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
            .toList();
        _categoriesController.add(list);
        return list;
      }
    } catch (e) {
      debugPrint('refreshCategories error: $e');
    }
    return [];
  }

  /// Authoritative Stream: Reads from Laravel API first.
  /// If connected, yields live MySQL categories and listens to broadcast updates.
  /// If offline/unreachable, falls back to Firestore cache.
  Stream<List<CategoryModel>> watchCategories() async* {
    List<CategoryModel>? liveCategories;
    try {
      final res = await ApiService.get('/categories');
      if (res != null && res['success'] == true && res['data'] is List) {
        liveCategories = (res['data'] as List)
            .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Laravel API watchCategories notice (offline fallback active): $e');
    }

    if (liveCategories != null) {
      yield liveCategories;
      yield* _categoriesController.stream;
    } else {
      // Offline fallback: Use Firestore cache only when Laravel is unreachable
      yield* ShopScope.query(FirestoreCollections.categories)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) {
              return _defaultCategories;
            }
            final list = snapshot.docs.map((d) => d.data()).toList();
            list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
            return list;
          });
    }
  }

  /// Authoritative Create Category:
  /// 1. Posts to Laravel API (MySQL authoritative).
  /// 2. Propagates validation or authorization failures to UI.
  /// 3. Syncs to Firestore cache with the backend-assigned ID.
  Future<CategoryModel> createCategory({
    required String name,
    int sortOrder = 0,
    String? id,
  }) async {
    final trimmedName = name.trim();

    // 1. Authoritative request to Laravel API
    final res = await ApiService.post('/categories', {
      'name': trimmedName,
    });

    if (res == null || res['success'] != true || res['data'] == null) {
      final msg = res?['message'] ?? 'Failed to create category on backend.';
      throw Exception(msg);
    }

    final serverData = res['data'] as Map<String, dynamic>;
    final createdCategory = CategoryModel.fromJson(serverData);

    // 2. Sync to Firestore cache with consistent backend ID
    try {
      final docRef = FirestoreCollections.categories.doc(createdCategory.id);
      await docRef.set(createdCategory);
    } catch (e) {
      debugPrint('Firestore category cache notice: $e');
    }

    await refreshCategories();
    return createdCategory;
  }

  /// Authoritative Update Category:
  /// 1. Updates via Laravel API.
  /// 2. Propagates errors to UI.
  /// 3. Syncs to Firestore cache.
  Future<void> updateCategory(
    String id, {
    required String name,
    int? sortOrder,
  }) async {
    final trimmedName = name.trim();

    // 1. Authoritative request to Laravel API
    final res = await ApiService.put('/categories/$id', {
      'name': trimmedName,
    });

    if (res == null || res['success'] != true) {
      final msg = res?['message'] ?? 'Failed to update category on backend.';
      throw Exception(msg);
    }

    // 2. Sync to Firestore cache
    try {
      final updateData = <String, dynamic>{'name': trimmedName};
      if (sortOrder != null) {
        updateData['sortOrder'] = sortOrder;
      }
      await FirestoreCollections.categories.doc(id).set(
        CategoryModel(id: id, name: trimmedName, sortOrder: sortOrder ?? 0),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore category update cache notice: $e');
    }

    await refreshCategories();
  }

  Future<bool> isCategoryInUse(String categoryId) async {
    try {
      final snap = await ShopScope.query(FirestoreCollections.products)
          .where('categoryId', isEqualTo: categoryId)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<int> countProductsInCategory(String categoryId) async {
    try {
      final snap = await ShopScope.query(FirestoreCollections.products)
          .where('categoryId', isEqualTo: categoryId)
          .get();
      return snap.docs.length;
    } catch (_) {
      return 0;
    }
  }

  /// Authoritative Delete Category:
  /// 1. Deletes via Laravel API (server verifies no products are attached).
  /// 2. Propagates errors to UI.
  /// 3. Removes from Firestore cache.
  Future<void> deleteCategory(String id) async {
    // 1. Authoritative delete on Laravel API
    final res = await ApiService.delete('/categories/$id');
    if (res == null || res['success'] != true) {
      final msg = res?['message'] ?? 'Failed to delete category on backend.';
      throw Exception(msg);
    }

    // 2. Remove from Firestore cache
    try {
      await FirestoreCollections.categories.doc(id).delete();
    } catch (e) {
      debugPrint('Firestore category delete cache notice: $e');
    }

    await refreshCategories();
  }
}
