import 'package:flutter/material.dart';

class AddProductScreen extends StatelessWidget {
  final String sellerId;
  const AddProductScreen({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Add Product (Disabled in Demo)')));
  }
}
