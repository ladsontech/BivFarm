import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/network_image_widget.dart';
import '../widgets/common_widgets.dart';
import '../widgets/responsive_wrapper.dart';
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
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import '../widgets/my_listings_tab.dart';
import 'common/management_screen.dart';
import '../widgets/floating_message_widget.dart';
import 'orders/bulk_order_form_screen.dart';
import 'marketplace/product_detail_screen.dart';
import 'common/registration_screens.dart';
import '../widgets/registry_bids_tab.dart';
import '../widgets/registry_database_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final ValueNotifier<int> _currentIndexNotifier = ValueNotifier<int>(0);
  final MarketplaceController _marketController = MarketplaceController();
  final GlobalKey<NavigatorState> _desktopNavKey = GlobalKey<NavigatorState>();
  String? _selectedCategoryForTab;
  String? _tokenStoredForUser;
  int _profileRetryVersion = 0;

  void _onCategorySelected(String category) {
    _marketController.showCategory(category);
    _currentIndexNotifier.value = 0;
  }

  @override
  void dispose() {
    _currentIndexNotifier.dispose();
    _marketController.dispose();
    super.dispose();
  }

  void _onViewAllCategory(String category) {
    final isDesktop = MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;
    if (isDesktop) {
      _marketController.showCategory(category);
      _currentIndexNotifier.value = 0;
    } else {
      // Go to Categories tab (index 1) with the selected category pre-loaded
      setState(() => _selectedCategoryForTab = category);
      _currentIndexNotifier.value = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final uid = authService.currentUser?.uid;

    if (uid == null) return const LoginScreen();

    return StreamBuilder<UserModel?>(
      key: ValueKey(_profileRetryVersion),
      stream: DatabaseService().streamUser(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: AppErrorState(
              title: 'Unable to load your account',
              onRetry: () => setState(() => _profileRetryVersion++),
            ),
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
        if (!kIsWeb && _tokenStoredForUser != user.id) {
          _tokenStoredForUser = user.id;
          unawaited(
            NotificationService()
                .storeToken(user.id)
                .catchError((error, stack) {
              debugPrint('Unable to store notification token: $error');
            }),
          );
        }

        return ValueListenableBuilder<int>(
          valueListenable: _currentIndexNotifier,
          builder: (context, currentIndex, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop =
                    constraints.maxWidth >= AppBreakpoints.desktop;
                final showExtendedRail =
                    constraints.maxWidth >= AppBreakpoints.wide;

                final actions = [
                  StreamBuilder<List<NotificationModel>>(
                    stream: DatabaseService().streamNotifications(user.id),
                    builder: (context, snap) {
                      final unreadCount =
                          snap.data?.where((n) => !n.isRead).length ?? 0;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_none,
                                color: Colors.white),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        NotificationsScreen(userId: user.id)),
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
                                constraints: const BoxConstraints(
                                    minWidth: 16, minHeight: 16),
                                child: Text(
                                  unreadCount > 9 ? '9+' : '$unreadCount',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
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

                final List<BottomNavigationBarItem> navItems = [];
                final List<Widget> screens = [];

                if (isDesktop && (user.role == 'Admin' || user.role == 'Registry')) {
                  // Marketplace
                  navItems.add(const BottomNavigationBarItem(
                      icon: Icon(Icons.storefront), label: 'Market'));
                  screens.add(MarketplaceScreen(
                      controller: _marketController,
                      userRole: user.role,
                      userId: user.id,
                      actions: actions,
                      onViewAllCategory: _onViewAllCategory));

                  // Admin Dashboard options (Flattened directly into main sidebar)
                  navItems.addAll([
                    const BottomNavigationBarItem(
                        icon: Icon(Icons.gavel_outlined), label: 'Bids & Orders'),
                    const BottomNavigationBarItem(
                        icon: Icon(Icons.storage_outlined), label: 'Registry Database'),
                    const BottomNavigationBarItem(
                        icon: Icon(Icons.people_outline), label: 'Users'),
                    const BottomNavigationBarItem(
                        icon: Icon(Icons.person_outline), label: 'Agents'),
                    const BottomNavigationBarItem(
                        icon: Icon(Icons.agriculture_outlined), label: 'Create Farmer'),
                    const BottomNavigationBarItem(
                        icon: Icon(Icons.groups_outlined), label: 'Create Group'),
                    const BottomNavigationBarItem(
                        icon: Icon(Icons.storefront_outlined), label: 'Register Store'),
                    const BottomNavigationBarItem(
                        icon: Icon(Icons.business_outlined), label: 'Register Dealer'),
                    const BottomNavigationBarItem(
                        icon: Icon(Icons.inventory_2_outlined), label: 'My Listings'),
                  ]);

                  screens.addAll([
                    RegistryBidsTab(db: DatabaseService()),
                    RegistryDatabaseTab(db: DatabaseService()),
                    AdminUsersList(db: DatabaseService()),
                    AdminAgentsList(db: DatabaseService()),
                    RegisterUserScreen(role: 'Farmer', agentId: user.id),
                    RegisterGroupScreen(agentId: user.id),
                    RegisterStoreScreen(agentId: user.id),
                    RegisterDealerScreen(agentId: user.id),
                    MyListingsTab(userId: user.id),
                  ]);

                  // Profile
                  navItems.add(const BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline), label: 'Profile'));
                  screens.add(ProfileScreen(user: user));

                } else {
                  final baseNavItems = _getNavItems(user);
                  final baseScreens = _getScreens(user, actions);

                  for (int i = 0; i < baseNavItems.length; i++) {
                    if (isDesktop && baseNavItems[i].label == 'Categories') {
                      continue;
                    }
                    navItems.add(baseNavItems[i]);
                    if (i < baseScreens.length) {
                      screens.add(baseScreens[i]);
                    }
                  }
                }

                // Clamp index
                final safeIndex = currentIndex.clamp(0, navItems.length - 1);

                if (isDesktop) {
                  return Scaffold(
                    body: Row(
                      children: [
                        NavigationRail(
                          extended: showExtendedRail,
                          minExtendedWidth: 220,
                          selectedIndex: safeIndex,
                          onDestinationSelected: (i) {
                            // If we are deep into the nested navigator, pop back to root when switching tabs
                            if (_desktopNavKey.currentState?.canPop() ??
                                false) {
                              _desktopNavKey.currentState
                                  ?.popUntil((route) => route.isFirst);
                            }
                            _currentIndexNotifier.value = i;
                          },
                          labelType: showExtendedRail
                              ? NavigationRailLabelType.none
                              : NavigationRailLabelType.all,
                          backgroundColor: AppTheme.surfaceLight,
                          selectedIconTheme:
                              const IconThemeData(color: AppTheme.green),
                          selectedLabelTextStyle: const TextStyle(
                              color: AppTheme.green,
                              fontWeight: FontWeight.bold),
                          unselectedIconTheme:
                              IconThemeData(color: AppTheme.textMuted),
                          unselectedLabelTextStyle:
                              TextStyle(color: AppTheme.textMuted),
                          leading: Padding(
                            padding: const EdgeInsets.only(bottom: 20, top: 10),
                            child: Image.asset('assets/images/Bfarm_icon.png',
                                height: 48),
                          ),
                          destinations: navItems
                              .map((item) => NavigationRailDestination(
                                    icon: item.icon,
                                    label: Text(item.label ?? ''),
                                  ))
                              .toList(),
                        ),
                        VerticalDivider(
                            thickness: 1, width: 1, color: AppTheme.border),
                        Expanded(
                          child: Navigator(
                            key: _desktopNavKey,
                            onGenerateRoute: (settings) {
                              return MaterialPageRoute(
                                builder: (context) {
                                  return ValueListenableBuilder<int>(
                                    valueListenable: _currentIndexNotifier,
                                    builder: (context, idx, _) {
                                      final safeIdx =
                                          idx.clamp(0, screens.length - 1);
                                      final hideAppBar =
                                          screens[safeIdx] is MarketplaceScreen ||
                                          screens[safeIdx] is CategoriesScreen ||
                                          screens[safeIdx] is ProfileScreen ||
                                          screens[safeIdx] is AdminDashboardScreen ||
                                          screens[safeIdx] is AgentDashboardScreen;

                                      return Scaffold(
                                        appBar: !hideAppBar
                                            ? AppBar(
                                                toolbarHeight: 64,
                                                title: Text(
                                                    navItems[safeIdx].label ??
                                                        'BFarm',
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w700)),
                                                actions: actions,
                                              )
                                            : null,
                                        body: IndexedStack(
                                            index: safeIdx, children: screens),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Stack(
                  children: [
                    Scaffold(
                      appBar: (safeIndex == 0 ||
                              safeIndex == 1 ||
                              screens[safeIndex] is AdminDashboardScreen ||
                              screens[safeIndex] is AgentDashboardScreen ||
                              screens[safeIndex] is ProfileScreen)
                          ? null
                          : AppBar(
                              toolbarHeight: 64,
                              title: Image.asset(
                                'assets/images/bfarm_premium_logo.png',
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
                      bottomNavigationBar:
                          _buildCustomBottomNav(safeIndex, navItems, context),
                    ),
                    if (safeIndex == 0) FloatingMessageWidget(userId: user.id),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCustomBottomNav(int currentIndex,
      List<BottomNavigationBarItem> items, BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: AppTheme.border, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = currentIndex == index;

          return Expanded(
            child: InkWell(
              onTap: () => _currentIndexNotifier.value = index,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: IconTheme(
                      data: IconThemeData(
                        color: isSelected ? AppTheme.green : AppTheme.textMuted,
                        size: 24,
                      ),
                      child: item.icon,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: isSelected ? AppTheme.green : AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                    child: Text(item.label ?? ''),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  List<Widget> _getScreens(UserModel user, List<Widget> actions) {
    switch (user.role) {
      case 'Admin':
        return [
          MarketplaceScreen(
              controller: _marketController,
              userRole: user.role,
              userId: user.id,
              actions: actions,
              onViewAllCategory: _onViewAllCategory),
          CategoriesScreen(
              onCategorySelected: _onCategorySelected,
              initialCategory: _selectedCategoryForTab,
              currentUserId: user.id,
              currentUserRole: user.role,
              onProductSelected: (p) => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(
                        product: p,
                        currentUserId: user.id,
                        currentUserRole: user.role),
                  ))),
          const AdminDashboardScreen(),
          ProfileScreen(user: user),
        ];
      case 'Registry':
        return [
          MarketplaceScreen(
              controller: _marketController,
              userRole: user.role,
              userId: user.id,
              actions: actions,
              onViewAllCategory: _onViewAllCategory),
          CategoriesScreen(
              onCategorySelected: _onCategorySelected,
              initialCategory: _selectedCategoryForTab,
              currentUserId: user.id,
              currentUserRole: user.role,
              onProductSelected: (p) => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(
                        product: p,
                        currentUserId: user.id,
                        currentUserRole: user.role),
                  ))),
          BidsListScreen(userId: user.id, userRole: user.role),
          const AdminDashboardScreen(),
          ProfileScreen(user: user),
        ];
      case 'Agent':
        return [
          MarketplaceScreen(
              controller: _marketController,
              userRole: user.role,
              userId: user.id,
              actions: actions,
              onViewAllCategory: _onViewAllCategory),
          CategoriesScreen(
              onCategorySelected: _onCategorySelected,
              initialCategory: _selectedCategoryForTab,
              currentUserId: user.id,
              currentUserRole: user.role,
              onProductSelected: (p) => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(
                        product: p,
                        currentUserId: user.id,
                        currentUserRole: user.role),
                  ))),
          BidsListScreen(userId: user.id, userRole: user.role),
          AgentDashboardScreen(agentId: user.id),
          ProfileScreen(user: user),
        ];
      case 'Farmer':
        return [
          MarketplaceScreen(
              controller: _marketController,
              userRole: user.role,
              userId: user.id,
              actions: actions,
              onViewAllCategory: _onViewAllCategory),
          CategoriesScreen(
              onCategorySelected: _onCategorySelected,
              initialCategory: _selectedCategoryForTab,
              currentUserId: user.id,
              currentUserRole: user.role,
              onProductSelected: (p) => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(
                        product: p,
                        currentUserId: user.id,
                        currentUserRole: user.role),
                  ))),
          ManagementScreen(user: user),
          ProfileScreen(user: user),
        ];
      case 'Buyer':
        return [
          MarketplaceScreen(
              controller: _marketController,
              userRole: user.role,
              userId: user.id,
              actions: actions,
              onViewAllCategory: _onViewAllCategory),
          CategoriesScreen(
              onCategorySelected: _onCategorySelected,
              initialCategory: _selectedCategoryForTab,
              currentUserId: user.id,
              currentUserRole: user.role,
              onProductSelected: (p) => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(
                        product: p,
                        currentUserId: user.id,
                        currentUserRole: user.role),
                  ))),
          BidsListScreen(userId: user.id, userRole: user.role),
          ProfileScreen(user: user),
        ];
      case 'Store':
        return [
          MarketplaceScreen(
              controller: _marketController,
              userRole: user.role,
              userId: user.id,
              actions: actions,
              onViewAllCategory: _onViewAllCategory),
          CategoriesScreen(
              onCategorySelected: _onCategorySelected,
              initialCategory: _selectedCategoryForTab,
              currentUserId: user.id,
              currentUserRole: user.role,
              onProductSelected: (p) => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(
                        product: p,
                        currentUserId: user.id,
                        currentUserRole: user.role),
                  ))),
          ManagementScreen(
              user: user, initialTabIndex: 1), // Default to Listings for Store
          ProfileScreen(user: user),
        ];
      default:
        return [
          MarketplaceScreen(
            controller: _marketController,
            userRole: user.role,
            userId: user.id,
            actions: actions,
          ),
          ProfileScreen(user: user),
        ];
    }
  }

  List<BottomNavigationBarItem> _getNavItems(UserModel user) {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
          icon: Icon(Icons.storefront), label: 'Market'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.category_outlined), label: 'Categories'),
    ];

    switch (user.role) {
      case 'Admin':
        items.addAll([
          const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Admin'),
        ]);
        break;
      case 'Registry':
        items.addAll([
          const BottomNavigationBarItem(icon: Icon(Icons.gavel), label: 'Bids'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.assignment), label: 'Registry'),
        ]);
        break;
      case 'Agent':
        items.addAll([
          const BottomNavigationBarItem(
              icon: Icon(Icons.gavel), label: 'My Bids'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.people), label: 'Dashboard'),
        ]);
        break;
      case 'Farmer':
        items.add(const BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined), label: 'Manage'));
        break;
      case 'Buyer':
        items.add(const BottomNavigationBarItem(
            icon: Icon(Icons.gavel), label: 'My Bids'));
        break;
      case 'Store':
        items.add(const BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined), label: 'Manage'));
        break;
    }

    // All roles get a Profile tab
    items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline), label: 'Profile'));

    return items;
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
                'Welcome to BFarm!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'How would you like to use BFarm?',
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
