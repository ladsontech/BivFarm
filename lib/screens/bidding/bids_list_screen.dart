import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/bid_model.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../models/message_model.dart';
import '../orders/admin_bulk_orders_tab.dart';

class BidsListScreen extends StatelessWidget {
  final String userId;
  final String userRole;

  const BidsListScreen({super.key, required this.userId, required this.userRole});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    final formatter = NumberFormat('#,###');

    if (userRole == 'Admin' || userRole == 'Registry') {
      return DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: AppTheme.surface,
              child: TabBar(
                labelColor: AppTheme.green,
                unselectedLabelColor: AppTheme.textMuted,
                indicatorColor: AppTheme.green,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Standard Bids'),
                  Tab(text: 'Bulk Orders'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  FutureBuilder<List<BidModel>>(
                    future: db.getAllBids(),
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppTheme.green));
                      }
                      return _buildBidList(snap.data ?? [], formatter, userRole, db);
                    },
                  ),
                  AdminBulkOrdersTab(db: db),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (userRole == 'Farmer') {
      return DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: AppTheme.surface,
              child: TabBar(
                labelColor: AppTheme.green,
                unselectedLabelColor: AppTheme.textMuted,
                indicatorColor: AppTheme.green,
                indicatorWeight: 2,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: 'Received Offers'),
                  Tab(text: 'My Bids'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  StreamBuilder<List<BidModel>>(
                    stream: db.streamBidsBySeller(userId),
                    builder: (ctx, snap) => _buildStreamContent(snap, formatter, 'Received Offers', db, 'Farmer'),
                  ),
                  StreamBuilder<List<BidModel>>(
                    stream: db.streamBidsByBuyer(userId),
                    builder: (ctx, snap) => _buildStreamContent(snap, formatter, 'My Placed Bids', db, 'Buyer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Standard view for other roles (Agent, Buyer)
    return StreamBuilder<List<BidModel>>(
      stream: db.streamBidsByBuyer(userId),
      builder: (ctx, snap) => _buildStreamContent(snap, formatter, 'My Bids', db, userRole),
    );
  }

  Widget _buildStreamContent(AsyncSnapshot<List<BidModel>> snap, NumberFormat formatter, String title, DatabaseService db, String role) {
    if (snap.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.green));
    }
    final bids = snap.data ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            title,
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ),
        Expanded(
          child: _buildBidList(bids, formatter, role, db),
        ),
      ],
    );
  }

  Widget _buildBidList(List<BidModel> bids, NumberFormat formatter, String role, DatabaseService db) {
    if (bids.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(role == 'Farmer' ? Icons.chat_bubble_outline : Icons.gavel, color: AppTheme.textMuted.withOpacity(0.3), size: 64),
            const SizedBox(height: 16),
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
        final isAdmin = role == 'Admin' || role == 'Registry';
        final isAgent = role == 'Agent';
        final canManage = isAdmin || isAgent;
        
        return ResponsiveWrapper(
          maxWidth: 800,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border, width: 0.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
            ),
          child: Column(
            children: [
              // Price & Status Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.greenSurface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.gavel, color: AppTheme.greenDark, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('UGX ${formatter.format(bid.offeredPrice)}', style: TextStyle(color: AppTheme.greenDark, fontSize: 18, fontWeight: FontWeight.w800)),
                          Text('${bid.productName} • Qty: ${bid.quantity}', style: TextStyle(color: AppTheme.greenDark.withOpacity(0.7), fontSize: 12)),
                        ],
                      ),
                    ),
                    if (canManage)
                      PopupMenuButton<String>(
                        tooltip: 'Change Status',
                        offset: const Offset(0, 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (v) {
                          db.updateBidStatus(bid.id, v);
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            enabled: false,
                            child: Text('Update State', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textMuted)),
                          ),
                          const PopupMenuDivider(),
                          ...['Pending', 'Under Review', 'Accepted', 'Rejected', 'Completed'].map(
                            (s) => PopupMenuItem(value: s, child: Row(children: [
                              Icon(s == bid.status ? Icons.radio_button_checked : Icons.radio_button_off, size: 16, color: s == bid.status ? AppTheme.greenLight : AppTheme.textMuted),
                              const SizedBox(width: 8),
                              Text(s),
                            ])),
                          ),
                        ],
                        child: BidStatusBadge(status: bid.status),
                      )
                    else
                      BidStatusBadge(status: bid.status),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Buyer Info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.surfaceLight,
                          child: Icon(role == 'Farmer' ? Icons.security : Icons.shopping_cart, color: AppTheme.textMuted, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                role == 'Farmer' ? 'From: Administrator' : (role == 'Buyer' ? 'Your bid' : bid.buyerName),
                                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              if (role != 'Farmer' && role != 'Buyer') 
                                Text('Buyer: ${bid.buyerPhone.isNotEmpty ? bid.buyerPhone : "No phone"}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        if (canManage)
                          IconButton(
                            icon: const Icon(Icons.message_outlined, color: AppTheme.greenLight, size: 20),
                            tooltip: 'Message Buyer',
                            onPressed: () => _showDirectMessageDialog(ctx, bid.buyerId, bid.buyerName, db),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Seller (Farmer) Info for Admins and Buyers
                    if (role != 'Farmer')
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.surfaceLight,
                            child: Icon(Icons.agriculture, color: AppTheme.textMuted, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bid.sellerName.isNotEmpty ? bid.sellerName : 'Farmer',
                                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                Text('Farmer: ${bid.sellerPhone.isNotEmpty ? bid.sellerPhone : "No phone"}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                          if (canManage)
                            IconButton(
                              icon: Icon(Icons.support_agent, color: AppTheme.green, size: 20),
                              tooltip: 'Leave notes & msg Farmer',
                              onPressed: () => _showMessageDialog(ctx, bid, db),
                            ),
                        ],
                      ),
                    
                    // Notes 
                    if (role != 'Farmer' && bid.notes != null && bid.notes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.notes, size: 14, color: AppTheme.textMuted),
                            const SizedBox(width: 6),
                            Expanded(child: Text(bid.notes!, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontStyle: FontStyle.italic))),
                          ],
                        ),
                      ),
                    ],
                    
                    // Admin Notes to Farmer
                    if (role == 'Farmer' && bid.adminNotes != null && bid.adminNotes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppTheme.greenSurface, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.forum, size: 14, color: AppTheme.greenLight),
                            const SizedBox(width: 6),
                            Expanded(child: Text(bid.adminNotes!, style: TextStyle(color: AppTheme.textPrimary, fontSize: 12))),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    // Date
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 13, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Text(DateFormat('MMM d, yyyy – h:mm a').format(bid.createdAt), style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      ],
                    ),

                    // Note: Action buttons moved up natively into UI. Status is handled by top right badge dropdown.
                  ],
                ),
              ),
            ],
          ),
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
        title: Text('Admin Note to Farmer', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
        content: TextField(
          controller: tc,
          maxLines: 3,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter details or instructions for the farmer...',
            hintStyle: TextStyle(color: AppTheme.textMuted),
            border: const OutlineInputBorder(),
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
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      ],
    );
  }

  void _showDirectMessageDialog(BuildContext context, String recipientId, String recipientName, DatabaseService db) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text('Message to $recipientName', style: TextStyle(color: AppTheme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(label: 'Subject', controller: titleCtrl),
              const SizedBox(height: 12),
              CustomTextField(label: 'Message', controller: bodyCtrl, maxLines: 4),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted))
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty || bodyCtrl.text.isEmpty) return;
                try {
                  await db.addMessage(MessageModel(
                    id: '',
                    senderId: 'admin',
                    senderName: 'Admin',
                    senderRole: 'Admin',
                    recipientId: recipientId,
                    subject: titleCtrl.text,
                    body: bodyCtrl.text,
                  ));
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message sent')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }
}
