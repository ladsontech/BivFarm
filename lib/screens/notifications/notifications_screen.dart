import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  final String userId;
  const NotificationsScreen({super.key, required this.userId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final db = DatabaseService();

  String _timeAgo(DateTime d) {
    Duration diff = DateTime.now().difference(d);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 7) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  void _markAllAsRead(List<NotificationModel> notes) async {
    for (var n in notes) {
      if (!n.isRead) {
        await db.markNotificationRead(n.id);
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: db.streamNotifications(widget.userId),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.green));
          }
          final notes = snap.data ?? [];
          
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.notifications_off_outlined, size: 48, color: AppTheme.textMuted.withOpacity(0.5)),
                  ),
                  const SizedBox(height: 20),
                  Text('All Caught Up!', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('You have no new notifications.', style: TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            );
          }

          final unreadCount = notes.where((n) => !n.isRead).length;

          return Column(
            children: [
              if (unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$unreadCount Unread', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                      GestureDetector(
                        onTap: () => _markAllAsRead(notes),
                        child: const Text('Mark all as read', style: TextStyle(color: AppTheme.greenLight, fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (ctx, i) {
                    final n = notes[i];
                    return _NotificationTile(
                      notification: n, 
                      db: db,
                      timeAgo: _timeAgo(n.createdAt),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final DatabaseService db;
  final String timeAgo;
  const _NotificationTile({required this.notification, required this.db, required this.timeAgo});

  IconData _getIcon() {
    switch (notification.type.toLowerCase()) {
      case 'bid':
        return Icons.gavel;
      case 'message':
        return Icons.chat_bubble_outline;
      case 'order':
        return Icons.shopping_cart_checkout;
      default:
        return Icons.notifications_active_outlined;
    }
  }
  
  Color _getIconColor() {
    if (notification.isRead) return AppTheme.textMuted;
    switch (notification.type.toLowerCase()) {
      case 'bid': return Colors.orange;
      case 'message': return Colors.blue;
      case 'order': return AppTheme.greenLight;
      default: return AppTheme.greenLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (!notification.isRead) {
          db.markNotificationRead(notification.id);
        }
        // Navigate to related content if needed
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.transparent : AppTheme.greenSurface.withOpacity(0.15),
          border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: notification.isRead ? AppTheme.surfaceLight : AppTheme.card,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: notification.isRead ? AppTheme.border : _getIconColor().withOpacity(0.3),
                    ),
                  ),
                  child: Icon(_getIcon(), color: _getIconColor(), size: 22),
                ),
                if (!notification.isRead)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.background, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          color: notification.isRead ? AppTheme.textMuted : AppTheme.greenLight, 
                          fontSize: 12,
                          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.body,
                    style: TextStyle(
                      color: notification.isRead ? AppTheme.textMuted : AppTheme.textSecondary, 
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
