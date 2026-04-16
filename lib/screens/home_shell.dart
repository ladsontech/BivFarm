import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'marketplace/marketplace_screen.dart';
import 'bidding/bids_list_screen.dart';
import 'agent/agent_dashboard_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin/registry_dashboard_screen.dart';
import 'messaging/farmer_messages_screen.dart';
import 'marketplace/add_product_screen.dart';

class HomeShell extends StatefulWidget {
  final UserModel user;

  const HomeShell({super.key, required this.user});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  final _auth = AuthService();

  List<Widget> get _screens {
    switch (widget.user.role) {
      case 'Admin':
        return [
          MarketplaceScreen(userRole: widget.user.role, userId: widget.user.id),
          BidsListScreen(userId: widget.user.id, userRole: widget.user.role),
          const AdminDashboardScreen(),
        ];
      case 'Registry':
        return [
          MarketplaceScreen(userRole: widget.user.role, userId: widget.user.id),
          BidsListScreen(userId: widget.user.id, userRole: widget.user.role),
          const RegistryDashboardScreen(),
        ];
      case 'Agent':
        return [
          MarketplaceScreen(userRole: widget.user.role, userId: widget.user.id),
          AgentDashboardScreen(agentId: widget.user.id),
        ];
      case 'Farmer':
        return [
          MarketplaceScreen(userRole: widget.user.role, userId: widget.user.id),
          FarmerMessagesScreen(userId: widget.user.id),
        ];
      case 'Buyer':
        return [
          MarketplaceScreen(userRole: widget.user.role, userId: widget.user.id),
          BidsListScreen(userId: widget.user.id, userRole: widget.user.role),
        ];
      default:
        return [
          MarketplaceScreen(userRole: widget.user.role, userId: widget.user.id),
        ];
    }
  }

  List<BottomNavigationBarItem> get _navItems {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Market'),
    ];

    switch (widget.user.role) {
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
        items.add(
          const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Dashboard'),
        );
        break;
      case 'Farmer':
        items.add(
          const BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Messages'),
        );
        break;
      case 'Buyer':
        items.add(
          const BottomNavigationBarItem(icon: Icon(Icons.gavel), label: 'My Bids'),
        );
        break;
      default:
        break;
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: Image.asset(
          'assets/images/Bfarm_icon.png',
          height: 64,
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
        ),
        actions: [
          // My Listings (Farmer)
          if (widget.user.role == 'Farmer')
            IconButton(
              icon: const Icon(Icons.inventory_2_outlined),
              tooltip: 'My Listings',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _MyListingsScreen(userId: widget.user.id),
                  ),
                );
              },
            ),
          // Profile
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.surfaceLight,
              backgroundImage: widget.user.profilePhoto != null ? NetworkImage(widget.user.profilePhoto!) : null,
              child: widget.user.profilePhoto == null
                  ? Text(
                      widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : '?',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600),
                    )
                  : null,
            ),
            color: AppTheme.surface,
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.user.name, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                    Text(widget.user.role, style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    Text(widget.user.district, style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: Row(
                children: [
                  Icon(Icons.logout, size: 18, color: AppTheme.error),
                  SizedBox(width: 8),
                  Text('Sign Out', style: TextStyle(color: AppTheme.error)),
                ],
              )),
            ],
            onSelected: (v) {
              if (v == 'logout') _auth.signOut();
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: _navItems,
        ),
      ),
    );
  }
}

// ─── My Listings Screen (Farmer) ─────────────────────
class _MyListingsScreen extends StatelessWidget {
  final String userId;
  const _MyListingsScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    return Scaffold(
      appBar: AppBar(title: Text('My Listings')),
      body: StreamBuilder(
        stream: db.streamProductsBySeller(userId),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppTheme.green));
          }
          final products = snap.data ?? [];
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined, color: AppTheme.textMuted.withOpacity(0.3), size: 64),
                  SizedBox(height: 16),
                  Text('No listings yet', style: TextStyle(color: AppTheme.textMuted)),
                  const SizedBox(height: 12),
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
          return ListView.builder(
            padding: const EdgeInsets.all(16),
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
                                      : NetworkImage(p.imageUrl!),
                                  fit: BoxFit.cover)
                              : null,
                        ),
                        child: p.imageUrl == null ? Icon(Icons.eco, color: AppTheme.greenLight) : null,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.productName, style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                            Text('${p.quantity} ${p.quantityUnit} • ${p.district}', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('UGX ${p.price.toStringAsFixed(0)} / ${p.quantityUnit.toLowerCase() == 'pieces' ? 'Piece' : (p.quantityUnit.toLowerCase() == 'crates' ? 'Crate' : p.quantityUnit)}', style: TextStyle(color: AppTheme.greenLight, fontSize: 13, fontWeight: FontWeight.w600)),
                          SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: p.availability == 'Available Now' ? AppTheme.greenSurface : AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(p.availability, style: TextStyle(color: p.availability == 'Available Now' ? AppTheme.greenLight : AppTheme.textMuted, fontSize: 10)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductScreen(sellerId: userId)));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
