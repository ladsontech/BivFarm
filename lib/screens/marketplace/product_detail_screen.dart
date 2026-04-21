import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../models/bid_model.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../bidding/bid_form_screen.dart';
import '../profile/public_profile_screen.dart';
import '../../widgets/product_card.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;
  final String currentUserId;
  final String currentUserRole;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final db = DatabaseService();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Image Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppTheme.background,
            flexibleSpace: FlexibleSpaceBar(
              background: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? (product.imageUrl!.startsWith('assets/')
                      ? Image.asset(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            color: AppTheme.surfaceLight,
                            child: Icon(Icons.broken_image, color: AppTheme.textMuted, size: 48),
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
                            child: Icon(Icons.broken_image, color: AppTheme.textMuted, size: 48),
                          ),
                        ))
                  : Container(
                      color: AppTheme.surfaceLight,
                      child: Icon(Icons.inventory_2, color: AppTheme.textMuted, size: 64),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.greenSurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      product.category,
                      style: const TextStyle(color: AppTheme.greenLight, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Product Name
                  Text(
                    product.productName,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Price
                  Text(
                    'UGX ${formatter.format(product.price)} / ${product.quantityUnit.toLowerCase() == 'pieces' ? 'Piece' : (product.quantityUnit.toLowerCase() == 'crates' ? 'Crate' : product.quantityUnit)}',
                    style: const TextStyle(
                      color: AppTheme.greenLight,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Details
                  _detailRow(Icons.scale, 'Quantity', '${product.quantity} ${product.quantityUnit}'),
                  _detailRow(Icons.location_on_outlined, 'District', product.district),
                  _detailRow(Icons.schedule, 'Availability', product.availability),
                  
                  _detailRow(Icons.calendar_today, 'Listed', DateFormat('MMM d, yyyy').format(product.createdAt)),
                  const SizedBox(height: 32),

                  // About the Farmer UI
                  Text(
                    'About the Farmer',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<UserModel?>(
                    future: db.getUser(product.sellerId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppTheme.green));
                      }
                      final user = snapshot.data;
                      if (user == null) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border, width: 0.5),
                          ),
                          child: Text('Farmer details not found.', style: TextStyle(color: AppTheme.textMuted)),
                        );
                      }
                      
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border, width: 0.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: AppTheme.greenSurface,
                                  backgroundImage: user.profilePhoto != null ? NetworkImage(user.profilePhoto!) : null,
                                  child: user.profilePhoto == null
                                      ? Text(
                                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                          style: const TextStyle(color: AppTheme.greenDark, fontSize: 20, fontWeight: FontWeight.bold),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name.isNotEmpty ? user.name : 'Unknown Farmer',
                                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(color: AppTheme.greenSurface, borderRadius: BorderRadius.circular(4)),
                                            child: Text(user.role, style: const TextStyle(color: AppTheme.greenLight, fontSize: 10, fontWeight: FontWeight.w600)),
                                          ),
                                          if (user.bio != null && user.bio!.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                user.bio!,
                                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // Location Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.location_on_rounded, color: AppTheme.textMuted, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Location', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${user.village.isNotEmpty ? '${user.village}, ' : ''}${user.subcounty.isNotEmpty ? '${user.subcounty}, ' : ''}${user.district}',
                                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            // Admin Only Info
                            if (currentUserRole == 'Admin') ...[
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.admin_panel_settings, color: Colors.orange, size: 16),
                                  const SizedBox(width: 8),
                                  const Text('Admin Only Contact Data', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.phone, color: AppTheme.textMuted, size: 16),
                                  const SizedBox(width: 12),
                                  Text(user.phone.isNotEmpty ? user.phone : 'N/A', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.email, color: AppTheme.textMuted, size: 16),
                                  const SizedBox(width: 12),
                                  Text(user.email.isNotEmpty ? user.email : 'N/A', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.badge, color: AppTheme.textMuted, size: 16),
                                  const SizedBox(width: 12),
                                  Text(user.nin.isNotEmpty ? user.nin : 'N/A', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                                ],
                              ),
                            ] else ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: [
                                    Icon(Icons.privacy_tip_outlined, color: AppTheme.textMuted, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Contact information is hidden for privacy. Place a bid to negotiate.',
                                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Bids section (admin view only)
                  if (currentUserRole == 'Admin' || currentUserRole == 'Registry') ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Bids on this product',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<List<BidModel>>(
                      stream: db.streamBidsByProduct(product.id),
                      builder: (ctx, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: AppTheme.green));
                        }
                        final bids = snap.data ?? [];
                        if (bids.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: Text('No bids yet', style: TextStyle(color: AppTheme.textMuted))),
                          );
                        }
                        return Column(
                          children: bids.map((bid) => _bidTile(bid, formatter)).toList(),
                        );
                      },
                    ),
                  ],
                  
                  const SizedBox(height: 40),
                  
                  // More Products from this Farmer
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'More products from ${product.sellerName.isNotEmpty ? product.sellerName.split(' ').first : "this farmer"}',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<List<ProductModel>>(
                    stream: db.streamProductsBySeller(product.sellerId),
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 100,
                          child: Center(child: CircularProgressIndicator(color: AppTheme.green)),
                        );
                      }
                      // Filter out only the current product (isActive is handled in the stream)
                      final otherProducts = (snap.data ?? []).where((p) => p.id != product.id).toList();
                      
                      if (otherProducts.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No other products available.',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                            ),
                          ),
                        );
                      }
                      
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.6, // Further increased height (was 0.65) to eliminate remaining 7.6px overflow
                        ),
                        itemCount: otherProducts.length,
                        itemBuilder: (ctx, i) {
                          final p = otherProducts[i];
                          return ProductCard(
                            product: p,
                            onTap: () {
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(
                                product: p,
                                currentUserId: currentUserId,
                                currentUserRole: currentUserRole,
                              )));
                            },
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: (currentUserRole == 'Buyer' || currentUserRole == 'Farmer' || currentUserRole == 'Admin') && currentUserId != product.sellerId
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BidFormScreen(product: product, buyerId: currentUserId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.gavel),
                  label: const Text('Place a Bid'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.textMuted, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              Text(value, style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bidTile(BidModel bid, NumberFormat formatter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (bid.buyerName.isNotEmpty ? bid.buyerName : 'Buyer') + (bid.buyerPhone.isNotEmpty ? ' • ${bid.buyerPhone}' : ''),
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${bid.quantity}  •  UGX ${formatter.format(bid.offeredPrice)}',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                if (bid.notes != null && bid.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(bid.notes!, style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ],
              ],
            ),
          ),
          BidStatusBadge(status: bid.status),
        ],
      ),
    );
  }
}
