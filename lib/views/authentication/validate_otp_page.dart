import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/assets.dart';
import '../../core/routes/app_routes.dart';
import '../../services/authentication/auth_service.dart';

class ValidateOtpPage extends StatefulWidget {
  final String email;

  const ValidateOtpPage({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  State<ValidateOtpPage> createState() => _ValidateOtpPageState();
}

class _ValidateOtpPageState extends State<ValidateOtpPage>
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
    print('🔐 [VALIDATE_OTP] ValidateOtpPage initState called');

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
    print('🔐 [VALIDATE_OTP] ValidateOtpPage dispose called');
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

  Future<void> _validateOtp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔐 [VALIDATE_OTP] Starting OTP validation for: ${widget.email}');

      final response = await AuthService.validateOtpFromEmail(
        email: widget.email,
        otp: _otpController.text.trim(),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
              'Validation request timed out. Please check your internet connection.');
        },
      );

      print('🔐 [VALIDATE_OTP] Validation response received: $response');

      if (response.isEmpty) {
        throw Exception('Empty response from server');
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      print('🔐 [VALIDATE_OTP] OTP validation successful');

      // Navigate to reset password page
      Get.toNamed<void>(
        AppRoutes.resetPassword,
        arguments: {
          'email': widget.email,
          'otp': _otpController.text.trim(),
        },
      );

      Get.snackbar(
        'Success',
        'OTP validated successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
    } catch (e) {
      print('🔐 [VALIDATE_OTP] OTP validation error: $e');

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
      await AuthService.sendOtpToEmail(email: widget.email);

      if (!mounted) return;

      setState(() {
        _isResending = false;
      });

      Get.snackbar(
        'Success',
        'OTP sent to ${widget.email}',
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
        'Failed to resend OTP. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔐 [VALIDATE_OTP] ValidateOtpPage build called');

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
                      // Validate OTP form
                      _buildValidateForm(),
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

  Widget _buildValidateForm() {
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
            // Security icon
            Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.security,
                size: 40.w,
                color: AppColors.primary,
              ),
            ),

            SizedBox(height: 24.h),

            // Title
            Text(
              'Enter Verification Code',
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

            // Validate Button
            _buildValidateButton(),

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

  Widget _buildValidateButton() {
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
        onPressed: _isLoading ? null : _validateOtp,
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
                'Validate OTP',
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
