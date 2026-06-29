import 'package:flutter/material.dart';
import '../../models/bulk_order_model.dart';
import '../../models/product_model.dart';
import '../../models/bid_model.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../utils/constants.dart';

class BulkFulfillmentScreen extends StatefulWidget {
  final BulkOrderModel order;
  const BulkFulfillmentScreen({super.key, required this.order});

  @override
  State<BulkFulfillmentScreen> createState() => _BulkFulfillmentScreenState();
}

class _BulkFulfillmentScreenState extends State<BulkFulfillmentScreen> {
  final _db = DatabaseService();
  String _searchQuery = '';
  String? _selectedDistrict;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fulfill Bulk Order')),
      body: ResponsiveWrapper(
        maxWidth: 800,
        child: Column(
          children: [
            // Bulk Order Summary Banner
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.surfaceLight,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: AppTheme.greenSurface,
                        borderRadius: BorderRadius.circular(10)),
                    child:
                        const Icon(Icons.call_split, color: AppTheme.greenDark),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Target: ${widget.order.quantity} ${widget.order.quantityUnit}',
                            style: TextStyle(
                                color: AppTheme.green,
                                fontSize: 16,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(
                            '${widget.order.itemName} (${widget.order.category})',
                            style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Filters Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search farmer, group or product...',
                      prefixIcon: const Icon(Icons.search),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      filled: true,
                      fillColor: AppTheme.card,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedDistrict,
                        hint: const Text('All Districts'),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All Districts')),
                          ...AppConstants.bunyoroDistricts.map((d) =>
                              DropdownMenuItem(value: d, child: Text(d))),
                        ],
                        onChanged: (v) => setState(() => _selectedDistrict = v),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<List<ProductModel>>(
                stream: _db.streamProducts(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child:
                            CircularProgressIndicator(color: AppTheme.green));
                  }

                  // Filter matching products
                  final allProducts = snap.data ?? [];

                  // Primary Filter: Category
                  var filtered = allProducts
                      .where((p) => p.category == widget.order.category)
                      .toList();

                  // Secondary Filter: Search Query
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    filtered = filtered
                        .where((p) =>
                            p.productName.toLowerCase().contains(q) ||
                            p.sellerName.toLowerCase().contains(q) ||
                            p.district.toLowerCase().contains(q))
                        .toList();
                  }

                  // Tertiary Filter: District
                  if (_selectedDistrict != null) {
                    filtered = filtered
                        .where((p) => p.district == _selectedDistrict)
                        .toList();
                  }

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              color: AppTheme.textMuted.withOpacity(0.3),
                              size: 64),
                          const SizedBox(height: 16),
                          Text(
                              _searchQuery.isNotEmpty ||
                                      _selectedDistrict != null
                                  ? 'No results found for your filters'
                                  : 'No farmers currently have ${widget.order.category}',
                              style: TextStyle(
                                  color: AppTheme.textMuted, fontSize: 16)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final p = filtered[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppTheme.border, width: 0.5),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.productName,
                                        style: TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text('Farmer: ${p.sellerName}',
                                        style: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 13)),
                                    const SizedBox(height: 2),
                                    Text(
                                        'Stock: ${p.quantity} ${p.quantityUnit}',
                                        style: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => _showRequestDialog(p),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.greenLight,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Request Supply'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRequestDialog(ProductModel product) {
    final qtyCtrl =
        TextEditingController(text: widget.order.quantity.toString());
    final priceCtrl = TextEditingController(text: product.price.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Request from ${product.sellerName.split(' ')[0]}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'You are creating a split sub-request for the bulk order. The farmer will receive a standard bid notification from the Administrator.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            CustomTextField(
                label: 'Requested Quantity (${product.quantityUnit})',
                controller: qtyCtrl,
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            CustomTextField(
                label: 'Offered Price (UGX)',
                controller: priceCtrl,
                keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final q = double.tryParse(qtyCtrl.text.trim()) ?? 0;
              final p = double.tryParse(priceCtrl.text.trim()) ?? 0;
              if (q <= 0 || p <= 0) return;

              Navigator.pop(ctx);

              try {
                // Create a standard bid acting on behalf of the Registry
                final bid = BidModel(
                  id: '',
                  productId: product.id,
                  productName: product.productName,
                  sellerId: product.sellerId,
                  sellerName: product.sellerName,
                  sellerPhone:
                      'Registered Farmer', // Fallback, not stored on ProductModel
                  buyerId: widget
                      .order.buyerId, // The person who requested the bulk order
                  buyerName:
                      'Registry (Bulk Request)', // Mask the original buyer name
                  buyerPhone: 'Via Admin',
                  quantity: q,
                  offeredPrice: p,
                  status: 'Pending',
                  notes:
                      'Bulk fulfillment sub-request for Master Order #${widget.order.id.substring(0, 4)}',
                );

                await _db.addBid(bid);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content:
                          Text('Supply requested to farmer successfully!')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }
}
