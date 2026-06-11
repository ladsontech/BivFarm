import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../screens/marketplace/add_product_screen.dart';
import 'network_image_widget.dart';

class AgentFarmerListingsTab extends StatelessWidget {
  final String agentId;
  const AgentFarmerListingsTab({super.key, required this.agentId});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return StreamBuilder<List<ProductModel>>(
      stream: db.streamProductsByAgent(agentId),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.green));
        }
        final products = snap.data ?? [];
        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.textMuted.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text('No listings found for your farmers', style: TextStyle(color: AppTheme.textMuted)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (ctx, i) {
            final p = products[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border, width: 0.5),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: p.imageUrl != null 
                      ? AppNetworkImage(
                          imageUrl: p.imageUrl!, 
                          width: 60, 
                          height: 60, 
                          fit: BoxFit.cover,
                          memCacheWidth: 200,
                        )
                      : Container(width: 60, height: 60, color: AppTheme.surfaceLight, child: const Icon(Icons.inventory_2_outlined)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Seller: ${p.sellerName}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('${p.category} • ${p.district}', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text('UGX ${p.price.toInt()}', style: TextStyle(color: AppTheme.greenLight, fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppTheme.greenLight, size: 20),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddProductScreen(sellerId: p.sellerId, existingProduct: p),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
