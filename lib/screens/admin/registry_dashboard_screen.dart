import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';

class RegistryDashboardScreen extends StatefulWidget {
  const RegistryDashboardScreen({super.key});

  @override
  State<RegistryDashboardScreen> createState() => _RegistryDashboardScreenState();
}

class _RegistryDashboardScreenState extends State<RegistryDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
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
        title: const Text('Registry'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Users'),
            Tab(text: 'Listings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _RegistryUsersTab(db: _db),
          _RegistryListingsTab(db: _db),
        ],
      ),
    );
  }
}

class _RegistryUsersTab extends StatelessWidget {
  final DatabaseService db;
  const _RegistryUsersTab({required this.db});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserModel>>(
      future: db.getAllUsers(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppTheme.green));
        }
        final users = snap.data ?? [];
        if (users.isEmpty) {
          return Center(child: Text('No users', style: TextStyle(color: AppTheme.textMuted)));
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
                        if (u.phone.isNotEmpty)
                          Text(u.phone, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: u.isVerified ? AppTheme.greenSurface : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      u.isVerified ? 'Verified' : 'Unverified',
                      style: TextStyle(color: u.isVerified ? AppTheme.greenLight : AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
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

class _RegistryListingsTab extends StatelessWidget {
  final DatabaseService db;
  const _RegistryListingsTab({required this.db});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: db.getAllProducts(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppTheme.green));
        }
        final products = snap.data ?? [];
        if (products.isEmpty) {
          return Center(child: Text('No listings', style: TextStyle(color: AppTheme.textMuted)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (ctx, i) {
            final p = products[i];
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
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.greenSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.eco, color: AppTheme.greenLight, size: 22),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.productName, style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                        Text('${p.category} • ${p.district}', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(
                    'UGX ${p.price.toStringAsFixed(0)}',
                    style: TextStyle(color: AppTheme.greenLight, fontSize: 13, fontWeight: FontWeight.w600),
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
