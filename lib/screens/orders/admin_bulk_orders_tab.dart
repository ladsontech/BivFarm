import 'package:flutter/material.dart';
import '../../models/bulk_order_model.dart';
import '../../models/message_model.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'bulk_fulfillment_screen.dart';

class AdminBulkOrdersTab extends StatelessWidget {
  final DatabaseService db;
  const AdminBulkOrdersTab({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BulkOrderModel>>(
      stream: db.streamBulkOrders(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.green));
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Error loading orders: ${snap.error}', style: TextStyle(color: AppTheme.error, fontSize: 14), textAlign: TextAlign.center),
            ),
          );
        }
        final orders = snap.data ?? [];
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_outlined, color: AppTheme.textMuted.withOpacity(0.3), size: 56),
                const SizedBox(height: 16),
                Text('No bulk orders yet', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (ctx, i) {
            final o = orders[i];
            final statusColor = _getStatusColor(o.status);
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
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.06),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    child: Row(
                      children: [
                        Icon(o.orderType == 'Produce' ? Icons.grass : Icons.agriculture, color: statusColor, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(o.itemName, style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                          child: Text(o.status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                  // Body
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _orderInfoChip(Icons.category, '${o.orderType} • ${o.category}'),
                            const Spacer(),
                            _orderInfoChip(Icons.scale, '${o.quantity} ${o.quantityUnit}'),
                          ],
                        ),
                        if (o.notes.isNotEmpty || o.adminNotes.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          if (o.notes.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(8)),
                              child: Text('Buyer: ${o.notes}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
                            ),
                          if (o.adminNotes.isNotEmpty) ...[
                            if (o.notes.isNotEmpty) const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: AppTheme.greenSurface, borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.sticky_note_2_outlined, size: 14, color: AppTheme.green),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text('Admin Note: ${o.adminNotes}', style: TextStyle(color: AppTheme.textPrimary, fontSize: 12))),
                                ],
                              ),
                            ),
                          ],
                        ],
                        const SizedBox(height: 14),
                        // Buyer Info Row
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppTheme.greenSurface,
                              child: Text(o.buyerName.isNotEmpty ? o.buyerName[0].toUpperCase() : '?', style: const TextStyle(color: AppTheme.greenDark, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(o.buyerName, style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                                  Text(o.buyerPhone, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                ],
                              ),
                            ),
                            // Actions
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, color: AppTheme.textMuted, size: 20),
                              onSelected: (v) {
                                if (v == 'message') {
                                  _AdminActions.showMessageDialog(context, db, o.buyerId, o.buyerName);
                                } else if (v == 'notes') {
                                  _AdminActions._showAdminNotesDialog(context, db, o);
                                } else {
                                  db.updateBulkOrderStatus(o.id, v);
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'message', child: Row(children: [Icon(Icons.message_outlined, size: 18), SizedBox(width: 8), Text('Message Buyer')])),
                                const PopupMenuItem(value: 'notes', child: Row(children: [Icon(Icons.sticky_note_2_outlined, size: 18), SizedBox(width: 8), Text('Update Notes')])),
                                const PopupMenuDivider(),
                                ...['Pending', 'Processing', 'Distributor Assigned', 'Completed'].map(
                                  (s) => PopupMenuItem(value: s, child: Row(children: [
                                    Icon(s == o.status ? Icons.radio_button_checked : Icons.radio_button_off, size: 16, color: s == o.status ? AppTheme.greenLight : AppTheme.textMuted),
                                    const SizedBox(width: 8),
                                    Text(s),
                                  ])),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        // Action: Fulfill (Split Order)
                        if (o.status != 'Completed') ...[
                          const SizedBox(height: 14),
                          const Divider(),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => BulkFulfillmentScreen(order: o)),
                                );
                              },
                              icon: const Icon(Icons.call_split),
                              label: const Text('Fulfill (Request from Farmers)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.greenSurface,
                                foregroundColor: AppTheme.greenDark,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ],
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

  Widget _orderInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending': return AppTheme.warning;
      case 'Processing': return AppTheme.info;
      case 'Distributor Assigned': return AppTheme.greenLight;
      case 'Completed': return AppTheme.green;
      default: return AppTheme.textMuted;
    }
  }
}

class _AdminActions {
  static void _showAdminNotesDialog(BuildContext context, DatabaseService db, BulkOrderModel order) {
    final tc = TextEditingController(text: order.adminNotes);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Admin Notes', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
        content: TextField(
          controller: tc,
          maxLines: 4,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Add internal/fulfillment notes...',
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
            onPressed: () async {
              await db.updateBulkOrderAdminNotes(order.id, tc.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }
// ... existing _AdminActions (already handled above)
  static void showMessageDialog(BuildContext context, DatabaseService db, String recipientId, String recipientName) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Message to $recipientName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(label: 'Subject', controller: titleCtrl),
              const SizedBox(height: 12),
              CustomTextField(label: 'Message', controller: bodyCtrl, maxLines: 4),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
