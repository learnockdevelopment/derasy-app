import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/auth_models.dart';

class AuthService {

  static String _getBaseUrl({String? role}) {
    if (role != null && role.toLowerCase() == 'sales') {
      return ApiConstants.salesBaseUrl;
    }
    return ApiConstants.parentBaseUrl;
  }

  // 1. User Registration
  static Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      final baseUrl = _getBaseUrl(role: request.role);
      final url = '$baseUrl${ApiConstants.registerEndpoint}';

      print('🔐 [REGISTER] ========== REQUEST ==========');
      print('🔐 [REGISTER] URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConstants.getHeaders(),
        body: jsonEncode(request.toJson()),
      );

      print('🔐 [REGISTER] ========== RESPONSE ==========');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return RegisterResponse.fromJson(responseData);
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body) as Map<
            String,
            dynamic>;
        throw AuthException(
            (errorData['message'] ?? 'Registration failed').toString(),
            response.statusCode);
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e', 0);
    }
  }

  // 2. Email Verification (OTP)
  static Future<VerifyEmailResponse> verifyEmail(VerifyEmailRequest request,
      {String? role}) async {
    try {
      final baseUrl = _getBaseUrl(role: role);
      final url = '$baseUrl${ApiConstants.verifyEmailEndpoint}';

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConstants.getHeaders(),
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return VerifyEmailResponse.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body) as Map<
            String,
            dynamic>;
        throw AuthException(
            (errorData['message'] ?? 'Verification failed').toString(),
            response.statusCode);
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e', 0);
    }
  }

  // 3. Resend Verification OTP
  static Future<ResendVerificationResponse> resendVerification(
      ResendVerificationRequest request, {String? role}) async {
    try {
      final baseUrl = _getBaseUrl(role: role);
      final url = '$baseUrl${ApiConstants.resendVerificationEndpoint}';

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConstants.getHeaders(),
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return ResendVerificationResponse.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body) as Map<
            String,
            dynamic>;
        throw AuthException(
            (errorData['message'] ?? 'Resend failed').toString(),
            response.statusCode);
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e', 0);
    }
  }

  // 4. Quick Registration
  static Future<QuickRegisterResponse> quickRegister(
      QuickRegisterRequest request) async {
    try {
      final url = '${ApiConstants.parentBaseUrl}${ApiConstants
          .quickRegisterEndpoint}';

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConstants.getHeaders(),
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return QuickRegisterResponse.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body) as Map<
            String,
            dynamic>;
        throw AuthException(
            (errorData['message'] ?? 'Quick registration failed').toString(),
            response.statusCode);
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e', 0);
    }
  }

  // 5. Login
  static Future<LoginResponse> login(LoginRequest request) async {
    try {
      print('🔐 [LOGIN] ========== STARTING LOGIN FLOW ==========');

      // Step 1: Prioritize Sales API
      try {
        final response = await http.post(
          Uri.parse(
              '${ApiConstants.salesBaseUrl}${ApiConstants.loginEndpoint}'),
          headers: ApiConstants.getHeaders(),
          body: jsonEncode(request.toJson()),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body) as Map<
              String,
              dynamic>;
          return LoginResponse.fromJson(data);
        }
      } catch (e) {
        print('🔐 [LOGIN] Sales API failed: $e');
      }

      // Step 2: Fallback to Parent API
      print('🔐 [LOGIN] Fallback to Parent Backend...');
      final parentResponse = await http.post(
        Uri.parse('${ApiConstants.parentBaseUrl}${ApiConstants.loginEndpoint}'),
        headers: ApiConstants.getHeaders(),
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 10));

      if (parentResponse.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(
            parentResponse.body) as Map<String, dynamic>;
        return LoginResponse.fromJson(data);
      } else {
        final Map<String, dynamic> errorData = jsonDecode(
            parentResponse.body) as Map<String, dynamic>;
        final String errorMsg = (errorData['message'] ?? 'Login failed')
            .toString();
        throw AuthException(errorMsg, parentResponse.statusCode);
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e', 0);
    }
  }

  // 6. Password Reset Request
  static Future<ResetPasswordResponse> resetPassword(
      ResetPasswordRequest request) async {
    try {
      // Try Sales first
      try {
        final salesResponse = await http.post(
          Uri.parse('${ApiConstants.salesBaseUrl}${ApiConstants
              .resetPasswordEndpoint}'),
          headers: ApiConstants.getHeaders(),
          body: jsonEncode(request.toJson()),
        ).timeout(const Duration(seconds: 10));

        if (salesResponse.statusCode == 200) {
          return ResetPasswordResponse.fromJson(
              jsonDecode(salesResponse.body) as Map<String, dynamic>);
        }
      } catch (e) {
        print('🔐 [RESET_PASSWORD] Sales API failed: $e');
      }

      // Try Parent fallback
      final response = await http.post(
        Uri.parse('${ApiConstants.parentBaseUrl}${ApiConstants
            .resetPasswordEndpoint}'),
        headers: ApiConstants.getHeaders(),
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return ResetPasswordResponse.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body) as Map<
            String,
            dynamic>;
        throw AuthException(
            (errorData['message'] ?? 'Email not registered').toString(),
            response.statusCode);
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e', 0);
    }
  }

  // 7. Password Reset OTP Verification
  static Future<VerifyResetOtpResponse> verifyResetOtp(
      VerifyResetOtpRequest request, {String? role}) async {
    try {
      final baseUrl = _getBaseUrl(role: role);
      final url = '$baseUrl${ApiConstants.verifyResetOtpEndpoint}';

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConstants.getHeaders(),
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return VerifyResetOtpResponse.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body) as Map<
            String,
            dynamic>;
        throw AuthException((errorData['message'] ?? 'Invalid OTP').toString(),
            response.statusCode);
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e', 0);
    }
  }

  // 8. Set New Password
  static Future<SetNewPasswordResponse> setNewPassword(
      SetNewPasswordRequest request, {String? role}) async {
    try {
      final baseUrl = _getBaseUrl(role: role);
      final url = '$baseUrl${ApiConstants.setNewPasswordEndpoint}';

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConstants.getHeaders(),
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return SetNewPasswordResponse.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body) as Map<
            String,
            dynamic>;
        throw AuthException(
            (errorData['message'] ?? 'Failed to set password').toString(),
            response.statusCode);
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e', 0);
    }
  }

  // 9. Get User Profile
  static Future<UserProfileResponse> getUserProfile(String token) async {
    try {
      // Step 1: Try Sales first
      try {
        final salesResponse = await http.get(
          Uri.parse('${ApiConstants.salesBaseUrl}${ApiConstants
              .getUserProfileEndpoint}'),
          headers: ApiConstants.getHeaders(token: token),
        ).timeout(const Duration(seconds: 10));

        if (salesResponse.statusCode == 200) {
          return UserProfileResponse.fromJson(
              jsonDecode(salesResponse.body) as Map<String, dynamic>);
        }
      } catch (e) {
        print('🔐 [GET_USER_PROFILE] Sales API failed: $e');
      }

      // Step 2: Try Parent fallback
      final response = await http.get(
        Uri.parse('${ApiConstants.parentBaseUrl}${ApiConstants
            .getUserProfileEndpoint}'),
        headers: ApiConstants.getHeaders(token: token),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return UserProfileResponse.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body) as Map<
            String,
            dynamic>;
        throw AuthException((errorData['message'] ?? 'Unauthorized').toString(),
            response.statusCode);
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e', 0);
    }
  }

  // 10. Login with Google
  static Future<LoginResponse> loginWithGoogle(String idToken) async {
    try {
      // Use Parent Backend for Google Login
      final response = await http.post(
        Uri.parse(
            '${ApiConstants.parentBaseUrl}${ApiConstants.googleLoginEndpoint}'),
        headers: ApiConstants.getHeaders(),
        body: jsonEncode({'idToken': idToken}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body) as Map<
            String,
            dynamic>;
        throw AuthException((errorData['error'] ?? errorData['message'] ??
            'Google login failed').toString(), response.statusCode);
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e', 0);
    }
  }

  // 11. Login with Apple
  // static Future<LoginResponse> loginWithApple(
  //     String idToken, {Map<String, dynamic>? user}) async {
  //   try {
  //     final body = {'idToken': idToken};
  //     if (user != null) body['user'] = user;
  //
  //     // Try Sales first
  //     try {
  //       final salesResponse = await http.post(
  //         Uri.parse('${ApiConstants.salesBaseUrl}${ApiConstants.appleLoginEndpoint}'),
  //         headers: ApiConstants.getHeaders(),
  //         body: jsonEncode(body),
  //       ).timeout(const Duration(seconds: 10));
  //
  //       if (salesResponse.statusCode == 200) {
  //         return LoginResponse.fromJson(jsonDecode(salesResponse.body) as Map<String, dynamic>);
  //       }
  //     } catch (e) {
  //       print('🔐 [LOGIN_APPLE] Sales API failed: $e');
  //     }
  //
  //     // Try Parent fallback
  //     final response = await http.post(
  //       Uri.parse('${ApiConstants.parentBaseUrl}${ApiConstants.appleLoginEndpoint}'),
  //       headers: ApiConstants.getHeaders(),
  //       body: jsonEncode(body),
  //     ).timeout(const Duration(seconds: 10));
  //
  //     if (response.statusCode == 200) {
  //       return LoginResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  //     } else {
  //       final Map<String, dynamic> errorData = jsonDecode(response.body) as Map<String, dynamic>;
  //       throw AuthException((errorData['error'] ?? errorData['message'] ?? 'Apple login failed').toString(), response.statusCode);
  //     }
  //   } catch (e) {
  //     if (e is AuthException) rethrow;
  //     throw AuthException('Network error: $e', 0);
  //   }
  // }

  // 12. Check User Collision (Email/Phone)
  static Future<bool> checkUserCollision({String? email, String? phone}) async {
    try {
      final body = <String, dynamic>{};
      if (email != null) body['email'] = email;
      if (phone != null) body['phone'] = phone;

      // Use Parent Base URL for global check
      final response = await http.post(
        Uri.parse('${ApiConstants.parentBaseUrl}${ApiConstants.checkUserEndpoint}'),
        headers: ApiConstants.getHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.body.trim().isEmpty) return false;

      // Returns 200 if not technical error, check contents
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      // If result is true, it means there is a collision (user exists)
      return data['exists'] == true || data['collision'] == true;
    } catch (e) {
      print('🔐 [CHECK_USER] Error checking: $e');
      return false; // Don't block on error
    }
  }
}
