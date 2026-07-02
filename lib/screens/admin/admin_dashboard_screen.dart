import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/input_dealer_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/registry_bids_tab.dart';
import '../../widgets/registry_database_tab.dart';
import '../../widgets/my_listings_tab.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/responsive_wrapper.dart';
import '../common/registration_screens.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _db = DatabaseService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedMenuIndex = 0;

  static const _menuItems = <_MenuItem>[
    _MenuItem('Bids & Orders', Icons.gavel_outlined),
    _MenuItem('Registry Database', Icons.storage_outlined),
    _MenuItem('Users', Icons.people_outline),
    _MenuItem('Agents', Icons.person_outline),
    _MenuItem('Create Farmer', Icons.agriculture_outlined),
    _MenuItem('Create Group', Icons.groups_outlined),
    _MenuItem('Register Store', Icons.storefront_outlined),
    _MenuItem('Register Dealer', Icons.business_outlined),
    _MenuItem('My Listings', Icons.inventory_2_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= AppBreakpoints.desktop;
    // On very wide screens, give the sidebar a bit more room
    final sidebarWidth = screenWidth >= AppBreakpoints.wide ? 220.0 : 200.0;

    return FutureBuilder<UserModel?>(
      future: auth.getCurrentUserModel(),
      builder: (context, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.green),
            ),
          );
        }
        if (userSnap.hasError) {
          return const Scaffold(
            body: AppErrorState(title: 'Unable to load the admin dashboard'),
          );
        }

        return Scaffold(
          key: _scaffoldKey,
          drawer: Drawer(
            width: 260,
            backgroundColor: AppTheme.surface,
            child: _buildSidebarContent(isMobile: true),
          ),
          body: Row(
            children: [
              // Persistent sidebar on desktop
              if (isDesktop)
                SizedBox(
                  width: sidebarWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      border: Border(
                        right: BorderSide(
                          color: AppTheme.border,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: _buildSidebarContent(isMobile: false),
                  ),
                ),
              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isDesktop)
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12, top: 8, bottom: 4),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.menu, color: AppTheme.green),
                                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _menuItems[_selectedMenuIndex].label,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Expanded(
                      child: _buildContentArea(context, userSnap.data!),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebarContent({required bool isMobile}) {
    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 12,
            top: isMobile ? MediaQuery.paddingOf(context).top + 12 : 12,
            bottom: 12,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppTheme.border),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.admin_panel_settings,
                  size: 20, color: AppTheme.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Admin Panel',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (isMobile)
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
            ],
          ),
        ),
        // Menu items list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: _menuItems.length,
            itemBuilder: (context, index) {
              final item = _menuItems[index];
              final isSelected = index == _selectedMenuIndex;

              return _SidebarMenuItem(
                label: item.label,
                icon: item.icon,
                isSelected: isSelected,
                onTap: () {
                  setState(() => _selectedMenuIndex = index);
                  // Close drawer on mobile after selection
                  if (isMobile) Navigator.pop(context);
                },
              );
            },
          ),
        ),
        // Logout Option
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _SidebarMenuItem(
            label: 'Log Out',
            icon: Icons.logout_rounded,
            isSelected: false,
            onTap: () async {
              await AuthService().signOut();
              if (mounted && isMobile) {
                Navigator.pop(context);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContentArea(BuildContext context, UserModel user) {
    switch (_selectedMenuIndex) {
      case 0:
        return RegistryBidsTab(db: _db);
      case 1:
        return RegistryDatabaseTab(db: _db);
      case 2:
        return AdminUsersList(db: _db);
      case 3:
        return AdminAgentsList(db: _db);
      case 4:
        return RegisterUserScreen(role: 'Farmer', agentId: user.id);
      case 5:
        return RegisterGroupScreen(agentId: user.id);
      case 6:
        return RegisterStoreScreen(agentId: user.id);
      case 7:
        return RegisterDealerScreen(agentId: user.id);
      case 8:
        return MyListingsTab(userId: user.id);
      default:
        return RegistryBidsTab(db: _db);
    }
  }
}

class AdminUsersList extends StatelessWidget {
  final DatabaseService db;
  const AdminUsersList({required this.db});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserModel>>(
      future: db.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.green));
        }
        if (snapshot.hasError) {
          return const AppErrorState(title: 'Unable to load users');
        }
        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return const Center(child: Text('No users registered.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final u = users[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: AppTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppTheme.border, width: 0.5),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.green.withValues(alpha: 0.08),
                  child: Text(
                    u.name.isNotEmpty ? u.name[0].toUpperCase() : 'U',
                    style: const TextStyle(color: AppTheme.green, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(u.name.isNotEmpty ? u.name : 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${u.role} • ${u.district}'),
                trailing: Text(u.phone, style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ),
            );
          },
        );
      },
    );
  }
}

