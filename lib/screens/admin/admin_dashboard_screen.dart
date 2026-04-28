import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/my_listings_tab.dart';
import '../../utils/constants.dart';
import '../../models/bid_model.dart';
import '../../models/bulk_order_model.dart';
import '../../models/message_model.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Analytics'),
            Tab(text: 'Users'),
            Tab(text: 'Agents'),
            Tab(text: 'Create Farmer'),
            Tab(text: 'My Listings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _AnalyticsTab(db: _db),
          _UsersTab(db: _db),
          _AgentsTab(db: _db),
          _CreateFarmerTab(db: _db),
          MyListingsTab(userId: AuthService().currentUser?.uid ?? ''),
        ],
      ),
    );
  }
}

// ─── Create Farmer Tab ───────────────────────────────
class _CreateFarmerTab extends StatefulWidget {
  final DatabaseService db;
  const _CreateFarmerTab({required this.db});

  @override
  State<_CreateFarmerTab> createState() => _CreateFarmerTabState();
}

class _CreateFarmerTabState extends State<_CreateFarmerTab> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String? _gender;
  String? _district;
  String? _selectedAgentId;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Register New Farmer',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            CustomTextField(label: 'First Name', controller: _firstNameCtrl),
            const SizedBox(height: 12),
            CustomTextField(label: 'Last Name', controller: _lastNameCtrl),
            const SizedBox(height: 12),
            CustomTextField(
                label: 'Phone',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            CustomTextField(
                label: 'Email',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            CustomDropdown(
                label: 'Gender',
                value: _gender,
                items: AppConstants.genderOptions,
                onChanged: (v) => setState(() => _gender = v)),
            const SizedBox(height: 12),
            CustomDropdown(
                label: 'District',
                value: _district,
                items: AppConstants.bunyoroDistricts,
                onChanged: (v) => setState(() => _district = v)),
            const SizedBox(height: 12),

            // Agent Selection
            StreamBuilder<List<UserModel>>(
              stream: Stream.fromFuture(widget.db.getUsersByRole('Agent')),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final agents = snapshot.data!;
                return DropdownButtonFormField<String>(
                  value: _selectedAgentId,
                  dropdownColor: AppTheme.card,
                  style: TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                      labelText: 'Assign to Agent (Optional)'),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('No Agent')),
                    ...agents.map((a) =>
                        DropdownMenuItem(value: a.id, child: Text(a.name))),
                  ],
                  onChanged: (v) => setState(() => _selectedAgentId = v),
                );
              },
            ),

            const SizedBox(height: 24),
            CustomButton(
              text: 'Create Farmer Account',
              isLoading: _loading,
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                setState(() => _loading = true);
                try {
                  await AuthService().registerUserByAgent(
                    email: _emailCtrl.text.trim(),
                    password: 'farmer123',
                    role: 'Farmer',
                    agentId: _selectedAgentId ?? '',
                    profileData: {
                      'firstName': _firstNameCtrl.text.trim(),
                      'lastName': _lastNameCtrl.text.trim(),
                      'name':
                          '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
                      'phone': _phoneCtrl.text.trim(),
                      'gender': _gender ?? '',
                      'district': _district ?? '',
                      'userCategory': 'Farmer',
                    },
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Farmer created successfully! Default password: farmer123')));
                    _formKey.currentState!.reset();
                    setState(() {
                      _selectedAgentId = null;
                      _gender = null;
                      _district = null;
                    });
                  }
                } catch (e) {
                  if (mounted)
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(e.toString())));
                }
                if (mounted) setState(() => _loading = false);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Analytics Tab ───────────────────────────────────
