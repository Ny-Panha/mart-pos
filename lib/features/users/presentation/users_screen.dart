import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/page_header.dart';
import '../../../data/firestore/models/user_model.dart';
import '../../../data/repositories/shift_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../shifts/providers/shift_provider.dart';
import '../providers/user_provider.dart';
import 'user_form_dialog.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleToggleActive(
    UserModel user,
    List<UserModel> allUsers,
  ) async {
    final newActive = !user.active;

    if (!newActive) {
      // Check if user is the last active admin
      final canDeactivate = UserRepository.canDeactivateUser(
        allUsers: allUsers,
        targetUid: user.id,
      );

      if (!canDeactivate) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                SizedBox(width: 8),
                Text('មិនអាចផ្អាកគណនីបានទេ'),
              ],
            ),
            content: const Text(
              'មិនអាចផ្អាកដំណើរការ Admin ចុងក្រោយបង្អស់បានឡើយ (Cannot deactivate the last active admin).\nប្រព័ន្ធត្រូវតែមាន Admin សកម្មយ៉ាងតិចម្នាក់។',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('យល់ព្រម (OK)'),
              ),
            ],
          ),
        );
        return;
      }

      // Confirm deactivation
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('ផ្អាកដំណើរការគណនី (Deactivate User)'),
          content: Text(
            'តើអ្នកពិតជាចង់ផ្អាកគណនីរបស់ "${user.name}" មែនទេ?\nគណនីនេះនឹងមិនអាចចូលប្រើប្រាស់បានទៀតទេ រហូតដល់បើកដំណើរការឡើងវិញ។',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('បោះបង់ (Cancel)'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ផ្អាកដំណើរការ (Deactivate)'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    try {
      final currentAdmin = ref.read(authProvider).value;
      await ref
          .read(userRepositoryProvider)
          .setUserActive(
            user.id,
            newActive,
            adminId: currentAdmin?.id,
            adminName: currentAdmin?.name,
            targetUserName: user.name,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newActive
                  ? 'បានបើកដំណើរការ "${user.name}" ឡើងវិញ'
                  : 'បានផ្អាកដំណើរការ "${user.name}" រួចរាល់',
            ),
            backgroundColor: newActive
                ? AppColors.success
                : Colors.orange.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            PageHeader(
              eyebrow: 'Access Control & Shifts',
              title: 'បុគ្គលិក និងវេនលក់ (Staff & Shifts)',
              description: 'គ្រប់គ្រងគណនី Cashier និងតាមដានប្រវត្តិបិទវេនលក់',
              actions: [
                SizedBox(
                  width: 170,
                  child: AppButton(
                    text: '+ ADD STAFF',
                    icon: Icons.person_add_alt_rounded,
                    onPressed: () => UserFormDialog.show(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: isDark
                    ? AppColors.darkMutedText
                    : AppColors.lightMutedText,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.people_alt_outlined, size: 18),
                    text: 'បុគ្គលិក (Staff Accounts)',
                  ),
                  Tab(
                    icon: Icon(Icons.history_rounded, size: 18),
                    text: 'ប្រវត្តិវេនលក់ (Shift History)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tab Content
            SizedBox(
              height: 750,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildStaffListTab(isDark),
                  _buildShiftHistoryTab(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffListTab(bool isDark) {
    final usersAsync = ref.watch(usersStreamProvider);
    final filteredUsers = ref.watch(filteredUsersProvider);

    return Column(
      children: [
        // Search Toolbar
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (val) =>
                    ref.read(userSearchQueryProvider.notifier).setQuery(val),
                decoration: InputDecoration(
                  hintText: 'ស្វែងរកឈ្មោះបុគ្គលិក ឬ UID...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(userSearchQueryProvider.notifier)
                                .setQuery('');
                          },
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Users List
        Expanded(
          child: usersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Text(
                'Error: $err',
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
            data: (allUsers) {
              if (filteredUsers.isEmpty) {
                return const EmptyState(
                  icon: Icons.person_off_outlined,
                  title: 'រកមិនឃើញបុគ្គលិកទេ',
                  subtitle:
                      'សូមចុចប៊ូតុង "+ ADD STAFF" ដើម្បីបង្កើតគណនីបុគ្គលិកថ្មី',
                );
              }

              return AppCard(
                padding: const EdgeInsets.all(16),
                child: ListView.separated(
                  itemCount: filteredUsers.length,
                  separatorBuilder: (_, _) => const Divider(height: 20),
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    final isAdmin = user.isAdmin;

                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor:
                              (isAdmin
                                      ? AppColors.primary
                                      : AppColors.secondary)
                                  .withValues(alpha: 0.12),
                          child: Icon(
                            isAdmin
                                ? Icons.admin_panel_settings_rounded
                                : Icons.point_of_sale_rounded,
                            color: isAdmin
                                ? AppColors.primary
                                : AppColors.secondary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    user.name,
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          (isAdmin
                                                  ? AppColors.primary
                                                  : AppColors.secondary)
                                              .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      user.role.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isAdmin
                                            ? AppColors.primary
                                            : AppColors.secondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'UID: ${user.id}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkMutedText
                                      : AppColors.lightMutedText,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Active Status Switch
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  user.active
                                      ? 'Active (សកម្ម)'
                                      : 'Inactive (អសកម្ម)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: user.active
                                        ? AppColors.success
                                        : Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Switch(
                                  value: user.active,
                                  activeThumbColor: AppColors.success,
                                  onChanged: (_) =>
                                      _handleToggleActive(user, allUsers),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Edit Button
                        IconButton(
                          tooltip: 'Edit Profile',
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () =>
                              UserFormDialog.show(context, user: user),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShiftHistoryTab(bool isDark) {
    final shiftsAsync = ref.watch(allShiftsStreamProvider);
    final users = ref.watch(usersStreamProvider).value ?? [];
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

    String getCashierName(String cashierId) {
      final match = users.where((u) => u.id == cashierId);
      if (match.isNotEmpty) return match.first.name;
      return cashierId.length > 8
          ? '${cashierId.substring(0, 8)}...'
          : cashierId;
    }

    return shiftsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Text(
          'Error loading shifts: $err',
          style: const TextStyle(color: AppColors.danger),
        ),
      ),
      data: (shifts) {
        if (shifts.isEmpty) {
          return const EmptyState(
            icon: Icons.history_toggle_off_rounded,
            title: 'មិនទាន់មានប្រវត្តិវេនលក់ទេ',
            subtitle:
                'នៅពេលអ្នកគិតលុយបើក និងបិទវេនលក់ ទិន្នន័យនឹងបង្ហាញនៅទីនេះ',
          );
        }

        return AppCard(
          padding: const EdgeInsets.all(16),
          child: ListView.separated(
            itemCount: shifts.length,
            separatorBuilder: (_, _) => const Divider(height: 20),
            itemBuilder: (context, index) {
              final shift = shifts[index];
              final isOpen = shift.closedAt == null;
              final cashierName = getCashierName(shift.cashierId);
              final expectedCash = ShiftRepository.calculateExpectedCash(
                openingCash: shift.openingCash,
                totalSales: shift.totalSales,
              );
              final difference = shift.difference;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isOpen ? AppColors.primary : Colors.grey)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isOpen ? Icons.lock_open_rounded : Icons.lock_rounded,
                          color: isOpen
                              ? AppColors.primary
                              : Colors.grey.shade700,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Cashier: $cashierName',
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (isOpen
                                                ? AppColors.primary
                                                : AppColors.success)
                                            .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isOpen ? 'OPEN' : 'CLOSED',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isOpen
                                          ? AppColors.primary
                                          : AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isOpen
                                  ? 'Opened: ${dateFormatter.format(shift.openedAt)}'
                                  : 'Opened: ${dateFormatter.format(shift.openedAt)}  •  Closed: ${dateFormatter.format(shift.closedAt!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkMutedText
                                    : AppColors.lightMutedText,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Difference highlight badge
                      if (!isOpen && difference != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (difference < 0
                                        ? AppColors.danger
                                        : AppColors.success)
                                    .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color:
                                  (difference < 0
                                          ? AppColors.danger
                                          : AppColors.success)
                                      .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            difference == 0
                                ? '0 ៛ (Exact)'
                                : (difference > 0
                                      ? '+${MoneyUtils.formatRiel(difference)} (Surplus)'
                                      : '${MoneyUtils.formatRiel(difference)} (Shortage)'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: difference < 0
                                  ? AppColors.danger
                                  : AppColors.success,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Metrics summary row
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBg : AppColors.lightBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Wrap(
                      spacing: 24,
                      runSpacing: 8,
                      children: [
                        _buildShiftStat(
                          'Opening Cash',
                          MoneyUtils.formatRiel(shift.openingCash),
                        ),
                        _buildShiftStat(
                          'Sales (${shift.salesCount} txns)',
                          MoneyUtils.formatRiel(shift.totalSales),
                        ),
                        _buildShiftStat(
                          'Expected Cash',
                          MoneyUtils.formatRiel(expectedCash),
                        ),
                        if (!isOpen)
                          _buildShiftStat(
                            'Actual Cash',
                            shift.actualCash != null
                                ? MoneyUtils.formatRiel(shift.actualCash!)
                                : '-',
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildShiftStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
