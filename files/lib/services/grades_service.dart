import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../services/user_storage_service.dart';

class Grade {
  final String id;
  final String name;
  final String? description;

  Grade({
    required this.id,
    required this.name,
    this.description,
  });

  factory Grade.fromJson(Map<String, dynamic> json) {
    print(
        '🎓 [GRADE] Parsing grade: ${json['name']} (ID: ${json['_id'] ?? json['id']})');
    return Grade(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}

class GradesResponse {
  final List<Grade> grades;
  final bool success;
  final String message;

  GradesResponse({
    required this.grades,
    required this.success,
    required this.message,
  });

  factory GradesResponse.fromJson(Map<String, dynamic> json) {
    print(
        '🎓 [GRADES RESPONSE] Parsing response with ${json['grades']?.length ?? 0} grades');
    final gradesList = (json['grades'] as List<dynamic>?)
            ?.map((grade) => Grade.fromJson(grade))
            .toList() ??
        [];
    print(
        '🎓 [GRADES RESPONSE] Parsed ${gradesList.length} grades successfully');
    return GradesResponse(
      grades: gradesList,
      success: json['success'] ?? true, // Default to true if not present
      message: json['message'] ?? 'Grades loaded successfully',
    );
  }
}

class GradesException implements Exception {
  final String message;
  final dynamic error;

  GradesException(this.message, {this.error});

  @override
  String toString() => 'GradesException: $message';
}

class GradesService {
  static const String _baseUrl = ApiConstants.baseUrl;

  /// Get all grades for a specific school
  static Future<GradesResponse> getAllGrades(String schoolId) async {
    try {
      print('📚 [GRADES] Getting grades for school: $schoolId');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw GradesException('No authentication token found');
      }

      final url = _baseUrl +
          ApiConstants.getGradesEndpoint.replaceFirst('[id]', schoolId);
      final headers = ApiConstants.getAuthHeaders(token);

      print('📚 [GRADES] URL: $url');
      print('📚 [GRADES] Headers: $headers');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📚 [GRADES] Response status: ${response.statusCode}');
      print('📚 [GRADES] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return GradesResponse.fromJson(responseData);
      } else if (response.statusCode == 403) {
        final errorData = jsonDecode(response.body);
        throw GradesException('Unauthorized: ${errorData['message']}');
      } else if (response.statusCode == 500) {
        final errorData = jsonDecode(response.body);
        throw GradesException('Server error: ${errorData['message']}');
      } else {
        throw GradesException(
            'Failed to get grades. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('📚 [GRADES] Error getting grades: $e');
      if (e is GradesException) {
        rethrow;
      } else {
        throw GradesException('Network error: ${e.toString()}');
      }
    }
  }
}

