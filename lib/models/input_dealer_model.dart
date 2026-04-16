
class InputDealerModel {
  final String id;
  final String businessName;
  final String registrationNumber;
  final String productType;
  final String phone;
  final String district;
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
      businessName: map['businessName'] ?? '',
      registrationNumber: map['registrationNumber'] ?? '',
      productType: map['productType'] ?? '',
      phone: map['phone'] ?? '',
      district: map['district'] ?? '',
      address: map['address'] ?? '',
      tradingLicensePhoto: map['tradingLicensePhoto'],
      isVerified: map['isVerified'] ?? false,
      isActive: map['isActive'] ?? true,
      registeredBy: map['registeredBy'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'].toString()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'registrationNumber': registrationNumber,
      'productType': productType,
      'phone': phone,
      'district': district,
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
    this.registeredBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory FarmerGroupModel.fromMap(Map<String, dynamic> map, String id) {
    return FarmerGroupModel(
      id: id,
      groupName: map['groupName'] ?? '',
      district: map['district'] ?? '',
      subcounty: map['subcounty'] ?? '',
      village: map['village'] ?? '',
      leaderName: map['leaderName'] ?? '',
      leaderPhone: map['leaderPhone'] ?? '',
      memberCount: map['memberCount'] ?? 0,
      registeredBy: map['registeredBy'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'].toString()) : DateTime.now(),
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
      'registeredBy': registeredBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
