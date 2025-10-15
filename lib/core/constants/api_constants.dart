class ApiConstants {
  // API Configuration
  static const String baseUrl = 'https://yussuf.b-circles.co';
  static const String apiKey =
      'c542e686791fd09b7720e494c894bd42c5fbb8a98f19754a9798ea96987v2s5v';
  static const String apiKeyHeader = 'x-api-key';
  static const String authorizationHeader = 'Authorization';

  // Auth Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';
  static const String refreshTokenEndpoint = '/auth/refresh';

  // Password Reset Endpoints
  static const String resetPasswordEndpoint = '/auth/reset_password';

  // mail Verification Endpoints
  static const String otpMailEndpoint = '/auth/otp_mail';
  static const String validateOtpMailEndpoint = '/auth/validate_otp_mail';

  // SMS Verification Endpoints
  static const String otpPhoneEndpoint = '/auth/otp_phone';
  static const String validateOtpPhoneEndpoint = '/auth/validate_otp_phone';

  // Headers
  static Map<String, String> get defaultHeaders => {
        apiKeyHeader: apiKey,
        'Content-Type': 'application/json',
      };

  static Map<String, String> getAuthHeaders(String token) => {
        ...defaultHeaders,
        authorizationHeader: 'Bearer $token',
      };
}
