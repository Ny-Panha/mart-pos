import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../mart_logo.dart';

class NavItem {
  final int index;
  final String label;
  final IconData icon;

  const NavItem(this.index, this.label, this.icon);
}

class AppSidebar extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const AppSidebar({
    super.key,
    required this.isExpanded,
    required this.onToggle,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final isDark = themeProv.isDarkMode;
    final bool isAdmin = auth.isAdmin;

    final bgColor = isDark ? AppColors.darkBg : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isExpanded ? 240 : 72,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
          // Header with MartLogo
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                const MartLogo(size: 36),
                if (isExpanded) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mart POS',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: isAdmin
                                ? Colors.cyan.withValues(alpha: 0.15)
                                : Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isAdmin ? 'ADMIN' : 'CASHIER',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isAdmin ? AppColors.cyan : AppColors.amber,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Collapse / Expand toggle button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isDark ? AppColors.darkCard : Colors.grey.shade100,
                ),
                child: Row(
                  mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                  children: [
                    Icon(
                      isExpanded ? Icons.menu_open : Icons.menu,
                      size: 18,
                      color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                    ),
                    if (isExpanded) ...[
                      const SizedBox(width: 10),
                      Text(
                        'បង្រួម Menu',
                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Portal Switcher (Cashier vs Admin)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: InkWell(
              onTap: () {
                if (isAdmin) {
                  auth.switchDemoUser(name: 'គក់ ស្រីផ្កាយ', role: 'CASHIER', email: 'pkay@bbu.edu.kh');
                } else {
                  auth.switchDemoUser(name: 'នី បញ្ញា', role: 'ADMIN', email: 'panha@bbu.edu.kh');
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: (isAdmin ? AppColors.cyan : AppColors.amber).withValues(alpha: 0.12),
                ),
                child: Row(
                  mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.swap_horiz,
                      size: 18,
                      color: isAdmin ? AppColors.cyan : AppColors.amber,
                    ),
                    if (isExpanded) ...[
                      const SizedBox(width: 8),
                      Text(
                        isAdmin ? 'ប្តូរទៅ Cashier' : 'ប្តូរទៅ Admin',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isAdmin ? AppColors.cyan : AppColors.amber,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const Divider(height: 12),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              children: [
                if (!isAdmin) ...[
                  // Cashier Menu (Matching CashierSidebar.jsx)
                  _buildSectionHeader('SALES'),
                  _buildNavItem(0, 'POS គិតលុយ', Icons.point_of_sale, isDark),
                  _buildNavItem(1, 'ប្រវត្តិលក់ (History)', Icons.history, isDark),

                  _buildSectionHeader('INVENTORY'),
                  _buildNavItem(2, 'ពិនិត្យស្តុក (Stock)', Icons.inventory_2_outlined, isDark),

                  _buildSectionHeader('SHIFT'),
                  _buildNavItem(3, 'បិទវេន (My Shift)', Icons.key_outlined, isDark),
                ] else ...[
                  // Admin Menu (Matching AdminSidebar.jsx)
                  _buildSectionHeader('OVERVIEW'),
                  _buildNavItem(0, 'ផ្ទាំងគ្រប់គ្រង (Dashboard)', Icons.dashboard_outlined, isDark),

                  _buildSectionHeader('CATALOG'),
                  _buildNavItem(1, 'ទំនិញ (Products)', Icons.inventory_2_outlined, isDark),
                  _buildNavItem(2, 'ប្រភេទ (Categories)', Icons.category_outlined, isDark),

                  _buildSectionHeader('SALES & PROCUREMENT'),
                  _buildNavItem(3, 'បញ្ជាទិញទំនិញ (Purchases)', Icons.shopping_cart_checkout_outlined, isDark),
                  _buildNavItem(4, 'ប្រវត្តិលក់ (Sales History)', Icons.receipt_long_outlined, isDark),

                  _buildSectionHeader('INVENTORY & VENDORS'),
                  _buildNavItem(5, 'ឃ្លាំង & ស្តុក (Inventory)', Icons.layers_outlined, isDark),
                  _buildNavItem(6, 'អ្នកផ្គត់ផ្គង់ (Suppliers)', Icons.local_shipping_outlined, isDark),

                  _buildSectionHeader('PEOPLE & CRM'),
                  _buildNavItem(7, 'អតិថិជន (Customers)', Icons.people_alt_outlined, isDark),
                  _buildNavItem(8, 'បុគ្គលិក (Staff)', Icons.badge_outlined, isDark),

                  _buildSectionHeader('ANALYTICS'),
                  _buildNavItem(9, 'របាយការណ៍ (Reports)', Icons.analytics_outlined, isDark),

                  _buildSectionHeader('SYSTEM'),
                  _buildNavItem(10, 'ការកំណត់ (Settings)', Icons.settings_outlined, isDark),
                ],

                const Divider(height: 16),
                _buildSectionHeader('BBU ACADEMIC'),
                _buildNavItem(isAdmin ? 11 : 4, 'ក្រុមការងារ (Team Info)', Icons.groups_outlined, isDark),

                const Divider(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: InkWell(
                    onTap: () => auth.logout(),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout, size: 20, color: Colors.red),
                          if (isExpanded) ...[
                            const SizedBox(width: 12),
                            const Text(
                              'ចាកចេញ (Sign Out)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    if (!isExpanded) return const SizedBox(height: 6);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon, bool isDark) {
    final isSelected = selectedIndex == index;
    final activeBg = isDark
        ? AppColors.primary.withValues(alpha: 0.25)
        : Colors.amber.shade50;
    final activeColor = isDark ? Colors.purple.shade200 : Colors.amber.shade800;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: InkWell(
        onTap: () => onSelect(index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? activeColor : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
              ),
              if (isExpanded) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? activeColor : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
