import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../core/constants/api_constants.dart';
import '../models/student_models.dart';
import '../models/pagination_models.dart';
import 'user_storage_service.dart';
import 'auth_error_handler.dart';

class StudentsService {
  static const String _baseUrl = ApiConstants.baseUrl;

  /// Get students in a school with advanced navigation (pagination and search)
  static Future<PaginatedStudentsResponse> getStudents(String schoolId,
      {StudentsRequest? request}) async {
    try {
      print('🎓 [STUDENTS] Getting students for school: $schoolId');
      if (request != null) {
        print(
            '🎓 [STUDENTS] Request params: page=${request.page}, limit=${request.limit}, search=${request.search}, grade=${request.grade}, age=${request.age}, class=${request.classId}');
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
      ).timeout(const Duration(seconds: 30));

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
      {String? search, String? grade, int? age, String? classId}) async {
    return getStudents(schoolId,
        request: StudentsRequest(
          page: page,
          limit: limit,
          search: search,
          grade: grade,
          age: age,
          classId: classId,
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

  /// Get related children for the current user (parent)
  static Future<StudentsResponse> getRelatedChildren() async {
    try {
      print('👶 [CHILDREN] Getting related children');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw StudentsException('No authentication token found');
      }

      final url = _baseUrl + ApiConstants.getRelatedChildrenEndpoint;
      final headers = ApiConstants.getAuthHeaders(token);

      print('👶 [CHILDREN] URL: $url');
      print('👶 [CHILDREN] Headers: $headers');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      print('👶 [CHILDREN] Response status: ${response.statusCode}');
      print('👶 [CHILDREN] Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          // API returns { children: [...] } format
          if (responseData.containsKey('children') && responseData['children'] is List) {
            return StudentsResponse( 
              success: true,
              message: 'Children retrieved successfully',
              students: (responseData['children'] as List)
                      .map((child) => Student.fromJson(child as Map<String, dynamic>))
                      .toList(),
            );
          } else {
            // Fallback for other response formats
            return StudentsResponse(
              success: true,
              message: 'Children retrieved successfully',
              students: [],
            );
          }
        } catch (e) {
          print('👶 [CHILDREN] Error parsing JSON: $e');
          throw StudentsException('Failed to parse response: $e');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Handle unauthorized - logout and navigate to login
        await AuthErrorHandler.handleIfUnauthorized(response.statusCode);
        
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          throw StudentsException('Unauthorized: ${errorData['message']}');
        } catch (e) {
          throw StudentsException('Unauthorized: ${response.body}');
        }
      } else {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          throw StudentsException(errorData['message']?.toString() ?? 'Failed to get children');
        } catch (e) {
          throw StudentsException('Failed to get children: ${response.body}');
        }
      }
    } catch (e) {
      print('👶 [CHILDREN] Error getting children: $e');
      if (e is StudentsException) {
        rethrow;
      } else {
        throw StudentsException('Network error: ${e.toString()}');
      }
    }
  }

  /// Add child(ren) for the current user (parent)
  static Future<AddChildrenResponse> addChildren(AddChildRequest request) async {
    try {
      print('👶 [ADD_CHILD] Adding child(ren)');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw StudentsException('No authentication token found');
      }

      final url = _baseUrl + ApiConstants.addChildrenEndpoint;
      final headers = ApiConstants.getAuthHeaders(token);
      final requestBody = request.toJson();

      print('👶 [ADD_CHILD] URL: $url');
      print('👶 [ADD_CHILD] Headers: $headers');
      print('👶 [ADD_CHILD] Body: ${jsonEncode(requestBody)}');
      _logApiRequest('addChildren', {
        'endpoint': url,
        'body': requestBody,
      });

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('👶 [ADD_CHILD] Response status: ${response.statusCode}');
      print('👶 [ADD_CHILD] Response body: ${response.body}');

      if (response.statusCode == 201) {
        try {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          return AddChildrenResponse.fromJson(responseData);
        } catch (e) {
          print('👶 [ADD_CHILD] Error parsing JSON: $e');
          throw StudentsException('Failed to parse response: $e');
        }
      } else if (response.statusCode == 400) {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          throw StudentsException(errorData['message']?.toString() ?? 'Missing required fields');
        } catch (e) {
          throw StudentsException('Bad request: ${response.body}');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          throw StudentsException('Unauthorized: ${errorData['message']}');
        } catch (e) {
          throw StudentsException('Unauthorized: ${response.body}');
        }
      } else {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          throw StudentsException(errorData['message']?.toString() ?? 'Failed to add child(ren)');
        } catch (e) {
          throw StudentsException('Failed to add child(ren): ${response.body}');
        }
      }
    } catch (e) {
      print('👶 [ADD_CHILD] Error adding child(ren): $e');
      if (e is StudentsException) {
        rethrow;
      } else {
        throw StudentsException('Network error: ${e.toString()}');
      }
    }
  }

  /// Add multiple children at once
  static Future<AddChildrenResponse> addMultipleChildren(List<AddChildRequest> requests) async {
    try {
      print('👶 [ADD_CHILDREN] Adding ${requests.length} child(ren)');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw StudentsException('No authentication token found');
      }

      final url = _baseUrl + ApiConstants.addChildrenEndpoint;
      final headers = ApiConstants.getAuthHeaders(token);

      // Convert list of requests to list of JSON maps
      final requestsJson = requests.map((req) => req.toJson()).toList();

      print('👶 [ADD_CHILDREN] URL: $url');
      print('👶 [ADD_CHILDREN] Headers: $headers');
      print('👶 [ADD_CHILDREN] Body: ${jsonEncode(requestsJson)}');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestsJson),
      );

      print('👶 [ADD_CHILDREN] Response status: ${response.statusCode}');
      print('👶 [ADD_CHILDREN] Response body: ${response.body}');

      if (response.statusCode == 201) {
        try {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          return AddChildrenResponse.fromJson(responseData);
        } catch (e) {
          print('👶 [ADD_CHILDREN] Error parsing JSON: $e');
          throw StudentsException('Failed to parse response: $e');
        }
      } else if (response.statusCode == 400) {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          throw StudentsException(errorData['message']?.toString() ?? 'Missing required fields');
        } catch (e) {
          throw StudentsException('Bad request: ${response.body}');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          throw StudentsException('Unauthorized: ${errorData['message']}');
        } catch (e) {
          throw StudentsException('Unauthorized: ${response.body}');
        }
      } else {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          throw StudentsException(errorData['message']?.toString() ?? 'Failed to add child(ren)');
        } catch (e) {
          throw StudentsException('Failed to add child(ren): ${response.body}');
        }
      }
    } catch (e) {
      print('👶 [ADD_CHILDREN] Error adding child(ren): $e');
      if (e is StudentsException) {
        rethrow;
      } else {
        throw StudentsException('Network error: ${e.toString()}');
      }
    }
  }

  /// Extract data from birth certificate using AI
  static Future<BirthCertificateExtractionResponse> extractBirthCertificate(File imageFile) async {
    try {
      print('📄 [EXTRACT] Extracting data from birth certificate');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw StudentsException('No authentication token found');
      }

      final url = _baseUrl + ApiConstants.extractBirthCertificateEndpoint;
      
      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(url));
      
      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        ApiConstants.apiKeyHeader: ApiConstants.apiKey,
      });

      // Add file
      final fileBytes = await imageFile.readAsBytes();
      final fileName = imageFile.path.split('/').last;
      final mimeType = fileName.toLowerCase().endsWith('.png') 
          ? 'image/png' 
          : fileName.toLowerCase().endsWith('.webp')
              ? 'image/webp'
              : 'image/jpeg';
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'birthCertificate',
          fileBytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );

      print('📄 [EXTRACT] URL: $url');
      print('📄 [EXTRACT] File: $fileName (${fileBytes.length} bytes)');
      _logApiRequest('extractBirthCertificate', {
        'endpoint': url,
        'fileName': fileName,
        'fileSize': fileBytes.length,
        'mimeType': mimeType,
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📄 [EXTRACT] Response status: ${response.statusCode}');
      print('📄 [EXTRACT] Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          return BirthCertificateExtractionResponse.fromJson(responseData);
        } catch (e) {
          print('📄 [EXTRACT] Error parsing JSON: $e');
          throw StudentsException('Failed to parse extraction response: $e');
        }
      } else if (response.statusCode == 409) {
        // Child with this national ID already exists
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          throw StudentsException(
            'Child with this national ID already exists. ${errorData['existingChildId'] != null ? 'Child ID: ${errorData['existingChildId']}' : ''}',
          );
        } catch (e) {
          throw StudentsException('Child with this national ID already exists');
        }
      } else if (response.statusCode == 503) {
        // Service unavailable - AI error
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          final canContinue = errorData['canContinue'] == true;
          throw BirthCertificateExtractionException(
            errorData['message']?.toString() ?? 'OCR extraction failed. Please enter data manually.',
            canContinue: canContinue,
          );
        } catch (e) {
          if (e is BirthCertificateExtractionException) {
            rethrow;
          }
          throw BirthCertificateExtractionException(
            'OCR extraction failed. Please enter data manually.',
            canContinue: true,
          );
        }
      } else {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          throw StudentsException(errorData['message']?.toString() ?? 'Failed to extract birth certificate data');
        } catch (e) {
          throw StudentsException('Failed to extract birth certificate data: ${response.body}');
        }
      }
    } catch (e) {
      print('📄 [EXTRACT] Error extracting birth certificate: $e');
      if (e is StudentsException || e is BirthCertificateExtractionException) {
        rethrow;
      } else {
        throw StudentsException('Network error: ${e.toString()}');
      }
    }
  }

  /// Extract data from National ID card (front and/or back) using AI
  static Future<NationalIdExtractionResponse> extractNationalId({
    File? nationalIdFront,
    File? nationalIdBack,
  }) async {
    try {
      print('🆔 [EXTRACT_ID] Extracting data from National ID');

      if (nationalIdFront == null && nationalIdBack == null) {
        throw StudentsException('At least one National ID image (front or back) is required');
      }

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw StudentsException('No authentication token found');
      }

      final url = _baseUrl + ApiConstants.extractNationalIdEndpoint;
      
      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(url));
      
      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        ApiConstants.apiKeyHeader: ApiConstants.apiKey,
      });

      final Map<String, dynamic> requestParams = {
        'endpoint': url,
      };

      // Add front image if provided
      if (nationalIdFront != null) {
        final frontBytes = await nationalIdFront.readAsBytes();
        final frontFileName = nationalIdFront.path.split('/').last;
        final frontMimeType = frontFileName.toLowerCase().endsWith('.png') 
            ? 'image/png' 
            : frontFileName.toLowerCase().endsWith('.webp')
                ? 'image/webp'
                : 'image/jpeg';
        
        request.files.add(
          http.MultipartFile.fromBytes(
            'nationalIdFront',
            frontBytes,
            filename: frontFileName,
            contentType: MediaType.parse(frontMimeType),
          ),
        );

        requestParams['frontFileName'] = frontFileName;
        requestParams['frontFileSize'] = frontBytes.length;
        requestParams['frontMimeType'] = frontMimeType;
        print('🆔 [EXTRACT_ID] Front: $frontFileName (${frontBytes.length} bytes)');
      }

      // Add back image if provided
      if (nationalIdBack != null) {
        final backBytes = await nationalIdBack.readAsBytes();
        final backFileName = nationalIdBack.path.split('/').last;
        final backMimeType = backFileName.toLowerCase().endsWith('.png') 
            ? 'image/png' 
            : backFileName.toLowerCase().endsWith('.webp')
                ? 'image/webp'
                : 'image/jpeg';
        
        request.files.add(
          http.MultipartFile.fromBytes(
            'nationalIdBack',
            backBytes,
            filename: backFileName,
            contentType: MediaType.parse(backMimeType),
          ),
        );

        requestParams['backFileName'] = backFileName;
        requestParams['backFileSize'] = backBytes.length;
        requestParams['backMimeType'] = backMimeType;
        print('🆔 [EXTRACT_ID] Back: $backFileName (${backBytes.length} bytes)');
      }

      print('🆔 [EXTRACT_ID] URL: $url');
      _logApiRequest('extractNationalId', requestParams);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('🆔 [EXTRACT_ID] Response status: ${response.statusCode}');
      print('🆔 [EXTRACT_ID] Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          return NationalIdExtractionResponse.fromJson(responseData);
        } catch (e) {
          print('🆔 [EXTRACT_ID] Error parsing JSON: $e');
          throw StudentsException('Failed to parse National ID extraction response: $e');
        }
      } else if (response.statusCode == 503) {
        // Service unavailable - AI error
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          final canContinue = errorData['canContinue'] == true;
          throw NationalIdExtractionException(
            errorData['message']?.toString() ?? 'OCR extraction failed. Please enter data manually.',
            canContinue: canContinue,
          );
        } catch (e) {
          if (e is NationalIdExtractionException) {
            rethrow;
          }
          throw NationalIdExtractionException(
            'OCR extraction failed. Please enter data manually.',
            canContinue: true,
          );
        }
      } else {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          throw StudentsException(errorData['message']?.toString() ?? 'Failed to extract National ID data');
        } catch (e) {
          throw StudentsException('Failed to extract National ID data: ${response.body}');
        }
      }
    } catch (e) {
      print('🆔 [EXTRACT_ID] Error extracting National ID: $e');
      if (e is StudentsException || e is NationalIdExtractionException) {
        rethrow;
      } else {
        throw StudentsException('Network error: ${e.toString()}');
      }
    }
  }

  /// Log API request parameters for debugging
  static void _logApiRequest(String endpoint, Map<String, dynamic> params) {
    print('🔍 [API REQUEST] Endpoint: $endpoint');
    print('🔍 [API REQUEST] Parameters: ${jsonEncode(params)}');
  }

  /// Submit non-Egyptian child request
  static Future<Map<String, dynamic>> submitNonEgyptianRequest({
    required File parentPassport,
    required File childPassport,
    String? fullName,
    String? arabicFullName,
    String? firstName,
    String? lastName,
    required String birthDate,
    required String gender,
    String? nationality,
    String? birthPlace,
    String? religion,
    String? desiredGrade,
    String? schoolId,
    String? currentSchool,
  }) async {
    try {
      print('🌍 [NON_EGYPTIAN] Submitting non-Egyptian child request');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw StudentsException('No authentication token found');
      }

      final url = '${_baseUrl}${ApiConstants.submitNonEgyptianRequestEndpoint}';
      final headers = {
        ...ApiConstants.getAuthHeaders(token),
        'Content-Type': 'multipart/form-data',
      };

      print('🌍 [NON_EGYPTIAN] URL: $url');

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll({
        'Authorization': headers['Authorization']!,
        'x-api-key': headers['x-api-key']!,
      });

      // Add files
      request.files.add(
        await http.MultipartFile.fromPath('parentPassport', parentPassport.path),
      );
      request.files.add(
        await http.MultipartFile.fromPath('childPassport', childPassport.path),
      );

      // Add form fields
      if (fullName != null && fullName.isNotEmpty) {
        request.fields['fullName'] = fullName;
      }
      if (arabicFullName != null && arabicFullName.isNotEmpty) {
        request.fields['arabicFullName'] = arabicFullName;
      }
      if (firstName != null && firstName.isNotEmpty) {
        request.fields['firstName'] = firstName;
      }
      if (lastName != null && lastName.isNotEmpty) {
        request.fields['lastName'] = lastName;
      }
      request.fields['birthDate'] = birthDate;
      request.fields['gender'] = gender;
      if (nationality != null && nationality.isNotEmpty) {
        request.fields['nationality'] = nationality;
      }
      if (birthPlace != null && birthPlace.isNotEmpty) {
        request.fields['birthPlace'] = birthPlace;
      }
      if (religion != null && religion.isNotEmpty) {
        request.fields['religion'] = religion;
      }
      if (desiredGrade != null && desiredGrade.isNotEmpty) {
        request.fields['desiredGrade'] = desiredGrade;
      }
      if (schoolId != null && schoolId.isNotEmpty) {
        request.fields['schoolId'] = schoolId;
      }
      if (currentSchool != null && currentSchool.isNotEmpty) {
        request.fields['currentSchool'] = currentSchool;
      }

      print('🌍 [NON_EGYPTIAN] Sending request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('🌍 [NON_EGYPTIAN] Response status: ${response.statusCode}');
      print('🌍 [NON_EGYPTIAN] Response body: ${response.body}');

      if (response.statusCode == 201) {
        try {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          return responseData;
        } catch (e) {
          print('🌍 [NON_EGYPTIAN] Error parsing JSON: $e');
          throw StudentsException('Failed to parse response: $e');
        }
      } else {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          throw StudentsException(errorData['message']?.toString() ?? 'Failed to submit non-Egyptian request');
        } catch (e) {
          throw StudentsException('Failed to submit non-Egyptian request: ${response.body}');
        }
      }
    } catch (e) {
      print('🌍 [NON_EGYPTIAN] Error submitting request: $e');
      if (e is StudentsException) {
        rethrow;
      } else {
        throw StudentsException('Network error: ${e.toString()}');
      }
    }
  }

  /// Update child information
  static Future<Map<String, dynamic>> updateChild(String childId, Map<String, dynamic> updateData) async {
    try {
      print('👶 [UPDATE_CHILD] Updating child: $childId');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw StudentsException('No authentication token found');
      }

      final url = '${_baseUrl}${ApiConstants.updateChildEndpoint}/$childId';
      final headers = ApiConstants.getAuthHeaders(token);

      print('👶 [UPDATE_CHILD] URL: $url');
      print('👶 [UPDATE_CHILD] Headers: $headers');
      print('👶 [UPDATE_CHILD] Body: ${jsonEncode(updateData)}');

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(updateData),
      );

      print('👶 [UPDATE_CHILD] Response status: ${response.statusCode}');
      print('👶 [UPDATE_CHILD] Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          return responseData;
        } catch (e) {
          print('👶 [UPDATE_CHILD] Error parsing JSON: $e');
          throw StudentsException('Failed to parse response: $e');
        }
      } else if (response.statusCode == 400) {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          throw StudentsException(errorData['message']?.toString() ?? 'Validation error');
        } catch (e) {
          throw StudentsException('Bad request: ${response.body}');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          throw StudentsException('Unauthorized: ${errorData['message']}');
        } catch (e) {
          throw StudentsException('Unauthorized: ${response.body}');
        }
      } else if (response.statusCode == 404) {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          throw StudentsException(errorData['message']?.toString() ?? 'Child not found or unauthorized');
        } catch (e) {
          throw StudentsException('Child not found: ${response.body}');
        }
      } else {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          throw StudentsException(errorData['message']?.toString() ?? 'Failed to update child');
        } catch (e) {
          throw StudentsException('Failed to update child: ${response.body}');
        }
      }
    } catch (e) {
      print('👶 [UPDATE_CHILD] Error updating child: $e');
      if (e is StudentsException) {
        rethrow;
      } else {
        throw StudentsException('Network error: ${e.toString()}');
      }
    }
  }

  /// Delete child
  static Future<void> deleteChild(String childId) async {
    try {
      print('👶 [DELETE_CHILD] Deleting child: $childId');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw StudentsException('No authentication token found');
      }

      final url = '${_baseUrl}${ApiConstants.deleteChildEndpoint}/$childId';
      final headers = ApiConstants.getAuthHeaders(token);

      print('👶 [DELETE_CHILD] URL: $url');
      print('👶 [DELETE_CHILD] Headers: $headers');

      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      );

      print('👶 [DELETE_CHILD] Response status: ${response.statusCode}');
      print('👶 [DELETE_CHILD] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          throw StudentsException('Unauthorized: ${errorData['message']}');
        } catch (e) {
          throw StudentsException('Unauthorized: ${response.body}');
        }
      } else if (response.statusCode == 404) {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          throw StudentsException(errorData['message']?.toString() ?? 'Child not found or unauthorized');
        } catch (e) {
          throw StudentsException('Child not found: ${response.body}');
        }
      } else {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          throw StudentsException(errorData['message']?.toString() ?? 'Failed to delete child');
        } catch (e) {
          throw StudentsException('Failed to delete child: ${response.body}');
        }
      }
    } catch (e) {
      print('👶 [DELETE_CHILD] Error deleting child: $e');
      if (e is StudentsException) {
        rethrow;
      } else {
        throw StudentsException('Network error: ${e.toString()}');
      }
    }
  }

  /// Send OTP to guardian for verification
  static Future<Map<String, dynamic>> sendOtpToGuardian(
      SendOtpRequest request) async {
    try {
      print('🔐 [OTP] Sending OTP to guardian');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw StudentsException('No authentication token found');
      }

      final url = _baseUrl + ApiConstants.sendOtpEndpoint;
      final headers = ApiConstants.getAuthHeaders(token);

      print('🔐 [OTP] URL: $url');
      print('🔐 [OTP] Body: ${jsonEncode(request.toJson())}');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 30));

      print('🔐 [OTP] Response status: ${response.statusCode}');
      print('🔐 [OTP] Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw StudentsException(
            errorData['message']?.toString() ?? 'Bad request');
      } else if (response.statusCode == 404) {
        throw StudentsException('Guardian not found');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw StudentsException(
            errorData['message']?.toString() ?? 'Failed to send OTP');
      }
    } catch (e) {
      print('🔐 [OTP] Error sending OTP: $e');
      if (e is StudentsException) {
        rethrow;
      } else {
        throw StudentsException('Network error: ${e.toString()}');
      }
    }
  }

  /// Verify OTP and link child
  static Future<VerifyOtpResponse> verifyOtpAndLinkChild(
      VerifyOtpRequest request) async {
    try {
      print('🔐 [OTP] Verifying OTP');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw StudentsException('No authentication token found');
      }

      final url = _baseUrl + ApiConstants.verifyOtpEndpoint;
      final headers = ApiConstants.getAuthHeaders(token);

      print('🔐 [OTP] URL: $url');
      print('🔐 [OTP] Body: ${jsonEncode(request.toJson())}');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 30));

      print('🔐 [OTP] Response status: ${response.statusCode}');
      print('🔐 [OTP] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return VerifyOtpResponse.fromJson(responseData);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw StudentsException(
            errorData['message']?.toString() ?? 'Failed to verify OTP');
      }
    } catch (e) {
      print('🔐 [OTP] Error verifying OTP: $e');
      if (e is StudentsException) {
        rethrow;
      } else {
        throw StudentsException('Network error: ${e.toString()}');
      }
    }
  }

  /// Get non-Egyptian child requests
  static Future<NonEgyptianRequestsResponse> getNonEgyptianRequests() async {
    try {
      print('🌍 [NON_EGYPTIAN] Getting requests');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw StudentsException('No authentication token found');
      }

      final url = _baseUrl + ApiConstants.getNonEgyptianRequestsEndpoint;
      final headers = ApiConstants.getAuthHeaders(token);

      print('🌍 [NON_EGYPTIAN] URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      print('🌍 [NON_EGYPTIAN] Response status: ${response.statusCode}');
      print('🌍 [NON_EGYPTIAN] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return NonEgyptianRequestsResponse.fromJson(responseData);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw StudentsException(
            errorData['message']?.toString() ?? 'Failed to get requests');
      }
    } catch (e) {
      print('🌍 [NON_EGYPTIAN] Error getting requests: $e');
      if (e is StudentsException) {
        rethrow;
      } else {
        throw StudentsException('Network error: ${e.toString()}');
      }
    }
  }
}
