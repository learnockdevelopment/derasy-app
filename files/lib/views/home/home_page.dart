import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'dart:ui';
import '../../core/constants/assets.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../models/admission_models.dart';
import '../../models/student_models.dart';
import '../../services/user_storage_service.dart';
import '../../widgets/horizontal_swipe_detector.dart';
import '../../widgets/shimmer_loading.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/bottom_nav_bar_widget.dart';
import '../../widgets/global_chatbot_widget.dart';
import '../../core/controllers/dashboard_controller.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../widgets/hero_section_widget.dart';

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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Stack(
          children: [
            // Modern Background Elements (Glassy Blobs)
            Positioned(
              top: -Responsive.h(50),
              right: -Responsive.w(50),
              child: Container(
                width: Responsive.w(250),
                height: Responsive.w(250),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.blue1.withOpacity(0.08),
                      AppColors.blue1.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: Responsive.h(100),
              left: -Responsive.w(70),
              child: Container(
                width: Responsive.w(300),
                height: Responsive.w(300),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6366F1).withOpacity(0.06),
                      const Color(0xFF6366F1).withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            
            // Scalable Content
            HorizontalSwipeDetector(
              onSwipeRight: () {
                if (Responsive.isRTL) {
                  Get.offNamed(AppRoutes.applications);
                }
              },
              onSwipeLeft: () {
                if (!Responsive.isRTL) {
                  Get.offNamed(AppRoutes.applications);
                }
              },
              child: Obx(() => _buildHomeContent()),
            ),
            
            // Absolute Floating Modern Navbar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: const BottomNavBarWidget(),
            ),
          ],
        ),
        extendBody: true,
        bottomNavigationBar: null,
        floatingActionButton: DraggableChatbotWidget(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildHomeContent() {
    final controller = DashboardController.to;
    final allApplications = controller.allApplications;
    final isLoading = controller.isLoading &&
        allApplications.isEmpty &&
        controller.relatedChildren.isEmpty;

    if (isLoading) {
      return _buildShimmerLoading();
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.blue1,
      edgeOffset: Responsive.h(100),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Elegant Header Section
          SliverAppBar(
            expandedHeight: Responsive.h(220),
            floating: true,
            pinned: false,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: Responsive.h(70),
            collapsedHeight: Responsive.h(80),
            flexibleSpace: FlexibleSpaceBar(
              background: HeroSectionWidget(
                userData: _userData,
                showFeatures: true,
                borderRadius: 24,
              ),
            ),
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                SizedBox(height: Responsive.h(24)),
                _buildSectionHeader(
                  title: 'my_students'.tr,
                  onViewAll: () => Get.toNamed(AppRoutes.myStudents),
                  icon: IconlyBold.user_2,
                ),
                SizedBox(height: Responsive.h(12)),
                _buildStudentsCarousel(),
                
                SizedBox(height: Responsive.h(28)),
                _buildRecentApplicationsSection(),
                
                SizedBox(height: Responsive.h(28)),
                _buildUpcomingInterviewsSection(allApplications),
                SizedBox(height: Responsive.h(110)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsCarousel() {
    final children = DashboardController.to.relatedChildren;
    return SizedBox(
      height: Responsive.h(205),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: Responsive.symmetric(horizontal: 20),
        itemCount: children.length + 1,
        itemBuilder: (context, index) {
          if (index == children.length) {
            return Padding(
              padding: EdgeInsets.only(right: Responsive.w(20)),
              child: _buildAddStudentCard(),
            );
          }
          final child = children[index];
          return Padding(
            padding: EdgeInsets.only(right: Responsive.w(20)),
            child: _buildStudentCard(child),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    VoidCallback? onViewAll,
    bool showViewAll = true,
    IconData? icon,
  }) {
    return Padding(
      padding: Responsive.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: Responsive.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(Responsive.r(12)),
                  ),
                  child: Icon(icon, color: AppColors.blue1, size: Responsive.sp(18)),
                ),
                SizedBox(width: Responsive.w(12)),
              ],
              Text(
                title,
                style: AppFonts.h3.copyWith(
                  color: const Color(0xFF1F2937),
                  fontSize: Responsive.sp(18),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          if (showViewAll)
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.blue1,
                padding: Responsive.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.r(12))),
              ),
              child: Row(
                children: [
                  Text(
                    'view_all'.tr,
                    style: AppFonts.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: Responsive.sp(13),
                    ),
                  ),
                  SizedBox(width: Responsive.w(4)),
                  Icon(
                    Responsive.isRTL ? IconlyLight.arrow_left_2 : IconlyLight.arrow_right_2,
                    size: Responsive.sp(14),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Student child) {
    final bool isMale = child.gender.toLowerCase().contains('male') || child.gender.isEmpty;
    final themeColor = isMale ? AppColors.blue600 : AppColors.pink500;
    final fullName = child.arabicFullName ?? child.fullName;
    final firstName = fullName.split(' ').first;
    final bool isEnrolled = child.schoolId.id.isNotEmpty;
    final birthDate = DateTime.tryParse(child.birthDate);
    final formattedBirthDate = birthDate != null ? DateFormat.yMMMMd(Get.locale?.languageCode ?? 'en').format(birthDate) : 'N/A';
    final ageYears = (child.ageInOctober / 12).floor();

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.childDetails, arguments: {'child': child}),
      child: Container(
        width: Responsive.w(280),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Responsive.r(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Responsive.r(32)),
          child: Stack(
            children: [
              // High-End Frosted Glass Background
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(Responsive.r(32)),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              
              // Subtle Modern Tech Pattern or Gradient Corner
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: Responsive.w(120),
                  height: Responsive.w(120),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        themeColor.withOpacity(0.12),
                        themeColor.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),

              // Card Content
              Padding(
                padding: Responsive.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Modern Floating Avatar
                        Container(
                          padding: Responsive.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: themeColor.withOpacity(0.1), width: 1.5),
                          ),
                          child: CircleAvatar(
                            radius: Responsive.r(24),
                            backgroundColor: themeColor.withOpacity(0.05),
                            child: Icon(IconlyBold.profile, color: themeColor, size: Responsive.sp(22)),
                          ),
                        ),
                        SizedBox(width: Responsive.w(15)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                firstName,
                                style: AppFonts.h3.copyWith(
                                  fontSize: Responsive.sp(19),
                                  color: const Color(0xFF1E293B),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              Text(
                                '$ageYears ${'years'.tr}',
                                style: TextStyle(
                                  color: themeColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: Responsive.sp(10),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Premium Information Area
                    Container(
                      padding: Responsive.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(Responsive.r(20)),
                        border: Border.all(color: Colors.black.withOpacity(0.03)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: isEnrolled ? themeColor : Colors.grey.shade400,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isEnrolled ? themeColor : Colors.grey.shade400).withOpacity(0.3),
                                      blurRadius: 6,
                                      spreadRadius: 2,
                                    )
                                  ],
                                ),
                              ),
                              SizedBox(width: Responsive.w(10)),
                              Expanded(
                                child: Text(
                                  isEnrolled ? child.schoolId.name : 'not_enrolled'.tr,
                                  style: TextStyle(
                                    color: const Color(0xFF334155),
                                    fontWeight: FontWeight.w800,
                                    fontSize: Responsive.sp(11),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: Responsive.h(10)),
                          Row(
                            children: [
                              Icon(IconlyLight.star, size: Responsive.sp(13), color: const Color(0xFF94A3B8)),
                              SizedBox(width: Responsive.w(8)),
                              Text(
                                '${child.grade.name}${child.studentClass.name.isNotEmpty ? ' | ${child.studentClass.name}' : ''}',
                                style: TextStyle(
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w700,
                                  fontSize: Responsive.sp(10),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: Responsive.h(12)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(IconlyLight.calendar, size: Responsive.sp(12), color: const Color(0xFFCBD5E1)),
                            SizedBox(width: Responsive.w(6)),
                            Text(
                              formattedBirthDate,
                              style: TextStyle(
                                color: const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w600,
                                fontSize: Responsive.sp(9.5),
                              ),
                            ),
                          ],
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

  Widget _buildAddStudentCard() {
    final themeColor = AppColors.blue900;
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.addChildSteps),
      child: Container(
        width: Responsive.w(140),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(Responsive.r(32)),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: Responsive.w(50),
              height: Responsive.w(50),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(IconlyLight.plus, color: themeColor, size: Responsive.sp(24)),
            ),
            SizedBox(height: Responsive.h(15)),
            Text(
              'add_student'.tr,
              style: TextStyle(
                color: const Color(0xFF475569),
                fontWeight: FontWeight.w800,
                fontSize: Responsive.sp(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentApplicationsSection() {
    final controller = DashboardController.to;
    // Filter for unfinished applications
    final apps = controller.allApplications.where((app) {
      final s = app.status.toLowerCase();
      return !s.contains('completed') && 
             !s.contains('declined') && 
             !s.contains('rejected') &&
             !s.contains('success');
    }).toList();
    
    final isLoading = controller.isLoading && apps.isEmpty;

    return Column(
      children: [
        _buildSectionHeader(
          title: 'recent_applications'.tr,
          onViewAll: () => Get.toNamed(AppRoutes.applications),
          showViewAll: apps.isNotEmpty,
          icon: IconlyBold.document,
        ),
        if (isLoading)
          Padding(
            padding: Responsive.symmetric(horizontal: 24),
            child: ShimmerCard(height: Responsive.h(140), borderRadius: Responsive.r(28)),
          )
        else if (apps.isEmpty)
          Padding(
            padding: Responsive.symmetric(horizontal: 24),
            child: _buildEmptyApplicationsState(),
          )
        else
          Padding(
            padding: Responsive.symmetric(horizontal: 24, vertical: 12),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: apps.length,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(bottom: Responsive.h(12)),
                child: _buildRecentAppCard(apps[index]),
              ),
            ),
          ),
      ]);
  }

  Widget _buildRecentAppCard(Application app) {
    final statusColor = _getStatusColor(app.status);
    final hasAiReport = app.aiAssessment != null;

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.applicationDetails, arguments: {'applicationId': app.id}),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Responsive.r(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(Responsive.r(32)),
              border: Border.all(color: statusColor.withOpacity(0.18), width: 1.5),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  statusColor.withOpacity(0.12),
                  statusColor.withOpacity(0.04),
                ],
              ),
            ),
            child: Column(
              children: [
                // Premium Status Header
                Container(
                  padding: Responsive.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(Responsive.r(30))),
                  ),
                  child: Row(
                    children: [
                      Icon(IconlyBold.document, color: statusColor, size: Responsive.sp(14)),
                      SizedBox(width: Responsive.w(8)),
                      Text(
                        app.status.tr.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w900,
                          fontSize: Responsive.sp(10),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const Spacer(),
                      if (app.payment != null)
                        Container(
                          padding: Responsive.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: app.payment!.isPaid ? AppColors.blue700.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(Responsive.r(8)),
                          ),
                          child: Text(
                            app.payment!.isPaid ? 'paid'.tr : 'unpaid'.tr,
                            style: TextStyle(
                              color: app.payment!.isPaid ? AppColors.blue700 : Colors.red.shade700,
                              fontWeight: FontWeight.w900,
                              fontSize: Responsive.sp(9),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: Responsive.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  app.school.name,
                                  style: AppFonts.h3.copyWith(
                                    fontSize: Responsive.sp(16),
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: -0.4,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: Responsive.h(4)),
                                Text(
                                  '${app.child.fullName} • ${app.child.gender?.tr ?? ''}',
                                  style: TextStyle(
                                    color: const Color(0xFF64748B),
                                    fontSize: Responsive.sp(10.5),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (app.payment != null)
                            Text(
                              '${app.payment!.amount} ${'egp'.tr}',
                              style: TextStyle(
                                color: AppColors.blue900,
                                fontWeight: FontWeight.w900,
                                fontSize: Responsive.sp(15),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: Responsive.h(18)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: Responsive.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(Responsive.r(14)),
                              border: Border.all(color: Colors.white.withOpacity(0.4)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  IconlyBold.shield_done,
                                  size: Responsive.sp(13),
                                  color: hasAiReport ? AppColors.blue600 : Colors.grey.shade400,
                                ),
                                SizedBox(width: Responsive.w(8)),
                                Text(
                                  hasAiReport ? 'ai_assessment_ready'.tr : 'ai_not_found'.tr,
                                  style: TextStyle(
                                    fontSize: Responsive.sp(10.5),
                                    color: hasAiReport ? AppColors.blue700 : Colors.grey.shade600,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (app.events.isNotEmpty)
                            Container(
                              padding: Responsive.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppColors.blue1.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(Responsive.r(14)),
                              ),
                              child: Text(
                                '${app.events.length} ${'events'.tr}',  
                                style: TextStyle(
                                  color: AppColors.blue900,
                                  fontWeight: FontWeight.w900,
                                  fontSize: Responsive.sp(10),
                                ),
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
      ),
    );
  }


  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('pending')) return AppColors.blue400;
    if (s.contains('success') || s.contains('accepted')) return AppColors.blue700;
    return AppColors.blue600;
  }


  Widget _buildUpcomingInterviewsSection(List<Application> allApplications) {
    final interviewApps = allApplications
        .where((app) => app.interview != null && app.interview?.date != null)
        .toList()
      ..sort((a, b) => (a.interview!.date!).compareTo(b.interview!.date!));

    return Column(
      children: [
        _buildSectionHeader(
          title: 'upcoming_interviews'.tr,
          showViewAll: false,
          icon: IconlyBold.calendar,
        ),
        SizedBox(height: Responsive.h(16)),
        if (interviewApps.isEmpty)
          Padding(
            padding: Responsive.symmetric(horizontal: 24),
            child: _buildEmptyInterviewsState(),
          )
        else
          Padding(
            padding: Responsive.symmetric(horizontal: 24),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: interviewApps.length,
              itemBuilder: (context, index) {
                final app = interviewApps[index];
                return _buildInterviewItem(app);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildInterviewItem(Application app) {
    final interviewDate = app.interview!.date!;
    return Container(
      margin: EdgeInsets.only(bottom: Responsive.h(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.r(24)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F2937).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: InkWell(
        onTap: () => Get.toNamed(AppRoutes.applicationDetails, arguments: {'applicationId': app.id}),
        borderRadius: BorderRadius.circular(Responsive.r(24)),
        child: Padding(
          padding: Responsive.all(18),
          child: Row(
            children: [
              // Date Badge
              Container(
                padding: Responsive.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(Responsive.r(16)),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('dd').format(interviewDate),
                      style: AppFonts.h3.copyWith(color: AppColors.blue1, height: 1),
                    ),
                    Text(
                      DateFormat('MMM').format(interviewDate).toUpperCase(),
                      style: AppFonts.bodySmall.copyWith(color: AppColors.blue1, fontWeight: FontWeight.w800, fontSize: Responsive.sp(10)),
                    ),
                  ],
                ),
              ),
              SizedBox(width: Responsive.w(18)),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.school.name,
                      style: AppFonts.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1F2937),
                        fontSize: Responsive.sp(15),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: Responsive.h(4)),
                    Row(
                      children: [
                        Icon(IconlyLight.time_circle, size: Responsive.sp(14), color: const Color(0xFF9CA3AF)),
                        SizedBox(width: Responsive.w(6)),
                        Text(
                          app.interview?.time ?? '',
                          style: AppFonts.bodySmall.copyWith(
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action Icon
              Icon(
                Responsive.isRTL ? IconlyLight.arrow_left_2 : IconlyLight.arrow_right_2,
                color: const Color(0xFFD1D5DB),
                size: Responsive.sp(20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyInterviewsState() {
    return Container(
      width: double.infinity,
      padding: Responsive.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(Responsive.r(28)),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        children: [
          Icon(IconlyBroken.calendar, size: Responsive.sp(48), color: const Color(0xFFD1D5DB)),
          SizedBox(height: Responsive.h(16)),
          Text(
            'no_upcoming_interviews'.tr,
            style: AppFonts.bodyMedium.copyWith(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyApplicationsState() {
    return Container(
      width: double.infinity,
      padding: Responsive.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.r(30)),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: Responsive.all(20),
            decoration: BoxDecoration(
              color: AppColors.blue1.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(IconlyBroken.document, color: AppColors.blue1.withOpacity(0.4), size: Responsive.sp(48)),
          ),
          SizedBox(height: Responsive.h(20)),
          Text(
            'no_applications_found'.tr,
            style: AppFonts.bodyLarge.copyWith(
              fontWeight: FontWeight.w800, 
              color: const Color(0xFF1F2937),
              fontSize: Responsive.sp(16),
            ),
          ),
          SizedBox(height: Responsive.h(8)),
          Text(
            'start_admission_journey_hint'.tr, // Assuming this key might exist or can be replaced
            style: AppFonts.bodySmall.copyWith(
              color: const Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
              fontSize: Responsive.sp(12),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Responsive.h(24)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Get.toNamed(AppRoutes.applyToSchools),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue1,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: Responsive.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.r(16))),
                shadowColor: AppColors.blue1.withOpacity(0.3),
              ),
              child: Text(
                'apply_now'.tr,
                style: AppFonts.bodyMedium.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
              ),
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
          expandedHeight: Responsive.h(180),
          backgroundColor: Colors.white,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            background: ShimmerCard(height: Responsive.h(180), borderRadius: 0),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: Responsive.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerCard(height: 24, width: 120, borderRadius: 8),
                SizedBox(height: 20),
                SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    itemBuilder: (_, __) => Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: ShimmerCard(width: 130, height: 160, borderRadius: 28),
                    ),
                  ),
                ),
                SizedBox(height: 40),
                ShimmerCard(height: 24, width: 180, borderRadius: 8),
                SizedBox(height: 20),
                ShimmerCard(height: 140, borderRadius: 28),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class DashRectPainter extends CustomPainter {
  final double strokeWidth;
  final Color color;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  DashRectPainter({
    this.strokeWidth = 1.5,
    this.color = Colors.black,
    this.dashWidth = 5.0,
    this.dashSpace = 3.0,
    this.borderRadius = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    Path path = Path();
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(borderRadius),
    ));

    Path dashPath = Path();
    double distance = 0.0;
    for (PathMetric measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        dashPath.addPath(
          measurePath.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(DashRectPainter oldDelegate) => false;
}
