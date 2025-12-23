import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';

class LoadingPrompts {
  static void showLoading({
    required String title,
    String? message,
  }) {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Container(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Loading indicator
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                  strokeWidth: 3.w,
                ),
                SizedBox(height: 20.h),
                // Title
                Text(
                  title,
                  style: AppFonts.AlmaraiBold16.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (message != null) ...[
                  SizedBox(height: 8.h),
                  Text(
                    message,
                    style: AppFonts.AlmaraiRegular14.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  static void hideLoading() {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  // Specific loading prompts for different auth flows
  static void showLoginLoading() {
    showLoading(
      title: 'Please wait',
      message: 'Signing you in...',
    );
  }

  static void showRegisterLoading() {
    showLoading(
      title: 'Please wait',
      message: 'Creating your account...',
    );
  }

  static void showVerifyCodeLoading() {
    showLoading(
      title: 'Please wait',
      message: 'Verifying your code...',
    );
  }

  static void showSetPinLoading() {
    showLoading(
      title: 'Please wait',
      message: 'Setting up your PIN...',
    );
  }

  static void showResetPinLoading() {
    showLoading(
      title: 'Please wait',
      message: 'Resetting your PIN...',
    );
  }

  static void showForgotPinLoading() {
    showLoading(
      title: 'Please wait',
      message: 'Sending verification code...',
    );
  }
}
