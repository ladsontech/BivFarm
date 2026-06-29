import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../models/product_model.dart';
import '../../services/database_service.dart';
import '../../widgets/product_card.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/responsive_wrapper.dart';
import 'product_detail_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final Function(String) onCategorySelected;
  // Optional — if not provided, tapping a card pushes ProductDetailScreen directly
  final Function(ProductModel)? onProductSelected;
  final String? initialCategory;
  final String? currentUserId;
  final String? currentUserRole;

  const CategoriesScreen({
    super.key,
    required this.onCategorySelected,
    this.onProductSelected,
    this.initialCategory,
    this.currentUserId,
    this.currentUserRole,
  });

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String? _selectedCategory;
  late List<String> _categories;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Add "All Products" to the list
    _categories = [
      'All Products',
      ...AppConstants.productCategories.keys.toList()
    ];
    _selectedCategory = widget.initialCategory ?? _categories.first;
  }

  @override
  void didUpdateWidget(covariant CategoriesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategory != null &&
        widget.initialCategory != oldWidget.initialCategory) {
      setState(() {
        _selectedCategory = widget.initialCategory;
        _searchCtrl.clear();
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'All Products':
        return Icons.grid_view_rounded;
      case 'Produce':
        return Icons.grass;
      case 'Poultry':
        return Icons.egg_outlined;
      case 'Livestock':
        return Icons.pets;
      case 'Fruits & Vegetables':
        return Icons.eco_outlined;
      case 'Farm Machinery':
        return Icons.agriculture;
      case 'Fertilizers & Pesticides':
        return Icons.science_outlined;
      default:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= AppBreakpoints.desktop;
            return Column(
              children: [
                // ── Clean Search Bar ────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: 'Filter in $_selectedCategory...',
                          hintStyle: TextStyle(
                              color: AppTheme.textMuted.withOpacity(0.6),
                              fontSize: 13),
                          prefixIcon: Icon(Icons.tune_rounded,
                              color: AppTheme.green, size: 18),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close_rounded,
                                      color: AppTheme.textMuted, size: 16),
                                  onPressed: () =>
                                      setState(() => _searchCtrl.clear()),
                                )
                              : null,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                          filled: true,
                          fillColor: AppTheme.surfaceLight,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: AppTheme.border.withOpacity(0.4)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppTheme.green, width: 1.2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: Row(
                    children: [
                      // ── Premium Side Navigation ──────────────────────
                      Container(
                        width: isDesktop ? 220 : 75,
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          border: Border(
                              right: BorderSide(
                                  color: AppTheme.border.withOpacity(0.5),
                                  width: 0.5)),
                        ),
                        child: ListView.builder(
                          itemCount: _categories.length,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemBuilder: (ctx, i) {
                            final cat = _categories[i];
                            final isSelected = _selectedCategory == cat;
                            return InkWell(
                              onTap: () =>
                                  setState(() => _selectedCategory = cat),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 8),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.green.withOpacity(0.08)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: isDesktop
                                    ? Row(
                                        children: [
                                          Icon(
                                            _getCategoryIcon(cat),
                                            color: isSelected
                                                ? AppTheme.green
                                                : AppTheme.textMuted
                                                    .withOpacity(0.7),
                                            size: 21,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              cat,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: isSelected
                                                    ? FontWeight.w800
                                                    : FontWeight.w600,
                                                color: isSelected
                                                    ? AppTheme.green
                                                    : AppTheme.textMuted,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _getCategoryIcon(cat),
                                            color: isSelected
                                                ? AppTheme.green
                                                : AppTheme.textMuted
                                                    .withOpacity(0.7),
                                            size: 20,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            cat
                                                .split(' ')
                                                .first, // Keep labels short
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: isSelected
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                              color: isSelected
                                                  ? AppTheme.green
                                                  : AppTheme.textMuted,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            );
                          },
                        ),
                      ),

                      // ── Main Content Area ──────────────────────────
                      Expanded(
                        child: _selectedCategory == null
                            ? const Center(child: Text('Select a category'))
                            : _CategoryPreview(
                                category: _selectedCategory!,
                                searchQuery: _searchCtrl.text,
                                onExplore: () => widget
                                    .onCategorySelected(_selectedCategory!),
                                onProductTap: (p) {
                                  if (widget.onProductSelected != null) {
                                    widget.onProductSelected!(p);
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetailScreen(
                                          product: p,
                                          currentUserId:
                                              widget.currentUserId ?? '',
                                          currentUserRole:
                                              widget.currentUserRole ?? 'Buyer',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CategoryPreview extends StatelessWidget {
  final String category;
  final String searchQuery;
  final VoidCallback onExplore;
  final Function(ProductModel) onProductTap;

  const _CategoryPreview({
    required this.category,
    required this.searchQuery,
    required this.onExplore,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper(
      maxWidth: 1200,
      child: ListView(
        padding: context.pageInsets,
        children: [
          // Category Header (Hide if All Products)
          if (category != 'All Products') ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 100,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      _getPlaceholderImage(category),
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7)
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          StreamBuilder<List<ProductModel>>(
            stream: DatabaseService().streamProducts(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppTheme.green),
                ));
              }
              if (snap.hasError) {
                return const SizedBox(
                  height: 360,
                  child: AppErrorState(
                    title: 'Unable to load this category',
                  ),
                );
              }

              final allProducts = snap.data ?? [];
              final q = searchQuery.toLowerCase().trim();

              // Filter logic
              var filtered = allProducts;
              if (category != 'All Products') {
                filtered = filtered
                    .where((p) =>
                        p.category == category ||
                        (category == 'Poultry' &&
                            p.category == 'Poultry & Livestock') ||
                        (category == 'Livestock' &&
                            p.category == 'Poultry & Livestock'))
                    .toList();
              }

              if (q.isNotEmpty) {
                filtered = filtered
                    .where((p) =>
                        p.productName.toLowerCase().contains(q) ||
                        p.district.toLowerCase().contains(q) ||
                        p.category.toLowerCase().contains(q))
                    .toList();
              }

              final displayList = (q.isEmpty && category != 'All Products')
                  ? filtered.take(6).toList()
                  : filtered;

              if (displayList.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: [
                        Icon(Icons.search_off_rounded,
                            color: AppTheme.textMuted.withOpacity(0.2),
                            size: 48),
                        const SizedBox(height: 12),
                        Text('No items found',
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (category != 'All Products') ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          searchQuery.isEmpty
                              ? 'Sample Listings'
                              : 'Search Results',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (searchQuery.isEmpty)
                          TextButton(
                            onPressed: onExplore,
                            style: TextButton.styleFrom(
                                foregroundColor: AppTheme.green,
                                textStyle: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700)),
                            child: const Text('View All →'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: responsiveGridDelegate(
                      context,
                      compactExtent: 170,
                      desktopExtent: 230,
                      compactAspectRatio: 0.65,
                      desktopAspectRatio: 0.76,
                      spacing: 14,
                    ),
                    itemCount: displayList.length,
                    itemBuilder: (ctx, i) {
                      return ProductCard(
                        product: displayList[i],
                        compact: true,
                        onTap: () => onProductTap(displayList[i]),
                      );
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  String _getPlaceholderImage(String cat) {
    switch (cat) {
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
}
