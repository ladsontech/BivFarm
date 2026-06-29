import 'package:flutter/material.dart';
import '../../models/bulk_order_model.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/responsive_wrapper.dart';

class BulkOrderFormScreen extends StatefulWidget {
  final String userId;
  const BulkOrderFormScreen({super.key, required this.userId});

  @override
  State<BulkOrderFormScreen> createState() => _BulkOrderFormScreenState();
}

class _BulkOrderFormScreenState extends State<BulkOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService();

  bool _loading = false;
  String _orderType = 'Produce'; // Produce or Input
  String? _category;

  final _itemCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  String _unit = 'Kg';
  final _notesCtrl = TextEditingController();

  final List<String> _produceCategories = [
    'Produce',
    'Poultry',
    'Livestock',
    'Fruits & Vegetables',
    'Other'
  ];

  final List<String> _inputCategories = [
    'Fertilizers',
    'Seeds',
    'Pesticides & Insecticides',
    'Farm Equipment',
    'Other'
  ];

  @override
  void dispose() {
    _itemCtrl.dispose();
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() => _loading = true);

    try {
      final user = await _db.getUser(widget.userId);
      if (user == null) throw Exception('User not found');

      final order = BulkOrderModel(
        id: '',
        buyerId: user.id,
        buyerName: user.name,
        buyerPhone: user.phone,
        orderType: _orderType,
        category: _category!,
        itemName: _itemCtrl.text.trim(),
        quantity: double.tryParse(_qtyCtrl.text.trim()) ?? 0,
        quantityUnit: _unit,
        notes: _notesCtrl.text.trim(),
        status: 'Pending',
      );

      final docId = await _db.addBulkOrder(order);

      // Send notifications for Bulk Order
      await _db.sendBulkOrderNotification(
        title: "New Bulk Order",
        body: "${order.quantity} ${_unit} of ${_itemCtrl.text.trim()}",
        relatedId: docId,
        buyerId: user.id,
      );

      if (mounted) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
                  title: const Text('Order Submitted Successfully'),
                  content: const Text(
                      'Your bulk order has been securely sent to the Registry. Our distributor network will process it shortly.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      child: const Text('OK'),
                    )
                  ],
                ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProduce = _orderType == 'Produce';
    final categories = isProduce ? _produceCategories : _inputCategories;

    return Scaffold(
      appBar: AppBar(
        title: Text('Place Bulk / Special Order',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 18)),
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ResponsiveWrapper(
          maxWidth: 600,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.greenSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.assignment_turned_in,
                          color: AppTheme.green, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Registry Order Form',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Orders pass securely to our administrators to negotiate and fulfill from large distributor channels or farmer cooperatives.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Order Type',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _orderType = 'Produce';
                          _category = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isProduce
                                ? AppTheme.greenSurface
                                : AppTheme.surfaceLight,
                            border: Border.all(
                                color: isProduce
                                    ? AppTheme.green
                                    : AppTheme.border),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'Produce',
                              style: TextStyle(
                                color: isProduce
                                    ? AppTheme.greenDark
                                    : AppTheme.textSecondary,
                                fontWeight: isProduce
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _orderType = 'Input';
                          _category = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: !isProduce
                                ? AppTheme.greenSurface
                                : AppTheme.surfaceLight,
                            border: Border.all(
                                color: !isProduce
                                    ? AppTheme.green
                                    : AppTheme.border),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'Farm Input',
                              style: TextStyle(
                                color: !isProduce
                                    ? AppTheme.greenDark
                                    : AppTheme.textSecondary,
                                fontWeight: !isProduce
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                CustomDropdown(
                  label: 'Category',
                  value: _category,
                  items: categories,
                  onChanged: (v) => setState(() => _category = v),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Specific Item Name',
                  hint: isProduce
                      ? 'e.g. Red Beauty Groundnuts'
                      : 'e.g. NPK 17-17-17 Fertilizer',
                  controller: _itemCtrl,
                  validator: (v) => v!.isEmpty ? 'Item name required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        label: 'Quantity',
                        hint: '100',
                        controller: _qtyCtrl,
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: CustomDropdown(
                        label: 'Unit',
                        value: _unit,
                        items: const [
                          'Kg',
                          'Tonnes',
                          'Bags',
                          'Litres',
                          'Pieces'
                        ],
                        onChanged: (v) => setState(() => _unit = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Additional Notes / Requirements (Optional)',
                  hint:
                      'Any specific instructions for delivery, packaging, or brand preferences?',
                  controller: _notesCtrl,
                  maxLines: 4,
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Submit Order Request',
                  onPressed: _submitOrder,
                  isLoading: _loading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
