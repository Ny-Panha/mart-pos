import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CapsuleTabItem {
  final String label;
  final String? count;
  final IconData? icon;

  const CapsuleTabItem({
    required this.label,
    this.count,
    this.icon,
  });
}

/// A luxury sliding capsule pill tab bar inspired by Tavola's navigation tabs.
class CapsuleTabBar extends StatefulWidget {
  final List<CapsuleTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final bool isDense;

  const CapsuleTabBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTabSelected,
    this.isDense = false,
  });

  @override
  State<CapsuleTabBar> createState() => _CapsuleTabBarState();
}

class _CapsuleTabBarState extends State<CapsuleTabBar> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _tabKeys = [];

  @override
  void initState() {
    super.initState();
    _rebuildTabKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(CapsuleTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _rebuildTabKeys();
    }
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  void _rebuildTabKeys() {
    _tabKeys
      ..clear()
      ..addAll(List.generate(widget.items.length, (_) => GlobalKey()));
  }

  void _scrollToSelected() {
    if (!mounted) return;
    final idx = widget.selectedIndex;
    if (idx < 0 || idx >= _tabKeys.length) return;
    final key = _tabKeys[idx];
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.5,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: IntrinsicWidth(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.items.length, (index) {
                final isSelected = index == widget.selectedIndex;
                final item = widget.items[index];

                return Padding(
                  key: _tabKeys[index],
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onTabSelected(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeInOutCubic,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: isDark
                                      ? const [
                                          Color(0xFF818CF8),
                                          Color(0xFF6366F1),
                                        ]
                                      : const [
                                          Color(0xFF6D28D9),
                                          Color(0xFF7C3AED),
                                        ],
                                )
                              : null,
                          color: isSelected ? null : Colors.transparent,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: (isDark
                                            ? const Color(0xFF6366F1)
                                            : const Color(0xFF6D28D9))
                                        .withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: widget.isDense ? 14 : 18,
                            vertical: widget.isDense ? 8 : 10,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (item.icon != null) ...[
                                Icon(
                                  item.icon,
                                  size: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                          ? AppColors.darkMutedText
                                          : AppColors.lightMutedText),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: widget.isDense ? 13 : 14,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                          ? AppColors.darkMutedText
                                          : AppColors.lightMutedText),
                                ),
                              ),
                              if (item.count != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.25)
                                        : (isDark
                                            ? Colors.white.withValues(alpha: 0.1)
                                            : Colors.black.withValues(alpha: 0.08)),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    item.count!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                              ? AppColors.darkMutedText
                                              : AppColors.lightMutedText),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
