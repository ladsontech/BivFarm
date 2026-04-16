import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/demo_data.dart';
import '../../services/theme_provider.dart';
import '../../theme/app_theme.dart';
import 'demo_marketplace.dart';
import 'demo_bids.dart';
import 'demo_admin.dart';
import '../messaging/farmer_messages_screen.dart';

class DemoHome extends StatefulWidget {
  const DemoHome({super.key});

  @override
  State<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> {
  int _navIndex = 0;
  String _currentRole = 'Buyer';

  UserModel get _currentUser {
    switch (_currentRole) {
      case 'Farmer':
        return DemoData.demoFarmer;
      case 'Buyer':
        return DemoData.demoBuyer;
      case 'Agent':
        return DemoData.demoAgent;
      case 'Admin':
        return DemoData.demoAdmin;
      default:
        return DemoData.demoBuyer;
    }
  }

  List<Widget> get _screens {
    final u = _currentUser;
    switch (_currentRole) {
      case 'Admin':
        return [
          DemoMarketplaceScreen(userRole: u.role, userId: u.id),
          DemoBidsScreen(userId: u.id, userRole: u.role),
          const DemoAdminScreen(),
        ];
      case 'Farmer':
        return [
          DemoMarketplaceScreen(userRole: u.role, userId: u.id),
          FarmerMessagesScreen(userId: u.id),
        ];
      default:
        return [
          DemoMarketplaceScreen(userRole: u.role, userId: u.id),
          DemoBidsScreen(userId: u.id, userRole: u.role),
        ];
    }
  }

  List<BottomNavigationBarItem> get _navItems {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Market'),
      if (_currentRole == 'Farmer')
        const BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Messages')
      else
        BottomNavigationBarItem(icon: const Icon(Icons.gavel), label: _currentRole == 'Admin' ? 'Bids' : 'My Bids'),
    ];
    if (_currentRole == 'Admin') {
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Admin'));
    }
    return items;
  }

  void _showRoleSwitcher() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Switch Role', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              Text('Preview the app as different user types', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              SizedBox(height: 20),
              ...['Farmer', 'Buyer', 'Admin'].map((role) {
                final selected = _currentRole == role;
                final user = role == 'Farmer' ? DemoData.demoFarmer : role == 'Buyer' ? DemoData.demoBuyer : DemoData.demoAdmin;
                return GestureDetector(
                  onTap: () {
                    setState(() { _currentRole = role; _navIndex = 0; });
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.greenSurface : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? AppTheme.green : AppTheme.border, width: selected ? 1.5 : 0.5),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: selected ? AppTheme.green.withOpacity(0.3) : AppTheme.surface,
                          child: Icon(_getRoleIcon(role), color: selected ? AppTheme.greenLight : AppTheme.textMuted, size: 20),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(role, style: TextStyle(color: selected ? AppTheme.greenLight : AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                              Text(user.name, style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                        if (selected) Icon(Icons.check_circle, color: AppTheme.greenLight, size: 20),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Farmer': return Icons.grass;
      case 'Buyer': return Icons.shopping_bag_outlined;
      case 'Agent': return Icons.people;
      case 'Admin': return Icons.admin_panel_settings;
      default: return Icons.person;
    }
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
          // Theme toggle
          IconButton(
            icon: Icon(
              Provider.of<ThemeProvider>(context).isDark ? Icons.light_mode : Icons.dark_mode,
              color: AppTheme.textMuted,
              size: 20,
            ),
            onPressed: () => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
            tooltip: 'Switch theme',
          ),
          // Role Badge
          GestureDetector(
            onTap: _showRoleSwitcher,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.greenSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getRoleIcon(_currentRole), color: AppTheme.greenLight, size: 14),
                  SizedBox(width: 6),
                  Text(_currentRole, style: TextStyle(color: AppTheme.greenLight, fontSize: 12, fontWeight: FontWeight.w600)),
                  SizedBox(width: 4),
                  Icon(Icons.swap_vert, color: AppTheme.greenLight, size: 14),
                ],
              ),
            ),
          ),
          // User avatar
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _showRoleSwitcher,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.surfaceLight,
                child: Text(
                  _currentUser.name.isNotEmpty ? _currentUser.name[0].toUpperCase() : '?',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _navIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: AppTheme.border, width: 0.5))),
        child: BottomNavigationBar(
          currentIndex: _navIndex,
          onTap: (i) => setState(() => _navIndex = i),
          items: _navItems,
        ),
      ),
    );
  }
}
