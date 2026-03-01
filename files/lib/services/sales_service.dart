import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import 'auth_service.dart';
import 'user_storage_service.dart';
import 'auth_error_handler.dart';

class SalesService {
  static const String _baseUrl = ApiConstants.salesBaseUrl;

  /// Helper to handle 403 errors and HTML redirects globally
  static Future<bool> _handleResponse(http.Response response) async {
    final body = response.body.trim();
    
    // Check for 403/401
    if (response.statusCode == 403) {
      print('🔒 [SalesService] Unauthorized Access Attempt ( ${response.statusCode} )');
      
      final token = UserStorageService.getAuthToken();
      print('🔒 [SalesService] Token Status: ${token != null ? "Exists (${token.length} chars)" : "MISSING"}');

      if (token == null || token.isEmpty) {
        print('🔒 [SalesService] No token found - Redirecting to login');
        await AuthErrorHandler.handle403Error();
        return true;
      }

      try {
        print('🔍 [SalesService] Verifying session via profile check...');
        
        // Attempt to get profile - this will check Sales first then Parent
        await AuthService.getUserProfile(token);
        
        print('✅ [SalesService] Session verified via profile check (could be Sales or Parent).');
        return false; // Token is valid somewhere, do not logout as requested
      } catch (e) {
        print('❌ [SalesService] Session verification failed on all backends: $e');
        await AuthErrorHandler.handle403Error();
        return true;
      }
    }

    // Check for HTML response (happens when hitting frontend instead of API)
    if (body.startsWith('<!DOCTYPE html>') || body.startsWith('<html')) {
       print('⚠️ [SalesService] Received HTML response - Likely session issue.');
       final token = UserStorageService.getAuthToken();
       if (token == null || token.isEmpty) {
         await AuthErrorHandler.handle403Error();
         return true;
       }
       
       try {
         await AuthService.getUserProfile(token);
         print('✅ [SalesService] Session verified after HTML response.');
         return false; 
       } catch (e) {
         print('❌ [SalesService] Profile check failed after HTML response: $e');
         await AuthErrorHandler.handle403Error();
         return true;
       }
    }

    return false;
  }

  /// [1.1] Education Systems Lookup (Public)
  static Future<Map<String, dynamic>> getEducationSystems() async {
    try {
      final url = '$_baseUrl${ApiConstants.getEducationSystemsEndpoint}';
      print('🚀 [SalesService] Lookup Systems: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: ApiConstants.defaultHeaders,
      );

      if (await _handleResponse(response)) throw Exception('Session Expired');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch education systems');
      }
    } catch (e) {
      print('❌ [SalesService] Error: $e');
      rethrow;
    }
  }

  /// [1.3] Final Onboarding Submission (God-API)
  static Future<Map<String, dynamic>> onboardSchool(Map<String, dynamic> onboardingData) async {
    final token = UserStorageService.getAuthToken();
    try {
      final url = '$_baseUrl${ApiConstants.salesOnboardingEndpoint}';
      final headers = ApiConstants.getHeaders(token: token);
      final body = jsonEncode(onboardingData);

      print('🚀 [SalesService] Onboarding Request:');
      print('   Method: POST');
      print('   URL: $url');
      print('   Headers: $headers');
      print('   Body: $body');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      print('📡 [SalesService] Onboarding Response: ${response.statusCode}');

      if (await _handleResponse(response)) throw Exception('Session Expired');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception((errorData['message'] ?? 'Failed to onboard school').toString());
      }
    } catch (e) {
      print('❌ [SalesService] Error: $e');
      rethrow;
    }
  }

  /// [2.1] Dashboard Statistics
  static Future<Map<String, dynamic>> getDashboardStats() async {
    final token = UserStorageService.getAuthToken();
    try {
      final url = '$_baseUrl${ApiConstants.salesDashboardStatsEndpoint}';
      final headers = ApiConstants.getHeaders(token: token);

      print('🚀 [SalesService] Dashboard Stats Request:');
      print('   Method: GET');
      print('   URL: $url');
      print('   Headers: $headers');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      print('📡 [SalesService] Stats Response: ${response.statusCode}');

      if (await _handleResponse(response)) throw Exception('Session Expired');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch sales stats: ${response.statusCode}');
      }
    } on FormatException catch (e) {
      print('❌ [SalesService] JSON Format Error: $e');
      await AuthErrorHandler.handle403Error();
      rethrow;
    } catch (e) {
      print('❌ [SalesService] Error: $e');
      rethrow;
    }
  }

  /// School Inspection (ID Detail)
  static Future<Map<String, dynamic>> getSchoolById(String schoolId) async {
    final token = UserStorageService.getAuthToken();
    try {
      final url = '$_baseUrl${ApiConstants.salesDashboardSchoolDetailsEndpoint}/$schoolId';
      print('🚀 [SalesService] School Detail: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: ApiConstants.getHeaders(token: token),
      );
      
      print('📡 [SalesService] School Detail Response: ${response.statusCode}');

      if (await _handleResponse(response)) throw Exception('Session Expired');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch school details');
      }
    } catch (e) {
      print('❌ [SalesService] Error: $e');
      rethrow;
    }
  }

  /// [3.1] Sales Team Management (POST - Add Rep)
  static Future<Map<String, dynamic>> addSalesRepresentative(Map<String, dynamic> teamData) async {
    final token = UserStorageService.getAuthToken();
    try {
      final url = '$_baseUrl${ApiConstants.salesManagerTeamEndpoint}';
      print('🚀 [SalesService] Adding Rep: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: ApiConstants.getHeaders(token: token),
        body: jsonEncode(teamData),
      );

      if (await _handleResponse(response)) throw Exception('Session Expired');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception((errorData['message'] ?? 'Failed to add representative').toString());
      }
    } catch (e) {
      print('❌ [SalesService] Error: $e');
      rethrow;
    }
  }

  /// [3.1] Sales Team List (GET)
  static Future<List<dynamic>> getSalesTeam() async {
    final token = UserStorageService.getAuthToken();
    try {
      final url = '$_baseUrl${ApiConstants.salesManagerTeamEndpoint}';
      print('🚀 [SalesService] Fetching Team: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: ApiConstants.getHeaders(token: token),
      );

      if (await _handleResponse(response)) throw Exception('Session Expired');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map && data.containsKey('team')) return data['team'];
        return [];
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception((errorData['message'] ?? 'Failed to fetch sales team').toString());
      }
    } catch (e) {
      print('❌ [SalesService] Error: $e');
      rethrow;
    }
  }

  /// Legacy method for backward compatibility while refactoring pages
  static Future<List<dynamic>> getSalesSchools() async {
    try {
      final stats = await getDashboardStats();
      if (stats.containsKey('recentOnboardings')) {
        return stats['recentOnboardings'];
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
