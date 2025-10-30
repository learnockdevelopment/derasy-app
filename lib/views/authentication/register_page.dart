import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'dart:ui';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/assets.dart';
import '../../core/routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../models/auth_models.dart';
import '../../core/controllers/app_config_controller.dart';
import '../widgets/safe_network_image.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String _passwordStrength = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);

    // Add listeners to all text fields to trigger UI updates
    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
    
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    final password = _passwordController.text;
    setState(() {
      _passwordStrength = _calculatePasswordStrength(password);
    });
  }

  void _validateForm() {
    setState(() {});
  }

  String _calculatePasswordStrength(String password) {
    if (password.isEmpty) return '';
    if (password.length < 6) return 'weak';
    if (password.length < 8) return 'medium';
    if (password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]'))) {
      return 'strong';
    }
    return 'medium';
  }

  Color _getPasswordStrengthColor() {
    switch (_passwordStrength) {
      case 'weak':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'strong':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  bool _isFormValid() {
    final isValid = _nameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _isValidEmail(_emailController.text) &&
        _passwordController.text == _confirmPasswordController.text;

    print('🔐 [REGISTER] Form validation: $isValid');
    print('🔐 [REGISTER] Name: ${_nameController.text.isNotEmpty}');
    print('🔐 [REGISTER] Email: ${_emailController.text.isNotEmpty}');
    print('🔐 [REGISTER] Password: ${_passwordController.text.isNotEmpty}');
    print(
        '🔐 [REGISTER] Confirm: ${_confirmPasswordController.text.isNotEmpty}');
    print('🔐 [REGISTER] Valid email: ${_isValidEmail(_emailController.text)}');
    print(
        '🔐 [REGISTER] Passwords match: ${_passwordController.text == _confirmPasswordController.text}');

    return isValid;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  Future<void> _register() async {
    print('🔐 [REGISTER] Register button pressed');
    if (!_formKey.currentState!.validate()) {
      print('🔐 [REGISTER] Form validation failed');
      return;
    }
    if (_isLoading || !_isFormValid()) {
      print('🔐 [REGISTER] Form not valid or loading');
      return;
    }

    print('🔐 [REGISTER] Starting registration process');
    setState(() {
      _isLoading = true;
    });

    try {
      final request = RegisterRequest(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final response = await AuthService.register(request);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Navigate to email verification page
      Get.toNamed(AppRoutes.verifyEmail, arguments: {
        'email': _emailController.text.trim(),
      });

      Get.snackbar(
        'Success',
        response.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
    } catch (e) {
      print('🔐 [REGISTER] Registration error: $e');

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
                    image: AssetImage(AssetsManager.register),
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
                                Icons.person_add,
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
                                'create_account'.tr,
                                style: AppFonts.cairoBold20.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'register_intro'.tr,
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
                                'create_your_account'.tr,
                                style: AppFonts.cairoBold18.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 5.h),
                              Text(
                                'join_parents_community'.tr,
                                style: AppFonts.cairoRegular12.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 24.h),

                              // Name Field
                          TextFormField(
                            controller: _nameController,
                            style: AppFonts.cairoRegular14,
                            decoration: InputDecoration(
                              labelText: 'full_name'.tr,
                              labelStyle: AppFonts.cairoRegular14,
                              hintText: 'enter_full_name'.tr,
                              hintStyle: AppFonts.cairoRegular12.copyWith(
                                color: AppColors.grey400,
                              ),
                              prefixIcon: Icon(
                                Icons.person_outlined,
                                color: AppColors.primary,
                                size: 20.sp,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide:
                                    BorderSide(color: AppColors.grey300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide(
                                  color: AppColors.primary,
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
                                return 'name_required'.tr;
                              }
                              if (value.length < 2) {
                                return 'name_min_length'.tr;
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16.h),

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
                                color: AppColors.primary,
                                size: 20.sp,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide(color: AppColors.grey300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide(
                                  color: AppColors.primary,
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
                                color: AppColors.primary,
                                size: 20.sp,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppColors.primary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide(color: AppColors.grey300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide(
                                  color: AppColors.primary,
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
                              if (value.length < 6) {
                                return 'password_too_short'.tr;
                              }
                              return null;
                            },
                          ),
                      if (_passwordStrength.isNotEmpty) ...[
                        SizedBox(height: 12.h),
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: _getPasswordStrengthColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color:
                                  _getPasswordStrengthColor().withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.security,
                                color: _getPasswordStrengthColor(),
                                size: 16.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'password_strength_label'.tr,
                                style: AppFonts.cairoRegular12.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.sp,
                                ),
                              ),
                              Text(
                                _passwordStrength.toUpperCase(),
                                style: AppFonts.cairoBold12.copyWith(
                                  color: _getPasswordStrengthColor(),
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 20.h),

                      // Confirm Password Field with enhanced design
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: !_isConfirmPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'confirm_password'.tr,
                          hintText: 're_enter_password'.tr,
                          prefixIcon: Container(
                            margin: EdgeInsets.all(8.w),
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.lock_outlined,
                              color: AppColors.primary,
                              size: 20.sp,
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.primary,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide(color: AppColors.grey300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide:
                                BorderSide(color: AppColors.primary, width: 2),
                          ),
                          filled: true,
                          fillColor: AppColors.grey50,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'confirm_password_prompt'.tr;
                          }
                          if (value != _passwordController.text) {
                            return 'passwords_no_match'.tr;
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 30.h),

                          // Register Button
                          SizedBox(
                            height: 50.h,
                            child: ElevatedButton(
                              onPressed: _isFormValid() && !_isLoading
                                  ? () {
                                      _register();
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
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
                                          Icons.person_add,
                                          color: Colors.white,
                                          size: 18.sp,
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          'create_account'.tr,
                                          style: AppFonts.cairoBold16.copyWith(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          SizedBox(height: 20.h),

                          // Sign In Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'already_have_account'.tr,
                                style: AppFonts.cairoRegular12.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Get.toNamed(AppRoutes.login);
                                },
                                child: Text(
                                  'sign_in'.tr,
                                  style: AppFonts.cairoBold12.copyWith(
                                    color: AppColors.primary,
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
