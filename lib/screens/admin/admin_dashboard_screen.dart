import 'package:flutter/material.dart';
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

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
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
            Text('Register New Farmer', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            CustomTextField(label: 'First Name', controller: _firstNameCtrl),
            const SizedBox(height: 12),
            CustomTextField(label: 'Last Name', controller: _lastNameCtrl),
            const SizedBox(height: 12),
            CustomTextField(label: 'Phone', controller: _phoneCtrl, keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            CustomTextField(label: 'Email', controller: _emailCtrl, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            CustomDropdown(label: 'Gender', value: _gender, items: AppConstants.genderOptions, onChanged: (v) => setState(() => _gender = v)),
            const SizedBox(height: 12),
            CustomDropdown(label: 'District', value: _district, items: AppConstants.bunyoroDistricts, onChanged: (v) => setState(() => _district = v)),
            const SizedBox(height: 12),
            
            // Agent Selection
            FutureBuilder<List<UserModel>>(
              future: widget.db.getUsersByRole('Agent'),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final agents = snapshot.data!;
                return DropdownButtonFormField<String>(
                  value: _selectedAgentId,
                  dropdownColor: AppTheme.card,
                  style: TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Assign to Agent (Optional)'),
                  items: agents.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
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
                      'name': '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
                      'phone': _phoneCtrl.text.trim(),
                      'gender': _gender ?? '',
                      'district': _district ?? '',
                      'userCategory': 'Farmer',
                    },
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Farmer created successfully! Password: farmer123')));
                    _formKey.currentState!.reset();
                    setState(() {
                      _selectedAgentId = null;
                      _gender = null;
                      _district = null;
                    });
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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
          return const Center(child: CircularProgressIndicator(color: AppTheme.green));
        }
        final data = snap.data ?? {};
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Overview', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  StatCard(title: 'Total Farmers', value: '${data['totalFarmers'] ?? 0}', icon: Icons.grass, color: AppTheme.greenLight),
                  StatCard(title: 'Total Buyers', value: '${data['totalBuyers'] ?? 0}', icon: Icons.shopping_bag, color: AppTheme.info),
                  StatCard(title: 'Total Agents', value: '${data['totalAgents'] ?? 0}', icon: Icons.support_agent, color: AppTheme.error),
                  StatCard(title: 'Active Listings', value: '${data['totalListings'] ?? 0}', icon: Icons.inventory_2, color: AppTheme.warning),
                  StatCard(title: 'Total Bids', value: '${data['totalBids'] ?? 0}', icon: Icons.gavel, color: AppTheme.greenAccent),
                ],
              ),
              const SizedBox(height: 24),
              Text('Gender Distribution', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
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
                    Expanded(child: _genderBar('Male', data['males'] ?? 0, data['totalUsers'] ?? 1, AppTheme.info)),
                    const SizedBox(width: 12),
                    Expanded(child: _genderBar('Female', data['females'] ?? 0, data['totalUsers'] ?? 1, AppTheme.greenLight)),
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
        Text('$count', style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
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
        Text('$pct%', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
      ],
    );
  }
}

