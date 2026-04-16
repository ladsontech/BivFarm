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
}
