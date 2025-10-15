import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../models/authentication/auth_models.dart';

class AuthService {
  static const String _baseUrl = ApiConstants.baseUrl;
  static const String _apiKey = ApiConstants.apiKey;

  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    print('🔐 [AUTH] Starting registration for: $email');
    print(
        '🔐 [AUTH] Request data: firstName=$firstName, lastName=$lastName, phone=$phone, role=$role');

    try {
      final requestBody = {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
      };

      print(
          '🔐 [AUTH] Sending POST request to: $_baseUrl${ApiConstants.registerEndpoint}');
      print('🔐 [AUTH] Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_baseUrl${ApiConstants.registerEndpoint}'),
        headers: ApiConstants.defaultHeaders,
        body: jsonEncode(requestBody),
      );

      print('🔐 [AUTH] Response status: ${response.statusCode}');
      print('🔐 [AUTH] Response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('🔐 [AUTH] Registration successful');
        return responseData;
      } else {
        print(
            '🔐 [AUTH] Registration failed with status: ${response.statusCode}');
        throw Exception('Registration failed: ${response.body}');
      }
    } catch (e) {
      print('🔐 [AUTH] Registration error: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> verifyEmail({
    required String userId,
    required String action,
    String? code,
  }) async {
    print('🔐 [AUTH] Starting email verification for userId: $userId');
    print('🔐 [AUTH] Action: $action, Code: ${code ?? 'null'}');

    try {
      final body = {
        'userId': userId,
        'action': action,
      };

      if (code != null) {
        body['code'] = code;
      }

      print(
          '🔐 [AUTH] Sending POST request to: $_baseUrl/api/auth/register/verify-email');
      print('🔐 [AUTH] Request body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/register/verify-email'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
        },
        body: jsonEncode(body),
      );

      print('🔐 [AUTH] Response status: ${response.statusCode}');
      print('🔐 [AUTH] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('🔐 [AUTH] Email verification successful');

        // Print verification code if available
        if (responseData['devCode'] != null) {
          print(
              '🔐 [AUTH] 📧 EMAIL VERIFICATION CODE: ${responseData['devCode']}');
        }
        if (responseData['code'] != null) {
          print(
              '🔐 [AUTH] 📧 EMAIL VERIFICATION CODE: ${responseData['code']}');
        }

        return responseData;
      } else {
        print(
            '🔐 [AUTH] Email verification failed with status: ${response.statusCode}');
        throw Exception('Email verification failed: ${response.body}');
      }
    } catch (e) {
      print('🔐 [AUTH] Email verification error: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> verifyPhone({
    required String userId,
    required String action,
    String? code,
  }) async {
    print('🔐 [AUTH] Starting phone verification for userId: $userId');
    print('🔐 [AUTH] Action: $action, Code: ${code ?? 'null'}');

    try {
      final body = {
        'userId': userId,
        'action': action,
      };

      if (code != null) {
        body['code'] = code;
      }

      print(
          '🔐 [AUTH] Sending POST request to: $_baseUrl/api/auth/register/verify-phone');
      print('🔐 [AUTH] Request body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/register/verify-phone'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
        },
        body: jsonEncode(body),
      );

      print('🔐 [AUTH] Response status: ${response.statusCode}');
      print('🔐 [AUTH] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('🔐 [AUTH] Phone verification successful');

        // Print verification code if available
        if (responseData['devCode'] != null) {
          print(
              '🔐 [AUTH] 📱 PHONE VERIFICATION CODE: ${responseData['devCode']}');
        }
        if (responseData['code'] != null) {
          print(
              '🔐 [AUTH] 📱 PHONE VERIFICATION CODE: ${responseData['code']}');
        }

        return responseData;
      } else {
        print(
            '🔐 [AUTH] Phone verification failed with status: ${response.statusCode}');
        throw Exception('Phone verification failed: ${response.body}');
      }
    } catch (e) {
      print('🔐 [AUTH] Phone verification error: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> login({
    required String loginField,
    required String password,
  }) async {
    print('🔐 [AUTH] Starting login for: $loginField');
    print('🔐 [AUTH] Password: ${password.replaceAll(RegExp(r'.'), '*')}');

    try {
      final requestBody = {
        'login_field': loginField,
        'password': password,
      };

      print(
          '🔐 [AUTH] Sending POST request to: $_baseUrl${ApiConstants.loginEndpoint}');
      print('🔐 [AUTH] Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_baseUrl${ApiConstants.loginEndpoint}'),
        headers: ApiConstants.defaultHeaders,
        body: jsonEncode(requestBody),
      );

      print('🔐 [AUTH] Response status: ${response.statusCode}');
      print('🔐 [AUTH] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('🔐 [AUTH] Login successful');
        return responseData;
      } else if (response.statusCode == 401) {
        print('🔐 [AUTH] Login failed: Invalid credentials');
        throw Exception('Invalid credentials');
      } else if (response.statusCode == 403) {
        print('🔐 [AUTH] Login failed: User is banned');
        throw Exception('User is banned');
      } else {
        print('🔐 [AUTH] Login failed with status: ${response.statusCode}');
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      print('🔐 [AUTH] Login error: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> sendOtpToPhone({
    required String phoneNumber,
  }) async {
    print('🔐 [AUTH] Starting send OTP to phone: $phoneNumber');

    try {
      final requestBody = {
        'phone_number': phoneNumber,
      };

      print(
          '🔐 [AUTH] Sending POST request to: $_baseUrl${ApiConstants.otpPhoneEndpoint}');
      print('🔐 [AUTH] Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_baseUrl${ApiConstants.otpPhoneEndpoint}'),
        headers: ApiConstants.defaultHeaders,
        body: jsonEncode(requestBody),
      );

      print('🔐 [AUTH] Response status: ${response.statusCode}');
      print('🔐 [AUTH] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('🔐 [AUTH] OTP sent to phone successfully');

        // Extract OTP from message if available
        if (responseData['message'] != null &&
            responseData['message'].toString().contains(',')) {
          final parts = responseData['message'].toString().split(',');
          if (parts.length > 1) {
            responseData['otp'] = parts[1].trim();
            print('🔐 [AUTH] 🔑 SMS OTP CODE: ${parts[1].trim()}');
          }
        }

        return responseData;
      } else {
        print(
            '🔐 [AUTH] Send OTP to phone failed with status: ${response.statusCode}');
        String errorMessage = response.body.isNotEmpty
            ? response.body
            : 'Server returned ${response.statusCode} with no message';
        throw AuthException(
            'Send OTP to phone failed: $errorMessage', response.statusCode);
      }
    } catch (e) {
      print('🔐 [AUTH] Send OTP to phone error: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e', 0);
    }
  }

  static Future<Map<String, dynamic>> validateOtpFromPhone({
    required String phoneNumber,
    required String code,
  }) async {
    print('🔐 [AUTH] Starting validate OTP from phone: $phoneNumber');

    try {
      final requestBody = {
        'phone_number': phoneNumber,
        'code': code,
      };

      print(
          '🔐 [AUTH] Sending POST request to: $_baseUrl${ApiConstants.validateOtpPhoneEndpoint}');
      print('🔐 [AUTH] Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_baseUrl${ApiConstants.validateOtpPhoneEndpoint}'),
        headers: ApiConstants.defaultHeaders,
        body: jsonEncode(requestBody),
      );

      print('🔐 [AUTH] Response status: ${response.statusCode}');
      print('🔐 [AUTH] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('🔐 [AUTH] OTP validation successful');
        return responseData;
      } else {
        print(
            '🔐 [AUTH] Validate OTP from phone failed with status: ${response.statusCode}');
        String errorMessage = response.body.isNotEmpty
            ? response.body
            : 'Server returned ${response.statusCode} with no message';
        throw AuthException('Validate OTP from phone failed: $errorMessage',
            response.statusCode);
      }
    } catch (e) {
      print('🔐 [AUTH] Validate OTP from phone error: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e', 0);
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    print('🔐 [AUTH] Starting reset password for: $email');
    print('🔐 [AUTH] OTP: ****');
    print('🔐 [AUTH] Password: ${password.replaceAll(RegExp(r'.'), '*')}');

    try {
      final requestBody = {
        'email': email,
        'otp': otp,
        'password': password,
        'password_confirmation': passwordConfirmation,
      };

      final url = Uri.parse('$_baseUrl${ApiConstants.resetPasswordEndpoint}');
      print('🔐 [AUTH] Sending POST request to: $url');
      print('🔐 [AUTH] Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: ApiConstants.defaultHeaders,
        body: jsonEncode(requestBody),
      );

      print('🔐 [AUTH] Response status: ${response.statusCode}');
      print('🔐 [AUTH] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('🔐 [AUTH] Reset password successful');
        return responseData;
      } else {
        print(
            '🔐 [AUTH] Reset password failed with status: ${response.statusCode}');
        String errorMessage = response.body.isNotEmpty
            ? response.body
            : 'Server returned ${response.statusCode} with no message';

        // Truncate HTML error messages to prevent UI overflow
        if (errorMessage.contains('<!DOCTYPE html>')) {
          errorMessage = 'API endpoint not found (404)';
        } else if (errorMessage.length > 200) {
          errorMessage = errorMessage.substring(0, 200) + '...';
        }

        throw AuthException(
            'Reset password failed: $errorMessage', response.statusCode);
      }
    } catch (e) {
      print('🔐 [AUTH] Reset password error: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e', 0);
    }
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String token,
  }) async {
    print('🔐 [AUTH] Starting change password');
    print(
        '🔐 [AUTH] Request data: currentPassword length=${currentPassword.length}, newPassword length=${newPassword.length}');

    try {
      final requestBody = {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      };

      final url = Uri.parse('$_baseUrl/api/auth/change-password');
      print('🔐 [AUTH] Sending POST request to: $url');
      print('🔐 [AUTH] Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('🔐 [AUTH] Response status: ${response.statusCode}');
      print('🔐 [AUTH] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('🔐 [AUTH] Change password successful');
        return responseData;
      } else {
        print(
            '🔐 [AUTH] Change password failed with status: ${response.statusCode}');
        String errorMessage = response.body.isNotEmpty
            ? response.body
            : 'Server returned ${response.statusCode} with no message';

        // Truncate HTML error messages to prevent UI overflow
        if (errorMessage.contains('<!DOCTYPE html>')) {
          errorMessage = 'API endpoint not found (404)';
        } else if (errorMessage.length > 200) {
          errorMessage = errorMessage.substring(0, 200) + '...';
        }

        throw AuthException(
            'Change password failed: $errorMessage', response.statusCode);
      }
    } catch (e) {
      print('🔐 [AUTH] Change password error: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e', 0);
    }
  }

  // Verify Email with OTP
  static Future<Map<String, dynamic>> verifyEmailOtp({
    required int userId,
    required String otp,
  }) async {
    print('🔐 [AUTH] Starting email verification for user: $userId');
    print('🔐 [AUTH] OTP: ${otp.replaceAll(RegExp(r'.'), '*')}');

    try {
      final requestBody = {
        'user_id': userId,
        'otp': otp,
      };

      print('🔐 [AUTH] Sending POST request to: $_baseUrl/auth/verify-email');
      print('🔐 [AUTH] Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/verify-email'),
        headers: ApiConstants.defaultHeaders,
        body: jsonEncode(requestBody),
      );

      print('🔐 [AUTH] Response status: ${response.statusCode}');
      print('🔐 [AUTH] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('🔐 [AUTH] Email verification successful');
        return responseData;
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage =
            errorData['message'] ?? 'Email verification failed';
        print('🔐 [AUTH] Email verification failed: $errorMessage');
        throw AuthException(errorMessage, response.statusCode);
      }
    } catch (e) {
      print('🔐 [AUTH] Email verification error: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e', 0);
    }
  }

  // Verify Phone with OTP
  static Future<Map<String, dynamic>> verifyPhoneOtp({
    required int userId,
    required String otp,
  }) async {
    print('🔐 [AUTH] Starting phone verification for user: $userId');
    print('🔐 [AUTH] OTP: ${otp.replaceAll(RegExp(r'.'), '*')}');

    try {
      final requestBody = {
        'user_id': userId,
        'otp': otp,
      };

      print('🔐 [AUTH] Sending POST request to: $_baseUrl/auth/verify-phone');
      print('🔐 [AUTH] Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/verify-phone'),
        headers: ApiConstants.defaultHeaders,
        body: jsonEncode(requestBody),
      );

      print('🔐 [AUTH] Response status: ${response.statusCode}');
      print('🔐 [AUTH] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('🔐 [AUTH] Phone verification successful');
        return responseData;
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage =
            errorData['message'] ?? 'Phone verification failed';
        print('🔐 [AUTH] Phone verification failed: $errorMessage');
        throw AuthException(errorMessage, response.statusCode);
      }
    } catch (e) {
      print('🔐 [AUTH] Phone verification error: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e', 0);
    }
  }

  // Send OTP to Email for Password Reset
  static Future<Map<String, dynamic>> sendOtpToEmail({
    required String email,
  }) async {
    print('🔐 [AUTH] Starting send OTP to email for: $email');

    try {
      final requestBody = {
        'email': email,
      };

      print('🔐 [AUTH] Sending POST request to: $_baseUrl/auth/otp_mail');
      print('🔐 [AUTH] Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/otp_mail'),
        headers: ApiConstants.defaultHeaders,
        body: jsonEncode(requestBody),
      );

      print('🔐 [AUTH] Response status: ${response.statusCode}');
      print('🔐 [AUTH] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('🔐 [AUTH] Send OTP to email successful');
        return responseData;
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = errorData['message'] ?? 'Failed to send OTP';
        print('🔐 [AUTH] Send OTP to email failed: $errorMessage');
        throw AuthException(errorMessage, response.statusCode);
      }
    } catch (e) {
      print('🔐 [AUTH] Send OTP to email error: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e', 0);
    }
  }

  // Validate OTP from Email
  static Future<Map<String, dynamic>> validateOtpFromEmail({
    required String email,
    required String otp,
  }) async {
    print('🔐 [AUTH] Starting validate OTP for email: $email');

    try {
      final requestBody = {
        'email': email,
        'otp': otp,
      };

      print(
          '🔐 [AUTH] Sending POST request to: $_baseUrl/auth/validate_otp_mail');
      print('🔐 [AUTH] Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/validate_otp_mail'),
        headers: ApiConstants.defaultHeaders,
        body: jsonEncode(requestBody),
      );

      print('🔐 [AUTH] Response status: ${response.statusCode}');
      print('🔐 [AUTH] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('🔐 [AUTH] Validate OTP successful');
        return responseData;
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = errorData['message'] ?? 'OTP validation failed';
        print('🔐 [AUTH] Validate OTP failed: $errorMessage');
        throw AuthException(errorMessage, response.statusCode);
      }
    } catch (e) {
      print('🔐 [AUTH] Validate OTP error: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e', 0);
    }
  }

  // Reset Password
  static Future<Map<String, dynamic>> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    print('🔐 [AUTH] Starting reset password for: $email');

    try {
      final requestBody = {
        'email': email,
        'otp': otp,
        'password': password,
        'password_confirmation': passwordConfirmation,
      };

      print('🔐 [AUTH] Sending POST request to: $_baseUrl/auth/reset_password');
      print('🔐 [AUTH] Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/reset_password'),
        headers: ApiConstants.defaultHeaders,
        body: jsonEncode(requestBody),
      );

      print('🔐 [AUTH] Response status: ${response.statusCode}');
      print('🔐 [AUTH] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('🔐 [AUTH] Reset password successful');
        return responseData;
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = errorData['message'] ?? 'Reset password failed';
        print('🔐 [AUTH] Reset password failed: $errorMessage');
        throw AuthException(errorMessage, response.statusCode);
      }
    } catch (e) {
      print('🔐 [AUTH] Reset password error: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e', 0);
    }
  }
}
