import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/assets.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/responsive_utils.dart';
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
          expandedHeight: Responsive.h(80),
          floating: false,
          pinned: true,
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFFF8FAFC),
          elevation: 0,
          toolbarHeight: 0,
          collapsedHeight: Responsive.h(45),
          flexibleSpace: FlexibleSpaceBar(
            background: HeroSectionWidget(
              userData: _userData,
              pageTitle: 'store'.tr,
              showGreeting: false,
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: Responsive.h(20))),
        // Categories Filter
        SliverToBoxAdapter(
          child: Container(
            color: Colors.transparent,
            padding: Responsive.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'categories'.tr,
                  style: AppFonts.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: Responsive.sp(14),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: Responsive.h(12)),
                // Categories Filter
                if (_isLoadingCategories)
                  SizedBox(
                    height: Responsive.h(36),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      separatorBuilder: (_, __) => SizedBox(width: Responsive.w(8)),
                      itemBuilder: (context, index) {
                        return ShimmerLoading(
                          child: Container(
                            width: Responsive.w(90),
                            height: Responsive.h(36),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(Responsive.r(18)),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  SizedBox(
                    height: Responsive.h(36),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length + 1,
                      separatorBuilder: (_, __) => SizedBox(width: Responsive.w(8)),
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
        SliverToBoxAdapter(child: SizedBox(height: Responsive.h(16))),
        // Products List
        if (_isLoading && _products.isEmpty)
          const SliverFillRemaining(
             child: Center(child: CircularProgressIndicator())) // Simplified loader for grid transition
        else if (_products.isEmpty)
          SliverFillRemaining(child: _buildEmptyState())
        else
          SliverPadding(
            padding: Responsive.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                crossAxisSpacing: Responsive.w(12),
                mainAxisSpacing: Responsive.h(12),
              ),
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
        borderRadius: BorderRadius.circular(Responsive.r(16)),
        child: Container(
          padding: Responsive.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBlue : Colors.white,
            borderRadius: BorderRadius.circular(Responsive.r(16)),
            border: Border.all(
              color: isSelected ? AppColors.primaryBlue : AppColors.borderLight,
              width: Responsive.w(1.5),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.3),
                      blurRadius: Responsive.r(8),
                      offset: Offset(0, Responsive.h(4)),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: Responsive.r(4),
                      offset: Offset(0, Responsive.h(2)),
                    ),
                  ],
          ),
          child: Text(
            label,
            style: AppFonts.bodyMedium.copyWith(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontSize: Responsive.sp(12),
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
        (product.discount?.global != null && (product.discount?.global ?? 0) > 0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(Responsive.r(16)),
        onTap: () {
          Get.toNamed(AppRoutes.storeProductDetails, arguments: {'productId': product.id});
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Responsive.r(16)),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
                      topLeft: Radius.circular(Responsive.r(16)),
                      topRight: Radius.circular(Responsive.r(16)),
                    ),
                    child: Container(
                      width: double.infinity,
                      height: Responsive.h(120),
                      color: AppColors.primaryBlue.withOpacity(0.05),
                      child: product.images.isNotEmpty
                          ? SafeNetworkImage(
                              imageUrl: product.images.first,
                              width: double.infinity,
                              height: Responsive.h(120),
                              fit: BoxFit.cover,
                            )
                          : Icon(
                              Icons.shopping_bag_rounded,
                              color: AppColors.primaryBlue,
                              size: Responsive.sp(32),
                            ),
                    ),
                  ),
                  // Discount Badge
                  if (hasDiscount)
                    Positioned(
                      top: Responsive.h(8),
                      left: Responsive.w(8),
                      child: Container(
                        padding: Responsive.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(Responsive.r(4)),
                        ),
                        child: Text(
                          '${product.discount!.global?.toStringAsFixed(0) ?? ''}%',
                          style: AppFonts.bodySmall.copyWith(
                            color: Colors.white,
                            fontSize: Responsive.sp(9),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Product Info Section
              Padding(
                padding: Responsive.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Title
                    Text(
                      product.titleAr,
                      style: AppFonts.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: Responsive.sp(11),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: Responsive.h(6)),
                    // Price
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasDiscount)
                              Text(
                                '${product.price.toStringAsFixed(0)} ${'egp'.tr}',
                                style: AppFonts.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: Responsive.sp(9),
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                             Text(
                              '${finalPrice.toStringAsFixed(0)} ${'egp'.tr}',
                              style: AppFonts.h4.copyWith(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: Responsive.sp(13),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Add Button (Small)
                        Container(
                          padding: Responsive.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(Responsive.r(8)),
                          ),
                          child: Icon(
                            IconlyBold.bag,
                            size: Responsive.sp(14),
                            color: AppColors.primaryBlue,
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
            width: Responsive.w(100),
            height: Responsive.h(100),
            colorFilter: const ColorFilter.mode(
              Color(0xFF9CA3AF),
              BlendMode.srcIn,
            ),
          ),
          SizedBox(height: Responsive.h(16)),
          Text(
            'no_products_found'.tr,
            style: AppFonts.bodyLarge.copyWith(
              color: const Color(0xFF6B7280),
              fontSize: Responsive.sp(15),
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
          padding: Responsive.only(left: 16, right: 16, bottom: 12),
          child: ShimmerLoading(
            child: Container(
              padding: Responsive.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Responsive.r(12)),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  // Product Icon/Image Shimmer
                  Container(
                    width: Responsive.w(60),
                    height: Responsive.w(60),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Responsive.r(10)),
                      color: Colors.grey[300],
                    ),
                  ),
                  SizedBox(width: Responsive.w(12)),
                  // Product Info Shimmer
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: Responsive.h(14),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(Responsive.r(6)),
                          ),
                        ),
                        SizedBox(height: Responsive.h(6)),
                        Container(
                          height: Responsive.h(12),
                          width: Responsive.w(80),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(Responsive.r(6)),
                          ),
                        ),
                        SizedBox(height: Responsive.h(6)),
                        Row(
                          children: [
                            Container(
                              height: Responsive.h(10),
                              width: Responsive.w(50),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(Responsive.r(4)),
                              ),
                            ),
                            SizedBox(width: Responsive.w(8)),
                            Container(
                              height: Responsive.h(10),
                              width: Responsive.w(30),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(Responsive.r(4)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: Responsive.w(12)),
                  // Arrow Icon Shimmer
                  Container(
                    width: Responsive.w(20),
                    height: Responsive.w(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(Responsive.r(10)),
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


