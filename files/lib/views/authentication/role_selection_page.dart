import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/assets.dart';
import '../../core/routes/app_routes.dart';
import '../../core/controllers/app_config_controller.dart';
import '../../core/controllers/language_controller.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({Key? key}) : super(key: key);

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Offset _chatButtonPosition = Offset(0, 0);

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    
    // Set initial chat button position after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      setState(() {
        _chatButtonPosition = Offset(size.width - 80.w, size.height - 110.h);
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    Get.toNamed(AppRoutes.login);
  }

  void _handleRegister() {
    Get.toNamed(AppRoutes.register);
  }

  void _toggleLanguage() {
    final languageController = LanguageController.to;
    if (languageController.isEnglish) {
      languageController.changeLanguage('ar_SA');
    } else {
      languageController.changeLanguage('en_US');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppConfigController.to.primaryColorAsColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              // Top App Bar with Language Button
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GetBuilder<LanguageController>(
                        builder: (controller) {
                          return Container(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _toggleLanguage,
                                borderRadius: BorderRadius.circular(10.r),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 8.h,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.language,
                                        color: primary,
                                        size: 20.sp,
                                      ),
                                      SizedBox(width: 6.w),
                                      Text(
                                        controller.isEnglish ? 'العربية' : 'English',
                                        style: AppFonts.AlmaraiBold14.copyWith(
                                          color: primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      children: [
                        SizedBox(height: 100.h),
                        
                        // Logo Section with enhanced design
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              // Logo
                              Image.asset(
                                AssetsManager.logo,
                                width: 140.w,
                                height: 140.w,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 60.h),
                        
                        // Buttons Section
                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              children: [
                                // Login Button
                                _buildButton(
                                  label: 'login'.tr,
                                  icon: IconlyBold.login,
                                  onPressed: _handleLogin,
                                  isPrimary: true,
                                  primary: AppColors.primaryBlue,
                                ),
                                SizedBox(height: 16.h),
                                
                                // Register Button
                                _buildButton(
                                  label: 'register'.tr,
                                  icon: IconlyBold.edit,
                                  onPressed: _handleRegister,
                                  isPrimary: false,
                                  primary: AppColors.primaryBlue,
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 100.h),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Footer Links - Stick to Bottom
              Container(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Get.snackbar(
                          'privacy_policy'.tr,
                          'privacy_policy_content'.tr,
                        );
                      },
                      child: Text(
                        'privacy_policy'.tr,
                        style: AppFonts.AlmaraiRegular12.copyWith(
                          color: AppColors.primaryPurple,
                        ),
                      ),
                    ),
                    Text(
                      ' • ',
                      style: AppFonts.AlmaraiRegular12.copyWith(
                        color: Colors.grey[400],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Get.snackbar(
                          'terms_conditions'.tr,
                          'terms_conditions_content'.tr,
                        );
                      },
                      child: Text(
                        'terms_conditions'.tr,
                        style: AppFonts.AlmaraiRegular12.copyWith(
                          color: AppColors.primaryPurple,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Draggable Floating Chat Button
          Positioned(
            left: _chatButtonPosition.dx,
            top: _chatButtonPosition.dy,
            child: Draggable(
              feedback: Material(
                color: Colors.transparent,
                child: Container(
                  width: 56.w,
                  height: 56.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary,
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    IconlyBold.chat,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: FloatingActionButton(
                  onPressed: null,
                  backgroundColor: primary,
                  elevation: 0,
                  child: Icon(
                    IconlyBold.chat,
                    color: AppColors.primaryGreen,
                    size: 24.sp,
                  ),
                ),
              ),
              onDragEnd: (details) {
                setState(() {
                  final size = MediaQuery.of(context).size;
                  double newX = details.offset.dx;
                  double newY = details.offset.dy;
                  
                  // Keep button within screen bounds
                  newX = newX.clamp(0.0, size.width - 56.w);
                  newY = newY.clamp(0.0, size.height - 56.h);
                  
                  _chatButtonPosition = Offset(newX, newY);
                });
              },
              child: FloatingActionButton(
                onPressed: () {
                  Get.toNamed(AppRoutes.chatbot);
                },
                backgroundColor: AppColors.primaryGreen,
                elevation: 6,
                child: Icon(
                  IconlyBold.chat,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isPrimary,
    required Color primary,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22.sp),
        label: Text(
          label,
          style: AppFonts.AlmaraiBold16.copyWith(
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? primary : Colors.white,
          foregroundColor: isPrimary ? Colors.white : primary,
          elevation: isPrimary ? 6 : 0,
          side: BorderSide(
            color: primary,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
      ),
    );
  }
}
