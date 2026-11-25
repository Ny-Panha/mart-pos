import 'package:mart_pos/core/motion/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../models/admin_manager_models.dart';
import '../providers/admin_manager_providers.dart';
import 'manager_widgets.dart';

export 'admin_manager_stock_screen.dart';
export 'admin_manager_catalog_screen.dart';

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
                                    final confirm = await showMotionDialog<bool>(
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
// Implemented and exported in admin_manager_stock_screen.dart
// =============================================================================

// =============================================================================
// SCREEN 7 — GLOBAL PRODUCTS (Rich Cross-Shop Catalog)
// Implemented and exported in admin_manager_catalog_screen.dart
// =============================================================================

// =============================================================================
// PROVISIONING & CONFIGURATION DIALOGS
// =============================================================================

Future<void> showProvisionShopDialog(BuildContext context, WidgetRef ref) =>
    _showProvisionShop(context, ref);

Future<void> _showProvisionShop(BuildContext context, WidgetRef ref) async {
  final form = await showMotionDialog<_ShopFormValue>(
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
  final value = await showMotionDialog<_AdminFormValue>(
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
  final value = await showMotionDialog<_LocationFormValue>(
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
  final value = await showMotionDialog<_SubscriptionFormValue>(
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
