import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/product_model.dart';
import '../../models/bid_model.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../bidding/bid_form_screen.dart';

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
                      : Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
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
                      style: TextStyle(color: AppTheme.greenLight, fontSize: 12, fontWeight: FontWeight.w500),
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
                    style: TextStyle(
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
                  _detailRow(Icons.person_outline, 'Seller', product.sellerName.isNotEmpty ? product.sellerName : 'Farmer'),
                  _detailRow(Icons.calendar_today, 'Listed', DateFormat('MMM d, yyyy').format(product.createdAt)),
                  const SizedBox(height: 24),

                  // Bids section (admin view only)
                  if (currentUserRole == 'Admin' || currentUserRole == 'Registry') ...[
                    const Divider(),
                    SizedBox(height: 8),
                    Text(
                      'Bids on this product',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 12),
                    StreamBuilder<List<BidModel>>(
                      stream: db.streamBidsByProduct(product.id),
                      builder: (ctx, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator(color: AppTheme.green));
                        }
                        final bids = snap.data ?? [];
                        if (bids.isEmpty) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: Text('No bids yet', style: TextStyle(color: AppTheme.textMuted))),
                          );
                        }
                        return Column(
                          children: bids.map((bid) => _bidTile(bid, formatter)).toList(),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: (currentUserRole == 'Buyer' || currentUserRole == 'Admin') && currentUserId != product.sellerId
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
          SizedBox(width: 12),
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
                SizedBox(height: 4),
                Text(
                  'Qty: ${bid.quantity}  •  UGX ${formatter.format(bid.offeredPrice)}',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                if (bid.notes != null && bid.notes!.isNotEmpty) ...[
                  SizedBox(height: 4),
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
