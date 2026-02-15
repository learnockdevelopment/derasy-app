import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/school_models.dart';
import '../models/school_suggestion_models.dart';
import 'user_storage_service.dart';



class SchoolsService {
  static const String _baseUrl = ApiConstants.baseUrl;

  // Get all schools with optional pagination/filtering (though API seems to return all or list)
  static Future<SchoolsResponse> getAllSchools() async {
    try {
      final token = UserStorageService.getAuthToken();
      final headers = ApiConstants.getHeaders(token: token);
      final url = '$_baseUrl${ApiConstants.getAllSchoolsEndpoint}';
      
      print('🏫 [SCHOOLS] Fetching all schools: $url');
      
      final response = await http.get(Uri.parse(url), headers: headers);
      
      print('🏫 [SCHOOLS] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return SchoolsResponse.fromJson(json);
      } else {
        throw SchoolsException('Failed to load schools: ${response.statusCode}');
      }
    } catch (e) {
      print('🏫 [SCHOOLS] Error: $e');
      throw SchoolsException('Network error: $e');
    }
  }

  // Get single school by ID
  static Future<School> getSchoolById(String id) async {
    try {
      final token = UserStorageService.getAuthToken();
      final headers = ApiConstants.getHeaders(token: token);
      // Assuming endpoint is /schools/[id]
      final url = '$_baseUrl${ApiConstants.getAllSchoolsEndpoint}/$id';
      
      print('🏫 [SCHOOLS] Fetching school details: $url');
      
      final response = await http.get(Uri.parse(url), headers: headers);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json is Map<String, dynamic>) {
           // Check if wrapped in 'school' or 'data'
           if (json.containsKey('school')) {
             return School.fromJson(json['school']);
           } else if (json.containsKey('data')) {
             return School.fromJson(json['data']);
           }
           // Or direct object
           return School.fromJson(json);
        }
        throw SchoolsException('Invalid response format');
      } else {
        throw SchoolsException('Failed to load school details: ${response.statusCode}');
      }
    } catch (e) {
      print('🏫 [SCHOOLS] Error: $e');
      throw SchoolsException('Network error: $e');
    }
  }

  // Suggest schools based on preferences (Mock implementation or client-side filter)
  static Future<SchoolSuggestionResponse> suggestThree(SchoolSuggestionRequest request) async {
    try {
      // Since no dedicated endpoint exists in ApiConstants, perform client-side filtering
      print('🏫 [SCHOOLS] Suggesting schools based on preferences...');
      
      var filtered = request.schools;
      final prefs = request.preferences;

      // Filter by Type
      if (prefs.type != null && prefs.type!.isNotEmpty) {
        filtered = filtered.where((s) => s.type?.toLowerCase() == prefs.type!.toLowerCase()).toList();
      }
      
      // Filter by Language
      if (prefs.language != null && prefs.language!.isNotEmpty) {
        filtered = filtered.where((s) => s.languages.any((l) => l.toLowerCase().contains(prefs.language!.toLowerCase()))).toList();
      }

      // Filter by max fee
      if (prefs.maxFee != null) {
        filtered = filtered.where((s) {
           if (s.feesRange != null) return s.feesRange!.min <= prefs.maxFee!;
           if (s.admissionFee != null) return s.admissionFee!.amount <= prefs.maxFee!;
           return true; // Keep if no fee info
        }).toList();
      }

      // Take top 3
      final top3 = filtered.take(3).toList();
      final ids = top3.map((s) => s.id).toList();

      return SchoolSuggestionResponse(
        message: 'Here are the best matches based on your criteria.',
        suggestedIds: ids,
        markdown: '### Top Recommendations\n\n' + top3.map((s) => '- **${s.name}**\n  Loc: ${s.location?.city ?? "Unknown"}\n  Type: ${s.type ?? "N/A"}').join('\n'),
      );

    } catch (e) {
      print('🏫 [SCHOOLS] Error suggesting schools: $e');
      throw SchoolsException('Failed to suggest schools: $e');
    }
  }
}
