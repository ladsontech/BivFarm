import '../utils/model_parsers.dart';

class InputDealerModel {
  final String id;
  final String businessName;
  final String registrationNumber;
  final String productType;
  final String phone;
  final String district;
  final String subcounty;
  final String village;
  final String address;
  final String? tradingLicensePhoto;
  final bool isVerified;
  final bool isActive;
  final String? registeredBy;
  final DateTime createdAt;

  InputDealerModel({
    required this.id,
    required this.businessName,
    this.registrationNumber = '',
    required this.productType,
    required this.phone,
    required this.district,
    this.subcounty = '',
    this.village = '',
    this.address = '',
    this.tradingLicensePhoto,
    this.isVerified = false,
    this.isActive = true,
    this.registeredBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory InputDealerModel.fromMap(Map<String, dynamic> map, String id) {
    return InputDealerModel(
      id: id,
      businessName: readString(map['businessName']),
      registrationNumber: readString(map['registrationNumber']),
      productType: readString(map['productType']),
      phone: readString(map['phone']),
      district: readString(map['district']),
      subcounty: readString(map['subcounty']),
      village: readString(map['village']),
      address: readString(map['address']),
      tradingLicensePhoto: readNullableString(map['tradingLicensePhoto']),
      isVerified: readBool(map['isVerified']),
      isActive: readBool(map['isActive'], fallback: true),
      registeredBy: readNullableString(map['registeredBy']),
      createdAt: readDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'registrationNumber': registrationNumber,
      'productType': productType,
      'phone': phone,
      'district': district,
      'subcounty': subcounty,
      'village': village,
      'address': address,
      'tradingLicensePhoto': tradingLicensePhoto,
      'isVerified': isVerified,
      'isActive': isActive,
      'registeredBy': registeredBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class FarmerGroupModel {
  final String id;
  final String groupName;
  final String district;
  final String subcounty;
  final String village;
  final String leaderName;
  final String leaderPhone;
  final int memberCount;
  final String
      category; // Produce, Poultry, Livestock, Fruits & Vegetables, All
  final String? userId; // Linked Firebase Auth user account
  final String? registeredBy;
  final DateTime createdAt;

  FarmerGroupModel({
    required this.id,
    required this.groupName,
    required this.district,
    this.subcounty = '',
    this.village = '',
    required this.leaderName,
    required this.leaderPhone,
    this.memberCount = 0,
    this.category = '',
    this.userId,
    this.registeredBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory FarmerGroupModel.fromMap(Map<String, dynamic> map, String id) {
    return FarmerGroupModel(
      id: id,
      groupName: readString(map['groupName']),
      district: readString(map['district']),
      subcounty: readString(map['subcounty']),
      village: readString(map['village']),
      leaderName: readString(map['leaderName']),
      leaderPhone: readString(map['leaderPhone']),
      memberCount: readInt(map['memberCount']),
      category: readString(map['category']),
      userId: readNullableString(map['userId']),
      registeredBy: readNullableString(map['registeredBy']),
      createdAt: readDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupName': groupName,
      'district': district,
      'subcounty': subcounty,
      'village': village,
      'leaderName': leaderName,
      'leaderPhone': leaderPhone,
      'memberCount': memberCount,
      'category': category,
      'userId': userId,
      'registeredBy': registeredBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
