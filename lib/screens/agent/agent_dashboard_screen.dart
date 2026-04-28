import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user_model.dart';
import '../../models/input_dealer_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/my_listings_tab.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../models/product_model.dart';
import '../marketplace/add_product_screen.dart';

class AgentDashboardScreen extends StatefulWidget {
  final String agentId;

  const AgentDashboardScreen({super.key, required this.agentId});

  @override
  State<AgentDashboardScreen> createState() => _AgentDashboardScreenState();
}

class _AgentDashboardScreenState extends State<AgentDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
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
        title: const Text('Agent Dashboard'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Register'),
            Tab(text: 'My Users'),
            Tab(text: 'Groups'),
            Tab(text: 'My Listings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _RegisterTab(agentId: widget.agentId),
          _MyUsersTab(agentId: widget.agentId),
          _GroupsTab(agentId: widget.agentId),
          MyListingsTab(userId: widget.agentId),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.title, required this.desc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.greenSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.greenLight, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(desc, style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}

// ─── Register Tab ────────────────────────────────────
class _RegisterTab extends StatelessWidget {
  final String agentId;
  const _RegisterTab({required this.agentId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _ActionCard(
            icon: Icons.grass,
            title: 'Register Farmer',
            desc: 'Create a new farmer account',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _AgentRegisterUserScreen(agentId: agentId, role: 'Farmer'))),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.shopping_bag_outlined,
            title: 'Register Buyer',
            desc: 'Create a new buyer account',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _AgentRegisterUserScreen(agentId: agentId, role: 'Buyer'))),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.groups,
            title: 'Register Farmer Group',
            desc: 'Register a group of farmers',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _AgentRegisterGroupScreen(agentId: agentId))),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.store,
            title: 'Register Input Dealer',
            desc: 'Register an agro input dealer',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _AgentRegisterDealerScreen(agentId: agentId))),
          ),
        ],
      ),
    );
  }
}

