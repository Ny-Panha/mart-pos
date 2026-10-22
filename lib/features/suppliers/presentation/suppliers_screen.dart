import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_header.dart';
import '../../../data/firestore/models/supplier_model.dart';
import '../providers/supplier_provider.dart';
import 'supplier_detail_dialog.dart';
import 'supplier_form_dialog.dart';

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleToggleActive(SupplierModel supplier) async {
    final repo = ref.read(supplierRepositoryProvider);

    if (supplier.active) {
      // Confirm deactivation
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('ផ្អាកដំណើរការអ្នកផ្គត់ផ្គង់'),
          content: Text(
            'តើអ្នកពិតជាចង់ផ្អាកអ្នកផ្គត់ផ្គង់ "${supplier.name}" មែនទេ?\nអ្នកផ្គត់ផ្គង់ដែលផ្អាក នឹងមិនបង្ហាញក្នុងបញ្ជីបញ្ជាទិញចូលថ្មីឡើយ។',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('បោះបង់'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                minimumSize: const Size(80, 40),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ផ្អាកដំណើរការ', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm != true || !mounted) return;

      try {
        await repo.deactivateSupplier(supplier.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('បានផ្អាកអ្នកផ្គត់ផ្គង់ដោយជោគជ័យ'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                SizedBox(width: 8),
                Text('មិនអាចផ្អាកអ្នកផ្គត់ផ្គង់បានទេ'),
              ],
            ),
            content: const Text(
              'មិនអាចផ្អាកអ្នកផ្គត់ផ្គង់ដែលមានប្រវត្តិបញ្ជាទិញរួចហើយទេ (Cannot deactivate supplier with existing purchase history)។\nប្រវត្តិវិក្កយបត្រទិញចូលតម្រូវឱ្យរក្សាទុកទិន្នន័យដើមរបស់អ្នកផ្គត់ផ្គង់នេះ។',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('យល់ព្រម (OK)'),
              ),
            ],
          ),
        );
      }
    } else {
      // Reactivate
      try {
        await repo.activateSupplier(supplier.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('បានបើកដំណើរការអ្នកផ្គត់ផ្គង់ឡើងវិញ'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = Responsive.isDesktop(context);
    final suppliers = ref.watch(filteredSuppliersProvider);
    final suppliersAsync = ref.watch(suppliersStreamProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            PageHeader(
              eyebrow: 'Inventory & Procurement',
              title: 'អ្នកផ្គត់ផ្គង់ (Suppliers Directory)',
              description: 'គ្រប់គ្រងបញ្ជីក្រុមហ៊ុន និងអ្នកផ្គត់ផ្គង់ទំនិញចូលស្តុកម៉ាត',
              actions: [
                SizedBox(
                  width: 190,
                  child: AppButton(
                    text: '+ NEW SUPPLIER',
                    onPressed: () => SupplierFormDialog.show(context),
                    icon: Icons.add_business_outlined,
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
                        ref.read(supplierSearchQueryProvider.notifier).setQuery(val);
                      },
                      decoration: const InputDecoration(
                        hintText: 'ស្វែងរកតាមឈ្មោះ, លេខទូរស័ព្ទ, ឬទីតាំង...',
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
                        ref.read(supplierSearchQueryProvider.notifier).setQuery('');
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Suppliers List
            suppliersAsync.when(
              data: (_) {
                if (suppliers.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60.0),
                    child: EmptyState(
                      icon: Icons.storefront_outlined,
                      title: 'គ្មានអ្នកផ្គត់ផ្គង់ទេ (No Suppliers)',
                      subtitle: 'ចុច "+ NEW SUPPLIER" ដើម្បីបង្កើតអ្នកផ្គត់ផ្គង់ដំបូង',
                    ),
                  );
                }

                return AppCard(
                  padding: const EdgeInsets.all(16),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: suppliers.length,
                    separatorBuilder: (_, _) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final s = suppliers[index];
                      return _buildSupplierRow(s, isDark, isDesktop);
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
                child: Text('Error loading suppliers: $err', style: const TextStyle(color: AppColors.danger)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierRow(SupplierModel s, bool isDark, bool isDesktop) {
    return InkWell(
      onTap: () => SupplierDetailDialog.show(context, supplier: s),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            // Icon Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: s.active
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.lightMutedText.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: Icon(
                  Icons.storefront_rounded,
                  color: s.active ? AppColors.primary : AppColors.lightMutedText,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Name & Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          s.name,
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
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: s.active
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.lightMutedText.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          s.active ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: s.active ? AppColors.success : AppColors.lightMutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (s.phone != null && s.phone!.isNotEmpty) ...[
                        const Icon(Icons.phone_outlined, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(s.phone!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(width: 12),
                      ],
                      if (s.address != null && s.address!.isNotEmpty) ...[
                        const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            s.address!,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'View Purchases',
                  icon: const Icon(Icons.history_rounded, size: 20, color: AppColors.primary),
                  onPressed: () => SupplierDetailDialog.show(context, supplier: s),
                ),
                IconButton(
                  tooltip: 'Edit Supplier',
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => SupplierFormDialog.show(context, supplier: s),
                ),
                Switch(
                  value: s.active,
                  activeThumbColor: AppColors.success,
                  onChanged: (_) => _handleToggleActive(s),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
