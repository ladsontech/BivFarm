import '../utils/model_parsers.dart';

class BulkOrderModel {
  final String id;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String orderType; // 'Produce' or 'Input'
  final String category; // e.g. Gnuts, Fertilizer, Beans
  final String itemName; // e.g. red beauty gnuts, NPK 17-17-17
  final double quantity;
  final String quantityUnit;
  final String notes;
  final String adminNotes;
  final String status; // Pending, Processing, Distributor Assigned, Completed
  final DateTime createdAt;

  BulkOrderModel({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    required this.orderType,
    required this.category,
    required this.itemName,
    required this.quantity,
    required this.quantityUnit,
    this.notes = '',
    this.adminNotes = '',
    this.status = 'Pending',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  BulkOrderModel copyWith({
    String? status,
    String? adminNotes,
  }) {
    return BulkOrderModel(
      id: id,
      buyerId: buyerId,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      orderType: orderType,
      category: category,
      itemName: itemName,
      quantity: quantity,
      quantityUnit: quantityUnit,
      notes: notes,
      adminNotes: adminNotes ?? this.adminNotes,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  factory BulkOrderModel.fromMap(Map<String, dynamic> map, String id) {
    return BulkOrderModel(
      id: id,
      buyerId: readString(map['buyerId']),
      buyerName: readString(map['buyerName']),
      buyerPhone: readString(map['buyerPhone']),
      orderType: readString(map['orderType'], fallback: 'Produce'),
      category: readString(map['category']),
      itemName: readString(map['itemName']),
      quantity: readDouble(map['quantity']),
      quantityUnit: readString(map['quantityUnit'], fallback: 'Kg'),
      notes: readString(map['notes']),
      adminNotes: readString(map['adminNotes']),
      status: readString(map['status'], fallback: 'Pending'),
      createdAt: readDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'orderType': orderType,
      'category': category,
      'itemName': itemName,
      'quantity': quantity,
      'quantityUnit': quantityUnit,
      'notes': notes,
      'adminNotes': adminNotes,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
