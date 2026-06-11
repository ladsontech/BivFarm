import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();

  // Email/Password
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _showPassword = false;

  // Phone Auth
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _codeSent = false;
  String _fullPhone = '';

  // Common
  String _selectedRole = 'Farmer';
  bool _loading = false;
  bool _isEmailRegister = true;

  String _formatPhone(String input) {
    String cleaned = input.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '+256${cleaned.substring(1)}';
    } else if (!cleaned.startsWith('+')) {
      cleaned = '+256$cleaned';
    }
    return cleaned;
  }

  Future<void> _registerWithEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      _showError('Passwords do not match');
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.register(_emailCtrl.text.trim(), _passwordCtrl.text, _selectedRole);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      await _auth.signInWithGoogle(defaultRole: _selectedRole);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _sendCode() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      _showError('Please enter your phone number');
      return;
    }
    _fullPhone = _formatPhone(phone);
    setState(() => _loading = true);

    await _auth.verifyPhoneNumber(
      phoneNumber: _fullPhone,
      onCodeSent: (verificationId) {
        if (mounted) {
          setState(() {
            _loading = false;
            _codeSent = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Code sent to $_fullPhone')),
          );
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _loading = false);
          _showError(error);
        }
      },
      onAutoVerified: (credential) async {
        try {
          final cred = await _auth.signInWithPhoneCredential(credential);
          await _auth.createUserIfNotExists(cred.user!.uid, _fullPhone, _selectedRole);
          if (mounted) Navigator.pop(context);
        } catch (e) {
          if (mounted) _showError(e.toString());
        }
      },
    );
  }

  Future<void> _verifyAndRegisterPhone() async {
    final code = _otpCtrl.text.trim();
    if (code.isEmpty || code.length < 6) {
      _showError('Please enter the 6-digit code');
      return;
    }
    setState(() => _loading = true);
    try {
      final cred = await _auth.signInWithOTP(code);
      await _auth.createUserIfNotExists(cred.user!.uid, _fullPhone, _selectedRole);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Role Picker ───────────────────────
              Text(
                'I want to join as a',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose how you want to use BFarm',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  _buildRoleCard(
                    role: 'Farmer',
                    icon: Icons.grass,
                    desc: 'List and sell your produce directly to buyers',
                  ),
                  const SizedBox(width: 12),
                  _buildRoleCard(
                    role: 'Buyer',
                    icon: Icons.shopping_bag_outlined,
                    desc: 'Browse products and place bids on listings',
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ─── Toggle ────────────────────────────
              _buildToggle(),
              const SizedBox(height: 24),

              // ─── Form ──────────────────────────────
              _isEmailRegister ? _buildEmailForm() : _buildPhoneForm(),

              const SizedBox(height: 28),

              // ─── OR Divider ────────────────────────
              Row(
                children: [
                  Expanded(child: Divider(color: AppTheme.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ),
                  Expanded(child: Divider(color: AppTheme.border)),
                ],
              ),
              const SizedBox(height: 28),

              // ─── Google Button ─────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _signInWithGoogle,
                  icon: Icon(Icons.g_mobiledata, size: 24, color: AppTheme.textPrimary),
                  label: Text('Sign Up with Google', style: TextStyle(color: AppTheme.textPrimary)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: AppTheme.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ─── Login Link ────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: AppTheme.greenLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      ),
      ),
    );
  }

  Widget _buildRoleCard({required String role, required IconData icon, required String desc}) {
    final selected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: _codeSent ? null : () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
          decoration: BoxDecoration(
            color: selected ? AppTheme.greenSurface : AppTheme.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppTheme.green : AppTheme.border,
              width: selected ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected ? AppTheme.green.withOpacity(0.15) : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: selected ? AppTheme.greenLight : AppTheme.textMuted,
                  size: 24,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                role,
                style: TextStyle(
                  color: selected ? AppTheme.textPrimary : AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11, height: 1.3),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _toggleTab('Email', _isEmailRegister, () => setState(() {
            _isEmailRegister = true;
            _codeSent = false;
          })),
          _toggleTab('Phone', !_isEmailRegister, () => setState(() => _isEmailRegister = false)),
        ],
      ),
    );
  }

  Widget _toggleTab(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.greenSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppTheme.greenDark : AppTheme.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextField(
            label: 'Email',
            hint: 'Enter your email',
            controller: _emailCtrl,
            validator: Validators.email,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textMuted, size: 20),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Password',
            hint: 'Create a password',
            controller: _passwordCtrl,
            validator: Validators.password,
            obscureText: !_showPassword,
            prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textMuted, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility_off : Icons.visibility,
                color: AppTheme.textMuted,
                size: 20,
              ),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Confirm Password',
            hint: 'Confirm your password',
            controller: _confirmPasswordCtrl,
            validator: Validators.password,
            obscureText: !_showPassword,
            prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textMuted, size: 20),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Create Account',
            onPressed: _registerWithEmail,
            isLoading: _loading,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneForm() {
    return Column(
      children: [
        if (!_codeSent) ...[
          CustomTextField(
            label: 'Phone Number',
            hint: '07XX XXX XXX',
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.textMuted, size: 20),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Send Verification Code',
            onPressed: _sendCode,
            isLoading: _loading,
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.greenSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.green.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppTheme.greenLight, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Code sent to $_fullPhone',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Enter OTP Code',
            hint: '123456',
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textMuted, size: 20),
            autofillHints: const [AutofillHints.oneTimeCode],
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Verify & Create Account',
            onPressed: _verifyAndRegisterPhone,
            isLoading: _loading,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => setState(() => _codeSent = false),
                child: const Text('Change Number'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _loading ? null : _sendCode,
                child: const Text('Resend Code'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
