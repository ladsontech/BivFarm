import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/image_source_picker.dart';
import '../../models/product_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
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

  late TextEditingController _nameCtrl;
  late TextEditingController _quantityCtrl;
  late TextEditingController _priceCtrl;
  
  String? _category;
  String? _unit;
  String? _availability;
  String? _district;
  
  // Multi-image support
  final List<File> _newImageFiles = [];
  List<String> _existingImageUrls = [];
  bool _loading = false;

  static const int _maxImages = 5;

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
    _existingImageUrls = List.from(p?.imageUrls ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  int get _totalImages => _existingImageUrls.length + _newImageFiles.length;

  Future<void> _pickImage() async {
    if (_totalImages >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum $_maxImages images allowed')),
      );
      return;
    }
    final picked = await showImageSourcePicker(context);
    if (picked != null) {
      setState(() => _newImageFiles.add(File(picked.path)));
    }
  }

  void _removeExistingImage(int index) {
    setState(() => _existingImageUrls.removeAt(index));
  }

  void _removeNewImage(int index) {
    setState(() => _newImageFiles.removeAt(index));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null || _unit == null || _availability == null || _district == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all dropdowns')));
      return;
    }

    setState(() => _loading = true);
    try {
      // Upload new images
      List<String> allUrls = List.from(_existingImageUrls);
      for (final file in _newImageFiles) {
        final url = await _storage.uploadImage(file, 'products');
        allUrls.add(url);
      }

      // Fetch seller profile for name, photo and phone
      String sellerName = '';
      String? sellerPhoto;
      String? sellerPhone;
      try {
        final sellerUser = await _db.getUser(widget.sellerId);
        if (sellerUser != null) {
          sellerName = sellerUser.name.isNotEmpty ? sellerUser.name : (AuthService().currentUser?.email ?? '');
          sellerPhoto = sellerUser.profilePhoto;
          sellerPhone = sellerUser.phone.isNotEmpty ? sellerUser.phone : null;
        }
      } catch (_) {}

      final product = ProductModel(
        id: widget.existingProduct?.id ?? '',
        sellerId: widget.sellerId,
        sellerName: sellerName,
        sellerPhoto: sellerPhoto,
        sellerPhone: sellerPhone,
        category: _category!,
        productName: _nameCtrl.text,
        quantity: double.parse(_quantityCtrl.text),
        quantityUnit: _unit!,
        availability: _availability!,
        price: double.parse(_priceCtrl.text),
        district: _district!,
        imageUrls: allUrls,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image Section ──────────────
              Text(
                'Product Photos',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                '$_totalImages / $_maxImages photos',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              _buildImageGrid(),
              const SizedBox(height: 20),

              // ── Form Fields ────────────────
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

  Widget _buildImageGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        // Existing images from server
        for (int i = 0; i < _existingImageUrls.length; i++)
          _buildImageTile(
            child: Image.network(_existingImageUrls[i], fit: BoxFit.cover),
            onRemove: () => _removeExistingImage(i),
            isFirst: i == 0 && _newImageFiles.isEmpty,
          ),
        // New local images
        for (int i = 0; i < _newImageFiles.length; i++)
          _buildImageTile(
            child: Image.file(_newImageFiles[i], fit: BoxFit.cover),
            onRemove: () => _removeNewImage(i),
            isFirst: _existingImageUrls.isEmpty && i == 0,
          ),
        // Add button
        if (_totalImages < _maxImages)
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: _totalImages == 0 ? double.infinity : 100,
              height: _totalImages == 0 ? 180 : 100,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, color: AppTheme.textMuted, size: _totalImages == 0 ? 32 : 24),
                  const SizedBox(height: 6),
                  Text(
                    _totalImages == 0 ? 'Add Product Photos' : 'Add More',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: _totalImages == 0 ? 13 : 11),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageTile({
    required Widget child,
    required VoidCallback onRemove,
    bool isFirst = false,
  }) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFirst ? AppTheme.greenLight : AppTheme.border,
              width: isFirst ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: child,
          ),
        ),
        // Remove button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
        // "Cover" label for first image
        if (isFirst)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.greenLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Cover', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }
}
