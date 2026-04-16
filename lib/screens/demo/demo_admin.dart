import 'package:flutter/material.dart';
import '../../services/demo_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class DemoAdminScreen extends StatelessWidget {
  const DemoAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = DemoData.analytics;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overview', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                StatCard(title: 'Farmers', value: '${data['totalFarmers']}', icon: Icons.grass, color: AppTheme.greenLight),
                StatCard(title: 'Buyers', value: '${data['totalBuyers']}', icon: Icons.shopping_bag, color: AppTheme.info),
                StatCard(title: 'Listings', value: '${data['totalListings']}', icon: Icons.inventory_2, color: AppTheme.warning),
                StatCard(title: 'Bids', value: '${data['totalBids']}', icon: Icons.gavel, color: AppTheme.greenAccent),
              ],
            ),
            SizedBox(height: 24),
            Text('Gender Distribution', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border, width: 0.5)),
              child: Row(
                children: [
                  Expanded(child: _genderBar('Male', data['males']!, data['totalUsers']!, AppTheme.info)),
                  SizedBox(width: 20),
                  Expanded(child: _genderBar('Female', data['females']!, data['totalUsers']!, AppTheme.greenLight)),
                ],
              ),
            ),
            SizedBox(height: 24),
            Text('Registered Users', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 12),
            ...DemoData.users.map((u) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.border, width: 0.5)),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.surfaceLight,
                    child: Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(u.name, style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                      Text('${u.role} • ${u.district}', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppTheme.greenSurface, borderRadius: BorderRadius.circular(4)),
                    child: Text(u.role, style: TextStyle(color: AppTheme.greenLight, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _genderBar(String label, int count, int total, Color color) {
    final pct = total > 0 ? (count / total * 100).round() : 0;
    return Column(children: [
      Text('$count', style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w700)),
      SizedBox(height: 4),
      Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(value: total > 0 ? count / total : 0, backgroundColor: AppTheme.surfaceLight, color: color, minHeight: 6),
      ),
      SizedBox(height: 4),
      Text('$pct%', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
    ]);
  }
}
