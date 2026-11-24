import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/product_thumbnail.dart';
import '../../../data/firestore/models/product_model.dart';

class PosProductPhoto extends StatelessWidget {
  const PosProductPhoto({
    super.key,
    required this.product,
    required this.size,
    this.radius = 12,
  });
  final ProductModel product;
  final double size, radius;
  @override
  Widget build(BuildContext context) => ProductThumbnail(
    imageUrl: product.imageUrl,
    productId: product.id,
    productName: product.name,
    barcode: product.barcode,
    width: size,
    height: size,
    borderRadius: radius,
  );
}

class PosProductCard extends StatelessWidget {
  const PosProductCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.onAdd,
  });
  final ProductModel product;
  final int quantity;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final stockColor = product.isOutOfStock
        ? colors.error
        : product.isLowStock
        ? AppColors.warning
        : theme.brightness == Brightness.dark
        ? AppColors.darkSuccess
        : AppColors.success;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: colors.surface,
        border: Border.all(
          color: quantity > 0
              ? colors.primary
              : theme.dividerTheme.color ?? colors.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onAdd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Opacity(
                      opacity: product.isOutOfStock ? .48 : 1,
                      child: PosProductPhoto(
                        product: product,
                        size: double.infinity,
                        radius: 0,
                      ),
                    ),
                    if (quantity > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              '$quantity in cart',
                              style: TextStyle(
                                color: colors.onPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.circle, color: stockColor, size: 6),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              product.isOutOfStock
                                  ? 'អស់ពីស្តុក'
                                  : '${product.stockQty} ${product.unit}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  MoneyUtils.formatRiel(product.salePrice),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  MoneyUtils.formatUSD(
                                    MoneyUtils.rielToUsd(product.salePrice),
                                  ),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            tooltip: 'Add ${product.name}',
                            iconSize: 18,
                            onPressed: onAdd,
                            constraints: const BoxConstraints.tightFor(
                              width: 36,
                              height: 36,
                            ),
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
