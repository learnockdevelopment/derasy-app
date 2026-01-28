class ApiConstants {
  // API Configuration
  static const String baseUrl = 'https://www.derasy.com/api';
  static const String apiKey = 'external_key_123';
  static const String apiKeyHeader = 'x-api-key';
  static const String authorizationHeader = 'Authorization';

  // Auth Endpoints
  static const String loginEndpoint = '/login';
  static const String googleLoginEndpoint = '/auth/mobile/google';
  static const String appleLoginEndpoint = '/auth/mobile/apple';
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

  // Children Endpoints
  static const String getRelatedChildrenEndpoint = '/children/get-related';
  static const String addChildrenEndpoint = '/children';
  static const String getChildrenBySchoolEndpoint = '/children';
  static const String extractBirthCertificateEndpoint = '/children/extract-birth-certificate';
  static const String extractNationalIdEndpoint = '/children/extract-national-id';

  static const String submitNonEgyptianRequestEndpoint = '/children/non-egyptian-request';
  static const String getNonEgyptianRequestsEndpoint = '/children/non-egyptian-requests';
  static const String sendOtpEndpoint = '/children/send-otp';
  static const String verifyOtpEndpoint = '/children/verify-otp';
  static const String updateChildEndpoint = '/children/get-related'; // PUT /api/children/get-related/[id]
  static const String deleteChildEndpoint = '/children/get-related'; // DELETE /api/children/get-related/[id]

  // Admission Endpoints
  static const String applyToSchoolsEndpoint = '/admission/apply';
  static const String createApplicationEndpoint = '/application';
  static const String getApplicationsEndpoint = '/application';
  static const String getAdmissionApplicationsEndpoint = '/me/applications';
  static const String reorderApplicationsEndpoint = '/applications/reorder';
  static const String getSchoolApplicationsEndpoint = '/schools/my/[id]/admission-forms';
  static const String getSingleApplicationEndpoint = '/me/applications/school/my';
  static const String addApplicationEventEndpoint = '/me/applications/school/my/[id]/events';
  static const String updateApplicationStatusEndpoint = '/me/applications/school/my/[id]/status';

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

  // Public Endpoints (No Auth Required)
  static const String appConfigEndpoint = '/public/app-config';
  static const String createAttendanceEndpoint = '/attendance/create';
  static const String getAttendanceByChildEndpoint =
      '/attendance/by-child/[childId]';

  // Schools Endpoints
  static const String getAllSchoolsEndpoint = '/schools';

  // Chatbot Endpoints
  static const String chatbotEndpoint = '/chatbot';

  // Bus Endpoints
  static const String getBusesEndpoint = '/schools/my/[id]/buses';
  static const String getBusDetailsEndpoint = '/schools/my/[id]/buses/[busId]';
  static const String createBusEndpoint = '/schools/my/[id]/buses';
  static const String updateBusEndpoint = '/schools/my/[id]/buses/[busId]';
  static const String deleteBusEndpoint = '/schools/my/[id]/buses/[busId]';
  static const String busRoutesEndpoint = '/schools/my/[id]/buses/[busId]/routes';
  static const String busStudentsEndpoint = '/schools/my/[id]/buses/[busId]/students';
  static const String busLocationEndpoint = '/schools/my/[id]/buses/[busId]/location';
  static const String busLinesEndpoint = '/schools/my/[id]/buses/[busId]/lines';
  static const String busLineDetailsEndpoint = '/schools/my/[id]/buses/[busId]/lines/[lineId]';
  static const String busStationAttendanceEndpoint =
      '/schools/my/[id]/buses/[busId]/lines/[lineId]/stations/[stationOrder]/attendance';

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

