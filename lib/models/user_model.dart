import '../utils/model_parsers.dart';

class UserModel {
  final String id;
  final String name;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String role; // Farmer, Buyer, Store, Agent, Registry, Admin
  final String gender;
  final String nin;
  final String userCategory; // Farmer, Buyer, Both
  final String district;
  final String subcounty;
  final String village;
  final String? profilePhoto;
  final String? bio;
  final String? agentId;
  final String? fcmToken;
  final bool isProfileComplete;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.role,
    this.gender = '',
    this.nin = '',
    this.userCategory = '',
    this.district = '',
    this.subcounty = '',
    this.village = '',
    this.profilePhoto,
    this.bio,
    this.agentId,
    this.fcmToken,
    this.isProfileComplete = false,
    this.isVerified = false,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: readString(map['name']),
      firstName: readString(map['firstName']),
      lastName: readString(map['lastName']),
      phone: readString(map['phone']),
      email: readString(map['email']),
      role: readString(map['role'], fallback: 'Buyer'),
      gender: readString(map['gender']),
      nin: readString(map['nin']),
      userCategory: readString(map['userCategory']),
      district: readString(map['district']),
      subcounty: readString(map['subcounty']),
      village: readString(map['village']),
      profilePhoto: readNullableString(map['profilePhoto']),
      bio: readNullableString(map['bio']),
      agentId: readNullableString(map['agentId']),
      fcmToken: readNullableString(map['fcmToken']),
      isProfileComplete: readBool(map['isProfileComplete']),
      isVerified: readBool(map['isVerified']),
      isActive: readBool(map['isActive'], fallback: true),
      createdAt: readDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'role': role,
      'gender': gender,
      'nin': nin,
      'userCategory': userCategory,
      'district': district,
      'subcounty': subcounty,
      'village': village,
      'profilePhoto': profilePhoto,
      'bio': bio,
      'agentId': agentId,
      'fcmToken': fcmToken,
      'isProfileComplete': isProfileComplete,
      'isVerified': isVerified,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? name,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? role,
    String? gender,
    String? nin,
    String? userCategory,
    String? district,
    String? subcounty,
    String? village,
    String? profilePhoto,
    String? bio,
    String? agentId,
    String? fcmToken,
    bool? isProfileComplete,
    bool? isVerified,
    bool? isActive,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      gender: gender ?? this.gender,
      nin: nin ?? this.nin,
      userCategory: userCategory ?? this.userCategory,
      district: district ?? this.district,
      subcounty: subcounty ?? this.subcounty,
      village: village ?? this.village,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      bio: bio ?? this.bio,
      agentId: agentId ?? this.agentId,
      fcmToken: fcmToken ?? this.fcmToken,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
