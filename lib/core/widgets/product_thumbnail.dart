import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable product thumbnail with support for bundled assets, network images,
/// base64 data URIs, and intelligent product photo mapping.
class ProductThumbnail extends StatelessWidget {
  final String? imageUrl;
  final String? productId;
  final String? productName;
  final String? barcode;
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
    this.productId,
    this.productName,
    this.barcode,
    this.width = 44,
    this.height = 44,
    this.borderRadius = 8,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.inventory_2_outlined,
    this.fallbackColor,
    this.backgroundColor,
  });

  /// Automatically map known mini-mart products to their local high-res photo assets
  static String? getAssetForProduct({
    String? id,
    String? name,
    String? url,
    String? barcode,
  }) {
    final cleanId = id?.toLowerCase() ?? '';
    final cleanName = name?.toLowerCase() ?? '';
    final cleanUrl = url?.toLowerCase() ?? '';
    final cleanBarcode = barcode?.trim() ?? '';

    if (cleanUrl.startsWith('assets/')) return url;

    // Coca Cola 330ml
    if (cleanId == 'p1' ||
        cleanBarcode == '884000101' ||
        cleanName.contains('coca') ||
        cleanName.contains('cola') ||
        cleanName.contains('កូកា') ||
        cleanUrl.contains('coca')) {
      return 'assets/products/coca_cola.jpg';
    }
    // Sting Strawberry
    if (cleanId == 'p2' ||
        cleanBarcode == '884000102' ||
        cleanName.contains('sting') ||
        cleanName.contains('ស្តីង') ||
        cleanUrl.contains('sting')) {
      return 'assets/products/sting_energy.jpg';
    }
    // Red Bull
    if (cleanId == 'p3' ||
        cleanBarcode == '884000103' ||
        cleanName.contains('red bull') ||
        cleanName.contains('redbull') ||
        cleanName.contains('bull') ||
        cleanName.contains('ប៊ូល') ||
        cleanUrl.contains('redbull')) {
      return 'assets/products/red_bull.jpg';
    }
    // Angkor Puro / Mineral Water
    if (cleanId == 'p4' ||
        cleanBarcode == '884000104' ||
        cleanName.contains('water') ||
        cleanName.contains('angkor') ||
        cleanName.contains('puro') ||
        cleanName.contains('ទឹក') ||
        cleanUrl.contains('water')) {
      return 'assets/products/angkor_water.jpg';
    }
    // MAMA Noodles Tom Yum
    if (cleanId == 'p5' ||
        cleanBarcode == '884000201' ||
        cleanName.contains('mama') ||
        cleanName.contains('noodle') ||
        cleanName.contains('មី') ||
        cleanUrl.contains('noodle')) {
      return 'assets/products/mama_noodles.jpg';
    }
    // Oreo Cookies
    if (cleanId == 'p6' ||
        cleanBarcode == '884000202' ||
        cleanName.contains('oreo') ||
        cleanName.contains('biscuit') ||
        cleanName.contains('cookie') ||
        cleanName.contains('អូរីអូ') ||
        cleanUrl.contains('oreo')) {
      return 'assets/products/oreo_cookies.jpg';
    }
    // Colgate Toothpaste
    if (cleanId == 'p7' ||
        cleanBarcode == '884000301' ||
        cleanName.contains('colgate') ||
        cleanName.contains('toothpaste') ||
        cleanName.contains('ថ្នាំដុសធ្មេញ') ||
        cleanName.contains('កុលហ្គេត') ||
        cleanUrl.contains('colgate')) {
      return 'assets/products/colgate_toothpaste.jpg';
    }
    // Lifebuoy Soap
    if (cleanId == 'p8' ||
        cleanBarcode == '884000302' ||
        cleanName.contains('lifebuoy') ||
        cleanName.contains('soap') ||
        cleanName.contains('សាប៊ូ') ||
        cleanName.contains('ឡៃហ្វ') ||
        cleanUrl.contains('soap')) {
      return 'assets/products/lifebuoy_soap.jpg';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Resolve source image
    String? rawUrl = (imageUrl != null && imageUrl!.trim().isNotEmpty)
        ? imageUrl!.trim()
        : null;

    final localAsset = getAssetForProduct(
      id: productId,
      name: productName,
      url: rawUrl,
      barcode: barcode,
    );

    // Prioritize:
    // 1) Custom base64 photo uploaded by user (data:image)
    // 2) High-res bundled local asset (assets/products/*.jpg) to prevent web CORS issues
    // 3) Fallback to rawUrl
    final String? effectiveSource;
    if (rawUrl != null && rawUrl.startsWith('data:image')) {
      effectiveSource = rawUrl;
    } else if (localAsset != null) {
      effectiveSource = localAsset;
    } else {
      effectiveSource = rawUrl;
    }

    final effectiveBg = backgroundColor ??
        (isDark
            ? AppColors.darkCard
            : Colors.white);
    final effectiveIconColor = fallbackColor ??
        (isDark ? AppColors.darkPrimary : AppColors.primary);

    Widget fallbackWidget() {
      // If we have a local asset fallback, use it even if network image failed
      if (localAsset != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            width: width,
            height: height,
            color: effectiveBg,
            child: Image.asset(
              localAsset,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (_, _, _) => _buildStyledInitialsCard(isDark, effectiveBg, effectiveIconColor),
            ),
          ),
        );
      }
      return _buildStyledInitialsCard(isDark, effectiveBg, effectiveIconColor);
    }

    if (effectiveSource == null || effectiveSource.isEmpty) {
      return fallbackWidget();
    }

    // A. Local Asset Image
    if (effectiveSource.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          width: width,
          height: height,
          color: effectiveBg,
          child: Image.asset(
            effectiveSource,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, _, _) => fallbackWidget(),
          ),
        ),
      );
    }

    // B. Base64 Data URI Image
    if (effectiveSource.startsWith('data:image')) {
      try {
        final commaIdx = effectiveSource.indexOf(',');
        final base64Str = commaIdx >= 0 ? effectiveSource.substring(commaIdx + 1) : effectiveSource;
        final bytes = base64Decode(base64Str.trim());
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            width: width,
            height: height,
            color: effectiveBg,
            child: Image.memory(
              bytes,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (_, _, _) => fallbackWidget(),
            ),
          ),
        );
      } catch (_) {
        return fallbackWidget();
      }
    }

    // C. Network Image (with asset fallback on error)
    if (effectiveSource.startsWith('http://') || effectiveSource.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          width: width,
          height: height,
          color: effectiveBg,
          child: Image.network(
            effectiveSource,
            width: width,
            height: height,
            fit: fit,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Center(
                child: SizedBox(
                  width: (width * 0.35).clamp(14.0, 24.0),
                  height: (width * 0.35).clamp(14.0, 24.0),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
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

    return fallbackWidget();
  }

  Widget _buildStyledInitialsCard(bool isDark, Color bg, Color iconColor) {
    final initials = (productName != null && productName!.trim().isNotEmpty)
        ? productName!.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '';

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.darkSurface, AppColors.darkCard]
              : [AppColors.primary.withValues(alpha: 0.08), AppColors.secondary.withValues(alpha: 0.12)],
        ),
      ),
      child: Center(
        child: initials.isNotEmpty
            ? Text(
                initials,
                style: TextStyle(
                  fontSize: (width * 0.36).clamp(11.0, 22.0),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: iconColor,
                ),
              )
            : Icon(
                fallbackIcon,
                color: iconColor,
                size: (width * 0.48).clamp(16.0, 32.0),
              ),
      ),
    );
  }
}
