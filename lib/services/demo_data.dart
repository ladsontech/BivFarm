import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/bid_model.dart';
import '../models/input_dealer_model.dart';
import '../models/message_model.dart';

class DemoData {
  // ─── Sample Users ───────────────────────────────────
  static final List<UserModel> users = [
    UserModel(id: 'farmer1', name: 'Mugisha Robert', firstName: 'Mugisha', lastName: 'Robert', phone: '0771234567', email: 'mugisha@bfarm.ug', role: 'Farmer', gender: 'Male', userCategory: 'Farmer', district: 'Hoima', subcounty: 'Buseruka', village: 'Kyabigambire', isProfileComplete: true, isVerified: true),
    UserModel(id: 'farmer2', name: 'Nakamya Florence', firstName: 'Nakamya', lastName: 'Florence', phone: '0782345678', email: 'nakamya@bfarm.ug', role: 'Farmer', gender: 'Female', userCategory: 'Farmer', district: 'Masindi', subcounty: 'Bwijanga', village: 'Kimengo', isProfileComplete: true, isVerified: true),
    UserModel(id: 'farmer3', name: 'Byaruhanga David', firstName: 'Byaruhanga', lastName: 'David', phone: '0753456789', email: 'byaruhanga@bfarm.ug', role: 'Farmer', gender: 'Male', userCategory: 'Farmer', district: 'Kikuube', subcounty: 'Buhimba', village: 'Kitana', isProfileComplete: true, isVerified: true),
    UserModel(id: 'farmer4', name: 'Ainebyoona Grace', firstName: 'Ainebyoona', lastName: 'Grace', phone: '0704567890', email: 'grace@bfarm.ug', role: 'Farmer', gender: 'Female', userCategory: 'Farmer', district: 'Kagadi', subcounty: 'Muhorro', village: 'Ndaiga', isProfileComplete: true, isVerified: true),
    UserModel(id: 'farmer5', name: 'Tumusiime Joseph', firstName: 'Tumusiime', lastName: 'Joseph', phone: '0775678901', email: 'tumusiime@bfarm.ug', role: 'Farmer', gender: 'Male', userCategory: 'Farmer', district: 'Kakumiro', subcounty: 'Kakumiro TC', village: 'Mparangasi', isProfileComplete: true, isVerified: true),
    UserModel(id: 'farmer6', name: 'Kabahuma Sarah', firstName: 'Kabahuma', lastName: 'Sarah', phone: '0786789012', email: 'kabahuma@bfarm.ug', role: 'Farmer', gender: 'Female', userCategory: 'Farmer', district: 'Kibaale', subcounty: 'Kibaale TC', village: 'Karuguza', isProfileComplete: true, isVerified: true),
    UserModel(id: 'buyer1', name: 'Okello James', firstName: 'Okello', lastName: 'James', phone: '0761234567', email: 'okello@buyer.ug', role: 'Buyer', gender: 'Male', userCategory: 'Buyer', district: 'Kampala', isProfileComplete: true, isVerified: true),
    UserModel(id: 'buyer2', name: 'Namukasa Irene', firstName: 'Namukasa', lastName: 'Irene', phone: '0742345678', email: 'namukasa@buyer.ug', role: 'Buyer', gender: 'Female', userCategory: 'Buyer', district: 'Wakiso', isProfileComplete: true, isVerified: true),
    UserModel(id: 'agent1', name: 'Kato Emmanuel', firstName: 'Kato', lastName: 'Emmanuel', phone: '0793456789', email: 'kato@agent.ug', role: 'Agent', gender: 'Male', district: 'Hoima City', isProfileComplete: true, isActive: true),
    UserModel(id: 'admin1', name: 'Admin User', firstName: 'Admin', lastName: 'User', phone: '0700000000', email: 'admin@bfarm.ug', role: 'Admin', gender: 'Male', district: 'Hoima City', isProfileComplete: true, isVerified: true),
  ];

