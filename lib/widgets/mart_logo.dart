import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MartLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final double fontSize;

  const MartLogo({
    super.key,
    this.size = 40,
    this.showText = false,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryContainer,
              ],
            ),
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: size * 0.58,
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mart POS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'ប្រព័ន្ធគ្រប់គ្រងការលក់នៅម៉ាត',
                style: TextStyle(
                  fontSize: fontSize * 0.7,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
