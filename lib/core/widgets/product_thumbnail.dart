import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable product thumbnail with graceful network image loading & fallback icon
class ProductThumbnail extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;
  final IconData fallbackIcon;
  final Color? fallbackColor;
  final Color? backgroundColor;

  const ProductThumbnail({
    super.key,
    required this.imageUrl,
    this.width = 44,
    this.height = 44,
    this.borderRadius = 8,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.inventory_2_outlined,
    this.fallbackColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasValidUrl = imageUrl != null &&
        imageUrl!.trim().isNotEmpty &&
        (imageUrl!.trim().startsWith('http://') ||
            imageUrl!.trim().startsWith('https://') ||
            imageUrl!.trim().startsWith('data:image'));

    final effectiveBg = backgroundColor ??
        (isDark
            ? AppColors.darkCard
            : AppColors.primary.withValues(alpha: 0.08));
    final effectiveIconColor = fallbackColor ??
        (isDark ? AppColors.darkPrimary : AppColors.primary);

    Widget fallbackWidget() {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Center(
          child: Icon(
            fallbackIcon,
            color: effectiveIconColor,
            size: (width * 0.52).clamp(16.0, 32.0),
          ),
        ),
      );
    }

    if (!hasValidUrl) {
      return fallbackWidget();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        color: effectiveBg,
        child: Image.network(
          imageUrl!.trim(),
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return fallbackWidget();
          },
        ),
      ),
    );
  }
}
