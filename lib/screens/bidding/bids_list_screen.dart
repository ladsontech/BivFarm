import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/bid_model.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class BidsListScreen extends StatelessWidget {
  final String userId;
  final String userRole;

  const BidsListScreen({super.key, required this.userId, required this.userRole});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    final formatter = NumberFormat('#,###');

    Stream<List<BidModel>> bidStream;
    if (userRole == 'Admin' || userRole == 'Registry') {
      bidStream = db.streamBidsByProduct('').asBroadcastStream(); // will use getAllBids
    } else if (userRole == 'Farmer') {
      bidStream = db.streamBidsBySeller(userId);
    } else {
      bidStream = db.streamBidsByBuyer(userId);
    }

    return Scaffold(
      body: (userRole == 'Admin' || userRole == 'Registry')
          ? FutureBuilder<List<BidModel>>(
              future: db.getAllBids(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: AppTheme.green));
                }
                return _buildBidList(snap.data ?? [], formatter, userRole, db);
              },
            )
          : StreamBuilder<List<BidModel>>(
              stream: bidStream,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: AppTheme.green));
                }
                return _buildBidList(snap.data ?? [], formatter, userRole, db);
              },
            ),
    );
  }

  Widget _buildBidList(List<BidModel> bids, NumberFormat formatter, String role, DatabaseService db) {
    if (bids.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(role == 'Farmer' ? Icons.chat_bubble_outline : Icons.gavel, color: AppTheme.textMuted.withOpacity(0.3), size: 64),
            SizedBox(height: 16),
            Text(role == 'Farmer' ? 'No messages yet' : 'No bids yet', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bids.length,
      itemBuilder: (ctx, i) {
        final bid = bids[i];
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
                      bid.productName,
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  BidStatusBadge(status: bid.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _infoChip(Icons.scale, '${bid.quantity}'),
                  const SizedBox(width: 12),
                  // Farmers do not see the buyer's offered price natively, maybe they only see the amount if the admin approves it?
                  // Or maybe they see the price but not the buyer. For now, we show the price to the farmer since it's an offer on their product.
                  _infoChip(Icons.payments, 'UGX ${formatter.format(bid.offeredPrice)}'),
                ],
              ),
              const SizedBox(height: 6),
              // Hide buyer name for farmer
              if (role != 'Farmer')
                Text(
                  role == 'Buyer' ? 'Your bid' : 'By: ${bid.buyerName} • ${bid.buyerPhone}',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                )
              else
                Text(
                  'From: Administrator',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                
              // Hide buyer notes for farmer
              if (role != 'Farmer' && bid.notes != null && bid.notes!.isNotEmpty) ...[
                SizedBox(height: 4),
                Text(bid.notes!, style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontStyle: FontStyle.italic)),
              ],
              
              // Show Admin Notes to Farmer
              if (role == 'Farmer' && bid.adminNotes != null && bid.adminNotes!.isNotEmpty) ...[
                SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.greenSurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.forum, size: 14, color: AppTheme.greenLight),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          bid.adminNotes!,
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              SizedBox(height: 4),
              Text(
                DateFormat('MMM d, yyyy • hh:mm a').format(bid.createdAt),
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
              
              // Admin/Registry actions
              if (role == 'Admin' || role == 'Registry') ...[
                SizedBox(height: 10),
                Row(
                  children: [
                    _actionBtn('Msg Farmer', AppTheme.green, () {
                      _showMessageDialog(ctx, bid, db);
                    }),
                    SizedBox(width: 6),
                    _actionBtn('Accept', AppTheme.statusAccepted, () {
                      db.updateBidStatus(bid.id, 'Accepted');
                    }),
                    SizedBox(width: 6),
                    _actionBtn('Reject', AppTheme.statusRejected, () {
                      db.updateBidStatus(bid.id, 'Rejected');
                    }),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showMessageDialog(BuildContext context, BidModel bid, DatabaseService db) {
    final tc = TextEditingController(text: bid.adminNotes ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Message Farmer', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
        content: TextField(
          controller: tc,
          maxLines: 3,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter a message for the farmer...',
            hintStyle: TextStyle(color: AppTheme.textMuted),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              db.updateBidStatus(bid.id, bid.status, adminNotes: tc.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }


  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textMuted),
        SizedBox(width: 4),
        Text(text, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      ],
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}
