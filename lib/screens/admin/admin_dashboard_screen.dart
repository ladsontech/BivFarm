import 'package:flutter/material.dart';
import '../../models/user_model.dart';

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

class AdminUsersList extends StatefulWidget {
  final DatabaseService db;
  const AdminUsersList({super.key, required this.db});

  @override
  State<AdminUsersList> createState() => _AdminUsersListState();
}

class _AdminUsersListState extends State<AdminUsersList> {
  List<UserModel> _users = [];
  bool _loading = true;
  String _search = '';
  String? _roleFilter;

  static const _allRoles = ['Farmer', 'Buyer', 'Store', 'Agent', 'Registry', 'Admin'];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final users = await widget.db.getAllUsers();
      if (mounted) setState(() { _users = users; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showEditSheet(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserEditSheet(
        user: user,
        db: widget.db,
        onSaved: _loadUsers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.green));
    }

    final q = _search.toLowerCase();
    final filtered = _users.where((u) {
      final matchesSearch = q.isEmpty ||
          u.name.toLowerCase().contains(q) ||
          u.phone.contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.district.toLowerCase().contains(q);
      final matchesRole = _roleFilter == null || u.role == _roleFilter;
      return matchesSearch && matchesRole;
    }).toList();

    return Column(
      children: [
        // Search + filter bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search users…',
                      hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.green),
                      filled: true,
                      fillColor: AppTheme.surfaceLight,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppTheme.border, width: 0.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppTheme.border, width: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String?>(
                tooltip: 'Filter by role',
                color: AppTheme.surface,
                onSelected: (v) => setState(() => _roleFilter = v),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: null, child: Text('All Roles')),
                  ..._allRoles.map((r) => PopupMenuItem(value: r, child: Text(r))),
                ],
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: _roleFilter != null ? AppTheme.green.withValues(alpha: 0.1) : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _roleFilter != null ? AppTheme.green : AppTheme.border, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, size: 16, color: _roleFilter != null ? AppTheme.green : AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        _roleFilter ?? 'Role',
                        style: TextStyle(fontSize: 12, color: _roleFilter != null ? AppTheme.green : AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Text(
                '${filtered.length} user${filtered.length == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('Refresh', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: AppTheme.green),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final u = filtered[index];
              final initial = u.name.isNotEmpty ? u.name[0].toUpperCase() : 'U';
              return _UserCompactCard(
                user: u,
                initial: initial,
                onEdit: () => _showEditSheet(context, u),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UserCompactCard extends StatelessWidget {
  final UserModel user;
  final String initial;
  final VoidCallback onEdit;

  const _UserCompactCard({
    required this.user,
    required this.initial,
    required this.onEdit,
  });

  Color get _roleColor {
    switch (user.role) {
      case 'Admin': return Colors.red.shade400;
      case 'Agent': return Colors.blue.shade400;
      case 'Registry': return Colors.purple.shade400;
      case 'Farmer': return AppTheme.green;
      case 'Store': return Colors.orange.shade400;
      default: return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: AppTheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppTheme.border, width: 0.5),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _roleColor.withValues(alpha: 0.12),
                child: Text(initial, style: TextStyle(color: _roleColor, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name.isNotEmpty ? user.name : 'No Name',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: _roleColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            user.role,
                            style: TextStyle(fontSize: 10, color: _roleColor, fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (user.district.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '• ${user.district}',
                              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(user.phone.isNotEmpty ? user.phone : '—', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  const SizedBox(height: 2),
                  Icon(Icons.edit_outlined, size: 14, color: AppTheme.green.withValues(alpha: 0.7)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserEditSheet extends StatefulWidget {
  final UserModel user;
  final DatabaseService db;
  final VoidCallback onSaved;
  const _UserEditSheet({required this.user, required this.db, required this.onSaved});

  @override
  State<_UserEditSheet> createState() => _UserEditSheetState();
}

class _UserEditSheetState extends State<_UserEditSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _districtCtrl;
  late String _selectedRole;
  bool _saving = false;

  static const _allRoles = ['Farmer', 'Buyer', 'Store', 'Agent', 'Registry', 'Admin'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _phoneCtrl = TextEditingController(text: widget.user.phone);
    _emailCtrl = TextEditingController(text: widget.user.email);
    _districtCtrl = TextEditingController(text: widget.user.district);
    _selectedRole = widget.user.role;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _districtCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.db.updateUser(widget.user.id, {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'district': _districtCtrl.text.trim(),
        'role': _selectedRole,
      });
      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully'), backgroundColor: AppTheme.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.green.withValues(alpha: 0.1),
                child: Text(
                  widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : 'U',
                  style: const TextStyle(color: AppTheme.green, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Edit User', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(widget.user.id, style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Role selector — most important
          Text('Role', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _allRoles.map((r) {
              final selected = _selectedRole == r;
              return GestureDetector(
                onTap: () => setState(() => _selectedRole = r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.green : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppTheme.green : AppTheme.border,
                      width: selected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Text(
                    r,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          _EditField(label: 'Full Name', controller: _nameCtrl, icon: Icons.person_outline),
          const SizedBox(height: 10),
          _EditField(label: 'Phone', controller: _phoneCtrl, icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
          const SizedBox(height: 10),
          _EditField(label: 'Email', controller: _emailCtrl, icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 10),
          _EditField(label: 'District', controller: _districtCtrl, icon: Icons.location_on_outlined),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType keyboardType;

  const _EditField({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12, color: AppTheme.textMuted),
        prefixIcon: Icon(icon, size: 18, color: AppTheme.green),
        filled: true,
        fillColor: AppTheme.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.border, width: 0.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.border, width: 0.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.green, width: 1)),
      ),
    );
  }
}

class AdminAgentsList extends StatefulWidget {
  final DatabaseService db;
  const AdminAgentsList({super.key, required this.db});

  @override
  State<AdminAgentsList> createState() => _AdminAgentsListState();
}

class _AdminAgentsListState extends State<AdminAgentsList> {
  List<UserModel> _agents = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  Future<void> _loadAgents() async {
    setState(() => _loading = true);
    try {
      final agents = await widget.db.getUsersByRole('Agent');
      if (mounted) setState(() { _agents = agents; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showEditSheet(BuildContext context, UserModel agent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserEditSheet(
        user: agent,
        db: widget.db,
        onSaved: _loadAgents,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.green));
    }

    final q = _search.toLowerCase();
    final filtered = _agents.where((a) =>
      q.isEmpty ||
      a.name.toLowerCase().contains(q) ||
      a.phone.contains(q) ||
      a.district.toLowerCase().contains(q),
    ).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search agents…',
                      hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.green),
                      filled: true,
                      fillColor: AppTheme.surfaceLight,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.border, width: 0.5)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.border, width: 0.5)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _loadAgents,
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('Refresh', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: AppTheme.green),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('${filtered.length} agent${filtered.length == 1 ? '' : 's'}', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final a = filtered[index];
              final initial = a.name.isNotEmpty ? a.name[0].toUpperCase() : 'A';
              return _UserCompactCard(
                user: a,
                initial: initial,
                onEdit: () => _showEditSheet(context, a),
              );
            },
          ),
        ),
      ],
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
