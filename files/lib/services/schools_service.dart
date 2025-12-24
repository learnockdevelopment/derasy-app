import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/school_models.dart';
import 'user_storage_service.dart';
import 'schools_cache_service.dart';

class SchoolsService {
  static const String _baseUrl = ApiConstants.baseUrl;

  /// Get all schools for the current user
  static Future<SchoolsResponse> getAllSchools() async {
    try {
      print('🏫 [SCHOOLS] Getting all schools for user');

      // Check cache first
      final cachedSchools = SchoolsCacheService.getCachedSchools();
      if (cachedSchools != null) {
        print(
            '🏫 [SCHOOLS] Returning cached schools (${cachedSchools.length} schools)');
        return SchoolsResponse(
          success: true,
          message: 'Schools loaded from cache',
          schools: cachedSchools,
        );
      }

      // Get stored token
      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw SchoolsException('No authentication token found');
      }

      final url = '$_baseUrl${ApiConstants.getAllSchoolsEndpoint}';
      print('🏫 [SCHOOLS] URL: $url');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      print('🏫 [SCHOOLS] Headers: $headers');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('🏫 [SCHOOLS] Response status: ${response.statusCode}');
      print('🏫 [SCHOOLS] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        // Handle case where API returns a list directly instead of an object
        SchoolsResponse schoolsResponse;
        if (jsonData is List) {
          // API returned a list directly
          print('🏫 [SCHOOLS] API returned list directly, converting to response format');
          schoolsResponse = SchoolsResponse(
            success: true,
            message: 'Schools loaded successfully',
            schools: jsonData
                .map((school) => school is Map<String, dynamic>
                    ? School.fromJson(school)
                    : null)
                .where((school) => school != null)
                .cast<School>()
                .toList(),
          );
        } else if (jsonData is Map<String, dynamic>) {
          // API returned an object with schools array
          schoolsResponse = SchoolsResponse.fromJson(jsonData);
        } else {
          throw SchoolsException('Unexpected response format from server');
        }

        // Cache the schools data
        if (schoolsResponse.schools.isNotEmpty) {
          SchoolsCacheService.cacheSchools(schoolsResponse.schools);
        }

        return schoolsResponse;
      } else if (response.statusCode == 403) {
        final jsonData = json.decode(response.body);
        final error = SchoolsError.fromJson(jsonData);
        throw SchoolsException('Unauthorized access: ${error.message}',
            error: error);
      } else if (response.statusCode == 500) {
        // Try to return cached data as fallback for server errors
        final cachedSchools = SchoolsCacheService.getCachedSchools();
        if (cachedSchools != null && cachedSchools.isNotEmpty) {
          print('🏫 [SCHOOLS] Server error 500, returning cached schools as fallback');
          return SchoolsResponse(
            success: true,
            message: 'Schools loaded from cache (server temporarily unavailable)',
            schools: cachedSchools,
          );
        }
        
        final jsonData = json.decode(response.body);
        final error = SchoolsError.fromJson(jsonData);
        throw SchoolsException('Server error: ${error.message}', error: error);
      } else {
        throw SchoolsException(
            'Failed to get schools. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('🏫 [SCHOOLS] Error getting schools: $e');
      
      // If it's a network/server error, try to return cached data as fallback
      if (e is SchoolsException && e.message.contains('Server error')) {
        final cachedSchools = SchoolsCacheService.getCachedSchools();
        if (cachedSchools != null && cachedSchools.isNotEmpty) {
          print('🏫 [SCHOOLS] Returning cached schools as fallback after error');
          return SchoolsResponse(
            success: true,
            message: 'Schools loaded from cache (server temporarily unavailable)',
            schools: cachedSchools,
          );
        }
      }
      
      if (e is SchoolsException) {
        rethrow;
      } else {
        throw SchoolsException('Network error: ${e.toString()}');
      }
    }
  }

  /// Get a single school by ID
  static Future<School> getSchoolById(String schoolId) async {
    try {
      print('🏫 [SCHOOLS] Getting school by ID: $schoolId');

      // Get stored token
      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw SchoolsException('No authentication token found');
      }

      final url = '$_baseUrl/schools/my/$schoolId';
      print('🏫 [SCHOOLS] Get school URL: $url');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('🏫 [SCHOOLS] Get school response status: ${response.statusCode}');
      print('🏫 [SCHOOLS] Get school response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData is Map<String, dynamic>) {
          // Handle response with "school" wrapper
          if (jsonData.containsKey('school')) {
            return School.fromJson(jsonData['school']);
          }
          // Handle direct school object
          return School.fromJson(jsonData);
        } else {
          throw SchoolsException('Unexpected response format from server');
        }
      } else if (response.statusCode == 403) {
        final jsonData = json.decode(response.body);
        final error = SchoolsError.fromJson(jsonData);
        throw SchoolsException('Unauthorized access: ${error.message}',
            error: error);
      } else if (response.statusCode == 404) {
        throw SchoolsException('School not found');
      } else {
        throw SchoolsException(
            'Failed to get school. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('🏫 [SCHOOLS] Error getting school by ID: $e');
      if (e is SchoolsException) {
        rethrow;
      } else {
        throw SchoolsException('Network error: ${e.toString()}');
      }
    }
  }

  /// Search schools by query
  static Future<SchoolsResponse> searchSchools(String query) async {
    try {
      print('🏫 [SCHOOLS] Searching schools with query: $query');

      // Get stored token
      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw SchoolsException('No authentication token found');
      }

      final url =
          '$_baseUrl${ApiConstants.getAllSchoolsEndpoint}?search=$query';
      print('🏫 [SCHOOLS] Search URL: $url');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('🏫 [SCHOOLS] Search response status: ${response.statusCode}');
      print('🏫 [SCHOOLS] Search response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return SchoolsResponse.fromJson(jsonData);
      } else if (response.statusCode == 403) {
        final jsonData = json.decode(response.body);
        final error = SchoolsError.fromJson(jsonData);
        throw SchoolsException('Unauthorized access: ${error.message}',
            error: error);
      } else if (response.statusCode == 500) {
        final jsonData = json.decode(response.body);
        final error = SchoolsError.fromJson(jsonData);
        throw SchoolsException('Server error: ${error.message}', error: error);
      } else {
        throw SchoolsException(
            'Failed to search schools. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('🏫 [SCHOOLS] Error searching schools: $e');
      if (e is SchoolsException) {
        rethrow;
      } else {
        throw SchoolsException('Network error: ${e.toString()}');
      }
    }
  }
}