// ─── Users Tab ───────────────────────────────────────
class _UsersTab extends StatefulWidget {
  final DatabaseService db;
  const _UsersTab({required this.db});

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matchesSearch(UserModel u) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return u.name.toLowerCase().contains(q) ||
        u.email.toLowerCase().contains(q) ||
        u.phone.contains(q) ||
        u.firstName.toLowerCase().contains(q) ||
        u.lastName.toLowerCase().contains(q);
  }

  void _showChangeRoleDialog(BuildContext context, UserModel user) {
    String? selectedRole = user.role;
    if (!AppConstants.userRoles.contains(selectedRole)) {
      selectedRole = AppConstants.userRoles.isNotEmpty ? AppConstants.userRoles.first : null;
    }
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              backgroundColor: AppTheme.card,
              title: Text('Change Role', style: TextStyle(color: AppTheme.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Update role for ${user.name.isNotEmpty ? user.name : user.email}', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    dropdownColor: AppTheme.surfaceLight,
                    style: TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                    items: AppConstants.userRoles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (v) => setDlgState(() => selectedRole = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedRole != null && selectedRole != user.role) {
                      widget.db.updateUser(user.id, {'role': selectedRole});
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Role updated to $selectedRole')));
                    }
                    Navigator.pop(ctx);
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
      future: widget.db.getAllUsers(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.green));
        }
        final allUsers = snap.data ?? [];
        final users = allUsers.where(_matchesSearch).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by name, email, or phone...',
                  prefixIcon: Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: AppTheme.textMuted, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _query.isEmpty
                      ? '${allUsers.length} users'
                      : '${users.length} of ${allUsers.length} users',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: users.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, color: AppTheme.textMuted.withOpacity(0.3), size: 48),
                          const SizedBox(height: 12),
                          Text('No users found', style: TextStyle(color: AppTheme.textMuted)),
                        ],
                      ),
                    )
                  : ListView.builder(
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
                            border: Border.all(color: AppTheme.border, width: 0.5),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppTheme.surfaceLight,
                                backgroundImage: u.profilePhoto != null ? NetworkImage(u.profilePhoto!) : null,
                                child: u.profilePhoto == null
                                    ? Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w600))
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(u.name.isNotEmpty ? u.name : u.email, style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text('${u.role} • ${u.district}', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                        const SizedBox(width: 6),
                                        GestureDetector(
                                          onTap: () => _showChangeRoleDialog(context, u),
                                          child: const Icon(Icons.edit, size: 14, color: AppTheme.greenLight),
                                        ),
                                      ],
                                    ),
                                    if (u.phone.isNotEmpty)
                                      Text(u.phone, style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: u.isVerified ? AppTheme.greenSurface : AppTheme.surfaceLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      u.isVerified ? 'Verified' : 'Pending',
                                      style: TextStyle(
                                        color: u.isVerified ? AppTheme.greenLight : AppTheme.textMuted,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (!u.isVerified)
                                    GestureDetector(
                                      onTap: () {
                                        widget.db.updateUser(u.id, {'isVerified': true});
                                        setState(() {});
                                      },
                                      child: const Text('Verify', style: TextStyle(color: AppTheme.greenLight, fontSize: 11, fontWeight: FontWeight.w600)),
                                    ),
                                ],
                              ),
                            ],
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
    return FutureBuilder<List<UserModel>>(
      future: widget.db.getUsersByRole('Agent'),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.green));
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
            Expanded(
              child: agents.isEmpty
                  ? Center(child: Text('No agents yet', style: TextStyle(color: AppTheme.textMuted)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: agents.length,
                      itemBuilder: (ctx, i) {
                        final a = agents[i];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => _AgentDetailScreen(agent: a, db: widget.db)),
                            );
                          },
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
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppTheme.greenSurface,
                                  child: Text(a.name.isNotEmpty ? a.name[0].toUpperCase() : 'A', style: const TextStyle(color: AppTheme.greenLight, fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(a.name.isNotEmpty ? a.name : a.email, style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                                      Text('${a.district} • ${a.phone}', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    widget.db.updateUser(a.id, {'isActive': !a.isActive});
                                    setState(() {});
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: a.isActive ? AppTheme.greenSurface : AppTheme.surfaceLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      a.isActive ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        color: a.isActive ? AppTheme.greenLight : AppTheme.textMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
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
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController(text: 'agent123'); // Default password
    String? district;
    bool isCreating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              title: Text('Create Agent Account', style: TextStyle(color: AppTheme.textPrimary)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameCtrl, style: TextStyle(color: AppTheme.textPrimary), decoration: const InputDecoration(labelText: 'Full Name', hintText: 'e.g. John Doe')),
                    const SizedBox(height: 10),
                    TextField(controller: emailCtrl, style: TextStyle(color: AppTheme.textPrimary), decoration: const InputDecoration(labelText: 'Email Address', hintText: 'agent@bivfarm.com'), keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 10),
                    TextField(controller: passwordCtrl, style: TextStyle(color: AppTheme.textPrimary), decoration: const InputDecoration(labelText: 'Login Password', hintText: 'Default: agent123')),
                    const SizedBox(height: 10),
                    TextField(controller: phoneCtrl, style: TextStyle(color: AppTheme.textPrimary), decoration: const InputDecoration(labelText: 'Phone Number', hintText: '07XX XXX XXX'), keyboardType: TextInputType.phone),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: district, isExpanded: true, dropdownColor: AppTheme.surfaceLight,
                      style: TextStyle(color: AppTheme.textPrimary), decoration: const InputDecoration(labelText: 'District'),
                      items: AppConstants.bunyoroDistricts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: (v) => setDlgState(() => district = v),
                    ),
                    if (isCreating) ...[
                      const SizedBox(height: 20),
                      const LinearProgressIndicator(color: AppTheme.green),
                      const SizedBox(height: 8),
                      Text('Initializing account...', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: isCreating ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: isCreating ? null : () async {
                    if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty || passwordCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all required fields')));
                      return;
                    }
                    setDlgState(() => isCreating = true);
                    try {
                      await AuthService().registerUserByAgent(
                        email: emailCtrl.text.trim(), 
                        password: passwordCtrl.text.trim(), 
                        role: 'Agent', agentId: '',
                        profileData: {
                          'name': nameCtrl.text.trim(), 
                          'firstName': nameCtrl.text.trim(), 
                          'lastName': '', 
                          'phone': phoneCtrl.text.trim(), 
                          'district': district ?? 'Hoima', 
                          'userCategory': 'Agent'
                        },
                      );
                      if (ctx.mounted) { 
                        Navigator.pop(ctx); 
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agent account created successfully')));
                        setState(() {}); 
                      }
                    } catch (e) {
                      setDlgState(() => isCreating = false);
                      String errorMsg = e.toString();
                      if (errorMsg.contains('email-already-in-use')) errorMsg = 'This email is already registered';
                      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(errorMsg)));
                    }
                  },
                  child: Text(isCreating ? 'Creating...' : 'Create Account'),
                ),
              ],
            );
          },
        );
      },
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
          bottom: const TabBar(tabs: [Tab(text: 'Users'), Tab(text: 'Groups')]),
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
                    child: Text(agent.name.isNotEmpty ? agent.name[0].toUpperCase() : 'A',
                        style: const TextStyle(color: AppTheme.greenLight, fontWeight: FontWeight.w700, fontSize: 22)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(agent.name, style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('${agent.district} • ${agent.phone}', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        if (agent.email.isNotEmpty) Text(agent.email, style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      ],
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
      selectedRole = AppConstants.userRoles.isNotEmpty ? AppConstants.userRoles.first : null;
    }
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              backgroundColor: AppTheme.card,
              title: Text('Change Role', style: TextStyle(color: AppTheme.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Update role for ${user.name.isNotEmpty ? user.name : user.email}', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    dropdownColor: AppTheme.surfaceLight,
                    style: TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                    items: AppConstants.userRoles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (v) => setDlgState(() => selectedRole = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedRole != null && selectedRole != user.role) {
                      widget.db.updateUser(user.id, {'role': selectedRole});
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Role updated to $selectedRole')));
                    }
                    Navigator.pop(ctx);
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
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppTheme.green));
        final users = snap.data ?? [];
        if (users.isEmpty) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.people_outline, color: AppTheme.textMuted.withOpacity(0.3), size: 48),
            const SizedBox(height: 12),
            Text('No users registered by this agent', style: TextStyle(color: AppTheme.textMuted)),
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
              decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.border, width: 0.5)),
              child: Row(children: [
                CircleAvatar(radius: 20, backgroundColor: AppTheme.surfaceLight,
                  child: Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w600))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(u.name.isNotEmpty ? u.name : u.email, style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                  Row(
                    children: [
                      Text('${u.role} • ${u.district}', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _showChangeRoleDialog(context, u),
                        child: const Icon(Icons.edit, size: 14, color: AppTheme.greenLight),
                      ),
                    ],
                  ),
                  if (u.phone.isNotEmpty) Text(u.phone, style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: u.isVerified ? AppTheme.greenSurface : AppTheme.surfaceLight, borderRadius: BorderRadius.circular(4)),
                  child: Text(u.isVerified ? 'Verified' : 'Pending', style: TextStyle(color: u.isVerified ? AppTheme.greenLight : AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
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
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppTheme.green));
        final groups = snap.data ?? [];
        if (groups.isEmpty) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.groups_outlined, color: AppTheme.textMuted.withOpacity(0.3), size: 48),
            const SizedBox(height: 12),
            Text('No groups registered by this agent', style: TextStyle(color: AppTheme.textMuted)),
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
              decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.border, width: 0.5)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(g.groupName, style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Leader: ${g.leaderName} • ${g.district}', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                Text('${g.memberCount} members • ${g.leaderPhone}', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
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
  static void showMessageDialog(BuildContext context, DatabaseService db, String recipientId, String recipientName) {
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
              CustomTextField(label: 'Message', controller: bodyCtrl, maxLines: 4),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message sent')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
