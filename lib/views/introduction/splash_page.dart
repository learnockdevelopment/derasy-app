import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
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
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Image.asset(
              AssetsManager.logo,
              width: 80.w,
              height: 80.h,
              fit: BoxFit.contain,
              colorBlendMode: BlendMode.multiply,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 60.w,
                  height: 60.h,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child: const Icon(
                    Icons.apps,
                    size: 30,
                    color: AppColors.white,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
