import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/network_image_widget.dart';
import 'marketplace/marketplace_screen.dart';
import 'marketplace/add_product_screen.dart';
import 'bidding/bids_list_screen.dart';
import 'agent/agent_dashboard_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'messaging/farmer_messages_screen.dart';
import 'profile/profile_screen.dart';
import 'marketplace/categories_screen.dart';
import 'auth/onboarding_screen.dart';
import 'auth/login_screen.dart';
import 'notifications/notifications_screen.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  final GlobalKey<State<MarketplaceScreen>> _marketKey = GlobalKey();

  void _onCategorySelected(String category) {
    setState(() {
      _currentIndex = 0; // Switch to Marketplace tab
    });
    // Use post frame callback to ensure the state is available if we just switched
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final marketState = _marketKey.currentState;
      if (marketState != null) {
        // Use forced dynamic cast to access the custom method on the private state class
        (marketState as dynamic).applyExternalFilter(category);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final uid = authService.currentUser?.uid;

    if (uid == null) return const LoginScreen();

    return StreamBuilder<UserModel?>(
      stream: DatabaseService().streamUser(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          // User exists in Firebase Auth but has no Firestore profile yet
          return _NewUserRoleSelector(
            uid: uid,
            email: authService.currentUser?.email,
            onSignOut: () => authService.signOut(),
          );
        }

        // Redirect to Onboarding if profile not complete
        if (!user.isProfileComplete) {
          return OnboardingScreen(userId: user.id);
        }

        // Store FCM token for push notifications
        NotificationService().storeToken(user.id);

        final screens = _getScreens(user);
        final navItems = _getNavItems(user);

        // Clamp index
        final safeIndex = _currentIndex.clamp(0, screens.length - 1);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 800;

            final actions = [
              StreamBuilder<List<NotificationModel>>(
                stream: DatabaseService().streamNotifications(user.id),
                builder: (context, snap) {
                  final unreadCount = snap.data?.where((n) => !n.isRead).length ?? 0;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.notifications_none, color: AppTheme.textPrimary),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => NotificationsScreen(userId: user.id)),
                          );
                        },
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppTheme.error,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 8),
            ];

            if (isDesktop) {
              return Scaffold(
                body: Row(
                  children: [
                    NavigationRail(
                      selectedIndex: safeIndex,
                      onDestinationSelected: (i) => setState(() => _currentIndex = i),
                      labelType: NavigationRailLabelType.all,
                      backgroundColor: AppTheme.surfaceLight,
                      selectedIconTheme: const IconThemeData(color: AppTheme.green),
                      selectedLabelTextStyle: const TextStyle(color: AppTheme.green, fontWeight: FontWeight.bold),
                      unselectedIconTheme: IconThemeData(color: AppTheme.textMuted),
                      unselectedLabelTextStyle: TextStyle(color: AppTheme.textMuted),
                      leading: Padding(
                        padding: const EdgeInsets.only(bottom: 20, top: 10),
                        child: Image.asset('assets/images/Bfarm_icon.png', height: 48),
                      ),
                      destinations: navItems.map((item) => NavigationRailDestination(
                        icon: item.icon,
                        label: Text(item.label ?? ''),
                      )).toList(),
                    ),
                    VerticalDivider(thickness: 1, width: 1, color: AppTheme.border),
                    Expanded(
                      child: Scaffold(
                        appBar: AppBar(
                          toolbarHeight: 64,
                          title: Text('BivFarm Dashboard', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
                          actions: actions,
                        ),
                        body: IndexedStack(index: safeIndex, children: screens),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Scaffold(
              appBar: AppBar(
                toolbarHeight: 64,
                title: Image.asset(
                  'assets/images/Bfarm_icon.png',
                  height: 64,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                ),
                actions: actions,
              ),
              body: IndexedStack(
                index: safeIndex,
                children: screens,
              ),
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
                ),
                child: BottomNavigationBar(
                  currentIndex: safeIndex,
                  onTap: (i) => setState(() => _currentIndex = i),
                  type: BottomNavigationBarType.fixed,
                  selectedFontSize: 11,
                  unselectedFontSize: 10,
                  items: navItems,
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _getScreens(UserModel user) {
    switch (user.role) {
      case 'Admin':
        return [
          MarketplaceScreen(key: _marketKey, userRole: user.role, userId: user.id),
          CategoriesScreen(onCategorySelected: _onCategorySelected),
          BidsListScreen(userId: user.id, userRole: user.role),
          const AdminDashboardScreen(),
          ProfileScreen(user: user),
        ];
      case 'Registry':
        return [
          MarketplaceScreen(key: _marketKey, userRole: user.role, userId: user.id),
          CategoriesScreen(onCategorySelected: _onCategorySelected),
          BidsListScreen(userId: user.id, userRole: user.role),
          const AdminDashboardScreen(),
          ProfileScreen(user: user),
        ];
      case 'Agent':
        return [
          MarketplaceScreen(key: _marketKey, userRole: user.role, userId: user.id),
          CategoriesScreen(onCategorySelected: _onCategorySelected),
          BidsListScreen(userId: user.id, userRole: user.role),
          AgentDashboardScreen(agentId: user.id),
          ProfileScreen(user: user),
        ];
      case 'Farmer':
        return [
          MarketplaceScreen(key: _marketKey, userRole: user.role, userId: user.id),
          CategoriesScreen(onCategorySelected: _onCategorySelected),
          _FarmerListingsTab(userId: user.id),
          FarmerMessagesScreen(userId: user.id),
          ProfileScreen(user: user),
        ];
      case 'Buyer':
        return [
          MarketplaceScreen(key: _marketKey, userRole: user.role, userId: user.id),
          CategoriesScreen(onCategorySelected: _onCategorySelected),
          BidsListScreen(userId: user.id, userRole: user.role),
          ProfileScreen(user: user),
        ];
      default:
        return [
          MarketplaceScreen(userRole: user.role, userId: user.id),
          ProfileScreen(user: user),
        ];
    }
  }

  List<BottomNavigationBarItem> _getNavItems(UserModel user) {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Market'),
      const BottomNavigationBarItem(icon: Icon(Icons.category_outlined), label: 'Categories'),
    ];

    switch (user.role) {
      case 'Admin':
        items.addAll([
          const BottomNavigationBarItem(icon: Icon(Icons.gavel), label: 'Bids'),
          const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Admin'),
        ]);
        break;
      case 'Registry':
        items.addAll([
          const BottomNavigationBarItem(icon: Icon(Icons.gavel), label: 'Bids'),
          const BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Registry'),
        ]);
        break;
      case 'Agent':
        items.addAll([
          const BottomNavigationBarItem(icon: Icon(Icons.gavel), label: 'Bids'),
          const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Dashboard'),
        ]);
        break;
      case 'Farmer':
        items.addAll([
          const BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Listings'),
          const BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Messages'),
        ]);
        break;
      case 'Buyer':
        items.add(const BottomNavigationBarItem(icon: Icon(Icons.gavel), label: 'My Bids'));
        break;
    }

    // All roles get a Profile tab
    items.add(const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'));

    return items;
  }
}

// ─── Farmer Listings Tab (embedded, no AppBar) ───────────
class _FarmerListingsTab extends StatelessWidget {
  final String userId;
  const _FarmerListingsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    return StreamBuilder(
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
                Icon(Icons.inventory_2_outlined, color: AppTheme.textMuted.withOpacity(0.3), size: 64),
                const SizedBox(height: 16),
                Text('No listings yet', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                const SizedBox(height: 6),
                Text(
                  'Start selling by creating your first listing',
                  style: TextStyle(color: AppTheme.textMuted.withOpacity(0.6), fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductScreen(sellerId: userId)));
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create Listing'),
                ),
              ],
            ),
          );
        }
        return Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: products.length,
              itemBuilder: (ctx, i) {
                final p = products[i];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddProductScreen(sellerId: userId, existingProduct: p)),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppTheme.greenSurface,
                            borderRadius: BorderRadius.circular(10),
                            image: p.imageUrl != null
                                ? DecorationImage(
                                    image: p.imageUrl!.startsWith('assets/')
                                        ? AssetImage(p.imageUrl!) as ImageProvider
                                        : appNetworkImageProvider(p.imageUrl!),
                                    fit: BoxFit.cover)
                                : null,
                          ),
                          child: p.imageUrl == null ? const Icon(Icons.eco, color: AppTheme.greenLight) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.productName, style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text('${p.quantity} ${p.quantityUnit} • ${p.district}', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'UGX ${p.price.toStringAsFixed(0)}',
                              style: const TextStyle(color: AppTheme.greenLight, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: p.availability == 'Available Now' ? AppTheme.greenSurface : AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                p.availability,
                                style: TextStyle(
                                  color: p.availability == 'Available Now' ? AppTheme.greenLight : AppTheme.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Floating Add button
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'addListing',
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductScreen(sellerId: userId)));
                },
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── New User Role Selector (for Firebase Auth users without Firestore profile) ───
class _NewUserRoleSelector extends StatefulWidget {
  final String uid;
  final String? email;
  final VoidCallback onSignOut;

  const _NewUserRoleSelector({
    required this.uid,
    this.email,
    required this.onSignOut,
  });

  @override
  State<_NewUserRoleSelector> createState() => _NewUserRoleSelectorState();
}

class _NewUserRoleSelectorState extends State<_NewUserRoleSelector> {
  String? _selectedRole;
  bool _loading = false;

  Future<void> _createProfile() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role to continue')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await DatabaseService().setUser(widget.uid, {
        'id': widget.uid,
        'email': widget.email ?? '',
        'role': _selectedRole,
        'name': '',
        'firstName': '',
        'lastName': '',
        'phone': '',
        'district': '',
        'profilePhoto': '',
        'isProfileComplete': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
      // StreamBuilder in HomeShell will automatically detect the new doc
      // and route to OnboardingScreen since isProfileComplete is false
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating profile: $e')),
        );
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const Icon(Icons.agriculture, color: AppTheme.green, size: 64),
              const SizedBox(height: 20),
              Text(
                'Welcome to BivFarm!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'How would you like to use BivFarm?',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 40),

              // Role cards
              _RoleCard(
                icon: Icons.eco,
                title: 'Farmer',
                subtitle: 'I want to sell my produce',
                isSelected: _selectedRole == 'Farmer',
                onTap: () => setState(() => _selectedRole = 'Farmer'),
              ),
              const SizedBox(height: 14),
              _RoleCard(
                icon: Icons.shopping_bag,
                title: 'Buyer',
                subtitle: 'I want to buy from farmers',
                isSelected: _selectedRole == 'Buyer',
                onTap: () => setState(() => _selectedRole = 'Buyer'),
              ),

              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _createProfile,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Continue', style: TextStyle(fontSize: 16)),
                ),
              ),
              const Spacer(flex: 3),

              // Sign out link
              TextButton(
                onPressed: widget.onSignOut,
                child: Text(
                  'Sign out',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.greenSurface : AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.green : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.green.withOpacity(0.15)
                    : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.green : AppTheme.textMuted,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.green, size: 26),
          ],
        ),
      ),
    );
  }
}
