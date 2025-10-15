class RegisterRequest {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String password;
  final String role;

  RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
    };
  }
}

class RegisterResponse {
  final bool success;
  final String message;
  final UserData data;
  final int statusCode;

  RegisterResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.statusCode,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      success: (json['success'] as bool?) ?? false,
      message: json['message']?.toString() ?? '',
      data: UserData.fromJson((json['data'] as Map<String, dynamic>?) ?? {}),
      statusCode: (json['status_code'] as int?) ?? 0,
    );
  }
}

class VerifyEmailRequest {
  final String userId;
  final String action;
  final String? code;

  VerifyEmailRequest({
    required this.userId,
    required this.action,
    this.code,
  });

  Map<String, dynamic> toJson() {
    final body = {
      'userId': userId,
      'action': action,
    };

    if (code != null) {
      body['code'] = code!;
    }

    return body;
  }
}

class VerifyEmailResponse {
  final bool sent;
  final bool verified;
  final String? devCode;

  VerifyEmailResponse({
    required this.sent,
    required this.verified,
    this.devCode,
  });

  factory VerifyEmailResponse.fromJson(Map<String, dynamic> json) {
    return VerifyEmailResponse(
      sent: (json['sent'] as bool?) ?? false,
      verified: (json['verified'] as bool?) ?? false,
      devCode: json['devCode']?.toString(),
    );
  }
}

class VerifyPhoneRequest {
  final String userId;
  final String action;
  final String? code;

  VerifyPhoneRequest({
    required this.userId,
    required this.action,
    this.code,
  });

  Map<String, dynamic> toJson() {
    final body = {
      'userId': userId,
      'action': action,
    };

    if (code != null) {
      body['code'] = code!;
    }

    return body;
  }
}

class VerifyPhoneResponse {
  final bool sent;
  final bool verified;
  final String? devCode;

  VerifyPhoneResponse({
    required this.sent,
    required this.verified,
    this.devCode,
  });

  factory VerifyPhoneResponse.fromJson(Map<String, dynamic> json) {
    return VerifyPhoneResponse(
      sent: (json['sent'] as bool?) ?? false,
      verified: (json['verified'] as bool?) ?? false,
      devCode: json['devCode']?.toString(),
    );
  }
}

class SetPasswordRequest {
  final String userId;
  final String password;

  SetPasswordRequest({
    required this.userId,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'password': password,
    };
  }
}

class SetPasswordResponse {
  final String token;

  SetPasswordResponse({
    required this.token,
  });

  factory SetPasswordResponse.fromJson(Map<String, dynamic> json) {
    return SetPasswordResponse(
      token: json['token']?.toString() ?? '',
    );
  }
}

class UserData {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String role;
  final String? image;
  final String createdAt;
  final String updatedAt;

  UserData({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    this.image,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: (json['id'] as int?) ?? 0,
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      image: json['image']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}

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

class LoginResponse {
  final bool success;
  final String message;
  final LoginData data;
  final int statusCode;

  LoginResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.statusCode,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: (json['success'] as bool?) ?? false,
      message: json['message']?.toString() ?? '',
      data: LoginData.fromJson((json['data'] as Map<String, dynamic>?) ?? {}),
      statusCode: (json['status_code'] as int?) ?? 0,
    );
  }
}

class LoginData {
  final String token;
  final UserData user;

  LoginData({
    required this.token,
    required this.user,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      token: json['token']?.toString() ?? '',
      user: UserData.fromJson((json['user'] as Map<String, dynamic>?) ?? {}),
    );
  }
}

class OtpMailRequest {
  final String email;

