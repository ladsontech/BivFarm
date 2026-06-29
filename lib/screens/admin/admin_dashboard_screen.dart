import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/registry_bids_tab.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/responsive_wrapper.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _db = DatabaseService();
  bool _sidebarOpen = false;

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final isMobile = MediaQuery.sizeOf(context).width < AppBreakpoints.desktop;

    return FutureBuilder<UserModel?>(
        future: auth.getCurrentUserModel(),
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(
                    child: CircularProgressIndicator(color: AppTheme.green)));
          }
          if (userSnap.hasError) {
            return const Scaffold(
              body: AppErrorState(title: 'Unable to load the admin dashboard'),
            );
          }

          return Scaffold(
            appBar: null,
            body: Row(
              children: [
                // Sidebar - collapsible
                if (!isMobile || _sidebarOpen)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: !isMobile || _sidebarOpen ? 240 : 0,
                    child: Container(
                      color: AppTheme.surface,
                      child: Column(
                        children: [
                          // Sidebar header
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(color: AppTheme.border)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Admin',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                if (isMobile)
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _sidebarOpen = false),
                                    child: Icon(Icons.close,
                                        size: 18, color: AppTheme.textMuted),
                                  ),
                              ],
                            ),
                          ),
                          // Menu items
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  _sidebarItem('Analytics',
                                      Icons.analytics_outlined, () {}),
                                  _sidebarItem('Registry Database',
                                      Icons.storage_outlined, () {}),
                                  _sidebarItem(
                                      'Users', Icons.people_outline, () {}),
                                  _sidebarItem(
                                      'Agents', Icons.person_outline, () {}),
                                  _sidebarItem('Create Farmer',
                                      Icons.agriculture_outlined, () {}),
                                  _sidebarItem('Create Group',
                                      Icons.groups_outlined, () {}),
                                  _sidebarItem('Register Store',
                                      Icons.storefront_outlined, () {}),
                                  _sidebarItem('Register Dealer',
                                      Icons.business_outlined, () {}),
                                  _sidebarItem('My Listings',
                                      Icons.inventory_2_outlined, () {}),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Main content
                Expanded(
                  child: Column(
                    children: [
                      // Thin header
                      Container(
                        height: 48,
                        color: AppTheme.surface,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  color: AppTheme.border, width: 0.5)),
                        ),
                        child: Row(
                          children: [
                            // Sidebar toggle
                            if (!_sidebarOpen)
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _sidebarOpen = true),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: Icon(Icons.menu,
                                      size: 20, color: AppTheme.green),
                                ),
                              ),
                            // Title
                            Text(
                              'Bids & Orders',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                      // Bids content
                      Expanded(
                        child: RegistryBidsTab(db: _db),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }

  Widget _sidebarItem(String label, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, size: 18, color: AppTheme.green),
      title: Text(label,
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      minLeadingWidth: 24,
      dense: true,
      hoverColor: AppTheme.surfaceLight,
    );
  }
}
