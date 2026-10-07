import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/firestore/models/daily_close_model.dart';
import '../../../data/repositories/shift_repository.dart';
import '../../auth/providers/auth_provider.dart';

final shiftRepositoryProvider = Provider<ShiftRepository>((ref) {
  return ShiftRepository();
});

final currentOpenShiftProvider = StreamProvider<DailyCloseModel?>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return Stream.value(null);

  final repo = ref.watch(shiftRepositoryProvider);
  return repo.watchOpenShift(user.id);
});

final allShiftsStreamProvider = StreamProvider<List<DailyCloseModel>>((ref) {
  final repo = ref.watch(shiftRepositoryProvider);
  return repo.watchAllShifts();
});

final shiftSalesSummaryFutureProvider =
    FutureProvider.family<({int totalSales, int salesCount}), DailyCloseModel>((ref, shift) async {
  final repo = ref.watch(shiftRepositoryProvider);
  return repo.getShiftSalesSummary(
    cashierId: shift.cashierId,
    openedAt: shift.openedAt,
  );
});
