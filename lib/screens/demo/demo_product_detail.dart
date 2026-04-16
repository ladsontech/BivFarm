import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/product_model.dart';
import '../../services/demo_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'demo_bid_form.dart';

class DemoProductDetail extends StatelessWidget {
  final ProductModel product;
  final String currentUserId;
  final String currentUserRole;

  const DemoProductDetail({super.key, required this.product, required this.currentUserId, required this.currentUserRole});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final bids = DemoData.bidsForProduct(product.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: AppTheme.background,
            flexibleSpace: FlexibleSpaceBar(
              background: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? (product.imageUrl!.startsWith('http')
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppTheme.surfaceLight,
                            child: Center(child: Icon(_getCategoryIcon(product.category), color: AppTheme.textMuted.withOpacity(0.3), size: 80)),
                          ),
                        )
                      : Image.asset(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppTheme.surfaceLight,
                            child: Center(child: Icon(_getCategoryIcon(product.category), color: AppTheme.textMuted.withOpacity(0.3), size: 80)),
                          ),
                        ))
                  : Container(
                      color: AppTheme.surfaceLight,
                      child: Center(child: Icon(_getCategoryIcon(product.category), color: AppTheme.textMuted.withOpacity(0.3), size: 80)),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.greenSurface, borderRadius: BorderRadius.circular(6)),
                    child: Text(product.category, style: TextStyle(color: AppTheme.greenLight, fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                  SizedBox(height: 12),
                  Text(product.productName, style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
                  SizedBox(height: 8),
                  Text('UGX ${formatter.format(product.price)} / ${product.quantityUnit}', style: TextStyle(color: AppTheme.greenLight, fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  _detailRow(Icons.scale, 'Quantity', '${product.quantity} ${product.quantityUnit}'),
                  _detailRow(Icons.location_on_outlined, 'District', product.district),
                  _detailRow(Icons.schedule, 'Availability', product.availability),
                  _detailRow(Icons.person_outline, 'Seller', product.sellerName),
                  _detailRow(Icons.calendar_today, 'Listed', DateFormat('MMM d, yyyy').format(product.createdAt)),
                  const SizedBox(height: 24),

                  if (bids.isNotEmpty && (currentUserRole == 'Admin' || currentUserRole == 'Registry')) ...[
                    const Divider(),
                    SizedBox(height: 8),
                    Text('Bids (${bids.length})', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 12),
                    ...bids.map((bid) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.border, width: 0.5)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(bid.buyerName, style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                                SizedBox(height: 4),
                                Text('Qty: ${bid.quantity}  •  UGX ${formatter.format(bid.offeredPrice)}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                if (bid.notes != null) Text(bid.notes!, style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ),
                          BidStatusBadge(status: bid.status),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: currentUserRole == 'Buyer'
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DemoBidForm(product: product))),
                  icon: const Icon(Icons.gavel),
                  label: const Text('Place a Bid'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
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
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: AppTheme.textMuted, size: 18)),
          SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            Text(value, style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
          ]),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'Produce': return Icons.grass;
      case 'Poultry & Livestock': return Icons.pets;
      case 'Fruits & Vegetables': return Icons.eco;
      default: return Icons.inventory_2;
    }
  }
}
