import 'package:bivfarm/models/bid_model.dart';
import 'package:bivfarm/models/notification_model.dart';
import 'package:bivfarm/models/product_model.dart';
import 'package:bivfarm/models/user_model.dart';
import 'package:bivfarm/utils/model_parsers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Firestore model parsing', () {
    test('accepts Timestamp, ISO string, and epoch dates', () {
      final expected = DateTime.utc(2026, 1, 15, 12);

      expect(readDate(Timestamp.fromDate(expected)), expected.toLocal());
      expect(readDate(expected.toIso8601String()), expected.toLocal());
      expect(readDate(expected.millisecondsSinceEpoch), expected.toLocal());
    });

    test('product tolerates legacy and mixed field types', () {
      final product = ProductModel.fromMap({
        'sellerId': 123,
        'productName': 'Maize',
        'quantity': '1,250.5',
        'price': 4200,
        'imageUrls': [null, 'https://example.com/maize.jpg', 42],
        'isActive': 'true',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 2, 1)),
      }, 'product-1');

      expect(product.sellerId, '123');
      expect(product.quantity, 1250.5);
      expect(product.price, 4200);
      expect(product.imageUrls, ['https://example.com/maize.jpg', '42']);
      expect(product.isActive, isTrue);
    });

    test('malformed optional values fall back without throwing', () {
      final user = UserModel.fromMap({
        'name': null,
        'isActive': 'not-a-bool',
        'createdAt': 'not-a-date',
      }, 'user-1');
      final bid = BidModel.fromMap({
        'quantity': 'bad',
        'offeredPrice': '12,500',
        'createdAt': Object(),
      }, 'bid-1');
      final notification = NotificationModel.fromMap({
        'data': {'attempts': 2},
        'createdAt': Timestamp.now(),
      }, 'notification-1');

      expect(user.name, isEmpty);
      expect(user.isActive, isTrue);
      expect(bid.quantity, 0);
      expect(bid.offeredPrice, 12500);
      expect(notification.data, {'attempts': 2});
    });
  });
}
