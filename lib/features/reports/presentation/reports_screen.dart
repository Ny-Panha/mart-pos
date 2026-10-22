import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/utils/date.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/capsule_tab_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_header.dart';
import '../providers/report_provider.dart';
import 'widgets/sale_list_tile.dart';

enum ReportRangeMode { today, sevenDays, thirtyDays, custom }

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportRangeMode _rangeMode = ReportRangeMode.today;

  Future<void> _pickCustomRange() async {
    final currentRange = ref.read(reportDateRangeProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: currentRange,
    );

    if (picked != null) {
      setState(() => _rangeMode = ReportRangeMode.custom);
      ref.read(reportDateRangeProvider.notifier).setCustom(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(reportSalesProvider);
    final summary = ref.watch(reportSummaryProvider);
    final dateRange = ref.watch(reportDateRangeProvider);

    final rangeText = '${DateUtilsHelper.formatDate(dateRange.start)} - ${DateUtilsHelper.formatDate(dateRange.end)}';

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 600 ? 16.0 : 24.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            PageHeader(
              eyebrow: 'Business Intelligence',
              title: 'របាយការណ៍លក់ (Sales Analytics & Reports)',
              description: 'Real-time sales, net profit, transaction volume, and invoice history',
              actions: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(rangeText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ),
              ],
            ),

            // Date Range Capsule Tabs (Tavola style)
            CapsuleTabBar(
              items: [
                const CapsuleTabItem(label: 'ថ្ងៃនេះ (Today)', icon: Icons.today_rounded),
                const CapsuleTabItem(label: '៧ ថ្ងៃ (7 Days)', icon: Icons.date_range_rounded),
                const CapsuleTabItem(label: '៣០ ថ្ងៃ (30 Days)', icon: Icons.calendar_view_month_rounded),
                CapsuleTabItem(
                  label: _rangeMode == ReportRangeMode.custom ? 'Custom ($rangeText)' : 'ជ្រើសរើសថ្ងៃ (Custom)',
                  icon: Icons.edit_calendar_rounded,
                ),
              ],
              selectedIndex: _rangeMode == ReportRangeMode.today
                  ? 0
                  : (_rangeMode == ReportRangeMode.sevenDays
                      ? 1
                      : (_rangeMode == ReportRangeMode.thirtyDays ? 2 : 3)),
              isDense: true,
              onTabSelected: (idx) {
                if (idx == 0) {
                  setState(() => _rangeMode = ReportRangeMode.today);
                  ref.read(reportDateRangeProvider.notifier).setToday();
                } else if (idx == 1) {
                  setState(() => _rangeMode = ReportRangeMode.sevenDays);
                  ref.read(reportDateRangeProvider.notifier).setLastDays(7);
                } else if (idx == 2) {
                  setState(() => _rangeMode = ReportRangeMode.thirtyDays);
                  ref.read(reportDateRangeProvider.notifier).setLastDays(30);
                } else {
                  _pickCustomRange();
                }
              },
            ),
            const SizedBox(height: 20),

            // Summary Metric Cards
            LayoutBuilder(builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 500 ? 2 : 1);
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: constraints.maxWidth > 900 ? 2.1 : 2.3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildSummaryCard(
                    title: 'ចំណូលសរុប (Revenue)',
                    value: MoneyUtils.formatRiel(summary.revenue),
                    subValue: MoneyUtils.formatUSD(MoneyUtils.rielToUsd(summary.revenue)),
                    icon: Icons.monetization_on_outlined,
                    color: AppColors.primary,
                  ),
                  _buildSummaryCard(
                    title: 'ប្រាក់ចំណេញដុល (Est. Profit)',
                    value: MoneyUtils.formatRiel(summary.profit),
                    subValue: MoneyUtils.formatUSD(MoneyUtils.rielToUsd(summary.profit)),
                    icon: Icons.trending_up_rounded,
                    color: AppColors.success,
                  ),
                  _buildSummaryCard(
                    title: 'ចំនួនវិក្កយបត្រ (Transactions)',
                    value: '${summary.transactionCount} Orders',
                    subValue: 'Total completed sales',
                    icon: Icons.receipt_long_outlined,
                    color: AppColors.secondary,
                  ),
                  _buildSummaryCard(
                    title: 'មធ្យមភាគ / វិក្កយបត្រ (Avg Ticket)',
                    value: MoneyUtils.formatRiel(summary.avgTicket),
                    subValue: MoneyUtils.formatUSD(MoneyUtils.rielToUsd(summary.avgTicket)),
                    icon: Icons.analytics_outlined,
                    color: AppColors.warning,
                  ),
                ],
              );
            }),
            const SizedBox(height: 24),

            // Sales Invoices Feed
            AppCard(
              isFrosted: true,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'បញ្ជីវិក្កយបត្រលក់ (Invoices in Range)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${summary.transactionCount} entries',
                        style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  salesAsync.when(
                    data: (sales) {
                      if (sales.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.0),
                          child: EmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: 'គ្មានការលក់ក្នុងចន្លោះកាលបរិច្ឆេទនេះទេ (No Sales in Range)',
                            subtitle: 'សូមជ្រើសរើសចន្លោះកាលបរិច្ឆេទផ្សេង ឬធ្វើការលក់ក្នុងផ្ទាំង POS',
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sales.length,
                        separatorBuilder: (_, _) => const Divider(height: 12),
                        itemBuilder: (context, index) {
                          return SaleListTile(sale: sales[index]);
                        },
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text('Error loading sales: $e', style: const TextStyle(color: AppColors.danger)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subValue,
    required IconData icon,
    required Color color,
  }) {
    return AppCard(
      isFrosted: true,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, maxLines: 1, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(subValue, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
