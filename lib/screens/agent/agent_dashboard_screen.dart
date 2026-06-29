import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user_model.dart';
import '../../models/input_dealer_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/agent_farmer_listings_tab.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../models/product_model.dart';
import '../marketplace/add_product_screen.dart';
import '../common/registration_screens.dart';

class AgentDashboardScreen extends StatefulWidget {
  final String agentId;

  const AgentDashboardScreen({super.key, required this.agentId});

  @override
  State<AgentDashboardScreen> createState() => _AgentDashboardScreenState();
}

class _AgentDashboardScreenState extends State<AgentDashboardScreen>
    with SingleTickerProviderStateMixin {
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
    return Column(
      children: [
        // Premium Tab Bar Header (Replaces AppBar to avoid overlap)
        Container(
          color: AppTheme.surface,
          child: TabBar(
            controller: _tabCtrl,
            labelColor: AppTheme.green,
            unselectedLabelColor: AppTheme.textMuted,
            indicatorColor: AppTheme.green,
            indicatorWeight: 3,
            labelStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Register'),
              Tab(text: 'Farmers'),
              Tab(text: 'Groups'),
              Tab(text: 'Listings'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _RegisterTab(agentId: widget.agentId),
              _MyUsersTab(agentId: widget.agentId),
              _GroupsTab(agentId: widget.agentId),
              AgentFarmerListingsTab(agentId: widget.agentId),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;

  const _ActionCard(
      {required this.icon,
      required this.title,
      required this.desc,
      required this.onTap});

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
                  Text(title,
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(desc,
                      style:
                          TextStyle(color: AppTheme.textMuted, fontSize: 12)),
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
      child: ResponsiveWrapper(
        maxWidth: 1100,
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: context.isDesktop ? 2 : 1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: context.isDesktop ? 3.25 : 3.6,
          children: [
            _ActionCard(
              icon: Icons.grass,
              title: 'Register Farmer',
              desc: 'Create a new farmer account',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => RegisterUserScreen(
                          agentId: agentId, role: 'Farmer'))),
            ),
            _ActionCard(
              icon: Icons.shopping_bag_outlined,
              title: 'Register Buyer',
              desc: 'Create a new buyer account',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          RegisterUserScreen(agentId: agentId, role: 'Buyer'))),
            ),
            _ActionCard(
              icon: Icons.groups,
              title: 'Register Farmer Group',
              desc: 'Register a group of farmers',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => RegisterGroupScreen(agentId: agentId))),
            ),
            _ActionCard(
              icon: Icons.storefront,
              title: 'Register Produce Store',
              desc: 'Register a farm store or produce outlet',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => RegisterStoreScreen(agentId: agentId))),
            ),
            _ActionCard(
              icon: Icons.store,
              title: 'Register Input Dealer',
              desc: 'Register an agro input dealer',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => RegisterDealerScreen(agentId: agentId))),
            ),
            _ActionCard(
              icon: Icons.add_business_outlined,
              title: 'Add Product Listing',
              desc: 'List new produce for a managed farmer',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          _AgentSelectFarmerPicker(agentId: agentId))),
            ),
          ],
        ),
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
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.green));
        }
        // Show Farmers AND Stores managed by this agent
        final users = (snap.data ?? [])
            .where((u) => u.role == 'Farmer' || u.role == 'Store')
            .toList();
        if (users.isEmpty) {
          return Center(
              child: Text('No registered farmers or stores yet',
                  style: TextStyle(color: AppTheme.textMuted)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (ctx, i) {
            final u = users[i];
            final isStore = u.role == 'Store';
            return ResponsiveWrapper(
              maxWidth: 800,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            _UserDetailScreen(user: u, agentId: agentId)),
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
                        backgroundColor: isStore
                            ? AppTheme.info.withOpacity(0.1)
                            : AppTheme.surfaceLight,
                        backgroundImage: u.profilePhoto != null
                            ? NetworkImage(u.profilePhoto!)
                            : null,
                        child: u.profilePhoto == null
                            ? Icon(isStore ? Icons.storefront : Icons.person,
                                color: isStore
                                    ? AppTheme.info
                                    : AppTheme.textMuted,
                                size: 20)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u.name.isNotEmpty ? u.name : u.phone,
                                style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: isStore
                                        ? AppTheme.info.withOpacity(0.12)
                                        : AppTheme.greenSurface,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(u.role,
                                      style: TextStyle(
                                          color: isStore
                                              ? AppTheme.info
                                              : AppTheme.greenLight,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(width: 6),
                                Text(u.district,
                                    style: TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 12)),
                              ],
                            ),
                            if (u.phone.isNotEmpty)
                              Text(u.phone,
                                  style: TextStyle(
                                      color: AppTheme.textMuted, fontSize: 11)),
                          ],
                        ),
                      ),
                      // Quick manage listings button for farmers and stores
                      if (u.role == 'Farmer' || u.role == 'Store')
                        IconButton(
                          icon: Icon(
                              isStore
                                  ? Icons.storefront
                                  : Icons.inventory_2_outlined,
                              color: AppTheme.greenLight,
                              size: 20),
                          tooltip: 'Manage Listings',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      _FarmerListingsManageScreen(farmer: u)),
                            );
                          },
                        ),
                      Icon(Icons.chevron_right,
                          color: AppTheme.textMuted, size: 20),
                    ],
                  ),
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
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Updated successfully!')));
        setState(() => _editing = false);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
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
              child:
                  Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            TextButton(
              onPressed: _save,
              child: const Text('Save',
                  style: TextStyle(
                      color: AppTheme.greenLight, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ResponsiveWrapper(
          maxWidth: 600,
          child: Column(
            children: [
              // Avatar header
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.surfaceLight,
                backgroundImage: u.profilePhoto != null
                    ? NetworkImage(u.profilePhoto!)
                    : null,
                child: u.profilePhoto == null
                    ? Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                        style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 28,
                            fontWeight: FontWeight.w700))
                    : null,
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                    color: AppTheme.greenSurface,
                    borderRadius: BorderRadius.circular(6)),
                child: Text(u.role,
                    style: TextStyle(
                        color: AppTheme.greenLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
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
      ),
    );
  }

  Widget _buildInfoView() {
    final u = widget.user;
    final isManagingAgent = u.agentId == widget.agentId;

    return Column(
      children: [
        _infoRow(
            Icons.person, 'Full Name', '${u.firstName} ${u.lastName}'.trim()),
        _infoRow(
            Icons.phone,
            'Phone',
            isManagingAgent
                ? (u.phone.isNotEmpty ? u.phone : 'Not set')
                : 'Hidden (Not your farmer)'),
        _infoRow(
            Icons.email,
            'Email',
            isManagingAgent
                ? (u.email.isNotEmpty ? u.email : 'Not set')
                : 'Hidden (Not your farmer)'),
        _infoRow(
            Icons.wc, 'Gender', u.gender.isNotEmpty ? u.gender : 'Not set'),
        _infoRow(Icons.location_on, 'District',
            u.district.isNotEmpty ? u.district : 'Not set'),
        _infoRow(Icons.map, 'Subcounty',
            u.subcounty.isNotEmpty ? u.subcounty : 'Not set'),
        _infoRow(Icons.home, 'Village',
            u.village.isNotEmpty ? u.village : 'Not set'),
        if (u.bio != null && u.bio!.isNotEmpty)
          _infoRow(Icons.info_outline, 'Bio', u.bio!),
        _infoRow(
            Icons.verified, 'Status', u.isVerified ? 'Verified' : 'Unverified',
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
            Expanded(
                child: CustomTextField(
                    label: 'First Name', controller: _firstNameCtrl)),
            const SizedBox(width: 12),
            Expanded(
                child: CustomTextField(
                    label: 'Last Name', controller: _lastNameCtrl)),
          ],
        ),
        const SizedBox(height: 14),
        CustomTextField(
            label: 'Phone',
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone),
        const SizedBox(height: 14),
        CustomTextField(
            label: 'Email (read-only)', controller: _emailCtrl, enabled: false),
        const SizedBox(height: 14),
        CustomDropdown(
            label: 'Gender',
            value: _gender,
            items: AppConstants.genderOptions,
            onChanged: (v) => setState(() => _gender = v)),
        const SizedBox(height: 14),
        CustomDropdown(
            label: 'District',
            value: _district,
            items: AppConstants.bunyoroDistricts,
            onChanged: (v) => setState(() => _district = v)),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 18),
          const SizedBox(width: 12),
          SizedBox(
              width: 80,
              child: Text(label,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13))),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: valueColor ?? AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
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
        title: Text(
            '${farmer.firstName.isNotEmpty ? farmer.firstName : farmer.name}\'s Listings'),
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
                Text('Managing as Agent',
                    style: TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AddProductScreen(sellerId: farmer.id)),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Listing'),
      ),
      body: FutureBuilder<List<ProductModel>>(
        future: db.getProductsBySeller(farmer.id),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.green));
          }
          final products = snap.data ?? [];
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      color: AppTheme.textMuted.withOpacity(0.3), size: 56),
                  const SizedBox(height: 12),
                  Text('No listings yet',
                      style:
                          TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text('Add a listing for this farmer',
                      style: TextStyle(
                          color: AppTheme.textMuted.withOpacity(0.6),
                          fontSize: 13)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (ctx, i) {
              final p = products[i];
              return ResponsiveWrapper(
                maxWidth: 800,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AddProductScreen(
                              sellerId: farmer.id, existingProduct: p)),
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
                                        ? AssetImage(p.imageUrl!)
                                            as ImageProvider
                                        : NetworkImage(p.imageUrl!),
                                    fit: BoxFit.cover)
                                : null,
                          ),
                          child: p.imageUrl == null
                              ? const Icon(Icons.eco,
                                  color: AppTheme.greenLight)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.productName,
                                  style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(
                                  '${p.quantity} ${p.quantityUnit} • ${p.district}',
                                  style: TextStyle(
                                      color: AppTheme.textMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'UGX ${p.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                  color: AppTheme.greenLight,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: p.availability == 'Available Now'
                                    ? AppTheme.greenSurface
                                    : AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                p.availability,
                                style: TextStyle(
                                  color: p.availability == 'Available Now'
                                      ? AppTheme.greenLight
                                      : AppTheme.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.green));
        }
        final groups = snap.data ?? [];
        if (groups.isEmpty) {
          return Center(
              child: Text('No groups registered',
                  style: TextStyle(color: AppTheme.textMuted)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          itemBuilder: (ctx, i) {
            final g = groups[i];
            return ResponsiveWrapper(
              maxWidth: 800,
              child: Container(
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
                    Text(g.groupName,
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Leader: ${g.leaderName} • ${g.district}',
                        style:
                            TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    Text(
                        '${g.memberCount} members${g.category.isNotEmpty ? ' • ${g.category}' : ''}',
                        style:
                            TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    if (g.subcounty.isNotEmpty || g.village.isNotEmpty)
                      Text(
                          '${g.subcounty}${g.subcounty.isNotEmpty && g.village.isNotEmpty ? ', ' : ''}${g.village}',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 11)),
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

// ─── Agent Register User Screen ──────────────────────
class _AgentRegisterUserScreen extends StatefulWidget {
  final String agentId;
  final String role;
  const _AgentRegisterUserScreen({required this.agentId, required this.role});

  @override
  State<_AgentRegisterUserScreen> createState() =>
      _AgentRegisterUserScreenState();
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

  /// Password is the user's phone number (digits only)
  String get _defaultPassword =>
      _phoneCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gender == null || _district == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fill all required fields')));
      return;
    }
    setState(() => _loading = true);
    try {
      final email = _emailCtrl.text.trim();
      final auth = AuthService();
      final db = DatabaseService();

      if (email.isNotEmpty) {
        // Has email: create Firebase Auth account + Firestore profile
        await auth.registerUserByAgent(
          email: email,
          password: _defaultPassword,
          role: widget.role,
          agentId: widget.agentId,
          profileData: {
            'firstName': _firstNameCtrl.text.trim(),
            'lastName': _lastNameCtrl.text.trim(),
            'name':
                '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
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
      } else {
        // No email: create Firestore-only profile. User will sign in via Phone OTP.
        final phone = _phoneCtrl.text.trim();
        if (phone.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text('Phone number is required when no email is provided')));
          setState(() => _loading = false);
          return;
        }
        // Use phone as unique document ID base + timestamp
        final uid =
            'phone_${phone.replaceAll(RegExp(r'[^0-9]'), '')}_${DateTime.now().millisecondsSinceEpoch}';
        await db.setUser(uid, {
          'firstName': _firstNameCtrl.text.trim(),
          'lastName': _lastNameCtrl.text.trim(),
          'name': '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
          'phone': phone,
          'email': '',
          'role': widget.role,
          'agentId': widget.agentId,
          'gender': _gender ?? '',
          'district': _district ?? '',
          'subcounty': _subcounty,
          'village': _village,
          'nin': _nin,
          'userCategory': widget.role,
          'bio': _bioCtrl.text.trim(),
          'isProfileComplete': true,
          'isVerified': true,
          'isActive': true,
          'createdAt': DateTime.now().toIso8601String(),
        });
        // Notify admins
        db
            .sendUserSignupNotification(
              userName:
                  '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
              userRole: widget.role,
              userId: uid,
            )
            .catchError((_) {});
      }

      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    }
    if (mounted) setState(() => _loading = false);
  }

  void _showSuccessDialog() {
    final name = '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}';
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final hasEmail = email.isNotEmpty;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle,
                  color: AppTheme.greenLight, size: 24),
              const SizedBox(width: 8),
              Text('${widget.role} Registered!',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Login credentials for $name:',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
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
                    if (hasEmail) _credRow('Email', email),
                    _credRow('Phone', phone),
                    if (hasEmail) _credRow('Password', _defaultPassword),
                    _credRow('Role', widget.role),
                    _credRow('District', _district ?? ''),
                    _credRow('Login via',
                        hasEmail ? 'Email & Password' : 'Phone Number (OTP)'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Phone-only login notice
              if (!hasEmail)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.greenSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.green.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.phone_android,
                          color: AppTheme.greenLight, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This user has no email. They must sign in using their Phone Number via OTP on the BFarm login screen.',
                          style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

              // Copy button
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                      text: 'BFarm Login Credentials\n'
                          'Name: $name\n'
                          '${hasEmail ? 'Email: $email\nPassword: $_defaultPassword' : 'Phone: $phone (Login via OTP)'}\n'
                          'Role: ${widget.role}',
                    ));
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                          content: Text('Credentials copied to clipboard')),
                    );
                  },
                  icon:
                      Icon(Icons.copy, size: 16, color: AppTheme.textSecondary),
                  label: Text('Copy Credentials',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Text(
                hasEmail
                    ? 'The user can change their password after first login.'
                    : 'The user will verify their phone number on first login.',
                style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontStyle: FontStyle.italic),
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
            child: Text('$label:',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

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
                    const Icon(Icons.info_outline,
                        color: AppTheme.greenLight, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Default password: Phone Number (digits only)\nThe user can change it after first login.',
                        style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              CustomTextField(
                  label: 'First Name',
                  controller: _firstNameCtrl,
                  validator: (v) => Validators.required(v, 'First name')),
              const SizedBox(height: 14),
              CustomTextField(
                  label: 'Last Name',
                  controller: _lastNameCtrl,
                  validator: (v) => Validators.required(v, 'Last name')),
              const SizedBox(height: 14),
              CustomTextField(
                  label: 'Phone',
                  controller: _phoneCtrl,
                  validator: Validators.phone,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icon(Icons.phone_outlined,
                      color: AppTheme.textMuted, size: 20)),
              const SizedBox(height: 14),
              CustomTextField(
                label: 'Email (Optional — leave blank to use phone login)',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icon(Icons.email_outlined,
                    color: AppTheme.textMuted, size: 20),
                // No validator — email is optional
              ),
              const SizedBox(height: 14),
              CustomDropdown(
                  label: 'Gender',
                  value: _gender,
                  items: AppConstants.genderOptions,
                  onChanged: (v) => setState(() => _gender = v)),
              const SizedBox(height: 14),
              CustomDropdown(
                  label: 'District',
                  value: _district,
                  items: AppConstants.bunyoroDistricts,
                  onChanged: (v) => setState(() => _district = v)),
              const SizedBox(height: 14),
              CustomTextField(
                  label: 'Subcounty (Optional)',
                  hint: 'e.g. Buseruka',
                  onChanged: (v) => _subcounty = v),
              const SizedBox(height: 14),
              CustomTextField(
                  label: 'Village (Optional)',
                  hint: 'e.g. Kaiso',
                  onChanged: (v) => _village = v),
              const SizedBox(height: 14),
              CustomTextField(
                  label: 'Bio / Speciality (Optional)',
                  hint: 'e.g. Pigs Farmer, Fruit Specialist',
                  controller: _bioCtrl),
              const SizedBox(height: 14),
              CustomTextField(
                  label: 'NIN (Optional)',
                  hint: 'National ID Number',
                  onChanged: (v) => _nin = v),
              const SizedBox(height: 28),
              CustomButton(
                  text: 'Register ${widget.role}',
                  onPressed: _register,
                  isLoading: _loading),
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
  State<_AgentRegisterGroupScreen> createState() =>
      _AgentRegisterGroupScreenState();
}

class _AgentRegisterGroupScreenState extends State<_AgentRegisterGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _leaderCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _membersCtrl = TextEditingController();
  final _subcountyCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  String? _district;
  String? _category;
  bool _loading = false;

  static const List<String> _groupCategories = [
    'Produce',
    'Poultry',
    'Livestock',
    'Fruits & Vegetables',
    'All',
  ];

  String _sanitizeEmail(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').trim();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _district == null) return;
    setState(() => _loading = true);
    try {
      final db = DatabaseService();
      final auth = AuthService();
      final phone = _phoneCtrl.text.trim();
      final groupName = _nameCtrl.text.trim();
      // Auto-generate email from group name for Firebase Auth
      final sanitized = _sanitizeEmail(groupName);
      final email = '$sanitized@bfarm.local';
      // Password = leader phone number (digits only)
      final password = phone.replaceAll(RegExp(r'[^0-9]'), '');

      // Create Firebase Auth account for the group
      String? userId;
      try {
        userId = await auth.registerUserByAgent(
          email: email,
          password: password,
          role: 'Farmer',
          agentId: widget.agentId,
          profileData: {
            'firstName': groupName,
            'lastName': '(Group)',
            'name': groupName,
            'phone': phone,
            'gender': '',
            'district': _district ?? '',
            'subcounty': _subcountyCtrl.text.trim(),
            'village': _villageCtrl.text.trim(),
            'userCategory': _category ?? 'All',
            'bio': 'Farmer Group • ${_membersCtrl.text} members',
          },
        );
      } catch (e) {
        // If email already exists, continue without user account
        if (e.toString().contains('email-already-in-use')) {
          userId = null;
        } else {
          rethrow;
        }
      }

      await db.addFarmerGroup(FarmerGroupModel(
        id: '',
        groupName: groupName,
        district: _district!,
        subcounty: _subcountyCtrl.text.trim(),
        village: _villageCtrl.text.trim(),
        leaderName: _leaderCtrl.text.trim(),
        leaderPhone: phone,
        memberCount: int.tryParse(_membersCtrl.text) ?? 0,
        category: _category ?? '',
        userId: userId,
        registeredBy: widget.agentId,
      ));
      if (mounted)
        _showGroupSuccessDialog(
            groupName, email, password, phone, userId != null);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    }
    if (mounted) setState(() => _loading = false);
  }

  void _showGroupSuccessDialog(String name, String email, String password,
      String phone, bool hasAccount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle,
                color: AppTheme.greenLight, size: 24),
            const SizedBox(width: 8),
            Expanded(
                child: Text('Group Registered!',
                    style:
                        TextStyle(color: AppTheme.textPrimary, fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasAccount) ...[
              Text('Login credentials for $name:',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
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
                    _credRow('Group', name),
                    _credRow('Email', email),
                    _credRow('Password', password),
                    _credRow('Phone', phone),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                      text:
                          'BFarm Group Login\nGroup: $name\nEmail: $email\nPassword: $password\nPhone: $phone',
                    ));
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Credentials copied!')));
                  },
                  icon:
                      Icon(Icons.copy, size: 16, color: AppTheme.textSecondary),
                  label: Text('Copy Credentials',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ] else
              Text(
                  'Group "$name" registered successfully (no login account created — email may already exist).',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _credRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 70,
              child: Text('$label:',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12))),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _leaderCtrl.dispose();
    _phoneCtrl.dispose();
    _membersCtrl.dispose();
    _subcountyCtrl.dispose();
    _villageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Farmer Group')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info notice
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.greenSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.green.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.groups,
                        color: AppTheme.greenLight, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'A user account will be created for this group.\nPassword: Leader\'s phone number (digits only).',
                        style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              CustomTextField(
                  label: 'Group Name',
                  controller: _nameCtrl,
                  validator: (v) => Validators.required(v, 'Group name')),
              const SizedBox(height: 14),
              CustomTextField(
                  label: 'Leader Name',
                  controller: _leaderCtrl,
                  validator: (v) => Validators.required(v, 'Leader name')),
              const SizedBox(height: 14),
              CustomTextField(
                  label: 'Leader Phone',
                  controller: _phoneCtrl,
                  validator: Validators.phone,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icon(Icons.phone_outlined,
                      color: AppTheme.textMuted, size: 20)),
              const SizedBox(height: 14),
              CustomTextField(
                  label: 'Number of Members',
                  controller: _membersCtrl,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              CustomDropdown(
                  label: 'Category',
                  value: _category,
                  items: _groupCategories,
                  onChanged: (v) => setState(() => _category = v)),
              const SizedBox(height: 14),
              CustomDropdown(
                  label: 'District',
                  value: _district,
                  items: AppConstants.bunyoroDistricts,
                  onChanged: (v) => setState(() => _district = v)),
              const SizedBox(height: 14),
              CustomTextField(
                  label: 'Subcounty',
                  hint: 'e.g. Buseruka',
                  controller: _subcountyCtrl),
              const SizedBox(height: 14),
              CustomTextField(
                  label: 'Village',
                  hint: 'e.g. Kaiso',
                  controller: _villageCtrl),
              const SizedBox(height: 28),
              CustomButton(
                  text: 'Register Group',
                  onPressed: _save,
                  isLoading: _loading),
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
  State<_AgentRegisterDealerScreen> createState() =>
      _AgentRegisterDealerScreenState();
}

class _AgentRegisterDealerScreenState
    extends State<_AgentRegisterDealerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bizNameCtrl = TextEditingController();
  final _regNumCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String? _productType;
  String? _district;
  bool _loading = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() ||
        _district == null ||
        _productType == null) return;
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
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Dealer registered!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _bizNameCtrl.dispose();
    _regNumCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

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
              CustomTextField(
                  label: 'Business Name',
                  controller: _bizNameCtrl,
                  validator: (v) => Validators.required(v, 'Business name')),
              const SizedBox(height: 14),
              CustomTextField(
                  label: 'Registration Number', controller: _regNumCtrl),
              const SizedBox(height: 14),
              CustomDropdown(
                  label: 'Product Type',
                  value: _productType,
                  items: AppConstants.inputProductTypes,
                  onChanged: (v) => setState(() => _productType = v)),
              const SizedBox(height: 14),
              CustomTextField(
                  label: 'Phone',
                  controller: _phoneCtrl,
                  validator: Validators.phone,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 14),
              CustomDropdown(
                  label: 'District',
                  value: _district,
                  items: AppConstants.bunyoroDistricts,
                  onChanged: (v) => setState(() => _district = v)),
              const SizedBox(height: 14),
              CustomTextField(label: 'Address', controller: _addressCtrl),
              const SizedBox(height: 28),
              CustomButton(
                  text: 'Register Dealer',
                  onPressed: _save,
                  isLoading: _loading),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Agent Register Produce Store Screen ─────────────
class _AgentRegisterProduceStoreScreen extends StatefulWidget {
  final String agentId;
  const _AgentRegisterProduceStoreScreen({required this.agentId});

  @override
  State<_AgentRegisterProduceStoreScreen> createState() =>
      _AgentRegisterProduceStoreScreenState();
}

class _AgentRegisterProduceStoreScreenState
    extends State<_AgentRegisterProduceStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _subcountyCtrl = TextEditingController();
  String? _district;
  String? _storeType;
  bool _loading = false;

  static const List<String> _storeTypes = [
    'Farm Store',
    'Produce Store',
    'Wholesale Store'
  ];

  String _sanitizeEmail(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').trim();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() ||
        _district == null ||
        _storeType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')));
      return;
    }
    setState(() => _loading = true);
    try {
      final db = DatabaseService();
      final auth = AuthService();
      final phone = _phoneCtrl.text.trim();
      final storeName = _storeNameCtrl.text.trim();
      // Auto-generate email from store name
      final sanitized = _sanitizeEmail(storeName);
      final email = 'store.$sanitized@bfarm.local';
      // Password = phone number (digits only)
      final password = phone.replaceAll(RegExp(r'[^0-9]'), '');

      // 1. Create Firebase Auth user account for the store (role: Store)
      String? userId;
      try {
        userId = await auth.registerUserByAgent(
          email: email,
          password: password,
          role: 'Store',
          agentId: widget.agentId,
          profileData: {
            'firstName': storeName,
            'lastName': '(${_storeType!})',
            'name': storeName,
            'phone': phone,
            'gender': '',
            'district': _district ?? '',
            'subcounty': _subcountyCtrl.text.trim(),
            'userCategory': 'Both',
            'bio': '$_storeType • Owner: ${_ownerNameCtrl.text.trim()}',
          },
        );
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          userId = null;
        } else {
          rethrow;
        }
      }

      // 2. Add to produce_stores collection
      await db.addProduceStore({
        'storeName': storeName,
        'ownerName': _ownerNameCtrl.text.trim(),
        'phone': phone,
        'subcounty': _subcountyCtrl.text.trim(),
        'district': _district!,
        'storeType': _storeType!,
        'agentId': widget.agentId,
        'userId': userId,
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
      });
      if (mounted)
        _showStoreSuccessDialog(
            storeName, email, password, phone, userId != null);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    }
    if (mounted) setState(() => _loading = false);
  }

  void _showStoreSuccessDialog(String name, String email, String password,
      String phone, bool hasAccount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle,
                color: AppTheme.greenLight, size: 24),
            const SizedBox(width: 8),
            Expanded(
                child: Text('Store Registered!',
                    style:
                        TextStyle(color: AppTheme.textPrimary, fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasAccount) ...[
              Text('Marketplace login credentials for $name:',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
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
                    _credRow('Store', name),
                    _credRow('Email', email),
                    _credRow('Password', password),
                    _credRow('Phone', phone),
                    _credRow('Access', 'Buy, Sell & Update Products'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                      text:
                          'BFarm Store Login\nStore: $name\nEmail: $email\nPassword: $password\nPhone: $phone\nAccess: Buy, Sell & Update Products',
                    ));
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Credentials copied!')));
                  },
                  icon:
                      Icon(Icons.copy, size: 16, color: AppTheme.textSecondary),
                  label: Text('Copy Credentials',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.info.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.storefront, color: AppTheme.info, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This store can now log in to buy, sell and update products on the marketplace. You (the agent) can also list products for them.',
                        style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              Text(
                  'Store "$name" registered successfully (no login account created — email may already exist).',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _credRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 70,
              child: Text('$label:',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12))),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _subcountyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Produce Store')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.greenSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.green.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.storefront,
                        color: AppTheme.greenLight, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Register a store with marketplace access.\nPassword: Phone number (digits only). The store can buy, sell & update products.',
                        style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              CustomTextField(
                  label: 'Store Name',
                  controller: _storeNameCtrl,
                  validator: (v) => Validators.required(v, 'Store name')),
              const SizedBox(height: 14),
              CustomTextField(
                  label: 'Owner / Manager Name',
                  controller: _ownerNameCtrl,
                  validator: (v) => Validators.required(v, 'Owner name')),
              const SizedBox(height: 14),
              CustomTextField(
                  label: 'Phone',
                  controller: _phoneCtrl,
                  validator: Validators.phone,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icon(Icons.phone_outlined,
                      color: AppTheme.textMuted, size: 20)),
              const SizedBox(height: 14),
              CustomDropdown(
                  label: 'Store Type',
                  value: _storeType,
                  items: _storeTypes,
                  onChanged: (v) => setState(() => _storeType = v)),
              const SizedBox(height: 14),
              CustomDropdown(
                  label: 'District',
                  value: _district,
                  items: AppConstants.bunyoroDistricts,
                  onChanged: (v) => setState(() => _district = v)),
              const SizedBox(height: 14),
              CustomTextField(
                  label: 'Subcounty (Optional)',
                  hint: 'e.g. Buseruka',
                  controller: _subcountyCtrl),
              const SizedBox(height: 28),
              CustomButton(
                  text: 'Register Store',
                  onPressed: _save,
                  isLoading: _loading),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Agent Select Farmer/Store Picker (for Add Listing flow) ----
class _AgentSelectFarmerPicker extends StatelessWidget {
  final String agentId;
  const _AgentSelectFarmerPicker({required this.agentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Farmer or Store')),
      body: FutureBuilder<List<UserModel>>(
        future: DatabaseService().getUsersByAgent(agentId),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.green));
          }
          // Include both Farmers and Stores for listing products
          final sellers = (snap.data ?? [])
              .where((u) => u.role == 'Farmer' || u.role == 'Store')
              .toList();
          if (sellers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_off_rounded,
                        size: 64, color: AppTheme.textMuted.withOpacity(0.2)),
                    const SizedBox(height: 16),
                    Text('No farmers or stores managed by you yet',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textMuted)),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sellers.length,
            itemBuilder: (ctx, i) {
              final f = sellers[i];
              final isStore = f.role == 'Store';
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isStore
                        ? AppTheme.info.withOpacity(0.1)
                        : AppTheme.surfaceLight,
                    backgroundImage: f.profilePhoto != null
                        ? NetworkImage(f.profilePhoto!)
                        : null,
                    child: f.profilePhoto == null
                        ? Icon(isStore ? Icons.storefront : Icons.person,
                            color: isStore ? AppTheme.info : AppTheme.textMuted)
                        : null,
                  ),
                  title: Text(f.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isStore
                              ? AppTheme.info.withOpacity(0.12)
                              : AppTheme.greenSurface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(f.role,
                            style: TextStyle(
                                color: isStore
                                    ? AppTheme.info
                                    : AppTheme.greenLight,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 6),
                      Text(f.district,
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                  trailing:
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => AddProductScreen(sellerId: f.id)));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
