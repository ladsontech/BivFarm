import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../bidding/bids_list_screen.dart';
import '../../widgets/my_listings_tab.dart';

class ManagementScreen extends StatefulWidget {
  final UserModel user;
  final int initialTabIndex;

  const ManagementScreen({
    super.key,
    required this.user,
    this.initialTabIndex = 0,
  });

  @override
  State<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends State<ManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppTheme.surface,
          child: TabBar(
            controller: _tabCtrl,
            labelColor: AppTheme.green,
            unselectedLabelColor: AppTheme.textMuted,
            indicatorColor: AppTheme.green,
            tabs: const [
              Tab(icon: Icon(Icons.gavel), text: 'Bids'),
              Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Listings'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              BidsListScreen(userId: widget.user.id, userRole: widget.user.role),
              MyListingsTab(userId: widget.user.id),
            ],
          ),
        ),
      ],
    );
  }
}
