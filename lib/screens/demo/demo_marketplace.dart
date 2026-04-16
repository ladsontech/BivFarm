import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/demo_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/product_card.dart';
import '../../utils/constants.dart';
import 'demo_product_detail.dart';
import 'demo_add_product.dart';

class DemoMarketplaceScreen extends StatefulWidget {
  final String userRole;
  final String userId;

  const DemoMarketplaceScreen({super.key, required this.userRole, required this.userId});

  @override
  State<DemoMarketplaceScreen> createState() => _DemoMarketplaceScreenState();
}

class _DemoMarketplaceScreenState extends State<DemoMarketplaceScreen> {
  final _searchCtrl = TextEditingController();
  String? _filterCategory;
  String? _filterAvailability;
  String _sortBy = 'Newest';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ProductModel> get _filteredProducts {
    var filtered = DemoData.products.where((p) {
      final q = _searchCtrl.text.toLowerCase();
      if (q.isNotEmpty) {
        final match = p.productName.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            p.district.toLowerCase().contains(q) ||
            p.sellerName.toLowerCase().contains(q);
        if (!match) return false;
      }
      if (_filterCategory != null && p.category != _filterCategory) return false;
      if (_filterAvailability != null && p.availability != _filterAvailability) return false;
      return true;
    }).toList();

    switch (_sortBy) {
      case 'Lowest price':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Highest price':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      default:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return filtered;
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filters', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                    TextButton(
                      onPressed: () {
                        setState(() { _filterCategory = null; _filterAvailability = null; _sortBy = 'Newest'; });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text('Category', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: AppConstants.productCategories.keys.map((cat) {
                    final selected = _filterCategory == cat;
                    return FilterChip(
                      label: Text(cat),
                      selected: selected,
                      onSelected: (v) { setModalState(() {}); setState(() => _filterCategory = v ? cat : null); },
                      selectedColor: AppTheme.greenSurface,
                      checkmarkColor: AppTheme.greenLight,
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),
                Text('Sort By', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Newest', 'Lowest price', 'Highest price'].map((s) {
                    return ChoiceChip(
                      label: Text(s, style: const TextStyle(fontSize: 12)),
                      selected: _sortBy == s,
                      onSelected: (_) { setModalState(() {}); setState(() => _sortBy = s); },
                      selectedColor: AppTheme.greenSurface,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Apply'))),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search products, categories, districts...',
                      prefixIcon: Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(icon: Icon(Icons.close, color: AppTheme.textMuted, size: 18), onPressed: () { _searchCtrl.clear(); setState(() {}); })
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: _showFilterSheet,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _filterCategory != null ? AppTheme.greenSurface : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _filterCategory != null ? AppTheme.green : AppTheme.border),
                    ),
                    child: Icon(Icons.tune, color: _filterCategory != null ? AppTheme.greenLight : AppTheme.textMuted, size: 20),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined, color: AppTheme.textMuted.withOpacity(0.3), size: 64),
                        SizedBox(height: 16),
                        Text('No products found', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.62, crossAxisSpacing: 12, mainAxisSpacing: 12),
                    itemCount: products.length,
                    itemBuilder: (ctx, i) => ProductCard(
                      product: products[i],
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DemoProductDetail(product: products[i], currentUserId: widget.userId, currentUserRole: widget.userRole))),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: widget.userRole == 'Farmer'
          ? FloatingActionButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DemoAddProduct())), child: const Icon(Icons.add))
          : null,
    );
  }
}
