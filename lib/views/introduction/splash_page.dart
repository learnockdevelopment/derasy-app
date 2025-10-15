import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

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
        // Check if this is the first time opening the app
        final GetStorage storage = GetStorage();
        final bool isFirstTime = storage.read('is_first_time') ?? true;

        if (isFirstTime) {
          // First time - show intro
          storage.write('is_first_time', false);
          Get.offNamed<void>(AppRoutes.intro);
        } else {
          // Not first time - check for saved users
          final savedUsers = UserStorageService.getSavedUsers();
          // Always go to login (account switching page doesn't exist)
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Image.asset(
                AssetsManager.logo,
                width: 200.w,
                height: 200.h,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 120.w,
                    height: 120.h,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                    child: const Icon(
                      Icons.apps,
                      size: 60,
                      color: AppColors.white,
                    ),
                  );
                },
              ),
            ),
          ),
          // Removed language toggle on splash per requirements
        ],
      ),
    );
  }
}
