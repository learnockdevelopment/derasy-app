import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/store_models.dart';
import '../../../services/store_service.dart';
import '../../../widgets/safe_network_image.dart';
import '../../../widgets/shimmer_loading.dart';

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({Key? key}) : super(key: key);

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  Product? _product;
  bool _isLoading = false;
  int _quantity = 1;
  Map<String, String> _selectedSelections = {};
  final PageController _imagePageController = PageController();

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    final productId = args?['productId'] as String?;
    if (productId != null) {
      _loadProduct(productId);
    }
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  String _getCategoryTitle(Category category) {
    final isArabic = Get.locale?.languageCode == 'ar';
    return isArabic ? category.titleAr : category.titleEn;
  }

  Future<void> _loadProduct(String id) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final product = await StoreService.getProduct(id);
      if (mounted) {
        setState(() {
          _product = product;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Get.snackbar(
          'error'.tr,
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFEF4444),
          colorText: Colors.white,
        );
        Get.back();
      }
    }
  }

  Future<void> _addToCart() async {
    if (_product == null) return;

    try {
      print('🛒 [PRODUCT DETAILS] Adding to cart...');
      print('🛒 [PRODUCT DETAILS] Product ID: ${_product!.id}');
      print('🛒 [PRODUCT DETAILS] Quantity: $_quantity');
      print('🛒 [PRODUCT DETAILS] Selections: $_selectedSelections');

      final selections = _selectedSelections.entries
          .map((e) => CartSelection(name: e.key, value: e.value))
          .toList();

      final cart = await StoreService.addToCart(
        productId: _product!.id,
        quantity: _quantity,
        selections: selections,
      );

      print('🛒 [PRODUCT DETAILS] ✅ Add to cart response:');
      print('🛒 [PRODUCT DETAILS] Cart Items Count: ${cart.items.length}');
      print('🛒 [PRODUCT DETAILS] Cart Total: ${cart.total}');
      print('🛒 [PRODUCT DETAILS] Cart Subtotal: ${cart.subtotal}');

      Get.snackbar(
        'success'.tr,
        'add_to_cart'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.blue1,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      
      // Navigate to cart after successful add
      await Future.delayed(const Duration(milliseconds: 500));
      Get.toNamed(AppRoutes.storeCart);
    } catch (e) {
      print('🛒 [PRODUCT DETAILS] ❌ Error adding to cart: $e');
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        appBar: AppBar(
          backgroundColor: AppColors.blue1,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
            onPressed: () => Get.back(),
          ),
        ),
        body: _buildShimmerLoading(),
      );
    }

    if (_product == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        appBar: AppBar(
          backgroundColor: AppColors.blue1,
          elevation: 0,
          title: Text(
            'product_details'.tr,
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
        body: Center(
          child: Text('product_not_found'.tr),
        ),
      );
    }

    // schoolId is optional for pricing, can be null
    final finalPrice = _product!.getFinalPrice(null);
    final hasDiscount = _product!.discount != null &&
        (_product!.discount!.global != null && _product!.discount!.global! > 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: AppColors.blue1,
        elevation: 0,
        title: Text(
          _product?.titleAr ?? 'product_details'.tr,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_rounded, color: Colors.white),
            onPressed: () => Get.toNamed(AppRoutes.storeCart),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Images
            if (_product!.images.isNotEmpty)
              SizedBox(
                height: 200.h,
                child: PageView.builder(
                  controller: _imagePageController,
                  itemCount: _product!.images.length,
                  itemBuilder: (context, index) {
                    return SafeNetworkImage(
                      imageUrl: _product!.images[index],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        color: const Color(0xFFF3F4F6),
                        child: Icon(Icons.image_rounded, size: 60.sp, color: const Color(0xFF9CA3AF)),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 200.h,
                color: const Color(0xFFF3F4F6),
                child: Icon(Icons.image_rounded, size: 60.sp, color: const Color(0xFF9CA3AF)),
              ),

            // Product Info
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _product!.titleAr,
                              style: AppFonts.h2.copyWith(
                                color: const Color(0xFF1F2937),
                                fontWeight: FontWeight.bold,
                                fontSize: AppFonts.size16,
                              ),
                            ),
                            if (_product!.category != null) ...[
                              SizedBox(height: 8.h),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  color: AppColors.blue1.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  _getCategoryTitle(_product!.category!),
                                  style: AppFonts.bodySmall.copyWith(
                                    color: AppColors.blue1,
                                    fontSize: AppFonts.size12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (hasDiscount)
                            Text(
                              '${_product!.price.toStringAsFixed(0)} ${'egp'.tr}',
                              style: AppFonts.bodyMedium.copyWith(
                                color: const Color(0xFF9CA3AF),
                                fontSize: AppFonts.size14,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            '${finalPrice.toStringAsFixed(0)} ${'egp'.tr}',
                            style: AppFonts.h2.copyWith(
                              color: AppColors.blue1,
                              fontWeight: FontWeight.bold,
                              fontSize: AppFonts.size18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 20.h),

                  // Stock Status
                  Row(
                    children: [
                      Icon(
                        _product!.stock > 0 ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: _product!.stock > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        _product!.stock > 0
                            ? '${'in_stock'.tr} (${_product!.stock})'
                            : 'out_of_stock'.tr,
                        style: AppFonts.bodyMedium.copyWith(
                          color: _product!.stock > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          fontSize: AppFonts.size14,
                        ),
                      ),
                    ],
                  ),

                  // Selections
                  if (_product!.selections.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    ..._product!.selections.map((selection) {
                      return _buildSelectionWidget(selection);
                    }),
                  ],

                  // Quantity
                  SizedBox(height: 24.h),
                  Row(
                    children: [
                      Text(
                        '${'quantity'.tr}:',
                        style: AppFonts.bodyLarge.copyWith(
                          color: const Color(0xFF1F2937),
                          fontWeight: FontWeight.bold,
                          fontSize: AppFonts.size16,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded),
                            onPressed: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                            color: AppColors.blue1,
                          ),
                          Container(
                            width: 50.w,
                            alignment: Alignment.center,
                            child: Text(
                              _quantity.toString(),
                              style: AppFonts.bodyLarge.copyWith(
                                fontSize: AppFonts.size18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            onPressed: _quantity < _product!.stock
                                ? () => setState(() => _quantity++)
                                : null,
                            color: AppColors.blue1,
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Add to Cart Button
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _product!.stock > 0 ? _addToCart : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue1,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        _product!.stock > 0 ? 'add_to_cart'.tr : 'out_of_stock'.tr,
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

            // Description
            if (_product!.descriptionAr != null && _product!.descriptionAr!.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Container(
                color: Colors.white,
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'description'.tr,
                      style: AppFonts.h3.copyWith(
                        color: const Color(0xFF1F2937),
                        fontWeight: FontWeight.bold,
                        fontSize: AppFonts.size18,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      _product!.descriptionAr!,
                      style: AppFonts.bodyMedium.copyWith(
                        color: const Color(0xFF6B7280),
                        fontSize: AppFonts.size14,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Specifications
            if (_product!.specificationsAr != null && _product!.specificationsAr!.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Container(
                color: Colors.white,
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'specifications'.tr,
                      style: AppFonts.h3.copyWith(
                        color: const Color(0xFF1F2937),
                        fontWeight: FontWeight.bold,
                        fontSize: AppFonts.size18,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      _product!.specificationsAr!,
                      style: AppFonts.bodyMedium.copyWith(
                        color: const Color(0xFF6B7280),
                        fontSize: AppFonts.size14,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionWidget(ProductSelection selection) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          selection.nameAr,
          style: AppFonts.bodyMedium.copyWith(
            color: const Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
            fontSize: AppFonts.size14,
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: selection.options.map((option) {
            final isSelected = _selectedSelections[selection.name] == option.value;
            return ChoiceChip(
              label: Text(option.valueAr),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSelections[selection.name] = option.value;
                  } else {
                    _selectedSelections.remove(selection.name);
                  }
                });
              },
              selectedColor: AppColors.blue1,
              labelStyle: AppFonts.bodySmall.copyWith(
                color: isSelected ? Colors.white : const Color(0xFF1F2937),
                fontSize: AppFonts.size12,
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Image Shimmer
          ShimmerLoading(
            child: Container(
              height: 300.h,
              width: double.infinity,
              color: Colors.grey[300],
            ),
          ),
          SizedBox(height: 20.h),
          // Info Cards Shimmer
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              children: [
                ShimmerLoading(
                  child: Container(
                    height: 200.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                ShimmerLoading(
                  child: Container(
                    height: 150.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                ShimmerLoading(
                  child: Container(
                    height: 150.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(16.r),
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
}


