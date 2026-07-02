import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/input_dealer_model.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class RegistryDatabaseTab extends StatefulWidget {
  final DatabaseService db;
  const RegistryDatabaseTab({super.key, required this.db});

  @override
  State<RegistryDatabaseTab> createState() => _RegistryDatabaseTabState();
}

class _RegistryDatabaseTabState extends State<RegistryDatabaseTab>
    with SingleTickerProviderStateMixin {
  late TabController _innerTabCtrl;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _innerTabCtrl = TabController(length: 4, vsync: this);
    _innerTabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _innerTabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Inner Tab Bar
        Container(
          color: AppTheme.surface,
          child: TabBar(
            controller: _innerTabCtrl,
            isScrollable: true,
            labelColor: AppTheme.green,
            unselectedLabelColor: AppTheme.textMuted,
            indicatorColor: AppTheme.green,
            indicatorWeight: 3,
            labelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Individuals'),
              Tab(text: 'Farmer Groups'),
              Tab(text: 'Produce Stores'),
              Tab(text: 'Input Dealers'),
            ],
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search database...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() {
                            _searchCtrl.clear();
                            _query = '';
                          }))
                  : null,
            ),
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _innerTabCtrl,
            children: [
              _IndividualsList(db: widget.db, query: _query),
              _GroupsList(db: widget.db, query: _query),
              _StoresList(db: widget.db, query: _query),
              _DealersList(db: widget.db, query: _query),
            ],
          ),
        ),
      ],
    );
  }
}

