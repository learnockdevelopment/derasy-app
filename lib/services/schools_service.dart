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
        final schoolsResponse = SchoolsResponse.fromJson(jsonData);

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
        final jsonData = json.decode(response.body);
        final error = SchoolsError.fromJson(jsonData);
        throw SchoolsException('Server error: ${error.message}', error: error);
      } else {
        throw SchoolsException(
            'Failed to get schools. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('🏫 [SCHOOLS] Error getting schools: $e');
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
