import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/input_dealer_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';

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
        title: const Text('Agent Dashboard'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Register'),
            Tab(text: 'My Users'),
            Tab(text: 'Groups'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _RegisterTab(agentId: widget.agentId),
          _MyUsersTab(agentId: widget.agentId),
          _GroupsTab(agentId: widget.agentId),
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
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2),
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
          return Center(child: CircularProgressIndicator(color: AppTheme.green));
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
                    backgroundColor: AppTheme.surfaceLight,
                    backgroundImage: u.profilePhoto != null ? NetworkImage(u.profilePhoto!) : null,
                    child: u.profilePhoto == null
                        ? Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?', style: TextStyle(color: AppTheme.textMuted))
                        : null,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.name.isNotEmpty ? u.name : u.email, style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                        Text('${u.role} • ${u.district}', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      ],
                    ),
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
          return Center(child: CircularProgressIndicator(color: AppTheme.green));
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
                  SizedBox(height: 4),
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
  String? _gender;
  String? _district;
  bool _loading = false;

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
        password: 'bivfarm123',
        role: widget.role,
        agentId: widget.agentId,
        profileData: {
          'firstName': _firstNameCtrl.text.trim(),
          'lastName': _lastNameCtrl.text.trim(),
          'name': '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
          'phone': _phoneCtrl.text.trim(),
          'gender': _gender,
          'district': _district,
          'userCategory': widget.role,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.role} registered!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() { _firstNameCtrl.dispose(); _lastNameCtrl.dispose(); _phoneCtrl.dispose(); _emailCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register ${widget.role}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(label: 'First Name', controller: _firstNameCtrl, validator: (v) => Validators.required(v, 'First name')),
              const SizedBox(height: 14),
              CustomTextField(label: 'Last Name', controller: _lastNameCtrl, validator: (v) => Validators.required(v, 'Last name')),
              const SizedBox(height: 14),
              CustomTextField(label: 'Phone', controller: _phoneCtrl, validator: Validators.phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 14),
              CustomTextField(label: 'Email', controller: _emailCtrl, validator: Validators.email, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 14),
              CustomDropdown(label: 'Gender', value: _gender, items: AppConstants.genderOptions, onChanged: (v) => setState(() => _gender = v)),
              const SizedBox(height: 14),
              CustomDropdown(label: 'District', value: _district, items: AppConstants.bunyoroDistricts, onChanged: (v) => setState(() => _district = v)),
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