class _AnalyticsTab extends StatelessWidget {
  final DatabaseService db;
  const _AnalyticsTab({required this.db});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: db.getAnalytics(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.green));
        }
        final data = snap.data ?? {};
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Overview',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  StatCard(
                      title: 'Total Farmers',
                      value: '${data['totalFarmers'] ?? 0}',
                      icon: Icons.grass,
                      color: AppTheme.greenLight),
                  StatCard(
                      title: 'Total Buyers',
                      value: '${data['totalBuyers'] ?? 0}',
                      icon: Icons.shopping_bag,
                      color: AppTheme.info),
                  StatCard(
                      title: 'Total Agents',
                      value: '${data['totalAgents'] ?? 0}',
                      icon: Icons.support_agent,
                      color: AppTheme.error),
                  StatCard(
                      title: 'Active Listings',
                      value: '${data['totalListings'] ?? 0}',
                      icon: Icons.inventory_2,
                      color: AppTheme.warning),
                  StatCard(
                      title: 'Total Bids',
                      value: '${data['totalBids'] ?? 0}',
                      icon: Icons.gavel,
                      color: AppTheme.greenAccent),
                ],
              ),
              const SizedBox(height: 24),
              Text('Gender Distribution',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border, width: 0.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                        child: _genderBar('Male', data['males'] ?? 0,
                            data['totalUsers'] ?? 1, AppTheme.info)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _genderBar('Female', data['females'] ?? 0,
                            data['totalUsers'] ?? 1, AppTheme.greenLight)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _genderBar(String label, int count, int total, Color color) {
    final pct = total > 0 ? (count / total * 100).round() : 0;
    return Column(
      children: [
        Text('$count',
            style: TextStyle(
                color: color, fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total > 0 ? count / total : 0,
            backgroundColor: AppTheme.surfaceLight,
            color: color,
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text('$pct%',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
      ],
    );
  }
}

// ─── Users Tab (live stream, full management) ─────────
class _UsersTab extends StatefulWidget {
  final DatabaseService db;
  const _UsersTab({required this.db});

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _roleFilter; // null = all

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matchesSearch(UserModel u) {
    if (_roleFilter != null && u.role != _roleFilter) return false;
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return u.name.toLowerCase().contains(q) ||
        u.email.toLowerCase().contains(q) ||
        u.phone.contains(q) ||
        u.firstName.toLowerCase().contains(q) ||
        u.lastName.toLowerCase().contains(q) ||
        u.district.toLowerCase().contains(q);
  }

  void _showUserSheet(BuildContext context, UserModel user,
      List<UserModel> agents) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserManagementSheet(
        user: user,
        agents: agents,
        db: widget.db,
        onChanged: () => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: Stream.fromFuture(widget.db.getAllUsers()),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.green));
        }
        final allUsers = snap.data ?? [];
        final agents =
            allUsers.where((u) => u.role == 'Agent').toList();
        final filtered = allUsers.where(_matchesSearch).toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        return Column(
          children: [
            // Search + filter bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style:
                          TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search name, email, phone...',
                        prefixIcon: Icon(Icons.search,
                            color: AppTheme.textMuted, size: 20),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear,
                                    color: AppTheme.textMuted, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Role filter button
                  PopupMenuButton<String?>(
                    color: AppTheme.card,
                    onSelected: (v) => setState(() => _roleFilter = v),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                          value: null,
                          child: Text('All Roles',
                              style:
                                  TextStyle(color: AppTheme.textPrimary))),
                      ...AppConstants.userRoles.map((r) => PopupMenuItem(
                            value: r,
                            child: Text(r,
                                style:
                                    TextStyle(color: AppTheme.textPrimary)),
                          )),
                    ],
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _roleFilter != null
                            ? AppTheme.greenSurface
                            : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: _roleFilter != null
                                ? AppTheme.green
                                : AppTheme.border),
                      ),
                      child: Icon(Icons.filter_list,
                          color: _roleFilter != null
                              ? AppTheme.greenLight
                              : AppTheme.textMuted,
                          size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // Count + active filter label
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Text(
                    '${filtered.length} of ${allUsers.length} users',
                    style:
                        TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  if (_roleFilter != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _roleFilter = null),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.greenSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_roleFilter!,
                                style: TextStyle(
                                    color: AppTheme.greenLight,
                                    fontSize: 11)),
                            const SizedBox(width: 4),
                            Icon(Icons.close,
                                size: 12, color: AppTheme.greenLight),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off,
                              color: AppTheme.textMuted.withOpacity(0.3),
                              size: 48),
                          const SizedBox(height: 12),
                          Text('No users found',
                              style:
                                  TextStyle(color: AppTheme.textMuted)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final u = filtered[i];
                        return _UserListTile(
                          user: u,
                          onTap: () => _showUserSheet(context, u, agents),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _UserListTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  const _UserListTile({required this.user, required this.onTap});

  Color _roleColor(String role) {
    switch (role) {
      case 'Admin':
        return AppTheme.error;
      case 'Agent':
        return AppTheme.info;
      case 'Farmer':
        return AppTheme.greenLight;
      case 'Registry':
        return AppTheme.warning;
      default:
        return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(user.role);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border, width: 0.5),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.surfaceLight,
                  backgroundImage: user.profilePhoto != null
                      ? NetworkImage(user.profilePhoto!)
                      : null,
                  child: user.profilePhoto == null
                      ? Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w600))
                      : null,
                ),
                if (!user.isActive)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.card, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name.isNotEmpty ? user.name : user.email,
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          user.role,
                          style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(user.district,
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 11)),
                    ],
                  ),
                  if (user.phone.isNotEmpty)
                    Text(user.phone,
                        style: TextStyle(
                            color: AppTheme.textMuted, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: user.isVerified
                        ? AppTheme.greenSurface
                        : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    user.isVerified ? 'Verified' : 'Pending',
                    style: TextStyle(
                      color: user.isVerified
                          ? AppTheme.greenLight
                          : AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Icon(Icons.chevron_right,
                    color: AppTheme.textMuted, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── User Management Bottom Sheet ────────────────────
class _UserManagementSheet extends StatefulWidget {
  final UserModel user;
  final List<UserModel> agents;
  final DatabaseService db;
  final VoidCallback onChanged;
  const _UserManagementSheet(
      {required this.user,
      required this.agents,
      required this.db,
      required this.onChanged});

  @override
  State<_UserManagementSheet> createState() => _UserManagementSheetState();
}

class _UserManagementSheetState extends State<_UserManagementSheet> {
  late String _selectedRole;
  late String? _selectedAgentId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role;
    _selectedAgentId = widget.user.agentId;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updates = <String, dynamic>{};
      if (_selectedRole != widget.user.role) updates['role'] = _selectedRole;
      if (_selectedAgentId != widget.user.agentId)
        updates['agentId'] = _selectedAgentId ?? '';
      if (updates.isNotEmpty) await widget.db.updateUser(widget.user.id, updates);
      widget.onChanged();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User updated successfully')));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _toggleVerified() async {
    await widget.db
        .updateUser(widget.user.id, {'isVerified': !widget.user.isVerified});
    widget.onChanged();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _toggleActive() async {
    await widget.db
        .updateUser(widget.user.id, {'isActive': !widget.user.isActive});
    widget.onChanged();
    if (mounted) Navigator.pop(context);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: Text('Delete User',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
            'Are you sure you want to delete ${widget.user.name.isNotEmpty ? widget.user.name : widget.user.email}? This cannot be undone.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              // Remove from Firestore users collection
              await widget.db.updateUser(
                  widget.user.id, {'isActive': false, 'isDeleted': true});
              widget.onChanged();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User deactivated')));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),

            // User header
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.greenSurface,
                  backgroundImage:
                      u.profilePhoto != null ? NetworkImage(u.profilePhoto!) : null,
                  child: u.profilePhoto == null
                      ? Text(
                          u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                              color: AppTheme.greenLight,
                              fontSize: 22,
                              fontWeight: FontWeight.w700))
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.name.isNotEmpty ? u.name : 'No Name',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(u.email,
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 13)),
                      if (u.phone.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: u.phone));
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Phone copied')));
                          },
                          child: Text(u.phone,
                              style: TextStyle(
                                  color: AppTheme.textMuted, fontSize: 12)),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Divider(color: AppTheme.border),
            const SizedBox(height: 12),

            // Info chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(u.district.isNotEmpty ? u.district : 'No district',
                    Icons.location_on_outlined),
                _InfoChip(u.gender.isNotEmpty ? u.gender : 'Gender N/A',
                    Icons.person_outline),
                _InfoChip(
                    DateFormat('dd MMM yyyy').format(u.createdAt), Icons.calendar_today),
              ],
            ),
            const SizedBox(height: 16),

            // Role change
            Text('Role',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              dropdownColor: AppTheme.surfaceLight,
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                  labelText: 'User Role', border: OutlineInputBorder()),
              items: AppConstants.userRoles
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedRole = v!),
            ),

            const SizedBox(height: 16),

            // Assign to Agent
            Text('Assigned Agent',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String?>(
              value: _selectedAgentId,
              dropdownColor: AppTheme.surfaceLight,
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                  labelText: 'Agent', border: OutlineInputBorder()),
              items: [
                DropdownMenuItem<String?>(
                    value: null,
                    child: Text('No Agent',
                        style: TextStyle(color: AppTheme.textMuted))),
                ...widget.agents.map((a) =>
                    DropdownMenuItem<String?>(value: a.id, child: Text(a.name))),
              ],
              onChanged: (v) => setState(() => _selectedAgentId = v),
            ),

            const SizedBox(height: 20),

            // Quick action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _toggleVerified,
                    icon: Icon(
                        u.isVerified ? Icons.cancel_outlined : Icons.verified,
                        size: 16),
                    label: Text(u.isVerified ? 'Unverify' : 'Verify'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          u.isVerified ? AppTheme.error : AppTheme.greenLight,
                      side: BorderSide(
                          color: u.isVerified
                              ? AppTheme.error
                              : AppTheme.greenLight),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _toggleActive,
                    icon: Icon(
                        u.isActive ? Icons.block : Icons.check_circle_outline,
                        size: 16),
                    label: Text(u.isActive ? 'Deactivate' : 'Activate'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          u.isActive ? AppTheme.error : AppTheme.info,
                      side: BorderSide(
                          color: u.isActive ? AppTheme.error : AppTheme.info),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Delete button
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _confirmDelete,
                icon:
                    const Icon(Icons.delete_outline, size: 16, color: AppTheme.error),
                label: const Text('Delete User',
                    style: TextStyle(color: AppTheme.error)),
              ),
            ),

            const SizedBox(height: 8),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _InfoChip(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textMuted),
          const SizedBox(width: 5),
          Text(label,
              style:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

// ─── Agents Tab ──────────────────────────────────────
class _AgentsTab extends StatefulWidget {
  final DatabaseService db;
  const _AgentsTab({required this.db});

  @override
  State<_AgentsTab> createState() => _AgentsTabState();
}

class _AgentsTabState extends State<_AgentsTab> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: Stream.fromFuture(widget.db.getUsersByRole('Agent')),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.green));
        }
        final agents = snap.data ?? [];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateAgentDialog(context),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Create Agent'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${agents.length} agent${agents.length == 1 ? '' : 's'}',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: agents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.support_agent,
                              color: AppTheme.textMuted.withOpacity(0.3),
                              size: 56),
                          const SizedBox(height: 12),
                          Text('No agents yet',
                              style:
                                  TextStyle(color: AppTheme.textMuted)),
                          const SizedBox(height: 4),
                          Text('Tap "Create Agent" to add one',
                              style: TextStyle(
                                  color: AppTheme.textMuted, fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: agents.length,
                      itemBuilder: (ctx, i) {
                        final a = agents[i];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => _AgentDetailScreen(
                                      agent: a, db: widget.db)),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.card,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppTheme.border, width: 0.5),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppTheme.greenSurface,
                                  child: Text(
                                      a.name.isNotEmpty
                                          ? a.name[0].toUpperCase()
                                          : 'A',
                                      style: const TextStyle(
                                          color: AppTheme.greenLight,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          a.name.isNotEmpty
                                              ? a.name
                                              : a.email,
                                          style: TextStyle(
                                              color: AppTheme.textPrimary,
                                              fontSize: 14,
                                              fontWeight:
                                                  FontWeight.w500)),
                                      Text('${a.district} • ${a.phone}',
                                          style: TextStyle(
                                              color: AppTheme.textMuted,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                                // Active toggle
                                GestureDetector(
                                  onTap: () async {
                                    await widget.db.updateUser(
                                        a.id, {'isActive': !a.isActive});
                                    setState(() {});
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: a.isActive
                                          ? AppTheme.greenSurface
                                          : AppTheme.surfaceLight,
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      a.isActive ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        color: a.isActive
                                            ? AppTheme.greenLight
                                            : AppTheme.textMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.chevron_right,
                                    color: AppTheme.textMuted, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showCreateAgentDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CreateAgentScreen(onCreated: () => setState(() {})),
      ),
    );
  }
}

// ─── Create Agent Screen (Full Form) ─────────────────
class _CreateAgentScreen extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateAgentScreen({required this.onCreated});

  @override
  State<_CreateAgentScreen> createState() => _CreateAgentScreenState();
}

class _CreateAgentScreenState extends State<_CreateAgentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController(text: 'agent123');
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _subcountyCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _ninCtrl = TextEditingController();
  String? _gender;
  String? _district;
  bool _isCreating = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose(); _lastNameCtrl.dispose(); _emailCtrl.dispose();
    _passwordCtrl.dispose(); _phoneCtrl.dispose(); _bioCtrl.dispose();
    _subcountyCtrl.dispose(); _villageCtrl.dispose(); _ninCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gender == null || _district == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select gender and district')),
      );
      return;
    }
    setState(() => _isCreating = true);
    try {
      await AuthService().registerUserByAgent(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        role: 'Agent',
        agentId: '',
        profileData: {
          'firstName': _firstNameCtrl.text.trim(),
          'lastName': _lastNameCtrl.text.trim(),
          'name': '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
          'phone': _phoneCtrl.text.trim(),
          'gender': _gender,
          'district': _district,
          'subcounty': _subcountyCtrl.text.trim(),
          'village': _villageCtrl.text.trim(),
          'bio': _bioCtrl.text.trim(),
          'nin': _ninCtrl.text.trim(),
          'userCategory': 'Agent',
        },
      );
      if (mounted) {
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agent account created successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isCreating = false);
      String errorMsg = e.toString();
      if (errorMsg.contains('email-already-in-use')) errorMsg = 'This email is already registered';
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Agent Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.greenSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.green.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.support_agent, color: AppTheme.greenLight, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Fill in all details for the new Agent.\nDefault password can be changed after first login.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: CustomTextField(label: 'First Name', hint: 'Jane', controller: _firstNameCtrl,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null)),
                const SizedBox(width: 12),
                Expanded(child: CustomTextField(label: 'Last Name', hint: 'Doe', controller: _lastNameCtrl,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null)),
              ]),
              const SizedBox(height: 14),
              CustomTextField(label: 'Email Address', hint: 'agent@bivfarm.com', controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null),
              const SizedBox(height: 14),
              CustomTextField(label: 'Password', hint: 'Default: agent123', controller: _passwordCtrl,
                  validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null),
              const SizedBox(height: 14),
              CustomTextField(label: 'Phone Number', hint: '07XX XXX XXX', controller: _phoneCtrl,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 14),
              CustomDropdown(label: 'Gender', value: _gender, items: AppConstants.genderOptions,
                  onChanged: (v) => setState(() => _gender = v)),
              const SizedBox(height: 14),
              CustomDropdown(label: 'District', value: _district, items: AppConstants.bunyoroDistricts,
                  onChanged: (v) => setState(() => _district = v)),
              const SizedBox(height: 14),
              CustomTextField(label: 'Subcounty (Optional)', hint: 'e.g. Buseruka', controller: _subcountyCtrl),
              const SizedBox(height: 14),
              CustomTextField(label: 'Village (Optional)', hint: 'e.g. Kaiso', controller: _villageCtrl),
              const SizedBox(height: 14),
              CustomTextField(label: 'Bio (Optional)', hint: 'Brief description', controller: _bioCtrl),
              const SizedBox(height: 14),
              CustomTextField(label: 'NIN (Optional)', hint: 'National ID Number', controller: _ninCtrl),
              const SizedBox(height: 28),
              if (_isCreating)
                const Center(child: CircularProgressIndicator(color: AppTheme.green))
              else
                CustomButton(text: 'Create Agent Account', onPressed: _create),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Agent Detail Screen (Admin view) ────────────────
