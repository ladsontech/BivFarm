import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../models/bid_model.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/network_image_widget.dart';
import '../../widgets/responsive_wrapper.dart';
import '../bidding/bid_form_screen.dart';
import '../../widgets/product_card.dart';
import 'add_product_screen.dart';
import '../auth/login_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  final String currentUserId;
  final String currentUserRole;
  final bool isEmbedded;
  final VoidCallback? onClose;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.currentUserId,
    required this.currentUserRole,
    this.isEmbedded = false,
    this.onClose,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final PageController _pageCtrl = PageController();
  final DatabaseService _db = DatabaseService();
  late final Future<UserModel?> _sellerFuture;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _sellerFuture = _db.getUser(widget.product.sellerId);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _showFullScreenImage(
      BuildContext context, List<String> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _FullScreenGallery(images: images, initialIndex: initialIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = viewportWidth >= AppBreakpoints.desktop;

    final scaffold = Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0.5,
        leading: widget.isEmbedded
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          widget.product.productName,
          style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700),
        ),
        actions: [
          FutureBuilder<UserModel?>(
            future: _sellerFuture,
            builder: (context, userSnap) {
              final seller = userSnap.data;
              final isAgentOfSeller = widget.currentUserRole == 'Agent' &&
                  (widget.product.agentId == widget.currentUserId ||
                      seller?.agentId == widget.currentUserId);
              final canEdit = widget.currentUserRole == 'Admin' ||
                  isAgentOfSeller ||
                  widget.product.sellerId == widget.currentUserId;
              if (canEdit) {
                return IconButton(
                  icon: Icon(Icons.edit_outlined, color: AppTheme.green),
                  tooltip: 'Edit Listing',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddProductScreen(
                          sellerId: widget.product.sellerId,
                          existingProduct: widget.product),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          if (widget.isEmbedded)
            IconButton(
              icon: Icon(Icons.close_rounded, color: AppTheme.textPrimary),
              onPressed: widget.onClose,
            )
        ],
      ),
      body: SafeArea(
        child: isDesktop
            ? _buildDesktopLayout(context)
            : _buildMobileLayout(context),
      ),
      bottomNavigationBar: _shouldShowBidButton()
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (widget.currentUserId == 'visitor') {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16)),
                                    title: const Text('Authentication Required'),
                                    content: const Text(
                                        'You need to be signed in to place a bid. Would you like to log in or register now?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('Cancel',
                                            style: TextStyle(color: AppTheme.textMuted)),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) => const LoginScreen()),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.green,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: const Text('Log In / Sign Up'),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BidFormScreen(
                                        product: widget.product,
                                        buyerId: widget.currentUserId),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.gavel_rounded),
                            label: const Text(
                              'Place a Bid',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );

    if (widget.isEmbedded) {
      return Container(
        color: AppTheme.background,
        child: scaffold,
      );
    }
    return scaffold;
  }

  bool _shouldShowBidButton() {
    final role = widget.currentUserRole;
    final isBuyerOrRelated = role == 'Buyer' ||
        role == 'Admin' ||
        role == 'Agent' ||
        role == 'Farmer';
    return isBuyerOrRelated && widget.currentUserId != widget.product.sellerId;
  }

  // ── Desktop Two-Column Split Layout ──────────────────────────────────────
  Widget _buildDesktopLayout(BuildContext context) {
    final images = widget.product.imageUrls;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Side: Image Gallery Card
                  Expanded(
                    flex: 1,
                    child: Card(
                      color: AppTheme.surface,
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          _buildCarouselWidget(400),
                          if (images.length > 1) _buildGallerySelector(images),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Right Side: Product details + Farmer Info
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProductDetailsCard(),
                        const SizedBox(height: 20),
                        _buildFarmerDetailsCard(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 24),
              _buildBidsListSection(),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              _buildMoreFromSellerSection(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Mobile/Tablet Vertical Layout ────────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image widget
          _buildCarouselWidget(300),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductDetailsCard(),
                const SizedBox(height: 16),
                _buildFarmerDetailsCard(),
                const SizedBox(height: 24),
                _buildBidsListSection(),
                const SizedBox(height: 24),
                _buildMoreFromSellerSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Image Carousel & Badge ────────────────────────────────────────────────
  Widget _buildCarouselWidget(double height) {
    final images = widget.product.imageUrls;

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          images.isNotEmpty
              ? PageView.builder(
                  controller: _pageCtrl,
                  itemCount: images.length,
                  onPageChanged: (i) {
                    if (mounted) setState(() => _currentPage = i);
                  },
                  itemBuilder: (ctx, i) {
                    return GestureDetector(
                      onTap: () => _showFullScreenImage(context, images, i),
                      child: _buildImage(images[i]),
                    );
                  },
                )
              : Container(
                  color: AppTheme.surfaceLight,
                  child: Icon(Icons.inventory_2_rounded,
                      color: AppTheme.textMuted.withValues(alpha: 0.4), size: 64),
                ),
          if (images.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPage == i ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? AppTheme.green
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGallerySelector(List<String> images) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: AppTheme.surfaceLight.withValues(alpha: 0.5),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (ctx, i) {
          final isSelected = _currentPage == i;
          return GestureDetector(
            onTap: () {
              _pageCtrl.animateToPage(i,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              width: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppTheme.green : Colors.transparent,
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildImage(images[i]),
            ),
          );
        },
      ),
    );
  }

  // ── Product Details Info Card ─────────────────────────────────────────────
  Widget _buildProductDetailsCard() {
    final formatter = NumberFormat('#,###');
    final p = widget.product;

    return Card(
      color: AppTheme.surface,
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                p.category,
                style: const TextStyle(
                    color: AppTheme.green, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              p.productName,
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'UGX ${formatter.format(p.price)} / ${p.quantityUnit.toLowerCase() == 'pieces' ? 'Piece' : (p.quantityUnit.toLowerCase() == 'crates' ? 'Crate' : p.quantityUnit)}',
              style: const TextStyle(
                  color: AppTheme.greenLight,
                  fontSize: 20,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            _infoItem(Icons.scale_outlined, 'Available Quantity',
                '${p.quantity} ${p.quantityUnit}'),
            _infoItem(Icons.location_on_outlined, 'District / Location', p.district),
            _infoItem(Icons.schedule_outlined, 'Availability Status', p.availability),
            _infoItem(
              Icons.calendar_today_outlined,
              'Date Posted',
              DateFormat('MMMM dd, yyyy').format(p.createdAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                const SizedBox(height: 1),
                Text(value,
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Farmer Profile Details Card ───────────────────────────────────────────
  Widget _buildFarmerDetailsCard() {
    final role = widget.currentUserRole;

    return FutureBuilder<UserModel?>(
      future: _sellerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 150,
            child: Center(
                child: CircularProgressIndicator(color: AppTheme.green)),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Card(
            color: AppTheme.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Farmer details are currently unavailable.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
            ),
          );
        }

        final user = snapshot.data!;
        final isPrivileged = role == 'Admin' ||
            role == 'Registry' ||
            (role == 'Agent' && user.agentId == widget.currentUserId);
        final displayLocation = isPrivileged
            ? '${user.village.isNotEmpty ? '${user.village}, ' : ''}${user.subcounty.isNotEmpty ? '${user.subcounty}, ' : ''}${user.district}'
            : user.district;

        return Card(
          color: AppTheme.surface,
          elevation: 0.5,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About the Farmer',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppTheme.green.withValues(alpha: 0.08),
                      backgroundImage: user.profilePhoto != null
                          ? NetworkImage(user.profilePhoto!)
                          : null,
                      child: user.profilePhoto == null
                          ? Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : 'F',
                              style: const TextStyle(
                                  color: AppTheme.green,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name.isNotEmpty ? user.name : 'Farmer Profile',
                            style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            displayLocation,
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (user.bio != null && user.bio!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    user.bio!,
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        height: 1.4),
                  ),
                ],
                if (isPrivileged) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    role == 'Admin' ? 'Admin Access Details' : 'Farmer Contact Details',
                    style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _contactRow(Icons.phone_outlined, user.phone.isNotEmpty ? user.phone : 'No Phone listed'),
                  _contactRow(Icons.email_outlined, user.email.isNotEmpty ? user.email : 'No Email listed'),
                  if (user.nin.isNotEmpty)
                    _contactRow(Icons.badge_outlined, 'NIN: ${user.nin}'),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _contactRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 14),
          const SizedBox(width: 10),
          Text(value, style: TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
        ],
      ),
    );
  }

  // ── Bids List Section ─────────────────────────────────────────────────────
  Widget _buildBidsListSection() {
    final role = widget.currentUserRole;

    return FutureBuilder<UserModel?>(
      future: _sellerFuture,
      builder: (ctx, farmerSnap) {
        final farmer = farmerSnap.data;
        final canSeeBids = role == 'Admin' ||
            role == 'Registry' ||
            (role == 'Agent' && farmer?.agentId == widget.currentUserId);

        if (!canSeeBids) return const SizedBox.shrink();

        final formatter = NumberFormat('#,###');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bids placed on this listing',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<BidModel>>(
              stream: _db.streamBidsByProduct(widget.product.id),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                        child: CircularProgressIndicator(color: AppTheme.green)),
                  );
                }
                if (snap.hasError) {
                  return const AppErrorState(title: 'Unable to load bids');
                }
                final bids = snap.data ?? [];
                if (bids.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border, width: 0.5),
                    ),
                    child: Center(
                      child: Text(
                        'No bids have been submitted yet.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bids.length,
                  itemBuilder: (ctx, idx) => _bidTile(bids[idx], formatter),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _bidTile(BidModel bid, NumberFormat formatter) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.border, width: 0.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          (bid.buyerName.isNotEmpty ? bid.buyerName : 'Buyer') +
              (bid.buyerPhone.isNotEmpty ? ' • ${bid.buyerPhone}' : ''),
          style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Qty: ${bid.quantity}  •  UGX ${formatter.format(bid.offeredPrice)}',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ),
        trailing: BidStatusBadge(status: bid.status),
      ),
    );
  }

  // ── More listings by same farmer ──────────────────────────────────────────
  Widget _buildMoreFromSellerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'More listings from this farmer',
          style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<ProductModel>>(
          stream: _db.streamProductsBySeller(widget.product.sellerId),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 120,
                child: Center(
                    child: CircularProgressIndicator(color: AppTheme.green)),
              );
            }
            if (snap.hasError || !snap.hasData) {
              return const SizedBox.shrink();
            }

            final otherProducts = snap.data!
                .where((p) => p.id != widget.product.id)
                .toList();

            if (otherProducts.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border, width: 0.5),
                ),
                child: Center(
                  child: Text(
                    'No other active listings found.',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                ),
              );
            }

            final viewportWidth = MediaQuery.sizeOf(context).width;
            final isDesktop = viewportWidth >= AppBreakpoints.desktop;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              gridDelegate: responsiveGridDelegate(
                context,
                compactExtent: 170,
                desktopExtent: 220,
                compactAspectRatio: 0.65,
                desktopAspectRatio: 0.72,
                spacing: isDesktop ? 16 : 10,
              ),
              itemCount: otherProducts.length,
              itemBuilder: (ctx, i) {
                final p = otherProducts[i];
                return ProductCard(
                  product: p,
                  compact: true,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(
                          product: p,
                          currentUserId: widget.currentUserId,
                          currentUserRole: widget.currentUserRole,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  // ── Image builder widget ──────────────────────────────────────────────────
  Widget _buildImage(String url) {
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => Container(
          color: AppTheme.surfaceLight,
          child: Icon(Icons.broken_image_rounded, color: AppTheme.textMuted, size: 36),
        ),
      );
    }
    return AppNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: Container(
        color: AppTheme.surfaceLight,
        child: const Center(
            child: CircularProgressIndicator(
                color: AppTheme.green, strokeWidth: 2)),
      ),
      errorWidget: Container(
        color: AppTheme.surfaceLight,
        child: Icon(Icons.broken_image_rounded, color: AppTheme.textMuted, size: 36),
      ),
    );
  }
}

// ── Full Screen Image Gallery Widget ────────────────────────────────────────
class _FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const _FullScreenGallery({required this.images, required this.initialIndex});

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late PageController _controller;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_current + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _controller,
        onPageChanged: (i) => setState(() => _current = i),
        itemCount: widget.images.length,
        itemBuilder: (ctx, i) {
          final url = widget.images[i];
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: url.startsWith('assets/')
                  ? Image.asset(url, fit: BoxFit.contain)
                  : AppNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.contain,
                      placeholder: const Center(
                        child: CircularProgressIndicator(color: AppTheme.green),
                      ),
                      errorWidget: const Icon(Icons.broken_image_outlined,
                          color: Colors.white54, size: 64),
                    ),
            ),
          );
        },
      ),
    );
  }
}
