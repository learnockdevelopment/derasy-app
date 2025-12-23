import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/assets.dart';
import '../../../core/routes/app_routes.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../models/store_models.dart';
import '../../../services/store_service.dart';
import '../../../services/user_storage_service.dart';
import '../../../widgets/safe_network_image.dart';
import '../../../widgets/shimmer_loading.dart';
import '../../../widgets/top_app_bar_widget.dart';

class StoreProductsPage extends StatefulWidget {
  const StoreProductsPage({Key? key}) : super(key: key);

  @override
  State<StoreProductsPage> createState() => _StoreProductsPageState();
}

class _StoreProductsPageState extends State<StoreProductsPage> {
  List<Product> _products = [];
  List<Category> _categories = [];
  Category? _selectedCategory;
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isLoadingCategories = false;
  int _currentPage = 1;
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _userData;


  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCategories();
    _loadProducts();
  }

  Future<void> _loadUserData() async {
    final userData = await UserStorageService.getUserData();
    if (mounted) {
      setState(() {
        _userData = userData;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final categories = await StoreService.getAllCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  Future<void> _loadProducts({bool resetPage = false}) async {
    if (resetPage) {
      _currentPage = 1;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🛒 [STORE PAGE] ===========================================');
      print('🛒 [STORE PAGE] Loading products...');
      print('🛒 [STORE PAGE] Selected Category: ${_selectedCategory?.titleAr}');
      print('🛒 [STORE PAGE] Search Query: $_searchQuery');
      print('🛒 [STORE PAGE] Current Page: $_currentPage');
      
      final result = await StoreService.getAllProducts(
        category: _selectedCategory?.id,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        page: _currentPage,
        limit: 20,
      );

      // Print response for debugging
      print('🛒 [STORE PAGE] ✅ Products loaded successfully');
      print('🛒 [STORE PAGE] Products count: ${(result['products'] as List<Product>).length}');
      print('🛒 [STORE PAGE] Pagination: ${result['pagination']}');
      if ((result['products'] as List<Product>).isNotEmpty) {
        print('🛒 [STORE PAGE] First product: ${(result['products'] as List<Product>).first.titleAr}');
      }
      print('🛒 [STORE PAGE] ===========================================');

      if (mounted) {
        setState(() {
          _products = result['products'] as List<Product>;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('🛒 [STORE PAGE] ===========================================');
      print('🛒 [STORE PAGE] ❌ ERROR loading products');
      print('🛒 [STORE PAGE] Error type: ${e.runtimeType}');
      print('🛒 [STORE PAGE] Error message: $e');
      print('🛒 [STORE PAGE] Stack trace: ${StackTrace.current}');
      print('🛒 [STORE PAGE] ===========================================');
      
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
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _loadProducts(resetPage: true);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Top App Bar Widget
        TopAppBarWidget(
          userData: _userData,
          showLoading: _userData == null,
        ),
        // Search and Categories
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'search_products'.tr,
                      hintStyle: AppFonts.bodyMedium.copyWith(
                        color: const Color(0xFF9CA3AF),
                        fontSize: AppFonts.size14,
                      ),
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.primaryBlue, size: 20.sp),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                // Categories Filter
                if (_isLoadingCategories)
                  SizedBox(
                    height: 40.h,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      separatorBuilder: (_, __) => SizedBox(width: 8.w),
                      itemBuilder: (context, index) {
                        return ShimmerLoading(
                          child: Container(
                            width: 100.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  SizedBox(
                    height: 40.h,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length + 1,
                      separatorBuilder: (_, __) => SizedBox(width: 8.w),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildCategoryChip(null, 'all_categories'.tr);
                        }
                        final category = _categories[index - 1];
                        return _buildCategoryChip(category, category.titleAr);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Products List
        if (_isLoading && _products.isEmpty)
          SliverToBoxAdapter(child: _buildProductsShimmer())
        else if (_products.isEmpty)
          SliverFillRemaining(child: _buildEmptyState())
        else
          SliverPadding(
            padding: EdgeInsets.all(16.w),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: _buildProductCard(_products[index]),
                ),
                childCount: _products.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryChip(Category? category, String label) {
    final isSelected = _selectedCategory?.id == category?.id;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? category : null;
        });
        _loadProducts(resetPage: true);
      },
      selectedColor: AppColors.primaryBlue,
      labelStyle: AppFonts.bodyMedium.copyWith(
        color: isSelected ? Colors.white : const Color(0xFF1F2937),
        fontSize: AppFonts.size12,
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
    );
  }

  Widget _buildProductCard(Product product) {
    // schoolId is optional for pricing, can be null
    final finalPrice = product.getFinalPrice(null);
    final hasDiscount = product.discount != null &&
        (product.discount!.global != null && product.discount!.global! > 0);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.06),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () {
          Get.toNamed(AppRoutes.storeProductDetails, arguments: {'productId': product.id});
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            color: Colors.white,
          ),
          child: Row(
            children: [
              // Product Icon/Image
              Container(
                width: 70.w,
                height: 70.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  color: const Color(0xFF8B5CF6),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: product.images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: SafeNetworkImage(
                          imageUrl: product.images.first,
                          width: 70.w,
                          height: 70.w,
                          fit: BoxFit.cover,
                          errorWidget: Icon(
                            Icons.shopping_bag_rounded,
                            color: Colors.white,
                            size: 32.sp,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.shopping_bag_rounded,
                        color: Colors.white,
                        size: 32.sp,
                      ),
              ),
              SizedBox(width: 14.w),
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.titleAr,
                            style: AppFonts.bodyLarge.copyWith(
                              color: const Color(0xFF1F2937),
                              fontWeight: FontWeight.bold,
                              fontSize: AppFonts.size16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (product.isFeatured)
                          Container(
                            margin: EdgeInsets.only(left: 8.w),
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              'featured'.tr,
                              style: AppFonts.bodySmall.copyWith(
                                color: Colors.white,
                                fontSize: AppFonts.size10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasDiscount)
                              Text(
                                '${product.price.toStringAsFixed(0)} ${'egp'.tr}',
                                style: AppFonts.bodySmall.copyWith(
                                  color: const Color(0xFF9CA3AF),
                                  fontSize: AppFonts.size10,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            Text(
                              '${finalPrice.toStringAsFixed(0)} ${'egp'.tr}',
                              style: AppFonts.bodyMedium.copyWith(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: AppFonts.size14,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: product.stock > 0
                                ? const Color(0xFF10B981).withOpacity(0.15)
                                : const Color(0xFFEF4444).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                product.stock > 0 ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                size: 14.sp,
                                color: product.stock > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                product.stock > 0 ? 'in_stock'.tr : 'out_of_stock'.tr,
                                style: AppFonts.bodySmall.copyWith(
                                  color: product.stock > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                  fontSize: AppFonts.size10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (hasDiscount) ...[
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          '${product.discount!.global?.toStringAsFixed(0) ?? ''}% ${'discount'.tr}',
                          style: AppFonts.bodySmall.copyWith(
                            color: const Color(0xFFEF4444),
                            fontSize: AppFonts.size10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.primaryBlue,
                size: 18.sp,
              ),
            ],
          ),
        ),
          ),
        );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            AssetsManager.storeSvg,
            width: 120.w,
            height: 120.h,
            colorFilter: const ColorFilter.mode(
              Color(0xFF9CA3AF),
              BlendMode.srcIn,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'no_products_found'.tr,
            style: AppFonts.bodyLarge.copyWith(
              color: const Color(0xFF6B7280),
              fontSize: AppFonts.size16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsShimmer() {
    return Column(
      children: List.generate(
        5,
        (index) => Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
          child: ShimmerLoading(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  // Product Icon/Image Shimmer
                  Container(
                    width: 70.w,
                    height: 70.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      color: Colors.grey[300],
                    ),
                  ),
                  SizedBox(width: 16.w),
                  // Product Info Shimmer
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          height: 14.h,
                          width: 100.w,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(7.r),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Container(
                              height: 12.h,
                              width: 60.w,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Container(
                              height: 12.h,
                              width: 40.w,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Arrow Icon Shimmer
                  Container(
                    width: 24.w,
                    height: 24.w,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