class _AgentDetailScreen extends StatelessWidget {
  final UserModel agent;
  final DatabaseService db;
  const _AgentDetailScreen({required this.agent, required this.db});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(agent.name.isNotEmpty ? agent.name : 'Agent'),
          bottom: const TabBar(
              tabs: [Tab(text: 'Users'), Tab(text: 'Groups')]),
        ),
        body: Column(
          children: [
            // Agent info header
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border, width: 0.5),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.greenSurface,
                    child: Text(
                        agent.name.isNotEmpty
                            ? agent.name[0].toUpperCase()
                            : 'A',
                        style: const TextStyle(
                            color: AppTheme.greenLight,
                            fontWeight: FontWeight.w700,
                            fontSize: 22)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(agent.name,
                            style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('${agent.district} • ${agent.phone}',
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 12)),
                        if (agent.email.isNotEmpty)
                          Text(agent.email,
                              style: TextStyle(
                                  color: AppTheme.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: agent.isActive
                          ? AppTheme.greenSurface
                          : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      agent.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                          color: agent.isActive
                              ? AppTheme.greenLight
                              : AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(children: [
                _AgentUsersView(agentId: agent.id, db: db),
                _AgentGroupsView(agentId: agent.id, db: db),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgentUsersView extends StatefulWidget {
  final String agentId;
  final DatabaseService db;
  const _AgentUsersView({required this.agentId, required this.db});

  @override
  State<_AgentUsersView> createState() => _AgentUsersViewState();
}

class _AgentUsersViewState extends State<_AgentUsersView> {
  void _showChangeRoleDialog(BuildContext context, UserModel user) {
    String? selectedRole = user.role;
    if (!AppConstants.userRoles.contains(selectedRole)) {
      selectedRole = AppConstants.userRoles.isNotEmpty
          ? AppConstants.userRoles.first
          : null;
    }
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              backgroundColor: AppTheme.card,
              title: Text('Change Role',
                  style: TextStyle(color: AppTheme.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Update role for ${user.name.isNotEmpty ? user.name : user.email}',
                      style: TextStyle(
                          color: AppTheme.textMuted, fontSize: 13)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    dropdownColor: AppTheme.surfaceLight,
                    style: TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                        labelText: 'Role', border: OutlineInputBorder()),
                    items: AppConstants.userRoles
                        .map((r) =>
                            DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) =>
                        setDlgState(() => selectedRole = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedRole != null && selectedRole != user.role) {
                      await widget.db
                          .updateUser(user.id, {'role': selectedRole});
                      setState(() {});
                      if (context.mounted)
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content:
                                Text('Role updated to $selectedRole')));
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserModel>>(
      future: widget.db.getUsersByAgent(widget.agentId),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.green));
        final users = snap.data ?? [];
        if (users.isEmpty) {
          return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.people_outline,
                color: AppTheme.textMuted.withOpacity(0.3), size: 48),
            const SizedBox(height: 12),
            Text('No users registered by this agent',
                style: TextStyle(color: AppTheme.textMuted)),
          ]));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: users.length,
          itemBuilder: (ctx, i) {
            final u = users[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border, width: 0.5)),
              child: Row(children: [
                CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.surfaceLight,
                    child: Text(
                        u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                        style: TextStyle(
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w600))),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(u.name.isNotEmpty ? u.name : u.email,
                          style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                      Row(
                        children: [
                          Text('${u.role} • ${u.district}',
                              style: TextStyle(
                                  color: AppTheme.textMuted, fontSize: 12)),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () =>
                                _showChangeRoleDialog(context, u),
                            child: const Icon(Icons.edit,
                                size: 14, color: AppTheme.greenLight),
                          ),
                        ],
                      ),
                      if (u.phone.isNotEmpty)
                        Text(u.phone,
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 11)),
                    ])),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: u.isVerified
                          ? AppTheme.greenSurface
                          : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(u.isVerified ? 'Verified' : 'Pending',
                      style: TextStyle(
                          color: u.isVerified
                              ? AppTheme.greenLight
                              : AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
            );
          },
        );
      },
    );
  }
}

