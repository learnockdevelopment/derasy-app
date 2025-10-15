import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';

class ErrorPrompts {
  static void showError({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    Get.snackbar(
      title,
      message,
      backgroundColor: AppColors.error,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: duration,
      margin: EdgeInsets.all(16.w),
      borderRadius: 12.r,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
      animationDuration: Duration(milliseconds: 300),
      titleText: Text(
        title,
        style: AppFonts.robotoBold16.copyWith(
          color: Colors.white,
        ),
      ),
      messageText: Text(
        message,
        style: AppFonts.robotoRegular14.copyWith(
          color: Colors.white,
        ),
      ),
    );
  }

  static void showSuccess({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    Get.snackbar(
      title,
      message,
      backgroundColor: AppColors.success,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: duration,
      margin: EdgeInsets.all(16.w),
      borderRadius: 12.r,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
      animationDuration: Duration(milliseconds: 300),
      titleText: Text(
        title,
        style: AppFonts.robotoBold16.copyWith(
          color: Colors.white,
        ),
      ),
      messageText: Text(
        message,
        style: AppFonts.robotoRegular14.copyWith(
          color: Colors.white,
        ),
      ),
    );
  }

  static void showInfo({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    Get.snackbar(
      title,
      message,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: duration,
      margin: EdgeInsets.all(16.w),
      borderRadius: 12.r,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
      animationDuration: Duration(milliseconds: 300),
      titleText: Text(
        title,
        style: AppFonts.robotoBold16.copyWith(
          color: Colors.white,
        ),
      ),
      messageText: Text(
        message,
        style: AppFonts.robotoRegular14.copyWith(
          color: Colors.white,
        ),
      ),
    );
  }

  // Specific error handlers for authentication with status-based titles
  static void showRegistrationError(String error, {int? statusCode}) {
    String cleanMessage = _extractErrorMessage(error);
    String title = _getErrorTitle('Registration', statusCode);
    showError(
      title: title,
      message: cleanMessage,
    );
  }

  static void showVerificationError(String error, {int? statusCode}) {
    String cleanMessage = _extractErrorMessage(error);
    String title = _getErrorTitle('Verification', statusCode);
    showError(
      title: title,
      message: cleanMessage,
    );
  }

  static void showSendCodeError(String error, {int? statusCode}) {
    String cleanMessage = _extractErrorMessage(error);
    String title = _getErrorTitle('Send Code', statusCode);
    showError(
      title: title,
      message: cleanMessage,
    );
  }

  static void showPinError(String error, {int? statusCode}) {
    String cleanMessage = _extractErrorMessage(error);
    String title = _getErrorTitle('PIN', statusCode);
    showError(
      title: title,
      message: cleanMessage,
    );
  }

  static void showLoginError(String error, {int? statusCode}) {
    String cleanMessage = _extractErrorMessage(error);
    String title = _getErrorTitle('Login', statusCode);
    showError(
      title: title,
      message: cleanMessage,
    );
  }

  static void showForgotPinError(String error, {int? statusCode}) {
    String cleanMessage = _extractErrorMessage(error);
    String title = _getErrorTitle('Forgot PIN', statusCode);
    showError(
      title: title,
      message: cleanMessage,
    );
  }

  // Helper method to get error title based on status code
  static String _getErrorTitle(String baseTitle, int? statusCode) {
    if (statusCode == null) return '$baseTitle Failed';

    switch (statusCode) {
      case 400:
        return '$baseTitle Error';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Access Denied';
      case 404:
        return 'Not Found';
      case 405:
        return 'Service Unavailable';
      case 409:
        return 'Conflict';
      case 422:
        return 'Validation Error';
      case 429:
        return 'Too Many Requests';
      case 500:
        return 'Server Error';
      case 502:
        return 'Bad Gateway';
      case 503:
        return 'Service Unavailable';
      default:
        return '$baseTitle Failed';
    }
  }

  // Success messages
  static void showRegistrationSuccess() {
    showSuccess(
      title: 'Registration Successful',
      message: 'Your account has been created successfully',
    );
  }

  static void showVerificationSuccess() {
    showSuccess(
      title: 'Verification Successful',
      message: 'Your account has been verified',
    );
  }

  static void showCodeSentSuccess() {
    showSuccess(
      title: 'Code Sent',
      message: 'Verification code has been sent',
    );
  }

  static void showPinSetSuccess() {
    showSuccess(
      title: 'PIN Set Successfully',
      message: 'Your PIN has been set successfully',
    );
  }

  static void showLoginSuccess() {
    showSuccess(
      title: 'Login Successful',
      message: 'Welcome back!',
    );
  }

  static void showAccountSwitchedSuccess(String name) {
    showSuccess(
      title: 'Account Switched',
      message: 'Welcome back, $name!',
    );
  }

  // Helper method to extract clean error messages
  static String _extractErrorMessage(String error) {
    // Handle specific error cases
    if (error.contains('Email or phone already in use')) {
      return 'Email or phone already in use';
    }

    if (error.contains('Invalid credentials')) {
      return 'Invalid credentials';
    }

    if (error.contains('User is banned')) {
      return 'User is banned';
    }

    if (error.contains('Invalid code')) {
      return 'Invalid verification code';
    }

    if (error.contains('Code expired')) {
      return 'Verification code has expired';
    }

    if (error.contains('Code consumed')) {
      return 'Verification code has already been used';
    }

    if (error.contains('User not found')) {
      return 'User not found';
    }

    if (error.contains('Method Not Allowed')) {
      return 'This action is not allowed';
    }

    if (error.contains('Forgot PIN failed: ')) {
      return 'Forgot PIN service is currently unavailable. Please try again later.';
    }

    if (error.contains('Network error')) {
      return 'Network connection error. Please check your internet connection.';
    }

    // Extract JSON message from API responses
    if (error.contains('"message":"')) {
      final match = RegExp(r'"message":"([^"]+)"').firstMatch(error);
      if (match != null) {
        return match.group(1)!;
      }
    }

    // Extract error from exception format
    if (error.contains('Exception: ')) {
      return error.replaceFirst('Exception: ', '');
    }

    // Handle empty response body
    if (error.trim().isEmpty) {
      return 'An unexpected error occurred';
    }

    // Return the original error if no specific case matches
    return error;
  }
}
