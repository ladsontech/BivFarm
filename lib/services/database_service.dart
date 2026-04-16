import 'dart:async';
import '../models/product_model.dart';
import '../models/bid_model.dart';
import '../models/user_model.dart';
import '../models/input_dealer_model.dart';
import 'demo_data.dart';

class DatabaseService {
  Stream<UserModel?> streamUser(String uid) => Stream.value(null);
  Future<UserModel?> getUser(String uid) async => null;
  Future<List<UserModel>> getAllUsers() async => [];
  Future<List<UserModel>> getUsersByRole(String role) async => [];
  Future<List<UserModel>> getUsersByAgent(String agentId) async => [];
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {}

  Future<String> addProduct(ProductModel product) async => 'demo_id';
  Future<void> updateProduct(String id, Map<String, dynamic> data) async {}
  Future<void> deleteProduct(String id) async {}

  Stream<List<ProductModel>> streamProducts() => Stream.value([]);
  Stream<List<ProductModel>> streamProductsBySeller(String sellerId) => Stream.value([]);
  Future<List<ProductModel>> getAllProducts() async => [];

  Future<String> addBid(BidModel bid) async => 'demo_id';
  Future<void> updateBidStatus(String bidId, String status, {String? adminNotes}) async {
    // Demo implementation
    final idx = DemoData.bids.indexWhere((b) => b.id == bidId);
    if (idx != -1) {
      DemoData.bids[idx] = DemoData.bids[idx].copyWith(status: status, adminNotes: adminNotes);
    }
  }
  Stream<List<BidModel>> streamBidsByProduct(String productId) => Stream.value([]);
  Stream<List<BidModel>> streamBidsByBuyer(String buyerId) => Stream.value([]);
  Stream<List<BidModel>> streamBidsBySeller(String sellerId) => Stream.value([]);
  Future<List<BidModel>> getAllBids() async => [];

  Future<String> addInputDealer(InputDealerModel dealer) async => 'demo_id';
  Stream<List<InputDealerModel>> streamInputDealers() => Stream.value([]);

  Future<String> addFarmerGroup(FarmerGroupModel group) async => 'demo_id';
  Stream<List<FarmerGroupModel>> streamFarmerGroups() => Stream.value([]);
  Future<List<FarmerGroupModel>> getGroupsByAgent(String agentId) async => [];

  Future<Map<String, int>> getAnalytics() async => {
    'totalUsers': 0, 'totalFarmers': 0, 'totalBuyers': 0,
    'totalListings': 0, 'totalBids': 0, 'males': 0, 'females': 0,
  };
}
