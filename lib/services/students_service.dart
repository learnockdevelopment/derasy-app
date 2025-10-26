import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/student_models.dart';
import '../models/pagination_models.dart';
import 'user_storage_service.dart';

class StudentsService {
  static const String _baseUrl = ApiConstants.baseUrl;

  /// Get students in a school with advanced navigation (pagination and search)
  static Future<PaginatedStudentsResponse> getStudents(String schoolId,
      {StudentsRequest? request}) async {
    try {
      print('🎓 [STUDENTS] Getting students for school: $schoolId');
      if (request != null) {
        print(
            '🎓 [STUDENTS] Request params: page=${request.page}, limit=${request.limit}, search=${request.search}');
      }

      // Get stored token
      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw StudentsException('No authentication token found');
      }

      final baseUrl = _baseUrl +
          ApiConstants.getAllStudentsEndpoint.replaceFirst('[id]', schoolId);
      final queryParams = request?.toQueryParams() ?? {};

      // Build URL with query parameters
      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      final headers = ApiConstants.getAuthHeaders(token);

      print('🎓 [STUDENTS] URL: $uri');
      print('🎓 [STUDENTS] Headers: $headers');

      final response = await http.get(
        uri,
        headers: headers,
      );

      print('🎓 [STUDENTS] Response status: ${response.statusCode}');
      print('🎓 [STUDENTS] Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          return PaginatedStudentsResponse.fromJson(responseData);
        } catch (e) {
          print(
              '🎓 [STUDENTS] Response is not JSON format, treating as success');
          print('🎓 [STUDENTS] Response body: ${response.body}');
          // If response is not JSON, create a simple success response
          return PaginatedStudentsResponse(
            students: [],
            pagination: PaginationInfo(
              currentPage: 1,
              totalPages: 1,
              totalStudents: 0,
              hasNextPage: false,
              hasPrevPage: false,
              limit: 0,
            ),
          );
        }
      } else if (response.statusCode == 403) {
        try {
          final errorData = jsonDecode(response.body);
          throw StudentsException('Unauthorized: ${errorData['message']}');
        } catch (e) {
          throw StudentsException('Unauthorized: ${response.body}');
        }
      } else if (response.statusCode == 500) {
        try {
          final errorData = jsonDecode(response.body);
          throw StudentsException('Server error: ${errorData['message']}');
        } catch (e) {
          throw StudentsException('Server error: ${response.body}');
        }
      } else {
        throw StudentsException(
            'Failed to get students. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('🎓 [STUDENTS] Error getting students: $e');
      if (e is StudentsException) {
        rethrow;
      } else {
        throw StudentsException('Network error: ${e.toString()}');
      }
    }
  }

  /// Get all students in a school (non-paginated mode)
  static Future<PaginatedStudentsResponse> getAllStudents(
      String schoolId) async {
    return getStudents(schoolId);
  }

  /// Get students with pagination
  static Future<PaginatedStudentsResponse> getStudentsPaginated(
      String schoolId, int page, int limit,
      {String? search}) async {
    return getStudents(schoolId,
        request: StudentsRequest(
          page: page,
          limit: limit,
          search: search,
        ));
  }

  /// Search students
  static Future<PaginatedStudentsResponse> searchStudents(
      String schoolId, String searchQuery) async {
    return getStudents(schoolId,
        request: StudentsRequest(
          search: searchQuery,
        ));
  }

