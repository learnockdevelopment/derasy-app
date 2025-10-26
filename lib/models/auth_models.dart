import 'user.dart';

// ==================== REQUEST MODELS ====================

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class RegisterRequest {
  final String name;
  final String email;
  final String password;
  final String role;

  RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    this.role = 'parent',
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    };
  }
}

class QuickRegisterRequest {
  final String email;

  QuickRegisterRequest({
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}

class VerifyEmailRequest {
  final String email;
  final String otp;

  VerifyEmailRequest({
    required this.email,
    required this.otp,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otp': otp,
    };
  }
}

class ResendVerificationRequest {
  final String email;

  ResendVerificationRequest({
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}

class ResetPasswordRequest {
  final String email;

  ResetPasswordRequest({
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}

class VerifyResetOtpRequest {
  final String email;
  final String otp;

  VerifyResetOtpRequest({
    required this.email,
    required this.otp,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otp': otp,
    };
  }
}

class SetNewPasswordRequest {
  final String email;
  final String newPassword;

  SetNewPasswordRequest({
    required this.email,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'newPassword': newPassword,
    };
  }
}

// ==================== RESPONSE MODELS ====================

class LoginResponse {
  final String message;
  final String token;
  final User user;
  final String? redirectUrl;

  LoginResponse({
    required this.message,
    required this.token,
    required this.user,
    this.redirectUrl,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      user: User.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      redirectUrl: json['redirectUrl']?.toString(),
    );
  }
}

class RegisterResponse {
  final String message;

  RegisterResponse({
    required this.message,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      message: json['message']?.toString() ?? '',
    );
  }
}

class QuickRegisterResponse {
  final String message;

  QuickRegisterResponse({
    required this.message,
  });

  factory QuickRegisterResponse.fromJson(Map<String, dynamic> json) {
    return QuickRegisterResponse(
      message: json['message']?.toString() ?? '',
    );
  }
}

class VerifyEmailResponse {
  final String message;
  final String token;
  final bool correct;

  VerifyEmailResponse({
    required this.message,
    required this.token,
    required this.correct,
  });

  factory VerifyEmailResponse.fromJson(Map<String, dynamic> json) {
    return VerifyEmailResponse(
      message: json['message']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      correct: json['correct'] ?? false,
    );
  }
}

class ResendVerificationResponse {
  final String message;

  ResendVerificationResponse({
    required this.message,
  });

  factory ResendVerificationResponse.fromJson(Map<String, dynamic> json) {
    return ResendVerificationResponse(
      message: json['message']?.toString() ?? '',
    );
  }
}

class ResetPasswordResponse {
  final String message;

  ResetPasswordResponse({
    required this.message,
  });

  factory ResetPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ResetPasswordResponse(
      message: json['message']?.toString() ?? '',
    );
  }
}

class VerifyResetOtpResponse {
  final bool success;
  final String message;

  VerifyResetOtpResponse({
    required this.success,
    required this.message,
  });

  factory VerifyResetOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyResetOtpResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
    );
  }
}

class SetNewPasswordResponse {
  final bool success;
  final String message;

  SetNewPasswordResponse({
    required this.success,
    required this.message,
  });

  factory SetNewPasswordResponse.fromJson(Map<String, dynamic> json) {
    return SetNewPasswordResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
    );
  }
}

class UserProfileResponse {
  final User user;

  UserProfileResponse({
    required this.user,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
    );
  }
}

// ==================== ERROR MODELS ====================

class AuthError {
  final String message;
  final int? statusCode;

  AuthError({
    required this.message,
    this.statusCode,
  });

  factory AuthError.fromJson(Map<String, dynamic> json) {
    return AuthError(
      message: json['message']?.toString() ?? 'Unknown error',
      statusCode: json['statusCode'] as int?,
    );
  }
}

class AuthException implements Exception {
  final String message;
  final int statusCode;

  AuthException(this.message, this.statusCode);

  @override
  String toString() => message;
}
