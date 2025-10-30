import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../models/auth_models.dart';

class SetNewPasswordPage extends StatefulWidget {
  const SetNewPasswordPage({Key? key}) : super(key: key);

  @override
  State<SetNewPasswordPage> createState() => _SetNewPasswordPageState();
}

class _SetNewPasswordPageState extends State<SetNewPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _email;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String _passwordStrength = '';

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordStrength);

    // Get email from arguments
    final args = Get.arguments as Map<String, dynamic>?;
    _email = args?['email'];
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength() {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() {
        _passwordStrength = '';
      });
      return;
    }

    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    String strength;
    if (score < 3) {
      strength = 'weak';
    } else if (score < 5) {
      strength = 'medium';
    } else {
      strength = 'strong';
    }

    setState(() {
      _passwordStrength = strength;
    });
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
    return _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text;
  }

  Future<void> _setNewPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_email == null) {
        Get.snackbar(
          'error'.tr,
          'email_not_found_try_again'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
        return;
      }

      final request = SetNewPasswordRequest(
        email: _email!,
        newPassword: _passwordController.text,
      );

      final response = await AuthService.setNewPassword(request);

      if (response.success) {
        Get.snackbar(
          'success'.tr,
          'password_updated_successfully'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
        Get.offAllNamed(AppRoutes.login);
      } else {
        Get.snackbar(
          'error'.tr,
          response.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'generic_error_with_message'.tr.replaceAll('{message}', e.toString()),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with gradient
              Container(
                width: double.infinity,
                height: 320.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primaryLight,
                      AppColors.primary.withOpacity(0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30.r),
                    bottomRight: Radius.circular(30.r),
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles for unity
                    Positioned(
                      top: 40.h, right: 30.w,
                      child: Container(
                        width: 80.w, height: 80.h,
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(40.r)),
                      ),
                    ),
                    Positioned(
                      bottom: 60.h, left: 30.w,
                      child: Container(
                        width: 50.w, height: 50.h,
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(25.r)),
                      ),
                    ),
                    // Main icon and label
                    Padding(
                      padding: EdgeInsets.all(24.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 20.h),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withOpacity(0.22),
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                child: Icon(Icons.lock_reset, color: AppColors.white, size: 32.sp),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'set_new_password'.tr,
                                      style: AppFonts.cairoBold28.copyWith(color: AppColors.white),
                                    ),
                                    Text(
                                      'create_secure_password'.tr,
                                      style: AppFonts.cairoRegular16.copyWith(color: AppColors.white.withOpacity(0.88)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 32.h),
                          // Security/lock badge
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.13),
                              borderRadius: BorderRadius.circular(20.r)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.security, color: AppColors.white, size: 16.sp),
                                SizedBox(width: 8.w),
                                Text('secure_password_reset'.tr, style: AppFonts.cairoMedium14.copyWith(color: AppColors.white)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Form card
              Container(
                margin: EdgeInsets.all(20.w),
                padding: EdgeInsets.all(28.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [BoxShadow(color: AppColors.grey200, blurRadius: 20, offset: Offset(0, 10))],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'create_new_password'.tr,
                        style: AppFonts.cairoBold20.copyWith(color: AppColors.textPrimary),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'enter_your_new_password_below'.tr,
                        style: AppFonts.cairoRegular14.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 28.h),
                      // New PW field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'new_password'.tr,
                          hintText: 'enter_your_new_password'.tr,
                          prefixIcon: Container(
                            margin: EdgeInsets.all(8.w), padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.07), borderRadius: BorderRadius.circular(8.r),),
                            child: Icon(Icons.lock_outlined, color: AppColors.primary, size: 20.sp),),
                          suffixIcon: IconButton(
                            icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility, color: AppColors.primary),
                            onPressed: () { setState(() { _isPasswordVisible = !_isPasswordVisible; }); },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide(color: AppColors.grey300)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide(color: AppColors.primary, width: 2)),
                          filled: true,
                          fillColor: AppColors.grey50,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'password_required'.tr;
                          if (value.length < 6) return 'password_min_length'.tr;
                          return null;
                        },
                      ),
                      if (_passwordStrength.isNotEmpty) ...[
                        SizedBox(height: 12.h),
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: _getPasswordStrengthColor().withOpacity(0.09),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: _getPasswordStrengthColor().withOpacity(0.23)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.security, color: _getPasswordStrengthColor(), size: 16.sp),
                              SizedBox(width: 8.w),
                              Text('password_strength'.tr, style: AppFonts.cairoRegular12.copyWith(color: AppColors.textSecondary, fontSize: 12.sp)),
                              Text(_passwordStrength.tr, style: AppFonts.cairoBold12.copyWith(color: _getPasswordStrengthColor(), fontSize: 12.sp)),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 18.h),
                      // Confirm field
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: !_isConfirmPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'confirm_password'.tr,
                          hintText: 're_enter_new_password'.tr,
                          prefixIcon: Container(
                            margin: EdgeInsets.all(8.w), padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.07), borderRadius: BorderRadius.circular(8.r),),
                            child: Icon(Icons.lock_outlined, color: AppColors.primary, size: 20.sp),),
                          suffixIcon: IconButton(
                            icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility, color: AppColors.primary),
                            onPressed: () { setState(() { _isConfirmPasswordVisible = !_isConfirmPasswordVisible; }); },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide(color: AppColors.grey300)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide(color: AppColors.primary, width: 2)),
                          filled: true,
                          fillColor: AppColors.grey50,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'please_confirm_your_password'.tr;
                          if (value != _passwordController.text) return 'passwords_do_not_match'.tr;
                          return null;
                        },
                      ),
                      SizedBox(height: 28.h),
                      // Submit/Set button
                      SizedBox(
                        height: 56.h,
                        child: ElevatedButton(
                          onPressed: _isFormValid() && !_isLoading ? _setNewPassword : null,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                          ),
                          child: _isLoading
                              ? SizedBox(height: 20.h, width: 20.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_outline, color: Colors.white, size: 20.sp),
                                    SizedBox(width: 8.w),
                                    Text('set_new_password'.tr, style: AppFonts.cairoBold16.copyWith(color: Colors.white, fontSize: 16.sp)),
                                  ],
                                ),
                        ),
                      ),
                      SizedBox(height: 22.h),
                      // Back to login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('remember_your_password'.tr, style: AppFonts.cairoRegular14.copyWith(color: AppColors.textSecondary, fontSize: 14.sp)),
                          TextButton(
                            onPressed: () => Get.offAllNamed(AppRoutes.login),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
                            ),
                            child: Text('back_to_sign_in'.tr, style: AppFonts.cairoBold14.copyWith(color: AppColors.primary, fontSize: 14.sp)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