// ─── My Users Tab ─────────────────────────────────────
class _MyUsersTab extends StatelessWidget {
  final String agentId;
  const _MyUsersTab({required this.agentId});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    return FutureBuilder<List<UserModel>>(
      future: db.getUsersByAgent(agentId),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.green));
        }
        final users = snap.data ?? [];
        if (users.isEmpty) {
          return Center(child: Text('No registered users yet', style: TextStyle(color: AppTheme.textMuted)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (ctx, i) {
            final u = users[i];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => _UserDetailScreen(user: u, agentId: agentId)),
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
                      backgroundColor: AppTheme.surfaceLight,
                      backgroundImage: u.profilePhoto != null ? NetworkImage(u.profilePhoto!) : null,
                      child: u.profilePhoto == null
                          ? Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?', style: TextStyle(color: AppTheme.textMuted))
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.name.isNotEmpty ? u.name : u.email, style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                          Text('${u.role} • ${u.district}', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                          if (u.phone.isNotEmpty)
                            Text(u.phone, style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                    // Quick manage listings button for farmers
                    if (u.role == 'Farmer')
                      IconButton(
                        icon: const Icon(Icons.inventory_2_outlined, color: AppTheme.greenLight, size: 20),
                        tooltip: 'Manage Listings',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => _FarmerListingsManageScreen(farmer: u)),
                          );
                        },
                      ),
                    Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── User Detail / Edit Screen ───────────────────────
class _UserDetailScreen extends StatefulWidget {
  final UserModel user;
  final String agentId;
  const _UserDetailScreen({required this.user, required this.agentId});

  @override
  State<_UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<_UserDetailScreen> {
  final _db = DatabaseService();
  bool _editing = false;

  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  String? _gender;
  String? _district;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.user.firstName);
    _lastNameCtrl = TextEditingController(text: widget.user.lastName);
    _phoneCtrl = TextEditingController(text: widget.user.phone);
    _emailCtrl = TextEditingController(text: widget.user.email);
    _gender = widget.user.gender.isNotEmpty ? widget.user.gender : null;
    _district = widget.user.district.isNotEmpty ? widget.user.district : null;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_firstNameCtrl.text.trim().isEmpty) return;
    try {
      await _db.updateUser(widget.user.id, {
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'name': '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
        'phone': _phoneCtrl.text.trim(),
        'gender': _gender ?? '',
        'district': _district ?? '',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated successfully!')));
        setState(() => _editing = false);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return Scaffold(
      appBar: AppBar(
        title: Text(u.name.isNotEmpty ? u.name : 'User Details'),
        actions: [
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _editing = true),
            )
          else ...[
            TextButton(
              onPressed: () {
                _firstNameCtrl.text = u.firstName;
                _lastNameCtrl.text = u.lastName;
                _phoneCtrl.text = u.phone;
                _emailCtrl.text = u.email;
                _gender = u.gender.isNotEmpty ? u.gender : null;
                _district = u.district.isNotEmpty ? u.district : null;
                setState(() => _editing = false);
              },
              child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            TextButton(
              onPressed: _save,
              child: const Text('Save', style: TextStyle(color: AppTheme.greenLight, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar header
            CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.surfaceLight,
              backgroundImage: u.profilePhoto != null ? NetworkImage(u.profilePhoto!) : null,
              child: u.profilePhoto == null
                  ? Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 28, fontWeight: FontWeight.w700))
                  : null,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.greenSurface, borderRadius: BorderRadius.circular(6)),
              child: Text(u.role, style: const TextStyle(color: AppTheme.greenLight, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 24),

            // Info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border, width: 0.5),
              ),
              child: _editing ? _buildEditForm() : _buildInfoView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoView() {
    final u = widget.user;
    return Column(
      children: [
        _infoRow(Icons.person, 'Full Name', '${u.firstName} ${u.lastName}'.trim()),
        _infoRow(Icons.phone, 'Phone', u.phone.isNotEmpty ? u.phone : 'Not set'),
        _infoRow(Icons.email, 'Email', u.email.isNotEmpty ? u.email : 'Not set'),
        _infoRow(Icons.wc, 'Gender', u.gender.isNotEmpty ? u.gender : 'Not set'),
        _infoRow(Icons.location_on, 'District', u.district.isNotEmpty ? u.district : 'Not set'),
        _infoRow(Icons.map, 'Subcounty', u.subcounty.isNotEmpty ? u.subcounty : 'Not set'),
        _infoRow(Icons.home, 'Village', u.village.isNotEmpty ? u.village : 'Not set'),
        if (u.bio != null && u.bio!.isNotEmpty)
          _infoRow(Icons.info_outline, 'Bio', u.bio!),
        _infoRow(Icons.verified, 'Status', u.isVerified ? 'Verified' : 'Unverified',
            valueColor: u.isVerified ? AppTheme.greenLight : AppTheme.warning),
        _infoRow(Icons.calendar_today, 'Registered', _formatDate(u.createdAt)),
      ],
    );
  }

  Widget _buildEditForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: CustomTextField(label: 'First Name', controller: _firstNameCtrl)),
            const SizedBox(width: 12),
            Expanded(child: CustomTextField(label: 'Last Name', controller: _lastNameCtrl)),
          ],
        ),
        const SizedBox(height: 14),
        CustomTextField(label: 'Phone', controller: _phoneCtrl, keyboardType: TextInputType.phone),
        const SizedBox(height: 14),
        CustomTextField(label: 'Email (read-only)', controller: _emailCtrl, enabled: false),
        const SizedBox(height: 14),
        CustomDropdown(label: 'Gender', value: _gender, items: AppConstants.genderOptions, onChanged: (v) => setState(() => _gender = v)),
        const SizedBox(height: 14),
        CustomDropdown(label: 'District', value: _district, items: AppConstants.bunyoroDistricts, onChanged: (v) => setState(() => _district = v)),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 18),
          const SizedBox(width: 12),
          SizedBox(width: 80, child: Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 13))),
          Expanded(
            child: Text(value, style: TextStyle(color: valueColor ?? AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ─── Farmer Listings Management (Agent Impersonation) ─
class _FarmerListingsManageScreen extends StatelessWidget {
  final UserModel farmer;
  const _FarmerListingsManageScreen({required this.farmer});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    return Scaffold(
      appBar: AppBar(
        title: Text('${farmer.firstName.isNotEmpty ? farmer.firstName : farmer.name}\'s Listings'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.swap_horiz, color: Colors.orange, size: 14),
                const SizedBox(width: 4),
                Text('Managing as Agent', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddProductScreen(sellerId: farmer.id)),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Listing'),
      ),
      body: FutureBuilder<List<ProductModel>>(
        future: db.getProductsBySeller(farmer.id),
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
                  Icon(Icons.inventory_2_outlined, color: AppTheme.textMuted.withOpacity(0.3), size: 56),
                  const SizedBox(height: 12),
                  Text('No listings yet', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text('Add a listing for this farmer', style: TextStyle(color: AppTheme.textMuted.withOpacity(0.6), fontSize: 13)),
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
                    MaterialPageRoute(builder: (_) => AddProductScreen(sellerId: farmer.id, existingProduct: p)),
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
          );
        },
      ),
    );
  }
}

// ─── Groups Tab ───────────────────────────────────────
class _GroupsTab extends StatelessWidget {
  final String agentId;
  const _GroupsTab({required this.agentId});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    return FutureBuilder(
      future: db.getGroupsByAgent(agentId),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.green));
        }
        final groups = snap.data ?? [];
        if (groups.isEmpty) {
          return Center(child: Text('No groups registered', style: TextStyle(color: AppTheme.textMuted)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          itemBuilder: (ctx, i) {
            final g = groups[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g.groupName, style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Leader: ${g.leaderName} • ${g.district}', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  Text('${g.memberCount} members', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Agent Register User Screen ──────────────────────
class _AgentRegisterUserScreen extends StatefulWidget {
  final String agentId;
  final String role;
  const _AgentRegisterUserScreen({required this.agentId, required this.role});

  @override
  State<_AgentRegisterUserScreen> createState() => _AgentRegisterUserScreenState();
}

class _AgentRegisterUserScreenState extends State<_AgentRegisterUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  String? _gender;
  String? _district;
  String _subcounty = '';
  String _village = '';
  String _nin = '';
  bool _loading = false;

  static const String _defaultPassword = 'bivfarm123';

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gender == null || _district == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill all required fields')));
      return;
    }
    setState(() => _loading = true);
    try {
      final auth = AuthService();
      await auth.registerUserByAgent(
        email: _emailCtrl.text.trim(),
        password: _defaultPassword,
        role: widget.role,
        agentId: widget.agentId,
        profileData: {
          'firstName': _firstNameCtrl.text.trim(),
          'lastName': _lastNameCtrl.text.trim(),
          'name': '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
          'phone': _phoneCtrl.text.trim(),
          'gender': _gender,
          'district': _district,
          'subcounty': _subcounty,
          'village': _village,
          'nin': _nin,
          'userCategory': widget.role,
          'bio': _bioCtrl.text.trim(),
        },
      );
      if (mounted) {
        // Show success dialog with credentials
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    if (mounted) setState(() => _loading = false);
  }

  void _showSuccessDialog() {
    final name = '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}';
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: AppTheme.greenLight, size: 24),
              const SizedBox(width: 8),
              Text('${widget.role} Registered!', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Login credentials for $name:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 16),

              // Credentials card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _credRow('Name', name),
                    _credRow('Email', email),
                    _credRow('Phone', phone),
                    _credRow('Password', _defaultPassword),
                    _credRow('Role', widget.role),
                    _credRow('District', _district ?? ''),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Copy button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                      text: 'BFarm Login Credentials\n'
                          'Name: $name\n'
                          'Email: $email\n'
                          'Phone: $phone\n'
                          'Password: $_defaultPassword\n'
                          'Role: ${widget.role}',
                    ));
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Credentials copied to clipboard')),
                    );
                  },
                  icon: Icon(Icons.copy, size: 16, color: AppTheme.textSecondary),
                  label: Text('Copy Credentials', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Text(
                'The user can change their password after first login.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // close dialog
                Navigator.pop(context); // go back to dashboard
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Widget _credRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text('$label:', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() { _firstNameCtrl.dispose(); _lastNameCtrl.dispose(); _phoneCtrl.dispose(); _emailCtrl.dispose(); _bioCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register ${widget.role}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Default password notice
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
                    const Icon(Icons.info_outline, color: AppTheme.greenLight, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Default password: $_defaultPassword\nThe user can change it after first login.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              CustomTextField(label: 'First Name', controller: _firstNameCtrl, validator: (v) => Validators.required(v, 'First name')),
              const SizedBox(height: 14),
              CustomTextField(label: 'Last Name', controller: _lastNameCtrl, validator: (v) => Validators.required(v, 'Last name')),
              const SizedBox(height: 14),
              CustomTextField(label: 'Phone', controller: _phoneCtrl, validator: Validators.phone, keyboardType: TextInputType.phone,
                  prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.textMuted, size: 20)),
              const SizedBox(height: 14),
              CustomTextField(label: 'Email', controller: _emailCtrl, validator: Validators.email, keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textMuted, size: 20)),
              const SizedBox(height: 14),
              CustomDropdown(label: 'Gender', value: _gender, items: AppConstants.genderOptions, onChanged: (v) => setState(() => _gender = v)),
              const SizedBox(height: 14),
              CustomDropdown(label: 'District', value: _district, items: AppConstants.bunyoroDistricts, onChanged: (v) => setState(() => _district = v)),
              const SizedBox(height: 14),
              CustomTextField(label: 'Subcounty (Optional)', hint: 'e.g. Buseruka', onChanged: (v) => _subcounty = v),
              const SizedBox(height: 14),
              CustomTextField(label: 'Village (Optional)', hint: 'e.g. Kaiso', onChanged: (v) => _village = v),
              const SizedBox(height: 14),
              CustomTextField(label: 'Bio / Speciality (Optional)', hint: 'e.g. Pigs Farmer, Fruit Specialist', controller: _bioCtrl),
              const SizedBox(height: 14),
              CustomTextField(label: 'NIN (Optional)', hint: 'National ID Number', onChanged: (v) => _nin = v),
              const SizedBox(height: 28),
              CustomButton(text: 'Register ${widget.role}', onPressed: _register, isLoading: _loading),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Agent Register Group Screen ─────────────────────
class _AgentRegisterGroupScreen extends StatefulWidget {
  final String agentId;
  const _AgentRegisterGroupScreen({required this.agentId});

  @override
  State<_AgentRegisterGroupScreen> createState() => _AgentRegisterGroupScreenState();
}

class _AgentRegisterGroupScreenState extends State<_AgentRegisterGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _leaderCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _membersCtrl = TextEditingController();
  String? _district;
  bool _loading = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _district == null) return;
    setState(() => _loading = true);
    try {
      final db = DatabaseService();
      await db.addFarmerGroup(FarmerGroupModel(
        id: '',
        groupName: _nameCtrl.text.trim(),
        district: _district!,
        leaderName: _leaderCtrl.text.trim(),
        leaderPhone: _phoneCtrl.text.trim(),
        memberCount: int.tryParse(_membersCtrl.text) ?? 0,
        registeredBy: widget.agentId,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group registered!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() { _nameCtrl.dispose(); _leaderCtrl.dispose(); _phoneCtrl.dispose(); _membersCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Farmer Group')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(label: 'Group Name', controller: _nameCtrl, validator: (v) => Validators.required(v, 'Group name')),
              const SizedBox(height: 14),
              CustomTextField(label: 'Leader Name', controller: _leaderCtrl, validator: (v) => Validators.required(v, 'Leader name')),
              const SizedBox(height: 14),
              CustomTextField(label: 'Leader Phone', controller: _phoneCtrl, validator: Validators.phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 14),
              CustomTextField(label: 'Number of Members', controller: _membersCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              CustomDropdown(label: 'District', value: _district, items: AppConstants.bunyoroDistricts, onChanged: (v) => setState(() => _district = v)),
              const SizedBox(height: 28),
              CustomButton(text: 'Register Group', onPressed: _save, isLoading: _loading),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Agent Register Dealer Screen ────────────────────
class _AgentRegisterDealerScreen extends StatefulWidget {
  final String agentId;
  const _AgentRegisterDealerScreen({required this.agentId});

  @override
  State<_AgentRegisterDealerScreen> createState() => _AgentRegisterDealerScreenState();
}

class _AgentRegisterDealerScreenState extends State<_AgentRegisterDealerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bizNameCtrl = TextEditingController();
  final _regNumCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String? _productType;
  String? _district;
  bool _loading = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _district == null || _productType == null) return;
    setState(() => _loading = true);
    try {
      final db = DatabaseService();
      await db.addInputDealer(InputDealerModel(
        id: '',
        businessName: _bizNameCtrl.text.trim(),
        registrationNumber: _regNumCtrl.text.trim(),
        productType: _productType!,
        phone: _phoneCtrl.text.trim(),
        district: _district!,
        address: _addressCtrl.text.trim(),
        registeredBy: widget.agentId,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dealer registered!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() { _bizNameCtrl.dispose(); _regNumCtrl.dispose(); _phoneCtrl.dispose(); _addressCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Input Dealer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(label: 'Business Name', controller: _bizNameCtrl, validator: (v) => Validators.required(v, 'Business name')),
              const SizedBox(height: 14),
              CustomTextField(label: 'Registration Number', controller: _regNumCtrl),
              const SizedBox(height: 14),
              CustomDropdown(label: 'Product Type', value: _productType, items: AppConstants.inputProductTypes, onChanged: (v) => setState(() => _productType = v)),
              const SizedBox(height: 14),
              CustomTextField(label: 'Phone', controller: _phoneCtrl, validator: Validators.phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 14),
              CustomDropdown(label: 'District', value: _district, items: AppConstants.bunyoroDistricts, onChanged: (v) => setState(() => _district = v)),
              const SizedBox(height: 14),
              CustomTextField(label: 'Address', controller: _addressCtrl),
              const SizedBox(height: 28),
              CustomButton(text: 'Register Dealer', onPressed: _save, isLoading: _loading),
            ],
          ),
        ),
      ),
    );
  }
}
