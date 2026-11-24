import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/product_thumbnail.dart';
import '../models/admin_manager_models.dart';
import '../providers/admin_manager_providers.dart';
import 'manager_widgets.dart';

// =============================================================================
// SCREEN 2 — SHOPS
// =============================================================================

class AdminManagerShopsScreen extends ConsumerStatefulWidget {
  const AdminManagerShopsScreen({super.key});

  @override
  ConsumerState<AdminManagerShopsScreen> createState() =>
      _AdminManagerShopsScreenState();
}

class _AdminManagerShopsScreenState
    extends ConsumerState<AdminManagerShopsScreen> {
  String _searchQuery = '';
  String _selectedStatus = 'All';

  @override
  Widget build(BuildContext context) {
    final shopsAsync = ref.watch(managerShopsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ManagerPage(
      title: 'គ្រប់គ្រងហាង (Shops)',
      description: 'បង្កើត និងគ្រប់គ្រងសាខាហាងទាំងអស់ក្នុងប្រព័ន្ធ Platform',
      actions: [
        FilledButton.icon(
          onPressed: () => _showProvisionShop(context, ref),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          icon: const Icon(Icons.add_business_rounded, size: 18),
          label: const Text('New Shop'),
        ),
      ],
      child: shopsAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(60),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, _) =>
            managerError(error, () => ref.invalidate(managerShopsProvider)),
        data: (shops) {
          final filtered = shops.where((shop) {
            final matchesSearch = shop.name.toLowerCase().contains(_searchQuery) ||
                shop.ownerName.toLowerCase().contains(_searchQuery) ||
                shop.ownerEmail.toLowerCase().contains(_searchQuery);
            final matchesStatus = _selectedStatus == 'All' ||
                shop.status.toLowerCase() == _selectedStatus.toLowerCase();
            return matchesSearch && matchesStatus;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ManagerSearchFilterBar(
                hintText: 'ស្វែងរកហាង ឬម្ចាស់ហាង (Search shops)...',
                onSearch: (q) => setState(() => _searchQuery = q.toLowerCase()),
                filters: const ['All', 'Active', 'Inactive'],
                activeFilter: _selectedStatus,
                onFilterChanged: (f) => setState(() => _selectedStatus = f),
              ),
              const SizedBox(height: 16),
              ManagerSectionCard(
                title: '${filtered.length} Shops Registered',
                subtitle: 'Active business entities operating POS terminals',
                child: shops.isEmpty
                    ? ManagerEmptyState(
                        icon: Icons.storefront_rounded,
                        title: 'No shops created yet',
                        description:
                            'Get started by provisioning the first shop on your SaaS platform.',
                        actionLabel: 'Provision First Shop',
                        onAction: () => _showProvisionShop(context, ref),
                      )
                    : filtered.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text('No shops match your search criteria.'),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 750) {
                                return _buildMobileShopList(filtered, isDark);
                              }
                              return _buildDesktopShopTable(filtered, isDark);
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktopShopTable(List<ShopSummary> shops, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3442) : const Color(0xFFE2E8F0),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              isDark ? const Color(0xFF131722) : const Color(0xFFF8FAFC),
            ),
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text('Shop Name')),
              DataColumn(label: Text('Owner')),
              DataColumn(label: Text('Subscription')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Created Date')),
            ],
            rows: shops.map((shop) {
              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shop.name,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            if (shop.address.isNotEmpty)
                              Text(
                                shop.address,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Text(
                      shop.ownerEmail.isEmpty
                          ? shop.ownerName
                          : '${shop.ownerName} (${shop.ownerEmail})',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        shop.subscription.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    ManagerStatusChip(
                      label: shop.status,
                      positive: shop.status.toLowerCase() == 'active',
                    ),
                  ),
                  DataCell(
                    Text(
                      managerDate(shop.createdAt),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileShopList(List<ShopSummary> shops, bool isDark) {
    return Column(
      children: shops.map((shop) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131722) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF262C3A) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      shop.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ManagerStatusChip(
                    label: shop.status,
                    positive: shop.status.toLowerCase() == 'active',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (shop.address.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        shop.address,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Owner: ${shop.ownerName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      shop.subscription.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// =============================================================================
// SCREEN 3 — ADMIN OWNERS
// =============================================================================

class AdminManagerAdminsScreen extends ConsumerStatefulWidget {
  const AdminManagerAdminsScreen({super.key});

  @override
  ConsumerState<AdminManagerAdminsScreen> createState() =>
      _AdminManagerAdminsScreenState();
}

class _AdminManagerAdminsScreenState
    extends ConsumerState<AdminManagerAdminsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final shops = ref.watch(managerShopsProvider).value ?? const <ShopSummary>[];
    final adminsAsync = ref.watch(managerAdminsProvider(null));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ManagerPage(
      title: 'អ្នកគ្រប់គ្រងហាង (Admin Owners)',
      description: 'គណនីម្ចាស់ហាង និងអ្នកគ្រប់គ្រងប្រតិបត្តិការទាំងអស់',
      actions: [
        FilledButton.icon(
          onPressed: shops.isEmpty
              ? null
              : () => _showProvisionAdmin(context, ref, shops),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          icon: const Icon(Icons.person_add_rounded, size: 18),
          label: const Text('New Administrator'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner when no shops exist
          if (shops.isEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.warning.withValues(alpha: .3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No shops registered yet',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Administrator accounts must belong to a shop. Please create a shop first.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.go('/manager/shops'),
                    icon: const Icon(Icons.storefront_rounded, size: 16),
                    label: const Text('Go to Shops'),
                  ),
                ],
              ),
            ),

          ManagerSearchFilterBar(
            hintText: 'ស្វែងរក Admin តាមឈ្មោះ ឬ Email...',
            onSearch: (q) => setState(() => _searchQuery = q.toLowerCase()),
            onFilterChanged: (_) {},
          ),
          const SizedBox(height: 16),

          adminsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(60),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => managerError(
              error,
              () => ref.invalidate(managerAdminsProvider(null)),
            ),
            data: (admins) {
              final filtered = admins.where((admin) {
                return admin.displayName.toLowerCase().contains(_searchQuery) ||
                    admin.email.toLowerCase().contains(_searchQuery) ||
                    admin.shopName.toLowerCase().contains(_searchQuery);
              }).toList();

              return ManagerSectionCard(
                title: '${filtered.length} Administrators Active',
                subtitle: 'Authorized business managers and store owners',
                child: admins.isEmpty
                    ? ManagerEmptyState(
                        icon: Icons.manage_accounts_rounded,
                        title: 'No administrators found',
                        description: shops.isEmpty
                            ? 'Provision a shop first before creating administrator accounts.'
                            : 'Click "New Administrator" above to grant shop owner credentials.',
                      )
                    : filtered.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text('No administrator matches your search.'),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 750) {
                                return _buildMobileAdminList(filtered, isDark);
                              }
                              return _buildDesktopAdminTable(filtered, isDark);
                            },
                          ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopAdminTable(List<AdminOwner> admins, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3442) : const Color(0xFFE2E8F0),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              isDark ? const Color(0xFF131722) : const Color(0xFFF8FAFC),
            ),
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text('Admin Name')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Assigned Shop')),
              DataColumn(label: Text('Role')),
              DataColumn(label: Text('Status')),
            ],
            rows: admins.map((admin) {
              final initials = admin.displayName.isNotEmpty
                  ? admin.displayName.split(' ').map((p) => p.isEmpty ? '' : p[0]).take(2).join().toUpperCase()
                  : 'A';

              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: AppColors.primary.withValues(alpha: .15),
                          child: Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          admin.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text(admin.email, style: const TextStyle(fontSize: 12.5))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF262C3A) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        admin.shopName.isEmpty ? admin.shopId : admin.shopName,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  DataCell(Text(admin.role)),
                  DataCell(
                    ManagerStatusChip(
                      label: admin.active ? 'active' : 'inactive',
                      positive: admin.active,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileAdminList(List<AdminOwner> admins, bool isDark) {
    return Column(
      children: admins.map((admin) {
        final initials = admin.displayName.isNotEmpty
            ? admin.displayName.split(' ').map((p) => p.isEmpty ? '' : p[0]).take(2).join().toUpperCase()
            : 'A';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131722) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF262C3A) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: .15),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      admin.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      admin.email,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Shop: ${admin.shopName.isEmpty ? admin.shopId : admin.shopName}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFFA78BFA) : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ManagerStatusChip(
                label: admin.active ? 'active' : 'inactive',
                positive: admin.active,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// =============================================================================
// SCREEN 4 — LOCATIONS
// =============================================================================

class AdminManagerLocationsScreen extends ConsumerStatefulWidget {
  const AdminManagerLocationsScreen({super.key});

  @override
  ConsumerState<AdminManagerLocationsScreen> createState() =>
      _AdminManagerLocationsScreenState();
}

class _AdminManagerLocationsScreenState
    extends ConsumerState<AdminManagerLocationsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final shops = ref.watch(managerShopsProvider).value ?? const <ShopSummary>[];
    final locationsAsync = ref.watch(managerLocationsProvider(null));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ManagerPage(
      title: 'ទីតាំងសាខា (Locations)',
      description: 'គ្រប់គ្រងសាខាលក់ និងឃ្លាំងទំនិញតាមហាងនីមួយៗ',
      actions: [
        FilledButton.icon(
          onPressed: shops.isEmpty
              ? null
              : () => _showLocationForm(context, ref, shops),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          icon: const Icon(Icons.add_location_alt_rounded, size: 18),
          label: const Text('New Location'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ManagerSearchFilterBar(
            hintText: 'ស្វែងរកទីតាំងសាខា ឬអាសយដ្ឋាន...',
            onSearch: (q) => setState(() => _searchQuery = q.toLowerCase()),
            onFilterChanged: (_) {},
          ),
          const SizedBox(height: 16),
          locationsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(60),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => managerError(
              error,
              () => ref.invalidate(managerLocationsProvider(null)),
            ),
            data: (locations) {
              final filtered = locations.where((loc) {
                return loc.name.toLowerCase().contains(_searchQuery) ||
                    loc.address.toLowerCase().contains(_searchQuery) ||
                    loc.shopId.toLowerCase().contains(_searchQuery);
              }).toList();

              return ManagerSectionCard(
                title: '${filtered.length} Locations Configured',
                subtitle: 'Physical stores, warehouses, and checkout points',
                child: locations.isEmpty
                    ? ManagerEmptyState(
                        icon: Icons.location_on_outlined,
                        title: 'No locations configured',
                        description:
                            'Add branch locations for your registered shops.',
                        actionLabel: shops.isNotEmpty ? 'Add First Location' : null,
                        onAction: shops.isNotEmpty
                            ? () => _showLocationForm(context, ref, shops)
                            : null,
                      )
                    : Column(
                        children: filtered.map((loc) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF131722) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? const Color(0xFF262C3A) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: .12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.store_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        loc.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14.5,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        [
                                          'Shop: ${loc.shopId}',
                                          if (loc.address.isNotEmpty) loc.address,
                                          if (loc.phone.isNotEmpty) loc.phone,
                                        ].join(' • '),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ManagerStatusChip(
                                  label: loc.active ? 'active' : 'inactive',
                                  positive: loc.active,
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'Delete location',
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.danger,
                                    size: 20,
                                  ),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Location'),
                                        content: Text('Are you sure you want to delete "${loc.name}"?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          FilledButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      try {
                                        await ref
                                            .read(adminManagerServiceProvider)
                                            .deleteLocation(loc.id);
                                        ref.invalidate(managerLocationsProvider(null));
                                      } catch (error) {
                                        if (context.mounted) showManagerError(context, error);
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SCREEN 5 — SUBSCRIPTIONS
// =============================================================================

class AdminManagerSubscriptionsScreen extends ConsumerStatefulWidget {
  const AdminManagerSubscriptionsScreen({super.key});

  @override
  ConsumerState<AdminManagerSubscriptionsScreen> createState() =>
      _AdminManagerSubscriptionsScreenState();
}

class _AdminManagerSubscriptionsScreenState
    extends ConsumerState<AdminManagerSubscriptionsScreen> {
  String _searchQuery = '';
  String _selectedPlan = 'All';

  @override
  Widget build(BuildContext context) {
    final subscriptionsAsync = ref.watch(managerSubscriptionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ManagerPage(
      title: 'កញ្ចប់សេវា (Subscriptions)',
      description: 'តាមដានកញ្ចប់សេវា កំណត់ចំនួន Seat និងស្ថានភាពគណនីហាង',
      child: subscriptionsAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(60),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, _) => managerError(
          error,
          () => ref.invalidate(managerSubscriptionsProvider),
        ),
        data: (items) {
          final activeCount = items.where((s) => s.status == 'active').length;
          final totalSeats = items.fold<int>(0, (acc, s) => acc + s.seats);

          final filtered = items.where((s) {
            final matchesSearch = s.shopId.toLowerCase().contains(_searchQuery);
            final matchesPlan = _selectedPlan == 'All' ||
                s.plan.toLowerCase() == _selectedPlan.toLowerCase();
            return matchesSearch && matchesPlan;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary KPI Row
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 600;
                  return Row(
                    children: [
                      Expanded(
                        child: ManagerMetricCard(
                          compact: isCompact,
                          label: 'Total Subscriptions',
                          value: '${items.length}',
                          icon: Icons.card_membership_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ManagerMetricCard(
                          compact: isCompact,
                          label: 'Active Plans',
                          value: '$activeCount',
                          icon: Icons.verified_rounded,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ManagerMetricCard(
                          compact: isCompact,
                          label: 'Total Seats',
                          value: '$totalSeats',
                          icon: Icons.people_outline_rounded,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),

              ManagerSearchFilterBar(
                hintText: 'ស្វែងរកតាម Shop ID...',
                onSearch: (q) => setState(() => _searchQuery = q.toLowerCase()),
                filters: const ['All', 'Trial', 'Basic', 'Pro', 'Enterprise'],
                activeFilter: _selectedPlan,
                onFilterChanged: (p) => setState(() => _selectedPlan = p),
              ),
              const SizedBox(height: 16),

              ManagerSectionCard(
                title: '${filtered.length} Subscriptions Listed',
                subtitle: 'SaaS plan assignment and seat licenses',
                child: items.isEmpty
                    ? const ManagerEmptyState(
                        icon: Icons.card_membership_rounded,
                        title: 'No subscriptions recorded',
                        description:
                            'Subscription records are automatically initialized upon shop provisioning.',
                      )
                    : filtered.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text('No subscriptions match your filter.'),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 750) {
                                return _buildMobileSubscriptionList(filtered, isDark);
                              }
                              return _buildDesktopSubscriptionTable(filtered, isDark);
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktopSubscriptionTable(
      List<SubscriptionSummary> items, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3442) : const Color(0xFFE2E8F0),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              isDark ? const Color(0xFF131722) : const Color(0xFFF8FAFC),
            ),
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text('Shop ID')),
              DataColumn(label: Text('Plan Tier')),
              DataColumn(label: Text('Seats')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Expires At')),
              DataColumn(label: Text('Action')),
            ],
            rows: items.map((sub) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(sub.shopId, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        sub.plan.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${sub.seats} Seats'),
                      ],
                    ),
                  ),
                  DataCell(
                    ManagerStatusChip(
                      label: sub.status,
                      positive: sub.status.toLowerCase() == 'active',
                    ),
                  ),
                  DataCell(Text(managerDate(sub.expiresAt))),
                  DataCell(
                    OutlinedButton(
                      onPressed: () => _showSubscriptionForm(context, ref, sub),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Change'),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileSubscriptionList(
      List<SubscriptionSummary> items, bool isDark) {
    return Column(
      children: items.map((sub) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131722) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF262C3A) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Shop: ${sub.shopId}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  ManagerStatusChip(
                    label: sub.status,
                    positive: sub.status.toLowerCase() == 'active',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          sub.plan.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${sub.seats} Seats',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  OutlinedButton(
                    onPressed: () => _showSubscriptionForm(context, ref, sub),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Edit Plan'),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// =============================================================================
// SCREEN 6 — STOCK OVERVIEW (Dedicated Stock Monitoring)
// =============================================================================

class AdminManagerStockScreen extends ConsumerStatefulWidget {
  const AdminManagerStockScreen({super.key});

  @override
  ConsumerState<AdminManagerStockScreen> createState() =>
      _AdminManagerStockScreenState();
}

class _AdminManagerStockScreenState extends ConsumerState<AdminManagerStockScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final shops = ref.watch(managerShopsProvider).value ?? const <ShopSummary>[];
    final productsAsync = ref.watch(managerProductsProvider(null));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final shopNameMap = {for (final s in shops) s.id: s.name};

    return ManagerPage(
      title: 'ស្តុកសរុបប្រព័ន្ធ (Stock Overview)',
      description: 'តាមដានចំនួនស្តុកទំនិញ ទំនិញជិតអស់ និងទំនិញដាច់ស្តុកតាមហាង',
      actions: [
        OutlinedButton.icon(
          onPressed: () => ref.invalidate(managerProductsProvider(null)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Refresh'),
        ),
      ],
      child: productsAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(60),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, _) => managerError(
          error,
          () => ref.invalidate(managerProductsProvider(null)),
        ),
        data: (products) {
          final lowStockCount = products
              .where((p) => p.lowStockThreshold > 0 && p.stockQty <= p.lowStockThreshold && p.stockQty > 0)
              .length;
          final outOfStockCount = products.where((p) => p.stockQty <= 0).length;
          final healthyCount = products.length - lowStockCount - outOfStockCount;

          final filtered = products.where((p) {
            final matchesSearch = p.name.toLowerCase().contains(_searchQuery) ||
                p.sku.toLowerCase().contains(_searchQuery) ||
                p.barcode.toLowerCase().contains(_searchQuery);
            final isLow = p.lowStockThreshold > 0 && p.stockQty <= p.lowStockThreshold && p.stockQty > 0;
            final isOut = p.stockQty <= 0;

            if (_selectedFilter == 'Low Stock') return matchesSearch && isLow;
            if (_selectedFilter == 'Out of Stock') return matchesSearch && isOut;
            if (_selectedFilter == 'Healthy') return matchesSearch && !isLow && !isOut;
            return matchesSearch;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stock KPI Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 600;
                  return Row(
                    children: [
                      Expanded(
                        child: ManagerMetricCard(
                          compact: isCompact,
                          label: 'Healthy Stock',
                          value: '$healthyCount',
                          icon: Icons.check_circle_outline_rounded,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ManagerMetricCard(
                          compact: isCompact,
                          label: 'Low Stock Alert',
                          value: '$lowStockCount',
                          icon: Icons.warning_amber_rounded,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ManagerMetricCard(
                          compact: isCompact,
                          label: 'Out of Stock',
                          value: '$outOfStockCount',
                          icon: Icons.error_outline_rounded,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),

              ManagerSearchFilterBar(
                hintText: 'ស្វែងរកតាមឈ្មោះ, SKU ឬ Barcode...',
                onSearch: (q) => setState(() => _searchQuery = q.toLowerCase()),
                filters: const ['All', 'Low Stock', 'Out of Stock', 'Healthy'],
                activeFilter: _selectedFilter,
                onFilterChanged: (f) => setState(() => _selectedFilter = f),
              ),
              const SizedBox(height: 16),

              ManagerSectionCard(
                title: '${filtered.length} Stock Records',
                subtitle: 'Real-time multi-shop inventory inventory ledger',
                child: products.isEmpty
                    ? const ManagerEmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'No inventory data',
                        description: 'Products will appear here once added by shop admins.',
                      )
                    : filtered.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text('No stock items match your filter.'),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 750) {
                                return _buildMobileStockList(filtered, shopNameMap, isDark);
                              }
                              return _buildDesktopStockTable(filtered, shopNameMap, isDark);
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktopStockTable(
    List<PlatformProduct> items,
    Map<String, String> shopNameMap,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3442) : const Color(0xFFE2E8F0),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              isDark ? const Color(0xFF131722) : const Color(0xFFF8FAFC),
            ),
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text('Product')),
              DataColumn(label: Text('Shop')),
              DataColumn(label: Text('SKU / Barcode')),
              DataColumn(label: Text('Quantity')),
              DataColumn(label: Text('Price')),
              DataColumn(label: Text('Health')),
            ],
            rows: items.map((p) {
              final isOut = p.stockQty <= 0;
              final isLow = p.lowStockThreshold > 0 && p.stockQty <= p.lowStockThreshold && !isOut;
              final healthColor = isOut ? AppColors.danger : (isLow ? AppColors.warning : AppColors.success);
              final healthLabel = isOut ? 'Out of stock' : (isLow ? 'Low stock' : 'In stock');

              return DataRow(
                cells: [
                  DataCell(
                    Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  DataCell(
                    Text(p.shopName.isNotEmpty ? p.shopName : (shopNameMap[p.shopId] ?? p.shopId)),
                  ),
                  DataCell(
                    Text([p.sku, p.barcode].where((v) => v.isNotEmpty).join(' / ')),
                  ),
                  DataCell(
                    Text(
                      '${p.stockQty}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: healthColor,
                      ),
                    ),
                  ),
                  DataCell(Text(managerMoney(p.salePrice))),
                  DataCell(
                    ManagerStatusChip(
                      label: healthLabel,
                      customColor: healthColor,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileStockList(
    List<PlatformProduct> items,
    Map<String, String> shopNameMap,
    bool isDark,
  ) {
    return Column(
      children: items.map((p) {
        final isOut = p.stockQty <= 0;
        final isLow = p.lowStockThreshold > 0 && p.stockQty <= p.lowStockThreshold && !isOut;
        final healthColor = isOut ? AppColors.danger : (isLow ? AppColors.warning : AppColors.success);
        final healthLabel = isOut ? 'Out of stock' : (isLow ? 'Low stock' : 'In stock');

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131722) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF262C3A) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Shop: ${p.shopName.isNotEmpty ? p.shopName : (shopNameMap[p.shopId] ?? p.shopId)}',
                      style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                    ),
                    if (p.barcode.isNotEmpty || p.sku.isNotEmpty)
                      Text(
                        [p.sku, p.barcode].where((v) => v.isNotEmpty).join(' • '),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${p.stockQty} Qty',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: healthColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ManagerStatusChip(label: healthLabel, customColor: healthColor),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// =============================================================================
// SCREEN 7 — GLOBAL PRODUCTS (Rich Cross-Shop Catalog)
// =============================================================================

class AdminManagerCatalogScreen extends ConsumerStatefulWidget {
  const AdminManagerCatalogScreen({super.key});

  @override
  ConsumerState<AdminManagerCatalogScreen> createState() =>
      _AdminManagerCatalogScreenState();
}

class _AdminManagerCatalogScreenState
    extends ConsumerState<AdminManagerCatalogScreen> {
  String _searchQuery = '';
  String _selectedShopId = 'All';
  String _selectedCategory = 'All';
  String _selectedSort = 'Name (A-Z)';
  bool _isGridView = true;

  static String _inferCategory(String name) {
    final clean = name.toLowerCase();
    if (clean.contains('water') ||
        clean.contains('coca') ||
        clean.contains('cola') ||
        clean.contains('sting') ||
        clean.contains('drink') ||
        clean.contains('bull') ||
        clean.contains('ទឹក') ||
        clean.contains('កូកា') ||
        clean.contains('ស្តីង')) {
      return 'Beverages';
    }
    if (clean.contains('noodle') ||
        clean.contains('mama') ||
        clean.contains('cookie') ||
        clean.contains('oreo') ||
        clean.contains('snack') ||
        clean.contains('មី') ||
        clean.contains('អូរីអូ')) {
      return 'Food & Snacks';
    }
    if (clean.contains('soap') ||
        clean.contains('toothpaste') ||
        clean.contains('colgate') ||
        clean.contains('lifebuoy') ||
        clean.contains('សាប៊ូ') ||
        clean.contains('ថ្នាំដុសធ្មេញ')) {
      return 'Personal Care';
    }
    return 'General';
  }

  @override
  Widget build(BuildContext context) {
    final shops = ref.watch(managerShopsProvider).value ?? const <ShopSummary>[];
    final productsAsync = ref.watch(managerProductsProvider(null));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final shopNameMap = {for (final s in shops) s.id: s.name};

    return ManagerPage(
      title: 'កាតាឡុកទំនិញរួម (Global Products)',
      description: 'តាំងបង្ហាញមុខទំនិញ រូបភាព តម្លៃ និងព័ត៌មានលម្អិតគ្រប់សាខាទាំងអស់',
      actions: [
        // Grid / List Toggle
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2430) : const Color(0xFFEDF2F7),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.grid_view_rounded, size: 18),
                tooltip: 'Grid view',
                color: _isGridView
                    ? AppColors.primary
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                style: _isGridView
                    ? IconButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF131722) : Colors.white,
                        elevation: 1,
                      )
                    : null,
                onPressed: () => setState(() => _isGridView = true),
              ),
              IconButton(
                icon: const Icon(Icons.view_list_rounded, size: 20),
                tooltip: 'List view',
                color: !_isGridView
                    ? AppColors.primary
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                style: !_isGridView
                    ? IconButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF131722) : Colors.white,
                        elevation: 1,
                      )
                    : null,
                onPressed: () => setState(() => _isGridView = false),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => ref.invalidate(managerProductsProvider(null)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Refresh'),
        ),
      ],
      child: productsAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(60),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, _) => managerError(
          error,
          () => ref.invalidate(managerProductsProvider(null)),
        ),
        data: (products) {
          // Dynamic Category set
          final categories = <String>{'All'};
          for (final p in products) {
            final cat = p.categoryName.isNotEmpty ? p.categoryName : _inferCategory(p.name);
            categories.add(cat);
          }

          // Compute KPI metrics
          int totalValuation = 0;
          final uniqueShops = <String>{};
          for (final p in products) {
            totalValuation += p.salePrice * p.stockQty;
            if (p.shopId.isNotEmpty) uniqueShops.add(p.shopId);
          }

          // Filter products
          var filtered = products.where((p) {
            final q = _searchQuery.trim().toLowerCase();
            final matchesSearch = q.isEmpty ||
                p.name.toLowerCase().contains(q) ||
                p.barcode.toLowerCase().contains(q) ||
                p.sku.toLowerCase().contains(q) ||
                p.categoryName.toLowerCase().contains(q);

            final matchesShop =
                _selectedShopId == 'All' || p.shopId == _selectedShopId;

            final cat = p.categoryName.isNotEmpty ? p.categoryName : _inferCategory(p.name);
            final matchesCategory =
                _selectedCategory == 'All' || cat == _selectedCategory;

            return matchesSearch && matchesShop && matchesCategory;
          }).toList();

          // Sort products
          switch (_selectedSort) {
            case 'Price: Low-High':
              filtered.sort((a, b) => a.salePrice.compareTo(b.salePrice));
              break;
            case 'Price: High-Low':
              filtered.sort((a, b) => b.salePrice.compareTo(a.salePrice));
              break;
            case 'Stock: High-Low':
              filtered.sort((a, b) => b.stockQty.compareTo(a.stockQty));
              break;
            case 'Name (A-Z)':
            default:
              filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
              break;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Catalog KPI Cards (Distinguishing Catalog from Stock)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 650;
                  return isCompact
                      ? Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: ManagerMetricCard(
                                    compact: true,
                                    label: 'Catalog Items',
                                    value: '${products.length}',
                                    icon: Icons.inventory_2_rounded,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ManagerMetricCard(
                                    compact: true,
                                    label: 'Total Valuation',
                                    value: managerMoney(totalValuation),
                                    icon: Icons.account_balance_wallet_rounded,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: ManagerMetricCard(
                                    compact: true,
                                    label: 'Active Shops',
                                    value: '${uniqueShops.length}',
                                    icon: Icons.storefront_rounded,
                                    color: const Color(0xFF3B82F6),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ManagerMetricCard(
                                    compact: true,
                                    label: 'Categories',
                                    value: '${categories.length - 1 <= 0 ? 1 : categories.length - 1}',
                                    icon: Icons.category_rounded,
                                    color: const Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: ManagerMetricCard(
                                compact: false,
                                label: 'Catalog Items',
                                value: '${products.length}',
                                icon: Icons.inventory_2_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ManagerMetricCard(
                                compact: false,
                                label: 'Total Valuation',
                                value: managerMoney(totalValuation),
                                icon: Icons.account_balance_wallet_rounded,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ManagerMetricCard(
                                compact: false,
                                label: 'Active Shops',
                                value: '${uniqueShops.length}',
                                icon: Icons.storefront_rounded,
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ManagerMetricCard(
                                compact: false,
                                label: 'Categories',
                                value: '${categories.length - 1 <= 0 ? 1 : categories.length - 1}',
                                icon: Icons.category_rounded,
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        );
                },
              ),
              const SizedBox(height: 18),

              // 2. Merchandising Filter Toolbar
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131722) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF262C3A) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search + Shop filter + Sort
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 720;
                        if (isNarrow) {
                          return Column(
                            children: [
                              TextField(
                                onChanged: (q) => setState(() => _searchQuery = q),
                                decoration: InputDecoration(
                                  hintText: 'ស្វែងរកទំនិញតាមឈ្មោះ, Barcode, SKU...',
                                  prefixIcon: const Icon(Icons.search, size: 20),
                                  filled: true,
                                  fillColor: isDark
                                      ? const Color(0xFF1E2430)
                                      : const Color(0xFFF8FAFC),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildShopDropdown(shops, isDark),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildSortDropdown(isDark),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                onChanged: (q) => setState(() => _searchQuery = q),
                                decoration: InputDecoration(
                                  hintText: 'ស្វែងរកទំនិញតាមឈ្មោះ, Barcode, SKU...',
                                  prefixIcon: const Icon(Icons.search, size: 20),
                                  filled: true,
                                  fillColor: isDark
                                      ? const Color(0xFF1E2430)
                                      : const Color(0xFFF8FAFC),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: _buildShopDropdown(shops, isDark),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: _buildSortDropdown(isDark),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Horizontal Category Pills Ribbon
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.map((cat) {
                          final isSelected = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.grey[300] : const Color(0xFF475569)),
                              ),
                              backgroundColor: isDark
                                  ? const Color(0xFF1E2430)
                                  : const Color(0xFFF1F5F9),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              onSelected: (_) => setState(() => _selectedCategory = cat),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Products Presentation
              ManagerSectionCard(
                title: '${filtered.length} Products Cataloged',
                subtitle: 'Platform-wide cross-shop visual merchandise showcase',
                child: products.isEmpty
                    ? const ManagerEmptyState(
                        icon: Icons.category_outlined,
                        title: 'No products cataloged',
                        description: 'Products added by shops will be displayed here.',
                      )
                    : filtered.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
                                  SizedBox(height: 12),
                                  Text(
                                    'No products match your search or filter.',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _isGridView
                            ? _buildVisualGrid(filtered, shopNameMap, isDark)
                            : _buildVisualList(filtered, shopNameMap, isDark),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShopDropdown(List<ShopSummary> shops, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedShopId,
          isExpanded: true,
          icon: const Icon(Icons.storefront_outlined, size: 18),
          dropdownColor: isDark ? const Color(0xFF1A202C) : Colors.white,
          items: [
            const DropdownMenuItem(
              value: 'All',
              child: Text('All Shops', style: TextStyle(fontSize: 13)),
            ),
            ...shops.map((s) => DropdownMenuItem(
                  value: s.id,
                  child: Text(
                    s.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                )),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _selectedShopId = val);
          },
        ),
      ),
    );
  }

  Widget _buildSortDropdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSort,
          isExpanded: true,
          icon: const Icon(Icons.sort_rounded, size: 18),
          dropdownColor: isDark ? const Color(0xFF1A202C) : Colors.white,
          items: const [
            DropdownMenuItem(
              value: 'Name (A-Z)',
              child: Text('Name (A-Z)', style: TextStyle(fontSize: 13)),
            ),
            DropdownMenuItem(
              value: 'Price: Low-High',
              child: Text('Price: Low → High', style: TextStyle(fontSize: 13)),
            ),
            DropdownMenuItem(
              value: 'Price: High-Low',
              child: Text('Price: High → Low', style: TextStyle(fontSize: 13)),
            ),
            DropdownMenuItem(
              value: 'Stock: High-Low',
              child: Text('Highest Stock', style: TextStyle(fontSize: 13)),
            ),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _selectedSort = val);
          },
        ),
      ),
    );
  }

  Widget _buildVisualGrid(
    List<PlatformProduct> items,
    Map<String, String> shopNameMap,
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1100
            ? 4
            : (width >= 750 ? 3 : (width >= 480 ? 2 : 1));

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 295,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final p = items[index];
            final shopName = p.shopName.isNotEmpty
                ? p.shopName
                : (shopNameMap[p.shopId] ?? p.shopId);

            return Material(
              color: isDark ? const Color(0xFF131722) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showProductDetails(context, p, shopName, isDark),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF262C3A) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Hero Product Photo Container with Badges
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                            child: Container(
                              height: 135,
                              width: double.infinity,
                              color: isDark ? const Color(0xFF1A202C) : const Color(0xFFF1F5F9),
                              child: Center(
                                child: ProductThumbnail(
                                  imageUrl: p.imageUrl,
                                  productId: p.id,
                                  productName: p.name,
                                  barcode: p.barcode,
                                  width: double.infinity,
                                  height: 135,
                                  fit: BoxFit.contain,
                                  borderRadius: 0,
                                  backgroundColor: Colors.transparent,
                                ),
                              ),
                            ),
                          ),
                          // Top-Left Category Badge
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Text(
                                p.categoryName.isNotEmpty ? p.categoryName : _inferCategory(p.name),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ),
                          // Top-Right Stock Badge
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: p.stockQty <= 0
                                    ? AppColors.danger
                                    : (p.stockQty <= p.lowStockThreshold
                                        ? AppColors.warning
                                        : AppColors.success),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                p.stockQty <= 0
                                    ? 'Out of stock'
                                    : (p.stockQty <= p.lowStockThreshold
                                        ? 'Low: ${p.stockQty}'
                                        : '${p.stockQty} in stock'),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // 2. Card Body
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                      height: 1.25,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.storefront_outlined,
                                        size: 12,
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          shopName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (p.barcode.isNotEmpty || p.sku.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      [
                                        if (p.barcode.isNotEmpty) 'Barcode: ${p.barcode}',
                                        if (p.sku.isNotEmpty) 'SKU: ${p.sku}',
                                      ].join(' • '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: Colors.grey,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              // 3. Price & View Details CTA
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        managerMoney(p.salePrice),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.success,
                                        ),
                                      ),
                                      if (p.unit.isNotEmpty)
                                        Text(
                                          '/ ${p.unit}',
                                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                                        ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Details',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        SizedBox(width: 2),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          size: 14,
                                          color: AppColors.primary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVisualList(
    List<PlatformProduct> items,
    Map<String, String> shopNameMap,
    bool isDark,
  ) {
    return Column(
      children: items.map((p) {
        final shopName = p.shopName.isNotEmpty
            ? p.shopName
            : (shopNameMap[p.shopId] ?? p.shopId);

        return Material(
          color: isDark ? const Color(0xFF131722) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _showProductDetails(context, p, shopName, isDark),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF262C3A) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 68,
                      height: 68,
                      color: isDark ? const Color(0xFF1A202C) : const Color(0xFFF1F5F9),
                      child: Center(
                        child: ProductThumbnail(
                          imageUrl: p.imageUrl,
                          productId: p.id,
                          productName: p.name,
                          barcode: p.barcode,
                          width: 68,
                          height: 68,
                          fit: BoxFit.contain,
                          borderRadius: 10,
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                p.categoryName.isNotEmpty ? p.categoryName : _inferCategory(p.name),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            Text(
                              shopName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        if (p.barcode.isNotEmpty || p.sku.isNotEmpty)
                          Text(
                            [
                              if (p.barcode.isNotEmpty) 'Barcode: ${p.barcode}',
                              if (p.sku.isNotEmpty) 'SKU: ${p.sku}',
                            ].join(' • '),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontFamily: 'monospace',
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        managerMoney(p.salePrice),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: p.stockQty <= 0
                              ? AppColors.danger.withValues(alpha: 0.15)
                              : (p.stockQty <= p.lowStockThreshold
                                  ? AppColors.warning.withValues(alpha: 0.15)
                                  : AppColors.success.withValues(alpha: 0.15)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p.stockQty <= 0
                              ? 'Out of stock'
                              : (p.stockQty <= p.lowStockThreshold
                                  ? 'Low: ${p.stockQty}'
                                  : '${p.stockQty} in stock'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: p.stockQty <= 0
                                ? AppColors.danger
                                : (p.stockQty <= p.lowStockThreshold
                                    ? AppColors.warning
                                    : AppColors.success),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showProductDetails(
    BuildContext context,
    PlatformProduct p,
    String shopName,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        final marginPercent = (p.costPrice > 0 && p.salePrice > p.costPrice)
            ? (((p.salePrice - p.costPrice) / p.salePrice) * 100).toStringAsFixed(1)
            : null;

        return Dialog(
          backgroundColor: isDark ? const Color(0xFF131722) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.inventory_2_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Product Details',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Big Photo Preview
                    Center(
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A202C) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: ProductThumbnail(
                            imageUrl: p.imageUrl,
                            productId: p.id,
                            productName: p.name,
                            barcode: p.barcode,
                            width: 180,
                            height: 180,
                            fit: BoxFit.contain,
                            borderRadius: 16,
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Name & Shop
                    Text(
                      p.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            p.categoryName.isNotEmpty ? p.categoryName : _inferCategory(p.name),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.storefront_outlined, size: 13, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                shopName,
                                style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    // Detailed specs
                    _buildModalRow('Sale Price', managerMoney(p.salePrice), isHighlight: true),
                    if (p.costPrice > 0)
                      _buildModalRow('Cost Price', managerMoney(p.costPrice)),
                    if (marginPercent != null)
                      _buildModalRow('Profit Margin', '+$marginPercent%', isSuccess: true),
                    _buildModalRow('Stock Level', '${p.stockQty} ${p.unit}'),
                    _buildModalRow('Low Stock Alert', '≤ ${p.lowStockThreshold} ${p.unit}'),
                    if (p.barcode.isNotEmpty)
                      _buildModalRow('Barcode', p.barcode),
                    if (p.sku.isNotEmpty)
                      _buildModalRow('SKU', p.sku),
                    _buildModalRow('Product ID', p.id),
                    _buildModalRow('Shop ID', p.shopId),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalRow(
    String label,
    String value, {
    bool isHighlight = false,
    bool isSuccess = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: isHighlight
                  ? AppColors.success
                  : (isSuccess ? const Color(0xFF10B981) : null),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// PROVISIONING & CONFIGURATION DIALOGS
// =============================================================================

Future<void> _showProvisionShop(BuildContext context, WidgetRef ref) async {
  final form = await showDialog<_ShopFormValue>(
    context: context,
    builder: (_) => const _ShopFormDialog(),
  );
  if (form == null || !context.mounted) return;
  try {
    await ref.read(adminManagerServiceProvider).provisionShop(
          name: form.name,
          ownerName: form.ownerName,
          ownerEmail: form.ownerEmail,
          phone: form.phone,
          address: form.address,
        );
    ref.invalidate(managerShopsProvider);
  } catch (error) {
    if (context.mounted) showManagerError(context, error);
  }
}

Future<void> _showProvisionAdmin(
  BuildContext context,
  WidgetRef ref,
  List<ShopSummary> shops,
) async {
  final value = await showDialog<_AdminFormValue>(
    context: context,
    builder: (_) => _AdminFormDialog(shops: shops),
  );
  if (value == null || !context.mounted) return;
  try {
    await ref.read(adminManagerServiceProvider).provisionShopAdmin(
          shopId: value.shopId,
          displayName: value.name,
          email: value.email,
          temporaryPassword: value.password,
        );
    ref.invalidate(managerAdminsProvider(null));
  } catch (error) {
    if (context.mounted) showManagerError(context, error);
  }
}

Future<void> _showLocationForm(
  BuildContext context,
  WidgetRef ref,
  List<ShopSummary> shops,
) async {
  final value = await showDialog<_LocationFormValue>(
    context: context,
    builder: (_) => _LocationFormDialog(shops: shops),
  );
  if (value == null || !context.mounted) return;
  try {
    await ref.read(adminManagerServiceProvider).createLocation(
          shopId: value.shopId,
          name: value.name,
          address: value.address,
          phone: value.phone,
        );
    ref.invalidate(managerLocationsProvider(null));
  } catch (error) {
    if (context.mounted) showManagerError(context, error);
  }
}

Future<void> _showSubscriptionForm(
  BuildContext context,
  WidgetRef ref,
  SubscriptionSummary item,
) async {
  final value = await showDialog<_SubscriptionFormValue>(
    context: context,
    builder: (_) => _SubscriptionFormDialog(item: item),
  );
  if (value == null || !context.mounted) return;
  try {
    await ref.read(adminManagerServiceProvider).setShopSubscription(
          shopId: item.shopId,
          plan: value.plan,
          status: value.status,
          seats: value.seats,
        );
    ref.invalidate(managerSubscriptionsProvider);
  } catch (error) {
    if (context.mounted) showManagerError(context, error);
  }
}

class _ShopFormValue {
  final String name, ownerName, ownerEmail, phone, address;
  const _ShopFormValue(
    this.name,
    this.ownerName,
    this.ownerEmail,
    this.phone,
    this.address,
  );
}

class _AdminFormValue {
  final String shopId, name, email, password;
  const _AdminFormValue(this.shopId, this.name, this.email, this.password);
}

class _LocationFormValue {
  final String shopId, name, address, phone;
  const _LocationFormValue(this.shopId, this.name, this.address, this.phone);
}

class _SubscriptionFormValue {
  final String plan, status;
  final int seats;
  const _SubscriptionFormValue(this.plan, this.status, this.seats);
}

class _ShopFormDialog extends StatefulWidget {
  const _ShopFormDialog();
  @override
  State<_ShopFormDialog> createState() => _ShopFormDialogState();
}

class _ShopFormDialogState extends State<_ShopFormDialog> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(),
      ownerName = TextEditingController(),
      ownerEmail = TextEditingController(),
      phone = TextEditingController(),
      address = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    ownerName.dispose();
    ownerEmail.dispose();
    phone.dispose();
    address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Provision Shop'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(name, 'Shop Name'),
                  _field(ownerName, 'Owner Name'),
                  _field(ownerEmail, 'Owner Email', email: true),
                  _field(phone, 'Phone Number', required: false),
                  _field(address, 'Address', required: false),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(
                  context,
                  _ShopFormValue(
                    name.text.trim(),
                    ownerName.text.trim(),
                    ownerEmail.text.trim(),
                    phone.text.trim(),
                    address.text.trim(),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Provision'),
          ),
        ],
      );
}

class _AdminFormDialog extends StatefulWidget {
  final List<ShopSummary> shops;
  const _AdminFormDialog({required this.shops});
  @override
  State<_AdminFormDialog> createState() => _AdminFormDialogState();
}

class _AdminFormDialogState extends State<_AdminFormDialog> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController();
  String? shopId;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Create Administrator'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: shopId,
                    decoration: const InputDecoration(labelText: 'Assigned Shop'),
                    items: widget.shops
                        .map(
                          (shop) => DropdownMenuItem(
                            value: shop.id,
                            child: Text(shop.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => shopId = value),
                    validator: (value) => value == null ? 'Select a shop' : null,
                  ),
                  const SizedBox(height: 12),
                  _field(name, 'Full Name'),
                  _field(email, 'Email Address', email: true),
                  _field(
                    password,
                    'Temporary Password',
                    required: false,
                    obscure: true,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(
                  context,
                  _AdminFormValue(
                    shopId!,
                    name.text.trim(),
                    email.text.trim(),
                    password.text.trim(),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Create'),
          ),
        ],
      );
}

class _LocationFormDialog extends StatefulWidget {
  final List<ShopSummary> shops;
  const _LocationFormDialog({required this.shops});
  @override
  State<_LocationFormDialog> createState() => _LocationFormDialogState();
}

class _LocationFormDialogState extends State<_LocationFormDialog> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(),
      address = TextEditingController(),
      phone = TextEditingController();
  String? shopId;

  @override
  void dispose() {
    name.dispose();
    address.dispose();
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('New Location'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: shopId,
                    decoration: const InputDecoration(labelText: 'Shop'),
                    items: widget.shops
                        .map(
                          (shop) => DropdownMenuItem(
                            value: shop.id,
                            child: Text(shop.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => shopId = value),
                    validator: (value) => value == null ? 'Select a shop' : null,
                  ),
                  const SizedBox(height: 12),
                  _field(name, 'Location Name'),
                  _field(address, 'Address', required: false),
                  _field(phone, 'Phone', required: false),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(
                  context,
                  _LocationFormValue(
                    shopId!,
                    name.text.trim(),
                    address.text.trim(),
                    phone.text.trim(),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Create'),
          ),
        ],
      );
}

class _SubscriptionFormDialog extends StatefulWidget {
  final SubscriptionSummary item;
  const _SubscriptionFormDialog({required this.item});
  @override
  State<_SubscriptionFormDialog> createState() =>
      _SubscriptionFormDialogState();
}

class _SubscriptionFormDialogState extends State<_SubscriptionFormDialog> {
  late String plan = widget.item.plan, status = widget.item.status;
  late final seats = TextEditingController(
    text: '${widget.item.seats == 0 ? 1 : widget.item.seats}',
  );

  @override
  void dispose() {
    seats.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Edit Subscription · ${widget.item.shopId}'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: plan,
                decoration: const InputDecoration(labelText: 'Plan Tier'),
                items: const ['trial', 'basic', 'pro', 'enterprise']
                    .map(
                      (v) => DropdownMenuItem(value: v, child: Text(v.toUpperCase())),
                    )
                    .toList(),
                onChanged: (v) => setState(() => plan = v ?? plan),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Account Status'),
                items: const ['active', 'paused', 'cancelled']
                    .map(
                      (v) => DropdownMenuItem(value: v, child: Text(v.toUpperCase())),
                    )
                    .toList(),
                onChanged: (v) => setState(() => status = v ?? status),
              ),
              const SizedBox(height: 12),
              _field(seats, 'Allocated Seats', keyboard: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              _SubscriptionFormValue(
                plan,
                status,
                int.tryParse(seats.text.trim()) ?? 1,
              ),
            ),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save Changes'),
          ),
        ],
      );
}

Widget _field(
  TextEditingController controller,
  String label, {
  bool email = false,
  bool required = true,
  bool obscure = false,
  TextInputType? keyboard,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard ?? (email ? TextInputType.emailAddress : null),
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) return 'Field is required';
              if (email && !value.contains('@')) return 'Enter a valid email address';
              return null;
            }
          : null,
    ),
  );
}
