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

class StoreHomePage extends StatefulWidget {
  const StoreHomePage({Key? key}) : super(key: key);

  @override
  State<StoreHomePage> createState() => _StoreHomePageState();
}

class _StoreHomePageState extends State<StoreHomePage> {
  bool _isLoading = true;
  List<StoreProduct> _allProducts = [];
  List<StoreProduct> _filteredProducts = [];
  List<StoreProduct> _filteredPackages = [];
  String _selectedCategory = 'all';
  String _searchQuery = '';
  int _cartCount = 0;

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'name': 'All Items', 'name_ar': 'الكل'},
  ];

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  String _translateCategoryArabic(String cat) {
    final lower = cat.toLowerCase();
    if (lower.contains('uniform')) return 'الزي المدرسي';
    if (lower.contains('book')) return 'الكتب الدراسية';
    if (lower.contains('tool')) return 'الأدوات المدرسية';
    if (lower.contains('package') || lower.contains('bundle')) return 'الباقات';
    return cat.replaceAll('_', ' ').capitalizeFirst ?? cat;
  }

  Future<void> _loadStoreData() async {
    setState(() => _isLoading = true);
    try {
      final products = await StoreService.getProducts();
      final cart = await StoreService.getCart();
      if (mounted) {
        setState(() {
          _allProducts = products;
          _cartCount = cart.itemCount;

          // Extract unique categories from items dynamically
          final uniqueCategories = _allProducts
              .map((p) => p.category)
              .where((c) => c.isNotEmpty)
              .toSet()
              .toList();

          _categories.clear();
          _categories.add({'id': 'all', 'name': 'All Items', 'name_ar': 'الكل'});
          for (final cat in uniqueCategories) {
            _categories.add({
              'id': cat,
              'name': cat.replaceAll('_', ' ').capitalizeFirst ?? cat,
              'name_ar': _translateCategoryArabic(cat),
            });
          }

          _filterProducts();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterProducts() {
    setState(() {
      final matchedAll = _allProducts.where((p) {
        final matchesCat = _selectedCategory == 'all' || p.category == _selectedCategory;
        final matchesSearch = _searchQuery.isEmpty || 
            p.titleEn.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.titleAr.toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesCat && matchesSearch;
      }).toList();

      _filteredProducts = matchedAll.where((p) => p.itemType == 'product').toList();
      _filteredPackages = matchedAll.where((p) => p.itemType == 'package').toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppConfigController.to.isDarkMode;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final textSecondary = isDark ? Colors.grey.shade400 : AppColors.textSecondary;
    final borderColor = isDark ? Colors.white12 : AppColors.grey300;

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
          'derasy_store'.tr.isNotEmpty ? 'derasy_store'.tr : 'Derasy Store',
          style: AppFonts.AlmaraiBold18.copyWith(color: textColor),
        ),
        centerTitle: true,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () => Get.toNamed(AppRoutes.storeCart)?.then((_) => _loadStoreData()),
                icon: Icon(IconlyLight.buy, color: textColor),
              ),
              if (_cartCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Center(
                      child: Text(
                        _cartCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: Responsive.w(12)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.salesAccent))
          : RefreshIndicator(
              onRefresh: _loadStoreData,
              color: AppColors.salesAccent,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. Search Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: Responsive.symmetric(horizontal: 24, vertical: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(Responsive.r(20)),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10, 
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: Responsive.symmetric(horizontal: 16),
                        child: TextField(
                          onChanged: (val) {
                            _searchQuery = val;
                            _filterProducts();
                          },
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: 'search_store'.tr.isNotEmpty ? 'search_store'.tr : 'Search store items...',
                            hintStyle: TextStyle(color: textSecondary),
                            border: InputBorder.none,
                            icon: Icon(IconlyLight.search, color: textSecondary),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. Horizontal Categories
                  SliverToBoxAdapter(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: Responsive.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        children: _categories.map((cat) {
                          final isSelected = _selectedCategory == cat['id'];
                          final catName = Responsive.isRTL ? cat['name_ar']! : cat['name']!;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = cat['id']!;
                                _filterProducts();
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: EdgeInsets.symmetric(horizontal: Responsive.w(4)),
                              padding: Responsive.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(colors: [AppColors.salesAccent, Color(0xFF6366F1)])
                                    : null,
                                color: isSelected ? null : cardBg,
                                borderRadius: BorderRadius.circular(Responsive.r(30)),
                                border: Border.all(
                                  color: isSelected ? Colors.transparent : borderColor,
                                  width: 1.2,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.salesAccent.withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Text(
                                catName,
                                style: AppFonts.AlmaraiBold12.copyWith(
                                  color: isSelected ? Colors.white : textSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // 3. School Packages / Bundles Section (Horizontal Scroll)
                  if (_filteredPackages.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: Responsive.symmetric(horizontal: 24, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              Responsive.isRTL ? 'الباقات' : 'Bundles',
                              style: AppFonts.AlmaraiBold16.copyWith(color: textColor),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.salesAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_filteredPackages.length} ${Responsive.isRTL ? 'باقات' : 'Bundles'}',
                                style: AppFonts.AlmaraiBold10.copyWith(color: AppColors.salesAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        height: Responsive.h(130),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: Responsive.symmetric(horizontal: 20),
                          itemCount: _filteredPackages.length,
                          itemBuilder: (context, index) {
                            final pkg = _filteredPackages[index];
                            final title = Responsive.isRTL ? pkg.titleAr : pkg.titleEn;
                            
                            return GestureDetector(
                              onTap: () {
                                Get.toNamed(
                                  AppRoutes.storeProductDetails,
                                  arguments: pkg,
                                )?.then((_) => _loadStoreData());
                              },
                              child: Container(
                                width: Responsive.w(230),
                                margin: EdgeInsets.symmetric(horizontal: Responsive.w(6), vertical: 4),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(Responsive.r(16)),
                                  border: Border.all(color: borderColor, width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Cover Image
                                    ClipRRect(
                                      borderRadius: BorderRadius.horizontal(
                                        left: Radius.circular(Responsive.isRTL ? 0 : Responsive.r(14)),
                                        right: Radius.circular(Responsive.isRTL ? Responsive.r(14) : 0),
                                      ),
                                      child: Image.network(
                                        pkg.images.isNotEmpty ? pkg.images.first : 'https://images.unsplash.com/photo-1544816155-12df9643f363?w=500',
                                        width: Responsive.w(80),
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Container(color: Colors.grey.shade300, width: Responsive.w(80)),
                                      ),
                                    ),
                                    // Text details
                                    Expanded(
                                      child: Padding(
                                        padding: Responsive.all(8),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF6366F1).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                pkg.category.isNotEmpty ? pkg.category : 'Uniform',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppFonts.AlmaraiBold10.copyWith(color: const Color(0xFF6366F1)),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppFonts.AlmaraiBold10.copyWith(color: textColor, height: 1.2),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  '${pkg.price.toInt()} EGP',
                                                  style: AppFonts.AlmaraiBold12.copyWith(color: AppColors.salesAccent),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.all(3),
                                                  decoration: const BoxDecoration(
                                                    color: AppColors.salesAccent,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    IconlyLight.plus,
                                                    size: 10,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],

                  // 4. Products Section Header
                  if (_filteredProducts.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: Responsive.symmetric(horizontal: 24, vertical: 12),
                        child: Text(
                          Responsive.isRTL ? 'المنتجات' : 'Products',
                          style: AppFonts.AlmaraiBold16.copyWith(color: textColor),
                        ),
                      ),
                    ),

                  // 5. Grid of Products / Empty State
                  if (_filteredProducts.isEmpty && _filteredPackages.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(IconlyLight.folder, size: 48, color: textSecondary),
                            const SizedBox(height: 12),
                            Text(
                              'no_products_found'.tr.isNotEmpty ? 'no_products_found'.tr : 'No products found',
                              style: AppFonts.AlmaraiBold14.copyWith(color: textColor),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: Responsive.symmetric(horizontal: 24, vertical: 16),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: Responsive.w(16),
                          mainAxisSpacing: Responsive.h(16),
                          childAspectRatio: 0.72,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final p = _filteredProducts[index];
                            final title = Responsive.isRTL ? p.titleAr : p.titleEn;

                            return GestureDetector(
                              onTap: () {
                                Get.toNamed(
                                  AppRoutes.storeProductDetails,
                                  arguments: p,
                                )?.then((_) => _loadStoreData());
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(Responsive.r(24)),
                                  border: Border.all(color: borderColor, width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Image
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(Responsive.r(24))),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.network(
                                              p.images.isNotEmpty ? p.images.first : 'https://images.unsplash.com/photo-1544816155-12df9643f363?w=500',
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) => Container(color: Colors.grey.shade300),
                                            ),
                                            if (p.featured)
                                              Positioned(
                                                top: 10,
                                                left: 10,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.salesAccent,
                                                    borderRadius: BorderRadius.circular(Responsive.r(8)),
                                                  ),
                                                  child: const Text(
                                                    'POPULAR',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 8,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Info
                                    Padding(
                                      padding: Responsive.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppFonts.AlmaraiBold12.copyWith(color: textColor, height: 1.3),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '${p.price.toInt()} EGP',
                                                style: AppFonts.AlmaraiBold14.copyWith(color: AppColors.salesAccent),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: AppColors.salesAccent.withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  IconlyLight.plus,
                                                  size: 14,
                                                  color: AppColors.salesAccent,
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
                            );
                          },
                          childCount: _filteredProducts.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
