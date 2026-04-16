import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class DemoBidForm extends StatelessWidget {
  final ProductModel product;
  const DemoBidForm({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Place a Bid')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border, width: 0.5)),
              child: Row(
                children: [
                  Container(width: 50, height: 50, decoration: BoxDecoration(color: AppTheme.greenSurface, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.eco, color: AppTheme.greenLight)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(product.productName, style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                      Text('${product.quantity} ${product.quantityUnit} • ${product.district}', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const CustomTextField(label: 'Quantity Requested', hint: 'e.g. 50'),
            const SizedBox(height: 14),
            const CustomTextField(label: 'Your Proposed Price (UGX)', hint: 'e.g. 45000'),
            const SizedBox(height: 14),
            const CustomTextField(label: 'Notes (optional)', hint: 'Any additional details...', maxLines: 3),
            SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(Icons.info_outline, color: AppTheme.textMuted, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text('Your bid will be sent to the registry for review. The registry will coordinate between you and the farmer.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12))),
              ]),
            ),
            const SizedBox(height: 28),
            CustomButton(
              text: 'Submit Bid',
              icon: Icons.gavel,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bid placed successfully! (Demo)')));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
