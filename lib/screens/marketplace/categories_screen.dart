import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

class CategoriesScreen extends StatelessWidget {
  final Function(String) onCategorySelected;

  const CategoriesScreen({super.key, required this.onCategorySelected});

  String _getCategoryImage(String category) {
    switch (category) {
      case 'Produce':
        return 'assets/images/categories/farm_produce.jpg';
      case 'Poultry':
        return 'assets/images/categories/poultry_products.jpg';
      case 'Livestock':
        return 'assets/images/categories/livestock.jpg';
      case 'Fruits & Vegetables':
        return 'assets/images/categories/fruits_and_vegetables.jpg';
      case 'Farm Machinery':
        return 'assets/images/categories/farm_machinery.jpg';
      case 'Fertilizers & Pesticides':
        return 'assets/images/carousel/firm_chemicals.jpg';
      default:
        return 'assets/images/categories/farm_produce.jpg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = AppConstants.productCategories.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Categories'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.0, // Square tiles
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final cat = categories[i];
          final img = _getCategoryImage(cat);
          return GestureDetector(
            onTap: () => onCategorySelected(cat),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border, width: 0.5),
                image: DecorationImage(
                  image: AssetImage(img),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.4),
                    BlendMode.darken,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    cat,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
