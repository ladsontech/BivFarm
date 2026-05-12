import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/product_card.dart';
import '../../utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/network_image_widget.dart';
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

  ProductModel? _selectedProduct;

  late PageController _carouselPageCtrl;
  Timer? _carouselTimer;
  final ValueNotifier<int> _carouselIndex = ValueNotifier(0);

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
        _carouselIndex.value = (_carouselIndex.value + 1) % _carouselItems.length;
        _carouselPageCtrl.animateToPage(
          _carouselIndex.value,
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
    _carouselIndex.dispose();
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 900;

        final Widget mainScaffold = Scaffold(
          body: CustomScrollView(
        slivers: [
          // ── Greeting + Search bar ────────────────────────
          SliverToBoxAdapter(
            child: StreamBuilder<UserModel?>(
              stream: DatabaseService().streamUser(widget.userId),
              builder: (ctx, snap) {
                final user = snap.data;
                final firstName = user?.firstName.isNotEmpty == true
                    ? user!.firstName
                    : (user?.name.split(' ').first ?? '');
                final greeting = _greeting();
                return Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(greeting, style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text(
                                  firstName.isNotEmpty ? firstName : widget.userRole,
                                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.green, width: 2),
                              image: user?.profilePhoto != null
                                  ? DecorationImage(image: appNetworkImageProvider(user!.profilePhoto!), fit: BoxFit.cover)
                                  : null,
                              color: AppTheme.greenSurface,
                            ),
                            child: user?.profilePhoto == null
                                ? Center(child: Text(
                                    firstName.isNotEmpty ? firstName[0].toUpperCase() : widget.userRole[0],
                                    style: const TextStyle(color: AppTheme.greenDark, fontWeight: FontWeight.w800, fontSize: 17),
                                  ))
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (_) => setState(() {}),
                              style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Search products, farmers, districts…',
                                prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                                suffixIcon: _searchCtrl.text.isNotEmpty
                                    ? IconButton(icon: Icon(Icons.close, color: AppTheme.textMuted, size: 18), onPressed: () { _searchCtrl.clear(); setState(() {}); })
                                    : null,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _showFilterSheet,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                color: _hasFilter ? AppTheme.green : AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _hasFilter ? AppTheme.green : AppTheme.border),
                                boxShadow: _hasFilter ? [BoxShadow(color: AppTheme.green.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : [],
                              ),
                              child: Icon(Icons.tune_rounded, color: _hasFilter ? Colors.white : AppTheme.textMuted, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          _buildActiveFilters(),

          // ── Hero Carousel ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: SizedBox(
                height: 195,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _carouselPageCtrl,
                      onPageChanged: (i) => _carouselIndex.value = i,
                      itemCount: _carouselItems.length,
                      itemBuilder: (ctx, i) {
                        final item = _carouselItems[i];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: DecorationImage(image: AssetImage(item['image']!), fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.25), BlendMode.darken)),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withOpacity(0.75)], stops: const [0.35, 1.0]),
                            ),
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: AppTheme.green.withOpacity(0.85), borderRadius: BorderRadius.circular(20)),
                                  child: const Text('BivFarm', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                                ),
                                const SizedBox(height: 6),
                                Text(item['title']!, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, height: 1.1)),
                                const SizedBox(height: 4),
                                Text(item['desc']!, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      bottom: 12, left: 0, right: 0,
                      child: ValueListenableBuilder<int>(
                        valueListenable: _carouselIndex,
                        builder: (_, idx, __) => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_carouselItems.length, (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: idx == i ? 22 : 6, height: 6,
                            decoration: BoxDecoration(
                              color: idx == i ? AppTheme.greenAccent : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          )),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Category quick-filter strip ──────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _categoryChip(null, 'All', Icons.apps_rounded),
                  ...AppConstants.productCategories.keys.map((cat) => _categoryChip(cat, cat, _catIcon(cat))),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // ── Bulk Order banner ────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BulkOrderFormScreen(userId: widget.userId))),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(colors: [AppTheme.green.withOpacity(0.85), const Color(0xFF1B5E20)],
                      begin: Alignment.centerLeft, end: Alignment.centerRight),
                    boxShadow: [BoxShadow(color: AppTheme.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.shopping_cart_checkout_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Bulk / Special Order', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                          SizedBox(height: 2),
                          Text('Large quantities & farm inputs from Registry', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ]),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Section header ───────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _filterCategory != null ? '$_filterCategory Listings' : 'All Listings',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  if (_hasFilter)
                    GestureDetector(
                      onTap: () => setState(() { _filterCategory = null; _filterDistrict = null; _filterAvailability = null; }),
                      child: Text('Clear', style: TextStyle(color: AppTheme.greenLight, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
          ),

          // ── Products grid ────────────────────────────────
          StreamBuilder<List<ProductModel>>(
            stream: _db.streamProducts(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppTheme.green)));
              }
              final products = _applyFilters(snap.data ?? []);
              if (products.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.inventory_2_outlined, color: AppTheme.textMuted.withOpacity(0.3), size: 64),
                      const SizedBox(height: 16),
                      Text('No products found', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Try adjusting your filters', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    ]),
                  ),
                );
              }
              for (final p in products) {
                if (p.imageUrl != null && p.imageUrl!.isNotEmpty && !p.imageUrl!.startsWith('assets/')) {
                  precacheImage(appNetworkImageProvider(p.imageUrl!), context);
                }
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220, childAspectRatio: 0.70, crossAxisSpacing: 12, mainAxisSpacing: 14,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => ProductCard(
                      product: products[i],
                      onTap: () {
                        if (isDesktop) {
                          setState(() => _selectedProduct = products[i]);
                        } else {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(product: products[i], currentUserId: widget.userId, currentUserRole: widget.userRole),
                          ));
                        }
                      },
                    ),
                    childCount: products.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: (widget.userRole == 'Farmer' || widget.userRole == 'Admin' || widget.userRole == 'Agent')
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductScreen(sellerId: widget.userId))),
              icon: const Icon(Icons.add),
              label: const Text('List Product', style: TextStyle(fontWeight: FontWeight.w700)),
              backgroundColor: AppTheme.green,
            )
          : null,
    );

        if (isDesktop && _selectedProduct != null) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: mainScaffold,
              ),
              VerticalDivider(width: 1, thickness: 1, color: AppTheme.border),
              Expanded(
                flex: 4,
                child: ProductDetailScreen(
                  key: ValueKey(_selectedProduct!.id),
                  product: _selectedProduct!,
                  currentUserId: widget.userId,
                  currentUserRole: widget.userRole,
                  isEmbedded: true,
                  onClose: () => setState(() => _selectedProduct = null),
                ),
              ),
            ],
          );
        }

        return mainScaffold;
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────

  bool get _hasFilter => _filterCategory != null || _filterDistrict != null || _filterAvailability != null;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  Widget _categoryChip(String? cat, String label, IconData icon) {
    final selected = _filterCategory == cat;
    return GestureDetector(
      onTap: () => setState(() {
        _filterCategory = cat;
        _filterSubCategory = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.green : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.green : AppTheme.border),
          boxShadow: selected ? [BoxShadow(color: AppTheme.green.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? Colors.white : AppTheme.textMuted),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _catIcon(String category) {
    switch (category) {
      case 'Produce': return Icons.grass_rounded;
      case 'Poultry': return Icons.egg_outlined;
      case 'Livestock': return Icons.pets_rounded;
      case 'Fruits & Vegetables': return Icons.eco_rounded;
      case 'Farm Machinery': return Icons.agriculture_rounded;
      case 'Fertilizers & Pesticides': return Icons.science_outlined;
      default: return Icons.inventory_2_outlined;
    }
  }

  Widget _buildActiveFilters() {
    if (!_hasFilter) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (_filterCategory != null)
              _buildFilterChip('Category: $_filterCategory', () => setState(() => _filterCategory = null)),
            if (_filterDistrict != null)
              _buildFilterChip('District: $_filterDistrict', () => setState(() => _filterDistrict = null)),
            if (_filterAvailability != null)
              _buildFilterChip('Status: $_filterAvailability', () => setState(() => _filterAvailability = null)),
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
          Text(label, style: const TextStyle(color: AppTheme.greenLight, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(width: 6),
          GestureDetector(onTap: onClear, child: const Icon(Icons.close, color: AppTheme.greenLight, size: 14)),
        ],
      ),
    );
  }
}
