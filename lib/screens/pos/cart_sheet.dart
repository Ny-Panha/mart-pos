import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import 'checkout_dialog.dart';

class CartSheet extends StatelessWidget {
  const CartSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final customerProv = Provider.of<CustomerProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final isDark = themeProv.isDarkMode;

    final currencyUSD = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final currencyKHR = NumberFormat.currency(symbol: '៛', decimalDigits: 0);

    final bgColor = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedText = isDark ? AppColors.darkMutedText : AppColors.lightMutedText;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header: Title & Clear ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_cart_outlined, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'កន្ត្រកទំនិញ (${cart.totalItemCount})',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ],
              ),
              if (cart.items.isNotEmpty)
                TextButton(
                  onPressed: () => cart.clearCart(),
                  child: const Text(
                    'សម្អាត (Clear)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // ── Hold Orders & Resume Bills toolbar ──
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.pause_circle_outline, size: 16),
                  label: const Text('Hold Bill', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: cart.items.isEmpty
                      ? null
                      : () {
                          cart.holdCurrentBill();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('បានរក្សាទុកវិក្កយបត្រនេះបណ្ដោះអាសន្ន (Bill Held)'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(color: cart.heldBills.isNotEmpty ? AppColors.cyan : borderColor),
                    backgroundColor: cart.heldBills.isNotEmpty ? AppColors.cyan.withValues(alpha: 0.1) : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: Icon(
                    Icons.history,
                    size: 16,
                    color: cart.heldBills.isNotEmpty ? AppColors.cyan : mutedText,
                  ),
                  label: Text(
                    'Resume (${cart.heldBills.length})',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: cart.heldBills.isNotEmpty ? AppColors.cyan : mutedText,
                    ),
                  ),
                  onPressed: cart.heldBills.isEmpty ? null : () => _showHeldBillsDialog(context, cart),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Customer Selector & Points ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBg : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_pin, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: bgColor,
                      value: cart.selectedCustomer?.id,
                      hint: Text('អតិថិជនទូទៅ (Guest Customer)', style: TextStyle(fontSize: 12, color: mutedText)),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text('អតិថិជនទូទៅ (Guest)', style: TextStyle(fontSize: 12, color: textColor)),
                        ),
                        ...customerProv.customers.map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text('${c.name} (${c.points} pts)', style: TextStyle(fontSize: 12, color: textColor)),
                            )),
                      ],
                      onChanged: (id) {
                        if (id == null) {
                          cart.setSelectedCustomer(null);
                        } else {
                          final c = customerProv.customers.firstWhere((item) => item.id == id);
                          cart.setSelectedCustomer(c);
                        }
                      },
                    ),
                  ),
                ),
                if (cart.selectedCustomer != null && cart.selectedCustomer!.points > 0)
                  TextButton(
                    onPressed: () => _showRedeemPointsDialog(context, cart),
                    child: Text(
                      cart.redeemedPoints > 0 ? 'កាត់ ${cart.redeemedPoints} pts' : 'ប្រើពិន្ទុ',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 20),

          // ── Cart Items List ──
          Expanded(
            child: cart.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.remove_shopping_cart_outlined, size: 48, color: mutedText.withValues(alpha: 0.5)),
                        const SizedBox(height: 8),
                        Text('មិនទាន់មានទំនិញក្នុងកន្ត្រកទេ', style: TextStyle(color: mutedText, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('ចុចលើទំនិញ ឬស្កេន Barcode', style: TextStyle(fontSize: 11, color: mutedText)),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: cart.items.length,
                    separatorBuilder: (_, _) => Divider(height: 1, color: borderColor.withValues(alpha: 0.5)),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            // Title & Price
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${currencyUSD.format(item.unitPrice)} / ${item.product.unit}',
                                    style: TextStyle(fontSize: 11, color: mutedText),
                                  ),
                                ],
                              ),
                            ),

                            // Controls (- qty +)
                            Row(
                              children: [
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                                  color: mutedText,
                                  onPressed: () => cart.decrementQuantity(item.product.id),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    '${item.quantity}',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.primary),
                                  onPressed: () => cart.incrementQuantity(item.product.id),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),

                            // Line total
                            SizedBox(
                              width: 60,
                              child: Text(
                                currencyUSD.format(item.total),
                                textAlign: TextAlign.right,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          const Divider(thickness: 1.2),

          // ── Cost Breakdown (Matching POS.jsx totals) ──
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('តម្លៃសរុប (Subtotal):', style: TextStyle(fontSize: 13, color: mutedText)),
                Text(currencyUSD.format(cart.subtotalUSD), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
              ],
            ),
          ),
          if (cart.totalDiscountUSD > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('បញ្ចុះតម្លៃ ${cart.redeemedPoints > 0 ? "(ពិន្ទុ ${cart.redeemedPoints})" : ""}:',
                      style: const TextStyle(fontSize: 12, color: Colors.red)),
                  Text('-${currencyUSD.format(cart.totalDiscountUSD)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('តម្លៃចុងក្រោយ (USD):', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                Text(
                  currencyUSD.format(cart.totalUSD),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('សរុបជាប្រាក់រៀល (KHR):', style: TextStyle(fontSize: 12, color: mutedText)),
                Text(
                  currencyKHR.format(cart.totalKHR),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: mutedText),
                ),
              ],
            ),
          ),

          // ── Checkout Button (Matching POS.jsx Pay Now button) ──
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            onPressed: cart.items.isEmpty
                ? null
                : () {
                    showDialog(
                      context: context,
                      builder: (context) => const CheckoutDialog(),
                    );
                  },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.payments_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  'គិតលុយ (${currencyUSD.format(cart.totalUSD)})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRedeemPointsDialog(BuildContext context, CartProvider cart) {
    int maxPoints = cart.selectedCustomer?.points ?? 0;
    int pointsToUse = maxPoints;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ប្រើប្រាស់ពិន្ទុសន្សំ (Redeem Points)'),
        content: Text(
          'អតិថិជនមាន: $maxPoints ពិន្ទុ\nអត្រាប្តូរ: 100 ពិន្ទុ = \$1.00\nប្រើ $pointsToUse ពិន្ទុ បញ្ចុះតម្លៃបាន: \$${(pointsToUse * 0.01).toStringAsFixed(2)}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              cart.setRedeemedPoints(0);
              Navigator.of(ctx).pop();
            },
            child: const Text('មិនប្រើ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              cart.setRedeemedPoints(pointsToUse);
              Navigator.of(ctx).pop();
            },
            child: const Text('យល់ព្រមប្រើ'),
          ),
        ],
      ),
    );
  }

  void _showHeldBillsDialog(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('វិក្កយបត្រដែលបានផ្អាក (Held Bills)'),
        content: SizedBox(
          width: 320,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: cart.heldBills.length,
            itemBuilder: (context, idx) {
              final held = cart.heldBills[idx];
              final total = held.fold(0.0, (sum, i) => sum + i.total);
              return ListTile(
                leading: CircleAvatar(child: Text('${idx + 1}')),
                title: Text('វិក្កយបត្រទី ${idx + 1} (${held.length} មុខ)'),
                subtitle: Text('សរុប: \$${total.toStringAsFixed(2)}'),
                trailing: ElevatedButton(
                  child: const Text('Resume'),
                  onPressed: () {
                    cart.resumeHeldBill(idx);
                    Navigator.of(context).pop();
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
