import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../core/constants/api_constants.dart';
import '../models/admission_models.dart';
import '../models/lookup_models.dart';
import '../models/education_system_models.dart';
import '../models/school_models.dart';
import 'user_storage_service.dart';

class AdmissionService {
  static const String _baseUrl = ApiConstants.parentBaseUrl;

  /// Helper to handle 403 errors and HTML redirects globally
  // static Future<bool> _handleResponse(http.Response response) async {
  //   final body = response.body.trim();
    
  //   if (response.statusCode == 403 || response.statusCode == 401) {
  //     print('🔒 [ADMISSION] Unauthorized ( ${response.statusCode} ) - Triggering Logout');
  //     await AuthErrorHandler.handle403Error();
  //     return true;
  //   }

  //   if (body.startsWith('<!DOCTYPE html>') || body.startsWith('<html')) {
  //      print('⚠️ [ADMISSION] Received HTML response - Likely session expired or wrong route.');
  //      await AuthErrorHandler.handle403Error();
  //      return true;
  //   }

  //   return false;
  // }

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
      ).timeout(const Duration(seconds: 30));

      print('🎓 [ADMISSION] Response status: ${response.statusCode}');
      
      // if (await _handleResponse(response)) throw AdmissionException('Session Expired');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return ApplyToSchoolsResponse.fromJson(responseData);
      } else if (response.statusCode == 400) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final message = responseData['message']?.toString() ?? 'bad_request'.tr;
        
        // Handle specific 400 cases from backend (Age, Period, Active Apps, Balance)
        if (responseData['details'] != null) {
           final details = responseData['details'];
           if (details['requiredAmount'] != null && details['currentBalance'] != null) {
              final required = details['requiredAmount'];
              final available = details['currentBalance'];
              throw AdmissionException('$message\n${'required'.tr}: $required, ${'available'.tr}: $available', 400);
           }
        }
        
        throw AdmissionException(message, 400);
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

  /// Reorder applications priority
  static Future<void> reorderApplications(
      ReorderApplicationsRequest request) async {
    try {
      print('🎓 [ADMISSION] Reordering applications');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw AdmissionException('No authentication token found');
      }

      final url = _baseUrl + ApiConstants.reorderApplicationsEndpoint;
      final headers = ApiConstants.getAuthHeaders(token);

      print('🎓 [ADMISSION] URL: $url');
      print('🎓 [ADMISSION] Body: ${jsonEncode(request.toJson())}');

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 30));

      print('🎓 [ADMISSION] Response status: ${response.statusCode}');

      // if (await _handleResponse(response)) throw AdmissionException('Session Expired');

      if (response.statusCode == 200) {
        return;
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AdmissionException(
            errorData['message']?.toString() ?? 'Failed to reorder applications',
            response.statusCode);
      }
    } catch (e) {
      print('🎓 [ADMISSION] Error reordering applications: $e');
      if (e is AdmissionException) {
        rethrow;
      } else {
        throw AdmissionException('Network error: ${e.toString()}');
      }
    }
  }

  /// Submit an admission application for a child to a school
  static Future<AdmissionApplyResponse> applyAdmission(
      AdmissionApplyRequest request) async {
    try {
      print('🎓 [ADMISSION] Submitting application for child: ${request.childId} to school: ${request.schoolId}');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw AdmissionException('No authentication token found');
      }

      final url = '$_baseUrl/admission/apply';
      final headers = ApiConstants.getAuthHeaders(token);

      print('🎓 [ADMISSION] URL: $url');
      print('🎓 [ADMISSION] Body: ${jsonEncode(request.toJson())}');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 30));

      print('🎓 [ADMISSION] Response status: ${response.statusCode}');

      // if (await _handleResponse(response)) throw AdmissionException('Session Expired');

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AdmissionApplyResponse.fromJson(responseData);
      } else if (response.statusCode == 400) {
        final errorType = responseData['error']?.toString();
        final message = responseData['message']?.toString() ?? 'Bad request';
        
        if (errorType == 'INSUFFICIENT_BALANCE') {
          final required = responseData['required'];
          final available = responseData['available'];
          throw AdmissionException('insufficient_wallet_balance'.tr +
              '\n' + 'required.tr' + ': $required, ' + 'available.tr' + ': $available', 400);
        }
        
        throw AdmissionException(message, 400);
      } else {
        throw AdmissionException(
            responseData['message']?.toString() ?? 'Failed to apply',
            response.statusCode);
      }
    } catch (e) {
      print('🎓 [ADMISSION] Error applying: $e');
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
      ).timeout(const Duration(seconds: 30));

      print('🎓 [ADMISSION] Response status: ${response.statusCode}');

      // if (await _handleResponse(response)) throw AdmissionException('Session Expired');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return Application.fromJson(responseData);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AdmissionException(
            errorData['message']?.toString() ?? 'Bad request', 400);
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

      final url = _baseUrl + ApiConstants.getAdmissionApplicationsEndpoint;
      final headers = ApiConstants.getAuthHeaders(token);

      print('🎓 [ADMISSION] URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      print('🎓 [ADMISSION] Response status: ${response.statusCode}');

      // if (await _handleResponse(response)) throw AdmissionException('Session Expired');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return ApplicationsResponse.fromJson(responseData);
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
          '${_baseUrl}${ApiConstants.getSingleApplicationEndpoint}/$applicationId';
      final headers = ApiConstants.getAuthHeaders(token);

      print('🎓 [ADMISSION] URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      print('🎓 [ADMISSION] Response status: ${response.statusCode}');

      // if (await _handleResponse(response)) throw AdmissionException('Session Expired');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return Application.fromJson(responseData);
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
          '${_baseUrl}${ApiConstants.getSingleApplicationEndpoint}/$applicationId';
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
      ).timeout(const Duration(seconds: 30));

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
          '${_baseUrl}/me/applications/school/my/$applicationId/events';
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
      ).timeout(const Duration(seconds: 30));

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
          '${_baseUrl}/me/applications/school/my/$applicationId/events';
      final headers = ApiConstants.getAuthHeaders(token);

      print('🎓 [ADMISSION] URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

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
  /// Get all admission applications for a specific school (school admin only)
  static Future<ApplicationsResponse> getSchoolApplications(String schoolId, {String? status}) async {
    try {
      print('🎓 [ADMISSION] Getting school applications for school: $schoolId');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw AdmissionException('No authentication token found');
      }

      String url = _baseUrl + ApiConstants.getSchoolApplicationsEndpoint.replaceAll('[id]', schoolId);
      if (status != null && status.isNotEmpty) {
        url += '?status=$status';
      }
      
      final headers = ApiConstants.getAuthHeaders(token);

      print('🎓 [ADMISSION] URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      print('🎓 [ADMISSION] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return ApplicationsResponse.fromJson(responseData);
      } else if (response.statusCode == 403) {
        throw AdmissionException('Access denied: You do not have permission', 403);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AdmissionException(
            errorData['message']?.toString() ?? 'Failed to get applications',
            response.statusCode);
      }
    } catch (e) {
      print('🎓 [ADMISSION] Error getting school applications: $e');
      if (e is AdmissionException) {
        rethrow;
      } else {
        throw AdmissionException('Network error: ${e.toString()}');
      }
    }
  }

  /// Update application status (school admin only)
  static Future<Application> updateApplicationStatus(String applicationId, String status, {String? note}) async {
    try {
      print('🎓 [ADMISSION] Updating status for application: $applicationId to: $status');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw AdmissionException('No authentication token found');
      }

      final url = _baseUrl + ApiConstants.updateApplicationStatusEndpoint.replaceAll('[id]', applicationId);
      final headers = ApiConstants.getAuthHeaders(token);

      final body = {
        'status': status,
        if (note != null) 'note': note,
      };

      print('🎓 [ADMISSION] URL: $url');
      print('🎓 [ADMISSION] Body: ${jsonEncode(body)}');

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      print('🎓 [ADMISSION] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return Application.fromJson(responseData['application'] as Map<String, dynamic>);
      } else if (response.statusCode == 400) {
        throw AdmissionException('Invalid status', 400);
      } else if (response.statusCode == 403) {
        throw AdmissionException('Access denied', 403);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AdmissionException(
            errorData['message']?.toString() ?? 'Failed to update status',
            response.statusCode);
      }
    } catch (e) {
      print('🎓 [ADMISSION] Error updating status: $e');
      if (e is AdmissionException) {
        rethrow;
      } else {
        throw AdmissionException('Network error: ${e.toString()}');
      }
    }
  }
  /// Get general lookups for admission form
  static Future<LookupsResponse> getLookups() async {
    try {
      print('🎓 [ADMISSION] Getting lookups');
      
      final url = _baseUrl + ApiConstants.getLookupsEndpoint;
      // Lookups are public, but we can send token if available (optional)
      final token = UserStorageService.getAuthToken();
      final headers = ApiConstants.getHeaders(token: token);

      print('🎓 [ADMISSION] URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      print('🎓 [ADMISSION] Response status: ${response.statusCode}');
      // buffer log to avoid truncation for large responses
      // print('🎓 [ADMISSION] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return LookupsResponse.fromJson(responseData);
      } else {
        throw AdmissionException(
            'Failed to load lookups',
            response.statusCode);
      }
    } catch (e) {
      print('🎓 [ADMISSION] Error getting lookups: $e');
      if (e is AdmissionException) {
        rethrow;
      } else {
        throw AdmissionException('Network error: ${e.toString()}');
      }
    }
  }

  /// Get education systems hierarchy
  static Future<EducationSystemsResponse> getEducationSystems() async {
    try {
      print('🎓 [ADMISSION] Getting education systems');
      
      final url = _baseUrl + ApiConstants.getEducationSystemsEndpoint;
      final token = UserStorageService.getAuthToken();
      final headers = ApiConstants.getHeaders(token: token);

      print('🎓 [ADMISSION] URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      print('🎓 [ADMISSION] Response status: ${response.statusCode}');
      // print('🎓 [ADMISSION] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return EducationSystemsResponse.fromJson(responseData);
      } else {
        throw AdmissionException(
            'Failed to load education systems',
            response.statusCode);
      }
    } catch (e) {
      print('🎓 [ADMISSION] Error getting education systems: $e');
      if (e is AdmissionException) {
        rethrow;
      } else {
        throw AdmissionException('Network error: ${e.toString()}');
      }
    }
  }

  /// Get filtered schools (POST)
  static Future<List<School>> viewSchools(ViewSchoolsRequest request) async {
    try {
      print('🎓 [ADMISSION] Viewing schools with filters (POST)');
      
      final url = _baseUrl + ApiConstants.viewSchoolsEndpoint;
      final token = UserStorageService.getAuthToken();
      final headers = ApiConstants.getHeaders(token: token);

      print('🎓 [ADMISSION] URL: $url');
      print('🎓 [ADMISSION] Body: ${jsonEncode(request.toJson())}');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(request.toJson()), // Use toJson method
      ).timeout(const Duration(seconds: 30));

      print('🎓 [ADMISSION] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List<dynamic> list;
        if (responseData is List) {
           list = responseData;
        } else if (responseData is Map && responseData['schools'] is List) {
           list = responseData['schools'];
        } else {
           list = [];
        }
        
        return list.map((e) => School.fromJson(e)).toList();
      } else {
         final errorData = jsonDecode(response.body) as Map<String, dynamic>;
         throw AdmissionException(
            errorData['message']?.toString() ?? 'Failed to load schools',
            response.statusCode);
      }
    } catch (e) {
      print('🎓 [ADMISSION] Error viewing schools: $e');
      if (e is AdmissionException) {
        rethrow;
      } else {
        throw AdmissionException('Network error: ${e.toString()}');
      }
    }
  }

  /// Get schools with filters
  static Future<List<School>> getSchools({
    String? governorateId,
    String? administrationId,
    String? educationSystemId,
    String? stageId,
    String? gradeId,
    String? gender,
    double? maxFee,
  }) async {
    try {
      print('🎓 [ADMISSION] Getting schools with filters');

      String url = _baseUrl + ApiConstants.getAllSchoolsEndpoint;
      Map<String, String> queryParams = {};
      if (governorateId != null) queryParams['governorate'] = governorateId;
      if (administrationId != null) queryParams['administration'] = administrationId;
      if (educationSystemId != null) queryParams['educationSystem'] = educationSystemId;
      if (stageId != null) queryParams['stage'] = stageId;
      if (gradeId != null) queryParams['grade'] = gradeId;
      if (gender != null) queryParams['gender'] = gender;
      if (maxFee != null) queryParams['maxFee'] = maxFee.toString();

      if (queryParams.isNotEmpty) {
        url += '?' + Uri(queryParameters: queryParams).query;
      }

      print('🎓 [ADMISSION] URL: $url');
      
      // Lookups are public, but we can send token if available (optional)
      final token = UserStorageService.getAuthToken(); 
      final headers = ApiConstants.getHeaders(token: token);

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      print('🎓 [ADMISSION] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Ensure responseData is a list or contains a list
        List<dynamic> list;
        if (responseData is List) {
           list = responseData;
        } else if (responseData is Map && responseData['schools'] is List) {
           list = responseData['schools'];
        } else {
           list = [];
        }
        
        return list.map((e) => School.fromJson(e)).toList();
      } else {
        throw AdmissionException(
            'Failed to load schools',
            response.statusCode);
      }
    } catch (e) {
      print('🎓 [ADMISSION] Error getting schools: $e');
      if (e is AdmissionException) {
        rethrow;
      } else {
        throw AdmissionException('Network error: ${e.toString()}');
      }
    }
  }

  static Future<SchoolSuggestionResponse> suggestThreeSchools(
      SchoolSuggestionRequest request) async {
    try {
      print('🎓 [ADMISSION] Getting AI school suggestions');
      
      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw AdmissionException('No authentication token found');
      }

      final url = _baseUrl + ApiConstants.suggestThreeEndpoint;
      final headers = ApiConstants.getAuthHeaders(token);

      print('🎓 [ADMISSION] URL: $url');
      print('🎓 [ADMISSION] Body: ${jsonEncode(request.toJson())}');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 60)); // Long timeout for AI

      print('🎓 [ADMISSION] Response status: ${response.statusCode}');
      print('🎓 [ADMISSION] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return SchoolSuggestionResponse.fromJson(responseData);
      } else if (response.statusCode == 429) {
         throw AdmissionException('AI service is busy, please try again later', 429);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AdmissionException(
            errorData['message']?.toString() ?? 'Failed to get suggestions',
            response.statusCode);
      }
    } catch (e) {
      print('🎓 [ADMISSION] Error getting suggestions: $e');
      if (e is AdmissionException) {
        rethrow;
      } else {
        throw AdmissionException('Network error: ${e.toString()}');
      }
    }
  }

  static Future<AIAssessmentResponse> performAIAssessment(
      AIAssessmentRequest request) async {
    try {
      print('🎓 [ADMISSION] Performing AI assessment');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw AdmissionException('No authentication token found');
      }

      final url = _baseUrl + ApiConstants.aiAssessmentEndpoint;
      final headers = ApiConstants.getAuthHeaders(token);

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 60));

      print('🎓 [ADMISSION] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return AIAssessmentResponse.fromJson(responseData);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw AdmissionException(
            errorData['message']?.toString() ?? 'AI assessment failed',
            response.statusCode);
      }
    } catch (e) {
      print('🎓 [ADMISSION] Error performing AI assessment: $e');
      if (e is AdmissionException) {
        rethrow;
      } else {
        throw AdmissionException('Network error: ${e.toString()}');
      }
    }
  }
}
