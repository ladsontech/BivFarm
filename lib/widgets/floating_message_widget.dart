import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import '../screens/messaging/chat_screen.dart';
import '../screens/messaging/farmer_messages_screen.dart';
import '../models/user_model.dart';

class FloatingMessageWidget extends StatefulWidget {
  final String userId;
  const FloatingMessageWidget({super.key, required this.userId});

  @override
  State<FloatingMessageWidget> createState() => _FloatingMessageWidgetState();
}

class _FloatingMessageWidgetState extends State<FloatingMessageWidget> {
  Offset? position; // Initialized in build to handle screen size

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Default to bottom right, clearly above the Sell Now FAB
    position ??= Offset(size.width - 76, size.height - 240);
    
    return Positioned(
      left: position!.dx,
      top: position!.dy,
      child: Draggable(
        feedback: _buildIcon(isDragging: true),
        childWhenDragging: Container(),
        onDragEnd: (details) {
          setState(() {
            double dx = details.offset.dx;
            double dy = details.offset.dy;
            
            // Basic boundary checks
            if (dx < 0) dx = 0;
            if (dx > size.width - 60) dx = size.width - 60;
            if (dy < 60) dy = 60;
            if (dy > size.height - 120) dy = size.height - 120;
            
            position = Offset(dx, dy);
          });
        },
        child: GestureDetector(
          onTap: () async {
            final db = DatabaseService();
            final currentUser = await db.getUser(widget.userId);
            if (currentUser != null && context.mounted) {
              if (currentUser.role == 'Admin') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FarmerMessagesScreen(userId: currentUser.id))
                );
              } else {
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
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => ChatScreen(currentUser: currentUser, otherUser: supportUser))
                );
              }
            }
          },
          child: _buildIcon(),
        ),
      ),
    );
  }

  Widget _buildIcon({bool isDragging = false}) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.green,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDragging ? 0.3 : 0.2),
              blurRadius: isDragging ? 20 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 28),
      ),
    );
  }
}
