import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
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
        _chatButtonPosition = Offset(size.width - Responsive.w(80), size.height - Responsive.h(110));
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
                  padding: Responsive.symmetric(horizontal: 16, vertical: 8),
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
                                borderRadius: BorderRadius.circular(Responsive.r(10)),
                                child: Padding(
                                  padding: Responsive.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.language,
                                        color: primary,
                                        size: Responsive.sp(20),
                                      ),
                                      SizedBox(width: Responsive.w(6)),
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
                    padding: Responsive.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        SizedBox(height: Responsive.h(100)),
                        
                        // Logo Section with enhanced design
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              // Logo
                              Image.asset(
                                AssetsManager.logo,
                                width: Responsive.w(140),
                                height: Responsive.w(140),
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: Responsive.h(60)),
                        
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
                                SizedBox(height: Responsive.h(25)),
                                
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
                        
                        SizedBox(height: Responsive.h(100)),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Footer Links - Stick to Bottom
              Container(
                padding: Responsive.symmetric(vertical: 16),
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
                  width: Responsive.w(56),
                  height: Responsive.h(56),
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
                    size: Responsive.sp(24),
                  ),
                ),
              ),
              onDragEnd: (details) {
                setState(() {
                  final size = MediaQuery.of(context).size;
                  double newX = details.offset.dx;
                  double newY = details.offset.dy;
                  
                  // Keep button within screen bounds
                  newX = newX.clamp(0.0, size.width - Responsive.w(56));
                  newY = newY.clamp(0.0, size.height - Responsive.h(56));
                  
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
                  size: Responsive.sp(24),
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
      width: Responsive.w(200),
      height: Responsive.h(45),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: Responsive.sp(22)),
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
            borderRadius: BorderRadius.circular(Responsive.r(14)),
          ),
        ),
      ),
    );
  }
}
