import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
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
      margin: Responsive.all(16),
      borderRadius: Responsive.r(12),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
      animationDuration: Duration(milliseconds: 300),
      titleText: Text(
        title,
        style: AppFonts.AlmaraiBold16.copyWith(
          color: Colors.white,
        ),
      ),
      messageText: Text(
        message,
        style: AppFonts.AlmaraiRegular14.copyWith(
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
      margin: Responsive.all(16),
      borderRadius: Responsive.r(12),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
      animationDuration: Duration(milliseconds: 300),
      titleText: Text(
        title,
        style: AppFonts.AlmaraiBold16.copyWith(
          color: Colors.white,
        ),
      ),
      messageText: Text(
        message,
        style: AppFonts.AlmaraiRegular14.copyWith(
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
      backgroundColor: AppColors.blue1,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: duration,
      margin: Responsive.all(16),
      borderRadius: Responsive.r(12),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
      animationDuration: Duration(milliseconds: 300),
      titleText: Text(
        title,
        style: AppFonts.AlmaraiBold16.copyWith(
          color: Colors.white,
        ),
      ),
      messageText: Text(
        message,
        style: AppFonts.AlmaraiRegular14.copyWith(
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
    if (statusCode == null) {
      switch (baseTitle) {
        case 'Registration':
          return 'registration_failed'.tr;
        case 'Verification':
          return 'verification_failed'.tr;
        case 'Send Code':
          return 'send_code_failed'.tr;
        case 'PIN':
          return 'pin_failed'.tr;
        case 'Login':
          return 'login_failed'.tr;
        case 'Forgot PIN':
          return 'forgot_pin_failed'.tr;
        default:
          return 'operation_failed'.tr;
      }
    }

    switch (statusCode) {
      case 400:
        return baseTitle == 'Registration' 
            ? 'registration_error'.tr 
            : baseTitle == 'Verification'
                ? 'verification_error'.tr
                : 'error'.tr;
      case 401:
        return 'unauthorized'.tr;
      case 403:
        return 'forbidden'.tr;
      case 404:
        return 'not_found'.tr;
      case 405:
        return 'service_unavailable'.tr;
      case 409:
        return 'conflict'.tr;
      case 422:
        return 'validation_error'.tr;
      case 429:
        return 'too_many_requests'.tr;
      case 500:
        return 'server_error'.tr;
      case 502:
        return 'bad_gateway'.tr;
      case 503:
        return 'service_unavailable'.tr;
      default:
        switch (baseTitle) {
          case 'Registration':
            return 'registration_failed'.tr;
          case 'Verification':
            return 'verification_failed'.tr;
          case 'Send Code':
            return 'send_code_failed'.tr;
          case 'PIN':
            return 'pin_failed'.tr;
          case 'Login':
            return 'login_failed'.tr;
          case 'Forgot PIN':
            return 'forgot_pin_failed'.tr;
          default:
            return 'operation_failed'.tr;
        }
    }
  }

  // Success messages
  static void showRegistrationSuccess() {
    showSuccess(
      title: 'registration_successful'.tr,
      message: 'registration_successful_verify_email'.tr,
    );
  }

  static void showVerificationSuccess() {
    showSuccess(
      title: 'verification_successful'.tr,
      message: 'verification_successful'.tr,
    );
  }

  static void showCodeSentSuccess() {
    showSuccess(
      title: 'code_sent'.tr,
      message: 'code_sent_successfully'.tr,
    );
  }

  static void showPinSetSuccess() {
    showSuccess(
      title: 'pin_set_successfully'.tr,
      message: 'pin_set_successfully'.tr,
    );
  }

  static void showLoginSuccess() {
    showSuccess(
      title: 'login_successful'.tr,
      message: 'welcome_back'.tr,
    );
  }

  static void showAccountSwitchedSuccess(String name) {
    showSuccess(
      title: 'account_switched'.tr,
      message: 'welcome_back_user'.tr.replaceAll('{name}', name),
    );
  }

  // Helper method to extract clean error messages
  static String _extractErrorMessage(String error) {
    // Handle specific error cases with translations
    if (error.contains('Email or phone already in use')) {
      return 'email_or_phone_already_in_use'.tr;
    }

    if (error.contains('Invalid credentials')) {
      return 'invalid_credentials'.tr;
    }

    if (error.contains('User is banned')) {
      return 'user_is_banned'.tr;
    }

    if (error.contains('Invalid code')) {
      return 'invalid_verification_code'.tr;
    }

    if (error.contains('Code expired')) {
      return 'code_expired'.tr;
    }

    if (error.contains('Code consumed')) {
      return 'code_consumed'.tr;
    }

    if (error.contains('User not found')) {
      return 'user_not_found'.tr;
    }

    if (error.contains('Method Not Allowed')) {
      return 'action_not_allowed'.tr;
    }

    if (error.contains('Forgot PIN failed: ')) {
      return 'forgot_pin_unavailable'.tr;
    }

    if (error.contains('Network error')) {
      return 'network_error_check_connection'.tr;
    }

    // Extract JSON message from API responses
    if (error.contains('"message":"')) {
      final match = RegExp(r'"message":"([^"]+)"').firstMatch(error);
      if (match != null) {
        final message = match.group(1)!;
        // Try to translate common error messages
        return _translateCommonError(message);
      }
    }

    // Extract error from exception format
    if (error.contains('Exception: ')) {
      final exceptionMessage = error.replaceFirst('Exception: ', '');
      return _translateCommonError(exceptionMessage);
    }

    // Handle empty response body
    if (error.trim().isEmpty) {
      return 'unexpected_error_try_again'.tr;
    }

    // Try to translate the original error
    return _translateCommonError(error);
  }

  // Helper method to translate common error messages
  static String _translateCommonError(String error) {
    final lowerError = error.toLowerCase();
    
    // Map common error patterns to translation keys
    if (lowerError.contains('email already') || lowerError.contains('email exists')) {
      return 'email_already_exists_error'.tr;
    }
    if (lowerError.contains('phone already') || lowerError.contains('phone exists')) {
      return 'phone_already_exists_error'.tr;
    }
    if (lowerError.contains('invalid email') || lowerError.contains('email invalid')) {
      return 'invalid_email'.tr;
    }
    if (lowerError.contains('invalid phone') || lowerError.contains('phone invalid')) {
      return 'invalid_phone'.tr;
    }
    if (lowerError.contains('network') || lowerError.contains('connection')) {
      return 'network_error_check_connection'.tr;
    }
    if (lowerError.contains('server error') || lowerError.contains('server')) {
      return 'server_error_try_again'.tr;
    }
    if (lowerError.contains('unauthorized') || lowerError.contains('authentication')) {
      return 'unauthorized'.tr;
    }
    if (lowerError.contains('forbidden') || lowerError.contains('permission')) {
      return 'forbidden'.tr;
    }
    if (lowerError.contains('not found')) {
      return 'not_found'.tr;
    }
    if (lowerError.contains('validation') || lowerError.contains('invalid')) {
      return 'validation_error'.tr;
    }
    if (lowerError.contains('timeout') || lowerError.contains('timed out')) {
      return 'request_timed_out'.tr;
    }
    
    // Return original error if no translation found
    return error;
  }
}

