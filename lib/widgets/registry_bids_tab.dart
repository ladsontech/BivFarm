import 'package:flutter/material.dart';
import '../models/bid_model.dart';
import '../models/bulk_order_model.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class RegistryBidsTab extends StatefulWidget {
  final DatabaseService db;
  const RegistryBidsTab({super.key, required this.db});

  @override
  State<RegistryBidsTab> createState() => _RegistryBidsTabState();
}

class _RegistryBidsTabState extends State<RegistryBidsTab> with SingleTickerProviderStateMixin {
  late TabController _typeCtrl;

  @override
  void initState() {
    super.initState();
    _typeCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _typeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppTheme.surface,
          child: TabBar(
            controller: _typeCtrl,
            labelColor: AppTheme.green,
            unselectedLabelColor: AppTheme.textMuted,
            indicatorColor: AppTheme.green,
            tabs: const [
              Tab(text: 'Bulk Requests'),
              Tab(text: 'Individual Bids'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _typeCtrl,
            children: [
              _BulkRequestsList(db: widget.db),
              _IndividualBidsList(db: widget.db),
            ],
          ),
        ),
      ],
    );
  }
}

class _BulkRequestsList extends StatelessWidget {
  final DatabaseService db;
  const _BulkRequestsList({required this.db});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BulkOrderModel>>(
      stream: db.streamBulkOrders(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final orders = snap.data!;
        if (orders.isEmpty) return const Center(child: Text('No bulk requests yet'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (ctx, i) {
             final o = orders[i];
             return _OrderCard(
               title: o.itemName,
               subtitle: 'Quantity: ${o.quantity} ${o.quantityUnit}\nCategory: ${o.category}',
               status: o.status,
               date: o.createdAt,
               color: AppTheme.warning,
               onTap: () {
                 // Show fulfillment/matchmaking screen or detail sheet
               },
             );
          },
        );
      },
    );
  }
}

class _IndividualBidsList extends StatelessWidget {
  final DatabaseService db;
  const _IndividualBidsList({required this.db});

  void _verifyBid(BuildContext context, BidModel bid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify Bid'),
        content: Text('Are you sure you want to mark the bid for ${bid.productName} (UGX ${bid.offeredPrice.toInt()}) as verified by Registry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Verify Bid')),
        ],
      ),
    );

    if (confirmed == true) {
      await db.updateBid(bid.id, {'isRegistryVerified': true, 'status': 'Under Review'});
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BidModel>>(
      stream: db.streamAllBids(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final bids = snap.data!;
        if (bids.isEmpty) return const Center(child: Text('No individual bids yet'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bids.length,
          itemBuilder: (ctx, i) {
             final b = bids[i];
             return _OrderCard(
               title: b.productName,
               subtitle: 'Offer: UGX ${b.offeredPrice.toInt()}\nBuyer: ${b.buyerName}',
               status: b.isRegistryVerified ? 'Registry Verified' : b.status,
               date: b.createdAt,
               color: b.isRegistryVerified ? AppTheme.green : AppTheme.info,
               tailing: !b.isRegistryVerified ? ElevatedButton(
                 onPressed: () => _verifyBid(context, b),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: AppTheme.green,
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                   textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)
                 ),
                 child: const Text('Verify'),
               ) : const Icon(Icons.verified, color: AppTheme.green, size: 20),
               onTap: () {},
             );
          },
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final DateTime date;
  final Color color;
  final Widget? tailing;
  final VoidCallback onTap;

  const _OrderCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.date,
    required this.color,
    this.tailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                        child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Text(DateFormat('MMM d, HH:mm').format(date), style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            if (tailing != null) tailing!,
          ],
        ),
      ),
    );
  }
}