  OtpMailRequest({
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}

class OtpMailResponse {
  final bool success;
  final String message;
  final dynamic data;
  final int statusCode;

  OtpMailResponse({
    required this.success,
    required this.message,
    this.data,
    required this.statusCode,
  });

  factory OtpMailResponse.fromJson(Map<String, dynamic> json) {
    return OtpMailResponse(
      success: (json['success'] as bool?) ?? false,
      message: json['message']?.toString() ?? '',
      data: json['data'],
      statusCode: (json['status_code'] as int?) ?? 0,
    );
  }
}

class ValidateOtpMailRequest {
  final String email;
  final String otp;

  ValidateOtpMailRequest({
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

class ValidateOtpMailResponse {
  final bool success;
  final String message;
  final dynamic data;
  final int statusCode;

  ValidateOtpMailResponse({
    required this.success,
    required this.message,
    this.data,
    required this.statusCode,
  });

  factory ValidateOtpMailResponse.fromJson(Map<String, dynamic> json) {
    return ValidateOtpMailResponse(
      success: (json['success'] as bool?) ?? false,
      message: json['message']?.toString() ?? '',
      data: json['data'],
      statusCode: (json['status_code'] as int?) ?? 0,
    );
  }
}

class OtpPhoneRequest {
  final String phoneNumber;

  OtpPhoneRequest({
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phoneNumber,
    };
  }
}

class OtpPhoneResponse {
  final bool success;
  final String message;
  final dynamic data;
  final int statusCode;

  OtpPhoneResponse({
    required this.success,
    required this.message,
    this.data,
    required this.statusCode,
  });

  factory OtpPhoneResponse.fromJson(Map<String, dynamic> json) {
    return OtpPhoneResponse(
      success: (json['success'] as bool?) ?? false,
      message: json['message']?.toString() ?? '',
      data: json['data'],
      statusCode: (json['status_code'] as int?) ?? 0,
    );
  }
}

class ValidateOtpPhoneRequest {
  final String phoneNumber;
  final String code;

  ValidateOtpPhoneRequest({
    required this.phoneNumber,
    required this.code,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phoneNumber,
      'code': code,
    };
  }
}

class ValidateOtpPhoneResponse {
  final bool success;
  final String message;
  final dynamic data;
  final int statusCode;

  ValidateOtpPhoneResponse({
    required this.success,
    required this.message,
    this.data,
    required this.statusCode,
  });

  factory ValidateOtpPhoneResponse.fromJson(Map<String, dynamic> json) {
    return ValidateOtpPhoneResponse(
      success: (json['success'] as bool?) ?? false,
      message: json['message']?.toString() ?? '',
      data: json['data'],
      statusCode: (json['status_code'] as int?) ?? 0,
    );
  }
}

class ResetPasswordRequest {
  final String email;
  final String otp;
  final String password;
  final String passwordConfirmation;

  ResetPasswordRequest({
    required this.email,
    required this.otp,
    required this.password,
    required this.passwordConfirmation,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otp': otp,
      'password': password,
      'password_confirmation': passwordConfirmation,
    };
  }
}

class ResetPasswordResponse {
  final bool success;
  final String message;
  final dynamic data;
  final int statusCode;

  ResetPasswordResponse({
    required this.success,
    required this.message,
    this.data,
    required this.statusCode,
  });

  factory ResetPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ResetPasswordResponse(
      success: (json['success'] as bool?) ?? false,
      message: json['message']?.toString() ?? '',
      data: json['data'],
      statusCode: (json['status_code'] as int?) ?? 0,
    );
  }
}

class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;

  ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    };
  }
}

class ChangePasswordResponse {
  final bool success;
  final String message;

  ChangePasswordResponse({
    required this.success,
    required this.message,
  });

  factory ChangePasswordResponse.fromJson(Map<String, dynamic> json) {
    return ChangePasswordResponse(
      success: (json['success'] as bool?) ?? false,
      message: json['message']?.toString() ?? '',
    );
  }
}

class AuthError {
  final String message;

  AuthError({
    required this.message,
  });

  factory AuthError.fromJson(Map<String, dynamic> json) {
    return AuthError(
      message: json['message']?.toString() ?? 'Unknown error',
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
