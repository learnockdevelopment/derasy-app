import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart'; 
import '../../services/students_service.dart';
import '../../services/user_storage_service.dart';
import '../../widgets/shimmer_loading.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/bottom_nav_bar_widget.dart';
import '../../widgets/hero_section_widget.dart';
import '../../services/admission_service.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  int _totalStudents = 0;
  int _totalApplications = 0;

  @override 
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final userData = await UserStorageService.getUserData();
      if (!mounted) return;
      setState(() {
        _userData = userData;
      });

      // Load statistics
      await _loadStatistics();
    } catch (e) {
      print('🏠 [HOME] Error loading data: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStatistics() async {
    if (!mounted) return;
    try {
      // Load students count
      final studentsResponse = await StudentsService.getRelatedChildren();
      if (!mounted) return;
      if (studentsResponse.success) {
        final currentUser = UserStorageService.getCurrentUser();
        if (currentUser != null) {
          final currentUserId = currentUser.id;
          final userJson = currentUser.toJson();
          final currentUserIdAlt = userJson['_id']?.toString() ?? currentUserId;

          final filteredChildren = studentsResponse.students.where((child) {
            final parentId = child.parent.id;
            return parentId == currentUserId || parentId == currentUserIdAlt;
          }).toList();

          if (!mounted) return;
          setState(() {
            _totalStudents = filteredChildren.length;
          });
        }
      }

      // Load applications count
      final applicationsResponse = await AdmissionService.getApplications();
      if (!mounted) return;
      setState(() {
        _totalApplications = applicationsResponse.applications.length;
      });
    } catch (e) {
      print('🏠 [HOME] Error loading statistics: $e');
    }
  }

  Future<void> _refreshData() async {
    await _loadStatistics();
  }

  int _getCurrentIndex() {
    final route = Get.currentRoute;
    if (route == AppRoutes.home) return 0;
    if (route == AppRoutes.myStudents) return 1;
    if (route == AppRoutes.applications) return 2;
    if (route == AppRoutes.storeProducts || route == AppRoutes.store) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey200,
      body: _buildHomeContent(),
      bottomNavigationBar: BottomNavBarWidget(
        currentIndex: _getCurrentIndex(),
        onTap: (index) {},
      ),
      floatingActionButton: _buildCustomerServiceButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, 
    );
  }

  Widget _buildHomeContent() {
    if (_isLoading) {
      return _buildShimmerLoading();  
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.primaryBlue,
      child: CustomScrollView(
        slivers: [
          // Hero Section
          SliverAppBar(
            expandedHeight: 100.h,
            floating: false,
            pinned: true,
            snap: false,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 0,
            collapsedHeight: 100.h,
            flexibleSpace: FlexibleSpaceBar(
              background: HeroSectionWidget(
                userData: _userData,
                showSearchBar: false,
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 20.h)),
          
          // Promotional Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: _buildPromotionalBanner(),
            ),
          ),
          
          SliverToBoxAdapter(child: SizedBox(height: 20.h)),
          
          // Statistics Cards - Symmetric Grid
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: IconlyBroken.profile,
                      title: 'total_students'.tr,
                      value: _totalStudents.toString(),
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildStatCard(
                      icon: IconlyBroken.document,
                      title: 'total_applications'.tr,
                      value: _totalApplications.toString(),
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(child: SizedBox(height: 24.h)),
          
          // Quick Actions Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: _buildSectionTitle('quick_actions'.tr, AppColors.primaryBlue),
            ),
          ),
          
          SliverToBoxAdapter(child: SizedBox(height: 16.h)),
          
          // Quick Actions Grid - Symmetric 2x2
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                children: [
                  // First Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          icon: IconlyBroken.profile,
                          title: 'my_students'.tr,
                          subtitle: 'view_and_manage_students'.tr,
                          color: AppColors.primaryBlue,
                          onTap: () => Get.offNamed(AppRoutes.myStudents),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildActionCard(
                          icon: IconlyBroken.document,
                          title: 'applications'.tr,
                          subtitle: 'view_applications'.tr,
                          color: AppColors.primaryGreen,
                          onTap: () => Get.offNamed(AppRoutes.applications),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  // Second Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          icon: IconlyBroken.bag,
                          title: 'store'.tr,
                          subtitle: 'browse_products'.tr,
                          color: AppColors.secondary,
                          onTap: () => Get.offNamed(AppRoutes.storeProducts),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildActionCard(
                          icon: IconlyBroken.plus,
                          title: 'add_student'.tr,
                          subtitle: 'start_learning'.tr,
                          color: AppColors.primaryPurple,
                          onTap: () => Get.offNamed(AppRoutes.addChild),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(child: SizedBox(height: 24.h)),
          
          // Special Offers Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: _buildSectionTitle('special_offers'.tr, AppColors.primaryPurple),
            ),
          ),
          
          SliverToBoxAdapter(child: SizedBox(height: 16.h)),
          
          // Special Offers - Symmetric Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                children: [
                  _buildOfferCard(
                    title: 'customer_service'.tr,
                    description: 'chat_with_support'.tr,
                    icon: IconlyBroken.chat,
                    color: AppColors.primaryBlue,
                    onTap: () => Get.toNamed(AppRoutes.chatbot),
                  ),
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(child: SizedBox(height: 100.h)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4.w,
          height: 20.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color,
                color.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(width: 10.w),
        Text(
          title,
          style: AppFonts.h4.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      height: 120.h,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            color.withOpacity(0.03),
          ],
        ),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withOpacity(0.75),
                ],
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: Colors.white, size: 20.sp),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppFonts.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                  height: 1,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                title,
                style: AppFonts.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          height: 130.h,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                color.withOpacity(0.04),
              ],
            ),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.12),
                blurRadius: 15,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      color.withOpacity(0.75),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(icon, color: Colors.white, size: 24.sp),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.bodyLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 3.h),
                    Text(
                      subtitle,
                      style: AppFonts.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromotionalBanner() {
    return Container(
      height: 160.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlue,
            AppColors.primaryBlue.withOpacity(0.85),
            AppColors.primaryPurple.withOpacity(0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative elements
          Positioned(
            top: -30.h,
            right: -30.w,
            child: Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -20.h,
            left: -20.w,
            child: Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        IconlyBroken.star,
                        color: Colors.white,
                        size: 16.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'welcome_back'.tr,
                        style: AppFonts.bodySmall.copyWith(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'education_management_platform'.tr,
                  style: AppFonts.h3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20.sp,
                    letterSpacing: 0.3,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'app_tagline'.tr,
                  style: AppFonts.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                color.withOpacity(0.04),
              ],
            ),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.12),
                blurRadius: 15,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      color.withOpacity(0.75),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(icon, color: Colors.white, size: 22.sp),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppFonts.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      description,
                      style: AppFonts.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                IconlyBroken.arrow_left_2,
                color: color.withOpacity(0.5),
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 100.h,
          floating: false,
          pinned: true,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 0,
          collapsedHeight: 100.h,
          flexibleSpace: HeroSectionWidget(
            userData: _userData,
            showSearchBar: false,
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 24.h)),
        // Banner Shimmer
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: ShimmerCard(height: 200.h, borderRadius: 28.r),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 24.h)),
        // Stats Shimmer
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                Expanded(child: ShimmerCard(height: 140.h, borderRadius: 24.r)),
                SizedBox(width: 16.w),
                Expanded(child: ShimmerCard(height: 140.h, borderRadius: 24.r)),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 32.h)),
        // Section Title Shimmer
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: ShimmerLoading(
              child: Container(
                height: 28.h,
                width: 140.w,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 20.h)),
        // Actions Grid Shimmer
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: ShimmerCard(height: 160.h, borderRadius: 24.r)),
                    SizedBox(width: 16.w),
                    Expanded(child: ShimmerCard(height: 160.h, borderRadius: 24.r)),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(child: ShimmerCard(height: 160.h, borderRadius: 24.r)),
                    SizedBox(width: 16.w),
                    Expanded(child: ShimmerCard(height: 160.h, borderRadius: 24.r)),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 32.h)),
        // Section Title Shimmer
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: ShimmerLoading(
              child: Container(
                height: 28.h,
                width: 140.w,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 20.h)),
        // Offer Shimmer
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: ShimmerCard(height: 100.h, borderRadius: 24.r),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerServiceButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.2),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: FloatingActionButton.small(
              heroTag: "customer_service_fab",
              onPressed: () {
                Get.toNamed(AppRoutes.chatbot);
              },
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(IconlyBroken.chat, color: Colors.white, size: 20.sp),
            ),
          ),
        );
      },
    );
  }
}

