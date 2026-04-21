import 'package:cloud_firestore/cloud_firestore.dart';

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
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? '',
      buyerPhone: map['buyerPhone'] ?? '',
      orderType: map['orderType'] ?? 'Produce',
      category: map['category'] ?? '',
      itemName: map['itemName'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      quantityUnit: map['quantityUnit'] ?? 'Kg',
      notes: map['notes'] ?? '',
      adminNotes: map['adminNotes'] ?? '',
      status: map['status'] ?? 'Pending',
      createdAt: _parseDate(map['createdAt']),
    );
  }

  static DateTime _parseDate(dynamic dateVal) {
    if (dateVal == null) return DateTime.now();
    if (dateVal is Timestamp) return dateVal.toDate();
    if (dateVal is String) return DateTime.tryParse(dateVal) ?? DateTime.now();
    return DateTime.now();
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
