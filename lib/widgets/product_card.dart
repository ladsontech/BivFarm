import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/network_image_widget.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late Future<UserModel?> _sellerFuture;

  @override
  void initState() {
    super.initState();
    // Cache the future so it doesn't refetch on every scroll/rebuild
    _sellerFuture = DatabaseService().getUser(widget.product.sellerId);
  }

  @override
  void didUpdateWidget(ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.sellerId != widget.product.sellerId) {
      _sellerFuture = DatabaseService().getUser(widget.product.sellerId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final bool isAvailableNow = widget.product.availability == 'Available Now';

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(AppTheme.isDark ? 0.3 : 0.07),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Clean Image Section ──────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 1.35, // Slightly wider to give text more room
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Product image
                    _buildImage(),
                    // Top gradient for badges to be visible
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.3],
                            colors: [
                              Colors.black.withOpacity(0.4),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Availability dot (top-right)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isAvailableNow ? AppTheme.greenAccent : AppTheme.warning,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isAvailableNow ? 'Now' : 'Soon',
                              style: TextStyle(
                                color: isAvailableNow ? AppTheme.greenAccent : AppTheme.warning,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Category badge (top-left)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.product.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    // Image count badge (bottom-right)
                    if (widget.product.imageUrls.length > 1)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.photo_library, color: Colors.white, size: 10),
                              const SizedBox(width: 3),
                              Text(
                                '${widget.product.imageUrls.length}',
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Info Section (Below Image) ───────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name & Quantity
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.product.productName,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatQty(widget.product.quantity)} ${_unitLabel(widget.product.quantityUnit)}',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Price row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'UGX ${formatter.format(widget.product.price.toInt())}',
                              style: const TextStyle(
                                color: AppTheme.greenLight,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Real Farmer Information
                    FutureBuilder<UserModel?>(
                      future: _sellerFuture,
                      builder: (context, snapshot) {
                        final user = snapshot.data;
                        final name = _getActualName(user);
                        
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildSellerAvatar(user),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 9, color: AppTheme.textMuted),
                                      const SizedBox(width: 2),
                                      Expanded(
                                        child: Text(
                                          widget.product.district,
                                          style: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 9,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
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

  String _getActualName(UserModel? user) {
    if (user != null && user.firstName.isNotEmpty) {
      return user.firstName;
    }
    if (user != null && user.name.isNotEmpty) {
      return user.name.split(' ').first;
    }
    final dbName = widget.product.sellerName.trim();
    return dbName.isNotEmpty && dbName.toLowerCase() != 'farmer' ? dbName : 'Farmer';
  }

  String _initial(UserModel? user) {
    final name = _getActualName(user);
    if (name.isNotEmpty && name.toLowerCase() != 'farmer') return name[0].toUpperCase();
    return 'F';
  }

  Color _avatarColor(UserModel? user) {
    const colors = [
      Color(0xFF2E7D32), // green
      Color(0xFF1565C0), // blue
      Color(0xFF6A1B9A), // purple
      Color(0xFFE65100), // orange
      Color(0xFF00695C), // teal
      Color(0xFFC62828), // red
      Color(0xFF4527A0), // deep-purple
      Color(0xFF283593), // indigo
    ];
    final code = _initial(user).codeUnitAt(0);
    return colors[code % colors.length];
  }

  Widget _buildSellerAvatar(UserModel? user) {
    final photo = user?.profilePhoto ?? widget.product.sellerPhoto;
    if (photo != null && photo.isNotEmpty) {
      return ClipOval(
        child: AppNetworkImage(
          imageUrl: photo,
          width: 24,
          height: 24,
          fit: BoxFit.cover,
          placeholder: _defaultAvatar(user),
          errorWidget: _defaultAvatar(user),
        ),
      );
    }
    return _defaultAvatar(user);
  }

  Widget _defaultAvatar(UserModel? user) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: _avatarColor(user),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initial(user),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
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
            ? const CircularProgressIndicator(color: AppTheme.green, strokeWidth: 2)
            : Icon(_getCategoryIcon(widget.product.category), color: AppTheme.textMuted.withOpacity(0.4), size: 38),
      ),
    );
  }

  String _unitLabel(String unit) {
    final u = unit.toLowerCase();
    if (u == 'pieces') return 'pc';
    if (u == 'crates') return 'crate';
    if (u == 'bags') return 'bag';
    if (u == 'bunches') return 'bunch';
    if (u == 'trays') return 'tray';
    if (u == 'litres') return 'L';
    if (u == 'tonnes') return 'T';
    if (u == 'kilograms') return 'kg';
    return u;
  }

  String _formatQty(double qty) {
    if (qty == qty.truncate()) return qty.toInt().toString();
    return qty.toStringAsFixed(1);
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
