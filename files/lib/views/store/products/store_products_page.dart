import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/assets.dart';
import '../../../core/routes/app_routes.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../models/store_models.dart';
import '../../../services/store_service.dart';
import '../../../services/user_storage_service.dart';
import '../../../widgets/bottom_nav_bar_widget.dart';
import '../../../widgets/safe_network_image.dart';
import '../../../widgets/shimmer_loading.dart';
import '../../../widgets/hero_section_widget.dart';
import '../../../widgets/global_chatbot_widget.dart';

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


  int _getCurrentIndex() {
    final route = Get.currentRoute;
    if (route == AppRoutes.home) return 0;
    if (route == AppRoutes.myStudents) return 1;
    if (route == AppRoutes.applications) return 2;
    if (route == AppRoutes.storeProducts || route == AppRoutes.store) return 3;
    return 3; // Default to Store
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
      slivers: [
        // Hero Section
        SliverAppBar(
          expandedHeight: 80.h,
          floating: false,
          pinned: true,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 0,
          collapsedHeight: 80.h,
          flexibleSpace: FlexibleSpaceBar(
            background: HeroSectionWidget(
              userData: _userData,
              pageTitle: 'store'.tr,
              showGreeting: false,
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 20.h)),
        // Categories Filter
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'categories'.tr,
                  style: AppFonts.h4.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
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
                        return _buildCategoryChip(category, _getCategoryTitle(category));
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
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildProductCard(_products[index]),
                childCount: _products.length,
              ),
            ),
          ),
      ],
    ),
      bottomNavigationBar: BottomNavBarWidget(
        currentIndex: _getCurrentIndex(),
        onTap: (index) {},
      ),
      floatingActionButton: DraggableChatbotWidget(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }


  String _getCategoryTitle(Category category) {
    final isArabic = Get.locale?.languageCode == 'ar';
    return isArabic ? category.titleAr : category.titleEn;
  }

  Widget _buildCategoryChip(Category? category, String label) {
    final isSelected = _selectedCategory?.id == category?.id;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategory = isSelected ? null : category;
          });
          _loadProducts(resetPage: true);
        },
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBlue : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isSelected ? AppColors.primaryBlue : AppColors.borderLight,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Text(
            label,
            style: AppFonts.bodyMedium.copyWith(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontSize: 13.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    // schoolId is optional for pricing, can be null
    final finalPrice = product.getFinalPrice(null);
    final hasDiscount = product.discount != null &&
        (product.discount!.global != null && product.discount!.global! > 0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () {
          Get.toNamed(AppRoutes.storeProductDetails, arguments: {'productId': product.id});
        },
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image Section
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.r),
                      topRight: Radius.circular(16.r),
                    ),
                    child: Container(
                      width: double.infinity,
                      height: 160.h,
                      color: AppColors.primaryBlue.withOpacity(0.05),
                      child: product.images.isNotEmpty
                          ? SafeNetworkImage(
                              imageUrl: product.images.first,
                              width: double.infinity,
                              height: 160.h,
                              fit: BoxFit.cover,
                              errorWidget: Container(
                                color: AppColors.primaryBlue.withOpacity(0.1),
                                child: Icon(
                                  Icons.shopping_bag_rounded,
                                  color: AppColors.primaryBlue,
                                  size: 48.sp,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.shopping_bag_rounded,
                              color: AppColors.primaryBlue,
                              size: 48.sp,
                            ),
                    ),
                  ),
                  // Featured Badge
                  if (product.isFeatured)
                    Positioned(
                      top: 12.h,
                      right: 12.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: Colors.white,
                              size: 14.sp,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'featured'.tr,
                              style: AppFonts.bodySmall.copyWith(
                                color: Colors.white,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Discount Badge
                  if (hasDiscount)
                    Positioned(
                      top: 12.h,
                      left: 12.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.error.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_offer_rounded,
                              color: Colors.white,
                              size: 14.sp,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '${product.discount!.global?.toStringAsFixed(0) ?? ''}%',
                              style: AppFonts.bodySmall.copyWith(
                                color: Colors.white,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              // Product Info Section
              Padding(
                padding: EdgeInsets.all(14.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Title
                    Text(
                      product.titleAr,
                      style: AppFonts.h4.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 12.h),
                    // Price and Stock Row
                    Row(
                      children: [
                        // Price Section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasDiscount)
                                Text(
                                  '${product.price.toStringAsFixed(0)} ${'egp'.tr}',
                                  style: AppFonts.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 12.sp,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              SizedBox(height: hasDiscount ? 4.h : 0),
                              Text(
                                '${finalPrice.toStringAsFixed(0)} ${'egp'.tr}',
                                style: AppFonts.h3.copyWith(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Stock Status
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: product.stock > 0
                                ? AppColors.success.withOpacity(0.1)
                                : AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: product.stock > 0
                                  ? AppColors.success.withOpacity(0.3)
                                  : AppColors.error.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                product.stock > 0 ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                size: 16.sp,
                                color: product.stock > 0 ? AppColors.success : AppColors.error,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                product.stock > 0 ? 'in_stock'.tr : 'out_of_stock'.tr,
                                style: AppFonts.bodyMedium.copyWith(
                                  color: product.stock > 0 ? AppColors.success : AppColors.error,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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


