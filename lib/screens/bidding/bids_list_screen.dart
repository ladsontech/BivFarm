import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/bid_model.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
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

    Stream<List<BidModel>> bidStream;
    if (userRole == 'Admin' || userRole == 'Registry') {
      bidStream = db.streamBidsByProduct('').asBroadcastStream(); // will use getAllBids
    } else if (userRole == 'Agent') {
      bidStream = db.streamBidsByAgent(userId);
    } else if (userRole == 'Farmer') {
      bidStream = db.streamBidsBySeller(userId);
    } else {
      bidStream = db.streamBidsByBuyer(userId);
    }

    final isAdmin = userRole == 'Admin' || userRole == 'Registry';
    final isAgent = userRole == 'Agent';
    final canManage = isAdmin || isAgent;

    if (isAdmin) {
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: AppBar(
              backgroundColor: AppTheme.surface,
              elevation: 0,
              bottom: TabBar(
                labelColor: AppTheme.green,
                unselectedLabelColor: AppTheme.textMuted,
                indicatorColor: AppTheme.green,
                tabs: const [
                  Tab(text: 'Standard Bids'),
                  Tab(text: 'Bulk Orders'),
                ],
              ),
            ),
          ),
          body: TabBarView(
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
      );
    }

    // Agent gets a similar tabbed view scoped to their farmers
    if (isAgent) {
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: AppBar(
              backgroundColor: AppTheme.surface,
              elevation: 0,
              title: Text('My Farmers\' Orders', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
              bottom: TabBar(
                labelColor: AppTheme.green,
                unselectedLabelColor: AppTheme.textMuted,
                indicatorColor: AppTheme.green,
                tabs: const [
                  Tab(text: 'Farmer Bids'),
                  Tab(text: 'My Bids'),
                ],
              ),
            ),
          ),
          body: TabBarView(
            children: [
              // Bids for managed farmers
              StreamBuilder<List<BidModel>>(
                stream: bidStream,
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.green));
                  }
                  return _buildBidList(snap.data ?? [], formatter, 'Agent', db);
                },
              ),
              // Agent's own bids (as buyer)
              StreamBuilder<List<BidModel>>(
                stream: db.streamBidsByBuyer(userId),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.green));
                  }
                  return _buildBidList(snap.data ?? [], formatter, 'Buyer', db);
                },
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: StreamBuilder<List<BidModel>>(
        stream: bidStream,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.green));
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
        
        return Container(
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
                          Text('UGX ${formatter.format(bid.offeredPrice)}', style: const TextStyle(color: AppTheme.greenDark, fontSize: 18, fontWeight: FontWeight.w800)),
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
