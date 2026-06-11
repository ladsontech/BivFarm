class ProductModel {
  final String id;
  final String sellerId;
  final String sellerName;
  final String? sellerPhoto;
  final String? sellerPhone;
  final String category;
  final String productName;
  final double quantity;
  final String quantityUnit;
  final String availability;
  final double price;
  final String district;
  final List<String> imageUrls;
  final bool isActive;
  final String? agentId;
  final DateTime createdAt;
  final String sellerRole;

  /// Backward-compatible getter: returns first image or null
  String? get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  ProductModel({
    required this.id,
    required this.sellerId,
    this.sellerName = '',
    this.sellerPhoto,
    this.sellerPhone,
    required this.category,
    required this.productName,
    required this.quantity,
    this.quantityUnit = 'Kg',
    required this.availability,
    required this.price,
    required this.district,
    List<String>? imageUrls,
    @Deprecated('Use imageUrls instead') String? imageUrl,
    this.isActive = true,
    this.agentId,
    DateTime? createdAt,
    this.sellerRole = '',
  })  : imageUrls = imageUrls ?? (imageUrl != null ? [imageUrl] : []),
        createdAt = createdAt ?? DateTime.now();

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    // Support both old single imageUrl and new imageUrls list
    List<String> urls = [];
    if (map['imageUrls'] != null && map['imageUrls'] is List) {
      urls = List<String>.from(map['imageUrls']);
    } else if (map['imageUrl'] != null && (map['imageUrl'] as String).isNotEmpty) {
      urls = [map['imageUrl'] as String];
    }

    return ProductModel(
      id: id,
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      sellerPhoto: map['sellerPhoto'],
      sellerPhone: map['sellerPhone'],
      category: map['category'] ?? '',
      productName: map['productName'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      quantityUnit: map['quantityUnit'] ?? 'Kg',
      availability: map['availability'] ?? 'Available Now',
      price: (map['price'] ?? 0).toDouble(),
      district: map['district'] ?? '',
      imageUrls: urls,
      isActive: map['isActive'] ?? true,
      agentId: map['agentId'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'].toString()) : DateTime.now(),
      sellerRole: map['sellerRole'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerPhoto': sellerPhoto,
      'sellerPhone': sellerPhone,
      'category': category,
      'productName': productName,
      'quantity': quantity,
      'quantityUnit': quantityUnit,
      'availability': availability,
      'price': price,
      'district': district,
      'imageUrls': imageUrls,
      'imageUrl': imageUrl, // backward compat for old queries
      'isActive': isActive,
      'agentId': agentId,
      'createdAt': createdAt.toIso8601String(),
      'sellerRole': sellerRole,
    };
  }

  ProductModel copyWith({
    String? sellerId,
    String? sellerName,
    String? sellerPhoto,
    String? sellerPhone,
    String? category,
    String? productName,
    double? quantity,
    String? quantityUnit,
    String? availability,
    double? price,
    String? district,
    List<String>? imageUrls,
    bool? isActive,
    String? agentId,
    String? sellerRole,
  }) {
    return ProductModel(
      id: id,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerPhoto: sellerPhoto ?? this.sellerPhoto,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      category: category ?? this.category,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      availability: availability ?? this.availability,
      price: price ?? this.price,
      district: district ?? this.district,
      imageUrls: imageUrls ?? this.imageUrls,
      isActive: isActive ?? this.isActive,
      agentId: agentId ?? this.agentId,
      createdAt: createdAt,
      sellerRole: sellerRole ?? this.sellerRole,
    );
  }
}