  // ─── Sample Products ────────────────────────────────
  static final List<ProductModel> products = [
    ProductModel(id: 'p1', sellerId: 'farmer1', sellerName: 'Mugisha Robert', category: 'Produce', productName: 'Maize', quantity: 500, quantityUnit: 'Kg', availability: 'Available Now', price: 1200, district: 'Hoima', imageUrl: 'assets/images/demo/p1_maize.jpg', createdAt: DateTime.now().subtract(const Duration(hours: 2))),
    ProductModel(id: 'p2', sellerId: 'farmer1', sellerName: 'Mugisha Robert', category: 'Produce', productName: 'Beans', quantity: 200, quantityUnit: 'Kg', availability: 'Available Now', price: 3500, district: 'Hoima', imageUrl: 'assets/images/demo/beans.jpg', createdAt: DateTime.now().subtract(const Duration(hours: 5))),
    ProductModel(id: 'p3', sellerId: 'farmer2', sellerName: 'Nakamya Florence', category: 'Produce', productName: 'Rice', quantity: 1000, quantityUnit: 'Kg', availability: 'Available in 1 Week', price: 4000, district: 'Masindi', imageUrl: 'assets/images/demo/rice.jpg', createdAt: DateTime.now().subtract(const Duration(hours: 8))),
    ProductModel(id: 'p4', sellerId: 'farmer2', sellerName: 'Nakamya Florence', category: 'Produce', productName: 'Groundnuts', quantity: 300, quantityUnit: 'Kg', availability: 'Available Now', price: 6000, district: 'Masindi', imageUrl: 'assets/images/demo/groundnuts.jpg', createdAt: DateTime.now().subtract(const Duration(hours: 12))),
    ProductModel(id: 'p5', sellerId: 'farmer3', sellerName: 'Byaruhanga David', category: 'Produce', productName: 'Coffee', quantity: 800, quantityUnit: 'Kg', availability: 'Available Now', price: 8500, district: 'Kikuube', imageUrl: 'assets/images/demo/p5_coffee.jpg', createdAt: DateTime.now().subtract(const Duration(days: 1))),
    ProductModel(id: 'p6', sellerId: 'farmer3', sellerName: 'Byaruhanga David', category: 'Poultry & Livestock', productName: 'Goats', quantity: 15, quantityUnit: 'Pieces', availability: 'Available Now', price: 250000, district: 'Kikuube', imageUrl: 'assets/images/demo/p6_goats.jpg', createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3))),
    ProductModel(id: 'p7', sellerId: 'farmer4', sellerName: 'Ainebyoona Grace', category: 'Fruits & Vegetables', productName: 'Tomatoes', quantity: 150, quantityUnit: 'Crates', availability: 'Available Now', price: 45000, district: 'Kagadi', imageUrl: 'assets/images/demo/p7_tomatoes.jpg', createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 6))),
    ProductModel(id: 'p8', sellerId: 'farmer4', sellerName: 'Ainebyoona Grace', category: 'Fruits & Vegetables', productName: 'Onions', quantity: 200, quantityUnit: 'Kg', availability: 'Available in 2 Weeks', price: 3000, district: 'Kagadi', imageUrl: 'assets/images/demo/p8_onions.jpg', createdAt: DateTime.now().subtract(const Duration(days: 2))),
    ProductModel(id: 'p9', sellerId: 'farmer5', sellerName: 'Tumusiime Joseph', category: 'Produce', productName: 'Soybeans', quantity: 400, quantityUnit: 'Kg', availability: 'Available Now', price: 3800, district: 'Kakumiro', imageUrl: 'assets/images/demo/soybeans.jpg', createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 4))),
    ProductModel(id: 'p10', sellerId: 'farmer5', sellerName: 'Tumusiime Joseph', category: 'Produce', productName: 'Cassava', quantity: 2000, quantityUnit: 'Kg', availability: 'Available in 1 Week', price: 800, district: 'Kakumiro', imageUrl: 'assets/images/demo/p10_cassava.jpg', createdAt: DateTime.now().subtract(const Duration(days: 3))),
    ProductModel(id: 'p11', sellerId: 'farmer6', sellerName: 'Kabahuma Sarah', category: 'Poultry & Livestock', productName: 'Poultry', quantity: 50, quantityUnit: 'Pieces', availability: 'Available Now', price: 25000, district: 'Kibaale', imageUrl: 'assets/images/demo/p11_poultry.jpg', createdAt: DateTime.now().subtract(const Duration(days: 3, hours: 2))),
    ProductModel(id: 'p12', sellerId: 'farmer6', sellerName: 'Kabahuma Sarah', category: 'Fruits & Vegetables', productName: 'Mangoes', quantity: 500, quantityUnit: 'Kg', availability: 'Available in 4 Weeks', price: 2000, district: 'Kibaale', imageUrl: 'assets/images/demo/p12_mangoes.jpg', createdAt: DateTime.now().subtract(const Duration(days: 4))),
    ProductModel(id: 'p13', sellerId: 'farmer1', sellerName: 'Mugisha Robert', category: 'Produce', productName: 'Sweet potatoes', quantity: 600, quantityUnit: 'Kg', availability: 'Available Now', price: 1500, district: 'Hoima', imageUrl: 'assets/images/demo/sweet_potatoes.jpg', createdAt: DateTime.now().subtract(const Duration(days: 4, hours: 5))),
    ProductModel(id: 'p14', sellerId: 'farmer2', sellerName: 'Nakamya Florence', category: 'Poultry & Livestock', productName: 'Cattle', quantity: 5, quantityUnit: 'Pieces', availability: 'Available Now', price: 1500000, district: 'Masindi', imageUrl: 'assets/images/demo/p14_cattle.jpg', createdAt: DateTime.now().subtract(const Duration(days: 5))),
    ProductModel(id: 'p15', sellerId: 'farmer3', sellerName: 'Byaruhanga David', category: 'Produce', productName: 'Cocoa', quantity: 350, quantityUnit: 'Kg', availability: 'Available in 2 Weeks', price: 9500, district: 'Kikuube', imageUrl: 'assets/images/demo/cocoa.jpg', createdAt: DateTime.now().subtract(const Duration(days: 5, hours: 3))),
    ProductModel(id: 'p16', sellerId: 'farmer5', sellerName: 'Tumusiime Joseph', category: 'Fruits & Vegetables', productName: 'Pineapples', quantity: 100, quantityUnit: 'Pieces', availability: 'Available Now', price: 5000, district: 'Kakumiro', imageUrl: 'assets/images/demo/p16_pineapples.jpg', createdAt: DateTime.now().subtract(const Duration(days: 6))),
    ProductModel(id: 'p17', sellerId: 'farmer2', sellerName: 'Nakamya Florence', category: 'Produce', productName: 'Irish', quantity: 250, quantityUnit: 'Kg', availability: 'Available Now', price: 2000, district: 'Masindi', imageUrl: 'assets/images/demo/irish_potatoes.jpg', createdAt: DateTime.now().subtract(const Duration(days: 7))),
  ];

  // ─── Sample Bids ────────────────────────────────────
  static final List<BidModel> bids = [
    BidModel(id: 'b1', productId: 'p1', productName: 'Maize', buyerId: 'buyer1', buyerName: 'Okello James', buyerPhone: '0775123456', sellerId: 'farmer1', quantity: 200, offeredPrice: 1100, status: 'Pending', notes: 'Need delivery to Kampala', createdAt: DateTime.now().subtract(const Duration(hours: 1))),
    BidModel(id: 'b2', productId: 'p5', productName: 'Coffee', buyerId: 'buyer1', buyerName: 'Okello James', buyerPhone: '0775123456', sellerId: 'farmer3', quantity: 300, offeredPrice: 8000, status: 'Under Review', createdAt: DateTime.now().subtract(const Duration(hours: 6))),
    BidModel(id: 'b3', productId: 'p3', productName: 'Rice', buyerId: 'buyer2', buyerName: 'Namukasa Irene', buyerPhone: '0752987654', sellerId: 'farmer2', quantity: 500, offeredPrice: 3800, status: 'Accepted', notes: 'Will pick up from farm', createdAt: DateTime.now().subtract(const Duration(days: 1))),
    BidModel(id: 'b4', productId: 'p7', productName: 'Tomatoes', buyerId: 'buyer2', buyerName: 'Namukasa Irene', buyerPhone: '0752987654', sellerId: 'farmer4', quantity: 50, offeredPrice: 42000, status: 'Completed', createdAt: DateTime.now().subtract(const Duration(days: 3))),
    BidModel(id: 'b5', productId: 'p6', productName: 'Goats', buyerId: 'buyer1', buyerName: 'Okello James', buyerPhone: '0775123456', sellerId: 'farmer3', quantity: 5, offeredPrice: 230000, status: 'Rejected', notes: 'Price too low', createdAt: DateTime.now().subtract(const Duration(days: 2))),
    BidModel(id: 'b6', productId: 'p14', productName: 'Cattle', buyerId: 'buyer2', buyerName: 'Namukasa Irene', buyerPhone: '0752987654', sellerId: 'farmer2', quantity: 2, offeredPrice: 1400000, status: 'Pending', createdAt: DateTime.now().subtract(const Duration(hours: 4))),
  ];

  // ─── Sample Farmer Groups ──────────────────────────
  static final List<FarmerGroupModel> groups = [
    FarmerGroupModel(id: 'g1', groupName: 'Bunyoro Maize Growers', district: 'Hoima', subcounty: 'Buseruka', leaderName: 'Mugisha Robert', leaderPhone: '0771234567', memberCount: 25, registeredBy: 'agent1'),
    FarmerGroupModel(id: 'g2', groupName: 'Masindi Rice Cooperative', district: 'Masindi', subcounty: 'Bwijanga', leaderName: 'Nakamya Florence', leaderPhone: '0782345678', memberCount: 40, registeredBy: 'agent1'),
    FarmerGroupModel(id: 'g3', groupName: 'Kikuube Coffee Farmers', district: 'Kikuube', subcounty: 'Buhimba', leaderName: 'Byaruhanga David', leaderPhone: '0753456789', memberCount: 32, registeredBy: 'agent1'),
  ];

  // ─── Sample Input Dealers ──────────────────────────
  static final List<InputDealerModel> dealers = [
    InputDealerModel(id: 'd1', businessName: 'Hoima Agro Supplies', registrationNumber: 'AGR-001', productType: 'Seeds', phone: '0701234567', district: 'Hoima City', address: 'Main Street, Hoima', isVerified: true, registeredBy: 'agent1'),
    InputDealerModel(id: 'd2', businessName: 'Farm Fresh Inputs', registrationNumber: 'AGR-002', productType: 'Fertilizers', phone: '0712345678', district: 'Masindi', address: 'Market Road, Masindi', isVerified: true, registeredBy: 'agent1'),
  ];

  // Helper getters
  static UserModel get demoFarmer => users.firstWhere((u) => u.id == 'farmer1');
  static UserModel get demoBuyer => users.firstWhere((u) => u.id == 'buyer1');
  static UserModel get demoAgent => users.firstWhere((u) => u.id == 'agent1');
  static UserModel get demoAdmin => users.firstWhere((u) => u.id == 'admin1');

  static List<UserModel> get farmers => users.where((u) => u.role == 'Farmer').toList();
  static List<UserModel> get buyers => users.where((u) => u.role == 'Buyer').toList();
  static List<UserModel> get agents => users.where((u) => u.role == 'Agent').toList();

  static List<ProductModel> productsBy(String sellerId) => products.where((p) => p.sellerId == sellerId).toList();
  static List<BidModel> bidsForProduct(String productId) => bids.where((b) => b.productId == productId).toList();
  static List<BidModel> bidsByBuyer(String buyerId) => bids.where((b) => b.buyerId == buyerId).toList();
  static List<BidModel> bidsBySeller(String sellerId) => bids.where((b) => b.sellerId == sellerId).toList();

  static Map<String, int> get analytics => {
    'totalUsers': users.length,
    'totalFarmers': farmers.length,
    'totalBuyers': buyers.length,
    'totalListings': products.length,
    'totalBids': bids.length,
    'males': users.where((u) => u.gender == 'Male').length,
    'females': users.where((u) => u.gender == 'Female').length,
  };

  // ─── Sample Messages (Admin → Farmers) ─────────────
  static final List<MessageModel> messages = [
    MessageModel(
      id: 'msg1', senderId: 'admin1', senderName: 'BivFarm Admin', senderRole: 'Admin',
      recipientId: 'farmer1', subject: 'Welcome to BivFarm!',
      body: 'Dear Mugisha, welcome to BivFarm marketplace. Your profile has been verified successfully. You can now list your produce and receive bids from buyers across the Bunyoro region.',
      isRead: true, createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    MessageModel(
      id: 'msg2', senderId: 'admin1', senderName: 'BivFarm Admin', senderRole: 'Admin',
      recipientId: 'farmer1', subject: 'New bid on your Maize listing',
      body: 'Good news! A buyer has placed a bid of UGX 1,100/Kg on your Maize listing (200 Kg). Our team is reviewing the bid to ensure fair pricing. We will update you shortly.',
      isRead: true, createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    MessageModel(
      id: 'msg3', senderId: 'registry1', senderName: 'Registry Office', senderRole: 'Registry',
      recipientId: 'farmer1', subject: 'Farmer group registration confirmed',
      body: 'Your farmer group "Bunyoro Maize Growers" has been officially registered with the district registry. Your registration number is BRG-2026-0041. Please keep this for your records.',
      isRead: false, createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    MessageModel(
      id: 'msg4', senderId: 'admin1', senderName: 'BivFarm Admin', senderRole: 'Admin',
      recipientId: 'farmer1', subject: 'Price advisory: Maize season update',
      body: 'Current market price for Maize in the Bunyoro region is UGX 1,200–1,400/Kg. We recommend pricing your listings competitively. Contact your local agent for guidance on best practices.',
      isRead: false, createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    MessageModel(
      id: 'msg5', senderId: 'admin1', senderName: 'BivFarm Admin', senderRole: 'Admin',
      recipientId: 'farmer2', subject: 'Welcome to BivFarm!',
      body: 'Dear Nakamya, your BivFarm account is now active. Start listing your produce to connect with buyers in the region.',
      isRead: false, createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    MessageModel(
      id: 'msg6', senderId: 'admin1', senderName: 'BivFarm Admin', senderRole: 'Admin',
      recipientId: 'farmer2', subject: 'Bid accepted on your Rice',
      body: 'Congratulations! The bid on your Rice listing has been accepted. The buyer will arrange pickup from your farm. Please prepare 500 Kg as agreed. Our team will facilitate the transaction.',
      isRead: false, createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
  ];
}
