import 'package:flutter/material.dart';

import '../core/utils/responsive_utils.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_fonts.dart';
import '../core/routes/app_routes.dart';

class HeroSectionWidget extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final String? pageTitle;
  final bool showGreeting;

  const HeroSectionWidget({
    Key? key,
    this.userData,
    this.pageTitle,
    this.showGreeting = false,
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
        color: AppColors.blue1,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(Responsive.r(30)),
          bottomRight: Radius.circular(Responsive.r(30)),
        ),
      ),
      child: Stack(
        children: [
          // Decorative Background Shapes
          Positioned(
            top: -Responsive.h(50),
            right: -Responsive.w(50),
            child: Container(
              width: Responsive.w(200),
              height: Responsive.w(200),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -Responsive.h(30),
            left: -Responsive.w(30),
            child: Container(
              width: Responsive.w(150),
              height: Responsive.w(150),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.blue1,
                  AppColors.blue1.withOpacity(0.8),
                  AppColors.blue1.withOpacity(0.9),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(Responsive.r(30)),
                bottomRight: Radius.circular(Responsive.r(30)),
              ),
            ),
          ),
          // Content
          // Content
          Padding(
            padding: Responsive.only(
              left: 16, 
              top: (Responsive.isTablet || Responsive.isDesktop) ? 70 : 50, 
              right: 16, 
              bottom: (Responsive.isTablet || Responsive.isDesktop) ? 20 : 6
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive.isDesktop ? 1200 : (Responsive.isTablet ? 800 : double.infinity),
                ),
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
                            size: Responsive.sp(16),
                          ),
                          SizedBox(width: Responsive.w(6)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  greeting,
                                  style: AppFonts.bodyMedium.copyWith(
                                    color: Colors.white.withOpacity(0.95),
                                    fontSize: Responsive.sp(10),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  userName,
                                  style: AppFonts.h3.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: Responsive.sp(12), 
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
                                  fontSize: Responsive.sp(14),
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
                                borderRadius: BorderRadius.circular(Responsive.r(10)),
                                child: Container(
                                  width: Responsive.w(32),
                                  height: Responsive.w(32),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(Responsive.r(10)),
                                  ),
                                  child: Icon(
                                    IconlyBroken.setting,
                                    color: Colors.white,
                                    size: Responsive.sp(18),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: Responsive.w(6)),
                            // Notification Icon from Iconly
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Get.toNamed(AppRoutes.notifications);
                                },
                                borderRadius: BorderRadius.circular(Responsive.r(10)),
                                child: Container(
                                  width: Responsive.w(32),
                                  height: Responsive.w(32),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(Responsive.r(10)),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,  
                                    children: [
                                      Icon(
                                        IconlyBroken.notification,
                                        color: Colors.white,
                                        size: Responsive.sp(18),
                                      ),
                                      // Notification badge 
                                      Positioned(
                                        right: Responsive.w(6),
                                        top: Responsive.w(6),
                                        child: Container(
                                          width: Responsive.w(6),
                                          height: Responsive.w(6),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(Responsive.r(3)),
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 1.0,
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
                    // Action Button removed as per user request
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


