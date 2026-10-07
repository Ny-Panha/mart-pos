import 'package:flutter/material.dart';
import '../models/shift_model.dart';

class ShiftProvider extends ChangeNotifier {
  ShiftModel _currentShift = ShiftModel(
    id: 'shift_today',
    cashierName: 'នី បញ្ញា',
    openedAt: DateTime.now().subtract(const Duration(hours: 4)),
    openingCash: 50.0,
    totalSales: 0.0,
    countedCash: 0.0,
    difference: 0.0,
    isClosed: false,
  );

  final List<ShiftModel> _history = [];

  ShiftModel get currentShift => _currentShift;
  List<ShiftModel> get history => List.unmodifiable(_history);
  bool get isShiftOpen => !_currentShift.isClosed;

  void addSaleToShift(double saleAmount) {
    if (isShiftOpen) {
      _currentShift = ShiftModel(
        id: _currentShift.id,
        cashierName: _currentShift.cashierName,
        openedAt: _currentShift.openedAt,
        openingCash: _currentShift.openingCash,
        totalSales: _currentShift.totalSales + saleAmount,
        countedCash: _currentShift.countedCash,
        difference: _currentShift.difference,
        isClosed: false,
      );
      notifyListeners();
    }
  }

  void closeShift({
    required double countedCash,
    required String note,
  }) {
    final double expected = _currentShift.openingCash + _currentShift.totalSales;
    final double diff = countedCash - expected;

    final closed = ShiftModel(
      id: _currentShift.id,
      cashierName: _currentShift.cashierName,
      openedAt: _currentShift.openedAt,
      closedAt: DateTime.now(),
      openingCash: _currentShift.openingCash,
      totalSales: _currentShift.totalSales,
      countedCash: countedCash,
      difference: diff,
      note: note,
      isClosed: true,
    );

    _history.insert(0, closed);
    _currentShift = closed;
    notifyListeners();
  }

  void openNewShift({required String cashierName, required double openingCash}) {
    _currentShift = ShiftModel(
      id: 'shift_${DateTime.now().millisecondsSinceEpoch}',
      cashierName: cashierName,
      openedAt: DateTime.now(),
      openingCash: openingCash,
      totalSales: 0.0,
      countedCash: 0.0,
      difference: 0.0,
      isClosed: false,
    );
    notifyListeners();
  }
}
