import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/controllers/app_config_controller.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/routes/app_routes.dart';
import '../../models/store_models.dart';
import '../../services/store_service.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _isLoading = true;
  StoreCart? _cart;
  bool _isUpdating = false;

  // Checkout Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _governorateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentMethod = 'wallet';
  String _deliveryMethod = 'pickup';

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _isLoading = true);
    try {
      final cart = await StoreService.getCart();
      if (mounted) {
        setState(() {
          _cart = cart;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateQuantity(String cartItemId, int newQty) async {
    if (newQty < 1) return;
    setState(() => _isUpdating = true);
    try {
      final updatedCart = await StoreService.updateCartItemQuantity(cartItemId, newQty);
      if (mounted) {
        setState(() {
          _cart = updatedCart;
          _isUpdating = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _deleteItem(String cartItemId) async {
    setState(() => _isUpdating = true);
    try {
      final updatedCart = await StoreService.removeCartItem(cartItemId: cartItemId);
      if (mounted) {
        setState(() {
          _cart = updatedCart;
          _isUpdating = false;
        });
      }
      Get.snackbar(
        'item_removed'.tr.isNotEmpty ? 'item_removed'.tr : 'Item Removed',
        'item_removed_success'.tr.isNotEmpty ? 'item_removed_success'.tr : 'Item was removed from your cart.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
      );
    } catch (e) {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _clearCart() async {
    setState(() => _isUpdating = true);
    try {
      final updatedCart = await StoreService.removeCartItem(clearAll: true);
      if (mounted) {
        setState(() {
          _cart = updatedCart;
          _isUpdating = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showCheckoutSheet() {
    final isDark = AppConfigController.to.isDarkMode;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final textSecondary = isDark ? Colors.grey.shade400 : AppColors.textSecondary;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: Responsive.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(Responsive.r(30))),
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'checkout'.tr.isNotEmpty ? 'checkout'.tr : 'Secure Checkout',
                      style: AppFonts.AlmaraiBold18.copyWith(color: textColor),
                    ),
                    const SizedBox(height: 18),

                    // Delivery Method Options
                    Text(
                      'delivery_method'.tr,
                      style: AppFonts.AlmaraiBold12.copyWith(color: textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: Center(child: Text('in_person'.tr)),
                            selected: _deliveryMethod == 'pickup',
                            selectedColor: AppColors.salesAccent.withOpacity(0.2),
                            onSelected: (val) {
                              if (val) setSheetState(() => _deliveryMethod = 'pickup');
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: Center(child: Text('home_delivery'.tr)),
                            selected: _deliveryMethod == 'delivery',
                            selectedColor: AppColors.salesAccent.withOpacity(0.2),
                            onSelected: (val) {
                              if (val) setSheetState(() => _deliveryMethod = 'delivery');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Shipping Address Inputs (only visible if home delivery selected)
                    if (_deliveryMethod == 'delivery') ...[
                      Text(
                        'delivery_details'.tr.isNotEmpty ? 'delivery_details'.tr : 'Delivery Details',
                        style: AppFonts.AlmaraiBold12.copyWith(color: textSecondary),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'full_name'.tr.isNotEmpty ? 'full_name'.tr : 'Full Name',
                          labelStyle: TextStyle(color: textSecondary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(Responsive.r(14))),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'shipping_address'.tr.isNotEmpty ? 'shipping_address'.tr : 'Shipping Address',
                          labelStyle: TextStyle(color: textSecondary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(Responsive.r(14))),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(
                                labelText: 'city'.tr.isNotEmpty ? 'city'.tr : 'City',
                                labelStyle: TextStyle(color: textSecondary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(Responsive.r(14))),
                              ),
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _governorateController,
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(
                                labelText: 'governorate'.tr.isNotEmpty ? 'governorate'.tr : 'Governorate',
                                labelStyle: TextStyle(color: textSecondary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(Responsive.r(14))),
                              ),
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _postalCodeController,
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(
                                labelText: 'postal_code'.tr.isNotEmpty ? 'postal_code'.tr : 'Postal Code',
                                labelStyle: TextStyle(color: textSecondary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(Responsive.r(14))),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              style: TextStyle(color: textColor),
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'phone'.tr.isNotEmpty ? 'phone'.tr : 'Phone Number',
                                labelStyle: TextStyle(color: textSecondary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(Responsive.r(14))),
                              ),
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'delivery_notes_hint'.tr.isNotEmpty ? 'delivery_notes_hint'.tr : 'Special delivery notes (optional)...',
                          hintStyle: TextStyle(color: textSecondary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(Responsive.r(14))),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Payment Method Options
                    Text(
                      'payment_method'.tr.isNotEmpty ? 'payment_method'.tr : 'Payment Method',
                      style: AppFonts.AlmaraiBold12.copyWith(color: textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: Center(child: Text('wallet'.tr.isNotEmpty ? 'wallet'.tr : 'Wallet Balance')),
                            selected: _paymentMethod == 'wallet',
                            selectedColor: AppColors.salesAccent.withOpacity(0.2),
                            onSelected: (val) {
                              if (val) setSheetState(() => _paymentMethod = 'wallet');
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: Center(child: Text('cod'.tr.isNotEmpty ? 'cod'.tr : 'Cash on Delivery')),
                            selected: _paymentMethod == 'cod',
                            selectedColor: AppColors.salesAccent.withOpacity(0.2),
                            onSelected: (val) {
                              if (val) setSheetState(() => _paymentMethod = 'cod');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Order Summary Row
                    if (_deliveryMethod == 'delivery') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'subtotal'.tr,
                            style: AppFonts.AlmaraiBold12.copyWith(color: textSecondary),
                          ),
                          Text(
                            '${_cart?.subtotal.toInt() ?? 0} EGP',
                            style: AppFonts.AlmaraiBold12.copyWith(color: textColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'delivery_fee'.tr,
                            style: AppFonts.AlmaraiBold12.copyWith(color: textSecondary),
                          ),
                          Text(
                            '50 EGP',
                            style: AppFonts.AlmaraiBold12.copyWith(color: textColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'total_amount'.tr.isNotEmpty ? 'total_amount'.tr : 'Total Amount',
                          style: AppFonts.AlmaraiBold14.copyWith(color: textColor),
                        ),
                        Text(
                          '${(_cart?.subtotal.toInt() ?? 0) + (_deliveryMethod == 'delivery' ? 50 : 0)} EGP',
                          style: AppFonts.AlmaraiBold18.copyWith(color: AppColors.salesAccent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Get.back(),
                            style: OutlinedButton.styleFrom(
                              padding: Responsive.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.r(16))),
                            ),
                            child: Text('cancel'.tr),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_deliveryMethod == 'pickup' || (_formKey.currentState?.validate() ?? false)) {
                                Get.back(); // Dismiss sheet
                                _submitCheckout();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.salesAccent,
                              padding: Responsive.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.r(16))),
                            ),
                            child: Text(
                              'place_order'.tr.isNotEmpty ? 'place_order'.tr : 'Place Order',
                              style: AppFonts.AlmaraiBold12.copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _submitCheckout() async {
    setState(() => _isLoading = true);
    try {
      final shippingAddress = StoreShippingAddress(
        name: _nameController.text,
        address: _deliveryMethod == 'delivery' ? _addressController.text : 'Store Lounge Pickup',
        city: _deliveryMethod == 'delivery' ? _cityController.text : 'Cairo',
        governorate: _deliveryMethod == 'delivery' ? _governorateController.text : 'Cairo',
        postalCode: _deliveryMethod == 'delivery' ? _postalCodeController.text : '',
        phone: _phoneController.text,
      );

      final orderId = await StoreService.createOrder(
        deliveryMethod: _deliveryMethod,
        shippingAddress: shippingAddress,
        items: _cart?.items ?? [],
        notes: _notesController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (orderId != null) {
        // Success Dialog
        Get.dialog(
          AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.r(24))),
            backgroundColor: AppConfigController.to.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            title: Column(
              children: [
                const Icon(IconlyBold.shield_done, color: Colors.green, size: 54),
                const SizedBox(height: 14),
                Text(
                  'order_success'.tr.isNotEmpty ? 'order_success'.tr : 'Order Placed!',
                  style: AppFonts.AlmaraiBold18,
                ),
              ],
            ),
            content: Text(
              'order_success_desc'.tr.isNotEmpty 
                  ? 'order_success_desc'.tr 
                  : 'Your order was successfully placed and wallet balance deducted.',
              textAlign: TextAlign.center,
              style: AppFonts.AlmaraiRegular12.copyWith(color: AppColors.textSecondary),
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Get.back(); // Dismiss dialog
                    Get.offNamed(AppRoutes.teacherHome); // Back to home
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.salesAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.r(12))),
                  ),
                  child: Text('ok'.tr, style: const TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.r(24))),
          backgroundColor: AppConfigController.to.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          title: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 54),
              const SizedBox(height: 14),
              Text(
                'error'.tr.isNotEmpty ? 'error'.tr : 'Checkout Failed',
                style: AppFonts.AlmaraiBold18,
              ),
            ],
          ),
          content: Text(
            e.toString().replaceAll('Exception:', '').trim(),
            textAlign: TextAlign.center,
            style: AppFonts.AlmaraiRegular12.copyWith(color: AppColors.textSecondary),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.r(12))),
                ),
                child: Text('ok'.tr, style: const TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppConfigController.to.isDarkMode;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final textSecondary = isDark ? Colors.grey.shade400 : AppColors.textSecondary;
    final borderColor = isDark ? Colors.white12 : AppColors.grey300;

    final cartItems = _cart?.items ?? [];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Responsive.isRTL ? IconlyLight.arrow_right : IconlyLight.arrow_left,
            color: textColor,
          ),
        ),
        title: Text(
          'my_cart'.tr.isNotEmpty ? 'my_cart'.tr : 'My Cart',
          style: AppFonts.AlmaraiBold18.copyWith(color: textColor),
        ),
        centerTitle: true,
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              onPressed: _clearCart,
              icon: const Icon(IconlyLight.delete, color: Colors.red),
            ),
          SizedBox(width: Responsive.w(8)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.salesAccent))
          : cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(IconlyLight.buy, size: 54, color: textSecondary),
                      const SizedBox(height: 14),
                      Text(
                        'cart_is_empty'.tr.isNotEmpty ? 'cart_is_empty'.tr : 'Your Cart is Empty',
                        style: AppFonts.AlmaraiBold14.copyWith(color: textColor),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: () => Get.back(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.salesAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.r(12))),
                        ),
                        child: Text(
                          'explore_store'.tr.isNotEmpty ? 'explore_store'.tr : 'Explore Store',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    ListView.separated(
                      padding: Responsive.symmetric(horizontal: 24, vertical: 16),
                      physics: const BouncingScrollPhysics(),
                      itemCount: cartItems.length,
                      separatorBuilder: (c, i) => SizedBox(height: Responsive.h(14)),
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        final pTitle = item.product != null
                            ? (Responsive.isRTL ? item.product!.titleAr : item.product!.titleEn)
                            : 'Unknown Item';
                        final pImage = item.product?.images.isNotEmpty == true
                            ? item.product!.images.first
                            : 'https://images.unsplash.com/photo-1544816155-12df9643f363?w=500';

                        return Container(
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(Responsive.r(24)),
                            border: Border.all(color: borderColor, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.01),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: Responsive.all(14),
                          child: Row(
                            children: [
                              // Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(Responsive.r(16)),
                                child: SizedBox(
                                  width: Responsive.w(70),
                                  height: Responsive.w(70),
                                  child: Image.network(
                                    pImage,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(color: Colors.grey.shade300),
                                  ),
                                ),
                              ),
                              SizedBox(width: Responsive.w(14)),

                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppFonts.AlmaraiBold12.copyWith(color: textColor),
                                    ),
                                    const SizedBox(height: 4),
                                    if (item.selections.isNotEmpty)
                                      Text(
                                        '${item.selections.first.name}: ${item.selections.first.value}',
                                        style: TextStyle(color: textSecondary, fontSize: 10),
                                      ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${item.price.toInt()} EGP',
                                      style: AppFonts.AlmaraiBold12.copyWith(color: AppColors.salesAccent),
                                    ),
                                  ],
                                ),
                              ),

                              // Quantity Controls / Actions
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  IconButton(
                                    onPressed: () => _deleteItem(item.id),
                                    icon: const Icon(IconlyLight.delete, size: 18, color: Colors.redAccent),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius: BorderRadius.circular(Responsive.r(12)),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: _isUpdating ? null : () => _updateQuantity(item.id, item.quantity - 1),
                                          child: const Padding(
                                            padding: EdgeInsets.all(6.0),
                                            child: const Icon(Icons.remove, size: 12),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          child: Text(
                                            item.quantity.toString(),
                                            style: AppFonts.AlmaraiBold12,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: _isUpdating ? null : () => _updateQuantity(item.id, item.quantity + 1),
                                          child: const Padding(
                                            padding: EdgeInsets.all(6.0),
                                            child: const Icon(Icons.add, size: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    if (_isUpdating)
                      Container(
                        color: Colors.black12,
                        child: const Center(child: CircularProgressIndicator(color: AppColors.salesAccent)),
                      ),
                  ],
                ),
      bottomSheet: cartItems.isEmpty
          ? null
          : Container(
              padding: Responsive.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'subtotal'.tr.isNotEmpty ? 'subtotal'.tr : 'Subtotal',
                          style: AppFonts.AlmaraiBold12.copyWith(color: textSecondary),
                        ),
                        Text(
                          '${_cart?.subtotal.toInt() ?? 0} EGP',
                          style: AppFonts.AlmaraiBold14.copyWith(color: textColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'total'.tr.isNotEmpty ? 'total'.tr : 'Total Amount',
                          style: AppFonts.AlmaraiBold14.copyWith(color: textColor),
                        ),
                        Text(
                          '${_cart?.total.toInt() ?? 0} EGP',
                          style: AppFonts.AlmaraiBold18.copyWith(color: AppColors.salesAccent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isUpdating ? null : _showCheckoutSheet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.salesAccent,
                          padding: Responsive.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.r(16))),
                        ),
                        child: Text(
                          'proceed_to_checkout'.tr.isNotEmpty ? 'proceed_to_checkout'.tr : 'Proceed to Checkout',
                          style: AppFonts.AlmaraiBold14.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
