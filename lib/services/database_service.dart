import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/bid_model.dart';
import '../models/bulk_order_model.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../models/input_dealer_model.dart';
import '../models/notification_model.dart';

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
      .where('isActive', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => ProductModel.fromMap(doc.data(), doc.id)).toList());
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

  Stream<List<FarmerGroupModel>> streamFarmerGroups() {
    return _db.collection('farmer_groups')
      .snapshots()
      .map((snap) => snap.docs.map((doc) => FarmerGroupModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<List<FarmerGroupModel>> getGroupsByAgent(String agentId) async {
    final snap = await _db.collection('farmer_groups').where('agentId', isEqualTo: agentId).get();
    return snap.docs.map((doc) => FarmerGroupModel.fromMap(doc.data(), doc.id)).toList();
  }

  Future<Map<String, int>> getAnalytics() async {
    final users = await _db.collection('users').get();
    final products = await _db.collection('products').get();
    final bids = await _db.collection('bids').get();

    int totalUsers = users.size;
    int totalFarmers = users.docs.where((d) => d['role'] == 'Farmer').length;
    int totalBuyers = users.docs.where((d) => d['role'] == 'Buyer').length;
    int totalAgents = users.docs.where((d) => d['role'] == 'Agent').length;
    int males = users.docs.where((d) => d['gender'] == 'Male').length;
    int females = users.docs.where((d) => d['gender'] == 'Female').length;

    return {
      'totalUsers': totalUsers,
      'totalFarmers': totalFarmers,
      'totalBuyers': totalBuyers,
      'totalAgents': totalAgents,
      'totalListings': products.size,
      'totalBids': bids.size,
      'males': males,
      'females': females,
    };
  }

  // --- Messages ---
  Future<String> addMessage(MessageModel msg) async {
    final docRef = await _db.collection('messages').add(msg.toMap());
    return docRef.id;
  }

  Stream<List<MessageModel>> streamMessagesByUser(String userId) {
    return _db.collection('messages')
      .where('recipientId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => MessageModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> markMessageRead(String messageId) async {
    await _db.collection('messages').doc(messageId).update({'isRead': true});
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
