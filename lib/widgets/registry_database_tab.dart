import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/input_dealer_model.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_wrapper.dart';

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
            return _DatabaseTile(
              title: s['storeName'] ?? 'Unknown Store',
              subtitle: 'Owner: ${s['ownerName']} • ${s['district']}',
              info: s['phone'] ?? '',
              icon: Icons.storefront,
              color: AppTheme.info,
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

  const _DatabaseTile({
    required this.title,
    required this.subtitle,
    required this.info,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
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
    );
  }
}
