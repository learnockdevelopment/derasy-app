import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/assets.dart';
import '../../core/routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/user_storage_service.dart';
import '../../models/auth_models.dart';
import '../../models/user.dart';
import '../../core/controllers/app_config_controller.dart';
import '../../../widgets/safe_network_image.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({Key? key}) : super(key: key);

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _isResending = false;
  int _resendCountdown = 0;
  String _email = '';
  bool _isPasswordReset = false;

  @override
  void initState() {
    super.initState();
    _email = Get.arguments?['email'] ?? '';
    _isPasswordReset = Get.arguments?['isPasswordReset'] ?? false;
    _startResendCountdown();

    // Add listener to OTP field to trigger UI updates
    _otpController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendCountdown--;
        });
        return _resendCountdown > 0;
      }
      return false;
    });
  }

  void _validateForm() {
    setState(() {});
  }

  Future<void> _verifyEmail() async {
    print('🔐 [VERIFY] Verify button pressed');
    if (!_formKey.currentState!.validate()) {
      print('🔐 [VERIFY] Form validation failed');
      return;
    }
    if (_isLoading) {
      print('🔐 [VERIFY] Already loading');
      return;
    }

    print('🔐 [VERIFY] Starting verification process');
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isPasswordReset) {
        // Handle password reset OTP verification
        final request = VerifyResetOtpRequest(
          email: _email,
          otp: _otpController.text.trim(),
        );

        final response = await AuthService.verifyResetOtp(request);

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        if (response.success) {
          // Navigate to set new password page
          Get.toNamed(AppRoutes.setNewPassword, arguments: {
            'email': _email,
          });
          Get.snackbar(
            'Success',
            response.message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.primaryBlue,
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            'Error',
            response.message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.error,
            colorText: Colors.white,
          );
        }
      } else {
        // Handle email verification
        final request = VerifyEmailRequest(
          email: _email,
          otp: _otpController.text.trim(),
        );

        final response = await AuthService.verifyEmail(request);

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        if (response.correct) {
          // Save user data and token
          await UserStorageService.saveCurrentUser(
            User(
              id: '',
              name: '',
              email: _email,
              role: 'parent',
            ),
            response.token,
          );

          Get.offAllNamed<void>(AppRoutes.home);
          Get.snackbar(
            'Success',
            response.message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.primaryBlue,
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            'Error',
            response.message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.error,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      print('🔐 [VERIFY_EMAIL] Verification error: $e');

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

  Future<void> _resendOtp() async {
    if (_isResending || _resendCountdown > 0) return;

    setState(() {
      _isResending = true;
    });

    try {
      final request = ResendVerificationRequest(email: _email);
      final response = await AuthService.resendVerification(request);

      if (!mounted) return;

      setState(() {
        _isResending = false;
      });

      _startResendCountdown();

      Get.snackbar(
        'Success',
        response.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primaryBlue,
        colorText: Colors.white,
      );
    } catch (e) {
      print('🔐 [VERIFY_EMAIL] Resend error: $e');

      if (!mounted) return;

      setState(() {
        _isResending = false;
      });

      String errorMessage =
          'Failed to resend verification code. Please try again.';

      if (e is AuthException) {
        errorMessage = e.message;
      }

      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Blurred cover background
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
          Container(
            color: Colors.black.withOpacity(0.35),
          ),
          // Foreground content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    SizedBox(height: 40.h),
                    // Logo and Title row (identical structure as login)
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: SizedBox(
                            width: 28.w,
                            height: 28.h,
                            child: SafeNetworkImage(
                              imageUrl: AppConfigController.to.lightLogoUrl,
                              width: 28.w,
                              height: 28.h,
                              fit: BoxFit.contain,
                              errorWidget: Icon(
                                Icons.verified_user,
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
                                _isPasswordReset ? 'reset_password'.tr : 'verify_email'.tr,
                                style: AppFonts.AlmaraiBold12.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                _isPasswordReset ? 'reset_code_sent_message'.tr : 'verification_intro_message'.tr,
                                style: AppFonts.AlmaraiBold12.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 50.h),
                    // Verification Card
                    Container(
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.grey200,
                            blurRadius: 15,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'enter_verification_code'.tr,
                              style: AppFonts.AlmaraiBold12.copyWith(color: AppColors.textPrimary),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 5.h),
                            Text(
                              'we_sent_verification_code_to'.tr,
                              style: AppFonts.AlmaraiBold12.copyWith(color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 20.h),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.email_rounded, color: AppColors.primaryBlue, size: 17.sp),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(_email, style: AppFonts.AlmaraiBold14.copyWith(color: AppColors.textPrimary, fontSize: 14.sp)),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24.h),
                            // OTP Field
                            TextFormField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 6,
                              style: AppFonts.AlmaraiBold12.copyWith( letterSpacing: 12.w, color: AppColors.primaryBlue),
                              decoration: InputDecoration(
                                labelText: 'verification_code'.tr,
                                hintText: '000000',
                                counterText: '',
                                prefixIcon: Icon(Icons.verified_user_outlined, color: AppColors.primaryBlue, size: 20.sp),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: BorderSide(color: AppColors.grey300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
                                ),
                                filled: true,
                                fillColor: AppColors.grey50,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'code_required'.tr;
                                if (value.length != 6) return 'verification_code_must_be_6_characters'.tr;
                                return null;
                              },
                            ),
                            SizedBox(height: 26.h),
                            // Main action button
                            SizedBox(
                              height: 50.h,
                              child: ElevatedButton(
                                onPressed: !_isLoading && _otpController.text.isNotEmpty ? _verifyEmail : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  disabledBackgroundColor: AppColors.grey300,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? SizedBox(height: 20.h, width: 20.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.verified_user, color: Colors.white, size: 18.sp),
                                          SizedBox(width: 8.w),
                                          Text('verify'.tr, style: AppFonts.AlmaraiBold12.copyWith(color: Colors.white)),
                                        ],
                                      ),
                              ),
                            ),
                            SizedBox(height: 18.h),
                            // Resend section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.timer, color: AppColors.textSecondary, size: 17.sp),
                                SizedBox(width: 8.w),
                                Text('didnt_receive_code'.tr, style: AppFonts.AlmaraiBold12.copyWith(color: AppColors.textSecondary)),
                                SizedBox(width: 8.w),
                                TextButton(
                                  onPressed: _resendCountdown > 0 || _isResending ? null : _resendOtp,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7.r)),
                                  ),
                                  child: _isResending
                                      ? SizedBox(height: 16.h, width: 16.w, child: const CircularProgressIndicator(strokeWidth: 2))
                                      : Text(
                                          _resendCountdown > 0
                                              ? 'resend_in_seconds'.tr.replaceAll('{seconds}', _resendCountdown.toString())
                                              : 'resend_code'.tr,
                                          style: AppFonts.AlmaraiBold12.copyWith(color: _resendCountdown > 0 ? Colors.grey : AppColors.primaryBlue)),
                                ),
                              ],
                            ),
                            SizedBox(height: 14.h),
                            // Back to login link
                            TextButton(
                              onPressed: () => Get.offAllNamed(AppRoutes.login),
                              child: Text('back_to_sign_in'.tr, style: AppFonts.AlmaraiBold12.copyWith(color: AppColors.textSecondary)),
                            ),
                          ],
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
