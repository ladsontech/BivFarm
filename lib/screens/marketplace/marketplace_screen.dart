import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/product_card.dart';
import '../../utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'product_detail_screen.dart';
import 'add_product_screen.dart';
import '../orders/bulk_order_form_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  final String userRole;
  final String userId;

  const MarketplaceScreen({super.key, required this.userRole, required this.userId});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _db = DatabaseService();
  final _searchCtrl = TextEditingController();
  String? _filterCategory;
  String? _filterSubCategory;
  String? _filterDistrict;
  String? _filterAvailability;
  String _sortBy = 'Newest';

  late PageController _carouselPageCtrl;
  Timer? _carouselTimer;
  int _carouselIndex = 0;

  final List<Map<String, String>> _carouselItems = [
    {
      'image': 'assets/images/carousel/farm_produce.jpg',
      'title': 'Fresh Farm Produce',
      'desc': 'Direct from Bunyoro local farmers to your doorstep'
    },
    {
      'image': 'assets/images/carousel/livestock.jpg',
      'title': 'Quality Livestock',
      'desc': 'Healthy cattle, poultry, and fish for your needs'
    },
    {
      'image': 'assets/images/carousel/fruits.jpg',
      'title': 'Organic Fruits',
      'desc': 'Naturally grown fruits and vegetables'
    },
    {
      'image': 'assets/images/carousel/farm_machinery.jpg',
      'title': 'Farm Machinery',
      'desc': 'Modern tools and equipment to boost productivity'
    },
    {
      'image': 'assets/images/carousel/firm_chemicals.jpg',
      'title': 'Farm Inputs',
      'desc': 'Quality seeds, fertilizers, and pesticides'
    },
  ];

  @override
  void initState() {
    super.initState();
    _carouselPageCtrl = PageController(initialPage: 0);
    _startCarousel();
  }

  void _startCarousel() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_carouselPageCtrl.hasClients) {
        _carouselIndex = (_carouselIndex + 1) % _carouselItems.length;
        _carouselPageCtrl.animateToPage(
          _carouselIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _carouselPageCtrl.dispose();
    _carouselTimer?.cancel();
    super.dispose();
  }

  List<ProductModel> _applyFilters(List<ProductModel> products) {
    var filtered = products.where((p) {
      final query = _searchCtrl.text.toLowerCase();
      if (query.isNotEmpty) {
        final match = p.productName.toLowerCase().contains(query) ||
            p.category.toLowerCase().contains(query) ||
            p.district.toLowerCase().contains(query) ||
            p.sellerName.toLowerCase().contains(query);
        if (!match) return false;
      }
      if (_filterCategory != null) {
        bool match = p.category == _filterCategory;
        // Handle split categories backward compatibility
        if (!match && p.category == 'Poultry & Livestock') {
          if (_filterCategory == 'Poultry' || _filterCategory == 'Livestock') match = true;
        }
        if (!match) return false;
      }
      if (_filterSubCategory != null && !p.productName.toLowerCase().contains(_filterSubCategory!.toLowerCase())) return false;
      if (_filterDistrict != null && p.district != _filterDistrict) return false;
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

  void applyExternalFilter(String? category) {
    setState(() {
      _searchCtrl.clear(); // Clear search query when a specific category is selected
      _filterCategory = category;
      _filterSubCategory = null;
    });
  }

  String _getCategoryImage(String category) {
    switch (category) {
      case 'Produce':
        return 'assets/images/categories/farm_produce.jpg';
      case 'Poultry':
        return 'assets/images/categories/poultry_products.jpg';
      case 'Livestock':
        return 'assets/images/categories/livestock.jpg';
      case 'Fruits & Vegetables':
        return 'assets/images/categories/fruits_and_vegetables.jpg';
      case 'Farm Machinery':
        return 'assets/images/categories/farm_machinery.jpg';
      case 'Fertilizers & Pesticides':
        return 'assets/images/carousel/firm_chemicals.jpg';
      default:
        return 'assets/images/categories/farm_produce.jpg';
    }
  }

  IconData _getSubCategoryIcon(String sub) {
    final s = sub.toLowerCase();
    if (s.contains('maize') || s.contains('grain')) return Icons.grass;
    if (s.contains('bean') || s.contains('soy')) return Icons.eco_outlined;
    if (s.contains('fruit') || s.contains('mango') || s.contains('pineapple')) return Icons.apple;
    if (s.contains('vege') || s.contains('tomato') || s.contains('onion')) return Icons.restaurant_menu;
    if (s.contains('poul') || s.contains('chicken')) return Icons.pets;
    if (s.contains('livestock') || s.contains('cattle') || s.contains('goat')) return Icons.agriculture_outlined;
    if (s.contains('coffee') || s.contains('cocoa')) return Icons.local_cafe;
    return Icons.inventory_2_outlined;
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: StatefulBuilder(
                builder: (ctx, setModalState) {
                  return Column(
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Filters', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _filterCategory = null;
                                        _filterSubCategory = null;
                                        _filterDistrict = null;
                                        _filterAvailability = null;
                                        _sortBy = 'Newest';
                                      });
                                      Navigator.pop(ctx);
                                    },
                                    child: const Text('Clear All'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text('Category', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                              const SizedBox(height: 8),
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 2.2,
                                children: AppConstants.productCategories.keys.map((cat) {
                                  final selected = _filterCategory == cat;
                                  final imagePath = _getCategoryImage(cat);
                                  return GestureDetector(
                                    onTap: () {
                                      setModalState(() {});
                                      if (selected) {
                                        setState(() {
                                          _filterCategory = null;
                                          _filterSubCategory = null;
                                        });
                                      } else {
                                        setState(() {
                                          _filterCategory = cat;
                                          _filterSubCategory = null;
                                        });
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: selected ? AppTheme.green : Colors.transparent,
                                          width: 2,
                                        ),
                                        image: DecorationImage(
                                          image: AssetImage(imagePath),
                                          fit: BoxFit.cover,
                                          colorFilter: ColorFilter.mode(
                                            Colors.black.withOpacity(selected ? 0.4 : 0.6),
                                            BlendMode.srcOver,
                                          ),
                                        ),
                                        boxShadow: selected ? [BoxShadow(color: AppTheme.green.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)] : null,
                                      ),
                                      child: Stack(
                                        children: [
                                          Center(
                                            child: Text(
                                              cat,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ),
                                          if (selected)
                                            const Positioned(
                                              top: 4,
                                              right: 4,
                                              child: CircleAvatar(
                                                radius: 10,
                                                backgroundColor: AppTheme.green,
                                                child: Icon(Icons.check, size: 12, color: Colors.white),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              
                              if (_filterCategory != null) ...[
                                const SizedBox(height: 16),
                                Text('Popular in $_filterCategory', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: AppConstants.productCategories[_filterCategory]!.take(8).map((sub) {
                                    final subSelected = _filterSubCategory == sub;
                                    return ChoiceChip(
                                      label: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(_getSubCategoryIcon(sub), size: 14, color: subSelected ? Colors.white : AppTheme.textMuted),
                                          const SizedBox(width: 4),
                                          Text(sub, style: TextStyle(fontSize: 12, color: subSelected ? Colors.white : AppTheme.textPrimary)),
                                        ],
                                      ),
                                      selected: subSelected,
                                      onSelected: (v) {
                                        setModalState(() {});
                                        setState(() => _filterSubCategory = v ? sub : null);
                                      },
                                      selectedColor: AppTheme.green,
                                      backgroundColor: AppTheme.surfaceLight,
                                    );
                                  }).toList(),
                                ),
                              ],

                              const SizedBox(height: 16),
                              Text('District', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceLight,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _filterDistrict,
                                    hint: Text('Select District', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                                    isExpanded: true,
                                    items: [
                                      const DropdownMenuItem(value: null, child: Text('All Districts')),
                                      ...AppConstants.bunyoroDistricts.map((d) => DropdownMenuItem(value: d, child: Text(d))),
                                    ],
                                    onChanged: (v) {
                                      setModalState(() {});
                                      setState(() => _filterDistrict = v);
                                    },
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),
                              Text('Availability', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: AppConstants.availabilityOptions.map((opt) {
                                  final selected = _filterAvailability == opt;
                                  return FilterChip(
                                    label: Text(opt, style: const TextStyle(fontSize: 12)),
                                    selected: selected,
                                    onSelected: (v) {
                                      setModalState(() {});
                                      setState(() => _filterAvailability = v ? opt : null);
                                    },
                                    selectedColor: AppTheme.greenSurface,
                                    checkmarkColor: AppTheme.greenLight,
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                              Text('Sort By', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: ['Newest', 'Lowest price', 'Highest price'].map((s) {
                                  final selected = _sortBy == s;
                                  return ChoiceChip(
                                    label: Text(s, style: const TextStyle(fontSize: 12)),
                                    selected: selected,
                                    onSelected: (v) {
                                      setModalState(() {});
                                      setState(() => _sortBy = s);
                                    },
                                    selectedColor: AppTheme.greenSurface,
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('Apply Filters'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
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
                            ? IconButton(
                                icon: Icon(Icons.close, color: AppTheme.textMuted, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _showFilterSheet,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (_filterCategory != null || _filterDistrict != null || _filterAvailability != null)
                            ? AppTheme.greenSurface
                            : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (_filterCategory != null || _filterDistrict != null || _filterAvailability != null)
                              ? AppTheme.green
                              : AppTheme.border,
                        ),
                      ),
                      child: Icon(
                        Icons.tune,
                        color: (_filterCategory != null || _filterDistrict != null || _filterAvailability != null)
                            ? AppTheme.greenLight
                            : AppTheme.textMuted,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Active Filters Display
          _buildActiveFilters(),
          
          // Carousel
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                height: 180,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _carouselPageCtrl,
                      onPageChanged: (i) => setState(() => _carouselIndex = i),
                      itemCount: _carouselItems.length,
                      itemBuilder: (ctx, i) {
                        final item = _carouselItems[i];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(
                              image: AssetImage(item['image']!),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                              ),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title']!,
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['desc']!,
                                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      bottom: 12,
                      right: 20,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          _carouselItems.length,
                          (index) => Container(
                            margin: const EdgeInsets.only(left: 4),
                            width: _carouselIndex == index ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _carouselIndex == index ? AppTheme.green : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Bulk / Special Order Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BulkOrderFormScreen(userId: widget.userId)),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.green.withOpacity(0.5), width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.greenSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.shopping_cart_checkout, color: AppTheme.green, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bulk / Special Order', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text('Order large quantities or farm inputs from Registry', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppTheme.green),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Products Grid
          StreamBuilder<List<ProductModel>>(
            stream: _db.streamProducts(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppTheme.green)),
                );
              }
              final products = _applyFilters(snap.data ?? []);
              if (products.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined, color: AppTheme.textMuted.withOpacity(0.3), size: 64),
                        const SizedBox(height: 16),
                        Text('No products found', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Try adjusting your filters', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }
              // Precache all product images for instant loading
              for (final p in products) {
                if (p.imageUrl != null && p.imageUrl!.isNotEmpty && !p.imageUrl!.startsWith('assets/')) {
                  precacheImage(CachedNetworkImageProvider(p.imageUrl!), context);
                }
              }
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.52,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      return ProductCard(
                        product: products[i],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(
                                product: products[i],
                                currentUserId: widget.userId,
                                currentUserRole: widget.userRole,
                              ),
                            ),
                          );
                        },
                      );
                    },
                    childCount: products.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: (widget.userRole == 'Farmer' || widget.userRole == 'Admin' || widget.userRole == 'Agent')
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddProductScreen(sellerId: widget.userId),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildActiveFilters() {
    final bool hasCategory = _filterCategory != null;
    final bool hasDistrict = _filterDistrict != null;
    final bool hasAvailability = _filterAvailability != null;

    if (!hasCategory && !hasDistrict && !hasAvailability) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (hasCategory)
              _buildFilterChip('Category: $_filterCategory', () {
                setState(() => _filterCategory = null);
              }),
            if (hasDistrict)
              _buildFilterChip('District: $_filterDistrict', () {
                setState(() => _filterDistrict = null);
              }),
            if (hasAvailability)
              _buildFilterChip('Status: $_filterAvailability', () {
                setState(() => _filterAvailability = null);
              }),
            if ((hasCategory ? 1 : 0) + (hasDistrict ? 1 : 0) + (hasAvailability ? 1 : 0) > 1)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _filterCategory = null;
                    _filterDistrict = null;
                    _filterAvailability = null;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                      color: AppTheme.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onClear) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.greenSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.green.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.greenLight,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onClear,
            child: const Icon(
              Icons.close,
              color: AppTheme.greenLight,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }
}
