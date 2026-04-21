import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/image_source_picker.dart';
import '../../models/product_model.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/constants.dart';

class AddProductScreen extends StatefulWidget {
  final String sellerId;
  final ProductModel? existingProduct;

  const AddProductScreen({super.key, required this.sellerId, this.existingProduct});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService();
  final _storage = StorageService();
  final _picker = ImagePicker();

  late TextEditingController _nameCtrl;
  late TextEditingController _quantityCtrl;
  late TextEditingController _priceCtrl;
  
  String? _category;
  String? _unit;
  String? _availability;
  String? _district;
  File? _imageFile;
  String? _existingImageUrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProduct;
    _nameCtrl = TextEditingController(text: p?.productName ?? '');
    _quantityCtrl = TextEditingController(text: p?.quantity.toString() ?? '');
    _priceCtrl = TextEditingController(text: p?.price.toString() ?? '');
    _category = p?.category;
    _unit = p?.quantityUnit;
    _availability = p?.availability;
    _district = p?.district;
    _existingImageUrl = p?.imageUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await showImageSourcePicker(context);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null || _unit == null || _availability == null || _district == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all dropdowns')));
      return;
    }

    setState(() => _loading = true);
    try {
      String? imageUrl = _existingImageUrl;
      if (_imageFile != null) {
        imageUrl = await _storage.uploadImage(_imageFile!, 'products');
      }

      final product = ProductModel(
        id: widget.existingProduct?.id ?? '',
        sellerId: widget.sellerId,
        category: _category!,
        productName: _nameCtrl.text,
        quantity: double.parse(_quantityCtrl.text),
        quantityUnit: _unit!,
        availability: _availability!,
        price: double.parse(_priceCtrl.text),
        district: _district!,
        imageUrl: imageUrl,
        createdAt: widget.existingProduct?.createdAt,
      );

      if (widget.existingProduct == null) {
        await _db.addProduct(product);
      } else {
        await _db.updateProduct(widget.existingProduct!.id, product.toMap());
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existingProduct == null ? 'Add Listing' : 'Edit Listing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                    image: _imageFile != null 
                        ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                        : (_existingImageUrl != null 
                            ? DecorationImage(image: NetworkImage(_existingImageUrl!), fit: BoxFit.cover)
                            : null),
                  ),
                  child: (_imageFile == null && _existingImageUrl == null)
                      ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_a_photo, color: AppTheme.textMuted, size: 32),
                          const SizedBox(height: 8),
                          Text('Add Product Photo', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        ])
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              CustomDropdown(
                label: 'Category', 
                value: _category,
                items: AppConstants.productCategories.keys.toList(), 
                onChanged: (v) => setState(() => _category = v),
              ),
              const SizedBox(height: 14),
              CustomTextField(label: 'Product Name', hint: 'Enter product name', controller: _nameCtrl),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(flex: 2, child: CustomTextField(label: 'Quantity', hint: 'e.g. 100', controller: _quantityCtrl, keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: CustomDropdown(label: 'Unit', value: _unit, items: AppConstants.quantityUnits, onChanged: (v) => setState(() => _unit = v))),
              ]),
              const SizedBox(height: 14),
              CustomDropdown(label: 'Availability', value: _availability, items: AppConstants.availabilityOptions, onChanged: (v) => setState(() => _availability = v)),
              const SizedBox(height: 14),
              CustomTextField(label: 'Price (UGX)', hint: 'e.g. 50000', controller: _priceCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              CustomDropdown(label: 'District', value: _district, items: AppConstants.bunyoroDistricts, onChanged: (v) => setState(() => _district = v)),
              const SizedBox(height: 28),
              CustomButton(
                text: widget.existingProduct == null ? 'Create Listing' : 'Save Changes',
                onPressed: _save,
                isLoading: _loading,
              ),
              if (widget.existingProduct != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () async {
                    await _db.deleteProduct(widget.existingProduct!.id);
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('Delete Listing', style: TextStyle(color: AppTheme.error)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
