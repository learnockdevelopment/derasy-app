import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Kids Cottage',
          style: AppFonts.robotoBold24.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Add logout functionality
              Get.snackbar(
                'Logout',
                'Logout functionality will be implemented',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            icon: const Icon(Icons.logout, color: AppColors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to Kids Cottage!',
                    style:
                        AppFonts.robotoBold28.copyWith(color: AppColors.white),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Nurturing Young Minds with Care',
                    style: AppFonts.robotoRegular16.copyWith(
                      color: AppColors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Features Section
            Text(
              'Features',
              style:
                  AppFonts.robotoBold20.copyWith(color: AppColors.textPrimary),
            ),
            SizedBox(height: 16.h),

            // Feature Cards
            _buildFeatureCard(
              icon: Icons.school,
              title: 'Learning Activities',
              description: 'Engaging educational activities for children',
              color: AppColors.primary,
            ),

            SizedBox(height: 12.h),

            _buildFeatureCard(
              icon: Icons.family_restroom,
              title: 'Parent Portal',
              description: 'Stay connected with your child\'s progress',
              color: AppColors.secondary,
            ),

            SizedBox(height: 24.h),

            // Quick Actions
            Text(
              'Quick Actions',
              style:
                  AppFonts.robotoBold20.copyWith(color: AppColors.textPrimary),
            ),
            SizedBox(height: 16.h),

            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.person_add,
                    label: 'Add Child',
                    onTap: () {
                      Get.snackbar(
                        'Add Child',
                        'Add child functionality will be implemented',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.calendar_today,
                    label: 'View Schedule',
                    onTap: () {
                      Get.snackbar(
                        'View Schedule',
                        'Schedule view functionality will be implemented',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.message,
                    label: 'Messages',
                    onTap: () {
                      Get.snackbar(
                        'Messages',
                        'Messages functionality will be implemented',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.settings,
                    label: 'Settings',
                    onTap: () {
                      Get.snackbar(
                        'Settings',
                        'Settings functionality will be implemented',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.robotoBold16
                      .copyWith(color: AppColors.textPrimary),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: AppFonts.robotoRegular14
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 24.sp,
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: AppFonts.robotoMedium14
                  .copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
