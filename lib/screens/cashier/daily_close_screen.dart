import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shift_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class DailyCloseScreen extends StatefulWidget {
  const DailyCloseScreen({super.key});

  @override
  State<DailyCloseScreen> createState() => _DailyCloseScreenState();
}

class _DailyCloseScreenState extends State<DailyCloseScreen> {
  final TextEditingController _cashCountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final currencyUSD = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void dispose() {
    _cashCountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _handleCloseShift(ShiftProvider shiftProv, AuthProvider auth) {
    final counted = double.tryParse(_cashCountController.text) ?? 0.0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_clock, color: AppColors.primary),
            SizedBox(width: 8),
            Text('បញ្ជាក់ការបិទវេន (Close Shift)'),
          ],
        ),
        content: Text(
          'តើអ្នកពិតជាចង់បិទវេនការងារនេះមែនទេ?\nប្រាក់រាប់បានជាក់ស្តែង: ${currencyUSD.format(counted)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('បោះបង់'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              shiftProv.closeShift(
                countedCash: counted,
                note: _noteController.text,
              );
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('បានបិទវេនដោយជោគជ័យ! (Shift Closed)'),
                  backgroundColor: AppColors.emerald,
                ),
              );
            },
            child: const Text('បិទវេនឥឡូវនេះ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shiftProv = Provider.of<ShiftProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final isDark = themeProv.isDarkMode;

    final current = shiftProv.currentShift;
    final expectedCash = current.openingCash + current.totalSales;
    final countedNumber = double.tryParse(_cashCountController.text) ?? 0.0;
    final difference = countedNumber - expectedCash;

    final bgColor = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedText = isDark ? AppColors.darkMutedText : AppColors.lightMutedText;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header (Matching DailyClose.jsx)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'បិទវេនប្រចាំថ្ងៃ (Daily Close / Shift)',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'គ្រប់គ្រង និងទូទាត់ប្រាក់ក្នុងថតរបស់ Cashier មុនពេលបិទម៉ាត',
                    style: TextStyle(fontSize: 13, color: mutedText),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: current.isClosed
                      ? Colors.grey.withValues(alpha: 0.15)
                      : AppColors.emerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      current.isClosed ? Icons.lock : Icons.lock_open,
                      size: 16,
                      color: current.isClosed ? Colors.grey : AppColors.emerald,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      current.isClosed ? 'Shift Closed' : 'Active Shift',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: current.isClosed ? Colors.grey : AppColors.emerald,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Shift Status Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: current.isClosed ? Colors.grey.shade400 : AppColors.primary,
                  foregroundColor: Colors.white,
                  child: Icon(current.isClosed ? Icons.lock : Icons.storefront),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        current.isClosed ? 'វេនត្រូវបានបិទរួចរាល់' : 'វេនកំពុងដំណើរការ (Active Cashier Shift)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'អ្នកគិតលុយ: ${current.cashierName} • បើកតាំងពី: ${dateFormat.format(current.openedAt)}',
                        style: TextStyle(fontSize: 12, color: mutedText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Financial Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'ប្រាក់ដើមគ្រា (Float)',
                  currencyUSD.format(current.openingCash),
                  Icons.account_balance_wallet_outlined,
                  AppColors.cyan,
                  bgColor,
                  borderColor,
                  mutedText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'ការលក់សរុប (Sales)',
                  currencyUSD.format(current.totalSales),
                  Icons.trending_up,
                  AppColors.emerald,
                  bgColor,
                  borderColor,
                  mutedText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'ប្រាក់រំពឹងទុកក្នុងថត',
                  currencyUSD.format(expectedCash),
                  Icons.payments_outlined,
                  AppColors.primary,
                  bgColor,
                  borderColor,
                  mutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (!current.isClosed) ...[
            // Cash counting input card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'រាប់ប្រាក់ជាក់ស្តែងក្នុងថត (Counted Drawer Cash):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _cashCountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.attach_money),
                      hintText: '0.00',
                      filled: true,
                      fillColor: isDark ? AppColors.darkBg : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),

                  // Discrepancy indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: difference == 0
                          ? AppColors.emerald.withValues(alpha: 0.1)
                          : (difference > 0 ? Colors.blue.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          difference == 0
                              ? 'ប្រាក់ស្មើត្រឹមត្រូវ (Balanced)'
                              : (difference > 0 ? 'ប្រាក់លើស (Over)' : 'ប្រាក់ខ្វះ (Short)'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: difference == 0
                                ? AppColors.emerald
                                : (difference > 0 ? Colors.blue : Colors.red),
                          ),
                        ),
                        Text(
                          currencyUSD.format(difference),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: difference == 0
                                ? AppColors.emerald
                                : (difference > 0 ? Colors.blue : Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: 'កំណត់ចំណាំបន្ថែម (Optional Note)',
                      filled: true,
                      fillColor: isDark ? AppColors.darkBg : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('បិទវេនការងារ (Close Shift)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    onPressed: () => _handleCloseShift(shiftProv, auth),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Open new shift button
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('បើកវេនការងារថ្មី (Open New Shift)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                onPressed: () {
                  shiftProv.openNewShift(cashierName: auth.currentUser.name, openingCash: 50.0);
                  _cashCountController.clear();
                  _noteController.clear();
                },
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Past Shifts History
          if (shiftProv.history.isNotEmpty) ...[
            Text('ប្រវត្តិវេនការងារកន្លងមក (Shift History):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
            const SizedBox(height: 12),
            ...shiftProv.history.map((h) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        child: Icon(Icons.history, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${h.cashierName} • លក់បាន: ${currencyUSD.format(h.totalSales)}',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                            const SizedBox(height: 2),
                            Text(
                              'បិទនៅ: ${dateFormat.format(h.closedAt ?? DateTime.now())} ${h.note.isNotEmpty ? "• ${h.note}" : ""}',
                              style: TextStyle(fontSize: 11, color: mutedText),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: h.difference == 0
                              ? AppColors.emerald.withValues(alpha: 0.12)
                              : Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          h.difference == 0 ? 'Balanced' : currencyUSD.format(h.difference),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: h.difference == 0 ? AppColors.emerald : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
    Color borderColor,
    Color mutedText,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 11, color: mutedText), maxLines: 1),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color), maxLines: 1),
        ],
      ),
    );
  }
}
