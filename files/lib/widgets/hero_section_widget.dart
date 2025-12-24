import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_fonts.dart';
import '../core/routes/app_routes.dart';

class HeroSectionWidget extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final TextEditingController? searchController;
  final bool showSearchBar;

  const HeroSectionWidget({
    Key? key,
    this.userData,
    this.searchController,
    this.showSearchBar = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;
     
    if (hour < 12) {
      greeting = 'good_morning'.tr;
      greetingIcon = Icons.wb_sunny_rounded;
    } else if (hour < 17) { 
      greeting = 'good_afternoon'.tr;
      greetingIcon = Icons.wb_twilight_rounded;
    } else {
      greeting = 'good_evening'.tr;
      greetingIcon = Icons.nightlight_round;
    }

    final userName = userData?['name'] ?? 
                    userData?['fullName'] ?? 
                    'user'.tr;

    return Container( 
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue,
            AppColors.primaryBlue.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.2),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 50.h, 20.w, showSearchBar ? 20.h : 10.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting, User Name, and Notification Icon
                Row(
                  children: [
                    Icon(
                      greetingIcon,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: AppFonts.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            userName,
                            style: AppFonts.h3.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp, 
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Icons Row
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Settings Icon
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Get.toNamed(AppRoutes.userProfile);
                            },
                            borderRadius: BorderRadius.circular(12.r),
                            child: Container(
                              width: 40.w,
                              height: 40.w,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Icon(
                                IconlyBroken.setting,
                                color: Colors.white,
                                size: 22.sp,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        // Notification Icon from Iconly
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Get.toNamed(AppRoutes.notifications);
                            },
                            borderRadius: BorderRadius.circular(12.r),
                            child: Container(
                              width: 40.w,
                              height: 40.w,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Stack(
                                alignment: Alignment.center,  
                                children: [
                                  Icon(
                                    IconlyBroken.notification,
                                    color: Colors.white,
                                    size: 22.sp,
                                  ),
                                  // Notification badge
                                  Positioned(
                                    right: 8.w,
                                    top: 8.w,
                                    child: Container(
                                      width: 8.w,
                                      height: 8.w,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(4.r),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (showSearchBar && searchController != null) ...[
                  Spacer(),
                  // Search Bar - Sticked to bottom
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: searchController,
                      style: AppFonts.bodyMedium.copyWith(fontSize: 13.sp),
                      decoration: InputDecoration(
                        hintText: 'search'.tr,
                        hintStyle: AppFonts.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13.sp,
                        ),
                        prefixIcon: Container(
                          padding: EdgeInsets.all(10.w),
                          child: Icon(IconlyBroken.search, color: AppColors.primaryBlue, size: 20.sp),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      ),
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
}

