import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../utils/image_source_picker.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/constants.dart';

class OnboardingScreen extends StatefulWidget {
  final String userId;
  const OnboardingScreen({super.key, required this.userId});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  final _picker = ImagePicker();
  int _currentPage = 0;

  // Step 1 — Welcome
  File? _avatarFile;

  // Step 2 — Personal Info
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _gender;

  // Step 3 — Location
  String? _district;
  String? _subcounty;
  String? _village;
  final _subcountyCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _subcountyCtrl.dispose();
    _villageCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 1) {
      // Validate personal info
      if (_firstNameCtrl.text.trim().isEmpty || _lastNameCtrl.text.trim().isEmpty) {
        _showError('Please enter your first and last name');
        return;
      }
      if (_gender == null) {
        _showError('Please select your gender');
        return;
      }
    }
    _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    _pageCtrl.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _pickAvatar() async {
    final picked = await showImageSourcePicker(context);
    if (picked != null) {
      setState(() => _avatarFile = File(picked.path));
    }
  }

  Future<void> _complete() async {
    if (_district == null) {
      _showError('Please select your district');
      return;
    }

    setState(() => _loading = true);
    try {
      String? photoUrl;
      if (_avatarFile != null) {
        photoUrl = await StorageService().uploadImage(_avatarFile!, 'profile_photos');
      }

      final data = <String, dynamic>{
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'name': '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
        'gender': _gender,
        'district': _district,
        'subcounty': _subcountyCtrl.text.trim(),
        'village': _villageCtrl.text.trim(),
        'isProfileComplete': true,
      };

      if (_phoneCtrl.text.trim().isNotEmpty) {
        data['phone'] = _phoneCtrl.text.trim();
      }
      if (photoUrl != null) {
        data['profilePhoto'] = photoUrl;
      }

      await DatabaseService().updateUser(widget.userId, data);
      // Firestore stream in HomeShell will auto-navigate
    } catch (e) {
      if (mounted) _showError('Error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Your Profile'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => Provider.of<AuthService>(context, listen: false).signOut(),
            child: Text('Sign Out', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
              child: Row(
                children: List.generate(3, (i) {
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 4,
                      margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: i <= _currentPage ? AppTheme.greenLight : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildWelcomePage(),
                  _buildPersonalInfoPage(),
                  _buildLocationPage(),
                ],
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _prevPage,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: AppTheme.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Back', style: TextStyle(color: AppTheme.textSecondary)),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _currentPage < 2
                        ? ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Next'),
                          )
                        : ElevatedButton(
                            onPressed: _loading ? null : _complete,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Complete Setup'),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step 1: Welcome ─────────────────────────────────
  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const Icon(Icons.waving_hand, color: AppTheme.warning, size: 48),
          const SizedBox(height: 20),
          Text(
            "Let's get you set up",
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a profile photo so others can recognize you on the marketplace.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),

          // Avatar picker
          GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: AppTheme.surfaceLight,
                  backgroundImage: _avatarFile != null ? FileImage(_avatarFile!) : null,
                  child: _avatarFile == null
                      ? Icon(Icons.person, color: AppTheme.textMuted.withOpacity(0.4), size: 56)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.background, width: 3),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _avatarFile != null ? 'Looking great! 🎉' : 'Tap to add photo',
            style: TextStyle(
              color: _avatarFile != null ? AppTheme.greenLight : AppTheme.textMuted,
              fontSize: 14,
              fontWeight: _avatarFile != null ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          if (_avatarFile == null)
            Text(
              'You can skip this and add one later',
              style: TextStyle(color: AppTheme.textMuted.withOpacity(0.6), fontSize: 12),
            ),
        ],
      ),
    );
  }

  // ─── Step 2: Personal Info ─────────────────────────────
  Widget _buildPersonalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Personal Information',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tell us a bit about yourself.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'First Name',
                  hint: 'Jane',
                  controller: _firstNameCtrl,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  label: 'Last Name',
                  hint: 'Doe',
                  controller: _lastNameCtrl,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          CustomTextField(
            label: 'Phone Number',
            hint: '07.. ... ...',
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.textMuted, size: 20),
          ),
          const SizedBox(height: 18),

          CustomDropdown(
            label: 'Gender',
            value: _gender,
            items: const ['Male', 'Female'],
            onChanged: (v) => setState(() => _gender = v),
          ),
        ],
      ),
    );
  }

  // ─── Step 3: Location ──────────────────────────────────
  Widget _buildLocationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Your Location',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This helps connect you with nearby farmers and buyers.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 28),

          CustomDropdown(
            label: 'District',
            value: _district,
            items: AppConstants.bunyoroDistricts,
            onChanged: (v) => setState(() => _district = v),
          ),
          const SizedBox(height: 18),

          CustomTextField(
            label: 'Subcounty (Optional)',
            hint: 'e.g. Buseruka',
            controller: _subcountyCtrl,
          ),
          const SizedBox(height: 18),

          CustomTextField(
            label: 'Village (Optional)',
            hint: 'e.g. Kaiso',
            controller: _villageCtrl,
          ),
          const SizedBox(height: 24),

          // Info box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.greenSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.green.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.greenLight, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You can update your location anytime from your profile settings.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
