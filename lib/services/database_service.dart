import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/bid_model.dart';
import '../models/bulk_order_model.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../models/input_dealer_model.dart';
import '../models/notification_model.dart';
import 'package:rxdart/rxdart.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Users ---
  Stream<UserModel?> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) => 
      doc.exists ? UserModel.fromMap(doc.data()!, doc.id) : null);
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? UserModel.fromMap(doc.data()!, doc.id) : null;
  }

  Future<List<UserModel>> getAllUsers() async {
    final snap = await _db.collection('users').get();
    return snap.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
  }

  Future<List<UserModel>> getUsersByRole(String role) async {
    final snap = await _db.collection('users').where('role', isEqualTo: role).get();
    return snap.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
  }

  Future<UserModel?> getFirstAdmin() async {
    final snap = await _db.collection('users').where('role', isEqualTo: 'Admin').limit(1).get();
    if (snap.docs.isEmpty) return null;
    return UserModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
  }

  Future<List<UserModel>> getUsersByAgent(String agentId) async {
    final snap = await _db.collection('users').where('agentId', isEqualTo: agentId).get();
    return snap.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  Future<void> setUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set(data);
  }

  /// Look up a user by phone number (normalizes +256 and 0-prefix formats)
  Future<UserModel?> getUserByPhone(String phone) async {
    // Normalize to +256 format
    String normalized = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (normalized.startsWith('0')) {
      normalized = '+256${normalized.substring(1)}';
    } else if (!normalized.startsWith('+')) {
      normalized = '+256$normalized';
    }

    // Try exact match first
    var snap = await _db.collection('users').where('phone', isEqualTo: normalized).limit(1).get();
    if (snap.docs.isNotEmpty) {
      return UserModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
    }

    // Try with 0-prefix format (some agents store as 07...)
    final localFormat = '0${normalized.substring(4)}'; // +256 -> 0
    snap = await _db.collection('users').where('phone', isEqualTo: localFormat).limit(1).get();
    if (snap.docs.isNotEmpty) {
      return UserModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
    }

    // Try without country code prefix
    final rawDigits = normalized.replaceAll('+', '');
    snap = await _db.collection('users').where('phone', isEqualTo: rawDigits).limit(1).get();
    if (snap.docs.isNotEmpty) {
      return UserModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
    }

    return null;
  }

  /// Migrate a user document from one UID to another (for phone-auth merge).
  /// Copies all data to a new doc keyed by [newUid], deletes old doc,
  /// and updates references in related collections.
  Future<void> migrateUserDocument(String oldUid, String newUid) async {
    final oldDoc = await _db.collection('users').doc(oldUid).get();
    if (!oldDoc.exists) return;

    final data = oldDoc.data()!;
    data['id'] = newUid; // Update the id field

    // Write new doc
    await _db.collection('users').doc(newUid).set(data);

    // Update products where sellerId == oldUid
    final products = await _db.collection('products').where('sellerId', isEqualTo: oldUid).get();
    for (final doc in products.docs) {
      await doc.reference.update({'sellerId': newUid});
    }

    // Update farmer_groups where userId == oldUid
    final groups = await _db.collection('farmer_groups').where('userId', isEqualTo: oldUid).get();
    for (final doc in groups.docs) {
      await doc.reference.update({'userId': newUid});
    }

    // Update produce_stores where userId == oldUid
    final stores = await _db.collection('produce_stores').where('userId', isEqualTo: oldUid).get();
    for (final doc in stores.docs) {
      await doc.reference.update({'userId': newUid});
    }

    // Update bids where sellerId or buyerId == oldUid
    final sellerBids = await _db.collection('bids').where('sellerId', isEqualTo: oldUid).get();
    for (final doc in sellerBids.docs) {
      await doc.reference.update({'sellerId': newUid});
    }
    final buyerBids = await _db.collection('bids').where('buyerId', isEqualTo: oldUid).get();
    for (final doc in buyerBids.docs) {
      await doc.reference.update({'buyerId': newUid});
    }

    // Delete old doc
    await _db.collection('users').doc(oldUid).delete();
  }

  /// Live stream of all users (for Admin Users tab)
  Stream<List<UserModel>> streamAllUsers() {
    return _db.collection('users')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
        .where((doc) => doc.data()['isDeleted'] != true)
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // --- Products ---
  Future<String> addProduct(ProductModel product) async {
    final docRef = await _db.collection('products').add(product.toMap());
    return docRef.id;
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await _db.collection('products').doc(id).update(data);
  }

  Future<void> deleteProduct(String id) async {
    await _db.collection('products').doc(id).delete();
  }

  Stream<List<ProductModel>> streamProducts() {
    return _db.collection('products')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
        .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
        .where((p) => p.isActive) 
        .toList());
  }

  Stream<List<ProductModel>> streamProductsFiltered({String? category, String? district}) {
    Query query = _db.collection('products').where('isActive', isEqualTo: true);
    
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    if (district != null) {
      query = query.where('district', isEqualTo: district);
    }
    
    return query.orderBy('createdAt', descending: true).snapshots().map((snap) => 
      snap.docs.map((doc) => ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  Stream<List<ProductModel>> streamProductsBySeller(String sellerId) {
    return _db.collection('products')
      .where('sellerId', isEqualTo: sellerId)
      .snapshots()
      .map((snap) {
        final products = snap.docs.map((doc) => ProductModel.fromMap(doc.data(), doc.id)).toList();
        // Sort in memory to avoid requiring complex composite indexes
        products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return products.where((p) => p.isActive).toList();
      });
  }

  Future<List<ProductModel>> getAllProducts() async {
    final snap = await _db.collection('products').get();
    return snap.docs.map((doc) => ProductModel.fromMap(doc.data(), doc.id)).toList();
  }

  /// Stream products for all farmers assigned to this agent
  Stream<List<ProductModel>> streamProductsByAgent(String agentId) {
    return Stream.fromFuture(getUsersByAgent(agentId)).asyncExpand((farmers) {
      final farmerIds = farmers.map((f) => f.id).toList();
      if (farmerIds.isEmpty) return Stream.value(<ProductModel>[]);
      
      // Firestore whereIn limited to 30, chunk if needed
      final chunks = <List<String>>[];
      for (var i = 0; i < farmerIds.length; i += 30) {
        chunks.add(farmerIds.sublist(i, i + 30 > farmerIds.length ? farmerIds.length : i + 30));
      }
      
      if (chunks.length == 1) {
        return _db.collection('products')
            .where('sellerId', whereIn: chunks.first)
            .snapshots()
            .map((snap) {
              final products = snap.docs.map((doc) => ProductModel.fromMap(doc.data(), doc.id)).toList();
              products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              return products.where((p) => p.isActive).toList();
            });
      }
      
      return Stream.fromFuture(Future.wait(
        chunks.map((chunk) => _db.collection('products').where('sellerId', whereIn: chunk).get()),
      )).map((snaps) {
        final products = snaps.expand((s) => s.docs.map((doc) => ProductModel.fromMap(doc.data(), doc.id))).toList();
        products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return products.where((p) => p.isActive).toList();
      });
    });
  }

  // --- Bids ---
  Future<String> addBid(BidModel bid) async {
    final docRef = await _db.collection('bids').add(bid.toMap());
    
    // Send notifications to Farmer, Agent, Buyer and Admin
    try {
      final farmer = await getUser(bid.sellerId);
      await sendOrderNotification(
        title: "New Bid Received",
        body: "You have a new bid of ${bid.offeredPrice} UGX for ${bid.quantity} ${bid.productName}",
        relatedId: docRef.id,
        farmerId: bid.sellerId,
        buyerId: bid.buyerId,
        agentId: farmer?.agentId,
      );
    } catch (e) {
      print("Notification Error: $e");
    }
    
    return docRef.id;
  }

  Future<void> updateBid(String bidId, Map<String, dynamic> data) async {
    await _db.collection('bids').doc(bidId).update(data);
  }

  Future<void> updateBidStatus(String bidId, String status, {String? adminNotes}) async {
    final data = {'status': status};
    if (adminNotes != null) data['adminNotes'] = adminNotes;
    await _db.collection('bids').doc(bidId).update(data);
    
    // Notify about status update
    try {
      final bidDoc = await _db.collection('bids').doc(bidId).get();
      if (bidDoc.exists) {
        final bid = BidModel.fromMap(bidDoc.data()!, bidDoc.id);
        final farmer = await getUser(bid.sellerId);
        
        await sendOrderNotification(
          title: "Bid Status Updated",
          body: "The bid for ${bid.productName} is now $status",
          relatedId: bidId,
          farmerId: bid.sellerId,
          buyerId: bid.buyerId,
          agentId: farmer?.agentId,
        );
      }
    } catch (e) {
      print("Notification Error: $e");
    }
  }

  Stream<List<BidModel>> streamBidsByProduct(String productId) {
    return _db.collection('bids')
      .where('productId', isEqualTo: productId)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => BidModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<BidModel>> streamBidsByBuyer(String buyerId) {
    return _db.collection('bids')
      .where('buyerId', isEqualTo: buyerId)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => BidModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<BidModel>> streamBidsBySeller(String sellerId) {
    return _db.collection('bids')
      .where('sellerId', isEqualTo: sellerId)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => BidModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<List<BidModel>> getAllBids() async {
    final snap = await _db.collection('bids').get();
    return snap.docs.map((doc) => BidModel.fromMap(doc.data(), doc.id)).toList();
  }

  /// Stream bids for all farmers assigned to this agent
  Stream<List<BidModel>> streamBidsByAgent(String agentId) {
    // First get farmer IDs, then stream bids for those farmers
    return Stream.fromFuture(getUsersByAgent(agentId)).asyncExpand((farmers) {
      final farmerIds = farmers.map((f) => f.id).toList();
      if (farmerIds.isEmpty) return Stream.value(<BidModel>[]);
      // Firestore whereIn limited to 30, chunk if needed
      final chunks = <List<String>>[];
      for (var i = 0; i < farmerIds.length; i += 30) {
        chunks.add(farmerIds.sublist(i, i + 30 > farmerIds.length ? farmerIds.length : i + 30));
      }
      if (chunks.length == 1) {
        return _db.collection('bids')
            .where('sellerId', whereIn: chunks.first)
            .snapshots()
            .map((snap) => snap.docs.map((doc) => BidModel.fromMap(doc.data(), doc.id)).toList());
      }
      // Multiple chunks: merge results
      return Stream.fromFuture(Future.wait(
        chunks.map((chunk) => _db.collection('bids').where('sellerId', whereIn: chunk).get()),
      )).map((snaps) => snaps.expand((s) => s.docs.map((doc) => BidModel.fromMap(doc.data(), doc.id))).toList());
    });
  }

  /// Stream bulk orders for all farmers assigned to this agent
  Stream<List<BulkOrderModel>> streamBulkOrdersByAgent(String agentId) {
    return Stream.fromFuture(getUsersByAgent(agentId)).asyncExpand((farmers) {
      final farmerIds = farmers.map((f) => f.id).toList();
      if (farmerIds.isEmpty) return Stream.value(<BulkOrderModel>[]);
      final chunks = <List<String>>[];
      for (var i = 0; i < farmerIds.length; i += 30) {
        chunks.add(farmerIds.sublist(i, i + 30 > farmerIds.length ? farmerIds.length : i + 30));
      }
      if (chunks.length == 1) {
        return _db.collection('bulk_orders')
            .where('sellerId', whereIn: chunks.first)
            .snapshots()
            .map((snap) => snap.docs.map((doc) => BulkOrderModel.fromMap(doc.data(), doc.id)).toList());
      }
      return Stream.fromFuture(Future.wait(
        chunks.map((chunk) => _db.collection('bulk_orders').where('sellerId', whereIn: chunk).get()),
      )).map((snaps) => snaps.expand((s) => s.docs.map((doc) => BulkOrderModel.fromMap(doc.data(), doc.id))).toList());
    });
  }

  // --- Bulk Orders ---
  Future<String> addBulkOrder(BulkOrderModel order) async {
    final docRef = await _db.collection('bulk_orders').add(order.toMap());
    return docRef.id;
  }

  Future<void> updateBulkOrderStatus(String orderId, String status) async {
    await _db.collection('bulk_orders').doc(orderId).update({'status': status});

    // Notify buyer and admins about status change
    try {
      final orderDoc = await _db.collection('bulk_orders').doc(orderId).get();
      if (orderDoc.exists) {
        final data = orderDoc.data()!;
        final buyerId = data['buyerId'] ?? '';
        final itemName = data['itemName'] ?? 'your order';
        if (buyerId.isNotEmpty) {
          await sendBulkOrderNotification(
            title: 'Order Status Updated',
            body: 'Your bulk order for $itemName is now: $status',
            relatedId: orderId,
            buyerId: buyerId,
          );
        }
      }
    } catch (e) {
      print('Notification Error (bulk order status): $e');
    }
  }

  Future<void> updateBulkOrderAdminNotes(String orderId, String notes) async {
    await _db.collection('bulk_orders').doc(orderId).update({'adminNotes': notes});
  }

  Stream<List<BulkOrderModel>> streamBulkOrders() {
    return _db.collection('bulk_orders')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => BulkOrderModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<BulkOrderModel>> streamBulkOrdersByBuyer(String buyerId) {
    return _db.collection('bulk_orders')
      .where('buyerId', isEqualTo: buyerId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => BulkOrderModel.fromMap(doc.data(), doc.id)).toList());
  }

  // --- Input Dealers ---
  Future<String> addInputDealer(InputDealerModel dealer) async {
    final docRef = await _db.collection('input_dealers').add(dealer.toMap());
    return docRef.id;
  }

  Stream<List<InputDealerModel>> streamInputDealers() {
    return _db.collection('input_dealers')
      .snapshots()
      .map((snap) => snap.docs.map((doc) => InputDealerModel.fromMap(doc.data(), doc.id)).toList());
  }

  // --- Farmer Groups ---
  Future<String> addFarmerGroup(FarmerGroupModel group) async {
    final docRef = await _db.collection('farmer_groups').add(group.toMap());
    return docRef.id;
  }

  Stream<List<FarmerGroupModel>> streamAllGroups() {
    return _db.collection('farmer_groups')
      .snapshots()
      .map((snap) => snap.docs.map((doc) => FarmerGroupModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<Map<String, dynamic>>> streamAllProduceStores() {
    return _db.collection('produce_stores')
      .snapshots()
      .map((snap) => snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList());
  }

  Stream<List<InputDealerModel>> streamAllInputDealers() {
    return _db.collection('input_dealers')
      .snapshots()
      .map((snap) => snap.docs.map((doc) => InputDealerModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<List<FarmerGroupModel>> getGroupsByAgent(String agentId) async {
    final snap = await _db.collection('farmer_groups').where('agentId', isEqualTo: agentId).get();
    return snap.docs.map((doc) => FarmerGroupModel.fromMap(doc.data(), doc.id)).toList();
  }

  // --- Produce Stores ---
  Future<String> addProduceStore(Map<String, dynamic> data) async {
    final docRef = await _db.collection('produce_stores').add(data);
    return docRef.id;
  }

  Stream<List<Map<String, dynamic>>> streamProduceStores() {
    return _db.collection('produce_stores')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList());
  }

  Future<List<Map<String, dynamic>>> getProduceStoresByAgent(String agentId) async {
    final snap = await _db.collection('produce_stores').where('agentId', isEqualTo: agentId).get();
    return snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<Map<String, int>> getAnalytics() async {
    try {
      final res = await Future.wait([
        _db.collection('users').count().get(),
        _db.collection('users').where('role', isEqualTo: 'Farmer').count().get(),
        _db.collection('users').where('role', isEqualTo: 'Buyer').count().get(),
        _db.collection('users').where('role', isEqualTo: 'Agent').count().get(),
        _db.collection('users').where('gender', isEqualTo: 'Male').count().get(),
        _db.collection('users').where('gender', isEqualTo: 'Female').count().get(),
        _db.collection('products').count().get(),
        _db.collection('bids').count().get(),
        _db.collection('users').where('role', isEqualTo: 'Store').count().get(),
        _db.collection('farmer_groups').count().get(),
        _db.collection('produce_stores').count().get(),
      ]);

      return {
        'totalUsers': res[0].count ?? 0,
        'totalFarmers': res[1].count ?? 0,
        'totalBuyers': res[2].count ?? 0,
        'totalAgents': res[3].count ?? 0,
        'males': res[4].count ?? 0,
        'females': res[5].count ?? 0,
        'totalListings': res[6].count ?? 0,
        'totalBids': res[7].count ?? 0,
        'totalStores': res[8].count ?? 0,
        'totalGroups': res[9].count ?? 0,
        'totalProduceStores': res[10].count ?? 0,
      };
    } catch (e) {
      print("Analytics Error: $e");
      rethrow;
    }
  }

  // --- Messages ---
  Future<String> addMessage(MessageModel msg) async {
    final docRef = await _db.collection('messages').add(msg.toMap());
    
    // Auto-notify recipient(s)
    try {
      if (msg.recipientId == 'support') {
        // Find all admins and create a notification for each
        final admins = await getUsersByRole('Admin');
        for (final admin in admins) {
          await _db.collection('notifications').add({
            'recipientId': admin.id,
            'title': 'New Support Message',
            'body': '${msg.senderName}: ${msg.body}',
            'isRead': false,
            'createdAt': DateTime.now().toIso8601String(),
            'type': 'message',
            'data': {
              'senderId': msg.senderId,
              'messageId': docRef.id,
            }
          });
        }
      } else {
        final recipient = await getUser(msg.recipientId);
        if (recipient != null) {
          // Create Notification Doc
          await _db.collection('notifications').add({
            'recipientId': msg.recipientId,
            'title': 'New Message from ${msg.senderName}',
            'body': msg.body,
            'isRead': false,
            'createdAt': DateTime.now().toIso8601String(),
            'type': 'message',
            'data': {
              'senderId': msg.senderId,
              'messageId': docRef.id,
            }
          });
        }
      }
    } catch (e) {
      print("Notification Error: $e");
    }
    
    return docRef.id;
  }

  Stream<List<MessageModel>> streamMessagesByUser(String userId) {
    return _db.collection('messages')
      .where('recipientId', isEqualTo: userId)
      .snapshots()
      .map((snap) {
        final messages = snap.docs.map((doc) => MessageModel.fromMap(doc.data(), doc.id)).toList();
        messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return messages;
      });
  }

  Stream<List<MessageModel>> streamSupportConversations() {
    final q1 = _db.collection('messages')
      .where('senderId', isEqualTo: 'support');
    
    final q2 = _db.collection('messages')
      .where('recipientId', isEqualTo: 'support');

    return CombineLatestStream.combine2<QuerySnapshot, QuerySnapshot, List<MessageModel>>(
      q1.snapshots(),
      q2.snapshots(),
      (s1, s2) {
        final messages = <MessageModel>[];
        final seenDocIds = <String>{};
        
        for (final d in [...s1.docs, ...s2.docs]) {
          if (!seenDocIds.contains(d.id)) {
            seenDocIds.add(d.id);
            messages.add(MessageModel.fromMap(d.data() as Map<String, dynamic>, d.id));
          }
        }
        
        messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return messages;
      }
    );
  }

  Stream<List<MessageModel>> streamMessagesBetween(String uid1, String uid2) {
    // We filter for either (uid1 -> uid2) OR (uid2 -> uid1)
    // Note: Firestore doesn't support OR across fields easily without multiple queries or custom data structure
    // For now, we'll stream all messages related to uid1 and filter locally for uid2, 
    // or better, stream both directions.
    final q1 = _db.collection('messages')
      .where('senderId', isEqualTo: uid1)
      .where('recipientId', isEqualTo: uid2);
    
    final q2 = _db.collection('messages')
      .where('senderId', isEqualTo: uid2)
      .where('recipientId', isEqualTo: uid1);

    return CombineLatestStream.combine2<QuerySnapshot, QuerySnapshot, List<MessageModel>>(
      q1.snapshots(),
      q2.snapshots(),
      (s1, s2) {
        final m1 = s1.docs.map((d) => MessageModel.fromMap(d.data() as Map<String, dynamic>, d.id));
        final m2 = s2.docs.map((d) => MessageModel.fromMap(d.data() as Map<String, dynamic>, d.id));
        final all = [...m1, ...m2];
        all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return all;
      }
    );
  }

  Future<void> markMessageRead(String messageId) async {
    await _db.collection('messages').doc(messageId).update({'isRead': true});
  }

  Future<void> markSupportMessagesRead(String userId) async {
    final snap = await _db.collection('messages')
      .where('senderId', isEqualTo: userId)
      .where('recipientId', isEqualTo: 'support')
      .where('isRead', isEqualTo: false)
      .get();
    
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // --- All Bids (for Registry) ---
  Stream<List<BidModel>> streamAllBids() {
    return _db.collection('bids')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => BidModel.fromMap(doc.data(), doc.id)).toList());
  }

  // --- Notifications ---
  Stream<List<NotificationModel>> streamNotifications(String userId, [String role = 'User']) {
    if (role == 'Admin') {
      // Admins see everything
      return _db.collection('notifications')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map((doc) => NotificationModel.fromMap(doc.data(), doc.id)).toList());
    }
    
    return _db.collection('notifications')
      .where('recipientId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => NotificationModel.fromMap(doc.data(), doc.id)).toList());
  }

  /// Specialized stream for Agents to see notifications for their assigned farmers
  Stream<List<NotificationModel>> streamAgentFarmerNotifications(String agentId) {
    return _db.collection('notifications')
        .where('data.agentId', isEqualTo: agentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => NotificationModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> markNotificationRead(String id) async {
    await _db.collection('notifications').doc(id).update({'isRead': true});
  }

  Future<void> addNotification(NotificationModel notification) async {
    await _db.collection('notifications').add(notification.toMap());
  }

  Future<void> sendOrderNotification({
    required String title,
    required String body,
    required String relatedId,
    required String farmerId,
    required String buyerId,
    String? agentId,
  }) async {
    // 1. Notify Farmer
    await addNotification(NotificationModel(
      id: '',
      recipientId: farmerId,
      title: title,
      body: body,
      type: 'order',
      relatedId: relatedId,
      data: {'agentId': agentId},
    ));

    // 2. Notify Buyer
    await addNotification(NotificationModel(
      id: '',
      recipientId: buyerId,
      title: title,
      body: body,
      type: 'order',
      relatedId: relatedId,
    ));

    // 3. Notify Agent if exists
    if (agentId != null && agentId.isNotEmpty) {
      await addNotification(NotificationModel(
        id: '',
        recipientId: agentId,
        title: "Farmer Order: $title",
        body: "Your assigned farmer received an order: $body",
        type: 'order',
        relatedId: relatedId,
        data: {'farmerId': farmerId},
      ));
    }

    // 4. Notify all Admins
    final admins = await getUsersByRole('Admin');
    for (var admin in admins) {
      await addNotification(NotificationModel(
        id: '',
        recipientId: admin.id,
        title: "System Order: $title",
        body: body,
        type: 'order',
        relatedId: relatedId,
      ));
    }
  }

  Future<void> sendBulkOrderNotification({
    required String title,
    required String body,
    required String relatedId,
    required String buyerId,
  }) async {
    // 1. Notify Buyer
    await addNotification(NotificationModel(
      id: '',
      recipientId: buyerId,
      title: title,
      body: body,
      type: 'order',
      relatedId: relatedId,
    ));

    // 2. Notify all Admins
    final admins = await getUsersByRole('Admin');
    for (var admin in admins) {
      await addNotification(NotificationModel(
        id: '',
        recipientId: admin.id,
        title: 'Bulk Order: $title',
        body: body,
        type: 'order',
        relatedId: relatedId,
      ));
    }
  }

  /// Send a notification to all admins when a new user signs up.
  Future<void> sendUserSignupNotification({
    required String userName,
    required String userRole,
    required String userId,
  }) async {
    try {
      final admins = await getUsersByRole('Admin');
      for (var admin in admins) {
        await addNotification(NotificationModel(
          id: '',
          recipientId: admin.id,
          title: 'New User Registered',
          body: '$userName joined as a $userRole',
          type: 'general',
          relatedId: userId,
          data: {'userId': userId, 'role': userRole},
        ));
      }
    } catch (e) {
      print('Notification Error (user signup): $e');
    }
  }

  // --- FCM Token ---
  Future<void> updateFcmToken(String userId, String token) async {
    await _db.collection('users').doc(userId).update({'fcmToken': token});
  }

  /// Get products for a specific seller (for agent impersonation)
  Future<List<ProductModel>> getProductsBySeller(String sellerId) async {
    final snap = await _db.collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .get();
    return snap.docs.map((doc) => ProductModel.fromMap(doc.data(), doc.id)).toList();
  }
}
