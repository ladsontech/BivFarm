import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/bid_model.dart';
import '../../services/demo_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class DemoBidsScreen extends StatefulWidget {
  final String userId;
  final String userRole;

  const DemoBidsScreen({super.key, required this.userId, required this.userRole});

  @override
  State<DemoBidsScreen> createState() => _DemoBidsScreenState();
}

class _DemoBidsScreenState extends State<DemoBidsScreen> {
  String _statusFilter = 'All';

  List<BidModel> get _filteredBids {
    List<BidModel> bids;
    switch (widget.userRole) {
      case 'Buyer':
        bids = DemoData.bidsByBuyer(widget.userId);
        break;
      case 'Farmer':
        bids = DemoData.bidsBySeller(widget.userId);
        break;
      default:
        bids = DemoData.bids;
    }
    if (_statusFilter != 'All') {
      bids = bids.where((b) => b.status == _statusFilter).toList();
    }
    return bids;
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final bids = _filteredBids;

    return Scaffold(
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['All', 'Pending', 'Under Review', 'Accepted', 'Rejected', 'Completed'].map((s) {
                final selected = _statusFilter == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(s, style: const TextStyle(fontSize: 12)),
                    selected: selected,
                    onSelected: (_) => setState(() => _statusFilter = s),
                    selectedColor: AppTheme.greenSurface,
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: bids.isEmpty
                ? Center(child: Text('No bids', style: TextStyle(color: AppTheme.textMuted)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: bids.length,
                    itemBuilder: (ctx, i) {
                      final b = bids[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border, width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    b.productName,
                                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                BidStatusBadge(status: b.status),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(children: [
                              Icon(widget.userRole == 'Buyer' ? Icons.person_outline : Icons.shopping_bag_outlined, color: AppTheme.textMuted, size: 14),
                              SizedBox(width: 6),
                              Text(widget.userRole == 'Buyer' ? 'You → seller' : '${b.buyerName} → you', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            ]),
                            SizedBox(height: 6),
                            Row(children: [
                              Text('Qty: ${b.quantity}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                              SizedBox(width: 16),
                              Text('UGX ${formatter.format(b.offeredPrice)}', style: TextStyle(color: AppTheme.greenLight, fontSize: 14, fontWeight: FontWeight.w600)),
                            ]),
                            if (b.notes != null) ...[
                              SizedBox(height: 6),
                              Text(b.notes!, style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontStyle: FontStyle.italic)),
                            ],
                            if (widget.userRole == 'Admin' || widget.userRole == 'Registry') ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated (Demo)'))),
                                      child: const Text('Review', style: TextStyle(fontSize: 12)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bid accepted (Demo)'))),
                                      child: const Text('Accept', style: TextStyle(fontSize: 12)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