class _AgentGroupsView extends StatelessWidget {
  final String agentId;
  final DatabaseService db;
  const _AgentGroupsView({required this.agentId, required this.db});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: db.getGroupsByAgent(agentId),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.green));
        final groups = snap.data ?? [];
        if (groups.isEmpty) {
          return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.groups_outlined,
                color: AppTheme.textMuted.withOpacity(0.3), size: 48),
            const SizedBox(height: 12),
            Text('No groups registered by this agent',
                style: TextStyle(color: AppTheme.textMuted)),
          ]));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: groups.length,
          itemBuilder: (ctx, i) {
            final g = groups[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border, width: 0.5)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(g.groupName,
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Leader: ${g.leaderName} • ${g.district}',
                    style:
                        TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                Text('${g.memberCount} members • ${g.leaderPhone}',
                    style:
                        TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ]),
            );
          },
        );
      },
    );
  }
}

// ─── Admin Actions Helper ────────────────────────────
class _AdminActions {
  static void showMessageDialog(BuildContext context, DatabaseService db,
      String recipientId, String recipientName) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Message to $recipientName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(label: 'Subject', controller: titleCtrl),
              const SizedBox(height: 12),
              CustomTextField(
                  label: 'Message', controller: bodyCtrl, maxLines: 4),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty || bodyCtrl.text.isEmpty) return;
                try {
                  await db.addMessage(MessageModel(
                    id: '',
                    senderId: 'admin',
                    senderName: 'Admin',
                    senderRole: 'Admin',
                    recipientId: recipientId,
                    subject: titleCtrl.text,
                    body: bodyCtrl.text,
                  ));
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Message sent')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }
}
