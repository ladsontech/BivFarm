import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/constants.dart';

class DemoAddProduct extends StatelessWidget {
  const DemoAddProduct({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Listing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_a_photo, color: AppTheme.textMuted, size: 32),
                SizedBox(height: 8),
                Text('Add Product Photo', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 20),
            CustomDropdown(label: 'Category', items: AppConstants.productCategories.keys.toList(), onChanged: (_) {}),
            const SizedBox(height: 14),
            const CustomTextField(label: 'Product Name', hint: 'Enter product name'),
            const SizedBox(height: 14),
            Row(children: [
              const Expanded(flex: 2, child: CustomTextField(label: 'Quantity', hint: 'e.g. 100')),
              const SizedBox(width: 12),
              Expanded(child: CustomDropdown(label: 'Unit', items: AppConstants.quantityUnits, onChanged: (_) {})),
            ]),
            const SizedBox(height: 14),
            CustomDropdown(label: 'Availability', items: AppConstants.availabilityOptions, onChanged: (_) {}),
            const SizedBox(height: 14),
            const CustomTextField(label: 'Price (UGX)', hint: 'e.g. 50000'),
            const SizedBox(height: 14),
            CustomDropdown(label: 'District', items: AppConstants.bunyoroDistricts, onChanged: (_) {}),
            const SizedBox(height: 28),
            CustomButton(
              text: 'Create Listing',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing created! (Demo)')));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
