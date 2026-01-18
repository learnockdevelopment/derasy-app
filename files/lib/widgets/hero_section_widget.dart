import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/utils/responsive_utils.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_fonts.dart';
import '../core/routes/app_routes.dart';

class HeroSectionWidget extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final String? pageTitle;
  final String? actionButtonText;
  final IconData? actionButtonIcon;
  final VoidCallback? onActionTap;
  final bool showGreeting;
  final bool isButtonDisabled;
  final String? disabledMessage;

  const HeroSectionWidget({
    Key? key,
    this.userData,
    this.pageTitle,
    this.actionButtonText,
    this.actionButtonIcon,
    this.onActionTap,
    this.showGreeting = false,
    this.isButtonDisabled = false,
    this.disabledMessage,
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlue,
            AppColors.primaryBlue.withOpacity(0.9),
            AppColors.primaryGreen.withOpacity(0.85),
            AppColors.primaryGreen.withOpacity(0.75),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(Responsive.r(24)),
          bottomRight: Radius.circular(Responsive.r(24)),
        ),
      ),
      child: Stack(
        children: [
          // Content
          Padding(
            padding: Responsive.only(left: 20, top: 40, right: 20, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Greeting/Page Name and Icons
                Row(
                  children: [
                    if (showGreeting) ...[
                      Icon(
                        greetingIcon,
                        color: Colors.white,
                        size: Responsive.sp(20),
                      ),
                      SizedBox(width: Responsive.w(8)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting,
                              style: AppFonts.bodyMedium.copyWith(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: Responsive.sp(14),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              userName,
                              style: AppFonts.h3.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: Responsive.sp(14), 
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Page Name with small font
                      if (pageTitle != null)
                        Expanded(
                          child: Text(
                            pageTitle!,
                            style: AppFonts.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: Responsive.sp(16),
                            ),
                          ),
                        ),
                    ],
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
                            borderRadius: BorderRadius.circular(Responsive.r(12)),
                            child: Container(
                              width: Responsive.w(40),
                              height: Responsive.w(40),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(Responsive.r(12)),
                              ),
                              child: Icon(
                                IconlyBroken.setting,
                                color: Colors.white,
                                size: Responsive.sp(22),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: Responsive.w(8)),
                        // Notification Icon from Iconly
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Get.toNamed(AppRoutes.notifications);
                            },
                            borderRadius: BorderRadius.circular(Responsive.r(12)),
                            child: Container(
                              width: Responsive.w(40),
                              height: Responsive.w(40),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(Responsive.r(12)),
                              ),
                              child: Stack(
                                alignment: Alignment.center,  
                                children: [
                                  Icon(
                                    IconlyBroken.notification,
                                    color: Colors.white,
                                    size: Responsive.sp(22),
                                  ),
                                  // Notification badge 
                                  Positioned(
                                    right: Responsive.w(8),
                                    top: Responsive.w(8),
                                    child: Container(
                                      width: Responsive.w(8),
                                      height: Responsive.w(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(Responsive.r(4)),
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
                // Action Button (page title removed from home page)
                // Action Button
                if (actionButtonText != null && onActionTap != null) ...[
                  SizedBox(height: Responsive.h(16)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Opacity(
                      opacity: isButtonDisabled ? 0.4 : 1.0,
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(Responsive.r(14)),
                        child: InkWell(
                          onTap: isButtonDisabled ? null : onActionTap,
                          borderRadius: BorderRadius.circular(Responsive.r(14)),
                          child: Container(
                            padding: Responsive.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(Responsive.r(14)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (actionButtonIcon != null) ...[
                                  Icon(
                                    actionButtonIcon,
                                    color: AppColors.primaryBlue,
                                    size: Responsive.sp(18),
                                  ),
                                  SizedBox(width: Responsive.w(6)),
                                ],
                                Text(
                                  actionButtonText!,
                                  style: AppFonts.bodyMedium.copyWith(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: Responsive.sp(13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Disabled message below button
                  if (isButtonDisabled && disabledMessage != null) ...[
                    SizedBox(height: Responsive.h(8)),
                    Align(
                      alignment: Alignment.centerLeft, 
                      child: Text(
                        disabledMessage!,
                        style: AppFonts.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: Responsive.sp(10),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

