class NotificationModel {
  final String id;
  final String recipientId;
  final String? senderId;
  final String title;
  final String body;
  final String type; // 'message', 'bid', 'order', 'general'
  final String? relatedId; // ID of the message/bid/order
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.recipientId,
    this.senderId,
    required this.title,
    required this.body,
    this.type = 'general',
    this.relatedId,
    this.isRead = false,
    DateTime? createdAt,
    this.data,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'senderId': senderId,
      'title': title,
      'body': body,
      'type': type,
      'relatedId': relatedId,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'data': data,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      recipientId: map['recipientId'] ?? '',
      senderId: map['senderId'],
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'general',
      relatedId: map['relatedId'],
      isRead: map['isRead'] ?? false,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      data: map['data'],
    );
  }
}
