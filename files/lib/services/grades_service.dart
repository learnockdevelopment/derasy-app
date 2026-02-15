import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import 'user_storage_service.dart';

class Grade {
  final String id;
  final String name;

  Grade({required this.id, required this.name});

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class GradesResponse {
  final bool success;
  final String message;
  final List<Grade> grades;

  GradesResponse({
    required this.success,
    required this.message,
    required this.grades,
  });
}

class GradesService {
  static const String _baseUrl = ApiConstants.baseUrl;

  static Future<GradesResponse> getAllGrades(String schoolId) async {
    try {
      final token = UserStorageService.getAuthToken();
      final headers = ApiConstants.getHeaders(token: token);
      final url = '$_baseUrl/schools/$schoolId/grades';
      
      print('📚 [GRADES] Fetching grades for school: $schoolId');
      
      final response = await http.get(Uri.parse(url), headers: headers);
      
      print('📚 [GRADES] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        List<Grade> grades = [];
        String message = 'Grades loaded successfully';

        if (json is Map && json['grades'] is List) {
           grades = (json['grades'] as List).map((e) => Grade.fromJson(e)).toList();
        } else if (json is List) {
           grades = json.map((e) => Grade.fromJson(e)).toList();
        } else if (json is Map && json['data'] is List) {
           grades = (json['data'] as List).map((e) => Grade.fromJson(e)).toList();
        }
        
        return GradesResponse(
          success: true,
          message: message,
          grades: grades,
        );
      } else {
        return GradesResponse(
          success: false,
          message: 'Failed to load grades: ${response.statusCode}',
          grades: [],
        );
      }
    } catch (e) {
      print('📚 [GRADES] Error: $e');
      return GradesResponse(
        success: false,
        message: 'Network error: $e',
        grades: [],
      );
    }
  }
}
