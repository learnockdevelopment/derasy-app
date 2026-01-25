import 'package:derasy/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:get/get.dart';
import '../../core/constants/assets.dart';
import '../../core/routes/app_routes.dart';
import '../../services/user_storage_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _gradientController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Alignment> _beginAlignmentAnimation;
  late Animation<Alignment> _endAlignmentAnimation;

  @override
  void initState() {
    super.initState();
    print('✅ SplashPage initState called');

    // Fade animation
    _fadeController = AnimationController(
       duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // Scale animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Gradient Animation
    _gradientController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _beginAlignmentAnimation = Tween<Alignment>(
      begin: Alignment.topLeft,
      end: Alignment.bottomLeft,
    ).animate(_gradientController);
    _endAlignmentAnimation = Tween<Alignment>(
      begin: Alignment.bottomRight,
      end: Alignment.topRight,
    ).animate(_gradientController);

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
    _pulseController.repeat(reverse: true);
    _gradientController.repeat(reverse: true);
    
    print('✅ Animation started');
    _navigateToAuth();
  }

  void _navigateToAuth() async {
    // Wait for initial display
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      // Fade out logo
      await _fadeController.reverse();
      
      // Navigate after fade out
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
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _gradientController,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: _beginAlignmentAnimation.value,
                end: _endAlignmentAnimation.value,
                colors: [
                  AppColors.blue1,
                  AppColors.blue2,
                ],
              ),
            ),
            child: child,
          );
        },
        child: Stack(
          children: [
            // Animated background circles with multiple layers
            Positioned(
              top: Responsive.h(-100),
              right: Responsive.w(-100),
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: Responsive.w(300),
                      height: Responsive.h(300),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.05),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Main content
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with enhanced pulse animation
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              // Stronger pulse effect: 1.0 to 1.15
                              scale: _pulseAnimation.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.2 * (_pulseAnimation.value - 1.0) * 6),
                                      blurRadius: 30,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  AssetsManager.logo,
                                  width: Responsive.w(180),
                                  height: Responsive.w(180),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