  /// Add a new student to a school
  static Future<StudentResponse> addStudent(
      String schoolId, AddStudentRequest request) async {
    try {
      print('🎓 [STUDENTS] Adding student to school: $schoolId');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw StudentsException('No authentication token found');
      }

      final url = _baseUrl +
          ApiConstants.addStudentEndpoint.replaceFirst('[id]', schoolId);
      final headers = ApiConstants.getAuthHeaders(token);

      print('🎓 [STUDENTS] URL: $url');
      print('🎓 [STUDENTS] Headers: $headers');
      print('🎓 [STUDENTS] Request body: ${jsonEncode(request.toJson())}');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      print('🎓 [STUDENTS] Response status: ${response.statusCode}');
      print('🎓 [STUDENTS] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = jsonDecode(response.body);
          return StudentResponse.fromJson(responseData);
        } catch (e) {
          print(
              '🎓 [STUDENTS] Response is not JSON format, treating as success');
          print('🎓 [STUDENTS] Response body: ${response.body}');
          // If response is not JSON, create a simple success response
          return StudentResponse(
            success: true,
            message: 'Student added successfully',
            student: null,
          );
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          throw StudentsException(
              errorData['message'] ?? 'Failed to add student');
        } catch (e) {
          throw StudentsException('Failed to add student: ${response.body}');
        }
      }
    } catch (e) {
      print('🎓 [STUDENTS] Error adding student: $e');
      throw StudentsException('Failed to add student: ${e.toString()}');
    }
  }

  /// Update an existing student
  static Future<StudentResponse> updateStudent(
      String schoolId, String studentId, UpdateStudentRequest request) async {
    try {
      print('🎓 [STUDENTS] Updating student: $studentId in school: $schoolId');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw StudentsException('No authentication token found');
      }

      final url = _baseUrl +
          ApiConstants.updateStudentEndpoint
              .replaceFirst('[id]', schoolId)
              .replaceFirst('[studentId]', studentId);
      final headers = ApiConstants.getAuthHeaders(token);

      print('🎓 [STUDENTS] URL: $url');
      print('🎓 [STUDENTS] Headers: $headers');
      print('🎓 [STUDENTS] Request body: ${jsonEncode(request.toJson())}');

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      print('🎓 [STUDENTS] Response status: ${response.statusCode}');
      print('🎓 [STUDENTS] Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          print('🎓 [STUDENTS] Successfully parsed JSON response');
          return StudentResponse.fromJson(responseData);
        } catch (e) {
          print('🎓 [STUDENTS] Error parsing JSON: $e');
          print('🎓 [STUDENTS] Response is not JSON format, treating as success');
          print('🎓 [STUDENTS] Response body: ${response.body}');
          // If response is not JSON, create a simple success response
          return StudentResponse(
            success: true,
            message: 'Student updated successfully',
            student: null,
          );
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          throw StudentsException(
              errorData['message'] ?? 'Failed to update student');
        } catch (e) {
          throw StudentsException('Failed to update student: ${response.body}');
        }
      }
    } catch (e) {
      print('🎓 [STUDENTS] Error updating student: $e');
      throw StudentsException('Failed to update student: ${e.toString()}');
    }
  }

  /// Delete a student from a school
  static Future<StudentResponse> deleteStudent(
      String schoolId, String studentId) async {
    try {
      print(
          '🎓 [STUDENTS] Deleting student: $studentId from school: $schoolId');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw StudentsException('No authentication token found');
      }

      final url = _baseUrl +
          ApiConstants.deleteStudentEndpoint
              .replaceFirst('[id]', schoolId)
              .replaceFirst('[studentId]', studentId);
      final headers = ApiConstants.getAuthHeaders(token);

      print('🎓 [STUDENTS] URL: $url');
      print('🎓 [STUDENTS] Headers: $headers');

      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      );

      print('🎓 [STUDENTS] Response status: ${response.statusCode}');
      print('🎓 [STUDENTS] Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          return StudentResponse.fromJson(responseData);
        } catch (e) {
          print(
              '🎓 [STUDENTS] Response is not JSON format, treating as success');
          print('🎓 [STUDENTS] Response body: ${response.body}');
          // If response is not JSON, create a simple success response
          return StudentResponse(
            success: true,
            message: 'Student deleted successfully',
            student: null,
          );
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          throw StudentsException(
              errorData['message'] ?? 'Failed to delete student');
        } catch (e) {
          throw StudentsException('Failed to delete student: ${response.body}');
        }
      }
    } catch (e) {
      print('🎓 [STUDENTS] Error deleting student: $e');
      throw StudentsException('Failed to delete student: ${e.toString()}');
    }
  }
}
