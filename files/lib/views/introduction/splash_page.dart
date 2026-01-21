import 'package:derasy/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:get/get.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/assets.dart';
import '../../core/routes/app_routes.dart';
import '../../services/user_storage_service.dart';
import '../../core/controllers/app_config_controller.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  String _appName = 'Derasy';

  @override
  void initState() {
    super.initState();
    print('✅ SplashPage initState called');
    
    // Get app name safely - defer to after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateAppName();
    });

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

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
    _pulseController.repeat(reverse: true);
    
    print('✅ Animation started');
    _navigateToAuth();
  }

  void _updateAppName() {
    if (!mounted) return;
    try {
      if (Get.isRegistered<AppConfigController>()) {
        final controller = Get.find<AppConfigController>();
        final name = controller.appName;
        if (name.isNotEmpty && name != 'xx') {
          if (mounted) {
            setState(() {
              _appName = name;
            });
          }
        }
      }
    } catch (e) {
      // Silently fail - use default 'Derasy'
      print('⚠️ Could not get app name: $e');
    }
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
            // User not logged in - go to role selection
            print('📱 User not logged in - navigating to role selection');
            Get.offNamed<void>(AppRoutes.roleSelection);
          }
        } catch (e) {
          print('❌ Error in navigation: $e');
          // Fallback to role selection page
          Get.offNamed<void>(AppRoutes.roleSelection);
        }
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
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
              AppColors.primaryBlue,
              AppColors.primaryPurple,
              AppColors.primaryGreen,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
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
                            AppColors.primaryPurple.withOpacity(0.2),
                            AppColors.primaryBlue.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: Responsive.h(-150),
              left: Responsive.w(-150),
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 / _pulseAnimation.value,
                    child: Container(
                      width: Responsive.w(400),
                      height: Responsive.h(400),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primaryGreen.withOpacity(0.2),
                            AppColors.primaryBlue.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Additional decorative circles
            Positioned(
              top: Responsive.h(100),
              left: Responsive.w(-50),
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.8 + (_pulseAnimation.value - 1.0) * 0.2,
                    child: Container(
                      width: Responsive.w(200),
                      height: Responsive.h(200),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryPurple.withOpacity(0.15),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: Responsive.h(150),
              right: Responsive.w(-80),
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.7 + (1.0 / _pulseAnimation.value - 1.0) * 0.3,
                    child: Container(
                      width: Responsive.w(250),
                      height: Responsive.h(250),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryGreen.withOpacity(0.15),
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
                    // Logo with enhanced design
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 1.0 + (_pulseAnimation.value - 1.0) * 0.1,
                              child: Image.asset(
                                AssetsManager.logo,
                                width: Responsive.w(120),
                                height: Responsive.w(120),
                                fit: BoxFit.contain,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: Responsive.h(50)),

                    // App name with animation
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Text(
                            _appName,
                                style: AppFonts.AlmaraiBold32.copyWith(
                                  color: Colors.white,
                                  fontSize: Responsive.sp(42).clamp(Responsive.sp(32), Responsive.sp(48)),
                                  letterSpacing: 1.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(0, 4),
                                      blurRadius: 12,
                                    ),
                                    Shadow(
                                      color: AppColors.primaryGreen.withOpacity(0.6),
                                      offset: const Offset(0, 2),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                          SizedBox(height: Responsive.h(12)),
                          Container(
                            padding: Responsive.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryPurple.withOpacity(0.3),
                                  AppColors.primaryBlue.withOpacity(0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(Responsive.r(20)),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'splash_subtitle'.tr,
                              style: AppFonts.bodyLarge.copyWith(
                                color: Colors.white,
                                fontSize: Responsive.sp(16).clamp(Responsive.sp(14), Responsive.sp(18)),
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: Responsive.h(80)),

                    // Loading indicator with modern design
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Container(
                            width: Responsive.w(56),
                            height: Responsive.h(56),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.25),
                                  Colors.white.withOpacity(0.15),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: Responsive.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 3.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                backgroundColor: Colors.white.withOpacity(0.25),
                              ),
                            ),
                          ),
                          SizedBox(height: Responsive.h(16)),
                          Text(
                            'splash_loading'.tr,
                            style: AppFonts.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
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
