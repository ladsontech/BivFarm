import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/validators.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();

  // Email/Password
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _showPassword = false;

  // Phone Auth
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _codeSent = false;
  String _fullPhone = '';

  // Common
  bool _loading = false;
  bool _isEmailLogin = true;

  String _formatPhone(String input) {
    String cleaned = input.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '+256${cleaned.substring(1)}';
    } else if (!cleaned.startsWith('+')) {
      cleaned = '+256$cleaned';
    }
    return cleaned;
  }

  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.signIn(_emailCtrl.text.trim(), _passwordCtrl.text);
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _resetPassword() async {
    final resetEmailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    bool localLoading = false;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Reset Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Enter your email address to receive a password reset link.', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: resetEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: localLoading ? null : () async {
                    final email = resetEmailCtrl.text.trim();
                    if (email.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter an email')),
                      );
                      return;
                    }
                    setState(() => localLoading = true);
                    try {
                      await _auth.resetPassword(email);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password reset email sent. Check your inbox.')),
                        );
                      }
                    } catch (e) {
                      setState(() => localLoading = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.greenLight,
                    foregroundColor: Colors.white,
                  ),
                  child: localLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Send Link'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      await _auth.signInWithGoogle();
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
          await _auth.signInWithPhoneCredential(credential);
        } catch (e) {
          if (mounted) _showError(e.toString());
        }
      },
    );
  }

  Future<void> _verifyCode() async {
    final code = _otpCtrl.text.trim();
    if (code.isEmpty || code.length < 6) {
      _showError('Please enter the 6-digit code');
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.signInWithOTP(code);
      final userModel = await _auth.getCurrentUserModel();
      if (userModel == null) {
        await _auth.signOut();
        if (mounted) {
          _showError('No account found. Please register first.');
          setState(() {
            _codeSent = false;
            _loading = false;
          });
        }
        return;
      }
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
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
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // ─── Logo ──────────────────────────────
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/Bfarm_icon.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Welcome Back',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sign in to your account',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 20),

              // ─── Toggle ────────────────────────────
              _buildToggle(),
              const SizedBox(height: 20),

              // ─── Form ──────────────────────────────
              _isEmailLogin ? _buildEmailForm() : _buildPhoneForm(),

              const SizedBox(height: 20),

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
              const SizedBox(height: 20),

              // ─── Google Button ─────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _signInWithGoogle,
                  icon: Icon(Icons.g_mobiledata, size: 24, color: AppTheme.textPrimary),
                  label: Text('Continue with Google', style: TextStyle(color: AppTheme.textPrimary)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: AppTheme.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ─── Register Link ─────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: const Text(
                      'Register',
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
          _toggleTab('Email', _isEmailLogin, () => setState(() {
            _isEmailLogin = true;
            _codeSent = false;
          })),
          _toggleTab('Phone', !_isEmailLogin, () => setState(() => _isEmailLogin = false)),
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
            hint: 'Enter your password',
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
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _resetPassword,
              child: const Text(
                'Forgot Password?',
                style: TextStyle(color: AppTheme.greenLight, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Sign In',
            onPressed: _loginWithEmail,
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
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Verify & Sign In',
            onPressed: _verifyCode,
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
