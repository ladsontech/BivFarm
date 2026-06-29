import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/message_model.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/responsive_wrapper.dart';
import 'chat_screen.dart';

class FarmerMessagesScreen extends StatefulWidget {
  final String userId;

  const FarmerMessagesScreen({super.key, required this.userId});

  @override
  State<FarmerMessagesScreen> createState() => _FarmerMessagesScreenState();
}

class _FarmerMessagesScreenState extends State<FarmerMessagesScreen> {
  final _db = DatabaseService();

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
      case 'Support':
        return Icons.support_agent;
      default:
        return Icons.person;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Admin':
      case 'Support':
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
    return FutureBuilder<UserModel?>(
      future: _db.getUser(widget.userId),
      builder: (context, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: const Center(
                child: CircularProgressIndicator(color: AppTheme.green)),
          );
        }
        if (userSnap.hasError) {
          return const Scaffold(
            body: AppErrorState(title: 'Unable to load messages'),
          );
        }

        final currentUser = userSnap.data;
        if (currentUser == null) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: const Center(child: Text('User not found')),
          );
        }

        final isAdmin = currentUser.role == 'Admin';
        return isAdmin
            ? _buildAdminMessages(currentUser)
            : _buildCustomerMessages(currentUser);
      },
    );
  }

  Widget _buildAdminMessages(UserModel currentUser) {
    return StreamBuilder<List<MessageModel>>(
      stream: _db.streamSupportConversations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: const Center(
                child: CircularProgressIndicator(color: AppTheme.green)),
          );
        }
        if (snapshot.hasError) {
          return const Scaffold(
            body: AppErrorState(title: 'Unable to load conversations'),
          );
        }

        final allMessages = snapshot.data ?? [];

        // Group messages by the customer (the non-support party)
        final userThreads = <String, List<MessageModel>>{};
        for (final msg in allMessages) {
          final otherUserId =
              msg.senderId == 'support' ? msg.recipientId : msg.senderId;
          if (otherUserId.isNotEmpty && otherUserId != 'support') {
            userThreads.putIfAbsent(otherUserId, () => []).add(msg);
          }
        }

        final threads = userThreads.entries.toList();
        // Sort threads by the latest message's createdAt descending
        threads.sort((a, b) =>
            b.value.first.createdAt.compareTo(a.value.first.createdAt));

        final totalUnreadCount = allMessages
            .where((m) => m.recipientId == 'support' && !m.isRead)
            .length;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('Support Desk'),
            actions: [
              if (totalUnreadCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$totalUnreadCount Unread',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: ResponsiveWrapper(
            maxWidth: 900,
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    border: Border(
                        bottom: BorderSide(color: AppTheme.border, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline,
                          color: AppTheme.greenLight, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'All Customer Conversations',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: threads.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  color: AppTheme.textMuted.withOpacity(0.3),
                                  size: 64),
                              const SizedBox(height: 16),
                              Text('No customer chats yet',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: threads.length,
                          separatorBuilder: (_, __) => Divider(
                              height: 1, color: AppTheme.border, indent: 72),
                          itemBuilder: (context, index) {
                            final entry = threads[index];
                            final otherUserId = entry.key;
                            final threadMessages = entry.value;
                            final latestMsg = threadMessages.first;

                            // Find a message sent by the user to extract fallback sender details
                            final userMsg = threadMessages.firstWhere(
                                (m) => m.senderId != 'support',
                                orElse: () => latestMsg);

                            return FutureBuilder<UserModel?>(
                              future: _db.getUser(otherUserId),
                              builder: (context, userSnap) {
                                final user = userSnap.data;
                                final displayName =
                                    user?.name ?? userMsg.senderName;
                                final displayRole =
                                    user?.role ?? userMsg.senderRole;
                                final roleColor = _getRoleColor(displayRole);
                                final roleIcon = _getRoleIcon(displayRole);

                                // Count unread support messages from this customer
                                final threadUnreadCount = threadMessages
                                    .where((m) =>
                                        m.recipientId == 'support' && !m.isRead)
                                    .length;
                                final isThreadUnread = threadUnreadCount > 0;

                                return InkWell(
                                  onTap: () async {
                                    // Mark support messages from this user as read
                                    await _db
                                        .markSupportMessagesRead(otherUserId);

                                    if (context.mounted) {
                                      // If user is loaded, push ChatScreen. Else fetch on tap.
                                      final targetUser = user ??
                                          await _db.getUser(otherUserId);
                                      if (targetUser != null &&
                                          context.mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ChatScreen(
                                                currentUser: currentUser,
                                                otherUser: targetUser),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: Container(
                                    color: isThreadUnread
                                        ? AppTheme.greenSurface.withOpacity(0.3)
                                        : Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor:
                                              roleColor.withOpacity(0.15),
                                          child: Icon(roleIcon,
                                              color: roleColor, size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      displayName,
                                                      style: TextStyle(
                                                        color: AppTheme
                                                            .textPrimary,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            isThreadUnread
                                                                ? FontWeight
                                                                    .w700
                                                                : FontWeight
                                                                    .w500,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    _formatTime(
                                                        latestMsg.createdAt),
                                                    style: TextStyle(
                                                      color: isThreadUnread
                                                          ? AppTheme.greenLight
                                                          : AppTheme.textMuted,
                                                      fontSize: 11,
                                                      fontWeight: isThreadUnread
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: roleColor
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text(
                                                      displayRole,
                                                      style: TextStyle(
                                                          color: roleColor,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w600),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      latestMsg.body,
                                                      style: TextStyle(
                                                        color: isThreadUnread
                                                            ? AppTheme
                                                                .textPrimary
                                                            : AppTheme
                                                                .textMuted,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            isThreadUnread
                                                                ? FontWeight
                                                                    .w500
                                                                : FontWeight
                                                                    .normal,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isThreadUnread)
                                          Container(
                                            margin: const EdgeInsets.only(
                                                left: 8, top: 4),
                                            padding: const EdgeInsets.all(6),
                                            decoration: const BoxDecoration(
                                              color: AppTheme.greenLight,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              '$threadUnreadCount',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomerMessages(UserModel currentUser) {
    return StreamBuilder<List<MessageModel>>(
      stream: _db.streamMessagesByUser(currentUser.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.green));
        }
        if (snapshot.hasError) {
          return const AppErrorState(title: 'Unable to load messages');
        }

        final messages = snapshot.data ?? [];
        final unreadCount = messages.where((m) => !m.isRead).length;

        final supportUser = UserModel(
          id: 'support',
          name: 'BFarm Support',
          firstName: 'BFarm',
          lastName: 'Support',
          email: 'support@bfarm.com',
          phone: '',
          role: 'Support',
          district: '',
          subcounty: '',
          village: '',
          isVerified: true,
          isProfileComplete: true,
        );

        return Scaffold(
          backgroundColor: AppTheme.background,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ChatScreen(
                        currentUser: currentUser, otherUser: supportUser)),
              );
            },
            backgroundColor: AppTheme.green,
            icon: const Icon(Icons.edit_note, color: Colors.white),
            label:
                const Text('Start Chat', style: TextStyle(color: Colors.white)),
          ),
          body: ResponsiveWrapper(
            maxWidth: 900,
            child: Column(
              children: [
                // Header bar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    border: Border(
                        bottom: BorderSide(color: AppTheme.border, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline,
                          color: AppTheme.greenLight, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Messages',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.greenSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$unreadCount unread',
                            style: TextStyle(
                                color: AppTheme.greenLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ),
                // Message list
                Expanded(
                  child: messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  color: AppTheme.textMuted.withOpacity(0.3),
                                  size: 64),
                              const SizedBox(height: 16),
                              Text('No messages yet',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                            currentUser: currentUser,
                                            otherUser: supportUser)),
                                  );
                                },
                                icon: const Icon(Icons.support_agent),
                                label: const Text('Chat with Admin Support'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.green,
                                  side: const BorderSide(
                                      color: AppTheme.green, width: 1),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: messages.length,
                          separatorBuilder: (_, __) => Divider(
                              height: 1, color: AppTheme.border, indent: 72),
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final isSupport = msg.senderId == 'support' ||
                                msg.senderId == 'admin' ||
                                msg.senderRole == 'Admin' ||
                                msg.senderRole == 'Support';
                            final displaySenderName =
                                isSupport ? 'BFarm Support' : msg.senderName;
                            final displaySenderRole =
                                isSupport ? 'Support' : msg.senderRole;

                            final roleColor = _getRoleColor(displaySenderRole);
                            final roleIcon = _getRoleIcon(displaySenderRole);

                            return InkWell(
                              onTap: () {
                                if (!msg.isRead) {
                                  _db.markMessageRead(msg.id);
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                        currentUser: currentUser,
                                        otherUser: supportUser),
                                  ),
                                );
                              },
                              child: Container(
                                color: msg.isRead
                                    ? Colors.transparent
                                    : AppTheme.greenSurface.withOpacity(0.3),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor:
                                          roleColor.withOpacity(0.15),
                                      child: Icon(roleIcon,
                                          color: roleColor, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  displaySenderName,
                                                  style: TextStyle(
                                                    color: AppTheme.textPrimary,
                                                    fontSize: 14,
                                                    fontWeight: msg.isRead
                                                        ? FontWeight.w500
                                                        : FontWeight.w700,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _formatTime(msg.createdAt),
                                                style: TextStyle(
                                                  color: msg.isRead
                                                      ? AppTheme.textMuted
                                                      : AppTheme.greenLight,
                                                  fontSize: 11,
                                                  fontWeight: msg.isRead
                                                      ? FontWeight.normal
                                                      : FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            msg.subject,
                                            style: TextStyle(
                                              color: AppTheme.textPrimary,
                                              fontSize: 13,
                                              fontWeight: msg.isRead
                                                  ? FontWeight.w400
                                                  : FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            msg.body,
                                            style: TextStyle(
                                                color: AppTheme.textMuted,
                                                fontSize: 12),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!msg.isRead)
                                      Container(
                                        margin: const EdgeInsets.only(
                                            left: 8, top: 4),
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
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
            ),
          ),
        );
      },
    );
  }
}
