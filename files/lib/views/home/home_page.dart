import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import '../../core/controllers/app_config_controller.dart';
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
    return Obx(() {
      final isDark = AppConfigController.to.isDarkMode;
      final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

      return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: bgColor,
            body: Stack(
              children: [
                // Ambient background blobs
                Positioned(
                  top: -Responsive.h(40),
                  right: -Responsive.w(60),
                  child: Container(
                    width: Responsive.w(280),
                    height: Responsive.w(280),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.blue1.withOpacity(isDark ? 0.06 : 0.10),
                          AppColors.blue1.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: Responsive.h(120),
                  left: -Responsive.w(80),
                  child: Container(
                    width: Responsive.w(320),
                    height: Responsive.w(320),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF6366F1).withOpacity(isDark ? 0.05 : 0.07),
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

                // Floating Navbar
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
          ));
    });
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

    final isDark = AppConfigController.to.isDarkMode;

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.blue1,
      edgeOffset: Responsive.h(100),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero Header
          SliverAppBar(
            expandedHeight: Responsive.h(170),
            floating: true,
            pinned: false,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: Responsive.h(60),
            collapsedHeight: Responsive.h(70),
            flexibleSpace: FlexibleSpaceBar(
              background: HeroSectionWidget(
                userData: _userData,
                showFeatures: true,
                borderRadius: 24,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: Responsive.h(20)),

                // ── Quick Stats Row ──────────────────────────────────
                _buildQuickStats(isDark),

                SizedBox(height: Responsive.h(28)),

                // ── My Children ─────────────────────────────────────
                _buildSectionHeader(
                  title: 'my_students'.tr,
                  onViewAll: () => Get.toNamed(AppRoutes.myStudents),
                  icon: IconlyBold.user_2,
                  isDark: isDark,
                ),
                SizedBox(height: Responsive.h(14)),
                _buildStudentsCarousel(isDark),

                SizedBox(height: Responsive.h(32)),

                // ── Recent Applications ──────────────────────────────
                _buildRecentApplicationsSection(isDark),

                SizedBox(height: Responsive.h(24)),

                // ── Upcoming Interviews ──────────────────────────────
                _buildUpcomingInterviewsSection(allApplications, isDark),

                SizedBox(height: Responsive.h(110)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Quick Stats Row
  // ─────────────────────────────────────────────────────────
  Widget _buildQuickStats(bool isDark) {
    final controller = DashboardController.to;
    final childCount = controller.relatedChildren.length;
    final appCount = controller.allApplications.length;
    final interviewCount = controller.allApplications
        .where((a) => a.interview != null && a.interview?.date != null)
        .length;

    return Padding(
      padding: Responsive.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildStatPill(
            isDark: isDark,
            icon: IconlyBold.user_2,
            label: 'my_students'.tr,
            value: '$childCount',
            color: AppColors.blue600,
            onTap: () => Get.toNamed(AppRoutes.myStudents),
          ),
          SizedBox(width: Responsive.w(10)),
          _buildStatPill(
            isDark: isDark,
            icon: IconlyBold.document,
            label: 'applications'.tr,
            value: '$appCount',
            color: const Color(0xFF8B5CF6),
            onTap: () => Get.toNamed(AppRoutes.applications),
          ),
          SizedBox(width: Responsive.w(10)),
          _buildStatPill(
            isDark: isDark,
            icon: IconlyBold.calendar,
            label: 'upcoming_interviews'.tr,
            value: '$interviewCount',
            color: const Color(0xFF059669),
            onTap: null,
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    final bg = isDark
        ? const Color(0xFF1E293B)
        : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.07) : color.withOpacity(0.12);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: Responsive.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(Responsive.r(20)),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(isDark ? 0.06 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: Responsive.all(7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(Responsive.r(10)),
                ),
                child: Icon(icon, color: color, size: Responsive.sp(14)),
              ),
              SizedBox(height: Responsive.h(8)),
              Text(
                value,
                style: AppFonts.AlmaraiBold20.copyWith(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  height: 1.0,
                ),
              ),
              SizedBox(height: Responsive.h(2)),
              Text(
                label,
                style: AppFonts.AlmaraiRegular10.copyWith(
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Section Header
  // ─────────────────────────────────────────────────────────
  Widget _buildSectionHeader({
    required String title,
    VoidCallback? onViewAll,
    bool showViewAll = true,
    IconData? icon,
    required bool isDark,
  }) {
    return Padding(
      padding: Responsive.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: Responsive.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(Responsive.r(11)),
                  ),
                  child: Icon(icon,
                      color: AppColors.blue1, size: Responsive.sp(15)),
                ),
                SizedBox(width: Responsive.w(10)),
              ],
              Text(
                title,
                style: AppFonts.AlmaraiBold16.copyWith(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
          if (showViewAll && onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: Container(
                padding:
                    Responsive.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(Responsive.r(12)),
                ),
                child: Row(
                  children: [
                    Text(
                      'view_all'.tr,
                      style: AppFonts.AlmaraiBold10.copyWith(
                        color: AppColors.blue1,
                      ),
                    ),
                    SizedBox(width: Responsive.w(3)),
                    Icon(
                      Responsive.isRTL
                          ? IconlyLight.arrow_left_2
                          : IconlyLight.arrow_right_2,
                      size: Responsive.sp(11),
                      color: AppColors.blue1,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Students Carousel
  // ─────────────────────────────────────────────────────────
  Widget _buildStudentsCarousel(bool isDark) {
    final children = DashboardController.to.relatedChildren;
    return SizedBox(
      height: Responsive.w(118),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: Responsive.symmetric(horizontal: 20),
        itemCount: children.length + 1,
        itemBuilder: (context, index) {
          if (index == children.length) {
            return Padding(
              padding: EdgeInsets.only(right: Responsive.w(12)),
              child: _buildAddStudentCard(isDark),
            );
          }
          final child = children[index];
          return Padding(
            padding: EdgeInsets.only(right: Responsive.w(12)),
            child: _buildStudentCard(child, isDark),
          );
        },
      ),
    );
  }

  Widget _buildStudentCard(Student child, bool isDark) {
    final bool isMale =
        child.gender.toLowerCase().contains('male') || child.gender.isEmpty;
    final themeColor = isMale ? AppColors.blue600 : AppColors.pink500;
    final fullName = child.arabicFullName ?? child.fullName;
    final firstName = fullName.split(' ').first;
    final bool isEnrolled = child.schoolId.id.isNotEmpty;
    final ageYears = (child.ageInOctober / 12).floor();

    return GestureDetector(
      onTap: () =>
          Get.toNamed(AppRoutes.childDetails, arguments: {'child': child}),
      child: Container(
        width: Responsive.w(108),
        height: Responsive.w(118),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B)
              : Colors.white,
          borderRadius: BorderRadius.circular(Responsive.r(26)),
          border: Border.all(
            color: isEnrolled
                ? themeColor.withOpacity(isDark ? 0.3 : 0.2)
                : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: themeColor.withOpacity(isDark ? 0.08 : 0.07),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar with enrollment ring
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: Responsive.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isEnrolled
                          ? themeColor.withOpacity(0.4)
                          : Colors.grey.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: Responsive.r(23),
                    backgroundColor: themeColor.withOpacity(0.12),
                    child: Icon(IconlyBold.profile,
                        color: themeColor, size: Responsive.sp(21)),
                  ),
                ),
                Container(
                  width: Responsive.w(11),
                  height: Responsive.w(11),
                  decoration: BoxDecoration(
                    color: isEnrolled ? themeColor : Colors.grey.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      width: 1.8,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.h(9)),
            // Name
            Padding(
              padding: Responsive.symmetric(horizontal: 8),
              child: Text(
                firstName,
                style: AppFonts.AlmaraiBold14.copyWith(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: Responsive.h(4)),
            // Age badge
            Container(
              padding: Responsive.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(Responsive.r(8)),
              ),
              child: Text(
                '$ageYears ${'years'.tr}',
                style: TextStyle(
                  color: themeColor,
                  fontWeight: FontWeight.w700,
                  fontSize: Responsive.sp(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddStudentCard(bool isDark) {
    final color = AppColors.blue900;
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.addChildSteps),
      child: Container(
        width: Responsive.w(108),
        height: Responsive.w(118),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B).withOpacity(0.8)
              : Colors.white,
          borderRadius: BorderRadius.circular(Responsive.r(26)),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : const Color(0xFFE2E8F0),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: Responsive.w(40),
              height: Responsive.w(40),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.15), width: 1.5),
              ),
              child: Icon(IconlyLight.plus,
                  color: color, size: Responsive.sp(18)),
            ),
            SizedBox(height: Responsive.h(10)),
            Text(
              'add_student'.tr,
              style: TextStyle(
                color: isDark ? Colors.white60 : const Color(0xFF475569),
                fontWeight: FontWeight.w700,
                fontSize: Responsive.sp(11),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Recent Applications Section
  // ─────────────────────────────────────────────────────────
  Widget _buildRecentApplicationsSection(bool isDark) {
    final controller = DashboardController.to;
    final apps = controller.allApplications.where((app) {
      final s = app.status.toLowerCase();
      return !s.contains('completed') &&
          !s.contains('declined') &&
          !s.contains('rejected') &&
          !s.contains('success');
    }).toList();

    final isLoading = controller.isLoading && apps.isEmpty;

    return Column(children: [
      _buildSectionHeader(
        title: 'recent_applications'.tr,
        onViewAll: () => Get.toNamed(AppRoutes.applications),
        showViewAll: apps.isNotEmpty,
        icon: IconlyBold.document,
        isDark: isDark,
      ),
      SizedBox(height: Responsive.h(14)),
      if (isLoading)
        Padding(
          padding: Responsive.symmetric(horizontal: 20),
          child: ShimmerCard(
              height: Responsive.h(150), borderRadius: Responsive.r(28)),
        )
      else if (apps.isEmpty)
        Padding(
          padding: Responsive.symmetric(horizontal: 20),
          child: _buildEmptyApplicationsState(isDark),
        )
      else
        Padding(
          padding: Responsive.symmetric(horizontal: 20),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: apps.length,
            separatorBuilder: (_, __) => SizedBox(height: Responsive.h(12)),
            itemBuilder: (context, index) => _buildRecentAppCard(apps[index], isDark),
          ),
        ),
    ]);
  }

  Widget _buildRecentAppCard(Application app, bool isDark) {
    final statusColor = _getStatusColor(app.status);
    final hasAiReport = app.aiAssessment != null;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = statusColor.withOpacity(isDark ? 0.25 : 0.18);

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.applicationDetails,
          arguments: {'applicationId': app.id}),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(Responsive.r(28)),
          border: Border.all(color: borderColor, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(isDark ? 0.08 : 0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Status Banner
            Container(
              padding: Responsive.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(isDark ? 0.12 : 0.07),
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(Responsive.r(27))),
              ),
              child: Row(
                children: [
                  Container(
                    width: Responsive.w(8),
                    height: Responsive.w(8),
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: Responsive.w(8)),
                  Text(
                    app.status.tr.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w900,
                      fontSize: Responsive.sp(9.5),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  if (app.payment != null)
                    Container(
                      padding: Responsive.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: app.payment!.isPaid
                            ? AppColors.blue700.withOpacity(0.12)
                            : Colors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(Responsive.r(8)),
                      ),
                      child: Text(
                        app.payment!.isPaid ? 'paid'.tr : 'unpaid'.tr,
                        style: TextStyle(
                          color: app.payment!.isPaid
                              ? AppColors.blue700
                              : Colors.red.shade600,
                          fontWeight: FontWeight.w900,
                          fontSize: Responsive.sp(9),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: Responsive.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // School Icon
                      Container(
                        padding: Responsive.all(10),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(Responsive.r(14)),
                        ),
                        child: Icon(IconlyBold.discovery,
                            color: statusColor, size: Responsive.sp(18)),
                      ),
                      SizedBox(width: Responsive.w(12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.school.name,
                              style: AppFonts.AlmaraiBold16.copyWith(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                letterSpacing: -0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: Responsive.h(3)),
                            Text(
                              '${app.child.fullName} • ${app.child.gender?.tr ?? ''}',
                              style: AppFonts.AlmaraiRegular12.copyWith(
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (app.payment != null)
                        Text(
                          '${app.payment!.amount} ${'egp'.tr}',
                          style: AppFonts.AlmaraiBold16.copyWith(
                            color: AppColors.blue700,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: Responsive.h(14)),
                  // Bottom row: AI badge + events
                  Row(
                    children: [
                      // AI Badge
                      Container(
                        padding: Responsive.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: hasAiReport
                              ? AppColors.blue600.withOpacity(0.08)
                              : (isDark
                                  ? Colors.white.withOpacity(0.04)
                                  : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(Responsive.r(10)),
                          border: Border.all(
                            color: hasAiReport
                                ? AppColors.blue600.withOpacity(0.2)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              IconlyBold.shield_done,
                              size: Responsive.sp(12),
                              color: hasAiReport
                                  ? AppColors.blue600
                                  : Colors.grey.shade400,
                            ),
                            SizedBox(width: Responsive.w(6)),
                            Text(
                              hasAiReport
                                  ? 'ai_assessment_ready'.tr
                                  : 'ai_not_found'.tr,
                              style: TextStyle(
                                fontSize: Responsive.sp(10),
                                color: hasAiReport
                                    ? AppColors.blue700
                                    : Colors.grey.shade500,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (app.events.isNotEmpty)
                        Container(
                          padding: Responsive.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.blue1.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(Responsive.r(10)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(IconlyBold.calendar,
                                  size: Responsive.sp(11),
                                  color: AppColors.blue700),
                              SizedBox(width: Responsive.w(4)),
                              Text(
                                '${app.events.length} ${'events'.tr}',
                                style: TextStyle(
                                  color: isDark ? AppColors.blue2 : AppColors.blue900,
                                  fontWeight: FontWeight.w800,
                                  fontSize: Responsive.sp(10),
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
    );
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('pending')) return AppColors.blue400;
    if (s.contains('success') || s.contains('accepted'))
      return AppColors.blue700;
    return AppColors.blue600;
  }

  // ─────────────────────────────────────────────────────────
  //  Upcoming Interviews Section
  // ─────────────────────────────────────────────────────────
  Widget _buildUpcomingInterviewsSection(
      List<Application> allApplications, bool isDark) {
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
          isDark: isDark,
        ),
        SizedBox(height: Responsive.h(16)),
        if (interviewApps.isEmpty)
          Padding(
            padding: Responsive.symmetric(horizontal: 20),
            child: _buildEmptyInterviewsState(isDark),
          )
        else
          Padding(
            padding: Responsive.symmetric(horizontal: 20),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: interviewApps.length,
              separatorBuilder: (_, __) => SizedBox(height: Responsive.h(12)),
              itemBuilder: (context, index) {
                final app = interviewApps[index];
                return _buildInterviewItem(app, isDark);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildInterviewItem(Application app, bool isDark) {
    final interviewDate = app.interview!.date!;
    final now = DateTime.now();
    final diff = interviewDate.difference(now).inDays;
    final accentColor = diff <= 1
        ? Colors.red.shade500
        : diff <= 3
            ? Colors.orange.shade600
            : AppColors.blue600;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.applicationDetails,
          arguments: {'applicationId': app.id}),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(Responsive.r(24)),
          border: Border.all(
            color: accentColor.withOpacity(isDark ? 0.2 : 0.15),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(isDark ? 0.07 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: Responsive.all(16),
          child: Row(
            children: [
              // Date Badge
              Container(
                padding: Responsive.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withOpacity(0.15),
                      accentColor.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(Responsive.r(16)),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('dd').format(interviewDate),
                      style: AppFonts.AlmaraiBold20.copyWith(
                        color: accentColor,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      DateFormat('MMM').format(interviewDate).toUpperCase(),
                      style: AppFonts.AlmaraiBold10.copyWith(
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: Responsive.w(14)),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.school.name,
                      style: AppFonts.AlmaraiBold14.copyWith(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: Responsive.h(4)),
                    Row(
                      children: [
                        Icon(IconlyLight.time_circle,
                            size: Responsive.sp(13),
                            color: const Color(0xFF9CA3AF)),
                        SizedBox(width: Responsive.w(5)),
                        Text(
                          app.interview?.time ?? '',
                          style: AppFonts.AlmaraiRegular12.copyWith(
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Countdown chip
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: Responsive.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(Responsive.r(10)),
                    ),
                    child: Text(
                      diff == 0
                          ? 'today'.tr
                          : diff == 1
                              ? 'tomorrow'.tr
                              : '$diff ${'days'.tr}',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w800,
                        fontSize: Responsive.sp(9.5),
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.h(6)),
                  Icon(
                    Responsive.isRTL
                        ? IconlyLight.arrow_left_2
                        : IconlyLight.arrow_right_2,
                    color: const Color(0xFFD1D5DB),
                    size: Responsive.sp(16),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Empty States
  // ─────────────────────────────────────────────────────────
  Widget _buildEmptyInterviewsState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: Responsive.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(Responsive.r(26)),
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: Responsive.all(16),
            decoration: BoxDecoration(
              color: AppColors.blue1.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(IconlyBroken.calendar,
                size: Responsive.sp(40),
                color: AppColors.blue1.withOpacity(0.5)),
          ),
          SizedBox(height: Responsive.h(14)),
          Text(
            'no_upcoming_interviews'.tr,
            style: AppFonts.AlmaraiBold14.copyWith(
              color: isDark ? Colors.white70 : const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyApplicationsState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: Responsive.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(Responsive.r(28)),
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFFE2E8F0),
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: Responsive.all(20),
            decoration: BoxDecoration(
              color: AppColors.blue1.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(IconlyBroken.document,
                color: AppColors.blue1.withOpacity(0.45),
                size: Responsive.sp(46)),
          ),
          SizedBox(height: Responsive.h(18)),
          Text(
            'no_applications_found'.tr,
            style: AppFonts.AlmaraiBold16.copyWith(
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: Responsive.h(8)),
          Text(
            'start_admission_journey_hint'.tr,
            style: AppFonts.AlmaraiRegular12.copyWith(
              color: const Color(0xFF9CA3AF),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Responsive.h(22)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.applyToSchools),
              icon: Icon(IconlyLight.arrow_right_2,
                  color: Colors.white, size: Responsive.sp(16)),
              label: Text(
                'apply_now'.tr,
                style: AppFonts.AlmaraiBold14.copyWith(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue1,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: Responsive.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Responsive.r(16))),
                shadowColor: AppColors.blue1.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Shimmer Loading
  // ─────────────────────────────────────────────────────────
  Widget _buildShimmerLoading() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: Responsive.h(180),
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            background:
                ShimmerCard(height: Responsive.h(180), borderRadius: 0),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: Responsive.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats row shimmer
                Row(
                  children: List.generate(
                    3,
                    (_) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: Responsive.w(10)),
                        child: ShimmerCard(height: Responsive.h(88), borderRadius: 20),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: Responsive.h(28)),
                ShimmerCard(height: 22, width: 120, borderRadius: 8),
                SizedBox(height: Responsive.h(16)),
                SizedBox(
                  height: Responsive.w(118),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    itemBuilder: (_, __) => Padding(
                      padding: EdgeInsets.only(right: Responsive.w(12)),
                      child: ShimmerCard(
                          width: Responsive.w(108),
                          height: Responsive.w(118),
                          borderRadius: 26),
                    ),
                  ),
                ),
                SizedBox(height: Responsive.h(32)),
                ShimmerCard(height: 22, width: 160, borderRadius: 8),
                SizedBox(height: Responsive.h(16)),
                ShimmerCard(height: Responsive.h(150), borderRadius: 28),
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
      Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth,
          size.height - strokeWidth),
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