class AdminAgentsList extends StatelessWidget {
  final DatabaseService db;
  const AdminAgentsList({required this.db});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserModel>>(
      future: db.getUsersByRole('Agent'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.green));
        }
        if (snapshot.hasError) {
          return const AppErrorState(title: 'Unable to load agents');
        }
        final agents = snapshot.data ?? [];
        if (agents.isEmpty) {
          return const Center(child: Text('No agents registered.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: agents.length,
          itemBuilder: (context, index) {
            final a = agents[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: AppTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppTheme.border, width: 0.5),
              ),
              child: ListTile(
                onTap: () => _showAgentDetailsSheet(context, a),
                leading: CircleAvatar(
                  backgroundColor: AppTheme.green.withValues(alpha: 0.08),
                  child: Text(
                    a.name.isNotEmpty ? a.name[0].toUpperCase() : 'A',
                    style: const TextStyle(color: AppTheme.green, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(a.name.isNotEmpty ? a.name : 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${a.email} • ${a.district}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(a.phone, style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    const SizedBox(width: 4),
                     Icon(Icons.chevron_right, size: 16, color: AppTheme.textMuted),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAgentDetailsSheet(BuildContext context, UserModel agent) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollCtrl) {
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: FutureBuilder<Map<String, dynamic>>(
                future: () async {
                  final users = await db.getUsersByAgent(agent.id);
                  final groups = await db.getGroupsByAgent(agent.id);
                  return {'users': users, 'groups': groups};
                }(),
                builder: (context, snap) {
                  final isLoading = snap.connectionState == ConnectionState.waiting;
                  final relations = snap.data;
                  final List<UserModel> users = relations?['users'] ?? [];
                  final List<FarmerGroupModel> groups = relations?['groups'] ?? [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Agent Header
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: AppTheme.green.withValues(alpha: 0.1),
                            child: Text(
                              agent.name.isNotEmpty ? agent.name[0].toUpperCase() : 'A',
                              style: const TextStyle(
                                color: AppTheme.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  agent.name.isNotEmpty ? agent.name : 'No Name',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${agent.email} • ${agent.district}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Phone: ${agent.phone}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Relations section header
                      Text(
                        'Members Registered by Agent',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Expanded(
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator(color: AppTheme.green))
                            : ListView(
                                controller: scrollCtrl,
                                children: [
                                  // Expandable Section: Individuals
                                  Theme(
                                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                    child: ExpansionTile(
                                      title: Text(
                                        'Individuals (${users.length})',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.greenLight,
                                        ),
                                      ),
                                      leading: const Icon(Icons.person, color: AppTheme.greenLight),
                                      initiallyExpanded: true,
                                      children: users.isEmpty
                                          ? [
                                              Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                                child: Text(
                                                  'No individuals registered under this agent.',
                                                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                                ),
                                              ),
                                            ]
                                          : users.map((u) {
                                              return ListTile(
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                                dense: true,
                                                title: Text(
                                                  u.name,
                                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                                ),
                                                subtitle: Text('${u.role} • ${u.district}'),
                                                trailing: Text(
                                                  u.phone,
                                                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                                ),
                                              );
                                            }).toList(),
                                    ),
                                  ),

                                  const Divider(height: 1),

                                  // Expandable Section: Farmer Groups
                                  Theme(
                                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                    child: ExpansionTile(
                                      title: Text(
                                        'Farmer Groups (${groups.length})',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.warning,
                                        ),
                                      ),
                                      leading: const Icon(Icons.groups, color: AppTheme.warning),
                                      initiallyExpanded: true,
                                      children: groups.isEmpty
                                          ? [
                                              Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                                child: Text(
                                                  'No groups registered under this agent.',
                                                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                                ),
                                              ),
                                            ]
                                          : groups.map((g) {
                                              return ListTile(
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                                dense: true,
                                                title: Text(
                                                  g.groupName,
                                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                                ),
                                                subtitle: Text('Leader: ${g.leaderName} • ${g.district}'),
                                                trailing: Text(
                                                  '${g.memberCount} members',
                                                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                                ),
                                              );
                                            }).toList(),
                                    ),
                                  ),
                                ],
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
}

class _MenuItem {
  final String label;
  final IconData icon;
  const _MenuItem(this.label, this.icon);
}

class _SidebarMenuItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarMenuItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<_SidebarMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppTheme.green.withValues(alpha: 0.10)
                : _isHovered
                    ? AppTheme.surfaceLight
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: widget.isSelected
                ? Border.all(
                    color: AppTheme.green.withValues(alpha: 0.20),
                    width: 0.5,
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 17,
                color: widget.isSelected
                    ? AppTheme.green
                    : _isHovered
                        ? AppTheme.textPrimary
                        : AppTheme.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: widget.isSelected
                        ? AppTheme.green
                        : _isHovered
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
