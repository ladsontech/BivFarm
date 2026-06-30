import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/bulk_order_model.dart';
import '../../models/message_model.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/bulk_order_utils.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/responsive_wrapper.dart';
import 'bulk_fulfillment_screen.dart';

class AdminBulkOrdersTab extends StatefulWidget {
  final DatabaseService db;
  const AdminBulkOrdersTab({super.key, required this.db});

  @override
  State<AdminBulkOrdersTab> createState() => _AdminBulkOrdersTabState();
}

class _AdminBulkOrdersTabState extends State<AdminBulkOrdersTab> {
  final _searchCtrl = TextEditingController();
  final Set<String> _selectedIds = <String>{};
  String _statusFilter = 'All';
  bool _bulkUpdating = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BulkOrderModel>>(
      stream: widget.db.streamBulkOrders(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.green),
          );
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Error loading orders: ${snap.error}',
                style: TextStyle(color: AppTheme.error, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final orders = snap.data ?? <BulkOrderModel>[];
        final filteredOrders = orders
            .where((order) => bulkOrderMatches(
                  order,
                  _searchCtrl.text,
                  statusFilter: _statusFilter,
                ))
            .toList();

        return ResponsiveWrapper(
          applyDefaultPadding: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(orders, filteredOrders),
              const SizedBox(height: 16),
              _buildControls(filteredOrders),
              if (_selectedIds.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildBulkActions(orders),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 1100;
                    if (filteredOrders.isEmpty) {
                      return _buildEmptyState();
                    }
                    return isDesktop
                        ? _buildDesktopList(filteredOrders)
                        : _buildMobileList(filteredOrders);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    List<BulkOrderModel> orders,
    List<BulkOrderModel> filteredOrders,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bulk Orders',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Search, filter, and update multiple orders from one simpler workspace.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _countChip('Total ${orders.length}', AppTheme.green),
              _countChip('Visible ${filteredOrders.length}', AppTheme.info),
              _countChip('Selected ${_selectedIds.length}', AppTheme.warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls(List<BulkOrderModel> filteredOrders) {
    final allVisibleSelected = filteredOrders.isNotEmpty &&
        filteredOrders.every(_selectedIds.contains);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 320,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search buyer, item, category, or status',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
          ),
          SizedBox(
            width: 210,
            child: DropdownButtonFormField<String>(
              initialValue: _statusFilter,
              decoration: const InputDecoration(
                labelText: 'Status filter',
              ),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All statuses')),
                DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                DropdownMenuItem(
                    value: 'Processing', child: Text('Processing')),
                DropdownMenuItem(
                  value: 'Distributor Assigned',
                  child: Text('Distributor Assigned'),
                ),
                DropdownMenuItem(value: 'Completed', child: Text('Completed')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _statusFilter = value);
              },
            ),
          ),
          OutlinedButton.icon(
            onPressed: filteredOrders.isEmpty
                ? null
                : () => _toggleVisibleSelection(
                    filteredOrders, !allVisibleSelected),
            icon:
                Icon(allVisibleSelected ? Icons.remove_done : Icons.select_all),
            label:
                Text(allVisibleSelected ? 'Clear visible' : 'Select visible'),
          ),
          TextButton.icon(
            onPressed: _selectedIds.isEmpty
                ? null
                : () => setState(() => _selectedIds.clear()),
            icon: const Icon(Icons.close),
            label: const Text('Clear selection'),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActions(List<BulkOrderModel> orders) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.greenSurface.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '${_selectedIds.length} selected',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          for (final status in bulkOrderStatuses)
            ElevatedButton.icon(
              onPressed: _bulkUpdating
                  ? null
                  : () => _bulkUpdateStatus(orders, status),
              icon: Icon(_statusIcon(status), size: 18),
              label: Text('Set $status'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.card,
                foregroundColor: AppTheme.textPrimary,
                elevation: 0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopList(List<BulkOrderModel> orders) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(
                bottom: BorderSide(color: AppTheme.border.withOpacity(0.6)),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(width: 48),
                SizedBox(
                  width: 260,
                  child: Text(
                    'Order',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: Text(
                    'Buyer',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: Text(
                    'Quantity',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    'Received',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                SizedBox(width: 56),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: orders.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: AppTheme.border.withOpacity(0.6),
              ),
              itemBuilder: (context, index) {
                final order = orders[index];
                final selected = _selectedIds.contains(order.id);
                return InkWell(
                  onTap: () => _toggleOrderSelection(order, !selected),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    color: selected
                        ? AppTheme.greenSurface.withOpacity(0.35)
                        : Colors.transparent,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 48,
                          child: Checkbox(
                            value: selected,
                            onChanged: (value) =>
                                _toggleOrderSelection(order, value ?? false),
                          ),
                        ),
                        SizedBox(
                          width: 260,
                          child: _orderCell(order),
                        ),
                        SizedBox(
                          width: 220,
                          child: _buyerCell(order),
                        ),
                        SizedBox(
                          width: 140,
                          child: Text(
                            formatBulkOrderQuantity(
                              order.quantity,
                              order.quantityUnit,
                            ),
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: _statusChip(order.status),
                        ),
                        SizedBox(
                          width: 120,
                          child: Text(
                            dateFormat.format(order.createdAt),
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 56,
                          child: _orderMenu(order),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(List<BulkOrderModel> orders) {
    return ListView.separated(
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        final selected = _selectedIds.contains(order.id);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.greenSurface.withOpacity(0.35)
                : AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: selected,
                    onChanged: (value) =>
                        _toggleOrderSelection(order, value ?? false),
                  ),
                  Expanded(child: _orderCell(order)),
                  _statusChip(order.status),
                  const SizedBox(width: 4),
                  _orderMenu(order),
                ],
              ),
              const SizedBox(height: 12),
              _detailRow('Buyer', order.buyerName),
              _detailRow('Phone', order.buyerPhone),
              _detailRow(
                'Quantity',
                formatBulkOrderQuantity(order.quantity, order.quantityUnit),
              ),
              _detailRow('Category', '${order.orderType} / ${order.category}'),
              if (order.notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Buyer note: ${order.notes}',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
              if (order.adminNotes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.greenSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Admin note: ${order.adminNotes}',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            color: AppTheme.textMuted.withOpacity(0.3),
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            'No bulk orders found',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _orderCell(BulkOrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          order.itemName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${shortBulkOrderId(order.id)}  ${order.orderType} / ${order.category}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buyerCell(BulkOrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          order.buyerName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          order.buyerPhone,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _orderMenu(BulkOrderModel order) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: AppTheme.textMuted, size: 20),
      onSelected: (value) {
        if (value == 'message') {
          _showMessageDialog(order);
          return;
        }
        if (value == 'notes') {
          _showNotesDialog(order);
          return;
        }
        if (value == 'fulfill') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BulkFulfillmentScreen(order: order),
            ),
          );
          return;
        }
        if (bulkOrderStatuses.contains(value)) {
          _setSingleStatus(order, value);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'message',
          child: Row(
            children: [
              Icon(Icons.message_outlined, size: 18),
              SizedBox(width: 8),
              Text('Message buyer'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'notes',
          child: Row(
            children: [
              Icon(Icons.sticky_note_2_outlined, size: 18),
              SizedBox(width: 8),
              Text('Update notes'),
            ],
          ),
        ),
        if (order.status != 'Completed')
          const PopupMenuItem(
            value: 'fulfill',
            child: Row(
              children: [
                Icon(Icons.call_split, size: 18),
                SizedBox(width: 8),
                Text('Fulfill order'),
              ],
            ),
          ),
        const PopupMenuDivider(),
        ...bulkOrderStatuses.map(
          (status) => PopupMenuItem(
            value: status,
            child: Row(
              children: [
                Icon(
                  status == order.status
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 16,
                  color: status == order.status
                      ? AppTheme.greenLight
                      : AppTheme.textMuted,
                ),
                const SizedBox(width: 8),
                Text('Mark $status'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _countChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.hourglass_top;
      case 'Processing':
        return Icons.autorenew;
      case 'Distributor Assigned':
        return Icons.local_shipping_outlined;
      case 'Completed':
        return Icons.verified_outlined;
      default:
        return Icons.label_outline;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return AppTheme.warning;
      case 'Processing':
        return AppTheme.info;
      case 'Distributor Assigned':
        return AppTheme.greenLight;
      case 'Completed':
        return AppTheme.green;
      default:
        return AppTheme.textMuted;
    }
  }

  void _toggleOrderSelection(BulkOrderModel order, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(order.id);
      } else {
        _selectedIds.remove(order.id);
      }
    });
  }

  void _toggleVisibleSelection(
    List<BulkOrderModel> visibleOrders,
    bool selected,
  ) {
    setState(() {
      for (final order in visibleOrders) {
        if (selected) {
          _selectedIds.add(order.id);
        } else {
          _selectedIds.remove(order.id);
        }
      }
    });
  }

  Future<void> _setSingleStatus(BulkOrderModel order, String status) async {
    if (order.status == status) return;
    try {
      await widget.db.updateBulkOrderStatus(order.id, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated ${order.itemName} to $status')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating order: $e')),
      );
    }
  }

  Future<void> _bulkUpdateStatus(
    List<BulkOrderModel> orders,
    String status,
  ) async {
    final selectedOrders = orders
        .where((order) =>
            _selectedIds.contains(order.id) && order.status != status)
        .toList();

    if (selectedOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No selected orders need that status')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update ${selectedOrders.length} orders?'),
        content: Text('Set all selected orders to $status?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _bulkUpdating = true);
    final failures = <String>[];

    try {
      const batchSize = 4;
      for (var index = 0; index < selectedOrders.length; index += batchSize) {
        final batch = selectedOrders.sublist(
          index,
          math.min(index + batchSize, selectedOrders.length),
        );
        final results = await Future.wait(
          batch.map((order) async {
            try {
              await widget.db.updateBulkOrderStatus(order.id, status);
              return true;
            } catch (_) {
              return false;
            }
          }),
        );
        for (var i = 0; i < results.length; i++) {
          if (!results[i]) failures.add(batch[i].id);
        }
      }

      if (!mounted) return;
      setState(() {
        _selectedIds
            .removeWhere((id) => selectedOrders.any((order) => order.id == id));
      });
      final successCount = selectedOrders.length - failures.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Updated $successCount orders to $status${failures.isEmpty ? '' : ' (${failures.length} failed)'}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bulk update failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _bulkUpdating = false);
    }
  }

  Future<void> _showNotesDialog(BulkOrderModel order) async {
    final notesCtrl = TextEditingController(text: order.adminNotes);
    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text(
            'Admin Notes',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
          ),
          content: SizedBox(
            width: 420,
            child: TextField(
              controller: notesCtrl,
              maxLines: 5,
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Add internal or fulfillment notes...',
                hintStyle: TextStyle(color: AppTheme.textMuted),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await widget.db.updateBulkOrderAdminNotes(
                    order.id,
                    notesCtrl.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Error saving notes: $e')),
                    );
                  }
                }
              },
              child: const Text('Save Note'),
            ),
          ],
        ),
      );
    } finally {
      notesCtrl.dispose();
    }
  }

  Future<void> _showMessageDialog(BulkOrderModel order) async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text('Message to ${order.buyerName}'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(label: 'Subject', controller: titleCtrl),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Message',
                    controller: bodyCtrl,
                    maxLines: 4,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (titleCtrl.text.trim().isEmpty ||
                      bodyCtrl.text.trim().isEmpty) {
                    return;
                  }
                  try {
                    await widget.db.addMessage(
                      MessageModel(
                        id: '',
                        senderId: 'admin',
                        senderName: 'Admin',
                        senderRole: 'Admin',
                        recipientId: order.buyerId,
                        subject: titleCtrl.text.trim(),
                        body: bodyCtrl.text.trim(),
                      ),
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Message sent')),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                child: const Text('Send'),
              ),
            ],
          );
        },
      );
    } finally {
      titleCtrl.dispose();
      bodyCtrl.dispose();
    }
  }
}
