import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
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
import '../../core/utils/format_utils.dart';

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
          expandedHeight: Responsive.h(Responsive.isTablet || Responsive.isDesktop ? 140 : 80),
          floating: false,
          pinned: true,
          snap: false,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 0,
          collapsedHeight: Responsive.h(45),
          flexibleSpace: FlexibleSpaceBar(
            background: HeroSectionWidget(
              userData: _userData,
              pageTitle: 'home'.tr,
              showGreeting: true,
            ),
          ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: Responsive.h(24))),
          
          // Wallet Card
          if (wallet != null) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: Responsive.symmetric(horizontal: 20),
                child: Text(
                  'wallet_balance'.tr,
                  style: AppFonts.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: Responsive.sp(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: Responsive.h(8))),
            SliverToBoxAdapter(
              child: Padding(
                padding: Responsive.symmetric(horizontal: 20),
                child: _buildWalletCard(wallet),
              ),
            ),
          ],
          
          if (wallet != null) SliverToBoxAdapter(child: SizedBox(height: Responsive.h(16))),
          
          // Student Management Section
          SliverToBoxAdapter(
            child: Padding(
              padding: Responsive.symmetric(horizontal: 20),
              child: Text(
                'student_management'.tr,
                style: AppFonts.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: Responsive.sp(15),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: Responsive.h(8))),

          // Statistics Cards - First Row
          SliverToBoxAdapter(
            child: Padding(
              padding: Responsive.symmetric(horizontal: 20),
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
                        padding: Responsive.only(bottom: 12),
                        child: Container(
                          padding: Responsive.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(Responsive.r(12)),
                            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.wifi_off_rounded, color: AppColors.warning, size: Responsive.sp(20)),
                              SizedBox(width: Responsive.w(12)),
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
                              ? ShimmerCard(height: Responsive.h(140), borderRadius: Responsive.r(16))
                              : _buildStatCard(
                                  icon: IconlyBroken.profile,
                                  title: 'total_students'.tr,
                                  value: _formatNumber(totalStudents.toString()),
                                  color: AppColors.primaryBlue,
                                  showAddButton: true,
                                  onAddTap: () => Get.toNamed(AppRoutes.addChildSteps),
                                ),
                        ),
                        SizedBox(width: Responsive.w(16)),
                        Expanded(
                          child: isLoading && totalApplications == 0
                              ? ShimmerCard(height: Responsive.h(140), borderRadius: Responsive.r(16))
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
          SliverToBoxAdapter(child: SizedBox(height: Responsive.h(32))),
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
          final group = match.group(0);
          if (group == null) return '';
          return arabicNumerals[int.parse(group)];
        },
      );
    }
    return number;
  }

  String _formatCurrency(double amount, String currency) {
    return FormatUtils.formatPrice(amount, currency);
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color, 
    bool showAddButton = false,
    VoidCallback? onAddTap,
    String? buttonText,
    bool isButtonDisabled = false,
    String? disabledMessage,
    Color? buttonColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.r(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppColors.grey100),
      ),
      child: Stack(
        children: [
          // Background Accent
          Positioned(
            right: -Responsive.w(15),
            top: -Responsive.h(15),
            child: Container(
              width: Responsive.w(70),
              height: Responsive.h(70),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: Responsive.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Header
                Container(
                  padding: Responsive.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(Responsive.r(14)),
                  ),
                  child: Icon(icon, color: color, size: Responsive.sp(18)),
                ),
                SizedBox(height: Responsive.h(12)),
                // Title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontSize: Responsive.sp(12),
                        ),
                      ),
                    ),
                    SizedBox(width: Responsive.w(8)),
                    Text(
                      value,
                      style: AppFonts.h3.copyWith(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.sp(24),
                      ),
                    ),
                  ],
                ),
                // Action Button (if any)
                if (showAddButton && onAddTap != null) ...[
                  SizedBox(height: Responsive.h(12)),
                  InkWell(
                    onTap: isButtonDisabled ? null : onAddTap,
                    borderRadius: BorderRadius.circular(Responsive.r(10)),
                    child: Container(
                      width: double.infinity,
                      padding: Responsive.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isButtonDisabled 
                            ? AppColors.grey50 
                            : (buttonColor ?? color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(Responsive.r(10)),
                      ),
                      child: Center(
                        child: Text(
                          buttonText ?? 'add_student'.tr,
                          style: AppFonts.bodySmall.copyWith(
                            color: isButtonDisabled 
                                ? AppColors.textSecondary 
                                : (buttonColor ?? color),
                            fontSize: Responsive.sp(9),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (isButtonDisabled && disabledMessage != null)
                    Padding(
                      padding: Responsive.only(top: 4),
                      child: Text(
                        disabledMessage,
                        style: AppFonts.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: Responsive.sp(8),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(Wallet wallet) {
    return Container(
      width: double.infinity,
      padding: Responsive.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Midnight Dark Blue
        borderRadius: BorderRadius.circular(Responsive.r(24)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0F172A), // Dark Slate
            const Color(0xFF1E293B), // Slate 800
            const Color(0xFF334155), // Slate 700
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Section (Right in RTL)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'current_balance'.tr,
                    style: AppFonts.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: Responsive.sp(11),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: Responsive.h(4)),
                  Text(
                    _formatCurrency(wallet.balance, wallet.currency),
                    style: AppFonts.h1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.sp(24),
                      height: 1.0,
                    ),
                  ),
                ],
              ),
              // Transactions Button (Left in RTL)
              Material(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Responsive.r(12)),
                child: InkWell(
                  onTap: () => Get.toNamed(AppRoutes.wallet),
                  borderRadius: BorderRadius.circular(Responsive.r(12)),
                  child: Padding(
                    padding: Responsive.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(IconlyBroken.document, color: Colors.white, size: Responsive.sp(14)),
                        SizedBox(width: Responsive.w(6)),
                        Text(
                          'transactions'.tr,
                          style: AppFonts.bodySmall.copyWith(
                            color: Colors.white,
                            fontSize: Responsive.sp(11),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(20)),
          Row(
            children: [
              Expanded(
                child: _buildWalletActionButton(
                  label: 'deposit'.tr,
                  icon: IconlyBroken.plus,
                  onTap: () => Get.toNamed(AppRoutes.walletDeposit),
                ),
              ),
              SizedBox(width: Responsive.w(12)),
              Expanded(
                child: _buildWalletActionButton(
                  label: 'withdraw'.tr,
                  icon: IconlyBroken.arrow_up_2,
                  onTap: () => Get.toNamed(AppRoutes.walletWithdraw),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(Responsive.r(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Responsive.r(14)),
        child: Container(
          padding: Responsive.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Responsive.r(14)),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: Responsive.sp(16)),
              SizedBox(width: Responsive.w(8)),
              Text(
                label,
                style: AppFonts.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.sp(12),
                ),
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
          expandedHeight: Responsive.h(80),
          floating: false,
          pinned: true,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 0,
          collapsedHeight: Responsive.h(45),
          flexibleSpace: HeroSectionWidget(
            userData: _userData,
            pageTitle: 'home'.tr,
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: Responsive.h(16))),
        // Banner Shimmer
        SliverToBoxAdapter(
          child: Padding(
            padding: Responsive.symmetric(horizontal: 20),
            child: ShimmerCard(height: Responsive.h(120), borderRadius: Responsive.r(16)),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: Responsive.h(16))),
        // Stats Shimmer
        SliverToBoxAdapter(
          child: Padding(
            padding: Responsive.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(child: ShimmerCard(height: Responsive.h(120), borderRadius: Responsive.r(16))),
                SizedBox(width: Responsive.w(16)),
                Expanded(child: ShimmerCard(height: Responsive.h(120), borderRadius: Responsive.r(16))),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: Responsive.h(24))),
        // Section Title Shimmer
        SliverToBoxAdapter(
          child: Padding(
            padding: Responsive.symmetric(horizontal: 20),
            child: ShimmerLoading(
              child: Container(
                height: Responsive.h(20),
                width: Responsive.w(120),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(Responsive.r(4)),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: Responsive.h(16))),
        // Actions Grid Shimmer
        SliverToBoxAdapter(
          child: Padding(
            padding: Responsive.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: ShimmerCard(height: Responsive.h(140), borderRadius: Responsive.r(16))),
                    SizedBox(width: Responsive.w(16)),
                    Expanded(child: ShimmerCard(height: Responsive.h(140), borderRadius: Responsive.r(16))),
                  ],
                ),
                SizedBox(height: Responsive.h(16)),
                Row(
                  children: [
                    Expanded(child: ShimmerCard(height: Responsive.h(140), borderRadius: Responsive.r(16))),
                    SizedBox(width: Responsive.w(16)),
                    Expanded(child: ShimmerCard(height: Responsive.h(140), borderRadius: Responsive.r(16))),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: Responsive.h(24))),
        // Section Title Shimmer
        SliverToBoxAdapter(
          child: Padding(
            padding: Responsive.symmetric(horizontal: 20),
            child: ShimmerLoading(
              child: Container(
                height: Responsive.h(20),
                width: Responsive.w(120),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(Responsive.r(4)),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: Responsive.h(16))),
        // Offer Shimmer
        SliverToBoxAdapter(
          child: Padding(
            padding: Responsive.symmetric(horizontal: 20),
            child: ShimmerCard(height: Responsive.h(90), borderRadius: Responsive.r(16)),
          ),
        ),
      ],
    );
  }
}

