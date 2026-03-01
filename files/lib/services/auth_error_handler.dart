import 'package:get/get.dart';
import 'user_storage_service.dart';

/// Centralized authentication error handler
class AuthErrorHandler {
  /// Handle 403 Unauthorized errors by logging out and navigating to login
  /// Handle 403 Unauthorized errors by logging out and navigating to login
  static Future<void> handle403Error() async {
    print('🔒 [AUTH] 403 Unauthorized detected - Logging out user');
    
    // Clear user data and token
    await UserStorageService.logout();
    
    // Navigate to login page and clear navigation stack
    Get.offAllNamed('/login');
    
    // Show error message to user
    Get.snackbar(
      'Session Expired',
      'Please login again',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }
  
  /// Check if error is 403 or HTML and handle it
  static Future<bool> handleIfUnauthorized(int statusCode, {String? body}) async {
    final isHtml = body != null && (body.trim().startsWith('<!DOCTYPE html>') || body.trim().startsWith('<html'));
    
    if (statusCode == 403 || statusCode == 401 || isHtml) {
      if (isHtml) print('⚠️ [AUTH] HTML response detected - redirecting to login');
      await handle403Error();
      return true;
    }
    return false;
  }
}

