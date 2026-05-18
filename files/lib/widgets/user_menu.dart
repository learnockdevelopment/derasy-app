import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/routes/app_routes.dart';
import '../../core/controllers/app_config_controller.dart';
import '../../services/user_storage_service.dart';

class UserMenu extends StatelessWidget {
  final String fullName;
  final String email;

  const UserMenu({
    Key? key,
    required this.fullName,
    required this.email,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Responsive.w(200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.r(12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // User Info Header
          Container(
            padding: Responsive.all(16),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(Responsive.r(12)),
                topRight: Radius.circular(Responsive.r(12)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: AppFonts.AlmaraiBold14.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: Responsive.h(4)),
                Text(
                  email,
                  style: AppFonts.AlmaraiRegular12.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: Responsive.h(1),
            color: AppColors.grey200,
          ),

          // Menu Items
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Responsive.r(8)),
        child: Container(
          padding: Responsive.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: Responsive.w(20),
                color: AppColors.textSecondary,
              ),
              SizedBox(width: Responsive.w(12)),
              Text(
                title,
                style: AppFonts.AlmaraiRegular14.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
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
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Clear user data
              UserStorageService.clearCurrentUser();
              // Navigate to login page
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
}

