import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import 'user_storage_service.dart';
import 'grades_service.dart';

class SchoolClass {
  final String id;
  final String name;
  final StageInfo? stage;
  final GradeInfo? grade;
  final SectionInfo? section;
  final String? school;
  final int? studentCount;
  final String? createdAt;

  SchoolClass({
    required this.id,
    required this.name,
    this.stage,
    this.grade,
    this.section,
    this.school,
    this.studentCount,
    this.createdAt,
  });

  factory SchoolClass.fromJson(Map<String, dynamic> json) {
    return SchoolClass(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      stage: json['stage'] != null ? StageInfo.fromJson(json['stage']) : null,
      grade: json['grade'] != null ? GradeInfo.fromJson(json['grade']) : null,
      section: json['section'] != null ? SectionInfo.fromJson(json['section']) : null,
      school: json['school'],
      studentCount: json['studentCount'],
      createdAt: json['createdAt'],
    );
  }
}

class StageInfo {
  final String id;
  final String name;
  final String? description;
  final int? order;

  StageInfo({
    required this.id,
    required this.name,
    this.description,
    this.order,
  });

  factory StageInfo.fromJson(Map<String, dynamic> json) {
    return StageInfo(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      order: json['order'],
    );
  }
}

class GradeInfo {
  final String id;
  final String name;
  final int? order;

  GradeInfo({
    required this.id,
    required this.name,
    this.order,
  });

  factory GradeInfo.fromJson(Map<String, dynamic> json) {
    return GradeInfo(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      order: json['order'],
    );
  }
}

class SectionInfo {
  final String id;
  final String name;
  final int? order;

  SectionInfo({
    required this.id,
    required this.name,
    this.order,
  });

  factory SectionInfo.fromJson(Map<String, dynamic> json) {
    return SectionInfo(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      order: json['order'],
    );
  }
}

class ClassesResponse {
  final List<SchoolClass> classes;
  final List<StageInfo> gradesOffered;
  final List<GradeInfo> years;
  final List<SectionInfo> divisions;
  final bool success;
  final String message;

  ClassesResponse({
    required this.classes,
    this.gradesOffered = const [],
    this.years = const [],
    this.divisions = const [],
    required this.success,
    required this.message,
  });

  factory ClassesResponse.fromJson(Map<String, dynamic> json) {
    return ClassesResponse(
      classes: (json['classes'] as List<dynamic>?)
          ?.map((c) => SchoolClass.fromJson(c))
          .toList() ?? [],
      gradesOffered: (json['gradesOffered'] as List<dynamic>?)
          ?.map((s) => StageInfo.fromJson(s))
          .toList() ?? [],
      years: (json['years'] as List<dynamic>?)
          ?.map((y) => GradeInfo.fromJson(y))
          .toList() ?? [],
      divisions: (json['divisions'] as List<dynamic>?)
          ?.map((d) => SectionInfo.fromJson(d))
          .toList() ?? [],
      success: json['success'] ?? true,
      message: json['message'] ?? 'Classes loaded successfully',
    );
  }
}

class ClassesException implements Exception {
  final String message;

  ClassesException(this.message);

  @override
  String toString() => 'ClassesException: $message';
}

class ClassesService {
  static const String _baseUrl = ApiConstants.baseUrl;

  /// Get all classes for a specific school
  static Future<ClassesResponse> getAllClasses(String schoolId) async {
    try {
      print('📚 [CLASSES] Getting classes for school: $schoolId');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw ClassesException('No authentication token found');
      }

      final url = '$_baseUrl/schools/my/$schoolId/classes';
      final headers = ApiConstants.getAuthHeaders(token);

      print('📚 [CLASSES] URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📚 [CLASSES] Response status: ${response.statusCode}');
      print('📚 [CLASSES] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return ClassesResponse.fromJson(responseData);
      } else if (response.statusCode == 403) {
        final errorData = jsonDecode(response.body);
        throw ClassesException('Unauthorized: ${errorData['message']}');
      } else if (response.statusCode == 404) {
        throw ClassesException('School not found');
      } else {
        throw ClassesException('Failed to load classes: ${response.statusCode}');
      }
    } catch (e) {
      print('📚 [CLASSES] Error getting classes: $e');
      if (e is ClassesException) rethrow;
      throw ClassesException('Failed to load classes: $e');
    }
  }

  /// Create a new class
  static Future<SchoolClass> addClass(String schoolId, Map<String, dynamic> classData) async {
    try {
      print('📚 [CLASSES] Adding class for school: $schoolId');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw ClassesException('No authentication token found');
      }

      final url = '$_baseUrl/schools/my/$schoolId/classes';
      final headers = ApiConstants.getAuthHeaders(token);

      print('📚 [CLASSES] URL: $url');
      print('📚 [CLASSES] Data: $classData');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(classData),
      );

      print('📚 [CLASSES] Response status: ${response.statusCode}');
      print('📚 [CLASSES] Response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return SchoolClass.fromJson(responseData['class']);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw ClassesException(errorData['message'] ?? 'Invalid data');
      } else if (response.statusCode == 403) {
        throw ClassesException('Unauthorized access');
      } else {
        throw ClassesException('Failed to add class: ${response.statusCode}');
      }
    } catch (e) {
      print('📚 [CLASSES] Error adding class: $e');
      if (e is ClassesException) rethrow;
      throw ClassesException('Failed to add class: $e');
    }
  }

  /// Update a class
  static Future<SchoolClass> updateClass(String schoolId, String classId, Map<String, dynamic> classData) async {
    try {
      print('📚 [CLASSES] Updating class $classId for school: $schoolId');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw ClassesException('No authentication token found');
      }

      final url = '$_baseUrl/schools/my/$schoolId/classes/$classId';
      final headers = ApiConstants.getAuthHeaders(token);

      print('📚 [CLASSES] URL: $url');
      print('📚 [CLASSES] Data: $classData');

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(classData),
      );

      print('📚 [CLASSES] Response status: ${response.statusCode}');
      print('📚 [CLASSES] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return SchoolClass.fromJson(responseData['class'] ?? responseData);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw ClassesException(errorData['message'] ?? 'Invalid data');
      } else if (response.statusCode == 403) {
        throw ClassesException('Unauthorized access');
      } else if (response.statusCode == 404) {
        throw ClassesException('Class not found');
      } else {
        throw ClassesException('Failed to update class: ${response.statusCode}');
      }
    } catch (e) {
      print('📚 [CLASSES] Error updating class: $e');
      if (e is ClassesException) rethrow;
      throw ClassesException('Failed to update class: $e');
    }
  }

  /// Delete empty classes
  static Future<int> deleteEmptyClasses(String schoolId) async {
    try {
      print('📚 [CLASSES] Deleting empty classes for school: $schoolId');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw ClassesException('No authentication token found');
      }

      final url = '$_baseUrl/schools/my/$schoolId/classes';
      final headers = ApiConstants.getAuthHeaders(token);

      print('📚 [CLASSES] URL: $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      );

      print('📚 [CLASSES] Response status: ${response.statusCode}');
      print('📚 [CLASSES] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['deletedCount'] ?? 0;
      } else if (response.statusCode == 403) {
        throw ClassesException('Unauthorized access');
      } else {
        throw ClassesException('Failed to delete classes: ${response.statusCode}');
      }
    } catch (e) {
      print('📚 [CLASSES] Error deleting classes: $e');
      if (e is ClassesException) rethrow;
      throw ClassesException('Failed to delete classes: $e');
    }
  }
}

