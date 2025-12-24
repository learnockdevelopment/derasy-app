import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/top_app_bar_widget.dart';
import '../../widgets/bottom_nav_bar_widget.dart';
import '../../services/user_storage_service.dart';

class SchoolFollowPage extends StatefulWidget {
  const SchoolFollowPage({Key? key}) : super(key: key);

  @override
  State<SchoolFollowPage> createState() => _SchoolFollowPageState();
}

class _SchoolFollowPageState extends State<SchoolFollowPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Top App Bar Widget
          TopAppBarWidget(
            userData: _userData,
            showLoading: _userData == null,
          ),
          SliverToBoxAdapter(child: SizedBox(height: 24.h)),
          // Page Title
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                'school_follow'.tr,
                style: AppFonts.h2.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 24.sp,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 8.h)),
          // Description
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                'school_follow_description'.tr,
                style: AppFonts.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 32.h)),
          // Action Buttons
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildActionCard(
                  icon: IconlyBold.discovery,
                  title: 'buses'.tr,
                  description: 'view_buses_description'.tr,
                  gradient: [
                    AppColors.primaryBlue,
                    AppColors.primaryBlue.withOpacity(0.8),
                  ],
                  onTap: () => Get.toNamed(AppRoutes.buses),
                ),
                SizedBox(height: 16.h),
                _buildActionCard(
                  icon: Icons.school_rounded,
                  title: 'teachers'.tr,
                  description: 'view_teachers_description'.tr,
                  gradient: [
                    const Color(0xFF667EEA),
                    const Color(0xFF764BA2),
                  ],
                  onTap: () => Get.toNamed(AppRoutes.teachers),
                ),
              ]),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 32.h)),
        ],
      ),
      bottomNavigationBar: BottomNavBarWidget(
        currentIndex: 2,
        onTap: (index) {},
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String description,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                // Icon Container
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 32.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppFonts.h3.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(0, 2),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        description,
                        style: AppFonts.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13.sp,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                // Arrow Icon
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 18.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

