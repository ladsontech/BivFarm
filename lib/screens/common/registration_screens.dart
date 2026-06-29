import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user_model.dart';
import '../../models/input_dealer_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../utils/validators.dart';
import '../../utils/constants.dart';

// standard helper to sanitize names for fake emails
String sanitizeEmailPart(String name) {
  return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').trim();
}

// ─── Register User Screen ────────────────────────────
class RegisterUserScreen extends StatefulWidget {
  final String role; // Farmer or Buyer
  final String agentId;
  const RegisterUserScreen(
      {super.key, required this.role, required this.agentId});

  @override
  State<RegisterUserScreen> createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> {
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
        final phone = _phoneCtrl.text.trim();
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
      builder: (ctx) => AlertDialog(
        title: Text('${widget.role} Registered!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Login credentials for $name:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  if (hasEmail) Text('Email: $email'),
                  Text('Phone: $phone'),
                  if (hasEmail) Text('Password: $_defaultPassword'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Done'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register ${widget.role}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ResponsiveWrapper(
          maxWidth: 700,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                CustomTextField(
                    label: 'First Name', controller: _firstNameCtrl),
                CustomTextField(label: 'Last Name', controller: _lastNameCtrl),
                CustomTextField(label: 'Phone', controller: _phoneCtrl),
                CustomTextField(
                    label: 'Email (Optional)', controller: _emailCtrl),
                CustomDropdown(
                    label: 'Gender',
                    value: _gender,
                    items: AppConstants.genderOptions,
                    onChanged: (v) => setState(() => _gender = v)),
                CustomDropdown(
                    label: 'District',
                    value: _district,
                    items: AppConstants.bunyoroDistricts,
                    onChanged: (v) => setState(() => _district = v)),
                CustomTextField(
                    label: 'Subcounty', onChanged: (v) => _subcounty = v),
                CustomTextField(
                    label: 'Village', onChanged: (v) => _village = v),
                CustomButton(
                    text: 'Register',
                    onPressed: _register,
                    isLoading: _loading),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Register Group Screen ────────────────────────────
class RegisterGroupScreen extends StatefulWidget {
  final String agentId;
  const RegisterGroupScreen({super.key, required this.agentId});

  @override
  State<RegisterGroupScreen> createState() => _RegisterGroupScreenState();
}

class _RegisterGroupScreenState extends State<RegisterGroupScreen> {
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _district == null) return;
    setState(() => _loading = true);
    try {
      final db = DatabaseService();
      final auth = AuthService();
      final phone = _phoneCtrl.text.trim();
      final groupName = _nameCtrl.text.trim();
      final sanitized = sanitizeEmailPart(groupName);
      final email = '$sanitized@bfarm.local';
      final password = phone.replaceAll(RegExp(r'[^0-9]'), '');

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
        if (!e.toString().contains('email-already-in-use')) rethrow;
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
        title: const Text('Group Registered!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasAccount) Text('Group Email: $email\nPassword: $password'),
          ],
        ),
        actions: [
          ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Done'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Farmer Group')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ResponsiveWrapper(
          maxWidth: 700,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                CustomTextField(label: 'Group Name', controller: _nameCtrl),
                CustomTextField(label: 'Leader Name', controller: _leaderCtrl),
                CustomTextField(label: 'Leader Phone', controller: _phoneCtrl),
                CustomTextField(
                    label: 'Number of Members',
                    controller: _membersCtrl,
                    keyboardType: TextInputType.number),
                CustomDropdown(
                  label: 'Category',
                  value: _category,
                  items: const [
                    'Produce',
                    'Poultry',
                    'Livestock',
                    'Fruits & Vegetables',
                    'All'
                  ],
                  onChanged: (v) => setState(() => _category = v),
                ),
                CustomDropdown(
                    label: 'District',
                    value: _district,
                    items: AppConstants.bunyoroDistricts,
                    onChanged: (v) => setState(() => _district = v)),
                CustomTextField(label: 'Subcounty', controller: _subcountyCtrl),
                CustomTextField(label: 'Village', controller: _villageCtrl),
                CustomButton(
                    text: 'Register Group',
                    onPressed: _save,
                    isLoading: _loading),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Register Store Screen ────────────────────────────
class RegisterStoreScreen extends StatefulWidget {
  final String agentId;
  const RegisterStoreScreen({super.key, required this.agentId});

  @override
  State<RegisterStoreScreen> createState() => _RegisterStoreScreenState();
}

class _RegisterStoreScreenState extends State<RegisterStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _subcountyCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  String? _district;
  String? _storeType;
  bool _loading = false;

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _subcountyCtrl.dispose();
    _villageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() ||
        _district == null ||
        _storeType == null) return;
    setState(() => _loading = true);
    try {
      final db = DatabaseService();
      final auth = AuthService();
      final phone = _phoneCtrl.text.trim();
      final storeName = _storeNameCtrl.text.trim();
      final sanitized = sanitizeEmailPart(storeName);
      final email = 'store.$sanitized@bfarm.local';
      final password = phone.replaceAll(RegExp(r'[^0-9]'), '');

      String? userId;
      try {
        userId = await auth.registerUserByAgent(
          email: email,
          password: password,
          role: 'Store',
          agentId: widget.agentId,
          profileData: {
            'firstName': storeName,
            'lastName': '($_storeType)',
            'name': storeName,
            'phone': phone,
            'gender': '',
            'district': _district ?? '',
            'subcounty': _subcountyCtrl.text.trim(),
            'village': _villageCtrl.text.trim(),
            'userCategory': 'Both',
            'bio': '$_storeType • Owner: ${_ownerNameCtrl.text.trim()}',
          },
        );
      } catch (e) {
        if (!e.toString().contains('email-already-in-use')) rethrow;
      }

      await db.addProduceStore({
        'storeName': storeName,
        'ownerName': _ownerNameCtrl.text.trim(),
        'phone': phone,
        'district': _district!,
        'subcounty': _subcountyCtrl.text.trim(),
        'village': _villageCtrl.text.trim(),
        'storeType': _storeType!,
        'agentId': widget.agentId,
        'userId': userId,
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Store')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ResponsiveWrapper(
          maxWidth: 700,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                CustomTextField(
                    label: 'Store Name', controller: _storeNameCtrl),
                CustomTextField(
                    label: 'Owner Name', controller: _ownerNameCtrl),
                CustomTextField(label: 'Phone', controller: _phoneCtrl),
                CustomDropdown(
                  label: 'Store Type',
                  value: _storeType,
                  items: const [
                    'Farm Store',
                    'Produce Store',
                    'Wholesale Store'
                  ],
                  onChanged: (v) => setState(() => _storeType = v),
                ),
                CustomDropdown(
                    label: 'District',
                    value: _district,
                    items: AppConstants.bunyoroDistricts,
                    onChanged: (v) => setState(() => _district = v)),
                CustomTextField(label: 'Subcounty', controller: _subcountyCtrl),
                CustomTextField(label: 'Village', controller: _villageCtrl),
                CustomButton(
                    text: 'Register Store',
                    onPressed: _save,
                    isLoading: _loading),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Register Dealer Screen ───────────────────────────
class RegisterDealerScreen extends StatefulWidget {
  final String agentId;
  const RegisterDealerScreen({super.key, required this.agentId});

  @override
  State<RegisterDealerScreen> createState() => _RegisterDealerScreenState();
}

class _RegisterDealerScreenState extends State<RegisterDealerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bizNameCtrl = TextEditingController();
  final _regNumCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _subcountyCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  String? _productType;
  String? _district;
  bool _loading = false;

  @override
  void dispose() {
    _bizNameCtrl.dispose();
    _regNumCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _subcountyCtrl.dispose();
    _villageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() ||
        _district == null ||
        _productType == null) return;
    setState(() => _loading = true);
    try {
      final db = DatabaseService();
      final auth = AuthService();
      final phone = _phoneCtrl.text.trim();
      final bizName = _bizNameCtrl.text.trim();
      final sanitized = sanitizeEmailPart(bizName);
      final email = 'dealer.$sanitized@bfarm.local';
      final password = phone.replaceAll(RegExp(r'[^0-9]'), '');

      // Dealers also get login accounts if they want to access the marketplace
      try {
        await auth.registerUserByAgent(
          email: email,
          password: password,
          role: 'Buyer', // Dealers act as buyers for bulk or sellers for inputs
          agentId: widget.agentId,
          profileData: {
            'firstName': bizName,
            'lastName': '(Dealer)',
            'name': bizName,
            'phone': phone,
            'district': _district ?? '',
            'subcounty': _subcountyCtrl.text.trim(),
            'village': _villageCtrl.text.trim(),
            'userCategory': 'Buyer',
            'bio': 'Input Dealer • $_productType',
          },
        );
      } catch (e) {
        if (!e.toString().contains('email-already-in-use')) rethrow;
      }

      await db.addInputDealer(InputDealerModel(
        id: '',
        businessName: bizName,
        registrationNumber: _regNumCtrl.text.trim(),
        productType: _productType!,
        phone: phone,
        district: _district!,
        subcounty: _subcountyCtrl.text.trim(),
        village: _villageCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        registeredBy: widget.agentId,
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Dealer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ResponsiveWrapper(
          maxWidth: 700,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                CustomTextField(
                    label: 'Business Name', controller: _bizNameCtrl),
                CustomTextField(label: 'Phone', controller: _phoneCtrl),
                CustomDropdown(
                    label: 'Product Type',
                    value: _productType,
                    items: AppConstants.inputProductTypes,
                    onChanged: (v) => setState(() => _productType = v)),
                CustomDropdown(
                    label: 'District',
                    value: _district,
                    items: AppConstants.bunyoroDistricts,
                    onChanged: (v) => setState(() => _district = v)),
                CustomTextField(label: 'Subcounty', controller: _subcountyCtrl),
                CustomTextField(label: 'Village', controller: _villageCtrl),
                CustomButton(
                    text: 'Register Dealer',
                    onPressed: _save,
                    isLoading: _loading),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
