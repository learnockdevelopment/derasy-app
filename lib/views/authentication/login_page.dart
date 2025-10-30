import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'dart:ui';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/assets.dart';
import '../../core/routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/user_storage_service.dart';
import '../../models/auth_models.dart';
import '../../core/controllers/app_config_controller.dart';
import '../widgets/safe_network_image.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    
    // Initialize animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {});
  }

  bool _isFormValid() {
    final isValid = _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _isValidEmail(_emailController.text);

    print('🔐 [LOGIN] Form validation: $isValid');
    print('🔐 [LOGIN] Email: ${_emailController.text.isNotEmpty}');
    print('🔐 [LOGIN] Password: ${_passwordController.text.isNotEmpty}');
    print('🔐 [LOGIN] Valid email: ${_isValidEmail(_emailController.text)}');

    return isValid;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  Future<void> _login() async {
    print('🔐 [LOGIN] Login button pressed');
    if (!_formKey.currentState!.validate()) {
      print('🔐 [LOGIN] Form validation failed');
      return;
    }
    if (_isLoading || !_isFormValid()) {
      print('🔐 [LOGIN] Form not valid or loading');
      return;
    }

    print('🔐 [LOGIN] Starting login process');
    setState(() {
      _isLoading = true;
    });

    try {
      final request = LoginRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final response = await AuthService.login(request);

      if (!mounted) return;

      // Save user data
      await UserStorageService.saveCurrentUser(response.user, response.token);

      setState(() {
        _isLoading = false;
      });

      Get.offAllNamed<void>(AppRoutes.home);

      Get.snackbar(
        'Success',
        response.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
    } catch (e) {
      print('🔐 [LOGIN] Login error: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      String errorMessage = 'An unexpected error occurred. Please try again.';

      if (e is AuthException) {
        errorMessage = e.message;
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        errorMessage = 'Network error. Please check your internet connection.';
      }

      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text(
          'forgot_password'.tr,
          style: AppFonts.cairoBold18.copyWith(
            fontSize: 18.sp,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'enter_email_reset'.tr,
              style: AppFonts.cairoRegular14.copyWith(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16.h),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'email'.tr,
                hintText: 'enter_your_email'.tr,
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'email_required'.tr;
                }
                if (!_isValidEmail(value)) {
                  return 'enter_valid_email'.tr;
                }
                return null;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'cancel'.tr,
              style: AppFonts.cairoRegular14.copyWith(
                fontSize: 14.sp,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isNotEmpty &&
                  _isValidEmail(emailController.text)) {
                Get.back();
                await _sendResetPassword(emailController.text.trim());
              } else {
                Get.snackbar(
                  'Error',
                  'enter_valid_email'.tr,
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.error,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'send_reset_instructions'.tr,
              style: AppFonts.cairoBold14.copyWith(
                fontSize: 14.sp,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendResetPassword(String email) async {
    try {
      final request = ResetPasswordRequest(email: email);
      await AuthService.resetPassword(request);

      Get.toNamed(AppRoutes.verifyEmail, arguments: {
        'email': email,
        'isPasswordReset': true,
      });

      Get.snackbar(
        'Success',
        'Reset instructions sent to $email',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
    } catch (e) {
      print('🔐 [LOGIN] Reset password error: $e');

      String errorMessage =
          'Failed to send reset instructions. Please try again.';

      if (e is AuthException) {
        errorMessage = e.message;
      }

      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppConfigController.to.primaryColorAsColor;
    final logoUrl = AppConfigController.to.lightLogoUrl;

    return Scaffold(
      body: Stack(
        children: [
          // Blurred background image - fills entire page
          SizedBox.expand(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(AssetsManager.login),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          // Dark overlay for better contrast
          Container(
            color: Colors.black.withOpacity(0.3),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    SizedBox(height: 40.h),
                    
                    // Compact Logo and Title
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: SizedBox(
                            width: 28.w,
                            height: 28.h,
                            child: SafeNetworkImage(
                              imageUrl: logoUrl,
                              width: 28.w,
                              height: 28.h,
                              fit: BoxFit.contain,
                              errorWidget: Icon(
                                Icons.school,
                                color: Colors.white,
                                size: 28.sp,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'welcome_back'.tr,
                                style: AppFonts.cairoBold20.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'sign_in_to_continue'.tr,
                                style: AppFonts.cairoRegular12.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 50.h),

                    // Compact Form
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: EdgeInsets.all(24.w),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.grey200,
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Compact Form Title
                              Text(
                                'login_to_your_account'.tr,
                                style: AppFonts.cairoBold18.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 5.h),
                              Text(
                                'enter_credentials_to_access'.tr,
                                style: AppFonts.cairoRegular12.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 24.h),

                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: AppFonts.cairoRegular14,
                                decoration: InputDecoration(
                                  labelText: 'email'.tr,
                                  labelStyle: AppFonts.cairoRegular14,
                                  hintText: 'enter_your_email'.tr,
                                  hintStyle: AppFonts.cairoRegular12.copyWith(
                                    color: AppColors.grey400,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: primary,
                                    size: 20.sp,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide(color: AppColors.grey300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide(
                                      color: primary,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.grey50,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 16.h,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'email_required'.tr;
                                  }
                                  if (!_isValidEmail(value)) {
                                    return 'enter_valid_email'.tr;
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16.h),

                              // Password Field
                              TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            style: AppFonts.cairoRegular14,
                            decoration: InputDecoration(
                              labelText: 'password'.tr,
                              labelStyle: AppFonts.cairoRegular14,
                              hintText: 'password_placeholder'.tr,
                              hintStyle: AppFonts.cairoRegular12.copyWith(
                                color: AppColors.grey400,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outlined,
                                color: primary,
                                size: 20.sp,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: primary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide:
                                    BorderSide(color: AppColors.grey300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide(
                                  color: primary,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: AppColors.grey50,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 16.h,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'password_required'.tr;
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 8.h),

                          // Forgot Password Link
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                _showForgotPasswordDialog();
                              },
                              child: Text(
                                'forgot_password'.tr,
                                style: AppFonts.cairoBold12.copyWith(
                                  color: primary,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h),

                          // Login Button
                          SizedBox(
                            height: 50.h,
                            child: ElevatedButton(
                              onPressed: _isFormValid() && !_isLoading
                                  ? () {
                                      _login();
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                disabledBackgroundColor: AppColors.grey300,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 20.h,
                                      width: 20.w,
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.login,
                                          color: Colors.white,
                                          size: 18.sp,
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          'sign_in'.tr,
                                          style: AppFonts.cairoBold16.copyWith(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          SizedBox(height: 20.h),

                          // Sign Up Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'dont_have_account'.tr,
                                style: AppFonts.cairoRegular12.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Get.toNamed(AppRoutes.register);
                                },
                                child: Text(
                                  'sign_up'.tr,
                                  style: AppFonts.cairoBold12.copyWith(
                                    color: primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
