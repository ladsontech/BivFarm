import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/product_card.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../utils/constants.dart';
import 'product_detail_screen.dart';
import 'add_product_screen.dart';
import '../orders/bulk_order_form_screen.dart';

class MarketplaceController extends ChangeNotifier {
  String? _category;

  String? get category => _category;

  void showCategory(String? category) {
    _category = category;
    notifyListeners();
  }
}

class MarketplaceScreen extends StatefulWidget {
  final String userRole;
  final String userId;
  final List<Widget>? actions;
  final void Function(String category)? onViewAllCategory;
  final MarketplaceController? controller;

  const MarketplaceScreen({
    super.key,
    required this.userRole,
    required this.userId,
    this.actions,
    this.onViewAllCategory,
    this.controller,
  });

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _db = DatabaseService();
  ProductModel? _selectedProduct;
  String? _activeCategory;
  String? _activeSellerRole;
  String? _activeDistrict;
  final _searchCtrl = TextEditingController();

  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;
  final List<String> _banners = [
    'assets/images/farm_products_banner.png',
    'assets/images/farm_machines_banner.png',
    'assets/images/farm_chemicals_banner.png',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.96);
    _activeCategory = widget.controller?.category;
    widget.controller?.addListener(_applyControllerFilter);
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant MarketplaceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_applyControllerFilter);
      widget.controller?.addListener(_applyControllerFilter);
      _applyControllerFilter();
    }
  }

  void _applyControllerFilter() {
    if (!mounted) return;
    setState(() {
      _activeCategory = widget.controller?.category;
      _activeSellerRole = null;
    });
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      if (!_pageController.hasClients) return;
      _currentPage = (_currentPage + 1) % _banners.length;
      _pageController
          .animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOutQuart,
          )
          .catchError((_) {});
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _autoScrollTimer?.cancel();
    widget.controller?.removeListener(_applyControllerFilter);
    _pageController.dispose();
    super.dispose();
  }

  void applyExternalFilter(String? category) {
    setState(() {
      _activeCategory = category;
    });
  }

  void _showDistrictFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter by District',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_activeDistrict != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _activeDistrict = null;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Clear',
                          style: TextStyle(color: AppTheme.error)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: AppConstants.bunyoroDistricts.length,
                  itemBuilder: (context, index) {
                    final district = AppConstants.bunyoroDistricts[index];
                    final isSelected = _activeDistrict == district;
                    return ListTile(
                      title: Text(
                        district,
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.greenLight
                              : AppTheme.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: AppTheme.greenLight)
                          : null,
                      onTap: () {
                        setState(() {
                          _activeDistrict = district;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= AppBreakpoints.desktop;
        final bool showSplitView = constraints.maxWidth >= 1280;

        final Widget mainScaffold = Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.maxContentWidth,
              ),
              child: isDesktop
                  ? _buildDesktopLayout(showSplitView)
                  : _buildMobileLayout(showSplitView),
            ),
          ),
          floatingActionButton: (widget.userRole == 'Farmer' ||
                  widget.userRole == 'Admin' ||
                  widget.userRole == 'Agent')
              ? FloatingActionButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              AddProductScreen(sellerId: widget.userId))),
                  backgroundColor: AppTheme.green,
                  mini: true,
                  tooltip: 'Sell Now',
                  child: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
                )
              : null,
        );

        if (showSplitView && _selectedProduct != null) {
          return Row(
            children: [
              Expanded(flex: 3, child: mainScaffold),
              VerticalDivider(width: 1, color: AppTheme.border),
              Expanded(
                flex: 2,
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

  // ── Clean & Minimalist Desktop Layout ────────────────────────────────────
  Widget _buildDesktopLayout(bool showSplitView) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Clean Search Bar ────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Row(
            children: [
              Expanded(
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
                      hintText: 'Search products by name, category, district...',
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
                              onPressed: () => setState(() => _searchCtrl.clear()),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      filled: true,
                      fillColor: AppTheme.surfaceLight,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: AppTheme.border.withValues(alpha: 0.4)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppTheme.green, width: 1.2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // District Filter Button
              OutlinedButton.icon(
                onPressed: _showDistrictFilterSheet,
                icon: Icon(
                  _activeDistrict != null
                      ? Icons.filter_alt
                      : Icons.filter_alt_outlined,
                  size: 16,
                  color: AppTheme.green,
                ),
                label: Text(
                  _activeDistrict ?? 'All Districts',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  side: BorderSide(color: AppTheme.border.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),

        // ── Compact Category Buttons Row ────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // "All" Chip
                _buildDesktopCategoryChip(
                  label: 'All Products',
                  icon: Icons.grid_view_rounded,
                  isSelected: _activeCategory == null && _activeSellerRole == null,
                  onTap: () => setState(() {
                    _activeCategory = null;
                    _activeSellerRole = null;
                  }),
                ),
                // "Produce Store" Chip
                _buildDesktopCategoryChip(
                  label: 'Produce Store',
                  icon: Icons.storefront,
                  isSelected: _activeSellerRole == 'Store',
                  onTap: () => setState(() {
                    _activeSellerRole = 'Store';
                    _activeCategory = null;
                  }),
                ),
                // Regular Categories
                ...AppConstants.productCategories.keys.map((cat) {
                  final isSelected = _activeCategory == cat && _activeSellerRole == null;
                  return _buildDesktopCategoryChip(
                    label: cat,
                    icon: _getCategoryIcon(cat),
                    isSelected: isSelected,
                    onTap: () => setState(() {
                      _activeCategory = cat;
                      _activeSellerRole = null;
                    }),
                  );
                }),
              ],
            ),
          ),
        ),

        // District filter chip reminder
        if (_activeDistrict != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Chip(
              label: Text(
                'District: $_activeDistrict',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: AppTheme.green,
              deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
              onDeleted: () => setState(() => _activeDistrict = null),
            ),
          ),

        // ── Products Grid ──────────────────────────────────
        Expanded(
          child: StreamBuilder<List<ProductModel>>(
            stream: _db.streamProducts(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.green),
                );
              }
              if (snap.hasError) {
                return const AppErrorState(title: 'Unable to load products');
              }

              final allProducts = snap.data ?? [];
              final q = _searchCtrl.text.toLowerCase().trim();

              // Filter logic
              var filtered = allProducts;
              if (_activeCategory != null) {
                filtered = filtered.where((p) => p.category == _activeCategory).toList();
              }
              if (_activeSellerRole != null) {
                filtered = filtered.where((p) => p.sellerRole == _activeSellerRole).toList();
              }
              if (_activeDistrict != null) {
                filtered = filtered.where((p) => p.district == _activeDistrict).toList();
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded,
                          color: AppTheme.textMuted.withValues(alpha: 0.2),
                          size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'No products found matching your search.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                gridDelegate: responsiveGridDelegate(
                  context,
                  compactExtent: 180,
                  desktopExtent: 230,
                  compactAspectRatio: 0.60,
                  desktopAspectRatio: 0.68,
                  spacing: 16,
                ),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  return ProductCard(
                    product: filtered[i],
                    onTap: () => _openDetail(context, filtered[i], showSplitView),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopCategoryChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.green : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.green : AppTheme.border.withValues(alpha: 0.4),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppTheme.green,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Mobile/Tablet View (using slivers, advertising carousels and banners) ──────
  Widget _buildMobileLayout(bool showSplitView) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Simple Minimalist App Bar ──────────────────────
        SliverAppBar(
          expandedHeight: 0,
          floating: false,
          pinned: true,
          backgroundColor: AppTheme.greenDark,
          elevation: 0,
          centerTitle: false,
          titleSpacing: 20,
          title: Opacity(
            opacity: 0.95,
            child: Image.asset(
              'assets/images/bfarm_premium_logo.png',
              height: 56, // Fill standard toolbar height better
              fit: BoxFit.contain,
              color: Colors.white.withValues(alpha: 0.95),
              colorBlendMode: BlendMode.srcATop,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _activeDistrict != null
                    ? Icons.filter_alt
                    : Icons.filter_alt_outlined,
                color: Colors.white,
              ),
              tooltip: 'Filter by District',
              onPressed: _showDistrictFilterSheet,
            ),
            ...?widget.actions,
          ],
        ),

        // ── Carousel Banners ──────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            height: 180,
            margin: const EdgeInsets.symmetric(
              horizontal: 0,
              vertical: 10,
            ),
            child: PageView.builder(
              controller: _pageController,
              itemCount: _banners.length,
              onPageChanged: (index) {
                if (mounted) setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _buildCarouselItem(_banners[index]),
                );
              },
            ),
          ),
        ),

        // ── Category Ribbon ────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            height: 96,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Builder(builder: (context) {
              // Custom ordered chip list: All, Produce, Produce Store, then rest
              final allCats =
                  AppConstants.productCategories.keys.toList();
              // Build ordered: [null=All, 'Produce', '__store__', then remaining cats]
              final List<String?> chipOrder = [
                null, // All
                'Produce',
                '__store__', // Produce Store
                ...allCats.where((c) => c != 'Produce'),
              ];
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16, right: 8),
                itemCount: chipOrder.length,
                itemBuilder: (context, index) {
                  final chip = chipOrder[index];

                  if (chip == null) {
                    // "All" chip
                    final isSelected = _activeCategory == null &&
                        _activeSellerRole == null;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() {
                          _activeCategory = null;
                          _activeSellerRole = null;
                        }),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.green
                                : AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.green
                                  : AppTheme.border.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(Icons.apps,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.green,
                                  size: 18),
                              const SizedBox(height: 2),
                              Text('All',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                    fontSize: 10,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    );
                  } else if (chip == '__store__') {
                    // "Produce Store" chip
                    final isSelected = _activeSellerRole == 'Store';
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() {
                          _activeSellerRole =
                              isSelected ? null : 'Store';
                          _activeCategory = null;
                        }),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.green
                                : AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.green
                                  : AppTheme.border.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(Icons.storefront,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.green,
                                  size: 18),
                              const SizedBox(height: 2),
                              Text('Produce Store',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                    fontSize: 10,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ),
                    );
                  } else {
                    // Regular category chip
                    final cat = chip;
                    final isSelected = _activeCategory == cat &&
                        _activeSellerRole == null;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() {
                          _activeCategory = isSelected ? null : cat;
                          _activeSellerRole = null;
                        }),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.green
                                : AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.green
                                  : AppTheme.border.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(_getCategoryIcon(cat),
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.green,
                                  size: 18),
                              const SizedBox(height: 2),
                              Text(cat,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                    fontSize: 10,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                },
              );
            }),
          ),
        ),

        if (_activeDistrict != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Chip(
                    label: Text(
                      'District: $_activeDistrict',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: AppTheme.green,
                    deleteIcon: const Icon(Icons.close,
                        size: 16, color: Colors.white),
                    onDeleted: () {
                      setState(() {
                        _activeDistrict = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

        // ── Bulk Order Banner ──────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      BulkOrderFormScreen(userId: widget.userId)),
              ),
              child: Container(
                height: 110,
                decoration: BoxDecoration(
                  color: AppTheme.green,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.green.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.inventory_2_rounded,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'BULK / SPECIAL ORDER',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Need large quantities?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 1),
                            Text(
                              'Registry network fulfillment',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Text(
                        'Get Quote',
                        style: TextStyle(
                          color: Color(0xFF1B5E20),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Main Content ───────────────────────────────────
        StreamBuilder<List<ProductModel>>(
          stream: _db.streamProducts(),
          builder: (ctx, snap) {
            final allProducts = snap.data ?? [];
            final isLoading =
                snap.connectionState == ConnectionState.waiting &&
                    allProducts.isEmpty;

            if (isLoading) {
              return const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.green)),
              );
            }
            if (snap.hasError && allProducts.isEmpty) {
              return const SliverFillRemaining(
                child: AppErrorState(
                  title: 'Unable to load the marketplace',
                ),
              );
            }

            // Filter by ribbon category, sellerRole, or district if active
            var filtered = allProducts;
            if (_activeCategory != null) {
              filtered = filtered
                  .where((p) => p.category == _activeCategory)
                  .toList();
            }
            if (_activeSellerRole != null) {
              filtered = filtered
                  .where((p) => p.sellerRole == _activeSellerRole)
                  .toList();
            }
            if (_activeDistrict != null) {
              filtered = filtered
                  .where((p) => p.district == _activeDistrict)
                  .toList();
            }

            if (_activeCategory != null ||
                _activeSellerRole != null ||
                _activeDistrict != null) {
              // ── Search/Filter results grid ─────────────────
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                sliver: filtered.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Center(
                            child: Text('No products found',
                                style: TextStyle(
                                    color: AppTheme.textMuted)),
                          ),
                        ),
                      )
                    : SliverGrid(
                        gridDelegate: responsiveGridDelegate(
                          context,
                          compactExtent: 180,
                          desktopExtent: 230,
                          compactAspectRatio: 0.60,
                          desktopAspectRatio: 0.68,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => ProductCard(
                            product: filtered[i],
                            onTap: () => _openDetail(
                                context, filtered[i], showSplitView),
                          ),
                          childCount: filtered.length,
                        ),
                      ),
              );
            }

            // ── Default: Featured per category section ──────
            return SliverList(
              delegate: SliverChildListDelegate(
                  _buildFeaturedSections(
                      context, allProducts, showSplitView)),
            );
          },
        ),
      ],
    );
  }

  void _openDetail(BuildContext context, ProductModel p, bool isDesktop) {
    if (isDesktop) {
      setState(() => _selectedProduct = p);
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
                product: p,
                currentUserId: widget.userId,
                currentUserRole: widget.userRole),
          ));
    }
  }

  List<Widget> _buildFeaturedSections(
      BuildContext context, List<ProductModel> allProducts, bool isDesktop) {
    final categories = AppConstants.productCategories.keys.toList();
    final List<Widget> sections = [];

    // ── Bulk Order Banner already rendered as a persistent SliverToBoxAdapter above ──

    for (final cat in categories) {
      final featured =
          allProducts.where((p) => p.category == cat).take(6).toList();
      if (featured.isEmpty) continue;

      sections.add(_CategorySection(
        category: cat,
        products: featured,
        onViewAll: () {
          if (widget.onViewAllCategory != null) {
            widget.onViewAllCategory!(cat);
          } else {
            setState(() => _activeCategory = cat);
          }
        },
        onProductTap: (p) => _openDetail(context, p, isDesktop),
      ));
    }

    sections.add(const SizedBox(height: 120));
    return sections;
  }

  Widget _buildCarouselItem(String imagePath) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Produce':
        return Icons.grass;
      case 'Poultry':
        return Icons.egg_outlined;
      case 'Livestock':
        return Icons.pets;
      case 'Fruits & Vegetables':
        return Icons.eco_rounded;
      case 'Farm Machinery':
        return Icons.agriculture_rounded;
      case 'Fertilizers & Pesticides':
        return Icons.science_outlined;
      default:
        return Icons.inventory_2;
    }
  }
}

class _CategorySection extends StatelessWidget {
  final String category;
  final List<ProductModel> products;
  final VoidCallback onViewAll;
  final void Function(ProductModel) onProductTap;

  const _CategorySection({
    required this.category,
    required this.products,
    required this.onViewAll,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.toUpperCase(),
                      style: TextStyle(
                          color: AppTheme.green,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5),
                    ),
                    Text(
                      'Best of $category',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onViewAll,
                child: Row(
                  children: [
                    Text('View All',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: context.isDesktop ? 330 : 268,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20, right: 10),
            itemCount: products.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (ctx, i) {
              return SizedBox(
                width: context.isDesktop ? 220 : 175,
                child: Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: ProductCard(
                    product: products[i],
                    onTap: () => onProductTap(products[i]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
