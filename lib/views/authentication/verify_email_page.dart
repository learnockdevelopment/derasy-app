import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/user_storage_service.dart';
import '../../models/auth_models.dart';
import '../../models/user.dart';

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
            backgroundColor: AppColors.primary,
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
            backgroundColor: AppColors.primary,
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
        backgroundColor: AppColors.primary,
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Enhanced Header with gradient background
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
                    // Background decorative elements
                    Positioned(
                      top: 40.h,
                      right: 30.w,
                      child: Container(
                        width: 80.w,
                        height: 80.h,
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(40.r),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 60.h,
                      left: 30.w,
                      child: Container(
                        width: 50.w,
                        height: 50.h,
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25.r),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: EdgeInsets.all(24.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 20.h),
                          // Logo and title
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                child: Icon(
                                  Icons.verified_user,
                                  color: AppColors.white,
                                  size: 32.sp,
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'verify_email'.tr,
                                      style: AppFonts.cairoBold28.copyWith(
                                        color: AppColors.white,
                                      ),
                                    ),
                                    Text(
                                      _isPasswordReset
                                          ? 'Reset Password'
                                          : 'Email Verification',
                                      style: AppFonts.cairoRegular16.copyWith(
                                        color: AppColors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 30.h),
                          // Email display
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 12.h),
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.email,
                                  color: AppColors.white,
                                  size: 16.sp,
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    _email,
                                    style: AppFonts.cairoMedium14.copyWith(
                                      color: AppColors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Verification Form with enhanced design
              Container(
                margin: EdgeInsets.all(20.w),
                padding: EdgeInsets.all(28.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.grey200,
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Form Title
                      Text(
                        'Enter Verification Code',
                        style: AppFonts.cairoBold20.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'we_sent_verification_code_to'.tr,
                        style: AppFonts.cairoRegular14.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 30.h),

                      // OTP Field with enhanced design
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: AppFonts.cairoBold28.copyWith(
                          fontSize: 28.sp,
                          letterSpacing: 12.w,
                          color: AppColors.primary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'enter_verification_code'.tr,
                          hintText: '000000',
                          counterText: '',
                          prefixIcon: Container(
                            margin: EdgeInsets.all(8.w),
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.verified_user_outlined,
                              color: AppColors.primary,
                              size: 20.sp,
                            ),
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
                            return 'verification_code_required'.tr;
                          }
                          if (value.length != 6) {
                            return 'verification_code_must_be_6_characters'.tr;
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 30.h),

                      // Verify Button with enhanced design
                      Container(
                        height: 56.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primaryLight,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed:
                              !_isLoading && _otpController.text.isNotEmpty
                                  ? () {
                                      print(
                                          '🔐 [VERIFY] Button onPressed triggered');
                                      _verifyEmail();
                                    }
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.verified_user,
                                      color: Colors.white,
                                      size: 20.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'verify'.tr,
                                      style: AppFonts.cairoBold16.copyWith(
                                        color: Colors.white,
                                        fontSize: 16.sp,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Resend Section with enhanced design
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        decoration: BoxDecoration(
                          color: AppColors.grey50,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.timer,
                              color: AppColors.textSecondary,
                              size: 16.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'didnt_receive_code'.tr,
                              style: AppFonts.cairoRegular14.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 14.sp,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            TextButton(
                              onPressed: _resendCountdown > 0 || _isResending
                                  ? null
                                  : _resendOtp,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 8.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              child: _isResending
                                  ? SizedBox(
                                      height: 16.h,
                                      width: 16.w,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _resendCountdown > 0
                                          ? 'resend_in_seconds'.tr.replaceAll(
                                              '{seconds}',
                                              _resendCountdown.toString())
                                          : 'resend_code'.tr,
                                      style: AppFonts.cairoBold14.copyWith(
                                        color: _resendCountdown > 0
                                            ? Colors.grey
                                            : AppColors.primary,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Back to Login
                      TextButton(
                        onPressed: () {
                          Get.offAllNamed(AppRoutes.login);
                        },
                        child: Text(
                          'back_to_sign_in'.tr,
                          style: AppFonts.cairoRegular14.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 14.sp,
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
      ),
    );
  }
}
