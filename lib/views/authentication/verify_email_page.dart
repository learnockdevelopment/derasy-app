import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:kids_cottage/models/authentication/auth_models.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/assets.dart';
import '../../core/routes/app_routes.dart';
import '../../services/authentication/auth_service.dart';

class VerifyEmailPage extends StatefulWidget {
  final int userId;
  final String email;

  const VerifyEmailPage({
    Key? key,
    required this.userId,
    required this.email,
  }) : super(key: key);

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _isResending = false;
  int _resendCountdown = 0;
  late AnimationController _animationController;
  late AnimationController _countdownController;

  @override
  void initState() {
    super.initState();
    print('📧 [VERIFY_EMAIL] VerifyEmailPage initState called');

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _countdownController = AnimationController(
      duration: const Duration(seconds: 60),
      vsync: this,
    );

    _animationController.forward();
    _startResendCountdown();
  }

  @override
  void dispose() {
    print('📧 [VERIFY_EMAIL] VerifyEmailPage dispose called');
    _otpController.dispose();
    _animationController.dispose();
    _countdownController.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60;
    });

    _countdownController.reset();
    _countdownController.forward();

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _resendCountdown--;
        });
        if (_resendCountdown > 0) {
          _startResendCountdown();
        }
      }
    });
  }

  Future<void> _verifyEmail() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print(
          '📧 [VERIFY_EMAIL] Starting email verification for user: ${widget.userId}');

      final response = await AuthService.verifyEmailOtp(
        userId: widget.userId,
        otp: _otpController.text.trim(),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
              'Verification request timed out. Please check your internet connection.');
        },
      );

      print('📧 [VERIFY_EMAIL] Verification response received: $response');

      if (response.isEmpty) {
        throw Exception('Empty response from server');
      }

      final verifyResponse = VerifyEmailResponse.fromJson(response);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      print('📧 [VERIFY_EMAIL] Email verification successful');

      // Check if account is now active
      if (verifyResponse.data?.accountStatus == 'active') {
        // Both email and phone verified, go to home
        Get.offAllNamed<void>(AppRoutes.home);
        Get.snackbar(
          'Success',
          'Email verified successfully! Account is now active.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primary,
          colorText: Colors.white,
        );
      } else {
        // Email verified but phone still pending, go to phone verification
        Get.offNamed<void>(
          AppRoutes.verifyPhone,
          arguments: {
            'userId': widget.userId,
            'phone': verifyResponse.data?.user?.phone ?? '',
          },
        );
        Get.snackbar(
          'Success',
          'Email verified successfully! Please verify your phone number.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primary,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('📧 [VERIFY_EMAIL] Email verification error: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      String errorMessage = 'An unexpected error occurred. Please try again.';

      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Invalid response from server. Please try again.';
      } else if (e.toString().contains('Invalid OTP')) {
        errorMessage = 'Invalid verification code. Please try again.';
      } else if (e.toString().contains('OTP expired')) {
        errorMessage =
            'Verification code has expired. Please request a new one.';
      } else if (e.toString().isNotEmpty) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
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
      // In a real app, you would call an API to resend OTP
      // For now, we'll just show a success message
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      setState(() {
        _isResending = false;
      });

      Get.snackbar(
        'Success',
        'Verification code sent to ${widget.email}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );

      _startResendCountdown();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isResending = false;
      });

      Get.snackbar(
        'Error',
        'Failed to resend verification code. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('📧 [VERIFY_EMAIL] VerifyEmailPage build called');

    return Scaffold(
      body: Stack(
        children: [
          // Blurred background image
          _buildBlurredBackground(),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                child: FadeTransition(
                  opacity: _animationController,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Verify email form
                      _buildVerifyForm(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurredBackground() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AssetsManager.login),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.black.withOpacity(0.2),
          ),
        ),
      ),
    );
  }

  Widget _buildVerifyForm() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Email icon
            Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.email_outlined,
                size: 40.w,
                color: AppColors.primary,
              ),
            ),

            SizedBox(height: 24.h),

            // Title
            Text(
              'Verify Your Email',
              style: AppFonts.robotoBold24.copyWith(
                color: AppColors.textPrimary,
                fontSize: 24.sp,
              ),
            ),

            SizedBox(height: 8.h),

            Text(
              'We sent a verification code to',
              style: AppFonts.robotoRegular16.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14.sp,
              ),
            ),

            SizedBox(height: 4.h),

            Text(
              widget.email,
              style: AppFonts.robotoBold16.copyWith(
                color: AppColors.primary,
                fontSize: 16.sp,
              ),
            ),

            SizedBox(height: 32.h),

            // OTP Field
            _buildOtpField(),

            SizedBox(height: 24.h),

            // Verify Button
            _buildVerifyButton(),

            SizedBox(height: 20.h),

            // Resend OTP
            _buildResendSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.grey200,
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Verification code is required';
          }
          if (value.length != 6) {
            return 'Verification code must be 6 digits';
          }
          return null;
        },
        style: AppFonts.robotoBold20.copyWith(
          color: AppColors.textPrimary,
          fontSize: 24.sp,
          letterSpacing: 8.w,
        ),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: '000000',
          hintStyle: AppFonts.robotoBold20.copyWith(
            color: AppColors.textSecondary.withOpacity(0.5),
            fontSize: 24.sp,
            letterSpacing: 8.w,
          ),
          prefixIcon: Icon(
            Icons.security,
            color: AppColors.primary,
            size: 20.w,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 20.h,
          ),
        ),
      ),
    );
  }

  Widget _buildVerifyButton() {
    return Container(
      width: double.infinity,
      height: 50.h,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _verifyEmail,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: 24.w,
                height: 24.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Verify Email',
                style: AppFonts.robotoBold16.copyWith(
                  color: Colors.white,
                  fontSize: 18.sp,
                ),
              ),
      ),
    );
  }

  Widget _buildResendSection() {
    return Column(
      children: [
        Text(
          "Didn't receive the code?",
          style: AppFonts.robotoRegular14.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: _resendCountdown > 0 ? null : _resendOtp,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color:
                  _resendCountdown > 0 ? AppColors.grey200 : AppColors.primary,
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: _isResending
                ? SizedBox(
                    width: 16.w,
                    height: 16.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _resendCountdown > 0
                        ? 'Resend in ${_resendCountdown}s'
                        : 'Resend Code',
                    style: AppFonts.robotoBold12.copyWith(
                      color: Colors.white,
                      fontSize: 12.sp,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
