import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mart_pos/features/admin_manager/data/admin_manager_service.dart';

class _MockFunctionClient implements AdminManagerFunctionClient {
  String? lastFunctionName;
  Map<String, dynamic>? lastPayload;
  Map<String, dynamic> responseToReturn = {};
  Exception? exceptionToThrow;

  @override
  Future<Map<String, dynamic>> call(
    String functionName,
    Map<String, dynamic> payload,
  ) async {
    lastFunctionName = functionName;
    lastPayload = payload;
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return responseToReturn;
  }
}

/// Mimic cloud_functions assertion check to guarantee 100% compatibility
bool _debugIsValidParameterType(dynamic parameter) {
  if (parameter is List) {
    for (final element in parameter) {
      if (!_debugIsValidParameterType(element)) return false;
    }
    return true;
  }
  if (parameter is Map) {
    for (final key in parameter.keys) {
      if (key is! String) return false;
    }
    for (final value in parameter.values) {
      if (!_debugIsValidParameterType(value)) return false;
    }
    return true;
  }
  return parameter == null ||
      parameter is String ||
      parameter is num ||
      parameter is bool;
}

void main() {
  group('AdminManagerService Callable Serialization & Error Safety', () {
    test('getPlatformDashboard serializes DateTime parameters to UTC ISO 8601 strings', () async {
      final mockFunctions = _MockFunctionClient();
      mockFunctions.responseToReturn = {
        'shops': 5,
        'activeShops': 4,
        'admins': 3,
        'cashiers': 6,
        'products': 50,
        'lowStock': 2,
        'revenue': 1200000,
        'orders': 25,
        'revenueSeries': [
          {'label': '2026-11-20', 'value': 500000},
          {'label': '2026-11-21', 'value': 700000},
        ],
      };

      final service = AdminManagerService(
        firestore: FakeFirebaseFirestoreInstance(),
        functions: mockFunctions,
      );

      final fromDate = DateTime(2026, 11, 1, 8, 30);
      final toDate = DateTime(2026, 11, 24, 17, 45);

      final dashboard = await service.getPlatformDashboard(
        from: fromDate,
        to: toDate,
      );

      // Verify function name and payload
      expect(mockFunctions.lastFunctionName, equals('getPlatformDashboard'));
      expect(mockFunctions.lastPayload, isNotNull);

      final payload = mockFunctions.lastPayload!;
      expect(payload['from'], isA<String>());
      expect(payload['to'], isA<String>());
      expect((payload['from'] as String).endsWith('Z'), isTrue);
      expect((payload['to'] as String).endsWith('Z'), isTrue);

      // Verify that every single value in the payload strictly passes cloud_functions type validation
      expect(_debugIsValidParameterType(payload), isTrue);

      // Verify dashboard parsed properly
      expect(dashboard.shops, equals(5));
      expect(dashboard.revenue, equals(1200000));
      expect(dashboard.revenueSeries.length, equals(2));
    });

    test('getPlatformDashboard rethrows unauthenticated and permission-denied errors without swallowing', () async {
      final mockFunctions = _MockFunctionClient();
      mockFunctions.exceptionToThrow = FirebaseFunctionsException(
        code: 'unauthenticated',
        message: 'Sign-in is required.',
      );

      final service = AdminManagerService(
        firestore: FakeFirebaseFirestoreInstance(),
        functions: mockFunctions,
      );

      expect(
        () => service.getPlatformDashboard(),
        throwsA(isA<FirebaseFunctionsException>().having(
          (e) => e.code,
          'code',
          equals('unauthenticated'),
        )),
      );
    });

    test('getPlatformDashboard rethrows permission-denied error', () async {
      final mockFunctions = _MockFunctionClient();
      mockFunctions.exceptionToThrow = FirebaseFunctionsException(
        code: 'permission-denied',
        message: 'Only managers may access this dashboard.',
      );

      final service = AdminManagerService(
        firestore: FakeFirebaseFirestoreInstance(),
        functions: mockFunctions,
      );

      expect(
        () => service.getPlatformDashboard(),
        throwsA(isA<FirebaseFunctionsException>().having(
          (e) => e.code,
          'code',
          equals('permission-denied'),
        )),
      );
    });
  });
}

class FakeFirebaseFirestoreInstance implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
