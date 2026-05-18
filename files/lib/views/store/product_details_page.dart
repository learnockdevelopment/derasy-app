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

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({Key? key}) : super(key: key);

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late StoreProduct _product;
  int _quantity = 1;
  String _selectedVariant = 'Standard';
  bool _isAdding = false;

  final List<String> _variants = ['Standard', 'Premium Upgrade', 'Deluxe Bundle'];

  @override
  void initState() {
    super.initState();
    _product = Get.arguments as StoreProduct;
  }

  Future<void> _handleAddToCart() async {
    setState(() => _isAdding = true);
    try {
      final selection = CartItemSelection(name: 'Option', value: _selectedVariant);
      await StoreService.addToCart(_product.id, _quantity, [selection]);
      
      if (mounted) {
        setState(() => _isAdding = false);
      }

      // Premium visual feedback bottom sheet
      Get.bottomSheet(
        Container(
          padding: Responsive.all(24),
          decoration: BoxDecoration(
            color: AppConfigController.to.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(Responsive.r(30))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(IconlyBold.shield_done, color: Colors.green, size: 36),
              ),
              const SizedBox(height: 18),
              Text(
                'added_to_cart'.tr.isNotEmpty ? 'added_to_cart'.tr : 'Added to Cart!',
                style: AppFonts.AlmaraiBold18.copyWith(
                  color: AppConfigController.to.isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'added_cart_success_desc'.tr.isNotEmpty 
                    ? 'added_cart_success_desc'.tr 
                    : 'The item has been successfully added to your cart.',
                textAlign: TextAlign.center,
                style: AppFonts.AlmaraiRegular12.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: Responsive.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.r(16))),
                      ),
                      child: Text(
                        'continue_shopping'.tr.isNotEmpty ? 'continue_shopping'.tr : 'Continue',
                        style: AppFonts.AlmaraiBold12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back(); // Dismiss bottomsheet
                        Get.offNamed(AppRoutes.storeCart); // Go to Cart
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.salesAccent,
                        padding: Responsive.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.r(16))),
                      ),
                      child: Text(
                        'view_cart'.tr.isNotEmpty ? 'view_cart'.tr : 'View Cart',
                        style: AppFonts.AlmaraiBold12.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        isScrollControlled: true,
      );
    } catch (e) {
      if (mounted) setState(() => _isAdding = false);
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
    
    final title = Responsive.isRTL ? _product.titleAr : _product.titleEn;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Premium Image Banner App Bar
          SliverAppBar(
            expandedHeight: Responsive.h(300),
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: isDark ? Colors.black45 : Colors.white.withOpacity(0.9),
                child: IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(
                    Responsive.isRTL ? IconlyLight.arrow_right : IconlyLight.arrow_left,
                    color: textColor,
                    size: 18,
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: _product.id,
                child: Image.network(
                  _product.images.isNotEmpty ? _product.images.first : 'https://images.unsplash.com/photo-1544816155-12df9643f363?w=500',
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),

          // 2. Info Cards
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(Responsive.r(30))),
              ),
              padding: Responsive.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Category
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.salesAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(Responsive.r(8)),
                        ),
                        child: Text(
                          _product.category.replaceAll('_', ' ').toUpperCase(),
                          style: AppFonts.AlmaraiBold10.copyWith(color: AppColors.salesAccent),
                        ),
                      ),
                      Text(
                        'in_stock'.tr.isNotEmpty ? 'in_stock'.tr : 'In Stock',
                        style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: AppFonts.AlmaraiBold18.copyWith(color: textColor, height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  
                  // Price Tag
                  Text(
                    '${_product.price.toInt()} EGP',
                    style: AppFonts.AlmaraiBold20.copyWith(color: AppColors.salesAccent),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: borderColor),
                  const SizedBox(height: 14),

                  // Product Description
                  Text(
                    'description'.tr.isNotEmpty ? 'description'.tr : 'Description',
                    style: AppFonts.AlmaraiBold14.copyWith(color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _product.description.isNotEmpty 
                        ? _product.description 
                        : 'No description available for this premium store product.',
                    style: AppFonts.AlmaraiRegular12.copyWith(color: textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: borderColor),
                  const SizedBox(height: 14),

                  // Option Variants
                  Text(
                    'select_option'.tr.isNotEmpty ? 'select_option'.tr : 'Select Format / Option',
                    style: AppFonts.AlmaraiBold14.copyWith(color: textColor),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: _variants.map((v) {
                      final isSelected = _selectedVariant == v;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedVariant = v),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.salesAccent.withOpacity(0.06) : cardBg,
                            borderRadius: BorderRadius.circular(Responsive.r(16)),
                            border: Border.all(
                              color: isSelected ? AppColors.salesAccent : borderColor,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                v,
                                style: AppFonts.AlmaraiBold12.copyWith(
                                  color: isSelected ? AppColors.salesAccent : textColor,
                                ),
                              ),
                              if (isSelected)
                                const Icon(IconlyBold.shield_done, color: AppColors.salesAccent, size: 18)
                              else
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: textSecondary),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: borderColor),
                  const SizedBox(height: 14),

                  // Quantity Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'quantity'.tr.isNotEmpty ? 'quantity'.tr : 'Quantity',
                        style: AppFonts.AlmaraiBold14.copyWith(color: textColor),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(Responsive.r(16)),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (_quantity > 1) {
                                  setState(() => _quantity--);
                                }
                              },
                              icon: Icon(Icons.remove, color: textColor, size: 16),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                _quantity.toString(),
                                style: AppFonts.AlmaraiBold14.copyWith(color: textColor),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() => _quantity++);
                              },
                              icon: Icon(Icons.add, color: textColor, size: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 100), // Space for bottom action bar
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: Responsive.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isAdding ? null : _handleAddToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.salesAccent,
                  padding: Responsive.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.r(18))),
                  elevation: 0,
                ),
                child: _isAdding
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'add_to_cart'.tr.isNotEmpty ? 'add_to_cart'.tr : 'Add to Cart',
                        style: AppFonts.AlmaraiBold14.copyWith(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
