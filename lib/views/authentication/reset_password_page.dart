import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/assets.dart';
import '../../core/routes/app_routes.dart';
import '../../services/authentication/auth_service.dart';
import '../../models/authentication/auth_models.dart';

class ResetPasswordPage extends StatefulWidget {
  final String identifier;
  final String otp;

  const ResetPasswordPage({
    Key? key,
    required this.identifier,
    required this.otp,
  }) : super(key: key);

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    setState(() {
      _isFormValid = _isValidPassword(password) &&
          _isValidPassword(confirmPassword) &&
          password == confirmPassword;
    });
  }

  bool _isValidPassword(String password) {
    if (password.isEmpty) return false;
    return password.length >= 6;
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthService.resetPassword(
        email: widget.identifier,
        otp: widget.otp,
        password: _passwordController.text.trim(),
        passwordConfirmation: _confirmPasswordController.text.trim(),
      );

      final resetResponse = ResetPasswordResponse.fromJson(response);

      setState(() {
        _isLoading = false;
      });

      // Navigate to login page
      Get.offAllNamed<void>(AppRoutes.login);

      Get.snackbar(
        'success'.tr,
        resetResponse.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
            size: 20.w,
          ),
          onPressed: () => Get.back<void>(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),

                // Header with logo and company name
                Row(
                  children: [
                    Image.asset(
                      AssetsManager.logo,
                      width: 40.w,
                      height: 40.h,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'app_name'.tr,
                      style: AppFonts.robotoBold18.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 32.h),

                // Reset Password title
                Text(
                  'reset_password'.tr,
                  style: AppFonts.robotoBold24.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),

                SizedBox(height: 8.h),

                // Description
                Text(
                  'reset_password_description'.tr,
                  style: AppFonts.robotoRegular14.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),

                SizedBox(height: 32.h),

                // New Password Field
                _buildPasswordField(
                  controller: _passwordController,
                  label: 'new_password'.tr,
                  hint: 'new_password_placeholder'.tr,
                  isVisible: _isPasswordVisible,
                  onToggleVisibility: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
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

                SizedBox(height: 24.h),

                // Confirm Password Field
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: 'confirm_password'.tr,
                  hint: 'confirm_password_placeholder'.tr,
                  isVisible: _isConfirmPasswordVisible,
                  onToggleVisibility: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'confirm_password_required'.tr;
                    }
                    if (value != _passwordController.text.trim()) {
                      return 'passwords_do_not_match'.tr;
                    }
                    return null;
                  },
                ),

                SizedBox(height: 32.h),

                // Reset Password Button
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed:
                        (_isLoading || !_isFormValid) ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.r),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 24.w,
                            height: 24.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'reset_password'.tr,
                            style: AppFonts.robotoBold16,
                          ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Back to Login Link
                Center(
                  child: GestureDetector(
                    onTap: () => Get.offAllNamed<void>(AppRoutes.login),
                    child: Text(
                      'back_to_login'.tr,
                      style: AppFonts.robotoBold14.copyWith(
                        color: AppColors.primary,
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppFonts.robotoMedium14.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          obscureText: !isVisible,
          validator: validator,
          style: AppFonts.robotoRegular16.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppFonts.robotoRegular14.copyWith(
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: AppColors.grey100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: AppColors.error,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
            suffixIcon: GestureDetector(
              onTap: onToggleVisibility,
              child: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                color: AppColors.textSecondary,
                size: 20.w,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
