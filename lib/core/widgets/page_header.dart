import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PageHeader extends ConsumerWidget {
  final String eyebrow;
  final String title;
  final String? description;
  final List<Widget>? actions;

  const PageHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.description,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    final headerText = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: AppTextStyles.eyebrow.copyWith(
            color: isDark ? AppColors.darkPrimary : AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: (isMobile ? AppTextStyles.titleXL : AppTextStyles.title2XL)
              .copyWith(
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkMutedText
                  : AppColors.lightMutedText,
            ),
          ),
        ],
      ],
    );

    final hasActions = actions != null && actions!.isNotEmpty;
    final headerActions = hasActions
        ? Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: actions!,
          )
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                headerText,
                if (hasActions) ...[
                  const SizedBox(height: 12),
                  headerActions!,
                ],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: headerText),
                if (hasActions) ...[
                  const SizedBox(width: 12),
                  headerActions!,
                ],
              ],
            ),
    );
  }
}
