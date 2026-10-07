import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/sale_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/shift_provider.dart';
import '../../services/firebase_service.dart';
import 'receipt_dialog.dart';

class CheckoutDialog extends StatefulWidget {
  const CheckoutDialog({super.key});

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  String _paymentMethod = 'CASH_USD'; // 'CASH_USD', 'CASH_KHR', 'KHQR'
  final TextEditingController _cashController = TextEditingController();
  double _receivedAmount = 0.0;
  bool _isProcessing = false;

  final currencyUSD = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final currencyKHR = NumberFormat.currency(symbol: '៛', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    final cart = Provider.of<CartProvider>(context, listen: false);
    _receivedAmount = cart.totalUSD;
    _cashController.text = _receivedAmount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  void _onMethodChanged(String method, CartProvider cart) {
    setState(() {
      _paymentMethod = method;
      if (method == 'CASH_USD') {
        _receivedAmount = cart.totalUSD;
        _cashController.text = _receivedAmount.toStringAsFixed(2);
      } else if (method == 'CASH_KHR') {
        _receivedAmount = cart.totalKHR;
        _cashController.text = _receivedAmount.toStringAsFixed(0);
      } else {
        _receivedAmount = cart.totalUSD;
        _cashController.text = _receivedAmount.toStringAsFixed(2);
      }
    });
  }

  double _calculateChange(CartProvider cart) {
    if (_paymentMethod == 'CASH_USD') {
      double change = _receivedAmount - cart.totalUSD;
      return change > 0 ? change : 0.0;
    } else if (_paymentMethod == 'CASH_KHR') {
      double changeKHR = _receivedAmount - cart.totalKHR;
      return changeKHR > 0 ? (changeKHR / CartProvider.khrExchangeRate) : 0.0;
    }
    return 0.0; // KHQR exact
  }

  Future<void> _processPayment(
    CartProvider cart,
    AuthProvider auth,
    CustomerProvider customerProv,
    ShiftProvider shiftProv,
  ) async {
    setState(() => _isProcessing = true);

    final invoiceNo = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final double changeUSD = _calculateChange(cart);

    final sale = SaleModel(
      id: const Uuid().v4(),
      invoiceNo: invoiceNo,
      cashierName: auth.currentUser.name,
      items: List.from(cart.items),
      subtotalUSD: cart.subtotalUSD,
      discountUSD: cart.totalDiscountUSD,
      taxUSD: cart.taxUSD,
      totalUSD: cart.totalUSD,
      totalKHR: cart.totalKHR,
      paymentMethod: _paymentMethod,
      cashReceived: _paymentMethod == 'CASH_KHR'
          ? (_receivedAmount / CartProvider.khrExchangeRate)
          : _receivedAmount,
      changeGiven: changeUSD,
      customerName: cart.selectedCustomer?.name ?? 'អតិថិជនទូទៅ',
      redeemedPoints: cart.redeemedPoints,
      createdAt: DateTime.now(),
    );

    // 1. Record sale in Firebase and deduct product stock
    final firebaseService = FirebaseService();
    await firebaseService.recordSale(sale);

    // 2. Add to active shift in ShiftProvider
    shiftProv.addSaleToShift(cart.totalUSD);

    // 3. Deduct points if redeemed, or add loyalty points (1 point per $1 spent)
    if (cart.selectedCustomer != null) {
      if (cart.redeemedPoints > 0) {
        customerProv.deductPoints(cart.selectedCustomer!.id, cart.redeemedPoints);
      } else {
        customerProv.addPoints(cart.selectedCustomer!.id, cart.totalUSD.toInt());
      }
    }

    // 4. Clear current cart
    cart.clearCart();

    if (!mounted) return;
    setState(() => _isProcessing = false);
    Navigator.of(context).pop(); // close checkout dialog

    // 5. Open official thermal receipt
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReceiptDialog(sale: sale),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final customerProv = Provider.of<CustomerProvider>(context, listen: false);
    final shiftProv = Provider.of<ShiftProvider>(context, listen: false);
    final double changeUSD = _calculateChange(cart);
    final double changeKHR = (changeUSD * CartProvider.khrExchangeRate).roundToDouble();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('គិតលុយ / Checkout',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
              const Divider(),

              // Amount due banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ទឹកប្រាក់ត្រូវបង់:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        if (cart.selectedCustomer != null)
                          Text('អតិថិជន: ${cart.selectedCustomer!.name}',
                              style: const TextStyle(fontSize: 12, color: Colors.indigo)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(currencyUSD.format(cart.totalUSD),
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo.shade900)),
                        Text(currencyKHR.format(cart.totalKHR),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Payment method tabs
              const Text('វិធីសាស្ត្រទូទាត់ (Payment Method):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildMethodButton('CASH_USD', 'Cash (\$)', Icons.attach_money, cart),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMethodButton('CASH_KHR', 'Cash (៛)', Icons.payments_outlined, cart),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMethodButton('KHQR', 'Bakong QR', Icons.qr_code_2, cart),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Cash input section
              if (_paymentMethod != 'KHQR') ...[
                Text(
                  _paymentMethod == 'CASH_USD' ? 'ប្រាក់ទទួលបាន (USD):' : 'ប្រាក់ទទួលបាន (KHR):',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _cashController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    prefixIcon: Icon(_paymentMethod == 'CASH_USD' ? Icons.attach_money : Icons.payments),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _receivedAmount = double.tryParse(val) ?? 0.0;
                    });
                  },
                ),
                const SizedBox(height: 10),

                // Quick denomination buttons
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _paymentMethod == 'CASH_USD'
                      ? [1.0, 5.0, 10.0, 20.0, 50.0, 100.0].map((amt) {
                          return ActionChip(
                            label: Text('\$$amt'),
                            onPressed: () {
                              setState(() {
                                _receivedAmount = amt;
                                _cashController.text = amt.toStringAsFixed(2);
                              });
                            },
                          );
                        }).toList()
                      : [5000.0, 10000.0, 20000.0, 50000.0, 100000.0].map((amt) {
                          return ActionChip(
                            label: Text('${amt.toInt()}៛'),
                            onPressed: () {
                              setState(() {
                                _receivedAmount = amt;
                                _cashController.text = amt.toStringAsFixed(0);
                              });
                            },
                          );
                        }).toList(),
                ),
                const SizedBox(height: 14),

                // Change calculation box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ប្រាក់អាប់ជូន (Change):',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(currencyUSD.format(changeUSD),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green.shade900)),
                          Text(currencyKHR.format(changeKHR),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // KHQR Display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.qr_code_scanner, size: 60, color: Colors.red),
                      const SizedBox(height: 6),
                      const Text('Bakong KHQR Payment',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                      const Text('អតិថិជនស្កេនទូទាត់ប្រាក់ភ្លាមៗតាម App ធនាគារនានា',
                          style: TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 8),
                      Text(currencyUSD.format(cart.totalUSD),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Confirm button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _isProcessing ? 'កំពុងដំណើរការ...' : 'បញ្ជាក់ការទូទាត់ និងចេញវិក្កយបត្រ',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: _isProcessing ? null : () => _processPayment(cart, auth, customerProv, shiftProv),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodButton(String method, String label, IconData icon, CartProvider cart) {
    final isSelected = _paymentMethod == method;
    return InkWell(
      onTap: () => _onMethodChanged(method, cart),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo.shade800 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? Colors.indigo.shade800 : Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.black87),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
