import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../services/user_storage_service.dart';

class SalesService {
  static const String _baseUrl = ApiConstants.baseUrl;

  static Future<Map<String, dynamic>> onboardSchool(Map<String, dynamic> onboardingData) async {
    final token = UserStorageService.getAuthToken();
    try {
      final url = '$_baseUrl${ApiConstants.salesOnboardingEndpoint}';
      print('🚀 [SalesService] Posting to: $url');
      
      // Enhance payload with defaults to satisfy backend controller expectations
      final Map<String, dynamic> enhancedData = Map.from(onboardingData);
      
      enhancedData['schoolData'] ??= {};
      enhancedData['configData'] ??= {};
      
      // Ensure financials exist to avoid NaN in backend
      if (enhancedData['schoolData']['financials'] == null) {
        enhancedData['schoolData']['financials'] = {'registrationFees': 0};
      }
      
      // Ensure selectedStructure exists (can be empty)
      if (enhancedData['schoolData']['selectedStructure'] == null) {
        enhancedData['schoolData']['selectedStructure'] = {};
      }

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConstants.getHeaders(token: token),
        body: jsonEncode(enhancedData),
      );

      print('📡 [SalesService] Response Code: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(errorData['message'] ?? 'Failed to onboard school');
      }
    } catch (e) {
      print('❌ [SalesService] Error: $e');
      rethrow;
    }
  }

  static Future<List<dynamic>> getSalesSchools() async {
    final token = UserStorageService.getAuthToken();
    try {
      final url = '$_baseUrl${ApiConstants.salesMySchoolsEndpoint}';
      print('🚀 [SalesService] Fetching schools from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: ApiConstants.getHeaders(token: token),
      );
      
      print('📡 [SalesService] Get Schools Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map && data.containsKey('schools')) return data['schools'];
        return [];
      } else {
        throw Exception('Failed to fetch sales schools');
      }
    } catch (e) {
      rethrow;
    }
  }
}
