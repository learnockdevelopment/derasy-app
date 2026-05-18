import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/assets.dart';

class PulsingLogoLoader extends StatefulWidget {
  final double size;
  const PulsingLogoLoader({Key? key, this.size = 90.0}) : super(key: key);

  @override
  State<PulsingLogoLoader> createState() => _PulsingLogoLoaderState();
}

class _PulsingLogoLoaderState extends State<PulsingLogoLoader> with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double pulseSize = widget.size;
    final double logoSize = widget.size * 0.55;
    final controller = _controller;
    if (controller == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return SizedBox(
          width: pulseSize,
          height: pulseSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulse Circle 1 (Primary Accent Color)
              Opacity(
                opacity: (1.0 - controller.value) * 0.4,
                child: Container(
                  width: pulseSize * (0.5 + (controller.value * 0.5)),
                  height: pulseSize * (0.5 + (controller.value * 0.5)),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.blue1,
                  ),
                ),
              ),
              // Pulse Circle 2 (Amber Accent Color)
              Opacity(
                opacity: (1.0 - controller.value) * 0.2,
                child: Container(
                  width: pulseSize * (0.3 + (controller.value * 0.7)),
                  height: pulseSize * (0.3 + (controller.value * 0.7)),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.amber,
                  ),
                ),
              ),
              // Logo in central white circle with subtle shadow
              Container(
                width: logoSize + 16.w,
                height: logoSize + 16.w,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: EdgeInsets.all(8.w),
                child: Image.asset(
                  AssetsManager.logo,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class LoadingPrompts {
  static void showLoading({
    required String title,
    String? message,
  }) {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(28.w),
            decoration: BoxDecoration(
              color: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Loading indicator: Pulsing logo loader instead of spinner
                const PulsingLogoLoader(size: 100),
                SizedBox(height: 24.h),
                // Title
                Text(
                  title,
                  style: AppFonts.AlmaraiBold16.copyWith(
                    color: Get.isDarkMode ? Colors.white : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (message != null) ...[
                  SizedBox(height: 8.h),
                  Text(
                    message,
                    style: AppFonts.AlmaraiRegular12.copyWith(
                      color: Get.isDarkMode ? Colors.white70 : AppColors.textSecondary,
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
