import 'package:flutter/material.dart';

import '../core/utils/responsive_utils.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_fonts.dart';
import '../core/routes/app_routes.dart';
import '../models/student_models.dart';
import 'student_selection_sheet.dart';

class BottomNavBarWidget extends StatelessWidget {
  const BottomNavBarWidget({Key? key}) : super(key: key);

  int get _currentIndex {
    final route = Get.currentRoute;
    if (route == AppRoutes.home) return 0;
    if (route == AppRoutes.applications) return 1;
    if (route == AppRoutes.myStudents) return 2;
    return 0; // Default to home
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: SafeArea(
        child: Container(
          height: Responsive.h(70), // Increased height to prevent overflow
          margin: Responsive.symmetric(horizontal: 40, vertical: 10), // Increased margin for smaller width
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(Responsive.r(30)), // Fully rounded
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: Responsive.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  icon: IconlyBold.home, 
                  label: 'home'.tr,
                  index: 0,
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
                  onTap: () {
                    Get.offNamed(AppRoutes.applications);
                  },
                ),
                _buildNavItem(
                  icon: IconlyBold.profile, 
                  label: 'my_students'.tr,
                  index: 2,
                  onTap: () {
                    if (Get.currentRoute != AppRoutes.myStudents) {
                      Get.offNamed(AppRoutes.myStudents);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    VoidCallback? onTap,
  }) {
    final isSelected = _currentIndex == index;
    // Simplified item logic for smaller height
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Responsive.r(24)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: Responsive.all(isSelected ? 8 : 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.blue1.withOpacity(0.1) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon, 
                  color: isSelected ? AppColors.blue1 : Colors.black,
                  size: Responsive.sp(22), 
                ),
              ),
              // Text is now always visible
              Text(
                label,
                style: AppFonts.labelSmall.copyWith(
                  color: isSelected ? AppColors.blue1 : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: Responsive.sp(9),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            ],
          ),
        ),
      ),
    );
  }
}


