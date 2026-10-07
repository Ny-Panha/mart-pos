import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_header.dart';
import '../../../data/firestore/models/customer_model.dart';
import '../providers/customer_provider.dart';
import 'customer_form_dialog.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleDeleteCustomer(CustomerModel customer) async {
    final repo = ref.read(customerRepositoryProvider);
    final inUse = await repo.isCustomerInUse(customer.id);

    if (inUse) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 24),
                SizedBox(width: 8),
                Text('មិនអាចលុបបានទេ (Blocked)'),
              ],
            ),
            content: Text(
              'មិនអាចលុបអតិថិជន "${customer.name}" បានទេ ព្រោះមានប្រវត្តិវិក្កយបត្រលក់ភ្ជាប់ជាមួយប្រព័ន្ធ។\n\n(Cannot delete customer with recorded sales history).',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('យល់ព្រម (OK)'),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('លុបអតិថិជន? (Delete Customer)'),
        content: Text('តើអ្នកពិតជាចង់លុប "${customer.name}" មែនទេ? សកម្មភាពនេះមិនអាចត្រឡប់វិញបានទេ។'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('បោះបង់ (Cancel)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('លុប (DELETE)', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await repo.deleteCustomer(customer.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('បានលុបអតិថិជន "${customer.name}" រួចរាល់!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final customersAsync = ref.watch(customersStreamProvider);

    return Scaffold(
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              onPressed: () => CustomerFormDialog.show(context),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.person_add_alt_1, color: Colors.white),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            PageHeader(
              eyebrow: 'Customer Relationship',
              title: 'អតិថិជន (Customer Directory)',
              description: 'Manage regular clients, track total spent and purchase history in Riel',
              actions: [
                if (isDesktop)
                  SizedBox(
                    width: 170,
                    child: AppButton(
                      text: '+ NEW CUSTOMER',
                      onPressed: () => CustomerFormDialog.show(context),
                      icon: Icons.person_add_alt_1_outlined,
                    ),
                  ),
              ],
            ),

            // Search Bar Card
            AppCard(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ស្វែងរកឈ្មោះអតិថិជន ឬលេខទូរស័ព្ទ...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              ),
            ),
            const SizedBox(height: 20),

            // Customers List
            AppCard(
              padding: const EdgeInsets.all(20),
              child: customersAsync.when(
                data: (allCustomers) {
                  final filtered = allCustomers.where((c) {
                    if (_searchQuery.isEmpty) return true;
                    final nameMatch = c.name.toLowerCase().contains(_searchQuery);
                    final phoneMatch = c.phone != null && c.phone!.contains(_searchQuery);
                    return nameMatch || phoneMatch;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: EmptyState(
                        icon: Icons.person_search_outlined,
                        title: 'គ្មានអតិថិជនទេ (No Customers Found)',
                        subtitle: 'ចុច "+ NEW CUSTOMER" ដើម្បីបង្កើតអតិថិជនថ្មីក្នុងប្រព័ន្ធ',
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 20),
                    itemBuilder: (context, index) {
                      final c = filtered[index];
                      final firstChar = c.name.isNotEmpty ? c.name.substring(0, 1) : 'C';

                      return Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: Text(
                              firstChar,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(
                                  c.phone != null && c.phone!.isNotEmpty
                                      ? 'Phone: ${c.phone}'
                                      : 'No phone number',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Total Spent:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Text(
                                MoneyUtils.formatDual(c.totalSpent),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: 'កែប្រែ (Edit)',
                                onPressed: () => CustomerFormDialog.show(context, customer: c),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                                tooltip: 'លុប (Delete)',
                                onPressed: () => _handleDeleteCustomer(c),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text('Error loading customers: $e', style: const TextStyle(color: AppColors.danger)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
