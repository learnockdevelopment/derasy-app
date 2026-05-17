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

class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({Key? key}) : super(key: key);

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  late Future<TeacherModel> _profileFuture;
  TeacherModel? _profile;
  String? _selectedDay;

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
  }

  Future<void> _handleLogout() async {
    await UserStorageService.logout();
    Get.offAllNamed(AppRoutes.login);
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
                          // Elegant Dashboard Header
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: Responsive.symmetric(horizontal: 24, vertical: 16),
                              child: _buildHeader(profile, isDark),
                            ),
                          ),

                          // Quick Statistics Grid
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: Responsive.symmetric(horizontal: 24),
                              child: _buildStatsGrid(profile, isDark),
                            ),
                          ),

                          // Timetable Schedule Section
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.only(top: Responsive.h(28)),
                              child: _buildTimetableSection(profile, isDark),
                            ),
                          ),

                          // Dashboard Actions
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: Responsive.symmetric(horizontal: 24, vertical: 28),
                              child: _buildActionCards(isDark),
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Premium glassmorphic avatar with initials
        Container(
          width: Responsive.w(64),
          height: Responsive.w(64),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.salesAccent,
                AppColors.salesAccent.withOpacity(0.6),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.salesAccent.withOpacity(0.3),
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
        SizedBox(width: Responsive.w(16)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'welcome_back_message'.tr,
                style: AppFonts.AlmaraiMedium12.copyWith(color: secondaryTextColor),
              ),
              SizedBox(height: Responsive.h(2)),
              Text(
                profile.name,
                style: AppFonts.AlmaraiBold20.copyWith(color: textColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: Responsive.h(2)),
              Container(
                padding: Responsive.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.salesAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(Responsive.r(6)),
                ),
                child: Text(
                  'teacher_portal'.tr,
                  style: AppFonts.AlmaraiBold10.copyWith(color: AppColors.salesAccent),
                ),
              ),
            ],
          ),
        ),
        // Logout button
        IconButton(
          onPressed: _handleLogout,
          icon: Icon(
            IconlyLight.logout,
            color: isDark ? Colors.white70 : AppColors.textSecondary,
            size: Responsive.sp(22),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(TeacherModel profile, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B).withOpacity(0.9) : Colors.white;
    final shadowColor = isDark ? Colors.black26 : Colors.black.withOpacity(0.04);
    final borderColor = isDark ? Colors.white.withOpacity(0.06) : AppColors.grey200.withOpacity(0.8);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: Responsive.w(16),
      mainAxisSpacing: Responsive.h(16),
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          icon: IconlyBold.category,
          title: 'subjects_count'.tr,
          value: profile.subjects.length.toString(),
          color: Colors.blue,
          cardBg: cardBg,
          borderColor: borderColor,
          shadowColor: shadowColor,
        ),
        _buildStatCard(
          icon: IconlyBold.profile,
          title: 'classes_count'.tr,
          value: profile.classes.length.toString(),
          color: Colors.indigo,
          cardBg: cardBg,
          borderColor: borderColor,
          shadowColor: shadowColor,
        ),
        _buildStatCard(
          icon: IconlyBold.work,
          title: 'experience'.tr,
          value: '${profile.experienceYears} ${'years'.tr}',
          color: Colors.amber,
          cardBg: cardBg,
          borderColor: borderColor,
          shadowColor: shadowColor,
        ),
        _buildStatCard(
          icon: IconlyBold.activity,
          title: 'employment_type'.tr,
          value: profile.employmentType == 'full_time' ? 'full_time'.tr : 'part_time'.tr,
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
      padding: Responsive.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(Responsive.r(24)),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: Responsive.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: Responsive.sp(14)),
            ),
            SizedBox(height: Responsive.h(4)),
            Text(
              title,
              style: AppFonts.AlmaraiRegular10.copyWith(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: Responsive.h(2)),
            Text(
              value,
              style: AppFonts.AlmaraiBold14.copyWith(color: AppConfigController.to.isDarkMode ? Colors.white : AppColors.textPrimary),
            ),
          ],
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
