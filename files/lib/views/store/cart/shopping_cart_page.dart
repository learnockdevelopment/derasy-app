import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/store_models.dart';
import '../../../models/wallet_models.dart';
import '../../../services/store_service.dart';
import '../../../services/wallet_service.dart';
import '../../../widgets/safe_network_image.dart';

class ShoppingCartPage extends StatefulWidget {
  const ShoppingCartPage({Key? key}) : super(key: key);

  @override
  State<ShoppingCartPage> createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends State<ShoppingCartPage> {
  ShoppingCart? _cart;
  Wallet? _wallet;
  bool _isLoading = false;
  bool _isLoadingWallet = false;

  @override
  void initState() {
    super.initState();
    _loadCart();
    _loadWallet();
  }

  Future<void> _loadCart() async {
    print('🛒 [CART PAGE] ===========================================');
    print('🛒 [CART PAGE] Loading cart...');
    
    setState(() {
      _isLoading = true;
    });

    try {
      final cart = await StoreService.getCart();
      print('🛒 [CART PAGE] ✅ Cart loaded successfully');
      print('🛒 [CART PAGE] Cart items: ${cart.items.length}');
      print('🛒 [CART PAGE] Cart total: ${cart.total}');
      
      if (mounted) {
        setState(() {
          _cart = cart;
          _isLoading = false;
        });
        print('🛒 [CART PAGE] State updated with cart data');
      }
      print('🛒 [CART PAGE] ===========================================');
    } catch (e) {
      print('🛒 [CART PAGE] ❌ Error loading cart: $e');
      print('🛒 [CART PAGE] ===========================================');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (e.toString().contains('Authentication')) {
          Get.snackbar(
            'error'.tr,
            'please_login'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFEF4444),
            colorText: Colors.white,
          );
          Get.back();
        } else {
          // Show error but don't close page
          Get.snackbar(
            'error'.tr,
            e.toString(),
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFEF4444),
            colorText: Colors.white,
          );
        }
      }
    }
  }

  Future<void> _loadWallet() async {
    print('💰 [CART PAGE] Loading wallet...');
     
    setState(() {
      _isLoadingWallet = true;
    });

    try {
      final walletResponse = await WalletService.getWallet();
      print('💰 [CART PAGE] ✅ Wallet loaded successfully');
      print('💰 [CART PAGE] Wallet balance: ${walletResponse.wallet.balance}');
      print('💰 [CART PAGE] Wallet currency: ${walletResponse.wallet.currency}');
      
      if (mounted) {
        setState(() {
          _wallet = walletResponse.wallet;
          _isLoadingWallet = false;
        });
        print('💰 [CART PAGE] State updated with wallet data');
      }
    } catch (e) {
      print('💰 [CART PAGE] ❌ Error loading wallet: $e');
      if (mounted) {
        setState(() {
          _isLoadingWallet = false;
        });
        // Silently fail - wallet is optional
      }
    }
  }

  Future<void> _updateQuantity(CartItem item, int newQuantity) async {
    if (newQuantity <= 0) {
      await _removeItem(item);
      return;
    }

    try {
      await StoreService.updateCartItem(
        productId: item.productId,
        quantity: newQuantity,
        selections: item.selections,
      );
      _loadCart();
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    }
  }

  Future<void> _removeItem(CartItem item) async {
    try {
      await StoreService.removeFromCart(
        productId: item.productId,
        selections: item.selections,
      );
      _loadCart();
      Get.snackbar(
        'success'.tr,
        'item_removed'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primaryBlue,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    }
  }

  void _checkout() {
    if (_cart == null || _cart!.items.isEmpty) return;
    // Navigate to checkout page (to be implemented)
    Get.snackbar(
      'info'.tr,
      'checkout_coming_soon'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primaryBlue,
      colorText: Colors.white,
    );
  }

  Future<void> _checkoutWithWallet() async {
    if (_cart == null || _cart!.items.isEmpty || _wallet == null) return;
    if (_wallet!.balance < _cart!.total) {
      Get.snackbar(
        'error'.tr,
        'insufficient_balance'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
      return;
    }

    Get.snackbar(
      'info'.tr,
      'wallet_checkout_coming_soon'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primaryBlue,
      colorText: Colors.white,
    );
  }

  Widget _buildWalletCard() {
    if (_wallet == null) {
      print('💰 [CART PAGE] _buildWalletCard: Wallet is null, returning empty');
      return const SizedBox.shrink();
    }

    print('💰 [CART PAGE] _buildWalletCard: Building wallet card with balance: ${_wallet!.balance}');

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue,
            AppColors.primaryBlue.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 28.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'wallet_balance'.tr,
                  style: AppFonts.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: AppFonts.size12,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${_wallet!.balance.toStringAsFixed(2)} ${_wallet!.currency}',
                  style: AppFonts.h2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: AppFonts.size20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug prints
    print('🛒 [CART PAGE BUILD] ===========================================');
    print('🛒 [CART PAGE BUILD] _isLoading: $_isLoading');
    print('🛒 [CART PAGE BUILD] _cart: ${_cart != null ? "NOT NULL" : "NULL"}');
    if (_cart != null) {
      print('🛒 [CART PAGE BUILD] _cart items count: ${_cart!.items.length}');
      print('🛒 [CART PAGE BUILD] _cart total: ${_cart!.total}');
      print('🛒 [CART PAGE BUILD] _cart subtotal: ${_cart!.subtotal}');
    }
    print('🛒 [CART PAGE BUILD] _wallet: ${_wallet != null ? "NOT NULL" : "NULL"}');
    if (_wallet != null) {
      print('🛒 [CART PAGE BUILD] _wallet balance: ${_wallet!.balance}');
      print('🛒 [CART PAGE BUILD] _wallet currency: ${_wallet!.currency}');
    }
    print('🛒 [CART PAGE BUILD] ===========================================');
    
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: Text(
          'shopping_cart'.tr,
          style: AppFonts.h2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
          onPressed: () => Get.back(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cart == null || _cart!.items.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.all(16.w),
                        itemCount: _cart!.items.length,
                        itemBuilder: (context, index) {
                          print('🛒 [CART PAGE] Building cart item $index: ${_cart!.items[index].product?.titleAr ?? "NO TITLE"}');
                          return _buildCartItem(_cart!.items[index]);
                        },
                      ),
                    ),
                    // Wallet Section
                    if (_wallet != null) ...[
                      Builder(
                        builder: (_) {
                          print('💰 [CART PAGE] Rendering wallet card with balance: ${_wallet!.balance}');
                          return _buildWalletCard();
                        },
                      ),
                    ],
                    // Checkout Section 
                    Container(
                      color: Colors.white,
                      padding: EdgeInsets.all(20.w),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'subtotal'.tr,
                                style: AppFonts.bodyLarge.copyWith(
                                  color: const Color(0xFF6B7280),
                                  fontSize: AppFonts.size16,
                                ),
                              ),
                              Text(
                                '${_cart!.subtotal.toStringAsFixed(0)} ${'egp'.tr}',
                                style: AppFonts.bodyLarge.copyWith(
                                  color: const Color(0xFF1F2937),
                                  fontWeight: FontWeight.bold,
                                  fontSize: AppFonts.size16,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'total'.tr,
                                style: AppFonts.h3.copyWith(
                                  color: const Color(0xFF1F2937),
                                  fontWeight: FontWeight.bold,
                                  fontSize: AppFonts.size18,
                                ),
                              ),
                              Text(
                                '${_cart!.total.toStringAsFixed(0)} ${'egp'.tr}',
                                style: AppFonts.h2.copyWith(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: AppFonts.size20,
                                ),
                              ),
                            ],
                          ),
                          if (_wallet != null) ...[
                            SizedBox(height: 12.h),
                            Divider(),
                            SizedBox(height: 12.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.account_balance_wallet_rounded, 
                                        color: AppColors.primaryBlue, size: 20.sp),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'wallet_balance'.tr,
                                      style: AppFonts.bodyMedium.copyWith(
                                        color: const Color(0xFF6B7280),
                                        fontSize: AppFonts.size14,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${_wallet!.balance.toStringAsFixed(2)} ${_wallet!.currency}',
                                  style: AppFonts.bodyLarge.copyWith(
                                    color: _wallet!.balance >= _cart!.total
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444),
                                    fontWeight: FontWeight.bold,
                                    fontSize: AppFonts.size16,
                                  ),
                                ),
                              ],
                            ),
                            if (_wallet!.balance < _cart!.total) ...[
                              SizedBox(height: 8.h),
                              Text(
                                'insufficient_balance'.tr,
                                style: AppFonts.bodySmall.copyWith(
                                  color: const Color(0xFFEF4444),
                                  fontSize: AppFonts.size12,
                                ),
                              ),
                            ],
                          ],
                          SizedBox(height: 20.h),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _wallet != null && _wallet!.balance >= _cart!.total
                                  ? _checkoutWithWallet
                                  : _checkout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: Text(
                                _wallet != null && _wallet!.balance >= _cart!.total
                                    ? 'buy_with_wallet'.tr
                                    : 'checkout'.tr,
                                style: AppFonts.bodyLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: AppFonts.size16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.horizontal(left: Radius.circular(16.r)),
            child: SafeNetworkImage(
              imageUrl: item.product?.images.isNotEmpty == true ? item.product!.images.first : '',
              width: 100.w,
              height: 100.h,
              fit: BoxFit.cover,
              errorWidget: Container(
                width: 100.w,
                height: 100.h,
                color: const Color(0xFFF3F4F6),
                child: Icon(Icons.image_rounded, size: 30.sp, color: const Color(0xFF9CA3AF)),
              ),
            ),
          ),
          // Product Info
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product?.titleAr ?? 'product'.tr,
                    style: AppFonts.bodyMedium.copyWith(
                      color: const Color(0xFF1F2937),
                      fontWeight: FontWeight.bold,
                      fontSize: AppFonts.size14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${item.price.toStringAsFixed(0)} ${'egp'.tr}',
                    style: AppFonts.bodySmall.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: AppFonts.size12,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                        onPressed: () => _updateQuantity(item, item.quantity - 1),
                        color: AppColors.primaryBlue,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        item.quantity.toString(),
                        style: AppFonts.bodyMedium.copyWith(
                          fontSize: AppFonts.size14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                        onPressed: () => _updateQuantity(item, item.quantity + 1),
                        color: AppColors.primaryBlue,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        onPressed: () => _removeItem(item),
                        color: const Color(0xFFEF4444),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80.sp, color: const Color(0xFF9CA3AF)),
          SizedBox(height: 16.h),
          Text(
            'cart_empty'.tr,
            style: AppFonts.bodyLarge.copyWith(
              color: const Color(0xFF6B7280),
              fontSize: AppFonts.size16,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () => Get.toNamed(AppRoutes.storeProducts),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
            ),
            child: Text(
              'continue_shopping'.tr,
              style: AppFonts.bodyMedium.copyWith(
                color: Colors.white,
                fontSize: AppFonts.size14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

