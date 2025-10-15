import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/assets.dart';
import '../../services/authentication/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _isEmailSent = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    print('🔑 [FORGOT_PASSWORD] ForgotPasswordPage initState called');

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    print('🔑 [FORGOT_PASSWORD] ForgotPasswordPage dispose called');
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print(
          '🔑 [FORGOT_PASSWORD] Starting forgot password for: ${_emailController.text.trim()}');

      final response = await AuthService.sendOtpToEmail(
        email: _emailController.text.trim(),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
              'Request timed out. Please check your internet connection.');
        },
      );

      print(
          '🔑 [FORGOT_PASSWORD] Forgot password response received: $response');

      if (response.isEmpty) {
        throw Exception('Empty response from server');
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isEmailSent = true;
      });

      print('🔑 [FORGOT_PASSWORD] Reset email sent successfully');

      Get.snackbar(
        'Success',
        'Password reset instructions sent to ${_emailController.text.trim()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      print('🔑 [FORGOT_PASSWORD] Forgot password error: $e');

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
      } else if (e.toString().contains('Email not found')) {
        errorMessage = 'No account found with this email address.';
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

  @override
  Widget build(BuildContext context) {
    print('🔑 [FORGOT_PASSWORD] ForgotPasswordPage build called');

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
                      // Forgot password form
                      _isEmailSent ? _buildEmailSentView() : _buildForgotForm(),
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

  Widget _buildForgotForm() {
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
            // Lock icon
            Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_reset,
                size: 40.w,
                color: AppColors.primary,
              ),
            ),

            SizedBox(height: 24.h),

            // Title
            Text(
              'Forgot Password?',
              style: AppFonts.robotoBold24.copyWith(
                color: AppColors.textPrimary,
                fontSize: 24.sp,
              ),
            ),

            SizedBox(height: 8.h),

            Text(
              'Enter your email address and we\'ll send you instructions to reset your password.',
              style: AppFonts.robotoRegular16.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 32.h),

            // Email Field
            _buildEmailField(),

            SizedBox(height: 24.h),

            // Send Button
            _buildSendButton(),

            SizedBox(height: 20.h),

            // Back to Login
            _buildBackToLogin(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailSentView() {
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
      child: Column(
        children: [
          // Success icon
          Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mark_email_read,
              size: 40.w,
              color: AppColors.primary,
            ),
          ),

          SizedBox(height: 24.h),

          // Title
          Text(
            'Check Your Email',
            style: AppFonts.robotoBold24.copyWith(
              color: AppColors.textPrimary,
              fontSize: 24.sp,
            ),
          ),

          SizedBox(height: 8.h),

          Text(
            'We\'ve sent password reset instructions to',
            style: AppFonts.robotoRegular16.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14.sp,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 4.h),

          Text(
            _emailController.text.trim(),
            style: AppFonts.robotoBold16.copyWith(
              color: AppColors.primary,
              fontSize: 16.sp,
            ),
          ),

          SizedBox(height: 16.h),

          Text(
            'Please check your email and follow the instructions to reset your password.',
            style: AppFonts.robotoRegular14.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12.sp,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 32.h),

          // Back to Login Button
          _buildBackToLoginButton(),

          SizedBox(height: 16.h),

          // Resend Email
          _buildResendEmail(),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
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
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Email is required';
          }
          if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
              .hasMatch(value)) {
            return 'Please enter a valid email';
          }
          return null;
        },
        style: AppFonts.robotoRegular16.copyWith(
          color: AppColors.textPrimary,
          fontSize: 16.sp,
        ),
        decoration: InputDecoration(
          hintText: 'Enter your email address',
          hintStyle: AppFonts.robotoRegular14.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14.sp,
          ),
          prefixIcon: Icon(
            Icons.email_outlined,
            color: AppColors.primary,
            size: 20.w,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
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
        onPressed: _isLoading ? null : _sendResetEmail,
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
                'Send Reset Instructions',
                style: AppFonts.robotoBold16.copyWith(
                  color: Colors.white,
                  fontSize: 18.sp,
                ),
              ),
      ),
    );
  }

  Widget _buildBackToLogin() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Remember your password? ',
          style: AppFonts.robotoRegular14.copyWith(
            color: AppColors.textPrimary,
            fontSize: 14.sp,
          ),
        ),
        GestureDetector(
          onTap: () => Get.back<void>(),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              'Sign In',
              style: AppFonts.robotoBold14.copyWith(
                color: Colors.white,
                fontSize: 14.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackToLoginButton() {
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
        onPressed: () => Get.back<void>(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Text(
          'Back to Sign In',
          style: AppFonts.robotoBold16.copyWith(
            color: Colors.white,
            fontSize: 18.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildResendEmail() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isEmailSent = false;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: Text(
          'Send to different email',
          style: AppFonts.robotoMedium12.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }
}
