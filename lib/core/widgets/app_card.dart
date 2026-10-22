import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final Border? border;
  final BorderRadiusGeometry? borderRadius;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final double? height;
  final bool isFrosted;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.gradient,
    this.border,
    this.borderRadius,
    this.boxShadow,
    this.width,
    this.height,
    this.isFrosted = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = gradient != null
        ? null
        : (color ??
            (isFrosted
                ? (isDark
                    ? const Color(0xFF0E1830).withValues(alpha: 0.65)
                    : Colors.white.withValues(alpha: 0.75))
                : (isDark ? AppColors.darkCard : AppColors.lightCard)));
    final borderColor = isFrosted
        ? (isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.08))
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);
    final effectiveRadius = borderRadius ?? BorderRadius.circular(AppRadius.card);
    final br = effectiveRadius is BorderRadius
        ? effectiveRadius
        : BorderRadius.circular(AppRadius.card);

    Widget body = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: effectiveRadius,
        border: border ?? Border.all(color: borderColor, width: 1),
      ),
      child: child,
    );

    if (onTap != null) {
      body = InkWell(
        borderRadius: br,
        onTap: onTap,
        child: body,
      );
    }

    Widget container = Container(
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: (isDark ? AppColors.darkPrimary : AppColors.primary)
                .withValues(alpha: isDark ? 0.04 : 0.015),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: gradient != null ? Colors.transparent : cardColor,
        borderRadius: effectiveRadius,
        clipBehavior: Clip.antiAlias,
        child: body,
      ),
    );

    if (isFrosted) {
      container = ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: container,
        ),
      );
    }

    return container;
  }
}

