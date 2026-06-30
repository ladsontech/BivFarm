import 'package:bivfarm/models/bulk_order_model.dart';
import 'package:bivfarm/utils/bulk_order_utils.dart';
import 'package:flutter_test/flutter_test.dart' as ft;

void main() {
  ft.group('bulk order utils', () {
    ft.test('formats quantity and short ids cleanly', () {
      ft.expect(formatBulkOrderQuantity(1250.5, 'Kg'), '1,250.5 Kg');
      ft.expect(shortBulkOrderId('abcdef123456'), 'ABCDEF...');
      ft.expect(shortBulkOrderId('abc'), 'ABC');
    });

    ft.test('matches text and status filters', () {
      final order = BulkOrderModel(
        id: 'bulk-001',
        buyerId: 'buyer-1',
        buyerName: 'Grace Farm',
        buyerPhone: '0712345678',
        orderType: 'Produce',
        category: 'Poultry',
        itemName: 'Layers Mash',
        quantity: 250,
        quantityUnit: 'Bags',
        notes: 'Need fast delivery',
        adminNotes: 'Call before delivery',
        status: 'Processing',
      );

      ft.expect(bulkOrderMatches(order, 'layers'), ft.isTrue);
      ft.expect(
        bulkOrderMatches(order, 'grace', statusFilter: 'Processing'),
        ft.isTrue,
      );
      ft.expect(
        bulkOrderMatches(order, '', statusFilter: 'Processing'),
        ft.isTrue,
      );
      ft.expect(
        bulkOrderMatches(order, 'grace', statusFilter: 'All'),
        ft.isTrue,
      );
      ft.expect(
        bulkOrderMatches(order, 'grace', statusFilter: 'Completed'),
        ft.isFalse,
      );
      ft.expect(bulkOrderMatches(order, 'maize'), ft.isFalse);
    });

    ft.test('status list stays in the expected order', () {
      ft.expect(bulkOrderStatuses, [
        'Pending',
        'Processing',
        'Distributor Assigned',
        'Completed',
      ]);
    });
  });
}
