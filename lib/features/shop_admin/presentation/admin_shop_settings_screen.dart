import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/utils/csv_exporter.dart';
import '../../../core/utils/responsive.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customers/providers/customer_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../reports/providers/report_provider.dart';
import '../providers/admin_shop_provider.dart';
import '../services/admin_shop_service.dart';

class _SettingsTheme {
  final bool isDark;
  final Color bg;
  final Color cardBg;
  final Color subCardBg;
  final Color cardBorder;
  final Color subBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;

  const _SettingsTheme({
    required this.isDark,
    required this.bg,
    required this.cardBg,
    required this.subCardBg,
    required this.cardBorder,
    required this.subBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
  });

  factory _SettingsTheme.of(BuildContext context, ThemeMode mode) {
    final platformDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDark = mode == ThemeMode.dark || (mode == ThemeMode.system && platformDark);

    return _SettingsTheme(
      isDark: isDark,
      bg: isDark ? const Color(0xFF0A101D) : const Color(0xFFF8FAFC),
      cardBg: isDark ? const Color(0xFF10192A) : Colors.white,
      subCardBg: isDark ? const Color(0xFF142036) : const Color(0xFFF1F5F9),
      cardBorder: isDark ? const Color(0xFF1B2844) : const Color(0xFFE2E8F0),
      subBorder: isDark ? const Color(0xFF203254) : const Color(0xFFCBD5E1),
      textPrimary: isDark ? Colors.white : const Color(0xFF0F172A),
      textSecondary: isDark ? const Color(0xFF889BB7) : const Color(0xFF64748B),
      divider: isDark ? const Color(0xFF152238) : const Color(0xFFE2E8F0),
    );
  }
}

class _DayScheduleControllers {
  bool isOpen;
  final TextEditingController lunchStart;
  final TextEditingController lunchEnd;
  final TextEditingController dinnerStart;
  final TextEditingController dinnerEnd;

  _DayScheduleControllers({
    required this.isOpen,
    required String lunchStart,
    required String lunchEnd,
    required String dinnerStart,
    required String dinnerEnd,
  })  : lunchStart = TextEditingController(text: lunchStart),
        lunchEnd = TextEditingController(text: lunchEnd),
        dinnerStart = TextEditingController(text: dinnerStart),
        dinnerEnd = TextEditingController(text: dinnerEnd);

  Map<String, dynamic> toMap() => {
        'isOpen': isOpen,
        'lunchStart': lunchStart.text.trim(),
        'lunchEnd': lunchEnd.text.trim(),
        'dinnerStart': dinnerStart.text.trim(),
        'dinnerEnd': dinnerEnd.text.trim(),
      };

  void dispose() {
    lunchStart.dispose();
    lunchEnd.dispose();
    dinnerStart.dispose();
    dinnerEnd.dispose();
  }
}

class AdminShopSettingsScreen extends ConsumerStatefulWidget {
  const AdminShopSettingsScreen({super.key});

  @override
  ConsumerState<AdminShopSettingsScreen> createState() =>
      _AdminShopSettingsScreenState();
}

