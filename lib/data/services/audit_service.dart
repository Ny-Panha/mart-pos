import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../firestore/firestore_collections.dart';
import '../firestore/models/audit_log_model.dart';
import '../firestore/shop_scope.dart';

class AuditService {
  /// Fire-and-forget logging to `auditLogs` collection.
  /// Never throws to caller, works offline via Firestore local cache.
  static Future<void> log({
    required String userId,
    required String userName,
    required String action,
    required String entityType,
    required String entityId,
    String details = '',
  }) async {
    try {
      final docRef = FirestoreCollections.auditLogs.doc();
      final logDoc = AuditLogModel(
        id: docRef.id,
        userId: userId,
        userName: userName,
        action: action,
        entityType: entityType,
        entityId: entityId,
        details: details,
        createdAt: DateTime.now(),
      );
      await docRef.set(logDoc);
    } catch (e) {
      // Swallows error to ensure business operations are never blocked
      debugPrint('AuditService.log error (swallowed): $e');
    }
  }

  /// Helper reading current user from `authProvider` via `WidgetRef` or `Ref`
  static Future<void> logFromRef(
    dynamic ref, {
    required String action,
    required String entityType,
    required String entityId,
    String details = '',
  }) async {
    try {
      String uid = 'system';
      String name = 'System';
      try {
        if (ref is WidgetRef) {
          final user = ref.read(authProvider).value;
          if (user != null) {
            uid = user.id;
            name = user.name;
          }
        } else if (ref is Ref) {
          final user = ref.read(authProvider).value;
          if (user != null) {
            uid = user.id;
            name = user.name;
          }
        }
      } catch (_) {
        // Fallback to system user if authProvider not accessible
      }

      await log(
        userId: uid,
        userName: name,
        action: action,
        entityType: entityType,
        entityId: entityId,
        details: details,
      );
    } catch (e) {
      debugPrint('AuditService.logFromRef error (swallowed): $e');
    }
  }

  /// Watch audit logs stream ordered by `createdAt` desc with limit (default 200).
  static Stream<List<AuditLogModel>> watchLogs({int limit = 200}) {
    return ShopScope.query(FirestoreCollections.auditLogs)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((d) => d.data()).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        })
        .handleError((error) {
          debugPrint('watchLogs error: $error');
          return <AuditLogModel>[];
        });
  }
}
