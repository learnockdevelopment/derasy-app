import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/controllers/app_config_controller.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/routes/app_routes.dart';
import '../../models/teacher_models.dart';
import '../../services/teacher_service.dart';
import '../../services/user_storage_service.dart';
import '../../widgets/loading_page.dart';
import '../../services/store_service.dart';

class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({Key? key}) : super(key: key);

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  late Future<TeacherModel> _profileFuture;
  TeacherModel? _profile;
  String? _selectedDay;
  List<TeacherJobApplication> _applications = [];
  TeacherRecruitmentStats? _recruitmentStats;
  int _cartCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final user = UserStorageService.getCurrentUser();
    setState(() {
      _profileFuture = TeacherService.getTeacherProfile(user?.id ?? 'teacher_123');
    });

    StoreService.getCart().then((cart) {
      if (mounted) {
        setState(() {
          _cartCount = cart.itemCount;
        });
      }
    }).catchError((e) {
      print('🛒 [TEACHER_HOME] Error loading cart count: $e');
    });

    _profileFuture.then((profile) {
      if (mounted) {
        setState(() {
          _profile = profile;
          if (profile.timetable.isNotEmpty) {
            final weekdayName = DateTime.now().weekday == 1 ? 'Monday' 
                : DateTime.now().weekday == 2 ? 'Tuesday'
                : DateTime.now().weekday == 3 ? 'Wednesday'
                : DateTime.now().weekday == 4 ? 'Thursday'
                : DateTime.now().weekday == 5 ? 'Friday'
                : DateTime.now().weekday == 6 ? 'Saturday' : 'Sunday';
            
            final profileDays = profile.timetable.map((t) => t.day).toSet();
            if (profileDays.contains(weekdayName)) {
              _selectedDay = weekdayName;
            } else {
              _selectedDay = profile.timetable.first.day;
            }
          }
        });
      }
    });

    TeacherService.getMyApplications().then((apps) {
      if (mounted) {
        setState(() {
          _applications = apps;
        });
      }
    });

    TeacherService.getRecruitmentStats().then((stats) {
      if (mounted) {
        setState(() {
          _recruitmentStats = stats;
        });
      }
    });
  }

  Future<void> _handleLogout() async {
    final isDark = AppConfigController.to.isDarkMode;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.r(20))),
        title: Text(
          'logout'.tr,
          style: AppFonts.AlmaraiBold16.copyWith(
            color: isDark ? Colors.white : Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'confirm_logout'.tr,
          style: AppFonts.AlmaraiRegular12.copyWith(
            color: isDark ? Colors.white70 : Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.r(10))),
            ),
            child: Text(
              'cancel'.tr,
              style: TextStyle(color: isDark ? Colors.white70 : AppColors.textPrimary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await UserStorageService.logout();
              Get.offAllNamed(AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.r(10))),
            ),
            child: Text(
              'logout'.tr,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final config = AppConfigController.to;
      final isDark = config.isDarkMode;
      final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
      final accentColor = AppColors.salesAccent;

      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: bgColor,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: bgColor,
          body: Stack(
            children: [
              // Premium Background Blobs
              Positioned(
                top: -Responsive.h(80),
                right: -Responsive.w(80),
                child: Container(
                  width: Responsive.w(280),
                  height: Responsive.w(280),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accentColor.withOpacity(0.09),
                        accentColor.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: Responsive.h(120),
                left: -Responsive.w(90),
                child: Container(
                  width: Responsive.w(320),
                  height: Responsive.w(320),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF6366F1).withOpacity(0.08),
                        const Color(0xFF6366F1).withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),

              // Main Content
              FutureBuilder<TeacherModel>(
                future: _profileFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && _profile == null) {
                    return const LoadingPage();
                  }

                  final profile = snapshot.data ?? _profile;
                  if (profile == null) {
                    return Center(child: Text('failed_to_load_user_data'.tr));
                  }

                  return SafeArea(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        _loadProfile();
                      },
                      color: accentColor,
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          // 1. Elegant Dashboard Header
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: Responsive.symmetric(horizontal: 24, vertical: 16),
                              child: _buildHeader(profile, isDark),
                            ),
                          ),

                          // 2. Store Section
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: Responsive.h(24)),
                              child: _buildStoreSection(isDark),
                            ),
                          ),

                          // 3. Timetable Schedule Section
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: Responsive.h(28)),
                              child: _buildTimetableSection(profile, isDark),
                            ),
                          ),

                          // 4. Careers Section (stats & cv)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: Responsive.h(28)),
                              child: _buildCareersSection(profile, isDark),
                            ),
                          ),

                          // 5. Applications Section (stats, apps list, jobs hub button)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: Responsive.h(28)),
                              child: _buildApplicationsSection(isDark),
                            ),
                          ),

                          // Bottom padding
                          SliverToBoxAdapter(
                            child: SizedBox(height: Responsive.h(40)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHeader(TeacherModel profile, bool isDark) {
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryTextColor = isDark ? Colors.white60 : AppColors.textSecondary;
    final cardBg = isDark ? const Color(0xFF1E293B).withOpacity(0.5) : Colors.white.withOpacity(0.7);
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05);

    return Container(
      padding: Responsive.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(Responsive.r(28)),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Premium glassmorphic avatar with initials and ring glow
          GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.userProfile),
            child: Container(
              width: Responsive.w(64),
              height: Responsive.w(64),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.salesAccent,
                    AppColors.salesAccent.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.salesAccent.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  profile.name.isNotEmpty ? profile.name.trim().substring(0, 1).toUpperCase() : 'T',
                  style: AppFonts.AlmaraiBold24.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
          SizedBox(width: Responsive.w(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(IconlyBold.discovery, color: AppColors.salesAccent, size: 14),
                    SizedBox(width: Responsive.w(4)),
                    Text(
                      'welcome_back_message'.tr,
                      style: AppFonts.AlmaraiMedium12.copyWith(color: secondaryTextColor),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.h(4)),
                Text(
                  profile.name,
                  style: AppFonts.AlmaraiBold20.copyWith(color: textColor, letterSpacing: -0.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: Responsive.h(6)),
                Container(
                  padding: Responsive.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.salesAccent.withOpacity(0.15), AppColors.salesAccent.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(Responsive.r(30)),
                    border: Border.all(color: AppColors.salesAccent.withOpacity(0.2), width: 1),
                  ),
                  child: Text(
                    'teacher_portal'.tr,
                    style: AppFonts.AlmaraiBold10.copyWith(color: AppColors.salesAccent),
                  ),
                ),
              ],
            ),
          ),
          // Cart Button
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => Get.toNamed(AppRoutes.storeCart)?.then((_) => _loadProfile()),
                  icon: Icon(
                    IconlyLight.buy,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                    size: Responsive.sp(20),
                  ),
                ),
              ),
              if (_cartCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
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
          SizedBox(width: Responsive.w(8)),
          // Logout button styled elegantly
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _handleLogout,
              icon: Icon(
                IconlyLight.logout,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                size: Responsive.sp(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreSection(bool isDark) {
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final cardBg = isDark ? const Color(0xFF1E293B).withOpacity(0.6) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.06) : AppColors.grey200.withOpacity(0.8);
    final shadowColor = isDark ? Colors.black26 : Colors.black.withOpacity(0.03);

    return Padding(
      padding: Responsive.symmetric(horizontal: 24),
      child: Container(
        padding: Responsive.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(Responsive.r(28)),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(color: shadowColor, blurRadius: 15, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: Responsive.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.salesAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(Responsive.r(12)),
                  ),
                  child: const Icon(IconlyBold.buy, color: AppColors.salesAccent, size: 18),
                ),
                SizedBox(width: Responsive.w(12)),
                Text(
                  'derasy_store'.tr.isNotEmpty ? 'derasy_store'.tr : 'Derasy Store',
                  style: AppFonts.AlmaraiBold16.copyWith(color: textColor, letterSpacing: -0.5),
                ),
              ],
            ),
            SizedBox(height: Responsive.h(12)),
            Text(
              'store_desc'.tr.isNotEmpty 
                  ? 'store_desc'.tr 
                  : 'Upgrade your classroom with premium tools, stationery, and hardware synced with your official school account.',
              style: AppFonts.AlmaraiRegular12.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            SizedBox(height: Responsive.h(16)),
            ElevatedButton(
              onPressed: () => Get.toNamed(AppRoutes.storeHome)?.then((_) => _loadProfile()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.salesAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.r(16))),
                padding: Responsive.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 44),
                elevation: 0,
              ),
              child: Text(
                'explore_store'.tr.isNotEmpty ? 'explore_store'.tr : 'Explore Store',
                style: AppFonts.AlmaraiBold12.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareersSection(TeacherModel profile, bool isDark) {
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white12 : AppColors.grey300;

    return Padding(
      padding: Responsive.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: Responsive.all(6),
                decoration: BoxDecoration(
                  color: AppColors.salesAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(Responsive.r(8)),
                ),
                child: const Icon(IconlyBold.work, color: AppColors.salesAccent, size: 16),
              ),
              SizedBox(width: Responsive.w(10)),
              Text(
                'careers'.tr,
                style: AppFonts.AlmaraiBold14.copyWith(color: textColor),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(14)),
          
          _buildActionCard(
            icon: IconlyLight.document,
            title: profile.hasCv ? 'edit_cv'.tr : 'add_cv'.tr,
            subtitle: profile.hasCv ? 'edit_cv_desc'.tr : 'cv_profile_desc'.tr,
            color: AppColors.salesAccent,
            cardBg: cardBg,
            borderColor: borderColor,
            shadowColor: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
            onTap: () => Get.toNamed(AppRoutes.teacherCvProfile)?.then((_) => _loadProfile()),
          ),
        ],
      ),
    );
  }

  Widget _buildCareerStatsSection(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B).withOpacity(0.6) : Colors.white;
    final shadowColor = isDark ? Colors.black26 : Colors.black.withOpacity(0.03);
    final borderColor = isDark ? Colors.white.withOpacity(0.06) : AppColors.grey200.withOpacity(0.8);

    return Container(
      width: double.infinity,
      padding: Responsive.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(Responsive.r(28)),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: 15, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCareerMetricItem(
              icon: IconlyBold.star,
              title: 'experience'.tr,
              value: '${_profile?.experienceYears ?? 0} ${'years'.tr}',
              color: Colors.amber,
              isDark: isDark,
            ),
          ),
          Container(
            width: 1,
            height: Responsive.h(40),
            color: isDark ? Colors.white12 : AppColors.grey200,
          ),
          Expanded(
            child: _buildCareerMetricItem(
              icon: IconlyBold.wallet,
              title: 'expected_salary'.tr,
              value: '${_profile?.salary.toStringAsFixed(0) ?? '0'} EGP',
              color: Colors.teal,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareerMetricItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Container(
          padding: Responsive.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: Responsive.h(10)),
        Text(
          title,
          style: AppFonts.AlmaraiBold10.copyWith(color: AppColors.textSecondary),
        ),
        SizedBox(height: Responsive.h(4)),
        Text(
          value,
          style: AppFonts.AlmaraiBold16.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildApplicationsSection(bool isDark) {
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white12 : AppColors.grey300;

    return Padding(
      padding: Responsive.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: Responsive.all(6),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(Responsive.r(8)),
                ),
                child: const Icon(IconlyBold.work, color: Colors.purple, size: 16),
              ),
              SizedBox(width: Responsive.w(10)),
              Text(
                'applications'.tr,
                style: AppFonts.AlmaraiBold14.copyWith(color: textColor),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(14)),
          
          if (_recruitmentStats != null) ...[
            _buildAppsDashboardStats(isDark),
            SizedBox(height: Responsive.h(16)),
          ],

          _buildRecentApplicationsSection(isDark),
          SizedBox(height: Responsive.h(16)),

          _buildActionCard(
            icon: IconlyLight.discovery,
            title: 'jobs_you_can_apply'.tr,
            subtitle: 'explore_latest_teacher_jobs'.tr,
            color: Colors.teal,
            cardBg: cardBg,
            borderColor: borderColor,
            shadowColor: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
            onTap: () => Get.toNamed(AppRoutes.teacherJobsHub),
          ),
        ],
      ),
    );
  }

  Widget _buildAppsDashboardStats(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B).withOpacity(0.6) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.06) : AppColors.grey200.withOpacity(0.8);
    final shadowColor = isDark ? Colors.black26 : Colors.black.withOpacity(0.03);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: Responsive.w(14),
      mainAxisSpacing: Responsive.h(14),
      childAspectRatio: 1.45,
      children: [
        _buildStatCard(
          icon: IconlyBold.document,
          title: 'applied_jobs'.tr,
          value: _recruitmentStats!.appliedJobsCount.toString(),
          color: Colors.blue,
          cardBg: cardBg,
          borderColor: borderColor,
          shadowColor: shadowColor,
        ),
        _buildStatCard(
          icon: IconlyBold.show,
          title: 'interviews'.tr,
          value: _recruitmentStats!.interviewsCount.toString(),
          color: Colors.purple,
          cardBg: cardBg,
          borderColor: borderColor,
          shadowColor: shadowColor,
        ),
        _buildStatCard(
          icon: IconlyBold.star,
          title: 'shortlisted'.tr,
          value: _recruitmentStats!.shortlistedCount.toString(),
          color: Colors.orange,
          cardBg: cardBg,
          borderColor: borderColor,
          shadowColor: shadowColor,
        ),
        _buildStatCard(
          icon: IconlyBold.ticket,
          title: 'hired'.tr,
          value: _recruitmentStats!.hiredCount.toString(),
          color: Colors.teal,
          cardBg: cardBg,
          borderColor: borderColor,
          shadowColor: shadowColor,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Color cardBg,
    required Color borderColor,
    required Color shadowColor,
  }) {
    return Container(
      padding: Responsive.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(Responsive.r(24)),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: SizedBox(
          width: Responsive.w(135),
          height: Responsive.h(75),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: Responsive.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: Responsive.sp(14)),
                  ),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: color.withOpacity(0.6), blurRadius: 4, spreadRadius: 1),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.AlmaraiBold10.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: Responsive.h(2)),
                  Text(
                    value,
                    style: AppFonts.AlmaraiBold18.copyWith(
                      color: AppConfigController.to.isDarkMode ? Colors.white : AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimetableSection(TeacherModel profile, bool isDark) {
    final titleColor = isDark ? Colors.white : AppColors.textPrimary;
    final cardBg = isDark ? const Color(0xFF1E293B).withOpacity(0.9) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.06) : AppColors.grey200.withOpacity(0.8);
    final shadowColor = isDark ? Colors.black26 : Colors.black.withOpacity(0.04);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Section Title
        Padding(
          padding: Responsive.symmetric(horizontal: 24),
          child: Row(
            children: [
              Container(
                padding: Responsive.all(6),
                decoration: BoxDecoration(
                  color: AppColors.salesAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Responsive.r(8)),
                ),
                child: const Icon(IconlyBold.calendar, color: AppColors.salesAccent, size: 16),
              ),
              SizedBox(width: Responsive.w(10)),
              Text(
                'my_timetable'.tr,
                style: AppFonts.AlmaraiBold14.copyWith(color: titleColor),
              ),
            ],
          ),
        ),
        SizedBox(height: Responsive.h(16)),

        if (profile.timetable.isEmpty)
          Padding(
            padding: Responsive.symmetric(horizontal: 24),
            child: Container(
              width: double.infinity,
              padding: Responsive.all(24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(Responsive.r(24)),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: Center(
                child: Text(
                  'no_classes_assigned'.tr,
                  style: AppFonts.AlmaraiRegular12.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ),
          )
        else ...[
          // 2. Interactive Horizontal Weekday Selector Bubbles
          (() {
            final order = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
            final days = order.where((day) => profile.timetable.any((t) => t.day.toLowerCase() == day.toLowerCase())).toList();
            
            if (_selectedDay == null && days.isNotEmpty) {
              _selectedDay = days.first;
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: Responsive.symmetric(horizontal: 20),
              child: Row(
                children: days.map((day) {
                  final isSelected = _selectedDay == day;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDay = day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: EdgeInsets.symmetric(horizontal: Responsive.w(4)),
                      padding: Responsive.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [AppColors.salesAccent, AppColors.salesAccent.withOpacity(0.85)],
                              )
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
                            : [
                                BoxShadow(
                                  color: shadowColor,
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ],
                      ),
                      child: Text(
                        day.toLowerCase().tr,
                        style: isSelected
                            ? AppFonts.AlmaraiBold12.copyWith(color: Colors.white)
                            : AppFonts.AlmaraiMedium12.copyWith(color: isDark ? Colors.white70 : AppColors.textSecondary),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }()),
          SizedBox(height: Responsive.h(20)),

          // 3. Vertical Timeline List of Classes for Selected Day
          (() {
            final dayClasses = profile.timetable.where((t) => t.day == _selectedDay).toList();

            if (dayClasses.isEmpty) {
              return Padding(
                padding: Responsive.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: Responsive.all(24),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(Responsive.r(24)),
                    border: Border.all(color: borderColor),
                  ),
                  child: Center(
                    child: Text(
                      'no_classes_assigned'.tr,
                      style: AppFonts.AlmaraiRegular12.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              );
            }

            return Padding(
              padding: Responsive.symmetric(horizontal: 24),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dayClasses.length,
                separatorBuilder: (context, index) => SizedBox(height: Responsive.h(14)),
                itemBuilder: (context, index) {
                  final item = dayClasses[index];
                  final accentColors = [Colors.indigo, Colors.teal, Colors.amber.shade700, Colors.pink, const Color(0xFF10B981)];
                  final themeColor = accentColors[index % accentColors.length];

                  return Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(Responsive.r(20)),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(color: shadowColor, blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left side colorful identifier stripe
                          Container(
                            width: Responsive.w(6),
                            decoration: BoxDecoration(
                              color: themeColor,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(Responsive.isRTL ? 0 : Responsive.r(20)),
                                bottomLeft: Radius.circular(Responsive.isRTL ? 0 : Responsive.r(20)),
                                topRight: Radius.circular(Responsive.isRTL ? Responsive.r(20) : 0),
                                bottomRight: Radius.circular(Responsive.isRTL ? Responsive.r(20) : 0),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: Responsive.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.subject,
                                          style: AppFonts.AlmaraiBold14.copyWith(color: isDark ? Colors.white : AppColors.textPrimary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: Responsive.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: themeColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(Responsive.r(8)),
                                        ),
                                        child: Text(
                                          item.gradeLevel,
                                          style: AppFonts.AlmaraiBold10.copyWith(color: themeColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: Responsive.h(10)),
                                  Row(
                                    children: [
                                      Icon(IconlyLight.time_circle, size: Responsive.sp(14), color: AppColors.textSecondary),
                                      SizedBox(width: Responsive.w(6)),
                                      Text(
                                        '${item.startTime} - ${item.endTime}',
                                        style: AppFonts.AlmaraiRegular12.copyWith(color: AppColors.textSecondary),
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
            );
          }()),
        ],
      ],
    );
  }

  Widget _buildActionCards(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B).withOpacity(0.9) : Colors.white;
    final shadowColor = isDark ? Colors.black26 : Colors.black.withOpacity(0.04);
    final borderColor = isDark ? Colors.white.withOpacity(0.06) : AppColors.grey200.withOpacity(0.8);

    return _buildActionCard(
      icon: IconlyLight.work,
      title: 'jobs'.tr,
      subtitle: 'manage_jobs_cv'.tr,
      color: AppColors.salesAccent,
      cardBg: cardBg,
      borderColor: borderColor,
      shadowColor: shadowColor,
      onTap: () => Get.toNamed(AppRoutes.teacherJobsHub),
    );
  }

  Widget _buildRecentApplicationsSection(bool isDark) {
    if (_applications.isEmpty) {
      return const SizedBox.shrink();
    }

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final textSecondaryColor = isDark ? Colors.grey.shade400 : AppColors.textSecondary;
    final borderColor = isDark ? Colors.white12 : AppColors.grey300;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(Responsive.r(24)),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: Responsive.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: Responsive.all(6),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(Responsive.r(8)),
                ),
                child: const Icon(
                  IconlyLight.work,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
              SizedBox(width: Responsive.w(10)),
              Text(
                'recent_applications'.tr,
                style: AppFonts.AlmaraiBold14.copyWith(
                  color: textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(16)),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _applications.length,
            separatorBuilder: (context, index) => Padding(
              padding: Responsive.symmetric(vertical: 10),
              child: Divider(color: borderColor, height: 1),
            ),
            itemBuilder: (context, index) {
              final app = _applications[index];
              
              Color statusColor = AppColors.salesAccent;
              if (app.status.toLowerCase().contains('shortlist')) {
                statusColor = Colors.orange;
              } else if (app.status.toLowerCase().contains('accept') || app.status.toLowerCase().contains('hire')) {
                statusColor = Colors.teal;
              } else if (app.status.toLowerCase().contains('reject')) {
                statusColor = Colors.red;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          app.jobTitle,
                          style: AppFonts.AlmaraiBold12.copyWith(color: textColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: Responsive.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(Responsive.r(12)),
                        ),
                        child: Text(
                          app.status.tr,
                          style: AppFonts.AlmaraiBold10.copyWith(color: statusColor),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.h(4)),
                  Text(
                    app.schoolName,
                    style: AppFonts.AlmaraiRegular10.copyWith(color: textSecondaryColor),
                  ),
                  SizedBox(height: Responsive.h(10)),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(Responsive.r(4)),
                          child: LinearProgressIndicator(
                            value: app.progress,
                            backgroundColor: isDark ? Colors.white10 : AppColors.grey200,
                            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                            minHeight: Responsive.h(6),
                          ),
                        ),
                      ),
                      SizedBox(width: Responsive.w(12)),
                      Text(
                        '${(app.progress * 100).toInt()}%',
                        style: AppFonts.AlmaraiBold10.copyWith(color: textSecondaryColor),
                      ),
                    ],
                  ),
                  if (app.interview != null)
                    _buildInterviewDetailsCard(
                      app.interview!,
                      cardBg,
                      borderColor,
                      textColor,
                      textSecondaryColor,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInterviewDetailsCard(
    TeacherInterview interview,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color textSecondaryColor,
  ) {
    return Container(
      margin: EdgeInsets.only(top: Responsive.h(12)),
      padding: Responsive.all(12),
      decoration: BoxDecoration(
        color: AppColors.salesAccent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(Responsive.r(12)),
        border: Border.all(color: AppColors.salesAccent.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(IconlyBold.calendar, color: AppColors.salesAccent, size: 16),
              SizedBox(width: Responsive.w(8)),
              Text(
                'interview_details'.tr,
                style: AppFonts.AlmaraiBold12.copyWith(color: AppColors.salesAccent),
              ),
              const Spacer(),
              Container(
                padding: Responsive.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.salesAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(Responsive.r(8)),
                ),
                child: Text(
                  interview.type.tr,
                  style: AppFonts.AlmaraiBold10.copyWith(color: AppColors.salesAccent),
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(10)),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(IconlyLight.calendar, size: 14, color: textSecondaryColor),
                    SizedBox(width: Responsive.w(4)),
                    Text(
                      interview.date.length >= 10 ? interview.date.substring(0, 10) : interview.date,
                      style: AppFonts.AlmaraiRegular10.copyWith(color: textColor),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Icon(IconlyLight.time_circle, size: 14, color: textSecondaryColor),
                    SizedBox(width: Responsive.w(4)),
                    Text(
                      interview.time,
                      style: AppFonts.AlmaraiRegular10.copyWith(color: textColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (interview.meetingLink.isNotEmpty) ...[
            SizedBox(height: Responsive.h(8)),
            InkWell(
              onTap: () => print('Open Link: ${interview.meetingLink}'),
              child: Row(
                children: [
                  const Icon(IconlyLight.video, size: 14, color: Colors.blue),
                  SizedBox(width: Responsive.w(4)),
                  Expanded(
                    child: Text(
                      interview.meetingLink,
                      style: AppFonts.AlmaraiRegular10.copyWith(color: Colors.blue, decoration: TextDecoration.underline),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (interview.notes.isNotEmpty) ...[
            SizedBox(height: Responsive.h(8)),
            Divider(color: AppColors.salesAccent.withOpacity(0.1), height: 1),
            SizedBox(height: Responsive.h(6)),
            Text(
              '${'notes'.tr}: ${interview.notes}',
              style: AppFonts.AlmaraiRegular10.copyWith(color: textSecondaryColor),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color cardBg,
    required Color borderColor,
    required Color shadowColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: Responsive.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(Responsive.r(28)),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(color: shadowColor, blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: Responsive.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(Responsive.r(16)),
              ),
              child: Icon(icon, color: color, size: Responsive.sp(22)),
            ),
            SizedBox(width: Responsive.w(16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.AlmaraiBold14.copyWith(color: AppConfigController.to.isDarkMode ? Colors.white : AppColors.textPrimary),
                  ),
                  SizedBox(height: Responsive.h(4)),
                  Text(
                    subtitle,
                    style: AppFonts.AlmaraiRegular10.copyWith(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Responsive.isRTL ? IconlyLight.arrow_left_2 : IconlyLight.arrow_right_2,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
