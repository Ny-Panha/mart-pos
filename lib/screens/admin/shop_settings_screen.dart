import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class ShopSettingsScreen extends StatefulWidget {
  const ShopSettingsScreen({super.key});

  @override
  State<ShopSettingsScreen> createState() => _ShopSettingsScreenState();
}

class _ShopSettingsScreenState extends State<ShopSettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers for Shop Profile
  final _nameKmCtrl = TextEditingController(text: 'ម៉ាត ភីអូអេស (Mart POS)');
  final _nameEnCtrl = TextEditingController(text: 'Mart POS Convenience Store');
  final _phoneCtrl = TextEditingController(text: '098 765 432 / 012 345 678');
  final _emailCtrl = TextEditingController(text: 'contact@martpos.bbu.edu.kh');
  final _addressCtrl = TextEditingController(text: 'ផ្លូវលេខ ៣, ក្រុងបាត់ដំបង, ខេត្តបាត់ដំបង');
  String _selectedProvince = 'ខេត្តបាត់ដំបង (Battambang)';

  // Controllers for POS Settings
  final _exchangeRateCtrl = TextEditingController(text: '4100');
  final _taxRateCtrl = TextEditingController(text: '0');
  final _footerNoteCtrl = TextEditingController(text: 'សូមអរគុណ! សូមអញ្ជើញមកពិសា និងទិញម្តងទៀត 🙏');
  final _bakongIdCtrl = TextEditingController(text: 'mart_pos_bbu@aclb');

  final List<String> _provinces = [
    'ខេត្តបាត់ដំបង (Battambang)',
    'រាជធានីភ្នំពេញ (Phnom Penh)',
    'ខេត្តសៀមរាប (Siem Reap)',
    'ខេត្តបន្ទាយមានជ័យ (Banteay Meanchey)',
    'ខេត្តកំពង់ចាម (Kampong Cham)',
    'ខេត្តព្រះសីហនុ (Preah Sihanouk)',
    'ខេត្តកណ្តាល (Kandal)',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ បានរក្សាទុកការកំណត់ហាងជោគជ័យ (Settings Saved Successfully)'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final isDark = themeProv.isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SETTINGS / ការកំណត់ហាង',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ការកំណត់ព័ត៌មានហាង & ប្រព័ន្ធ (Shop Settings)',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'កែប្រែព័ត៌មានហាង អត្រាប្តូរប្រាក់ ពន្ធ កំណត់ចំណាំវិក្កយបត្រ និង KHQR',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('រក្សាទុកការកំណត់ (Save Changes)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Tabs
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.primary,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.store, size: 18), text: 'ព័ត៌មានហាង & POS (General & POS)'),
                  Tab(icon: Icon(Icons.notifications_active, size: 18), text: 'កំណត់ហេតុប្រព័ន្ធ (System Logs)'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 600,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGeneralSettings(isDark),
                  _buildSystemLogs(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettings(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Section 1: Shop Profile
          _buildCard(
            isDark,
            title: 'ព័ត៌មានអត្តសញ្ញាណហាង (Store Identity)',
            subtitle: 'បង្ហាញលើក្បាលវិក្កយបត្រ និងព័ត៌មានទំនាក់ទំនងអាជីវកម្ម',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildInput(isDark, 'ឈ្មោះហាងជាភាសាខ្មែរ (Shop Name Khmer)*', _nameKmCtrl)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildInput(isDark, 'ឈ្មោះហាងជាអក្សរឡាតាំង (Shop Name English)*', _nameEnCtrl)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildInput(isDark, 'លេខទូរស័ព្ទហាង (Contact Phone)', _phoneCtrl)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildInput(isDark, 'អ៊ីមែលហាង (Store Email)', _emailCtrl)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ខេត្ត / រាជធានី (Province / City)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkBg : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedProvince,
                                items: _provinces.map((p) => DropdownMenuItem(value: p, child: Text(p, style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkText : AppColors.lightText)))).toList(),
                                onChanged: (v) => setState(() => _selectedProvince = v!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _buildInput(isDark, 'អាសយដ្ឋានលម្អិត (Street Address)', _addressCtrl)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section 2: Financial & POS Config
          _buildCard(
            isDark,
            title: 'ប្រតិបត្តិការហិរញ្ញវត្ថុ & វិក្កយបត្រ (POS & Receipt Config)',
            subtitle: 'កំណត់អត្រាប្តូរប្រាក់ដុល្លារ/រៀល ពន្ធអាករ និង Bakong KHQR',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildInput(isDark, 'អត្រាប្តូរប្រាក់ (Exchange Rate 1 USD = KHR)*', _exchangeRateCtrl, isNumber: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildInput(isDark, 'អាករលើតម្លៃបន្ថែម (VAT Tax %)*', _taxRateCtrl, isNumber: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildInput(isDark, 'គណនី Bakong ID (KHQR Merchant)*', _bakongIdCtrl)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInput(isDark, 'សារជូនពរចុងវិក្កយបត្រ (Receipt Footer Message)', _footerNoteCtrl, maxLines: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemLogs(bool isDark) {
    return _buildCard(
      isDark,
      title: 'កំណត់ហេតុសកម្មភាពប្រព័ន្ធ (System Notification & Action Logs)',
      subtitle: 'ប្រវត្តិប្រតិបត្តិការសំខាន់ៗក្នុងប្រព័ន្ធ Mart POS',
      child: Column(
        children: [
          _buildLogRow(isDark, 'បិទវេនលក់ (Shift Closed)', 'បេឡាករ "គក់ ស្រីផ្កាយ" បានបិទវេនលក់ប្រចាំថ្ងៃដោយជោគជ័យ។', '10 នាទីមុន', Icons.lock_clock, Colors.blue),
          _buildLogRow(isDark, 'កែសម្រួលស្តុក (Stock Adjustment)', 'បុគ្គលិក "នី បញ្ញា" បានកែសម្រួលស្តុក "Coca-Cola" នាំចូល +50 កំប៉ុង។', '1 ម៉ោងមុន', Icons.inventory, const Color(0xFF10B981)),
          _buildLogRow(isDark, 'ការបញ្ជាទិញទំនិញថ្មី (Purchase PO)', 'បានបង្កើត PO-1002 សម្រាប់ផ្គត់ផ្គង់ទឹកដោះគោ Angkor Dairy។', '3 ម៉ោងមុន', Icons.shopping_cart, Colors.orange),
          _buildLogRow(isDark, 'ចូលប្រើប្រព័ន្ធ (User Login)', 'អ្នកគ្រប់គ្រង "នី បញ្ញា" បានចូលប្រើប្រព័ន្ធតាមរយៈ Web Terminal។', '5 ម៉ោងមុន', Icons.login, Colors.purple),
          _buildLogRow(isDark, 'ការបង់ប្រាក់ KHQR', 'ការទូទាត់ប្រាក់ \$24.50 តាមរយៈ Bakong KHQR ជោគជ័យ។', '6 ម៉ោងមុន', Icons.qr_code_2, Colors.green),
        ],
      ),
    );
  }

  Widget _buildLogRow(bool isDark, String title, String desc, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? AppColors.darkText : AppColors.lightText)),
                    Text(time, style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(desc, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(bool isDark, {required String title, required String subtitle, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 20, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkText : AppColors.lightText)),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText)),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInput(bool isDark, String label, TextEditingController ctrl, {bool isNumber = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkText : AppColors.lightText),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: isDark ? AppColors.darkBg : Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }
}
