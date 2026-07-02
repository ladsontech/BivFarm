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
  bool _showCategoriesAsColumn = false;

  @override
  void initState() {
    super.initState();
    // Add "All Products" to the list
    _categories = [
      'All Products',
      ...AppConstants.productCategories.keys
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

  void _handleProductTap(ProductModel p) {
    if (widget.onProductSelected != null) {
      widget.onProductSelected!(p);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(
            product: p,
            currentUserId: widget.currentUserId ?? '',
            currentUserRole: widget.currentUserRole ?? 'Buyer',
          ),
        ),
      );
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

            if (isDesktop) {
              return _buildDesktopLayout();
            }
            return _buildMobileLayout();
          },
        ),
      ),
    );
  }

  // ── Mobile Layout: search bar + horizontal chips + full-width product grid ──
  Widget _buildMobileLayout() {
    return Column(
      children: [
        // ── Search Bar (replaces AppBar) ────────────────────────
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Search products...',
              hintStyle: TextStyle(
                color: AppTheme.textMuted.withValues(alpha: 0.6),
                fontSize: 13,
              ),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppTheme.green, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: AppTheme.textMuted, size: 16),
                      onPressed: () =>
                          setState(() => _searchCtrl.clear()),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              filled: true,
              fillColor: AppTheme.surfaceLight,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: AppTheme.border.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppTheme.green, width: 1.2),
              ),
            ),
          ),
        ),

        // ── Category Selector (Row or Wrap Column) ────────────────────────────
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_showCategoriesAsColumn)
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _categories.map((cat) {
                            final isSelected = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedCategory = cat),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.green
                                        : AppTheme.surfaceLight,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.green
                                          : AppTheme.border.withValues(alpha: 0.4),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getCategoryIcon(cat),
                                        size: 14,
                                        color: isSelected ? Colors.white : AppTheme.green,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        cat,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? Colors.white
                                              : AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _showCategoriesAsColumn = true),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: AppTheme.green,
                        ),
                      ),
                    ),
                  ],
                )
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Category',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _showCategoriesAsColumn = false),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_up_rounded,
                          size: 20,
                          color: AppTheme.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat;
                          _showCategoriesAsColumn = false;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.green
                              : AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.green
                                : AppTheme.border.withValues(alpha: 0.4),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getCategoryIcon(cat),
                              size: 14,
                              color: isSelected ? Colors.white : AppTheme.green,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              cat,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),

        // ── Products Grid ──────────────────────────────────────
        Expanded(
          child: _selectedCategory == null
              ? const Center(child: Text('Select a category'))
              : _MobileProductGrid(
                  category: _selectedCategory!,
                  searchQuery: _searchCtrl.text,
                  onProductTap: _handleProductTap,
                ),
        ),
      ],
    );
  }

  // ── Desktop Layout: side panel + main content area ────────────────
  Widget _buildDesktopLayout() {
    return Column(
      children: [
        // Search bar
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
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
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Filter in $_selectedCategory...',
                  hintStyle: TextStyle(
                    color: AppTheme.textMuted.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(Icons.tune_rounded,
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
                        color: AppTheme.border.withValues(alpha: 0.4)),
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
              // ── Desktop Side Navigation ──────────────────────
              Container(
                width: 220,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: Border(
                    right: BorderSide(
                      color: AppTheme.border.withValues(alpha: 0.5),
                      width: 0.5,
                    ),
                  ),
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
                            vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.green.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getCategoryIcon(cat),
                              color: isSelected
                                  ? AppTheme.green
                                  : AppTheme.textMuted
                                      .withValues(alpha: 0.7),
                              size: 20,
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
                        onProductTap: _handleProductTap,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Mobile Product Grid — full-width, no banners, no side panel
// ══════════════════════════════════════════════════════════════════════

class _MobileProductGrid extends StatelessWidget {
  final String category;
  final String searchQuery;
  final Function(ProductModel) onProductTap;

  const _MobileProductGrid({
    required this.category,
    required this.searchQuery,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProductModel>>(
      stream: DatabaseService().streamProducts(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.green),
          );
        }
        if (snap.hasError) {
          return const AppErrorState(
            title: 'Unable to load products',
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

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off_rounded,
                      color: AppTheme.textMuted.withValues(alpha: 0.2),
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

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
          gridDelegate: responsiveGridDelegate(
            context,
            compactExtent: 170,
            desktopExtent: 230,
            compactAspectRatio: 0.65,
            desktopAspectRatio: 0.76,
            spacing: 10,
          ),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) {
            return ProductCard(
              product: filtered[i],
              compact: true,
              onTap: () => onProductTap(filtered[i]),
            );
          },
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Desktop Category Preview (kept for desktop side-panel layout)
// ══════════════════════════════════════════════════════════════════════

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
      child: StreamBuilder<List<ProductModel>>(
        stream: DatabaseService().streamProducts(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: AppTheme.green),
              ),
            );
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off_rounded,
                        color: AppTheme.textMuted.withValues(alpha: 0.2),
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

          return ListView(
            padding: context.pageInsets,
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
              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }
}
