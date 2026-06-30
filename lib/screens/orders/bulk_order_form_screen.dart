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
  String _orderType = 'Produce';
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
    if (_loading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    final itemName = _itemCtrl.text.trim();
    final quantity = double.tryParse(_qtyCtrl.text.trim().replaceAll(',', ''));
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid quantity greater than 0')),
      );
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
        itemName: itemName,
        quantity: quantity,
        quantityUnit: _unit,
        notes: _notesCtrl.text.trim(),
        status: 'Pending',
      );

      final docId = await _db.addBulkOrder(order);

      try {
        await _db.sendBulkOrderNotification(
          title: 'New Bulk Order',
          body: '${order.quantity} $_unit of $itemName',
          relatedId: docId,
          buyerId: user.id,
        );
      } catch (e) {
        debugPrint('Bulk order notification failed: $e');
      }

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Order Submitted Successfully'),
            content: const Text(
              'Your bulk order has been securely sent to the Registry. Our distributor network will process it shortly.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              )
            ],
          ),
        );
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
        title: Text(
          'Place Bulk / Special Order',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
        ),
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ResponsiveWrapper(
          maxWidth: 1040,
          child: Form(
            key: _formKey,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 900;
                final primaryPanel = _buildPanel(
                  title: 'Order details',
                  subtitle:
                      'Choose the request type, category, and the exact item name.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Type',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _orderType = 'Produce';
                                _category = null;
                              }),
                              child: _typeTile(
                                label: 'Produce',
                                selected: isProduce,
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
                              child: _typeTile(
                                label: 'Farm Input',
                                selected: !isProduce,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      CustomDropdown(
                        label: 'Category',
                        value: _category,
                        items: categories,
                        validator: (v) =>
                            v == null ? 'Choose a category' : null,
                        onChanged: (v) => setState(() => _category = v),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Specific Item Name',
                        hint: isProduce
                            ? 'e.g. Red Beauty Groundnuts'
                            : 'e.g. NPK 17-17-17 Fertilizer',
                        controller: _itemCtrl,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Item name required'
                            : null,
                      ),
                    ],
                  ),
                );

                final secondaryPanel = _buildPanel(
                  title: 'Quantity and notes',
                  subtitle:
                      'Use a precise quantity and add any constraints the registry should know about.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              validator: (v) {
                                final text = v?.trim() ?? '';
                                if (text.isEmpty) return 'Quantity required';
                                final parsed = double.tryParse(
                                  text.replaceAll(',', ''),
                                );
                                if (parsed == null || parsed <= 0) {
                                  return 'Enter a valid quantity';
                                }
                                return null;
                              },
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
                            'Delivery, packaging, preferred brands, or other instructions.',
                        controller: _notesCtrl,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Submit Order Request',
                        icon: Icons.send_rounded,
                        onPressed: _submitOrder,
                        isLoading: _loading,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppTheme.border, width: 0.5),
                        ),
                        child: Text(
                          'Orders are saved immediately. Notification delivery is handled separately so a temporary alert failure will not block the order.',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIntroCard(),
                    const SizedBox(height: 24),
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: primaryPanel),
                          const SizedBox(width: 20),
                          Expanded(child: secondaryPanel),
                        ],
                      )
                    else ...[
                      primaryPanel,
                      const SizedBox(height: 20),
                      secondaryPanel,
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.greenSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.assignment_turned_in_outlined,
              color: AppTheme.green,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registry Order Form',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Create a clean bulk request for produce or farm inputs. The order is submitted once, then notifications are handled in the background so the form stays stable.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _typeTile({required String label, required bool selected}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: selected ? AppTheme.greenSurface : AppTheme.surfaceLight,
        border: Border.all(color: selected ? AppTheme.green : AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.greenDark : AppTheme.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
