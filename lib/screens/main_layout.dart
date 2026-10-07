import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shell/app_sidebar.dart';
import '../widgets/shell/top_menu.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin/category_screen.dart';
import 'admin/customer_list_screen.dart';
import 'admin/inventory_screen.dart';
import 'admin/product_management_screen.dart';
import 'admin/purchase_list_screen.dart';
import 'admin/shop_settings_screen.dart';
import 'admin/staff_screen.dart';
import 'admin/supplier_list_screen.dart';
import 'cashier/daily_close_screen.dart';
import 'cashier/sales_history_screen.dart';
import 'cashier/stock_check_screen.dart';
import 'pos/pos_screen.dart';
import 'reports/reports_screen.dart';
import 'team/team_info_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _isSidebarExpanded = true;
  int _cashierIndex = 0;
  int _adminIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final isDark = themeProv.isDarkMode;
    final bool isAdmin = auth.isAdmin;

    // Cashier Pages (Matching CashierSidebar.jsx in Kambuja-POS)
    final List<Widget> cashierPages = [
      const PosScreen(),            // 0: POS គិតលុយ
      const SalesHistoryScreen(),   // 1: ប្រវត្តិលក់ (History)
      const StockCheckScreen(),     // 2: ពិនិត្យស្តុក (Stock Check)
      const DailyCloseScreen(),     // 3: បិទវេន (My Shift / Daily Close)
      const TeamInfoScreen(),       // 4: BBU Academic Team
    ];

    // Admin Pages (Matching AdminSidebar.jsx in Kambuja-POS)
    final List<Widget> adminPages = [
      AdminDashboardScreen(onNavigateToPos: () => setState(() => _cashierIndex = 0)), // 0: Overview Dashboard
      const ProductManagementScreen(), // 1: Catalog Products
      const CategoryScreen(),          // 2: Catalog Categories
      const PurchaseListScreen(),      // 3: Sales Purchases
      const SalesHistoryScreen(),      // 4: Sales History
      const InventoryScreen(),         // 5: Inventory & Adjust
      const SupplierListScreen(),      // 6: Suppliers
      const CustomerListScreen(),      // 7: Customers (CRM & Loyalty)
      const StaffScreen(),             // 8: Staff (Cashier & Admin users)
      const ReportsScreen(),           // 9: Insights Reports (Sales, Stock, Profit, Best Sellers)
      const ShopSettingsScreen(),      // 10: Shop Settings & Logs
      const TeamInfoScreen(),          // 11: BBU Academic Team
    ];

    final activePages = isAdmin ? adminPages : cashierPages;
    final int selectedIndex = isAdmin ? _adminIndex : _cashierIndex;
    final int safeIndex = selectedIndex < activePages.length ? selectedIndex : 0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Column(
        children: [
          // 64px Top Menu (Mart POS)
          TopMenu(
            isSidebarExpanded: _isSidebarExpanded,
            onToggleSidebar: () {
              setState(() => _isSidebarExpanded = !_isSidebarExpanded);
            },
          ),

          // Main Body: Left Sidebar + Page Viewport
          Expanded(
            child: Row(
              children: [
                // Collapsible Left Sidebar (240px / 72px)
                AppSidebar(
                  isExpanded: _isSidebarExpanded,
                  onToggle: () {
                    setState(() => _isSidebarExpanded = !_isSidebarExpanded);
                  },
                  selectedIndex: safeIndex,
                  onSelect: (idx) {
                    setState(() {
                      if (isAdmin) {
                        _adminIndex = idx;
                      } else {
                        _cashierIndex = idx;
                      }
                    });
                  },
                ),

                // Active Page Content Viewport
                Expanded(
                  child: activePages[safeIndex],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
