import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../mart_logo.dart';

class TopMenu extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onToggleSidebar;
  final bool isSidebarExpanded;
  final Widget? centerWidget;

  const TopMenu({
    super.key,
    required this.onToggleSidebar,
    required this.isSidebarExpanded,
    this.centerWidget,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final isDark = themeProv.isDarkMode;

    final bgColor = isDark ? AppColors.darkBg : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Left: Sidebar Toggle
          IconButton(
            icon: Icon(Icons.menu, color: textColor),
            tooltip: 'Toggle Sidebar',
            onPressed: onToggleSidebar,
          ),
          const SizedBox(width: 8),

          // Mart POS Logo & Name
          const MartLogo(size: 32),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mart POS',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
              ),
              Text(
                auth.currentUser.shopName,
                style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText),
              ),
            ],
          ),

          const SizedBox(width: 24),

          // Center Slot (Search Bar or Barcode scanner)
          Expanded(
            child: centerWidget ?? const SizedBox.shrink(),
          ),

          const SizedBox(width: 16),

          // Right: Online Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.emerald,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_done, size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text('Online', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Theme Switcher (Sun / Moon)
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: textColor),
            tooltip: isDark ? 'ប្តូរទៅ Light Mode' : 'ប្តូរទៅ Dark Mode',
            onPressed: () => themeProv.toggleTheme(),
          ),

          // Notifications Bell
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none, color: textColor),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ប្រព័ន្ធដំណើរការធម្មតា (System Normal - No Alerts)')),
                  );
                },
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),

          const SizedBox(width: 8),

          // User Profile Dropdown
          PopupMenuButton<String>(
            tooltip: 'គណនីរបស់អ្នក',
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            color: isDark ? AppColors.darkCard : Colors.white,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: auth.isAdmin ? AppColors.cyan : AppColors.amber,
                  child: Text(
                    auth.currentUser.name.isNotEmpty ? auth.currentUser.name[0] : 'U',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.currentUser.name,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: auth.isAdmin
                            ? Colors.cyan.withValues(alpha: 0.2)
                            : Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        auth.currentUser.role,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: auth.isAdmin ? Colors.cyan.shade700 : Colors.amber.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                Icon(Icons.arrow_drop_down, color: textColor),
              ],
            ),
            onSelected: (val) {
              if (val == 'switch_panha') {
                auth.switchDemoUser(name: 'នី បញ្ញា', role: 'ADMIN', email: 'panha@bbu.edu.kh');
              } else if (val == 'switch_pkay') {
                auth.switchDemoUser(name: 'គក់ ស្រីផ្កាយ', role: 'CASHIER', email: 'pkay@bbu.edu.kh');
              } else if (val == 'switch_daly') {
                auth.switchDemoUser(name: 'គុយ ដាលី', role: 'CASHIER', email: 'daly@bbu.edu.kh');
              } else if (val == 'logout') {
                auth.logout();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                enabled: false,
                child: Text('ប្តូរអ្នកប្រើប្រាស់ (Demo Switch):',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54)),
              ),
              const PopupMenuItem(
                value: 'switch_panha',
                child: Text('ចូលជា: នី បញ្ញា (Admin)'),
              ),
              const PopupMenuItem(
                value: 'switch_pkay',
                child: Text('ចូលជា: គក់ ស្រីផ្កាយ (Cashier)'),
              ),
              const PopupMenuItem(
                value: 'switch_daly',
                child: Text('ចូលជា: គុយ ដាលី (Cashier)'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('ចាកចេញ (Sign Out)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
