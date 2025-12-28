import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/auth_models.dart';

class AuthService {
  static const String _baseUrl = ApiConstants.baseUrl;

  // 1. User Registration
  static Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      print('🔐 [REGISTER] ========== REQUEST ==========');
      print('🔐 [REGISTER] URL: $_baseUrl${ApiConstants.registerEndpoint}');
      print('🔐 [REGISTER] Headers: ${ApiConstants.getHeaders()}');
      print('🔐 [REGISTER] Body: ${jsonEncode(request.toJson())}');
      print('🔐 [REGISTER] Email: ${request.email}');
      print('🔐 [REGISTER] Name: ${request.name}');
      print('🔐 [REGISTER] Role: ${request.role}');

      final response = await http.post(
        Uri.parse('$_baseUrl${ApiConstants.registerEndpoint}'),
        headers: ApiConstants.getHeaders(),
        body: jsonEncode(request.toJson()),
      );

      print('🔐 [REGISTER] ========== RESPONSE ==========');
      print('🔐 [REGISTER] Status Code: ${response.statusCode}');
      print('🔐 [REGISTER] Headers: ${response.headers}');
      print('🔐 [REGISTER] Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('🔐 [REGISTER] ✅ Registration successful');
        return RegisterResponse.fromJson(responseData);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AuthException(
            errorData['message'] ?? 'Missing required fields', 400);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AuthException(errorData['message'] ?? 'Internal Server Error',
            response.statusCode);
      }
    } catch (e) {
      print('🔐 [AUTH] Registration error: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e', 0);
    }
  }

  // 2. Email Verification (OTP)
  static Future<VerifyEmailResponse> verifyEmail(
      VerifyEmailRequest request) async {
    try {
      print('🔐 [VERIFY_EMAIL] ========== REQUEST ==========');
      print(
          '🔐 [VERIFY_EMAIL] URL: $_baseUrl${ApiConstants.verifyEmailEndpoint}');
      print('🔐 [VERIFY_EMAIL] Headers: ${ApiConstants.getHeaders()}');
      print('🔐 [VERIFY_EMAIL] Body: ${jsonEncode(request.toJson())}');
      print('🔐 [VERIFY_EMAIL] Email: ${request.email}');
      print('🔐 [VERIFY_EMAIL] OTP: ${request.otp}');

      final response = await http.post(
        Uri.parse('$_baseUrl${ApiConstants.verifyEmailEndpoint}'),
        headers: ApiConstants.getHeaders(),
        body: jsonEncode(request.toJson()),
      );

      print('🔐 [VERIFY_EMAIL] ========== RESPONSE ==========');
      print('🔐 [VERIFY_EMAIL] Status Code: ${response.statusCode}');
      print('🔐 [VERIFY_EMAIL] Headers: ${response.headers}');
      print('🔐 [VERIFY_EMAIL] Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('🔐 [VERIFY_EMAIL] ✅ Email verification successful');
        return VerifyEmailResponse.fromJson(responseData);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AuthException(errorData['message'] ?? 'Invalid OTP', 400);
      } else if (response.statusCode == 404) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AuthException(errorData['message'] ?? 'User not found', 404);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AuthException(
            errorData['message'] ?? 'Verification failed', response.statusCode);
      }
    } catch (e) {
      print('🔐 [AUTH] Email verification error: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e', 0);
    }
  }

  // 3. Resend Verification OTP
  static Future<ResendVerificationResponse> resendVerification(
      ResendVerificationRequest request) async {
    try {
      print('🔐 [RESEND_VERIFICATION] ========== REQUEST ==========');
      print(
          '🔐 [RESEND_VERIFICATION] URL: $_baseUrl${ApiConstants.resendVerificationEndpoint}');
      print('🔐 [RESEND_VERIFICATION] Headers: ${ApiConstants.getHeaders()}');
      print('🔐 [RESEND_VERIFICATION] Body: ${jsonEncode(request.toJson())}');
      print('🔐 [RESEND_VERIFICATION] Email: ${request.email}');

      final response = await http.post(
        Uri.parse('$_baseUrl${ApiConstants.resendVerificationEndpoint}'),
        headers: ApiConstants.getHeaders(),
        body: jsonEncode(request.toJson()),
      );

      print('🔐 [RESEND_VERIFICATION] ========== RESPONSE ==========');
      print('🔐 [RESEND_VERIFICATION] Status Code: ${response.statusCode}');
      print('🔐 [RESEND_VERIFICATION] Headers: ${response.headers}');
      print('🔐 [RESEND_VERIFICATION] Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('🔐 [RESEND_VERIFICATION] ✅ Resend verification successful');
        return ResendVerificationResponse.fromJson(responseData);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AuthException(errorData['message'] ?? 'Email is required', 400);
      } else if (response.statusCode == 404) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AuthException(errorData['message'] ?? 'User not found', 404);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AuthException(
            errorData['message'] ?? 'Resend failed', response.statusCode);
      }
    } catch (e) {
      print('🔐 [AUTH] Resend verification error: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e', 0);
    }
  }

  // 4. Quick Registration
  static Future<QuickRegisterResponse> quickRegister(
      QuickRegisterRequest request) async {
    try {
      print('🔐 [QUICK_REGISTER] ========== REQUEST ==========');
      print(
          '🔐 [QUICK_REGISTER] URL: $_baseUrl${ApiConstants.quickRegisterEndpoint}');
      print('🔐 [QUICK_REGISTER] Headers: ${ApiConstants.getHeaders()}');
      print('🔐 [QUICK_REGISTER] Body: ${jsonEncode(request.toJson())}');
      print('🔐 [QUICK_REGISTER] Email: ${request.email}');

      final response = await http.post(
        Uri.parse('$_baseUrl${ApiConstants.quickRegisterEndpoint}'),
        headers: ApiConstants.getHeaders(),
        body: jsonEncode(request.toJson()),
      );

      print('🔐 [QUICK_REGISTER] ========== RESPONSE ==========');
      print('🔐 [QUICK_REGISTER] Status Code: ${response.statusCode}');
      print('🔐 [QUICK_REGISTER] Headers: ${response.headers}');
      print('🔐 [QUICK_REGISTER] Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('🔐 [QUICK_REGISTER] ✅ Quick registration successful');
        return QuickRegisterResponse.fromJson(responseData);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AuthException(errorData['message'] ?? 'Email is required', 400);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AuthException(errorData['message'] ?? 'Quick registration failed',
            response.statusCode);
      }
    } catch (e) {
      print('🔐 [AUTH] Quick registration error: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e', 0);
    }
  }

  // 5. Login
  static Future<LoginResponse> login(LoginRequest request) async {
    try {
      print('🔐 [LOGIN] ========== REQUEST ==========');
      print('🔐 [LOGIN] URL: $_baseUrl${ApiConstants.loginEndpoint}');
      print('🔐 [LOGIN] Headers: ${ApiConstants.getHeaders()}');
      print('🔐 [LOGIN] Body: ${jsonEncode(request.toJson())}');
      print('🔐 [LOGIN] Email: ${request.email}');
      print('🔐 [LOGIN] Password: ${'*' * request.password.length}');

      final response = await http.post(
        Uri.parse('$_baseUrl${ApiConstants.loginEndpoint}'),
        headers: ApiConstants.getHeaders(),
        body: jsonEncode(request.toJson()),
      );

      print('🔐 [LOGIN] ========== RESPONSE ==========');
      print('🔐 [LOGIN] Status Code: ${response.statusCode}');
      print('🔐 [LOGIN] Headers: ${response.headers}');
      print('🔐 [LOGIN] Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 307) {
        // Handle redirect by making another request to the redirected URL
        if (response.statusCode == 307) {
          final redirectUrl = response.headers['location'];
          if (redirectUrl != null) {
            print('🔐 [LOGIN] Following redirect to: $redirectUrl');
            final redirectResponse = await http.post(
              Uri.parse(redirectUrl),
              headers: ApiConstants.getHeaders(),
              body: jsonEncode(request.toJson()),
            );
            print(
                '🔐 [LOGIN] Redirect response status: ${redirectResponse.statusCode}');
            print(
                '🔐 [LOGIN] Redirect response body: ${redirectResponse.body}');

            if (redirectResponse.statusCode == 200) {
              final responseData =
                  jsonDecode(redirectResponse.body) as Map<String, dynamic>;
              print('🔐 [LOGIN] ✅ Login successful after redirect');
              return LoginResponse.fromJson(responseData);
            } else {
              final errorData =
                  jsonDecode(redirectResponse.body) as Map<String, dynamic>;
              throw AuthException(errorData['message'] ?? 'Login failed',
                  redirectResponse.statusCode);
            }
          }
        }

        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('🔐 [LOGIN] ✅ Login successful');
        return LoginResponse.fromJson(responseData);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AuthException(
            errorData['message'] ?? 'Email and password are required', 400);
      } else if (response.statusCode == 401) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final message = errorData['message'] ?? 'Invalid credentials';
        throw AuthException(message, 401);
      } else if (response.statusCode == 403) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AuthException(
            errorData['message'] ??
                'Please verify your email before logging in.',
            403);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AuthException(
            errorData['message'] ?? 'Login failed', response.statusCode);
      }
    } catch (e) {
      print('🔐 [AUTH] Login error: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e', 0);
    }
  }

  // 6. Password Reset Request
  static Future<ResetPasswordResponse> resetPassword(
      ResetPasswordRequest request) async {
    try {
      print('🔐 [RESET_PASSWORD] ========== REQUEST ==========');
      print(
          '🔐 [RESET_PASSWORD] URL: $_baseUrl${ApiConstants.resetPasswordEndpoint}');
      print('🔐 [RESET_PASSWORD] Headers: ${ApiConstants.getHeaders()}');
      print('🔐 [RESET_PASSWORD] Body: ${jsonEncode(request.toJson())}');
      print('🔐 [RESET_PASSWORD] Email: ${request.email}');

      final response = await http.post(
        Uri.parse('$_baseUrl${ApiConstants.resetPasswordEndpoint}'),
        headers: ApiConstants.getHeaders(),
        body: jsonEncode(request.toJson()),
      );

      print('🔐 [RESET_PASSWORD] ========== RESPONSE ==========');
      print('🔐 [RESET_PASSWORD] Status Code: ${response.statusCode}');
      print('🔐 [RESET_PASSWORD] Headers: ${response.headers}');
      print('🔐 [RESET_PASSWORD] Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('🔐 [RESET_PASSWORD] ✅ Password reset request successful');
        return ResetPasswordResponse.fromJson(responseData);
      } else if (response.statusCode == 404) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AuthException(
            errorData['message'] ?? 'Email not registered', 404);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AuthException(errorData['message'] ?? 'Password reset failed',
            response.statusCode);
      }
    } catch (e) {
      print('🔐 [AUTH] Password reset error: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e', 0);
    }
  }

  // 7. Password Reset OTP Verification
  static Future<VerifyResetOtpResponse> verifyResetOtp(
      VerifyResetOtpRequest request) async {
    try {
      print('🔐 [VERIFY_RESET_OTP] ========== REQUEST ==========');
      print(
          '🔐 [VERIFY_RESET_OTP] URL: $_baseUrl${ApiConstants.verifyResetOtpEndpoint}');
      print('🔐 [VERIFY_RESET_OTP] Headers: ${ApiConstants.getHeaders()}');
      print('🔐 [VERIFY_RESET_OTP] Body: ${jsonEncode(request.toJson())}');
      print('🔐 [VERIFY_RESET_OTP] Email: ${request.email}');
      print('🔐 [VERIFY_RESET_OTP] OTP: ${request.otp}');

      final response = await http.post(
        Uri.parse('$_baseUrl${ApiConstants.verifyResetOtpEndpoint}'),
        headers: ApiConstants.getHeaders(),
        body: jsonEncode(request.toJson()),
      );

      print('🔐 [VERIFY_RESET_OTP] ========== RESPONSE ==========');
      print('🔐 [VERIFY_RESET_OTP] Status Code: ${response.statusCode}');
      print('🔐 [VERIFY_RESET_OTP] Headers: ${response.headers}');
      print('🔐 [VERIFY_RESET_OTP] Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('🔐 [VERIFY_RESET_OTP] ✅ Reset OTP verification successful');
        return VerifyResetOtpResponse.fromJson(responseData);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AuthException(errorData['message'] ?? 'Invalid OTP', 400);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AuthException(errorData['message'] ?? 'OTP verification failed',
            response.statusCode);
      }
    } catch (e) {
      print('🔐 [AUTH] Reset OTP verification error: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e', 0);
    }
  }

  // 8. Set New Password
  static Future<SetNewPasswordResponse> setNewPassword(
      SetNewPasswordRequest request) async {
    try {
      print('🔐 [SET_NEW_PASSWORD] ========== REQUEST ==========');
      print(
          '🔐 [SET_NEW_PASSWORD] URL: $_baseUrl${ApiConstants.setNewPasswordEndpoint}');
      print('🔐 [SET_NEW_PASSWORD] Headers: ${ApiConstants.getHeaders()}');
      print('🔐 [SET_NEW_PASSWORD] Body: ${jsonEncode(request.toJson())}');
      print('🔐 [SET_NEW_PASSWORD] Email: ${request.email}');
      print(
          '🔐 [SET_NEW_PASSWORD] New Password: ${'*' * request.newPassword.length}');

      final response = await http.post(
        Uri.parse('$_baseUrl${ApiConstants.setNewPasswordEndpoint}'),
        headers: ApiConstants.getHeaders(),
        body: jsonEncode(request.toJson()),
      );

      print('🔐 [SET_NEW_PASSWORD] ========== RESPONSE ==========');
      print('🔐 [SET_NEW_PASSWORD] Status Code: ${response.statusCode}');
      print('🔐 [SET_NEW_PASSWORD] Headers: ${response.headers}');
      print('🔐 [SET_NEW_PASSWORD] Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('🔐 [SET_NEW_PASSWORD] ✅ Set new password successful');
        return SetNewPasswordResponse.fromJson(responseData);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AuthException(
            errorData['message'] ?? 'Missing required fields', 400);
      } else if (response.statusCode == 404) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AuthException(errorData['message'] ?? 'User not found', 404);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AuthException(
            errorData['message'] ?? 'Set password failed', response.statusCode);
      }
    } catch (e) {
      print('🔐 [AUTH] Set new password error: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e', 0);
    }
  }

  // 9. Get User Profile
  static Future<UserProfileResponse> getUserProfile(String token) async {
    try {
      print('🔐 [GET_USER_PROFILE] ========== REQUEST ==========');
      print(
          '🔐 [GET_USER_PROFILE] URL: $_baseUrl${ApiConstants.getUserProfileEndpoint}');
      print(
          '🔐 [GET_USER_PROFILE] Headers: ${ApiConstants.getHeaders(token: token)}');
      print('🔐 [GET_USER_PROFILE] Token: ${token.substring(0, 10)}...');

      final response = await http.get(
        Uri.parse('$_baseUrl${ApiConstants.getUserProfileEndpoint}'),
        headers: ApiConstants.getHeaders(token: token),
      );

      print('🔐 [GET_USER_PROFILE] ========== RESPONSE ==========');
      print('🔐 [GET_USER_PROFILE] Status Code: ${response.statusCode}');
      print('🔐 [GET_USER_PROFILE] Headers: ${response.headers}');
      print('🔐 [GET_USER_PROFILE] Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('🔐 [GET_USER_PROFILE] ✅ Get user profile successful');
        return UserProfileResponse.fromJson(responseData);
      } else if (response.statusCode == 401) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AuthException(errorData['message'] ?? 'Unauthorized', 401);
      } else if (response.statusCode == 404) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AuthException(errorData['message'] ?? 'User not found', 404);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AuthException(
            errorData['message'] ?? 'Get profile failed', response.statusCode);
      }
    } catch (e) {
      print('🔐 [AUTH] Get user profile error: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e', 0);
    }
  }
}
