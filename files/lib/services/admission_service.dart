import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/admission_models.dart';
import '../models/school_models.dart';
import '../models/student_models.dart';
import 'user_storage_service.dart';
import 'auth_error_handler.dart';

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

  /// Set interview date for an application (school admin only)
  static Future<Application> setInterviewDate({
    required String applicationId,
    required String date,
    required String time,
    String? location,
    String? notes,
  }) async {
    try {
      print('🎓 [ADMISSION] Setting interview date for: $applicationId');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw AdmissionException('No authentication token found');
      }

      final url =
          '${_baseUrl}/api/me/applications/school/my/$applicationId';
      final headers = ApiConstants.getAuthHeaders(token);

      final body = {
        'date': date,
        'time': time,
        if (location != null) 'location': location,
        if (notes != null) 'notes': notes,
      };

      print('🎓 [ADMISSION] URL: $url');
      print('🎓 [ADMISSION] Body: ${jsonEncode(body)}');

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      print('🎓 [ADMISSION] Response status: ${response.statusCode}');
      print('🎓 [ADMISSION] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return Application.fromJson(
            responseData['application'] as Map<String, dynamic>);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AdmissionException(
            errorData['message']?.toString() ?? 'Bad request', 400);
      } else if (response.statusCode == 403) {
        throw AdmissionException('Access denied', 403);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AdmissionException(
            errorData['message']?.toString() ?? 'Failed to set interview date',
            response.statusCode);
      }
    } catch (e) {
      print('🎓 [ADMISSION] Error setting interview date: $e');
      if (e is AdmissionException) {
        rethrow;
      } else {
        throw AdmissionException('Network error: ${e.toString()}');
      }
    }
  }

  /// Add an event/note to an application (school admin only)
  static Future<ApplicationEvent> addApplicationEvent({
    required String applicationId,
    required String type,
    required String title,
    String? description,
    DateTime? date,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('🎓 [ADMISSION] Adding event to application: $applicationId');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw AdmissionException('No authentication token found');
      }

      final url =
          '${_baseUrl}/api/me/applications/school/my/$applicationId/events';
      final headers = ApiConstants.getAuthHeaders(token);

      final body = {
        'type': type,
        'title': title,
        if (description != null) 'description': description,
        if (date != null) 'date': date.toIso8601String(),
        if (metadata != null) 'metadata': metadata,
      };

      print('🎓 [ADMISSION] URL: $url');
      print('🎓 [ADMISSION] Body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      print('🎓 [ADMISSION] Response status: ${response.statusCode}');
      print('🎓 [ADMISSION] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return ApplicationEvent.fromJson(
            responseData['event'] as Map<String, dynamic>);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AdmissionException(
            errorData['message']?.toString() ?? 'Bad request', 400);
      } else if (response.statusCode == 403) {
        throw AdmissionException('Access denied', 403);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AdmissionException(
            errorData['message']?.toString() ?? 'Failed to add event',
            response.statusCode);
      }
    } catch (e) {
      print('🎓 [ADMISSION] Error adding event: $e');
      if (e is AdmissionException) {
        rethrow;
      } else {
        throw AdmissionException('Network error: ${e.toString()}');
      }
    }
  }

  /// Get all events for an application
  static Future<List<ApplicationEvent>> getApplicationEvents(
      String applicationId) async {
    try {
      print('🎓 [ADMISSION] Getting events for application: $applicationId');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw AdmissionException('No authentication token found');
      }

      final url =
          '${_baseUrl}/api/me/applications/school/my/$applicationId/events';
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
        final events = (responseData['events'] as List<dynamic>?)
                ?.map((event) =>
                    ApplicationEvent.fromJson(event as Map<String, dynamic>))
                .toList() ??
            [];
        return events;
      } else if (response.statusCode == 403) {
        throw AdmissionException('Access denied', 403);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AdmissionException(
            errorData['message']?.toString() ?? 'Failed to get events',
            response.statusCode);
      }
    } catch (e) {
      print('🎓 [ADMISSION] Error getting events: $e');
      if (e is AdmissionException) {
        rethrow;
      } else {
        throw AdmissionException('Network error: ${e.toString()}');
      }
    }
  }
}

