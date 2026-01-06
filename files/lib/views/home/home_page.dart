import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart'; 
import '../../models/student_models.dart';
import '../../services/user_storage_service.dart';
import '../../widgets/shimmer_loading.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/bottom_nav_bar_widget.dart';
import '../../widgets/hero_section_widget.dart';
import '../../widgets/global_chatbot_widget.dart';
import '../../core/controllers/dashboard_controller.dart';
import '../../models/wallet_models.dart';
import '../../widgets/student_selection_sheet.dart';
 
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
} 

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _userData;

  @override 
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await UserStorageService.getUserData();
    if (mounted) {
      setState(() {
        _userData = userData;
      });
    }
  }

  Future<void> _refreshData() async {
    await DashboardController.to.refreshAll();
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
      backgroundColor: Colors.white,
      body: Obx(() => _buildHomeContent()),
      bottomNavigationBar: BottomNavBarWidget(
        currentIndex: _getCurrentIndex(),
        onTap: (index) {},
      ),
      floatingActionButton: DraggableChatbotWidget(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, 
    );
  }

  Widget _buildHomeContent() {
    final controller = DashboardController.to;
    final wallet = controller.wallet.value;
    final isLoading = controller.isLoading && controller.allApplications.isEmpty && controller.relatedChildren.isEmpty;

    if (isLoading) {
      return _buildShimmerLoading();  
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.primaryBlue,
      child: CustomScrollView(
        slivers: [
          // Hero Section
          SliverAppBar(
            expandedHeight: 80.h,
            floating: false,
            pinned: true,
            snap: false,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 0,
            collapsedHeight: 80.h,
          flexibleSpace: FlexibleSpaceBar(
            background: HeroSectionWidget(
              userData: _userData,
              pageTitle: 'home'.tr,
              showGreeting: true,
            ),
          ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 24.h)),
          
          // Wallet Card
          if (wallet != null) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text(
                  'wallet_balance'.tr,
                  style: AppFonts.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 8.h)),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: _buildWalletCard(wallet),
              ),
            ),
          ],
          
          if (wallet != null) SliverToBoxAdapter(child: SizedBox(height: 16.h)),
          
          // Student Management Section
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text(
                'student_management'.tr,
                style: AppFonts.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 8.h)),
          
          // Statistics Cards - First Row
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Obx(() {
                final controller = DashboardController.to;
                final totalStudents = controller.relatedChildren.length;
                final totalApplications = controller.allApplications.length;
                final isLoading = controller.isLoading;
                final isTakingLong = controller.isTakingLong;

                return Column(
                  children: [
                    if (isTakingLong && isLoading)
                      Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.wifi_off_rounded, color: AppColors.warning, size: 20.sp),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  'slow_connection_message'.tr,
                                  style: AppFonts.bodySmall.copyWith(color: AppColors.warning, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: isLoading && totalStudents == 0
                              ? ShimmerCard(height: 120.h, borderRadius: 16.r)
                              : _buildStatCard(
                                  icon: IconlyBroken.profile,
                                  title: 'total_students'.tr,
                                  value: _formatNumber(totalStudents.toString()),
                                  color: AppColors.primaryBlue,
                                  showAddButton: true,
                                  onAddTap: () => Get.toNamed(AppRoutes.addChildSteps),
                                ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: isLoading && totalApplications == 0
                              ? ShimmerCard(height: 120.h, borderRadius: 16.r)
                              : _buildStatCard(
                                  icon: IconlyBroken.document,
                                  title: 'total_applications'.tr,
                                  value: _formatNumber(totalApplications.toString()),
                                  color: AppColors.primaryGreen,
                                  showAddButton: true,
                                  onAddTap: () {
                                    if (totalStudents == 0) {
                                      Get.snackbar(
                                        'error'.tr,
                                        'no_students_for_application'.tr,
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: AppColors.error,
                                        colorText: Colors.white,
                                      );
                                    } else {
                                      // Show bottom sheet to select student first
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) => const StudentSelectionSheet(),
                                      ).then((selectedStudent) {
                                        if (selectedStudent != null && selectedStudent is Student) {
                                          // Navigate with selected student
                                          Get.toNamed(
                                            AppRoutes.applyToSchools,
                                            arguments: {'child': selectedStudent},
                                          );
                                        }
                                      });
                                    }
                                  },
                                  buttonText: 'add_application'.tr,
                                  isButtonDisabled: totalStudents == 0,
                                  disabledMessage: 'add_student_first_to_apply'.tr,
                                  buttonColor: AppColors.primaryGreen,
                                ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 32.h)),
        ],
      ),
    );
  }

  String _formatNumber(String number) {
    if (Get.locale?.languageCode == 'ar') {
      // Convert Western numerals to Arabic-Indic numerals
      return number.replaceAllMapped(
        RegExp(r'\d'),
        (match) {
          const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
          return arabicNumerals[int.parse(match.group(0)!)];
        },
      );
    }
    return number;
  }

  String _formatCurrency(double amount, String currency) {
    final formattedAmount = amount.toStringAsFixed(2);
    if (Get.locale?.languageCode == 'ar') {
      // Convert numbers to Arabic-Indic numerals
      final arabicAmount = _formatNumber(formattedAmount);
      // Translate currency if needed
      String translatedCurrency = currency;
      if (currency.toUpperCase() == 'USD') {
        translatedCurrency = 'دولار';
      } else if (currency.toUpperCase() == 'EGP') {
        translatedCurrency = 'جنيه';
      } else if (currency.toUpperCase() == 'SAR') {
        translatedCurrency = 'ريال';
      }
      return '$arabicAmount $translatedCurrency';
    }
    return '$formattedAmount $currency';
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool showAddButton = false,
    VoidCallback? onAddTap,
    String? buttonText,
    bool isButtonDisabled = false,
    String? disabledMessage,
    Color? buttonColor,
  }) {
    return Container(
      height: 190.h,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            color.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [ 
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight, 
                    colors: [
                      color,
                      color.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 15.sp),
              ),
            ],
          ),
          SizedBox(height: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppFonts.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 6.h),
              Text(
                value,
                style: AppFonts.h3.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 24.sp,
                  height: 1,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          // Add Student Button at bottom
          if (showAddButton && onAddTap != null) ...[
            SizedBox(height: 12.h),
            Opacity(
              opacity: isButtonDisabled ? 0.4 : 1.0,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isButtonDisabled ? null : onAddTap,
                  borderRadius: BorderRadius.circular(10.r),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: buttonColor ?? AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(
                        color: (buttonColor ?? AppColors.primaryBlue).withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        IconlyBroken.plus,
                        color: Colors.white,
                        size: 12.sp,
                      ),
                      SizedBox(width: 6.w),
                      Flexible(
                        child:                       Text(
                        buttonText ?? 'add_student'.tr,
                        style: AppFonts.bodySmall.copyWith(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ),
            // Disabled message below button
            if (isButtonDisabled && disabledMessage != null) ...[
              SizedBox(height: 8.h),
              Text(
                disabledMessage,
                style: AppFonts.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildWalletCard(Wallet wallet) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
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
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatCurrency(wallet.balance, wallet.currency),
                  style: AppFonts.h2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 80.h,
          floating: false,
          pinned: true,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 0,
          collapsedHeight: 80.h,
          flexibleSpace: HeroSectionWidget(
            userData: _userData,
            pageTitle: 'home'.tr,
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

}

