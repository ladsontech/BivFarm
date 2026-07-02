import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';
import '../widgets/network_image_widget.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final bool compact; // minimal card: image + name + price only

  const ProductCard(
      {super.key, required this.product, this.onTap, this.compact = false});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final bool isAvailableNow = widget.product.availability == 'Available Now';

    // ── Compact card (category page): image + name + price only ──
    if (widget.compact) {
      return GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: AppTheme.border.withValues(alpha: 0.35), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 1.1,
                  child: _buildImage(),
                ),
              ),
              // Name + Price
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.product.productName,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'UGX ${formatter.format(widget.product.price.toInt())} / ${_fullUnitLabel(widget.product.quantityUnit)}',
                      style: const TextStyle(
                        color: AppTheme.greenLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                        ),
                    const SizedBox(height: 2),
                    Text(
                      widget.product.district,
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Standard card (home/marketplace) ──────────────────────────
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.4), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Image with status badge ──────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: AspectRatio(
                    aspectRatio: 1.15,
                    child: _buildImage(),
                  ),
                ),
                // Availability badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAvailableNow
                          ? AppTheme.green.withValues(alpha: 0.9)
                          : Colors.orange.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isAvailableNow ? 'IN STOCK' : 'SOON',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Info section ──
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category label
                  Text(
                    widget.product.category.toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.green.withValues(alpha: 0.8),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  // Product name
                  Text(
                    widget.product.productName,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Price
                  Text(
                    'UGX ${formatter.format(widget.product.price.toInt())} / ${_fullUnitLabel(widget.product.quantityUnit)}',
                    style: const TextStyle(
                      color: AppTheme.greenLight,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: AppTheme.textMuted, size: 10),
                      const SizedBox(width: 4),
                      Text(
                        widget.product.district,
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final url = widget.product.imageUrl; // uses first image from imageUrls
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('assets/')) {
        return Image.asset(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      }
      return AppNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: _placeholder(loading: true),
        errorWidget: _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder({bool loading = false}) {
    return Container(
      color: AppTheme.surfaceLight,
      child: Center(
        child: loading
            ? const CircularProgressIndicator(
                color: AppTheme.green, strokeWidth: 2)
            : Icon(_getCategoryIcon(widget.product.category),
                color: AppTheme.textMuted.withValues(alpha: 0.4), size: 38),
      ),
    );
  }

  String _fullUnitLabel(String unit) {
    final u = unit.toLowerCase();
    if (u == 'pieces') return 'Piece';
    if (u == 'crates') return 'Crate';
    if (u == 'bags') return 'Bag';
    if (u == 'bunches') return 'Bunch';
    if (u == 'trays') return 'Tray';
    if (u == 'litres') return 'Litre';
    if (u == 'tonnes') return 'Tonne';
    if (u == 'kilograms') return 'Kg';
    if (u.endsWith('s')) return u.substring(0, u.length - 1);
    return u;
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Produce':
        return Icons.grass;
      case 'Poultry':
      case 'Poultry & Livestock':
        return Icons.egg_outlined;
      case 'Livestock':
        return Icons.pets;
      case 'Fruits & Vegetables':
        return Icons.eco;
      case 'Farm Machinery':
        return Icons.agriculture;
      case 'Fertilizers & Pesticides':
        return Icons.science_outlined;
      default:
        return Icons.inventory_2;
    }
  }
}