class _IndividualsList extends StatelessWidget {
  final DatabaseService db;
  final String query;
  const _IndividualsList({required this.db, required this.query});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: Stream.fromFuture(db.getAllUsers()),
      builder: (ctx, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final users = snap.data!
            .where((u) => u.role == 'Farmer' || u.role == 'Buyer')
            .where((u) {
          final q = query.toLowerCase();
          return u.name.toLowerCase().contains(q) ||
              u.phone.contains(q) ||
              u.district.toLowerCase().contains(q);
        }).toList();

        if (users.isEmpty)
          return const Center(child: Text('No individuals found'));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: users.length,
          itemBuilder: (ctx, i) {
            final u = users[i];
            return _DatabaseTile(
              title: u.name,
              subtitle: '${u.role} • ${u.district}',
              info: u.phone,
              icon: u.role == 'Farmer' ? Icons.person : Icons.shopping_cart,
              color: u.role == 'Farmer' ? AppTheme.green : AppTheme.info,
              onTap: () {
                _showDetailsSheet(
                  context,
                  title: u.name,
                  subtitle: '${u.role} Account Details',
                  icon: u.role == 'Farmer' ? Icons.person : Icons.shopping_cart,
                  color: u.role == 'Farmer' ? AppTheme.green : AppTheme.info,
                  phone: u.phone,
                  details: {
                    'User ID': u.id,
                    'Full Name': u.name,
                    'First Name': u.firstName,
                    'Last Name': u.lastName,
                    'Role': u.role,
                    'Phone Number': u.phone,
                    'District': u.district,
                    'Subcounty': u.subcounty,
                    'Village': u.village,
                    'Profile Complete': u.isProfileComplete ? 'Yes' : 'No',
                    'Email Address': u.email.isNotEmpty ? u.email : 'None',
                    'Registered At': DateFormat('yyyy-MM-dd').format(u.createdAt),
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _GroupsList extends StatelessWidget {
  final DatabaseService db;
  final String query;
  const _GroupsList({required this.db, required this.query});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FarmerGroupModel>>(
      stream: db.streamAllGroups(),
      builder: (ctx, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final items = snap.data!.where((g) {
          final q = query.toLowerCase();
          return g.groupName.toLowerCase().contains(q) ||
              g.district.toLowerCase().contains(q);
        }).toList();

        if (items.isEmpty)
          return const Center(child: Text('No farmer groups found'));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          itemBuilder: (ctx, i) {
            final g = items[i];
            return _DatabaseTile(
              title: g.groupName,
              subtitle: 'Leader: ${g.leaderName} • ${g.district}',
              info: '${g.memberCount} members',
              icon: Icons.groups,
              color: AppTheme.warning,
              onTap: () {
                _showDetailsSheet(
                  context,
                  title: g.groupName,
                  subtitle: 'Farmer Group Details',
                  icon: Icons.groups,
                  color: AppTheme.warning,
                  phone: g.leaderPhone,
                  details: {
                    'Group ID': g.id,
                    'Group Name': g.groupName,
                    'Leader Name': g.leaderName,
                    'Leader Phone': g.leaderPhone,
                    'Member Count': '${g.memberCount}',
                    'Category': g.category.isNotEmpty ? g.category : 'General',
                    'District': g.district,
                    'Subcounty': g.subcounty,
                    'Village': g.village,
                    'Registered At': DateFormat('yyyy-MM-dd').format(g.createdAt),
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _StoresList extends StatelessWidget {
  final DatabaseService db;
  final String query;
  const _StoresList({required this.db, required this.query});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: db.streamAllProduceStores(),
      builder: (ctx, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final items = snap.data!.where((s) {
          final q = query.toLowerCase();
          return (s['storeName'] ?? '').toString().toLowerCase().contains(q) ||
              (s['district'] ?? '').toString().toLowerCase().contains(q);
        }).toList();

        if (items.isEmpty) return const Center(child: Text('No stores found'));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          itemBuilder: (ctx, i) {
            final s = items[i];
            final storeName = s['storeName'] ?? 'Unknown Store';
            return _DatabaseTile(
              title: storeName,
              subtitle: 'Owner: ${s['ownerName']} • ${s['district']}',
              info: s['phone'] ?? '',
              icon: Icons.storefront,
              color: AppTheme.info,
              onTap: () {
                _showDetailsSheet(
                  context,
                  title: storeName,
                  subtitle: 'Produce Store Details',
                  icon: Icons.storefront,
                  color: AppTheme.info,
                  phone: s['phone'] ?? '',
                  details: {
                    'Store ID': s['id'] ?? '-',
                    'Store Name': storeName,
                    'Owner Name': s['ownerName'] ?? '-',
                    'Phone Number': s['phone'] ?? '-',
                    'District': s['district'] ?? '-',
                    'Subcounty': s['subcounty'] ?? '-',
                    'Village': s['village'] ?? '-',
                    'Address': s['address'] ?? '-',
                    'Is Active': (s['isActive'] == true) ? 'Yes' : 'No',
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _DealersList extends StatelessWidget {
  final DatabaseService db;
  final String query;
  const _DealersList({required this.db, required this.query});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InputDealerModel>>(
      stream: db.streamAllInputDealers(),
      builder: (ctx, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final items = snap.data!.where((d) {
          final q = query.toLowerCase();
          return d.businessName.toLowerCase().contains(q) ||
              d.district.toLowerCase().contains(q);
        }).toList();

        if (items.isEmpty) return const Center(child: Text('No dealers found'));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          itemBuilder: (ctx, i) {
            final d = items[i];
            return _DatabaseTile(
              title: d.businessName,
              subtitle: '${d.productType} • ${d.district}',
              info: d.phone,
              icon: Icons.business,
              color: AppTheme.error,
              onTap: () {
                _showDetailsSheet(
                  context,
                  title: d.businessName,
                  subtitle: 'Input Dealer Details',
                  icon: Icons.business,
                  color: AppTheme.error,
                  phone: d.phone,
                  details: {
                    'Dealer ID': d.id,
                    'Business Name': d.businessName,
                    'Reg. Number': d.registrationNumber,
                    'Product Type': d.productType,
                    'Phone Number': d.phone,
                    'District': d.district,
                    'Subcounty': d.subcounty,
                    'Village': d.village,
                    'Address': d.address,
                    'Is Verified': d.isVerified ? 'Yes' : 'No',
                    'Is Active': d.isActive ? 'Yes' : 'No',
                    'Registered At': DateFormat('yyyy-MM-dd').format(d.createdAt),
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _DatabaseTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String info;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DatabaseTile({
    required this.title,
    required this.subtitle,
    required this.info,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.border, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(subtitle,
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    Text(info,
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

void _showDetailsSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required Map<String, String> details,
  required IconData icon,
  required Color color,
  String? phone,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...details.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value.isNotEmpty ? entry.value : '-',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            if (phone != null && phone.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Phone number $phone copied to clipboard'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy Phone'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.surfaceLight,
                        foregroundColor: AppTheme.textPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Calling $phone...'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.phone, size: 18),
                      label: const Text('Call Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}
