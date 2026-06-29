import '../utils/model_parsers.dart';

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
      senderId: readString(map['senderId']),
      senderName: readString(map['senderName']),
      senderRole: readString(map['senderRole'], fallback: 'Admin'),
      recipientId: readString(map['recipientId']),
      subject: readString(map['subject']),
      body: readString(map['body']),
      isRead: readBool(map['isRead']),
      createdAt: readDate(map['createdAt']),
    );
  }
}
