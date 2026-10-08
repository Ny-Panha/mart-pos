import '../../core/utils/money.dart';
import '../firestore/firestore_collections.dart';
import '../firestore/models/daily_close_model.dart';
import '../firestore/models/sale_model.dart';
import '../services/audit_service.dart';

class ShiftRepository {
  /// Watches the active open shift for a specific cashier
  Stream<DailyCloseModel?> watchOpenShift(String cashierId) {
    return FirestoreCollections.dailyCloses
        .where('cashierId', isEqualTo: cashierId)
        .where('closedAt', isNull: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return snapshot.docs.first.data();
        });
  }

  /// Watches all closed and open shifts for history reporting
  Stream<List<DailyCloseModel>> watchAllShifts() {
    return FirestoreCollections.dailyCloses
        .orderBy('openedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Opens a new cashier shift with opening float cash
  Future<DailyCloseModel> openShift({
    required String cashierId,
    required int openingCash,
  }) async {
    // If cashier already has an active open shift, return it
    final existing = await FirestoreCollections.dailyCloses
        .where('cashierId', isEqualTo: cashierId)
        .where('closedAt', isNull: true)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.data();
    }

    final docRef = FirestoreCollections.dailyCloses.doc();
    final newShift = DailyCloseModel(
      id: docRef.id,
      cashierId: cashierId,
      openedAt: DateTime.now(),
      openingCash: openingCash,
      totalSales: 0,
      salesCount: 0,
    );

    await docRef.set(newShift);
    return newShift;
  }

  /// Fetches sales completed during the shift window [openedAt, now]
  Future<List<SaleModel>> getSalesForShift({
    required String cashierId,
    required DateTime openedAt,
    DateTime? closedAt,
  }) async {
    final end = closedAt ?? DateTime.now();

    try {
      final snapshot = await FirestoreCollections.sales
          .where('cashierId', isEqualTo: cashierId)
          .where('createdAt', isGreaterThanOrEqualTo: openedAt)
          .where('createdAt', isLessThanOrEqualTo: end)
          .get();
      return snapshot.docs.map((d) => d.data()).toList();
    } catch (_) {
      // Graceful fallback for offline / index building
      final snapshot = await FirestoreCollections.sales
          .where('createdAt', isGreaterThanOrEqualTo: openedAt)
          .where('createdAt', isLessThanOrEqualTo: end)
          .get();
      return snapshot.docs
          .map((d) => d.data())
          .where((s) => s.cashierId == cashierId)
          .toList();
    }
  }

  /// Previews total sales and count for an ongoing shift
  Future<({int totalSales, int salesCount})> getShiftSalesSummary({
    required String cashierId,
    required DateTime openedAt,
  }) async {
    final sales = await getSalesForShift(
      cashierId: cashierId,
      openedAt: openedAt,
    );

    int totalSales = 0;
    for (final sale in sales) {
      totalSales += sale.total;
    }

    return (totalSales: totalSales, salesCount: sales.length);
  }

  /// Closes an open cashier shift and writes final reconciliation to Firestore
  Future<DailyCloseModel> closeShift({
    required String shiftId,
    required String cashierId,
    required int actualCash,
    String? cashierName,
  }) async {
    final shiftDoc = await FirestoreCollections.dailyCloses.doc(shiftId).get();
    if (!shiftDoc.exists || shiftDoc.data() == null) {
      throw Exception('Shift doc not found: $shiftId');
    }

    final currentShift = shiftDoc.data()!;
    final now = DateTime.now();

    final summary = await getShiftSalesSummary(
      cashierId: cashierId,
      openedAt: currentShift.openedAt,
    );

    final difference = calculateDifference(
      openingCash: currentShift.openingCash,
      totalSales: summary.totalSales,
      actualCash: actualCash,
    );

    final closedShift = DailyCloseModel(
      id: shiftId,
      cashierId: cashierId,
      openedAt: currentShift.openedAt,
      closedAt: now,
      openingCash: currentShift.openingCash,
      totalSales: summary.totalSales,
      salesCount: summary.salesCount,
      actualCash: actualCash,
      difference: difference,
    );

    await FirestoreCollections.dailyCloses.doc(shiftId).set(closedShift);

    final diffStr = difference == 0
        ? '0 ៛'
        : (difference > 0 ? '+${MoneyUtils.formatRiel(difference)}' : MoneyUtils.formatRiel(difference));

    // Fire-and-forget Audit Log
    AuditService.log(
      userId: cashierId,
      userName: cashierName ?? 'Cashier $cashierId',
      action: 'shift.close',
      entityType: 'shift',
      entityId: shiftId,
      details: 'Diff: $diffStr · Actual: ${MoneyUtils.formatRiel(actualCash)}',
    );

    return closedShift;
  }

  /// Pure helper: difference = actualCash - (openingCash + totalSales)
  static int calculateDifference({
    required int openingCash,
    required int totalSales,
    required int actualCash,
  }) {
    return actualCash - (openingCash + totalSales);
  }

  /// Pure helper: expectedCash = openingCash + totalSales
  static int calculateExpectedCash({
    required int openingCash,
    required int totalSales,
  }) {
    return openingCash + totalSales;
  }
}
