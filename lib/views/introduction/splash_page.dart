import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/routes/app_routes.dart';
import '../../services/user_storage_service.dart';
import '../../core/controllers/app_config_controller.dart';
import '../widgets/safe_network_image.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    print('✅ SplashPage initState called');

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    print('✅ Animation started');
    _navigateToAuth();
  }

  void _navigateToAuth() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        try {
          // Check if user is logged in
          final bool isLoggedIn = UserStorageService.isLoggedIn();
          print('🔍 Login check: $isLoggedIn');

          if (isLoggedIn) {
            // User is logged in - go to home
            print('📱 User logged in - navigating to home');
            Get.offNamed<void>(AppRoutes.home);
          } else {
            // User not logged in - go to login
            print('📱 User not logged in - navigating to login');
            Get.offNamed<void>(AppRoutes.login);
          }
        } catch (e) {
          print('❌ Error in navigation: $e');
          // Fallback to login page
          Get.offNamed<void>(AppRoutes.login);
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppConfigController.to.primaryColorAsColor;
    final appName = AppConfigController.to.appName;
    final logoUrl = AppConfigController.to.lightLogoUrl;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary.withOpacity(0.1),
              AppColors.background,
              primary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with enhanced design
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.white,
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: primary.withOpacity(0.1),
                          blurRadius: 50,
                          offset: const Offset(0, 25),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Container(
                        width: 100.w,
                        height: 100.h,
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                        ),
                        child: SafeNetworkImage(
                          imageUrl: logoUrl,
                          width: 100.w,
                          height: 100.h,
                          fit: BoxFit.contain,
                          errorWidget: Container(
                            width: 80.w,
                            height: 80.h,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  primary,
                                  primary.withOpacity(0.8),
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.child_care,
                              size: 40.w,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 40.h),

                // App name with animation
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        appName,
                        style: AppFonts.cairoBold32.copyWith(
                          color: primary,
                          fontSize: 36.sp.clamp(28.sp, 40.sp),
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              color: primary.withOpacity(0.3),
                              offset: const Offset(0, 2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'management'.tr,
                        style: AppFonts.bodyLarge.copyWith(
                          color: primary.withOpacity(0.8),
                          fontSize: 16.sp.clamp(14.sp, 18.sp),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 60.h),

                // Loading indicator
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizedBox(
                    width: 40.w,
                    height: 40.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        primary.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20.h),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: TextButton(
                    onPressed: () {
                      Get.offNamed(AppRoutes.login);
                    },
                    child: Text(
                      'Debug: Go to Login',
                      style: AppFonts.bodySmall.copyWith(
                        color: primary.withOpacity(0.7),
                        fontSize: 12.sp,
                      ),
                    ),
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
