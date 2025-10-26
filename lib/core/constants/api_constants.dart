class ApiConstants {
  // API Configuration
  static const String baseUrl = 'https://www.derasy.com/api';
  static const String apiKey = 'external_key_123';
  static const String apiKeyHeader = 'x-api-key';
  static const String authorizationHeader = 'Authorization';

  // Auth Endpoints
  static const String loginEndpoint = '/login';
  static const String registerEndpoint = '/register';
  static const String quickRegisterEndpoint = '/register/quick-register';
  static const String verifyEmailEndpoint = '/register/verify';
  static const String resendVerificationEndpoint =
      '/register/resend-verification';
  static const String resetPasswordEndpoint = '/register/reset-password';
  static const String verifyResetOtpEndpoint =
      '/register/reset-password/verify';
  static const String setNewPasswordEndpoint =
      '/register/reset-password/new-password';
  static const String getUserProfileEndpoint = '/me';

  // Students Endpoints
  static const String getAllStudentsEndpoint = '/schools/my/[id]/students';
  static const String getGradesEndpoint = '/schools/my/[id]/grades';
  static const String addStudentEndpoint = '/schools/my/[id]/students/add';
  static const String updateStudentEndpoint =
      '/schools/my/[id]/students/[studentId]';
  static const String deleteStudentEndpoint =
      '/schools/my/[id]/students/[studentId]';

  // Guardians Endpoints
  static const String updateStudentGuardiansEndpoint =
      '/schools/my/[id]/students/[studentId]';

  // Pickup Permissions Endpoints
  static const String getPickupPermissionsEndpoint =
      '/schools/my/[id]/students/[studentId]/pickup-permission';
  static const String addPickupPermissionEndpoint =
      '/schools/my/[id]/students/[studentId]/pickup-permission';

  // Clinic Records Endpoints
  static const String getStudentClinicRecordsEndpoint =
      '/schools/my/[id]/clinic/students/[studentId]';

  // Attendance Endpoints
  static const String getAllAttendanceEndpoint = '/attendance';
  static const String createAttendanceEndpoint = '/attendance/create';
  static const String getAttendanceByChildEndpoint =
      '/attendance/by-child/[childId]';

  // Schools Endpoints
  static const String getAllSchoolsEndpoint = '/schools/my';

  // Headers
  static Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
        apiKeyHeader: apiKey,
      };

  static Map<String, String> getAuthHeaders(String token) => {
        ...defaultHeaders,
        authorizationHeader: 'Bearer $token',
      };

  // Helper method to get headers with optional token
  static Map<String, String> getHeaders({String? token}) {
    if (token != null && token.isNotEmpty) {
      return getAuthHeaders(token);
    }
    return defaultHeaders;
  }
}
