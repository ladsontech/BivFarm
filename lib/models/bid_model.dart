
class BidModel {
  final String id;
  final String productId;
  final String productName;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String sellerId;
  final double quantity;
  final double offeredPrice;
  final String status; // Pending, Under Review, Accepted, Rejected, Completed
  final String? notes;
  final String? adminNotes;
  final DateTime createdAt;

  BidModel({
    required this.id,
    required this.productId,
    this.productName = '',
    required this.buyerId,
    this.buyerName = '',
    this.buyerPhone = '',
    required this.sellerId,
    required this.quantity,
    required this.offeredPrice,
    this.status = 'Pending',
    this.notes,
    this.adminNotes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  BidModel copyWith({
    String? status,
    String? adminNotes,
  }) {
    return BidModel(
      id: id,
      productId: productId,
      productName: productName,
      buyerId: buyerId,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      sellerId: sellerId,
      quantity: quantity,
      offeredPrice: offeredPrice,
      status: status ?? this.status,
      notes: notes,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt,
    );
  }

  factory BidModel.fromMap(Map<String, dynamic> map, String id) {
    return BidModel(
      id: id,
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? '',
      buyerPhone: map['buyerPhone'] ?? '',
      sellerId: map['sellerId'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      offeredPrice: (map['offeredPrice'] ?? 0).toDouble(),
      status: map['status'] ?? 'Pending',
      notes: map['notes'],
      adminNotes: map['adminNotes'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'].toString()) : DateTime.now(),
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
      'quantity': quantity,
      'offeredPrice': offeredPrice,
      'status': status,
      'notes': notes,
      'adminNotes': adminNotes,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
