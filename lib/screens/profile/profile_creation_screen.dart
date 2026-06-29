import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../utils/constants.dart';

class ProfileCreationScreen extends StatefulWidget {
  final String userId;
  const ProfileCreationScreen({super.key, required this.userId});

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  String? _gender;
  String? _district;
  String? _subcounty;
  String? _village;
  bool _loading = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gender == null || _district == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select gender and district')));
      return;
    }

    setState(() => _loading = true);
    try {
      final db = DatabaseService();
      await db.updateUser(widget.userId, {
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'name': '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
        'phone': _phoneCtrl.text.trim(),
        'gender': _gender,
        'district': _district,
        'subcounty': _subcounty ?? '',
        'village': _village ?? '',
        'bio': _bioCtrl.text.trim(),
        'isProfileComplete': true,
      });
      // The state change in Firestore will trigger a rebuild in the AuthWrapper/HomeShell
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Profile'),
        actions: [
          TextButton(
            onPressed: () =>
                Provider.of<AuthService>(context, listen: false).signOut(),
            child: const Text('Sign Out'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ResponsiveWrapper(
          maxWidth: 700,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tell us more about yourself',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'This information helps us personalize your experience.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                        child: CustomTextField(
                            label: 'First Name',
                            hint: 'Jane',
                            controller: _firstNameCtrl)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: CustomTextField(
                            label: 'Last Name',
                            hint: 'Doe',
                            controller: _lastNameCtrl)),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Phone Number',
                  hint: '07.. ... ...',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Bio / Specialization (Optional)',
                  hint: 'e.g. Pigs Farmer, Fruit Specialist',
                  controller: _bioCtrl,
                ),
                const SizedBox(height: 16),
                CustomDropdown(
                  label: 'Gender',
                  value: _gender,
                  items: const ['Male', 'Female'],
                  onChanged: (v) => setState(() => _gender = v),
                ),
                const SizedBox(height: 16),
                CustomDropdown(
                  label: 'District',
                  value: _district,
                  items: AppConstants.bunyoroDistricts,
                  onChanged: (v) => setState(() => _district = v),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                    label: 'Subcounty (Optional)',
                    hint: 'e.g. Buseruka',
                    onChanged: (v) => _subcounty = v),
                const SizedBox(height: 16),
                CustomTextField(
                    label: 'Village (Optional)',
                    hint: 'e.g. Kaiso',
                    onChanged: (v) => _village = v),
                const SizedBox(height: 40),
                CustomButton(
                  text: 'Complete Setup',
                  onPressed: _save,
                  isLoading: _loading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
