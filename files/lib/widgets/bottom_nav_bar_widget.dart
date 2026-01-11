import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/utils/responsive_utils.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_fonts.dart';
import '../core/routes/app_routes.dart';

class BottomNavBarWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBarWidget({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Responsive.r(35)),
          topRight: Radius.circular(Responsive.r(35)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: Responsive.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                icon: IconlyBroken.home,
                label: 'home'.tr,
                index: 0,
                onTap: () {
                  if (Get.currentRoute != AppRoutes.home) {
                    Get.offNamed(AppRoutes.home);
                  }
                },
              ),
              _buildNavItem(
                icon: IconlyBroken.profile,
                label: 'my_students'.tr,
                index: 1,
                onTap: () {
                  if (Get.currentRoute != AppRoutes.myStudents) {
                    Get.offNamed(AppRoutes.myStudents);
                  }
                },
              ),
              _buildNavItem(
                icon: IconlyBroken.document,
                label: 'applications'.tr,
                index: 2,
                onTap: () {
                  // Navigate to applications page without arguments to show all applications
                  Get.offNamed(AppRoutes.applications);
                },
              ),
              _buildNavItem(
                icon: IconlyBroken.bag,
                label: 'store'.tr,
                index: 3,
                onTap: () {
                  if (Get.currentRoute != AppRoutes.storeProducts) {
                    Get.offNamed(AppRoutes.storeProducts);
                  }
                },
              ),
            ],
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
    final isSelected = currentIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => this.onTap(index),
          borderRadius: BorderRadius.circular(Responsive.r(12)),
          child: Container(
            padding: Responsive.symmetric(horizontal: 2, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.primaryBlue : const Color(0xFF9CA3AF),
                  size: Responsive.sp(22),
                ),
                SizedBox(height: Responsive.h(4)),
                Flexible(
                  child: Text(
                    label,
                    style: AppFonts.labelSmall.copyWith(
                      color: isSelected ? AppColors.primaryBlue : const Color(0xFF9CA3AF),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: Responsive.sp(10),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

