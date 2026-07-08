import 'package:flutter/material.dart';
import 'dart:ui';

import '../core/utils/responsive_utils.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../core/constants/app_fonts.dart';
import '../core/routes/app_routes.dart';
import '../core/controllers/app_config_controller.dart';

class BottomNavBarWidget extends StatelessWidget {
  const BottomNavBarWidget({Key? key}) : super(key: key);

  int get _currentIndex {
    final route = Get.currentRoute;
    if (route == AppRoutes.home) return 0;
    if (route == AppRoutes.applications) return 1;
    if (route == AppRoutes.myStudents) return 2;
    if (route == AppRoutes.storeHome) return 3;

    return 0; // Default to home
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = AppConfigController.to.isDarkMode;
      
      return Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: Responsive.isMobile ? double.infinity : 600,
          ),
          child: SafeArea(
            bottom: true,
            child: Padding(
            padding: EdgeInsets.fromLTRB(
              Responsive.w(24),
              0,
              Responsive.w(24),
              Responsive.h(12),
            ),
            child: Container(
              height: Responsive.h(70),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Responsive.r(40)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Responsive.r(40)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25), // High iPhone-style blur
                  child: Container(
                    padding: Responsive.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B).withOpacity(0.8) : Colors.white.withOpacity(0.4), // Low opacity glass
                      borderRadius: BorderRadius.circular(Responsive.r(40)),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(
                          icon: IconlyBold.home,
                          label: 'home'.tr,
                          index: 0,
                          isDark: isDark,
                          onTap: () {
                            if (Get.currentRoute != AppRoutes.home) {
                              Get.offNamed(AppRoutes.home);
                            }
                          },
                        ),
                        _buildNavItem(
                          icon: IconlyBold.document,
                          label: 'applications'.tr,
                          index: 1,
                          isDark: isDark,
                          onTap: () {
                            if (Get.currentRoute != AppRoutes.applications) {
                              Get.offNamed(AppRoutes.applications);
                            }
                          },
                        ),
                        _buildNavItem(
                          icon: IconlyBold.profile,
                          label: 'my_students'.tr,
                          index: 2,
                          isDark: isDark,
                          onTap: () {
                            if (Get.currentRoute != AppRoutes.myStudents) {
                              Get.offNamed(AppRoutes.myStudents);
                            }
                          },
                        ),
                        _buildNavItem(
                          icon: IconlyBold.buy,
                          label: 'store'.tr,
                          index: 3,
                          isDark: isDark,
                          onTap: () {
                            if (Get.currentRoute != AppRoutes.storeHome) {
                              Get.offNamed(AppRoutes.storeHome);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    });
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    final isSelected = _currentIndex == index;
    final activeColor = isDark ? Colors.white : const Color(0xFF000000); 
    final inactiveColor = isDark ? Colors.grey.shade500 : const Color(0xFF000000).withOpacity(0.45);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: Responsive.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.06)) : Colors.transparent,
                  borderRadius: BorderRadius.circular(Responsive.r(20)),
                ),
                child: Icon(
                  icon, 
                  color: isSelected ? activeColor : inactiveColor,
                  size: Responsive.sp(22), 
                ),
              ),
              SizedBox(height: Responsive.h(4)),
              Text(
                label,
                style: AppFonts.labelSmall.copyWith(
                  color: isSelected ? activeColor : inactiveColor,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  fontSize: Responsive.sp(10),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
