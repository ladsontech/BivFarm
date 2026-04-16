import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/constants.dart';

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
    _tabCtrl = TabController(length: 3, vsync: this);
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
          tabs: const [
            Tab(text: 'Analytics'),
            Tab(text: 'Users'),
            Tab(text: 'Agents'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _AnalyticsTab(db: _db),
          _UsersTab(db: _db),
          _AgentsTab(db: _db),
        ],
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
          return Center(child: CircularProgressIndicator(color: AppTheme.green));
        }
        final data = snap.data ?? {};
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Overview', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 16),
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
                  StatCard(title: 'Active Listings', value: '${data['totalListings'] ?? 0}', icon: Icons.inventory_2, color: AppTheme.warning),
                  StatCard(title: 'Total Bids', value: '${data['totalBids'] ?? 0}', icon: Icons.gavel, color: AppTheme.greenAccent),
                ],
              ),
              SizedBox(height: 24),
              Text('Gender Distribution', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              SizedBox(height: 12),
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
                    SizedBox(width: 12),
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
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total > 0 ? count / total : 0,
            backgroundColor: AppTheme.surfaceLight,
            color: color,
            minHeight: 6,
          ),
        ),
        SizedBox(height: 4),
        Text('$pct%', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
      ],
    );
  }
}

// ─── Users Tab ───────────────────────────────────────
class _UsersTab extends StatelessWidget {
  final DatabaseService db;
  const _UsersTab({required this.db});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserModel>>(
      future: db.getAllUsers(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppTheme.green));
        }
        final users = snap.data ?? [];
        return ListView.builder(
          padding: const EdgeInsets.all(16),
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
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.name.isNotEmpty ? u.name : u.email, style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                        SizedBox(height: 2),
                        Text('${u.role} • ${u.district}', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
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
                          onTap: () => db.updateUser(u.id, {'isVerified': true}),
                          child: Text('Verify', style: TextStyle(color: AppTheme.greenLight, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
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
          return Center(child: CircularProgressIndicator(color: AppTheme.green));
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
                                radius: 20,
                                backgroundColor: AppTheme.greenSurface,
                                child: Text(a.name.isNotEmpty ? a.name[0].toUpperCase() : 'A', style: TextStyle(color: AppTheme.greenLight, fontWeight: FontWeight.w600)),
                              ),
                              SizedBox(width: 12),
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

  void _showCreateAgentDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String? district;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              title: Text('Create Agent', style: TextStyle(color: AppTheme.textPrimary)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: phoneCtrl,
                      style: TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(labelText: 'Phone'),
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: emailCtrl,
                      style: TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: district,
                      dropdownColor: AppTheme.surfaceLight,
                      style: TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(labelText: 'District'),
                      items: AppConstants.bunyoroDistricts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: (v) => setDlgState(() => district = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty) return;
                    try {
                      final auth = AuthService();
                      await auth.registerUserByAgent(
                        email: emailCtrl.text.trim(),
                        password: 'agent123',
                        role: 'Agent',
                        agentId: '',
                        profileData: {
                          'name': nameCtrl.text.trim(),
                          'firstName': nameCtrl.text.trim(),
                          'lastName': '',
                          'phone': phoneCtrl.text.trim(),
                          'district': district ?? '',
                          'userCategory': 'Agent',
                        },
                      );
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        setState(() {});
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
