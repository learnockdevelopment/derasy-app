import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import 'user_storage_service.dart';

class UserProfileService {
  static const String _baseUrl = ApiConstants.baseUrl;

  /// Get current user profile from API
  static Future<Map<String, dynamic>> getCurrentUserProfile() async {
    try {
      print('👤 [USER PROFILE API] ===========================================');
      print('👤 [USER PROFILE API] Starting getCurrentUserProfile() method');
      
      final token = await UserStorageService.getAuthToken();
      print('👤 [USER PROFILE API] Token retrieved: ${token != null ? "YES" : "NO"}');
      if (token == null) {
        print('👤 [USER PROFILE API] ERROR: No authentication token found');
        throw Exception('No authentication token found');
      }

      final url = Uri.parse('$_baseUrl/me');
      final headers = ApiConstants.getAuthHeaders(token);

      print('👤 [USER PROFILE API] Getting user profile...');
      print('👤 [USER PROFILE API] Base URL: $_baseUrl');
      print('👤 [USER PROFILE API] Full URL: $url');
      print('👤 [USER PROFILE API] Headers: $headers');
      print('👤 [USER PROFILE API] ===========================================');

      final response = await http.get(url, headers: headers);

      print('👤 [USER PROFILE API] Response status: ${response.statusCode}');
      print('👤 [USER PROFILE API] Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Check if response is HTML (starts with <!DOCTYPE or <html)
        if (response.body.trim().startsWith('<!DOCTYPE') || 
            response.body.trim().startsWith('<html')) {
          print('👤 [USER PROFILE API] Response is HTML, not JSON');
          throw Exception('API returned HTML instead of JSON. This might be a server configuration issue.');
        }
        
        try {
          final data = jsonDecode(response.body);
          print('👤 [USER PROFILE API] Successfully retrieved user profile');
          return data;
        } catch (e) {
          print('👤 [USER PROFILE API] Failed to parse JSON: $e');
          print('👤 [USER PROFILE API] Response body: ${response.body}');
          throw Exception('Invalid JSON response from server');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid token');
      } else if (response.statusCode == 404) {
        throw Exception('User not found');
      } else {
        throw Exception('Failed to get user profile. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('👤 [USER PROFILE API] ===========================================');
      print('👤 [USER PROFILE API] ERROR in getCurrentUserProfile(): $e');
      print('👤 [USER PROFILE API] Error type: ${e.runtimeType}');
      print('👤 [USER PROFILE API] Stack trace: ${StackTrace.current}');
      print('👤 [USER PROFILE API] ===========================================');
      rethrow;
    }
  }

  /// Update user profile
  static Future<Map<String, dynamic>> updateUserProfile({
    required String name,
    required String phone,
    String? avatar,
  }) async {
    try {
      final token = await UserStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = Uri.parse('$_baseUrl/me');
      final headers = ApiConstants.getAuthHeaders(token);
      headers['Content-Type'] = 'application/json';

      final body = {
        'name': name,
        'phone': phone,
        if (avatar != null && avatar.isNotEmpty) 'avatar': avatar,
      };

      print('👤 [USER PROFILE API] Updating user profile...');
      print('👤 [USER PROFILE API] URL: $url');
      print('👤 [USER PROFILE API] Headers: $headers');
      print('👤 [USER PROFILE API] Body: $body');

      final response = await http.put(url, headers: headers, body: jsonEncode(body));

      print('👤 [USER PROFILE API] Response status: ${response.statusCode}');
      print('👤 [USER PROFILE API] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('👤 [USER PROFILE API] Successfully updated user profile');
        return data;
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw Exception('Validation error: ${errorData['message']}');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid token');
      } else {
        throw Exception('Failed to update user profile. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('👤 [USER PROFILE API] Error updating user profile: $e');
      rethrow;
    }
  }
}
