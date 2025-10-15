import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/assets.dart';
import '../../core/routes/app_routes.dart';
import '../../services/user_storage_service.dart';

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
    _navigateToIntro();
  }

  void _navigateToIntro() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // Check if user is logged in
        final bool isLoggedIn = UserStorageService.isLoggedIn();
        print('🔍 Login check: $isLoggedIn');

        if (isLoggedIn) {
          // User is logged in - go to home
          print('📱 User logged in - navigating to home');
          Get.offNamed<void>(AppRoutes.home);
        } else {
          // User not logged in - always show intro
          print('📱 User not logged in - navigating to intro');
          Get.offNamed<void>(AppRoutes.intro);
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
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.background,
              AppColors.primary.withOpacity(0.05),
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
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.1),
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
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          AssetsManager.logo,
                          width: 100.w,
                          height: 100.h,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            print('❌ Primary logo loading error: $error');
                            return Container(
                              width: 80.w,
                              height: 80.h,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withOpacity(0.8),
                                  ],
                                ),
                              ),
                              child: Icon(
                                Icons.child_care,
                                size: 40.w,
                                color: AppColors.white,
                              ),
                            );
                          },
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
                        'Kids Cottage',
                        style: AppFonts.robotoBold32.copyWith(
                          color: AppColors.primary,
                          fontSize: 36.sp.clamp(28.sp, 40.sp),
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              color: AppColors.primary.withOpacity(0.3),
                              offset: Offset(0, 2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Nurturing Young Minds',
                        style: AppFonts.bodyLarge.copyWith(
                          color: AppColors.primary.withOpacity(0.8),
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
                  child: Container(
                    width: 40.w,
                    height: 40.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),

                // Debug button (remove in production)
                SizedBox(height: 20.h),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: TextButton(
                    onPressed: () {
                      print('🔍 [DEBUG] Direct navigation to login');
                      Get.offNamed(AppRoutes.login);
                    },
                    child: Text(
                      'Debug: Go to Login',
                      style: AppFonts.bodySmall.copyWith(
                        color: AppColors.primary.withOpacity(0.7),
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