class _AdminShopSettingsScreenState
    extends ConsumerState<AdminShopSettingsScreen> {
  // Active navigation tab (6 exact tabs matching Tavola layout)
  String _activeTab = 'store';

  // Store Profile Controllers
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _bakongId = TextEditingController();

  // Receipt & Printer Controllers
  final _receiptFooter = TextEditingController();

  // Store Hours Controllers (Legacy fallbacks)
  final _openTime = TextEditingController(text: '12:00 PM');
  final _closeTime = TextEditingController(text: '10:30 PM');
  bool _is24Hours = false;

  // POS & Inventory Rules States
  String _currency = 'KHR';
  bool _taxEnabled = true;
  double _salesTax = 10.0; // %
  int _exchangeRate = 4100; // KHR per 1 USD
  int _lowStockThreshold = 5; // items
  bool _allowNegativeStock = false;

  // Receipt States
  String _paperSize = '80mm';
  bool _showBarcodeOnReceipt = true;

  // Notifications States
  bool _notifLowStock = true;
  bool _notifNightlyDigest = true;
  bool _notifShiftAlerts = true;

  // Appearance Theme
  String _selectedTheme = 'Dark';

  // Store Weekly Schedule (Tavola interactive format - directly editable)
  late final Map<String, _DayScheduleControllers> _schedules = {
    'Mon': _DayScheduleControllers(
      isOpen: true,
      lunchStart: '12:00 PM',
      lunchEnd: '02:45 PM',
      dinnerStart: '06:00 PM',
      dinnerEnd: '10:30 PM',
    ),
    'Tue': _DayScheduleControllers(
      isOpen: true,
      lunchStart: '12:00 PM',
      lunchEnd: '02:45 PM',
      dinnerStart: '06:00 PM',
      dinnerEnd: '10:30 PM',
    ),
    'Wed': _DayScheduleControllers(
      isOpen: true,
      lunchStart: '12:00 PM',
      lunchEnd: '02:45 PM',
      dinnerStart: '06:00 PM',
      dinnerEnd: '10:30 PM',
    ),
    'Thu': _DayScheduleControllers(
      isOpen: true,
      lunchStart: '12:00 PM',
      lunchEnd: '02:45 PM',
      dinnerStart: '06:00 PM',
      dinnerEnd: '10:30 PM',
    ),
    'Fri': _DayScheduleControllers(
      isOpen: true,
      lunchStart: '12:00 PM',
      lunchEnd: '02:45 PM',
      dinnerStart: '06:00 PM',
      dinnerEnd: '11:30 PM',
    ),
    'Sat': _DayScheduleControllers(
      isOpen: true,
      lunchStart: '12:00 PM',
      lunchEnd: '03:30 PM',
      dinnerStart: '06:00 PM',
      dinnerEnd: '11:30 PM',
    ),
    'Sun': _DayScheduleControllers(
      isOpen: true,
      lunchStart: '12:00 PM',
      lunchEnd: '03:30 PM',
      dinnerStart: '06:00 PM',
      dinnerEnd: '10:30 PM',
    ),
  };

  bool _initialised = false;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;
  bool _isSyncing = false;

  final ScrollController _scrollController = ScrollController();
  bool _isProgrammaticScroll = false;
  Timer? _scrollTimer;

  // Section Keys for smooth scrolling (3 on left, 3 on right - exactly balanced)
  final _storeKey = GlobalKey();
  final _rulesKey = GlobalKey();
  final _appearanceKey = GlobalKey();
  final _hoursKey = GlobalKey();
  final _notificationsKey = GlobalKey();
  final _dataKey = GlobalKey();

  // Tab Keys for auto-scrolling the top tab bar to keep the active tab visible
  final Map<String, GlobalKey> _tabKeys = {
    'store': GlobalKey(),
    'rules': GlobalKey(),
    'hours': GlobalKey(),
    'notifications': GlobalKey(),
    'appearance': GlobalKey(),
    'data': GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _updateActiveTab(String newTab) {
    if (newTab == _activeTab) return;
    setState(() => _activeTab = newTab);

    // Auto-scroll the top horizontal tab bar to keep active pill visible & centered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tabKey = _tabKeys[newTab];
      if (tabKey?.currentContext != null) {
        Scrollable.ensureVisible(
          tabKey!.currentContext!,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: 0.5,
        );
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isProgrammaticScroll) return;

    final isDesktop = Responsive.isDesktop(context);
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentOffset = _scrollController.offset;

    if (currentOffset <= 20) {
      if (_activeTab != 'store') {
        _updateActiveTab('store');
      }
      return;
    }

    if (currentOffset >= maxScroll - 40) {
      final bottomTab = (isDesktop && _activeTab == 'appearance') ? 'appearance' : 'data';
      if (_activeTab != bottomTab) {
        _updateActiveTab(bottomTab);
      }
      return;
    }

    // Trigger line just below the top pinned header
    const double triggerY = 200.0;
    String? bestTab;

    if (!isDesktop) {
      // On mobile (single column: store, rules, hours, notifications, appearance, data)
      // Check from bottom card to top card
      final mobileSections = [
        {'id': 'data', 'key': _dataKey},
        {'id': 'appearance', 'key': _appearanceKey},
        {'id': 'notifications', 'key': _notificationsKey},
        {'id': 'hours', 'key': _hoursKey},
        {'id': 'rules', 'key': _rulesKey},
        {'id': 'store', 'key': _storeKey},
      ];

      for (final s in mobileSections) {
        final key = s['key'] as GlobalKey;
        final ctx = key.currentContext;
        if (ctx == null) continue;
        final box = ctx.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) continue;

        final top = box.localToGlobal(Offset.zero).dy;
        if (top <= triggerY) {
          bestTab = s['id'] as String;
          break;
        }
      }
    } else {
      // On desktop (2 columns): check row pairs from bottom to top
      final rowPairs = [
        {'pair': ['appearance', 'data'], 'keys': [_appearanceKey, _dataKey]},
        {'pair': ['rules', 'notifications'], 'keys': [_rulesKey, _notificationsKey]},
        {'pair': ['store', 'hours'], 'keys': [_storeKey, _hoursKey]},
      ];

      for (final p in rowPairs) {
        final keys = p['keys'] as List<GlobalKey>;
        final ids = p['pair'] as List<String>;
        final ctx = keys[0].currentContext;
        if (ctx == null) continue;
        final box = ctx.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) continue;

        final top = box.localToGlobal(Offset.zero).dy;
        if (top <= triggerY) {
          if (ids.contains(_activeTab)) {
            bestTab = _activeTab;
          } else {
            bestTab = ids[0];
          }
          break;
        }
      }
    }

    bestTab ??= 'store';

    if (bestTab != _activeTab) {
      _updateActiveTab(bestTab);
    }
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _email.dispose();
    _bakongId.dispose();
    _receiptFooter.dispose();
    _openTime.dispose();
    _closeTime.dispose();
    for (final s in _schedules.values) {
      s.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  late _SettingsTheme _theme;

  void _markDirty() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  void _applyTheme(String val) {
    setState(() => _selectedTheme = val);
    _markDirty();
    final mode = val == 'Light'
        ? ThemeMode.light
        : val == 'System'
            ? ThemeMode.system
            : ThemeMode.dark;
    ref.read(themeModeProvider.notifier).setThemeMode(mode);
  }

  void _scrollTo(GlobalKey key, String tabId) {
    _isProgrammaticScroll = true;
    _scrollTimer?.cancel();
    _updateActiveTab(tabId);

    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    }

    _scrollTimer = Timer(const Duration(milliseconds: 550), () {
      _isProgrammaticScroll = false;
    });
  }

  Future<void> _save(ShopSettingsModel current) async {
    final user = ref.read(authProvider).value;
    if (user == null) return;
    setState(() => _isSaving = true);
    try {
      final weeklyData = <String, dynamic>{};
      for (final entry in _schedules.entries) {
        weeklyData[entry.key] = entry.value.toMap();
      }

      final todayKey = DateFormat('EEE').format(DateTime.now());
      final todaySched = _schedules[todayKey];
      final todayOpen = todaySched?.lunchStart.text.trim() ?? '12:00 PM';
      final todayClose = todaySched?.dinnerEnd.text.trim() ?? '10:30 PM';

      await ref.read(adminShopServiceProvider).saveSettings(
            user,
            ShopSettingsModel(
              shopId: current.shopId,
              shopName: _name.text.trim(),
              phone: _phone.text.trim(),
              address: _address.text.trim(),
              email: _email.text.trim(),
              currency: _currency,
              taxEnabled: _taxEnabled,
              taxRate: _salesTax,
              exchangeRate: _exchangeRate,
              bakongId: _bakongId.text.trim(),
              receiptFooter: _receiptFooter.text.trim(),
              paperSize: _paperSize,
              showBarcodeOnReceipt: _showBarcodeOnReceipt,
              lowStockThreshold: _lowStockThreshold,
              allowNegativeStock: _allowNegativeStock,
              notifLowStock: _notifLowStock,
              notifNightlyDigest: _notifNightlyDigest,
              notifShiftAlerts: _notifShiftAlerts,
              openTime: todayOpen,
              closeTime: todayClose,
              is24Hours: _is24Hours,
              themeMode: _selectedTheme,
              weeklySchedule: weeklyData,
            ),
          );

      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Settings saved successfully'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to save settings: $error'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  // --- CSV Export Functions ---
  void _exportSalesCsv() {
    final sales = ref.read(allRecentSalesProvider).value ?? [];
    final buffer = StringBuffer();
    buffer.writeln('Invoice ID,Date,Items Count,Total (Riel),Payment Method,Cashier');
    for (final s in sales) {
      final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(s.createdAt);
      buffer.writeln(
        '"${s.invoiceNumber.isNotEmpty ? s.invoiceNumber : s.id}","$dateStr",${s.items.length},${s.total},"${s.paymentMethod}","${s.cashierName ?? s.cashierId}"',
      );
    }

    downloadCsvFile('sales_export_${DateTime.now().millisecondsSinceEpoch}.csv', buffer.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${sales.length} sales orders exported to CSV'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _exportCustomersCsv() {
    final customers = ref.read(customersStreamProvider).value ?? [];
    final buffer = StringBuffer();
    buffer.writeln('Customer ID,Name,Phone,Total Spent (Riel)');
    for (final c in customers) {
      buffer.writeln(
        '"${c.id}","${c.name.replaceAll('"', '""')}","${c.phone ?? ''}",${c.totalSpent}',
      );
    }

    downloadCsvFile('guest_list_${DateTime.now().millisecondsSinceEpoch}.csv', buffer.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${customers.length} customers exported to CSV'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _exportInventoryCsv() {
    final products = ref.read(productsStreamProvider).value ?? [];
    final buffer = StringBuffer();
    buffer.writeln('Product ID,Barcode,Name,Category ID,Cost Price (Riel),Sale Price (Riel),Stock Qty,Unit');
    for (final p in products) {
      buffer.writeln(
        '"${p.id}","${p.barcode}","${p.name.replaceAll('"', '""')}","${p.categoryId}",${p.costPrice},${p.salePrice},${p.stockQty},"${p.unit}"',
      );
    }

    downloadCsvFile('inventory_export_${DateTime.now().millisecondsSinceEpoch}.csv', buffer.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${products.length} products exported to CSV'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _syncCloudDatabase() async {
    setState(() => _isSyncing = true);
    ref.invalidate(adminShopSettingsProvider);
    ref.invalidate(productsStreamProvider);
    ref.invalidate(customersStreamProvider);
    ref.invalidate(allRecentSalesProvider);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.cloud_done_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Cloud database synced successfully'),
            ],
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _resetDemoData() {
    ref.invalidate(adminShopSettingsProvider);
    ref.invalidate(productsStreamProvider);
    ref.invalidate(customersStreamProvider);
    ref.invalidate(allRecentSalesProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings restored to defaults'),
        backgroundColor: Color(0xFFF46A55),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final settingsAsync = ref.watch(adminShopSettingsProvider);
    final themeMode = ref.watch(themeModeProvider);
    _theme = _SettingsTheme.of(context, themeMode);

    return Scaffold(
      backgroundColor: _theme.bg,
      body: settingsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFF9D8C0)),
        ),
        error: (e, _) => Center(
          child: Text(
            'Unable to load settings: $e',
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
        data: (current) {
          if (!_initialised) {
            _name.text = current.shopName.isEmpty ? 'Nha Mini-Mart' : current.shopName;
            _address.text = current.address.isEmpty ? 'Street 102, Battambang City' : current.address;
            _phone.text = current.phone.isEmpty ? '012 345 678' : current.phone;
            _email.text = current.email.isEmpty ? 'contact@nhamart.com' : current.email;
            _bakongId.text = current.bakongId.isEmpty ? 'nha_mart@aclb' : current.bakongId;
            _receiptFooter.text = current.receiptFooter;
            _currency = current.currency;
            _taxEnabled = current.taxEnabled;
            _salesTax = current.taxRate;
            _exchangeRate = current.exchangeRate;
            _lowStockThreshold = current.lowStockThreshold;
            _allowNegativeStock = current.allowNegativeStock;
            _paperSize = current.paperSize;
            _showBarcodeOnReceipt = current.showBarcodeOnReceipt;
            _notifLowStock = current.notifLowStock;
            _notifNightlyDigest = current.notifNightlyDigest;
            _notifShiftAlerts = current.notifShiftAlerts;
            _openTime.text = current.openTime;
            _closeTime.text = current.closeTime;
            _is24Hours = current.is24Hours;
            if (current.weeklySchedule != null && current.weeklySchedule!.isNotEmpty) {
              current.weeklySchedule!.forEach((dayKey, val) {
                if (_schedules.containsKey(dayKey) && val is Map) {
                  final s = _schedules[dayKey]!;
                  if (val['isOpen'] != null) s.isOpen = val['isOpen'] == true;
                  if (val['lunchStart'] != null) s.lunchStart.text = val['lunchStart'].toString();
                  if (val['lunchEnd'] != null) s.lunchEnd.text = val['lunchEnd'].toString();
                  if (val['dinnerStart'] != null) s.dinnerStart.text = val['dinnerStart'].toString();
                  if (val['dinnerEnd'] != null) s.dinnerEnd.text = val['dinnerEnd'].toString();
                }
              });
            }
            _selectedTheme = current.themeMode.isNotEmpty
                ? current.themeMode
                : (_theme.isDark ? 'Dark' : 'Light');
            _initialised = true;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PINNED TOP BAR (Never scrolls away - Exactly 6 Tavola tabs)
              Container(
                color: _theme.bg,
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 40.0 : 16.0,
                  20.0,
                  isDesktop ? 40.0 : 16.0,
                  14.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Title Row & Save Pill Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: _theme.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            if (_hasUnsavedChanges)
                              Container(
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9D8C0).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFF9D8C0).withValues(alpha: 0.4)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.fiber_manual_record_rounded, size: 8, color: Color(0xFFF9D8C0)),
                                    SizedBox(width: 6),
                                    Text(
                                      'Unsaved changes',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFF9D8C0),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            FilledButton(
                              onPressed: _isSaving ? null : () => _save(current),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFF9D8C0),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                    )
                                  : const Text(
                                      'Save',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Tavola Signature Navigation Tabs (PINNED AT TOP - EXACT 6 TABS)
                    _buildTavolaPillTabs(),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: _theme.divider),

              // Scrollable Cards Content (Scrolls underneath the pinned header)
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 40.0 : 16.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    children: [
                      // 2-Column Grid Layout (3 on Left, 3 on Right - PERFECT BALANCE)
                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column: Store Profile, POS Rules, Appearance
                            Expanded(
                              child: Column(
                                children: [
                                  _buildStoreProfileCard(key: _storeKey),
                                  const SizedBox(height: 24),
                                  _buildPosRulesCard(key: _rulesKey),
                                  const SizedBox(height: 24),
                                  _buildAppearanceCard(key: _appearanceKey),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Right Column: Store Hours, Notifications, Data & Export
                            Expanded(
                              child: Column(
                                children: [
                                  _buildStoreHoursCard(key: _hoursKey),
                                  const SizedBox(height: 24),
                                  _buildNotificationsCard(key: _notificationsKey),
                                  const SizedBox(height: 24),
                                  _buildDataCard(key: _dataKey),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildStoreProfileCard(key: _storeKey),
                            const SizedBox(height: 24),
                            _buildPosRulesCard(key: _rulesKey),
                            const SizedBox(height: 24),
                            _buildStoreHoursCard(key: _hoursKey),
                            const SizedBox(height: 24),
                            _buildNotificationsCard(key: _notificationsKey),
                            const SizedBox(height: 24),
                            _buildAppearanceCard(key: _appearanceKey),
                            const SizedBox(height: 24),
                            _buildDataCard(key: _dataKey),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // TAVOLA NAVIGATION TABS (PINNED AT TOP - EXACT 6 TABS)
  // ==========================================
  Widget _buildTavolaPillTabs() {
    final tabs = [
      {'id': 'store', 'label': 'Store Profile', 'icon': Icons.storefront_outlined, 'key': _storeKey},
      {'id': 'rules', 'label': 'POS Rules', 'icon': Icons.tune_rounded, 'key': _rulesKey},
      {'id': 'hours', 'label': 'Store Hours', 'icon': Icons.access_time_rounded, 'key': _hoursKey},
      {'id': 'notifications', 'label': 'Notifications', 'icon': Icons.notifications_none_rounded, 'key': _notificationsKey},
      {'id': 'appearance', 'label': 'Appearance', 'icon': Icons.wb_sunny_outlined, 'key': _appearanceKey},
      {'id': 'data', 'label': 'Data & Export', 'icon': Icons.storage_rounded, 'key': _dataKey},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((t) {
          final active = _activeTab == t['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: InkWell(
              key: _tabKeys[t['id']],
              onTap: () => _scrollTo(t['key'] as GlobalKey, t['id'] as String),
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFF9D8C0) : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Icon(
                      t['icon'] as IconData,
                      size: 16,
                      color: active ? Colors.black : _theme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t['label'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: active ? FontWeight.bold : FontWeight.w500,
                        color: active
                            ? Colors.black
                            : (_theme.isDark ? const Color(0xFFD4E0F0) : const Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================
  // CARD 1: STORE PROFILE (LEFT COLUMN, TOP)
  // ==========================================
  Widget _buildStoreProfileCard({required GlobalKey key}) {
    final storeInitial = _name.text.trim().isNotEmpty ? _name.text.trim()[0].toUpperCase() : 'M';
    return _buildTavolaCardContainer(
      key: key,
      icon: Icons.storefront_rounded,
      title: 'Store Profile',
      subtitle: 'Shop identity, contact & Bakong KHQR for payments',
      children: [
        // Brand Profile Header Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _theme.subCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _theme.subBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9D8C0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    storeInitial,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name.text.trim().isEmpty ? 'Nha Mini-Mart' : _name.text.trim(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _theme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Active Mini-Mart Store · Cambodia',
                      style: TextStyle(fontSize: 12, color: _theme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildHorizontalRow(
          icon: Icons.store_mall_directory_outlined,
          label: 'Shop name',
          hint: 'Appears on receipt & checkout',
          stackOnMobile: true,
          control: _buildInputCapsule(
            controller: _name,
            hint: 'e.g. Nha Mini-Mart',
          ),
        ),
        _buildDivider(),
        _buildHorizontalRow(
          icon: Icons.phone_outlined,
          label: 'Phone / Telegram',
          hint: 'Customer service & invoices',
          stackOnMobile: true,
          control: _buildInputCapsule(
            controller: _phone,
            hint: 'e.g. 012 345 678',
            keyboardType: TextInputType.phone,
          ),
        ),
        _buildDivider(),
        _buildHorizontalRow(
          icon: Icons.email_outlined,
          label: 'Email',
          hint: 'Inquiries & administrative alerts',
          stackOnMobile: true,
          control: _buildInputCapsule(
            controller: _email,
            hint: 'e.g. contact@nhamart.com',
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        _buildDivider(),
        _buildHorizontalRow(
          icon: Icons.location_on_outlined,
          label: 'Store address',
          hint: 'Street, Sangkat, Battambang',
          stackOnMobile: true,
          control: _buildInputCapsule(
            controller: _address,
            hint: 'e.g. Street 102, Battambang',
          ),
        ),
        _buildDivider(),
        _buildHorizontalRow(
          icon: Icons.monetization_on_outlined,
          label: 'Base currency',
          hint: 'Primary currency for transactions',
          control: _buildSegmentedPill(
            options: ['KHR', 'USD'],
            selected: _currency,
            onSelect: (val) {
              setState(() => _currency = val);
              _markDirty();
            },
          ),
        ),
        _buildDivider(),
        _buildHorizontalRow(
          icon: Icons.qr_code_scanner_rounded,
          label: 'Bakong KHQR ID',
          hint: 'Account for customer QR scan & pay',
          stackOnMobile: true,
          control: _buildInputCapsule(
            controller: _bakongId,
            hint: 'e.g. nha_mart@aclb',
          ),
        ),
      ],
    );
  }

  // ==========================================
  // CARD 2: POS RULES & RECEIPT (LEFT COLUMN, MIDDLE)
  // Perfectly balanced height opposite Store Hours!
  // ==========================================
  Widget _buildPosRulesCard({required GlobalKey key}) {
    return _buildTavolaCardContainer(
      key: key,
      icon: Icons.tune_rounded,
      title: 'POS Rules & Receipt',
      subtitle: 'Exchange rates, VAT, inventory thresholds & receipt',
      children: [
        _buildHorizontalRow(
          icon: Icons.currency_exchange_rounded,
          label: 'Exchange rate',
          hint: 'KHR per 1 USD for dual-currency POS checkout',
          control: _buildStepperControl(
            valueText: '${NumberFormat('#,###').format(_exchangeRate)} ៛',
            onDecrement: _exchangeRate > 4000
                ? () {
                    setState(() => _exchangeRate -= 50);
                    _markDirty();
                  }
                : null,
            onIncrement: () {
              setState(() => _exchangeRate += 50);
              _markDirty();
            },
          ),
        ),
        _buildDivider(),
        _buildHorizontalRow(
          icon: Icons.percent_rounded,
          label: 'Sales tax (VAT)',
          hint: _taxEnabled ? 'Automatically calculate $_salesTax% on sales' : 'Tax is currently disabled',
          stackOnMobile: true,
          control: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_taxEnabled) ...[
                _buildStepperControl(
                  valueText: '${_salesTax.toStringAsFixed(1)} %',
                  onDecrement: _salesTax > 0
                      ? () {
                          setState(() => _salesTax = (_salesTax - 1.0).clamp(0.0, 30.0));
                          _markDirty();
                        }
                      : null,
                  onIncrement: () {
                    setState(() => _salesTax = (_salesTax + 1.0).clamp(0.0, 30.0));
                    _markDirty();
                  },
                ),
                const SizedBox(width: 8),
              ],
              _buildTavolaSwitch(
                value: _taxEnabled,
                onChanged: (val) {
                  setState(() => _taxEnabled = val);
                  _markDirty();
                },
              ),
            ],
          ),
        ),
        _buildDivider(),
        _buildHorizontalRow(
          icon: Icons.inventory_2_outlined,
          label: 'Low stock threshold',
          hint: 'Alert badge when item inventory reaches count',
          control: _buildStepperControl(
            valueText: '$_lowStockThreshold items',
            onDecrement: _lowStockThreshold > 1
                ? () {
                    setState(() => _lowStockThreshold -= 1);
                    _markDirty();
                  }
                : null,
            onIncrement: () {
              setState(() => _lowStockThreshold += 1);
              _markDirty();
            },
          ),
        ),
        _buildDivider(),
        _buildHorizontalRow(
          icon: Icons.remove_circle_outline_rounded,
          label: 'Allow negative stock',
          hint: 'Permit cashier to sell even when inventory is 0',
          control: _buildTavolaSwitch(
            value: _allowNegativeStock,
            onChanged: (val) {
              setState(() => _allowNegativeStock = val);
              _markDirty();
            },
          ),
        ),
        _buildDivider(),
        _buildHorizontalRow(
          icon: Icons.print_outlined,
          label: 'Receipt paper size',
          hint: 'Thermal printer paper format',
          control: _buildSegmentedPill(
            options: ['80mm', '58mm'],
            selected: _paperSize,
            onSelect: (val) {
              setState(() => _paperSize = val);
              _markDirty();
            },
          ),
        ),
        _buildDivider(),
        _buildHorizontalRow(
          icon: Icons.qr_code_2_rounded,
          label: 'Receipt barcode',
          hint: 'Print scannable barcode for quick returns',
          control: _buildTavolaSwitch(
            value: _showBarcodeOnReceipt,
            onChanged: (val) {
              setState(() => _showBarcodeOnReceipt = val);
              _markDirty();
            },
          ),
        ),
        _buildDivider(),
        _buildHorizontalRow(
          icon: Icons.policy_outlined,
          label: 'Receipt footer',
          hint: 'Policy message at bottom of receipt',
          stackOnMobile: true,
          control: _buildInputCapsule(
            controller: _receiptFooter,
            hint: 'e.g. ទំនិញទិញហើយមិនអាចប្តូរប្រាក់វិញបានទេ • សូមអរគុណ!',
          ),
        ),
      ],
    );
  }

  // ==========================================
  // CARD 3: APPEARANCE (LEFT COLUMN, BOTTOM)
  // Opposite Data & Export
  // ==========================================
  Widget _buildAppearanceCard({required GlobalKey key}) {
    return _buildTavolaCardContainer(
      key: key,
      icon: Icons.wb_sunny_outlined,
      title: 'Appearance',
      subtitle: 'How the screen looks behind the glass',
      children: [
        _buildHorizontalRow(
          icon: Icons.nightlight_outlined,
          label: 'Theme',
          hint: _selectedTheme == 'Light'
              ? 'A crisp white room in natural sun'
              : _selectedTheme == 'System'
                  ? 'Follows your operating system theme'
                  : 'A navy room behind frosted glass',
          stackOnMobile: true,
          control: _buildSegmentedPill(
            options: ['Light', 'Dark', 'System'],
            selected: _selectedTheme,
            onSelect: (val) => _applyTheme(val),
          ),
        ),
        const SizedBox(height: 18),

        // Visual Theme Mockup Cards
        Row(
          children: [
            // Dark Room Box
            Expanded(
              child: InkWell(
                onTap: () => _applyTheme('Dark'),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 104,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedTheme == 'Dark' ? const Color(0xFFF9D8C0) : const Color(0xFF203254),
                      width: _selectedTheme == 'Dark' ? 2.0 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 24,
                              decoration: BoxDecoration(
                                color: const Color(0xFF334B6E),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9D8C0),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          'Dark',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Light Room Box (Crisp white preview box)
            Expanded(
              child: InkWell(
                onTap: () => _applyTheme('Light'),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 104,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _theme.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedTheme == 'Light' ? const Color(0xFFF9D8C0) : _theme.subBorder,
                      width: _selectedTheme == 'Light' ? 2.0 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 24,
                              decoration: BoxDecoration(
                                color: const Color(0xFFCBD5E1),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9D8C0),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          'Light',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _theme.isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // CARD 4: STORE HOURS (RIGHT COLUMN, TOP)
  // Copy today's lunch & dinner hours to all other 6 days
  void _copyTodayToAll() {
    final todayKey = DateFormat('EEE').format(DateTime.now());
    final source = _schedules[todayKey];
    if (source == null) return;

    setState(() {
      for (final entry in _schedules.entries) {
        if (entry.key != todayKey) {
          entry.value.isOpen = source.isOpen;
          entry.value.lunchStart.text = source.lunchStart.text;
          entry.value.lunchEnd.text = source.lunchEnd.text;
          entry.value.dinnerStart.text = source.dinnerStart.text;
          entry.value.dinnerEnd.text = source.dinnerEnd.text;
        }
      }
    });
    _markDirty();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Copied $todayKey schedule to all days'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Editable Time Capsule Box (Matching Tavola screenshot)
  Widget _buildScheduleTimeBox(TextEditingController controller, bool enabled) {
    return SizedBox(
      width: 82,
      height: 36,
      child: TextField(
        controller: controller,
        enabled: enabled,
        textAlign: TextAlign.center,
        onChanged: (_) => _markDirty(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: enabled ? _theme.textPrimary : _theme.textSecondary,
          letterSpacing: -0.2,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          filled: true,
          fillColor: enabled ? _theme.subCardBg : _theme.subCardBg.withValues(alpha: 0.3),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: _theme.subBorder, width: 1.0),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: _theme.subBorder.withValues(alpha: 0.3), width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFF9D8C0), width: 1.5),
          ),
        ),
      ),
    );
  }

  // Row for a single day in the Tavola schedule table
  Widget _buildDayScheduleRow(
    String day,
    _DayScheduleControllers s,
    bool isToday,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Day Abbreviation & Gold 'Today' label
          SizedBox(
            width: 44,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  day,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                    color: _theme.textPrimary,
                  ),
                ),
                if (isToday)
                  const Text(
                    'Today',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFBBF24),
                      height: 1.1,
                    ),
                  ),
              ],
            ),
          ),

          // Open Toggle Switch
          SizedBox(
            width: 50,
            child: _buildTavolaSwitch(
              value: s.isOpen,
              onChanged: (val) {
                setState(() => s.isOpen = val);
                _markDirty();
              },
            ),
          ),
          const SizedBox(width: 8),

          // Time Capsules for Lunch and Dinner (Dimmed when closed)
          AnimatedOpacity(
            opacity: s.isOpen ? 1.0 : 0.35,
            duration: const Duration(milliseconds: 150),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lunch Start – End
                _buildScheduleTimeBox(s.lunchStart, s.isOpen),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text(
                    '–',
                    style: TextStyle(
                      color: _theme.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildScheduleTimeBox(s.lunchEnd, s.isOpen),

                const SizedBox(width: 12),

                // Dinner Start – End
                _buildScheduleTimeBox(s.dinnerStart, s.isOpen),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text(
                    '–',
                    style: TextStyle(
                      color: _theme.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildScheduleTimeBox(s.dinnerEnd, s.isOpen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Perfectly opposite Store Profile at the top! (Tavola Signature Opening hours Card)
  // ==========================================
  Widget _buildStoreHoursCard({required GlobalKey key}) {
    final todayKey = DateFormat('EEE').format(DateTime.now());
    final todaySchedule = _schedules[todayKey];
    final bool isOpenToday = todaySchedule?.isOpen ?? true;
    final dinnerClosing = todaySchedule?.dinnerEnd.text.trim().isNotEmpty == true
        ? todaySchedule!.dinnerEnd.text.trim()
        : '10:30 PM';

    return _buildTavolaCardContainer(
      key: key,
      icon: Icons.access_time_rounded,
      title: 'Opening hours',
      subtitleWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isOpenToday ? const Color(0xFF10B981) : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              isOpenToday ? 'Open now · dinner until $dinnerClosing' : 'Closed today',
              style: TextStyle(
                fontSize: 12,
                color: _theme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      headerAction: InkWell(
        onTap: _copyTodayToAll,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _theme.subCardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _theme.subBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.copy_rounded, size: 13, color: _theme.textPrimary),
              const SizedBox(width: 6),
              Text(
                'Copy $todayKey to all',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _theme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
      children: [
        // Responsive scroll wrapper so it never overflows
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TABLE HEADER (DAY | OPEN | LUNCH | DINNER)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: Text(
                        'DAY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: _theme.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: Text(
                        'OPEN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: _theme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 178,
                      child: Text(
                        'LUNCH',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: _theme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 178,
                      child: Text(
                        'DINNER',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: _theme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 7 DAYS SCHEDULE ROWS (Mon – Sun)
              ..._schedules.entries.map((entry) {
                final day = entry.key;
                final sched = entry.value;
                final isToday = day == todayKey;
                return _buildDayScheduleRow(day, sched, isToday);
              }),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // CARD 5: NOTIFICATIONS (RIGHT COLUMN, MIDDLE)
  // Opposite POS Rules & Receipt
  // ==========================================
  Widget _buildNotificationsCard({required GlobalKey key}) {
    return _buildTavolaCardContainer(
      key: key,
      icon: Icons.notifications_none_rounded,
      title: 'Notifications',
      subtitle: 'System and inventory alerts for shop managers',
      children: [
        _buildHorizontalRow(
          icon: Icons.inventory_2_outlined,
          label: 'Low stock alerts',
          hint: 'When an item inventory drops below threshold',
          control: _buildTavolaSwitch(
            value: _notifLowStock,
            onChanged: (val) {
              setState(() => _notifLowStock = val);
              _markDirty();
            },
          ),
        ),
        _buildDivider(),
        _buildHorizontalRow(
          icon: Icons.mail_outline_rounded,
          label: 'Nightly digest',
          hint: 'One summary of sales, revenue and profit after close',
          control: _buildTavolaSwitch(
            value: _notifNightlyDigest,
            onChanged: (val) {
              setState(() => _notifNightlyDigest = val);
              _markDirty();
            },
          ),
        ),
        _buildDivider(),
        _buildHorizontalRow(
          icon: Icons.point_of_sale_rounded,
          label: 'Cashier shift alerts',
          hint: 'Drawer opening and shift reconciliation differences',
          control: _buildTavolaSwitch(
            value: _notifShiftAlerts,
            onChanged: (val) {
              setState(() => _notifShiftAlerts = val);
              _markDirty();
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // CARD 6: DATA & CLOUD EXPORT (RIGHT COLUMN, BOTTOM)
  // Opposite Appearance
  // ==========================================
  Widget _buildDataCard({required GlobalKey key}) {
    final salesCount = ref.watch(allRecentSalesProvider).value?.length ?? 0;
    final customersCount = ref.watch(customersStreamProvider).value?.length ?? 0;
    final productsCount = ref.watch(productsStreamProvider).value?.length ?? 0;

    return _buildTavolaCardContainer(
      key: key,
      icon: Icons.storage_rounded,
      title: 'Data & Cloud Export',
      subtitle: 'Everything synced securely in Google Cloud Firestore',
      children: [
        _buildHorizontalRow(
          icon: Icons.file_download_outlined,
          label: 'Export sales',
          hint: '$salesCount recent sales orders recorded',
          control: _buildCsvButton(
            label: 'CSV',
            onTap: _exportSalesCsv,
          ),
        ),
        _buildDivider(),
        _buildHorizontalRow(
          icon: Icons.people_outline_rounded,
          label: 'Export guest list',
          hint: '$customersCount registered customers with spend data',
          control: _buildCsvButton(
            label: 'CSV',
            onTap: _exportCustomersCsv,
          ),
        ),
        _buildDivider(),
        _buildHorizontalRow(
          icon: Icons.inventory_outlined,
          label: 'Export inventory',
          hint: '$productsCount products with barcodes and stock counts',
          control: _buildCsvButton(
            label: 'CSV',
            onTap: _exportInventoryCsv,
          ),
        ),
        _buildDivider(),
        _buildHorizontalRow(
          icon: Icons.cloud_sync_outlined,
          label: 'Sync cloud database',
          hint: 'Refresh local state with Firebase Firestore',
          control: OutlinedButton(
            onPressed: _isSyncing ? null : _syncCloudDatabase,
            style: OutlinedButton.styleFrom(
              backgroundColor: _theme.subCardBg,
              side: BorderSide(color: _theme.subBorder),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isSyncing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF9D8C0)),
                  )
                : Text(
                    'Sync',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _theme.textPrimary),
                  ),
          ),
        ),
        _buildDivider(),
        _buildHorizontalRow(
          icon: Icons.refresh_rounded,
          label: 'Reset demo data',
          hint: 'Restore local cached state back to sample data',
          control: OutlinedButton(
            onPressed: _resetDemoData,
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFFF9D8C0).withValues(alpha: 0.1),
              side: const BorderSide(color: Color(0xFFF9D8C0)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Reset',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF9D8C0)),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SHARED TAVOLA DESIGN SYSTEM HELPERS
  // ==========================================
  Widget _buildTavolaCardContainer({
    required GlobalKey key,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? subtitleWidget,
    Color? subtitleColor,
    Widget? headerAction,
    required List<Widget> children,
  }) {
    final isMobile = Responsive.isMobile(context);
    return Container(
      key: key,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: _theme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _theme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with signature peach squircle badge
          if (isMobile && headerAction != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9D8C0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 20, color: const Color(0xFF1E293B)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _theme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (subtitleWidget != null)
                            subtitleWidget
                          else if (subtitle != null)
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: subtitleColor ?? _theme.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                headerAction,
              ],
            )
          else
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9D8C0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: const Color(0xFF1E293B)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _theme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (subtitleWidget != null)
                        subtitleWidget
                      else if (subtitle != null)
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: subtitleColor ?? _theme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (headerAction != null) ...[
                  const SizedBox(width: 8),
                  headerAction,
                ],
              ],
            ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  // Horizontal split row: Icon + Label/Hint on Left | Control on Right (Responsive on Mobile)
  Widget _buildHorizontalRow({
    required IconData icon,
    required String label,
    required String hint,
    required Widget control,
    bool stackOnMobile = false,
  }) {
    final isMobile = Responsive.isMobile(context);

    if (isMobile && stackOnMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: _theme.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _theme.textPrimary,
                        ),
                      ),
                      if (hint.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          hint,
                          style: TextStyle(
                            fontSize: 11,
                            color: _theme.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: control,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: _theme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _theme.textPrimary,
                  ),
                ),
                if (hint.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: TextStyle(
                      fontSize: 11,
                      color: _theme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          control,
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 16, thickness: 1, color: _theme.divider);
  }

  // Capsule Input field (~280px width on desktop, 100% full width on mobile)
  Widget _buildInputCapsule({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isMobile = Responsive.isMobile(context);
    return SizedBox(
      width: isMobile ? double.infinity : 280,
      height: 38,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: (_) => _markDirty(),
        style: TextStyle(fontSize: 13, color: _theme.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: _theme.textSecondary.withValues(alpha: 0.7), fontSize: 12),
          filled: true,
          fillColor: _theme.subCardBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _theme.subBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFF9D8C0)),
          ),
        ),
      ),
    );
  }

  // Stepper Control `[ - ]  Value  [ + ]`
  Widget _buildStepperControl({
    required String valueText,
    required VoidCallback? onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: _theme.subCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _theme.subBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.remove, size: 14, color: _theme.textSecondary),
            onPressed: onDecrement,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            constraints: const BoxConstraints(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              valueText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _theme.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.add, size: 14, color: _theme.textSecondary),
            onPressed: onIncrement,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // Tavola iOS-style pill switch
  Widget _buildTavolaSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Transform.scale(
      scale: 0.85,
      child: Switch(
        value: value,
        activeThumbColor: Colors.white,
        activeTrackColor: const Color(0xFF10B981),
        inactiveThumbColor: _theme.textSecondary,
        inactiveTrackColor: _theme.isDark ? const Color(0xFF1E2D4A) : const Color(0xFFCBD5E1),
        onChanged: onChanged,
      ),
    );
  }

  // Segmented pill control (e.g. Light | Dark | System or KHR | USD)
  Widget _buildSegmentedPill({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    return Container(
      height: 34,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: _theme.subCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _theme.subBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final active = selected == opt;
          return InkWell(
            onTap: () => onSelect(opt),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: active
                    ? (_theme.isDark ? const Color(0xFF223554) : const Color(0xFFE2E8F0))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                opt,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                  color: active ? _theme.textPrimary : _theme.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // CSV download pill button
  Widget _buildCsvButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(Icons.download_rounded, size: 14, color: _theme.textPrimary),
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _theme.textPrimary)),
      style: OutlinedButton.styleFrom(
        backgroundColor: _theme.subCardBg,
        side: BorderSide(color: _theme.subBorder),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
