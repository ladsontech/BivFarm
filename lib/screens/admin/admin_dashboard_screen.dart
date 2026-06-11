import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/registry_bids_tab.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final currentUserId = auth.currentUser?.uid ?? '';
    
    return FutureBuilder<UserModel?>(
      future: auth.getCurrentUserModel(),
      builder: (context, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.green)));
        }
        
        // Just show the Bids & Orders view with filters at the top
        return Scaffold(
          appBar: null, // No app bar, filters are in the content
          body: Column(
            children: [
              // Header with menu button
              Container(
                color: AppTheme.surface,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      'Bids & Orders',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Tooltip(
                      message: 'Admin Menu',
                      child: IconButton(
                        icon: Icon(Icons.more_vert, color: AppTheme.textMuted, size: 20),
                        onPressed: () => _showAdminMenu(context, currentUserId),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                    ),
                  ],
                ),
              ),
              // Bids & Orders content with filters
              Expanded(
                child: RegistryBidsTab(db: _db),
              ),
            ],
          ),
        );
      }
    );
  }

  void _showAdminMenu(BuildContext context, String currentUserId) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 300,
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Admin Options',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Divider(height: 1, color: AppTheme.border),
              _menuItem(ctx, 'Analytics', Icons.analytics_outlined, () {
                Navigator.pop(ctx);
                // Will implement navigation
              }),
              _menuItem(ctx, 'Registry Database', Icons.storage_outlined, () {
                Navigator.pop(ctx);
                // Will implement navigation
              }),
              _menuItem(ctx, 'Users', Icons.people_outline, () {
                Navigator.pop(ctx);
                // Will implement navigation
              }),
              _menuItem(ctx, 'Agents', Icons.person_outline, () {
                Navigator.pop(ctx);
                // Will implement navigation
              }),
              _menuItem(ctx, 'Create Farmer', Icons.agriculture_outlined, () {
                Navigator.pop(ctx);
                // Will implement navigation
              }),
              _menuItem(ctx, 'My Listings', Icons.inventory_2_outlined, () {
                Navigator.pop(ctx);
                // Will implement navigation
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, size: 20, color: AppTheme.green),
      title: Text(label, style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      hoverColor: AppTheme.surfaceLight,
    );
  }
}
