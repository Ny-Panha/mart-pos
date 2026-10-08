import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_header.dart';
import '../../../data/firestore/models/purchase_model.dart';
import '../providers/purchase_provider.dart';
import 'purchase_detail_dialog.dart';
import 'purchase_form_dialog.dart';

class PurchasesScreen extends ConsumerStatefulWidget {
  const PurchasesScreen({super.key});

  @override
  ConsumerState<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends ConsumerState<PurchasesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = Responsive.isDesktop(context);
    final purchases = ref.watch(filteredPurchasesProvider);
    final purchasesAsync = ref.watch(purchasesStreamProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            PageHeader(
              eyebrow: 'Procurement & Stock In',
              title: 'ការទិញចូល (Stock Purchases)',
              description: 'កត់ត្រា និងតាមដានការទិញទំនិញចូលស្តុកពីអ្នកផ្គត់ផ្គង់ និងថ្លៃដើមទំនិញ',
              actions: [
                SizedBox(
                  width: 190,
                  child: AppButton(
                    text: '+ NEW PURCHASE',
                    onPressed: () => PurchaseFormDialog.show(context),
                    icon: Icons.shopping_bag_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Toolbar
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        ref.read(purchaseSearchQueryProvider.notifier).setQuery(val);
                      },
                      decoration: const InputDecoration(
                        hintText: 'ស្វែងរកតាមអ្នកផ្គត់ផ្គង់, លេខវិក្កយបត្រ, ឬឈ្មោះទំនិញ...',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(purchaseSearchQueryProvider.notifier).setQuery('');
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Purchases List Card
            purchasesAsync.when(
              data: (_) {
                if (purchases.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60.0),
                    child: EmptyState(
                      icon: Icons.shopping_cart_checkout_outlined,
                      title: 'មិនទាន់មានការទិញចូលទេ (No Purchases)',
                      subtitle: 'ចុច "+ NEW PURCHASE" ដើម្បីកត់ត្រាទំនិញចូលស្តុកដំបូង',
                    ),
                  );
                }

                return AppCard(
                  padding: const EdgeInsets.all(16),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: purchases.length,
                    separatorBuilder: (_, _) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final p = purchases[index];
                      return _buildPurchaseRow(p, isDark, isDesktop);
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error loading purchases: $err', style: const TextStyle(color: AppColors.danger)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseRow(PurchaseModel p, bool isDark, bool isDesktop) {
    final totalRiel = MoneyUtils.formatRiel(p.totalCost);
    final totalUsd = MoneyUtils.formatUSD(MoneyUtils.rielToUsd(p.totalCost));
    final dateStr =
        '${p.createdAt.day.toString().padLeft(2, '0')}/${p.createdAt.month.toString().padLeft(2, '0')}/${p.createdAt.year}';
    final shortId = p.id.length > 8 ? p.id.substring(0, 8) : p.id;

    return InkWell(
      onTap: () => PurchaseDetailDialog.show(context, purchase: p),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            // Icon Badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Center(
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.secondary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Purchase Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          p.supplierName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '#$shortId',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$dateStr • ${p.items.length} មុខទំនិញ${p.note != null && p.note!.isNotEmpty ? " • ${p.note}" : ""}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Total Cost & Chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  totalRiel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  totalUsd,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
