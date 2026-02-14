import 'package:flutter/material.dart';
import 'dart:async';
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
import '../../widgets/student_selection_sheet.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() => _buildHomeContent()),
      bottomNavigationBar: const BottomNavBarWidget(),
      floatingActionButton: DraggableChatbotWidget(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, 
    );
  }

  Widget _buildHomeContent() {
    final controller = DashboardController.to;
    final allApplications = controller.allApplications;
    final isLoading = controller.isLoading && allApplications.isEmpty && controller.relatedChildren.isEmpty;

    if (isLoading) {
      return _buildShimmerLoading();  
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.blue1,
      child: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // Hero Section
        SliverAppBar(
          expandedHeight: Responsive.h(Responsive.isTablet || Responsive.isDesktop ? 120 : 80), // Increased height
          floating: false,
          pinned: true,
          snap: false,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 0,
          collapsedHeight: Responsive.h(35),
          flexibleSpace: FlexibleSpaceBar(
            background: HeroSectionWidget(
              userData: _userData,
              pageTitle: 'home'.tr,
              showGreeting: true,
            ),
          ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: Responsive.h(24))), // Increased spacing
          
          // Simplified Hero Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: Responsive.only(left: 20, right: 20, top: 10),
              child: _HeroBanner(), 
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: Responsive.h(16))),

          // Separated Animated Feature Cards Section
          SliverToBoxAdapter(
            child: Padding(
              padding: Responsive.symmetric(horizontal: 20),
              child: _FeatureRotator(),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: Responsive.h(12))), 

          // Statistics Cards - First Row
          SliverToBoxAdapter(
            child: Padding(
              padding: Responsive.symmetric(horizontal: 20),
              child: Builder(
                builder: (context) {
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
                                ? ShimmerCard(height: Responsive.h(130), borderRadius: Responsive.r(16))
                                : _buildStatCard(
                                    height: Responsive.h(130), 
                                    icon: IconlyBroken.profile,
                                    title: 'total_students'.tr,
                                    value: _formatNumber(totalStudents.toString()),
                                    color: AppColors.blue1,
                                    showAddButton: true,
                                    onAddTap: () => Get.toNamed(AppRoutes.addChildSteps),
                                  ),
                          ),
                          SizedBox(width: Responsive.w(12)), 
                          Expanded(
                            child: isLoading && totalApplications == 0
                                ? ShimmerCard(height: Responsive.h(130), borderRadius: Responsive.r(16))
                                : _buildStatCard(
                                    height: Responsive.h(130), 
                                    icon: IconlyBroken.document,
                                    title: 'total_applications'.tr,
                                    value: _formatNumber(totalApplications.toString()),
                                    color: AppColors.blue1,
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
                                    buttonColor: AppColors.blue1,
                                  ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: Responsive.h(24))), 

          // Quick Actions Section Title
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
          SliverToBoxAdapter(child: SizedBox(height: Responsive.h(12))), 
          
          // Upcoming Interviews Section
          SliverToBoxAdapter(
            child: Padding(
              padding: Responsive.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'upcoming_interviews'.tr,
                    style: AppFonts.h3.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: Responsive.sp(15),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: Responsive.h(8))), 
          
          // Upcoming Interviews List
          Builder(
            builder: (context) {
              final interviewApps = allApplications
                  .where((app) => app.interview != null && app.interview?.date != null)
                  .toList()
                ..sort((a, b) => (a.interview!.date!).compareTo(b.interview!.date!));
              
              if (controller.isLoading && interviewApps.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: Responsive.symmetric(horizontal: 20),
                    child: ShimmerCard(height: Responsive.h(80), borderRadius: Responsive.r(16)), 
                  ),
                );
              }
              
              if (interviewApps.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: Responsive.symmetric(horizontal: 20),
                    child: Container(
                      padding: Responsive.all(16), 
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
                        borderRadius: BorderRadius.circular(Responsive.r(16)),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            IconlyBroken.calendar,
                            size: Responsive.sp(40), 
                            color: AppColors.grey400,
                          ),
                          SizedBox(height: Responsive.h(8)),
                          Text(
                            'no_upcoming_interviews'.tr,
                            style: AppFonts.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
 
              return SliverPadding(
                padding: Responsive.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final app = interviewApps[index];
                      final interviewDate = app.interview!.date!;
 
                      return Padding(
                        padding: EdgeInsets.only(bottom: Responsive.h(10)),
                        child: InkWell(
                          onTap: () => Get.toNamed(AppRoutes.applicationDetails, arguments: {'applicationId': app.id}),
                          borderRadius: BorderRadius.circular(Responsive.r(16)),
                          child: Container(
                            padding: Responsive.all(12), 
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(Responsive.r(16)),
                              border: Border.all(color: AppColors.blue1.withOpacity(0.1)),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadowLight,
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: Responsive.all(10), 
                                  decoration: BoxDecoration(
                                    color: AppColors.blue1.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(Responsive.r(12)),
                                  ),
                                  child: Icon(
                                    IconlyLight.calendar,
                                    color: AppColors.blue1,
                                    size: Responsive.sp(22), 
                                  ),
                                ),
                                SizedBox(width: Responsive.w(12)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        Get.locale?.languageCode == 'ar' 
                                            ? app.school.nameAr ?? app.school.name 
                                            : app.school.name,
                                        style: AppFonts.bodyLarge.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                          fontSize: Responsive.sp(13), 
                                        ),
                                      ),
                                      SizedBox(height: Responsive.h(2)), 
                                      Text(
                                        "${DateFormat('EEEE, MMMM d', Get.locale?.languageCode).format(interviewDate)}${app.interview?.time != null ? ' ${'at'.tr} ${app.interview?.time}' : ''}",
                                        style: AppFonts.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: Responsive.sp(11),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Responsive.isRTL ? IconlyLight.arrow_left_2 : IconlyLight.arrow_right_2,
                                  color: AppColors.grey400,
                                  size: Responsive.sp(14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: interviewApps.length,
                  ),
                ),
              );
            },
          ),
          
          SliverToBoxAdapter(child: SizedBox(height: Responsive.h(16))),
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
    double? height,
  }) { 
    // Fixed height ensures both cards are exactly the same size as requested
    final cardHeight = height ?? Responsive.h(140); 
 
    return Container(
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.r(20)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Responsive.r(20)),
        child: Stack(
          children: [
            // Decorative Circle Background
            Positioned(
              right: -Responsive.w(20),
              top: -Responsive.h(20),
              child: Container(
                width: Responsive.w(100),
                height: Responsive.w(100),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.03),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            Padding(
              padding: Responsive.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon with soft background
                       Container(
                        padding: Responsive.all(8), // Reduced from 12
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(Responsive.r(12)), // Reduced from 16
                        ),
                        child: Icon(icon, color: color, size: Responsive.sp(18)), // Reduced from 22
                      ),
                      
                      // Value (Number)
                      Text(
                        value,
                        style: AppFonts.h2.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: Responsive.sp(28),
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Title
                  Text(
                    title,
                    style: AppFonts.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: Responsive.sp(14),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                   SizedBox(height: Responsive.h(8)), // Reduced from 16
 
                  // Action Button
                  if (showAddButton && onAddTap != null) ...[
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isButtonDisabled ? null : onAddTap,
                        borderRadius: BorderRadius.circular(Responsive.r(12)),
                        child: Container(
                          width: double.infinity,
                          padding: Responsive.symmetric(vertical: 6), // Reduced padding
                          decoration: BoxDecoration(
                            color: isButtonDisabled
                                ? AppColors.grey50
                                : color,
                            borderRadius: BorderRadius.circular(Responsive.r(12)),
                             gradient: isButtonDisabled ? null : LinearGradient(
                               colors: [
                                 color,
                                 color.withOpacity(0.8),
                               ],
                               begin: Alignment.topLeft,
                               end: Alignment.bottomRight,
                            ),
                            boxShadow: isButtonDisabled ? null : [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              buttonText ?? 'add'.tr,
                              style: AppFonts.bodySmall.copyWith(
                                color: isButtonDisabled
                                    ? AppColors.textSecondary
                                    : Colors.white,
                                fontSize: Responsive.sp(10), // Reduced font size
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                     if (isButtonDisabled && disabledMessage != null)
                      Padding(
                        padding: Responsive.only(top: 6),
                        child: Center(
                          child: Text(
                            disabledMessage,
                            style: AppFonts.bodySmall.copyWith(
                              color: AppColors.error,
                              fontSize: Responsive.sp(10),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ] else ...[
                     // Maintain height consistency if no button
                     SizedBox(height: Responsive.h(36)), 
                  ]
                ],
              ),
            ),
          ],
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

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E3A8A), // Deep Blue
            const Color(0xFF2563EB), // Brighter Blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Responsive.r(20)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: Responsive.all(20),
      child: Column(
        children: [
          // Header Title
          Text(
            'admission_portal'.tr,
            textAlign: TextAlign.center,
            style: AppFonts.h3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: Responsive.sp(18),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          SizedBox(height: Responsive.h(20)),
          
          // Action Button
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Responsive.r(25)),
            elevation: 3,
            shadowColor: Colors.black.withOpacity(0.15),
            child: InkWell(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const StudentSelectionSheet(),
                ).then((selectedStudent) {
                  if (selectedStudent != null && selectedStudent is Student) {
                    Get.toNamed(
                      AppRoutes.applyToSchools,
                      arguments: {'child': selectedStudent},
                    );
                  }
                });
              },
              borderRadius: BorderRadius.circular(Responsive.r(25)),
              child: Container(
                width: double.infinity,
                padding: Responsive.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'start_now'.tr,
                      style: AppFonts.bodyMedium.copyWith(
                        color: const Color(0xFF1E3A8A),
                        fontWeight: FontWeight.w900,
                        fontSize: Responsive.sp(14),
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(width: Responsive.w(8)),
                    Icon(
                      Get.locale?.languageCode == 'ar' ? IconlyBold.arrow_left_2 : IconlyBold.arrow_right_2,
                      color: const Color(0xFF1E3A8A),
                      size: Responsive.sp(16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRotator extends StatefulWidget {
  @override
  _FeatureRotatorState createState() => _FeatureRotatorState();
}

class _FeatureRotatorState extends State<_FeatureRotator> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late Timer _timer;
  late PageController _pageController;

  List<Map<String, dynamic>> get _features => [
    {
      'title': 'hero_feature_1_title'.tr,
      'subtitle': 'hero_feature_1_desc'.tr,
      'icon': IconlyBold.discovery,
      'color': const Color(0xFF6366F1),
    },
    {
      'title': 'hero_feature_2_title'.tr,
      'subtitle': 'hero_feature_2_desc'.tr,
      'icon': IconlyBold.activity,
      'color': const Color(0xFF10B981),
    },
    {
      'title': 'hero_feature_3_title'.tr,
      'subtitle': 'hero_feature_3_desc'.tr,
      'icon': IconlyBold.time_circle,
      'color': const Color(0xFFF59E0B),
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        final nextIndex = (_currentIndex + 1) % _features.length;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
        );
      } 
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> features = _features;

    return Column(
      children: [
        SizedBox(
          height: Responsive.h(90), 
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index % features.length;
              });
            },
            itemCount: features.length * 1000, // Looping effect
            itemBuilder: (context, index) {
              final featureIndex = index % features.length;
              
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
                  } else {
                    // Handle initial build where _pageController.page is null
                    value = index == 0 ? 1.0 : 0.85;
                  }
                  
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Padding(
                  padding: Responsive.symmetric(horizontal: 4),
                  child: Container(
                    padding: Responsive.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D65E8),
                      borderRadius: BorderRadius.circular(Responsive.r(20)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: Responsive.all(10),
                          decoration: BoxDecoration(
                            color: features[featureIndex]['color'].withOpacity(0.2),
                            borderRadius: BorderRadius.circular(Responsive.r(12)),
                          ),
                          child: Icon(
                            features[featureIndex]['icon'],
                            color: Colors.white,
                            size: Responsive.sp(22),
                          ),
                        ),
                        SizedBox(width: Responsive.w(15)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                features[featureIndex]['title'],
                                style: AppFonts.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: Responsive.sp(14),
                                ),
                              ),
                              SizedBox(height: Responsive.h(2)),
                              Text(
                                features[featureIndex]['subtitle'],
                                style: AppFonts.bodySmall.copyWith(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: Responsive.sp(11),
                                  height: 1.1,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        SizedBox(height: Responsive.h(12)),
        
        // Page Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(features.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: Responsive.symmetric(horizontal: 4),
              width: _currentIndex == index ? Responsive.w(18) : Responsive.w(6),
              height: Responsive.h(5),
              decoration: BoxDecoration(
                color: _currentIndex == index ? AppColors.blue1 : AppColors.grey300,
                borderRadius: BorderRadius.circular(Responsive.r(3)),
              ),
            );
          }),
        ),
      ],
    );
  }
}
