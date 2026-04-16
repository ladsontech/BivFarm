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
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _auth = AuthService();
  String _selectedRole = 'Buyer';
  bool _loading = false;
  bool _showPassword = false;

  final List<Map<String, dynamic>> _roles = [
    {'name': 'Farmer', 'icon': Icons.grass, 'desc': 'List and sell your produce'},
    {'name': 'Buyer', 'icon': Icons.shopping_bag_outlined, 'desc': 'Browse and bid on products'},
  ];

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.register(_emailCtrl.text, _passwordCtrl.text, _selectedRole);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose your role',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),

                // Role selector
                Row(
                  children: _roles.map((role) {
                    final selected = _selectedRole == role['name'];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = role['name']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.only(
                            right: role == _roles.first ? 6 : 0,
                            left: role == _roles.last ? 6 : 0,
                          ),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: selected ? AppTheme.greenSurface : AppTheme.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected ? AppTheme.green : AppTheme.border,
                              width: selected ? 1.5 : 0.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                role['icon'],
                                color: selected ? AppTheme.greenLight : AppTheme.textMuted,
                                size: 28,
                              ),
                              SizedBox(height: 8),
                              Text(
                                role['name'],
                                style: TextStyle(
                                  color: selected ? AppTheme.textPrimary : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                role['desc'],
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

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
                const SizedBox(height: 28),

                CustomButton(
                  text: 'Create Account',
                  onPressed: _register,
                  isLoading: _loading,
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
