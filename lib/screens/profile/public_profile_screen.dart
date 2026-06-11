import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';

class PublicProfileScreen extends StatelessWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: Text('Farmer Profile', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18)),
        backgroundColor: AppTheme.background,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<UserModel?>(
        future: db.getUser(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.green));
          }
          final user = snapshot.data;
          if (user == null) {
            return Center(child: Text('Farmer details not found.', style: TextStyle(color: AppTheme.textMuted)));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.surfaceLight,
                  backgroundImage: (user.profilePhoto != null && user.profilePhoto!.isNotEmpty) ? NetworkImage(user.profilePhoto!) : null,
                  child: (user.profilePhoto == null || user.profilePhoto!.isEmpty)
                      ? (user.name.isNotEmpty 
                         ? Text(user.name[0].toUpperCase(), style: TextStyle(color: AppTheme.textMuted, fontSize: 36, fontWeight: FontWeight.w700))
                         : Icon(Icons.person_outline, color: AppTheme.textMuted, size: 40))
                      : null,
                ),
                const SizedBox(height: 16),

                // Name
                Text(
                  user.name.isNotEmpty ? user.name : 'Unknown Farmer',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),

                // Role
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.greenSurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    user.role,
                    style: TextStyle(color: AppTheme.greenLight, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 32),

                // Location Details
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, color: AppTheme.textMuted, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Location',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _infoRow(Icons.map, 'District', user.district.isNotEmpty ? user.district : 'Not specified'),
                      const SizedBox(height: 12),
                      _infoRow(Icons.location_city, 'Subcounty', user.subcounty.isNotEmpty ? user.subcounty : 'Not specified'),
                      const SizedBox(height: 12),
                      _infoRow(Icons.house, 'Village', user.village.isNotEmpty ? user.village : 'Not specified'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                // Notice about contact info
                Text(
                  'Contact information is protected for privacy.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.textMuted, size: 16),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
