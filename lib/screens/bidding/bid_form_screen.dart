import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../models/bid_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../utils/validators.dart';

class BidFormScreen extends StatefulWidget {
  final ProductModel product;
  final String buyerId;

  const BidFormScreen(
      {super.key, required this.product, required this.buyerId});

  @override
  State<BidFormScreen> createState() => _BidFormScreenState();
}

class _BidFormScreenState extends State<BidFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _db = DatabaseService();
  final _auth = AuthService();
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await _auth.getCurrentUserModel();
      final seller = await _db.getUser(widget.product.sellerId);
      final bid = BidModel(
        id: '',
        productId: widget.product.id,
        productName: widget.product.productName,
        buyerId: widget.buyerId,
        buyerName: user?.name ?? '',
        buyerPhone: user?.phone ?? '',
        sellerId: widget.product.sellerId,
        sellerName: seller?.name ?? widget.product.sellerName,
        sellerPhone: seller?.phone ?? '',
        quantity: double.parse(_qtyCtrl.text),
        offeredPrice: double.parse(_priceCtrl.text.replaceAll(',', '')),
        notes:
            _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      );
      await _db.addBid(bid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bid placed successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Place a Bid')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ResponsiveWrapper(
          maxWidth: 700,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppTheme.greenSurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child:
                            const Icon(Icons.eco, color: AppTheme.greenLight),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.productName,
                              style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${widget.product.quantity} ${widget.product.quantityUnit} • ${widget.product.district}',
                              style: TextStyle(
                                  color: AppTheme.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                CustomTextField(
                  label: 'Quantity Requested',
                  hint: 'e.g. 50',
                  controller: _qtyCtrl,
                  validator: Validators.quantity,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  label: 'Your Proposed Price (UGX)',
                  hint: 'e.g. 45000',
                  controller: _priceCtrl,
                  validator: Validators.price,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  label: 'Notes (optional)',
                  hint: 'Any additional details...',
                  controller: _notesCtrl,
                  maxLines: 3,
                ),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppTheme.textMuted, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your bid will be sent to the registry for review. The registry will coordinate between you and the farmer.',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                CustomButton(
                  text: 'Submit Bid',
                  onPressed: _submit,
                  isLoading: _loading,
                  icon: Icons.gavel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
