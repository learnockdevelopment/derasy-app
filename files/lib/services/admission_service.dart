import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/admission_models.dart';
import '../models/school_models.dart';
import '../models/student_models.dart';
import 'user_storage_service.dart';

class AdmissionService {
  static const String _baseUrl = ApiConstants.baseUrl;

  /// Apply to multiple schools with payment processing
  static Future<ApplyToSchoolsResponse> applyToSchools(
      ApplyToSchoolsRequest request) async {
    try {
      print('🎓 [ADMISSION] Applying to schools for child: ${request.childId}');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw AdmissionException('No authentication token found');
      }

      final url = _baseUrl + ApiConstants.applyToSchoolsEndpoint;
      final headers = ApiConstants.getAuthHeaders(token);

      print('🎓 [ADMISSION] URL: $url');
      print('🎓 [ADMISSION] Body: ${jsonEncode(request.toJson())}');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      print('🎓 [ADMISSION] Response status: ${response.statusCode}');
      print('🎓 [ADMISSION] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return ApplyToSchoolsResponse.fromJson(responseData);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AdmissionException(
            errorData['message']?.toString() ?? 'Bad request', 400);
      } else if (response.statusCode == 401) {
        throw AdmissionException('Unauthorized: User is not a parent', 401);
      } else if (response.statusCode == 403) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AdmissionException(
            errorData['message']?.toString() ?? 'Unauthorized', 403);
      } else if (response.statusCode == 409) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AdmissionException(
            errorData['message']?.toString() ?? 'Duplicate application exists',
            409);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AdmissionException(
            errorData['message']?.toString() ?? 'Failed to apply to schools',
            response.statusCode);
      }
    } catch (e) {
      print('🎓 [ADMISSION] Error applying to schools: $e');
      if (e is AdmissionException) {
        rethrow;
      } else {
        throw AdmissionException('Network error: ${e.toString()}');
      }
    }
  }

  /// Create a simple application
  static Future<Application> createApplication(
      CreateApplicationRequest request) async {
    try {
      print('🎓 [ADMISSION] Creating application');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw AdmissionException('No authentication token found');
      }

      final url = _baseUrl + ApiConstants.createApplicationEndpoint;
      final headers = ApiConstants.getAuthHeaders(token);

      print('🎓 [ADMISSION] URL: $url');
      print('🎓 [ADMISSION] Body: ${jsonEncode(request.toJson())}');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      print('🎓 [ADMISSION] Response status: ${response.statusCode}');
      print('🎓 [ADMISSION] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return Application.fromJson(responseData);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AdmissionException(
            errorData['message']?.toString() ?? 'Bad request', 400);
      } else if (response.statusCode == 401) {
        throw AdmissionException('Unauthorized: User is not a parent', 401);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AdmissionException(
            errorData['message']?.toString() ?? 'Failed to create application',
            response.statusCode);
      }
    } catch (e) {
      print('🎓 [ADMISSION] Error creating application: $e');
      if (e is AdmissionException) {
        rethrow;
      } else {
        throw AdmissionException('Network error: ${e.toString()}');
      }
    }
  }

  /// Get all applications for authenticated parent
  static Future<ApplicationsResponse> getApplications() async {
    try {
      print('🎓 [ADMISSION] Getting applications');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw AdmissionException('No authentication token found');
      }

      final url = _baseUrl + ApiConstants.getApplicationsEndpoint;
      final headers = ApiConstants.getAuthHeaders(token);

      print('🎓 [ADMISSION] URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('🎓 [ADMISSION] Response status: ${response.statusCode}');
      print('🎓 [ADMISSION] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return ApplicationsResponse.fromJson(responseData);
      } else if (response.statusCode == 401) {
        throw AdmissionException('Unauthorized', 401);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AdmissionException(
            errorData['message']?.toString() ?? 'Failed to get applications',
            response.statusCode);
      }
    } catch (e) {
      print('🎓 [ADMISSION] Error getting applications: $e');
      if (e is AdmissionException) {
        rethrow;
      } else {
        throw AdmissionException('Network error: ${e.toString()}');
      }
    }
  }

  /// Get single application by ID
  static Future<Application> getApplicationById(String applicationId) async {
    try {
      print('🎓 [ADMISSION] Getting application: $applicationId');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw AdmissionException('No authentication token found');
      }

      final url =
          '${_baseUrl}${ApiConstants.getApplicationByIdEndpoint}/$applicationId';
      final headers = ApiConstants.getAuthHeaders(token);

      print('🎓 [ADMISSION] URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('🎓 [ADMISSION] Response status: ${response.statusCode}');
      print('🎓 [ADMISSION] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return Application.fromJson(responseData);
      } else if (response.statusCode == 401) {
        throw AdmissionException('Unauthorized', 401);
      } else if (response.statusCode == 404) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AdmissionException(
            errorData['message']?.toString() ?? 'Application not found', 404);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AdmissionException(
            errorData['message']?.toString() ?? 'Failed to get application',
            response.statusCode);
      }
    } catch (e) {
      print('🎓 [ADMISSION] Error getting application: $e');
      if (e is AdmissionException) {
        rethrow;
      } else {
        throw AdmissionException('Network error: ${e.toString()}');
      }
    }
  }
}

