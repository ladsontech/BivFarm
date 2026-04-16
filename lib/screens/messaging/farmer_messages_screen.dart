import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/message_model.dart';
import '../../services/demo_data.dart';
import '../../theme/app_theme.dart';

class FarmerMessagesScreen extends StatefulWidget {
  final String userId;

  const FarmerMessagesScreen({super.key, required this.userId});

  @override
  State<FarmerMessagesScreen> createState() => _FarmerMessagesScreenState();
}

class _FarmerMessagesScreenState extends State<FarmerMessagesScreen> {
  late List<MessageModel> _messages;

  @override
  void initState() {
    super.initState();
    _messages = DemoData.messages
        .where((m) => m.recipientId == widget.userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(dt);
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Admin':
        return Icons.admin_panel_settings;
      case 'Registry':
        return Icons.assignment;
      case 'Agent':
        return Icons.support_agent;
      default:
        return Icons.person;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Admin':
        return AppTheme.green;
      case 'Registry':
        return AppTheme.info;
      case 'Agent':
        return AppTheme.warning;
      default:
        return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, color: AppTheme.textMuted.withOpacity(0.3), size: 64),
            SizedBox(height: 16),
            Text('No messages yet', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
            SizedBox(height: 8),
            Text(
              'Messages from the Admin and\nRegistry will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final unreadCount = _messages.where((m) => !m.isRead).length;

    return Column(
      children: [
        // Header bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline, color: AppTheme.greenLight, size: 20),
              SizedBox(width: 10),
              Text(
                'Messages',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.greenSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$unreadCount unread',
                    style: TextStyle(color: AppTheme.greenLight, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
        // Message list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _messages.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: AppTheme.border, indent: 72),
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final roleColor = _getRoleColor(msg.senderRole);
              return InkWell(
                onTap: () => _showMessageDetail(msg),
                child: Container(
                  color: msg.isRead ? Colors.transparent : AppTheme.greenSurface.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: roleColor.withOpacity(0.15),
                        child: Icon(_getRoleIcon(msg.senderRole), color: roleColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    msg.senderName,
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 14,
                                      fontWeight: msg.isRead ? FontWeight.w500 : FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  _formatTime(msg.createdAt),
                                  style: TextStyle(
                                    color: msg.isRead ? AppTheme.textMuted : AppTheme.greenLight,
                                    fontSize: 11,
                                    fontWeight: msg.isRead ? FontWeight.normal : FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 3),
                            Text(
                              msg.subject,
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: msg.isRead ? FontWeight.w400 : FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2),
                            Text(
                              msg.body,
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Unread dot
                      if (!msg.isRead)
                        Container(
                          margin: const EdgeInsets.only(left: 8, top: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.greenLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showMessageDetail(MessageModel msg) {
    // Mark as read
    setState(() {
      final idx = _messages.indexOf(msg);
      if (idx != -1) {
        _messages[idx] = MessageModel(
          id: msg.id,
          senderId: msg.senderId,
          senderName: msg.senderName,
          senderRole: msg.senderRole,
          recipientId: msg.recipientId,
          subject: msg.subject,
          body: msg.body,
          isRead: true,
          createdAt: msg.createdAt,
        );
      }
    });

    final roleColor = _getRoleColor(msg.senderRole);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scrollCtrl) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollCtrl,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Sender info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: roleColor.withOpacity(0.15),
                        child: Icon(_getRoleIcon(msg.senderRole), color: roleColor, size: 22),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(msg.senderName, style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                            Text(msg.senderRole, style: TextStyle(color: roleColor, fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM, HH:mm').format(msg.createdAt),
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Divider(color: AppTheme.border, height: 1),
                  const SizedBox(height: 16),
                  // Subject
                  Text(
                    msg.subject,
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  // Body
                  Text(
                    msg.body,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.6),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
