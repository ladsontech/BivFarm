import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 1.2,
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? (product.imageUrl!.startsWith('assets/')
                        ? Image.asset(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              color: AppTheme.surfaceLight,
                              child: Center(
                                child: Icon(Icons.broken_image, color: AppTheme.textMuted, size: 32),
                              ),
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: product.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppTheme.surfaceLight,
                              child: const Center(child: CircularProgressIndicator(color: AppTheme.green, strokeWidth: 2)),
                            ),
                            errorWidget: (context, url, err) => Container(
                              color: AppTheme.surfaceLight,
                              child: Center(
                                child: Icon(Icons.broken_image, color: AppTheme.textMuted, size: 32),
                              ),
                            ),
                          ))
                    : Container(
                        color: AppTheme.surfaceLight,
                        child: Center(
                          child: Icon(
                            _getCategoryIcon(product.category),
                            color: AppTheme.textMuted,
                            size: 40,
                          ),
                        ),
                      ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productName,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      product.category,
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'UGX ${formatter.format(product.price)} / ${product.quantityUnit.toLowerCase() == 'pieces' ? 'Piece' : (product.quantityUnit.toLowerCase() == 'crates' ? 'Crate' : product.quantityUnit)}',
                        style: const TextStyle(
                          color: AppTheme.greenLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 8, color: AppTheme.textMuted),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                product.district,
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 8),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 8, color: AppTheme.textMuted),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                product.sellerName.isNotEmpty ? product.sellerName : 'Farmer',
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 8),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: product.availability == 'Available Now'
                            ? AppTheme.greenSurface
                            : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.availability,
                        style: TextStyle(
                          color: product.availability == 'Available Now'
                              ? AppTheme.greenLight
                              : AppTheme.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Produce':
        return Icons.grass;
      case 'Poultry & Livestock':
        return Icons.pets;
      case 'Fruits & Vegetables':
        return Icons.eco;
      default:
        return Icons.inventory_2;
    }
  }
}
