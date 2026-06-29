import '../utils/model_parsers.dart';

class BidModel {
  final String id;
  final String productId;
  final String productName;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String sellerId;
  final String sellerName;
  final String sellerPhone;
  final double quantity;
  final double offeredPrice;
  final String status; // Pending, Under Review, Accepted, Rejected, Completed
  final String? notes;
  final String? adminNotes;
  final bool isRegistryVerified;
  final String? registryNotes;
  final DateTime createdAt;

  BidModel({
    required this.id,
    required this.productId,
    this.productName = '',
    required this.buyerId,
    this.buyerName = '',
    this.buyerPhone = '',
    required this.sellerId,
    this.sellerName = '',
    this.sellerPhone = '',
    required this.quantity,
    required this.offeredPrice,
    this.status = 'Pending',
    this.notes,
    this.adminNotes,
    this.isRegistryVerified = false,
    this.registryNotes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  BidModel copyWith({
    String? status,
    String? adminNotes,
    bool? isRegistryVerified,
    String? registryNotes,
  }) {
    return BidModel(
      id: id,
      productId: productId,
      productName: productName,
      buyerId: buyerId,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      sellerId: sellerId,
      sellerName: sellerName,
      sellerPhone: sellerPhone,
      quantity: quantity,
      offeredPrice: offeredPrice,
      status: status ?? this.status,
      notes: notes,
      adminNotes: adminNotes ?? this.adminNotes,
      isRegistryVerified: isRegistryVerified ?? this.isRegistryVerified,
      registryNotes: registryNotes ?? this.registryNotes,
      createdAt: createdAt,
    );
  }

  factory BidModel.fromMap(Map<String, dynamic> map, String id) {
    return BidModel(
      id: id,
      productId: readString(map['productId']),
      productName: readString(map['productName']),
      buyerId: readString(map['buyerId']),
      buyerName: readString(map['buyerName']),
      buyerPhone: readString(map['buyerPhone']),
      sellerId: readString(map['sellerId']),
      sellerName: readString(map['sellerName']),
      sellerPhone: readString(map['sellerPhone']),
      quantity: readDouble(map['quantity']),
      offeredPrice: readDouble(map['offeredPrice']),
      status: readString(map['status'], fallback: 'Pending'),
      notes: readNullableString(map['notes']),
      adminNotes: readNullableString(map['adminNotes']),
      isRegistryVerified: readBool(map['isRegistryVerified']),
      registryNotes: readNullableString(map['registryNotes']),
      createdAt: readDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerPhone': sellerPhone,
      'quantity': quantity,
      'offeredPrice': offeredPrice,
      'status': status,
      'notes': notes,
      'adminNotes': adminNotes,
      'isRegistryVerified': isRegistryVerified,
      'registryNotes': registryNotes,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
