import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/firestore/models/sale_model.dart';
import '../../../data/repositories/report_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../products/providers/product_provider.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository();
});

class ReportDateRangeNotifier extends Notifier<DateTimeRange> {
  @override
  DateTimeRange build() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return DateTimeRange(start: start, end: end);
  }

  void setToday() {
    final now = DateTime.now();
    state = DateTimeRange(
      start: DateTime(now.year, now.month, now.day, 0, 0, 0),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
    );
  }

  void setLastDays(int days) {
    final now = DateTime.now();
    final startDay = now.subtract(Duration(days: days - 1));
    state = DateTimeRange(
      start: DateTime(startDay.year, startDay.month, startDay.day, 0, 0, 0),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
    );
  }

  void setCustom(DateTimeRange range) {
    state = DateTimeRange(
      start: DateTime(range.start.year, range.start.month, range.start.day, 0, 0, 0),
      end: DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59, 999),
    );
  }
}

final reportDateRangeProvider =
    NotifierProvider<ReportDateRangeNotifier, DateTimeRange>(
  ReportDateRangeNotifier.new,
);

final reportSalesProvider = StreamProvider<List<SaleModel>>((ref) {
  ref.watch(authProvider);
  final repo = ref.watch(reportRepositoryProvider);
  final range = ref.watch(reportDateRangeProvider);
  return repo.watchSalesRange(range.start, range.end);
});

final allRecentSalesProvider = StreamProvider<List<SaleModel>>((ref) {
  ref.watch(authProvider);
  final repo = ref.watch(reportRepositoryProvider);
  return repo.watchAllRecentSales(limit: 200);
});

class ReportSummary {
  final int revenue;
  final int profit;
  final int transactionCount;
  final int avgTicket;

  const ReportSummary({
    required this.revenue,
    required this.profit,
    required this.transactionCount,
    required this.avgTicket,
  });
}

final reportSummaryProvider = Provider<ReportSummary>((ref) {
  final salesAsync = ref.watch(reportSalesProvider);
  final products = ref.watch(productsStreamProvider).value ?? [];
  final productsMap = {for (var p in products) p.id: p};

  final sales = salesAsync.value ?? [];
  int revenue = 0;
  for (final s in sales) {
    revenue += s.total;
  }

  final profit = ReportRepository.calculateProfit(
    sales: sales,
    productsMap: productsMap,
  );

  final count = sales.length;
  final avg = count > 0 ? (revenue / count).round() : 0;

  return ReportSummary(
    revenue: revenue,
    profit: profit,
    transactionCount: count,
    avgTicket: avg,
  );
});
