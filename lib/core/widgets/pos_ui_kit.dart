import 'package:mart_pos/core/motion/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// ============================================================================
/// MART POS — MODERN CORE UI KIT
/// Built from a blank canvas according to Linear, Stripe, and Apple HIG.
/// ============================================================================

/// 1. Standard Page Scaffold
class PosPageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? badge;
  final List<Widget> actions;
  final Widget child;
  final Widget? floatingActionButton;
  final EdgeInsetsGeometry? padding;

  const PosPageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.badge,
    this.actions = const [],
    required this.child,
    this.floatingActionButton,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 650;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0D14) : const Color(0xFFF8FAFC),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: padding ?? EdgeInsets.all(isCompact ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: GoogleFonts.notoSansKhmer(
                                  fontSize: isCompact ? 20 : 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            if (badge != null) ...[
                              const SizedBox(width: 8),
                              PosStatusBadge(
                                label: badge!,
                                variant: PosBadgeVariant.primary,
                              ),
                            ],
                          ],
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: GoogleFonts.notoSansKhmer(
                              fontSize: isCompact ? 11.5 : 13,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: actions,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// 2. Modern Metric KPI Card
class PosMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? delta;
  final bool isPositive;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const PosMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.delta,
    this.isPositive = true,
    required this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = color ?? AppColors.primary;

    return Material(
      color: isDark ? const Color(0xFF111622) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF1F293D) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: accent, size: 20),
                  ),
                  if (delta != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isPositive ? AppColors.success : AppColors.danger)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                            size: 12,
                            color: isPositive ? AppColors.success : AppColors.danger,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            delta!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isPositive ? AppColors.success : AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: GoogleFonts.notoSansKhmer(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 3. Flat Section Card with single-level border
class PosSectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const PosSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111622) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1F293D) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.notoSansKhmer(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: GoogleFonts.notoSansKhmer(
                            fontSize: 11.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF1F293D) : const Color(0xFFE2E8F0),
          ),
          Padding(
            padding: padding,
            child: child,
          ),
        ],
      ),
    );
  }
}

/// 4. Semantic Status Badge
enum PosBadgeVariant { primary, success, warning, danger, info, neutral }

class PosStatusBadge extends StatelessWidget {
  final String label;
  final PosBadgeVariant variant;
  final Color? customColor;
  final IconData? icon;

  const PosStatusBadge({
    super.key,
    required this.label,
    this.variant = PosBadgeVariant.neutral,
    this.customColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color base;
    if (customColor != null) {
      base = customColor!;
    } else {
      switch (variant) {
        case PosBadgeVariant.primary:
          base = AppColors.primary;
          break;
        case PosBadgeVariant.success:
          base = AppColors.success;
          break;
        case PosBadgeVariant.warning:
          base = AppColors.warning;
          break;
        case PosBadgeVariant.danger:
          base = AppColors.danger;
          break;
        case PosBadgeVariant.info:
          base = const Color(0xFF0EA5E9);
          break;
        case PosBadgeVariant.neutral:
          base = const Color(0xFF64748B);
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: base),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.notoSansKhmer(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: base,
            ),
          ),
        ],
      ),
    );
  }
}

/// 5. Standard Search Bar
class PosSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onScan;
  final Widget? trailing;

  const PosSearchBar({
    super.key,
    this.hintText = 'ស្វែងរក...',
    required this.onChanged,
    this.onScan,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111622) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF1F293D) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: GoogleFonts.notoSansKhmer(fontSize: 13),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.notoSansKhmer(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (onScan != null)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
              color: AppColors.primary,
              tooltip: 'Scan barcode',
              onPressed: onScan,
            ),
          ?trailing,
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

/// 6. Horizontal Category Pill Filter Ribbon
class PosCategoryFilter extends StatelessWidget {
  final List<String> categories;
  final String activeCategory;
  final ValueChanged<String> onSelected;

  const PosCategoryFilter({
    super.key,
    required this.categories,
    required this.activeCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = cat == activeCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? const Color(0xFF111622) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () => onSelected(cat),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? const Color(0xFF1F293D) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Text(
                    cat,
                    style: GoogleFonts.notoSansKhmer(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 7. Standard Buttons
class PosButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final bool isDestructive;

  const PosButton({
    super.key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = isDestructive
        ? AppColors.danger
        : (isSecondary ? Colors.transparent : AppColors.primary);
    Color fg = isSecondary ? AppColors.primary : Colors.white;

    if (isSecondary) {
      return SpringPressEffect(
        enabled: !isLoading && onPressed != null,
        child: OutlinedButton.icon(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            side: BorderSide(
              color: isDestructive ? AppColors.danger : AppColors.primary,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : (icon != null ? Icon(icon, size: 16) : const SizedBox.shrink()),
          label: Text(
            text,
            style: GoogleFonts.notoSansKhmer(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      );
    }

    return SpringPressEffect(
      enabled: !isLoading && onPressed != null,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : (icon != null ? Icon(icon, size: 16) : const SizedBox.shrink()),
        label: Text(
          text,
          style: GoogleFonts.notoSansKhmer(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }
}

/// 8. Empty State
class PosEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  const PosEmptyState({
    super.key,
    this.icon = Icons.inbox_rounded,
    required this.title,
    required this.description,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.notoSansKhmer(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKhmer(
                  fontSize: 12.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// 9. Shimmering Skeleton for loading states
class PosSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const PosSkeleton({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
