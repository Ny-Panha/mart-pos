import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

class QtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final ValueChanged<int>? onQtyChanged;
  final int maxQty;

  const QtyStepper({
    super.key,
    required this.qty,
    required this.onDecrease,
    required this.onIncrease,
    this.onQtyChanged,
    this.maxQty = 9999,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(
            icon: Icons.remove,
            onTap: onDecrease,
            isDark: isDark,
          ),
          InkWell(
            onTap: onQtyChanged == null
                ? null
                : () async {
                    final controller = TextEditingController(text: '$qty');
                    final result = await showDialog<int>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                        title: const Text('បញ្ចូលចំនួន (Quantity)'),
                        content: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          autofocus: true,
                          decoration: InputDecoration(
                            labelText: 'ចំនួន (Qty) - អតិបរិមា $maxQty',
                            isDense: true,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('បោះបង់'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              final val = int.tryParse(controller.text) ?? qty;
                              Navigator.pop(ctx, val);
                            },
                            child: const Text('យល់ព្រម'),
                          ),
                        ],
                      ),
                    );
                    if (result != null && result > 0) {
                      onQtyChanged!(result);
                    }
                  },
            borderRadius: BorderRadius.circular(4),
            child: Container(
              constraints: const BoxConstraints(minWidth: 32),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                '$qty',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ),
          ),
          _buildButton(
            icon: Icons.add,
            onTap: qty < maxQty ? onIncrease : null,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 16,
          color: onTap == null
              ? (isDark ? AppColors.darkBorder : Colors.grey.shade400)
              : (isDark ? AppColors.darkText : AppColors.lightText),
        ),
      ),
    );
  }
}
