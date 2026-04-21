import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../screens/marketplace/add_product_screen.dart';

class MyListingsTab extends StatelessWidget {
  final String userId;
  const MyListingsTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return StreamBuilder<List<ProductModel>>(
      stream: db.streamProductsBySeller(userId),
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
                Text('You haven\'t uploaded any products yet', style: TextStyle(color: AppTheme.textMuted)),
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
                      ? Image.network(p.imageUrl!, width: 60, height: 60, fit: BoxFit.cover)
                      : Container(width: 60, height: 60, color: AppTheme.surfaceLight, child: const Icon(Icons.image_not_supported)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('${p.category} • ${p.district}', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('UGX ${p.price.toInt()}', style: const TextStyle(color: AppTheme.greenLight, fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppTheme.greenLight, size: 20),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddProductScreen(sellerId: userId, existingProduct: p),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                        onPressed: () => _confirmDelete(context, db, p),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, DatabaseService db, ProductModel p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Listing?'),
        content: Text('Are you sure you want to delete "${p.productName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await db.deleteProduct(p.id);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}
