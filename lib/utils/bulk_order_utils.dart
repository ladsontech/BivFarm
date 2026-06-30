import 'package:intl/intl.dart';

import '../models/bulk_order_model.dart';

const List<String> bulkOrderStatuses = <String>[
  'Pending',
  'Processing',
  'Distributor Assigned',
  'Completed',
];

String formatBulkOrderQuantity(double quantity, String unit) {
  final formattedQuantity =
      NumberFormat.decimalPattern('en_US').format(quantity);
  return '$formattedQuantity $unit';
}

String shortBulkOrderId(String id, {int visibleChars = 6}) {
  if (id.length <= visibleChars) {
    return id.toUpperCase();
  }
  return '${id.substring(0, visibleChars).toUpperCase()}...';
}

String bulkOrderSearchText(BulkOrderModel order) {
  return [
    order.id,
    order.buyerName,
    order.buyerPhone,
    order.orderType,
    order.category,
    order.itemName,
    order.notes,
    order.adminNotes,
    order.status,
  ].join(' ');
}

bool bulkOrderMatches(
  BulkOrderModel order,
  String query, {
  String statusFilter = 'All',
}) {
  if (statusFilter != 'All' && order.status != statusFilter) {
    return false;
  }

  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return true;
  }

  return bulkOrderSearchText(order).toLowerCase().contains(normalizedQuery);
}
