import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../utils/image_source_picker.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../services/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _db = DatabaseService();
  final _storage = StorageService();
  final _picker = ImagePicker();

  bool _editingPersonal = false;
  bool _editingLocation = false;
  bool _uploadingPhoto = false;

  // Personal info controllers
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _phoneCtrl;
  String? _gender;

  // Location controllers
  String? _district;
  late TextEditingController _subcountyCtrl;
  late TextEditingController _villageCtrl;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _firstNameCtrl = TextEditingController(text: widget.user.firstName);
    _lastNameCtrl = TextEditingController(text: widget.user.lastName);
    _phoneCtrl = TextEditingController(text: widget.user.phone);
    _gender = widget.user.gender.isNotEmpty ? widget.user.gender : null;
    _district = widget.user.district.isNotEmpty ? widget.user.district : null;
    _subcountyCtrl = TextEditingController(text: widget.user.subcounty);
    _villageCtrl = TextEditingController(text: widget.user.village);
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id) {
      _initControllers();
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _subcountyCtrl.dispose();
    _villageCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    final picked = await showImageSourcePicker(context);
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final url = await _storage.uploadImage(File(picked.path), 'profile_photos');
      await _db.updateUser(widget.user.id, {'profilePhoto': url});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _uploadingPhoto = false);
  }

  Future<void> _savePersonalInfo() async {
    if (_firstNameCtrl.text.trim().isEmpty || _lastNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }
    try {
      await _db.updateUser(widget.user.id, {
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'name': '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
        'phone': _phoneCtrl.text.trim(),
        'gender': _gender ?? '',
      });
      setState(() => _editingPersonal = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Personal info updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _saveLocation() async {
    try {
      await _db.updateUser(widget.user.id, {
        'district': _district ?? '',
        'subcounty': _subcountyCtrl.text.trim(),
        'village': _villageCtrl.text.trim(),
      });
      setState(() => _editingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ─── Header / Avatar ───────────────────────
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _uploadingPhoto ? null : _changePhoto,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.surfaceLight,
                  backgroundImage: user.profilePhoto != null ? NetworkImage(user.profilePhoto!) : null,
                  child: _uploadingPhoto
                      ? const CircularProgressIndicator(strokeWidth: 2, color: AppTheme.greenLight)
                      : (user.profilePhoto == null
                          ? Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.background, width: 3),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            user.name.isNotEmpty ? user.name : 'No Name',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.greenSurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  user.role,
                  style: const TextStyle(color: AppTheme.greenLight, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              if (user.district.isNotEmpty) ...[
                const SizedBox(width: 8),
                Icon(Icons.location_on_outlined, color: AppTheme.textMuted, size: 14),
                const SizedBox(width: 2),
                Text(
                  user.district,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ],
            ],
          ),
          const SizedBox(height: 28),

          // ─── Personal Info Card ────────────────────
          _buildCard(
            title: 'Personal Information',
            icon: Icons.person_outline,
            isEditing: _editingPersonal,
            onEdit: () => setState(() => _editingPersonal = true),
            onCancel: () {
              _firstNameCtrl.text = user.firstName;
              _lastNameCtrl.text = user.lastName;
              _phoneCtrl.text = user.phone;
              _gender = user.gender.isNotEmpty ? user.gender : null;
              setState(() => _editingPersonal = false);
            },
            onSave: _savePersonalInfo,
            child: _editingPersonal
                ? Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _editField('First Name', _firstNameCtrl)),
                          const SizedBox(width: 12),
                          Expanded(child: _editField('Last Name', _lastNameCtrl)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _editField('Phone', _phoneCtrl, keyboard: TextInputType.phone),
                      const SizedBox(height: 12),
                      CustomDropdown(
                        label: 'Gender',
                        value: _gender,
                        items: const ['Male', 'Female'],
                        onChanged: (v) => setState(() => _gender = v),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _infoRow(Icons.person, 'Full Name', '${user.firstName} ${user.lastName}'.trim()),
                      _infoRow(Icons.phone, 'Phone', user.phone.isNotEmpty ? user.phone : 'Not set'),
                      _infoRow(Icons.wc, 'Gender', user.gender.isNotEmpty ? user.gender : 'Not set'),
                    ],
                  ),
          ),
          const SizedBox(height: 14),

          // ─── Location Card ─────────────────────────
          _buildCard(
            title: 'Location',
            icon: Icons.location_on_outlined,
            isEditing: _editingLocation,
            onEdit: () => setState(() => _editingLocation = true),
            onCancel: () {
              _district = user.district.isNotEmpty ? user.district : null;
              _subcountyCtrl.text = user.subcounty;
              _villageCtrl.text = user.village;
              setState(() => _editingLocation = false);
            },
            onSave: _saveLocation,
            child: _editingLocation
                ? Column(
                    children: [
                      CustomDropdown(
                        label: 'District',
                        value: _district,
                        items: AppConstants.bunyoroDistricts,
                        onChanged: (v) => setState(() => _district = v),
                      ),
                      const SizedBox(height: 12),
                      _editField('Subcounty', _subcountyCtrl),
                      const SizedBox(height: 12),
                      _editField('Village', _villageCtrl),
                    ],
                  )
                : Column(
                    children: [
                      _infoRow(Icons.map, 'District', user.district.isNotEmpty ? user.district : 'Not set'),
                      _infoRow(Icons.location_city, 'Subcounty', user.subcounty.isNotEmpty ? user.subcounty : 'Not set'),
                      _infoRow(Icons.house, 'Village', user.village.isNotEmpty ? user.village : 'Not set'),
                    ],
                  ),
          ),
          const SizedBox(height: 14),

          // ─── Account Card ──────────────────────────
          _buildCard(
            title: 'Account',
            icon: Icons.account_circle_outlined,
            child: Column(
              children: [
                _infoRow(Icons.email, 'Email', user.email.isNotEmpty ? user.email : 'Not set'),
                _infoRow(Icons.shield_outlined, 'Role', user.role),
                _infoRow(Icons.calendar_today, 'Member Since', _formatDate(user.createdAt)),
                _infoRow(
                  Icons.verified,
                  'Status',
                  user.isVerified ? 'Verified' : 'Unverified',
                  valueColor: user.isVerified ? AppTheme.greenLight : AppTheme.warning,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ─── Settings Card ─────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.settings_outlined, color: AppTheme.textMuted, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Settings',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Dark mode toggle
                Row(
                  children: [
                    Icon(
                      themeProvider.isDark ? Icons.dark_mode : Icons.light_mode,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Dark Mode',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                      ),
                    ),
                    Switch(
                      value: themeProvider.isDark,
                      activeThumbColor: AppTheme.greenLight,
                      onChanged: (v) => themeProvider.setDark(v),
                    ),
                  ],
                ),

                Divider(color: AppTheme.border, height: 24),

                // Sign out
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Sign Out', style: TextStyle(color: AppTheme.textPrimary)),
                        content: Text('Are you sure you want to sign out?', style: TextStyle(color: AppTheme.textSecondary)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              Provider.of<AuthService>(context, listen: false).signOut();
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: AppTheme.error, size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Sign Out',
                          style: TextStyle(color: AppTheme.error, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ─── Help & Support Card ─────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.help_outline, color: AppTheme.green, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Help & Support',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'For inquiries or Web/WhatsApp direct messaging, please contact us:',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.email, color: AppTheme.textMuted, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'infobivmark@gmail.com',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.phone, color: AppTheme.textMuted, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '+256 792 110485',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
    bool isEditing = false,
    VoidCallback? onEdit,
    VoidCallback? onCancel,
    VoidCallback? onSave,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.textMuted, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onEdit != null && !isEditing)
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.greenSurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Edit',
                      style: TextStyle(color: AppTheme.greenLight, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              if (isEditing) ...[
                GestureDetector(
                  onTap: onCancel,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onSave,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.green,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 18),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editField(String label, TextEditingController ctrl, {TextInputType? keyboard}) {
    return CustomTextField(
      label: label,
      controller: ctrl,
      keyboardType: keyboard ?? TextInputType.text,
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
