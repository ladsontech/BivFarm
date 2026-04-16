
class ProductModel {
  final String id;
  final String sellerId;
  final String sellerName;
  final String category;
  final String productName;
  final double quantity;
  final String quantityUnit;
  final String availability;
  final double price;
  final String district;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.sellerId,
    this.sellerName = '',
    required this.category,
    required this.productName,
    required this.quantity,
    this.quantityUnit = 'Kg',
    required this.availability,
    required this.price,
    required this.district,
    this.imageUrl,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      category: map['category'] ?? '',
      productName: map['productName'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      quantityUnit: map['quantityUnit'] ?? 'Kg',
      availability: map['availability'] ?? 'Available Now',
      price: (map['price'] ?? 0).toDouble(),
      district: map['district'] ?? '',
      imageUrl: map['imageUrl'],
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'].toString()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'sellerName': sellerName,
      'category': category,
      'productName': productName,
      'quantity': quantity,
      'quantityUnit': quantityUnit,
      'availability': availability,
      'price': price,
      'district': district,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ProductModel copyWith({
    String? sellerId,
    String? sellerName,
    String? category,
    String? productName,
    double? quantity,
    String? quantityUnit,
    String? availability,
    double? price,
    String? district,
    String? imageUrl,
    bool? isActive,
  }) {
    return ProductModel(
      id: id,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      category: category ?? this.category,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      availability: availability ?? this.availability,
      price: price ?? this.price,
      district: district ?? this.district,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
