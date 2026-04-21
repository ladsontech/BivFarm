class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole; // Admin, Registry, Agent
  final String recipientId;
  final String subject;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.senderId,
    this.senderName = 'Administrator',
    this.senderRole = 'Admin',
    required this.recipientId,
    this.subject = '',
    required this.body,
    this.isRead = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'recipientId': recipientId,
      'subject': subject,
      'body': body,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderRole: map['senderRole'] ?? 'Admin',
      recipientId: map['recipientId'] ?? '',
      subject: map['subject'] ?? '',
      body: map['body'] ?? '',
      isRead: map['isRead'] ?? false,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }
}
