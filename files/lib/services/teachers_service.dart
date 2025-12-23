import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import 'user_storage_service.dart';
import 'grades_service.dart';

class TeacherSubject {
  final String id;
  final String name;
  final Grade? grade;

  TeacherSubject({
    required this.id,
    required this.name,
    this.grade,
  });

  factory TeacherSubject.fromJson(Map<String, dynamic> json) {
    return TeacherSubject(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      grade: json['grade'] != null ? Grade.fromJson(json['grade']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      if (grade != null) 'grade': grade!.toJson(),
    };
  }
}

class TeacherClass {
  final String id;
  final String name;
  final Grade? grade;

  TeacherClass({
    required this.id,
    required this.name,
    this.grade,
  });

  factory TeacherClass.fromJson(Map<String, dynamic> json) {
    return TeacherClass(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      grade: json['grade'] != null ? Grade.fromJson(json['grade']) : null,
    );
  }
}

class TeacherDetails {
  final String? employeeId;
  final List<TeacherSubject> subjects;
  final List<TeacherClass> classes;
  final List<Grade> gradeLevels;
  final String? hireDate;
  final int? salary;
  final String? employmentType;
  final List<String> qualifications;
  final int? experienceYears;

  TeacherDetails({
    this.employeeId,
    this.subjects = const [],
    this.classes = const [],
    this.gradeLevels = const [],
    this.hireDate,
    this.salary,
    this.employmentType,
    this.qualifications = const [],
    this.experienceYears,
  });

  factory TeacherDetails.fromJson(Map<String, dynamic>? json) {
    if (json == null) return TeacherDetails();
    
    return TeacherDetails(
      employeeId: json['employeeId'],
      subjects: (json['subjects'] as List<dynamic>?)
          ?.map((s) => TeacherSubject.fromJson(s))
          .toList() ?? [],
      classes: (json['class'] as List<dynamic>?)
          ?.map((c) => TeacherClass.fromJson(c))
          .toList() ?? [],
      gradeLevels: (json['gradeLevels'] as List<dynamic>?)
          ?.map((g) => Grade.fromJson(g))
          .toList() ?? [],
      hireDate: json['hireDate'],
      salary: json['salary'],
      employmentType: json['employmentType'],
      qualifications: (json['qualifications'] as List<dynamic>?)
          ?.map((q) => q.toString())
          .toList() ?? [],
      experienceYears: json['experienceYears'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (employeeId != null) 'employeeId': employeeId,
      'subjects': subjects.map((s) => s.id).toList(),
      'classList': classes.map((c) => c.id).toList(),
      'gradeLevels': gradeLevels.map((g) => g.id).toList(),
      if (hireDate != null) 'hireDate': hireDate,
      if (salary != null) 'salary': salary,
      if (employmentType != null) 'employmentType': employmentType,
      'qualifications': qualifications,
      if (experienceYears != null) 'experienceYears': experienceYears,
    };
  }
}

class Teacher {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? username;
  final String? avatar;
  final TeacherDetails? teacher;
  final bool? systemUser;
  final bool? isActive;
  final String? createdAt;

  Teacher({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.username,
    this.avatar,
    this.teacher,
    this.systemUser,
    this.isActive,
    this.createdAt,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? json['fullName'] ?? '',
      email: json['email'],
      phone: json['phone'],
      username: json['username'],
      avatar: json['avatar'],
      teacher: json['teacher'] != null ? TeacherDetails.fromJson(json['teacher']) : null,
      systemUser: json['systemUser'],
      isActive: json['isActive'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'username': username,
      'avatar': avatar,
      if (teacher != null) 'teacher': teacher!.toJson(),
      'systemUser': systemUser,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }

  // Helper getters for backward compatibility
  String? get subject {
    if (teacher?.subjects.isNotEmpty == true) {
      return teacher!.subjects.map((s) => s.name).join(', ');
    }
    return null;
  }
}

class TeachersResponse {
  final List<Teacher> teachers;
  final bool success;
  final String message;

  TeachersResponse({
    required this.teachers,
    required this.success,
    required this.message,
  });

  factory TeachersResponse.fromJson(Map<String, dynamic> json) {
    return TeachersResponse(
      teachers: (json['teachers'] as List<dynamic>?)
              ?.map((teacher) => Teacher.fromJson(teacher))
              .toList() ??
          [],
      success: json['success'] ?? true,
      message: json['message'] ?? 'Teachers loaded successfully',
    );
  }
}

class TeachersException implements Exception {
  final String message;

  TeachersException(this.message);

  @override
  String toString() => 'TeachersException: $message';
}

class TeachersService {
  static const String _baseUrl = ApiConstants.baseUrl;

  /// Get all teachers for a specific school
  static Future<TeachersResponse> getAllTeachers(String schoolId) async {
    try {
      print('👨‍🏫 [TEACHERS] Getting teachers for school: $schoolId');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw TeachersException('No authentication token found');
      }

      // Note: This endpoint may need to be added to API constants
      // For now, using a placeholder endpoint pattern
      final url = _baseUrl +
          '/schools/my/$schoolId/teachers';
      final headers = ApiConstants.getAuthHeaders(token);

      print('👨‍🏫 [TEACHERS] URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('👨‍🏫 [TEACHERS] Response status: ${response.statusCode}');
      print('👨‍🏫 [TEACHERS] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return TeachersResponse.fromJson(responseData);
      } else if (response.statusCode == 403) {
        final errorData = jsonDecode(response.body);
        throw TeachersException('Unauthorized: ${errorData['message']}');
      } else if (response.statusCode == 500) {
        final errorData = jsonDecode(response.body);
        throw TeachersException('Server error: ${errorData['message']}');
      } else {
        // Return empty list if endpoint doesn't exist yet
        return TeachersResponse(
          teachers: [],
          success: true,
          message: 'No teachers endpoint available',
        );
      }
    } catch (e) {
      print('👨‍🏫 [TEACHERS] Error getting teachers: $e');
      // Return empty list instead of throwing to allow page to load
      return TeachersResponse(
        teachers: [],
        success: false,
        message: 'Failed to load teachers',
      );
    }
  }

  /// Add a new teacher
  static Future<Teacher> addTeacher(String schoolId, Map<String, dynamic> teacherData) async {
    try {
      print('👨‍🏫 [TEACHERS] Adding teacher for school: $schoolId');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw TeachersException('No authentication token found');
      }

      final url = '$_baseUrl/schools/my/$schoolId/teachers';
      final headers = ApiConstants.getAuthHeaders(token);

      print('👨‍🏫 [TEACHERS] URL: $url');
      print('👨‍🏫 [TEACHERS] Data: $teacherData');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(teacherData),
      );

      print('👨‍🏫 [TEACHERS] Response status: ${response.statusCode}');
      print('👨‍🏫 [TEACHERS] Response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return Teacher.fromJson(responseData['teacher']);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw TeachersException(errorData['message'] ?? 'Invalid data');
      } else if (response.statusCode == 403) {
        throw TeachersException('Unauthorized access');
      } else {
        throw TeachersException('Failed to add teacher: ${response.statusCode}');
      }
    } catch (e) {
      print('👨‍🏫 [TEACHERS] Error adding teacher: $e');
      if (e is TeachersException) rethrow;
      throw TeachersException('Failed to add teacher: $e');
    }
  }

  /// Update teacher information
  static Future<Teacher> updateTeacher(String schoolId, String teacherId, Map<String, dynamic> teacherData) async {
    try {
      print('👨‍🏫 [TEACHERS] Updating teacher: $teacherId for school: $schoolId');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw TeachersException('No authentication token found');
      }

      final url = '$_baseUrl/schools/my/$schoolId/teachers';
      final headers = ApiConstants.getAuthHeaders(token);
      final data = {
        ...teacherData,
        'teacherId': teacherId,
      };

      print('👨‍🏫 [TEACHERS] URL: $url');
      print('👨‍🏫 [TEACHERS] Data: $data');

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(data),
      );

      print('👨‍🏫 [TEACHERS] Response status: ${response.statusCode}');
      print('👨‍🏫 [TEACHERS] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return Teacher.fromJson(responseData['teacher']);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw TeachersException(errorData['message'] ?? 'Invalid data');
      } else if (response.statusCode == 404) {
        throw TeachersException('Teacher not found');
      } else if (response.statusCode == 403) {
        throw TeachersException('Unauthorized access');
      } else {
        throw TeachersException('Failed to update teacher: ${response.statusCode}');
      }
    } catch (e) {
      print('👨‍🏫 [TEACHERS] Error updating teacher: $e');
      if (e is TeachersException) rethrow;
      throw TeachersException('Failed to update teacher: $e');
    }
  }

  /// Delete a teacher
  static Future<void> deleteTeacher(String schoolId, String teacherId) async {
    try {
      print('👨‍🏫 [TEACHERS] Deleting teacher: $teacherId for school: $schoolId');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw TeachersException('No authentication token found');
      }

      final url = '$_baseUrl/schools/my/$schoolId/teachers';
      final headers = ApiConstants.getAuthHeaders(token);

      print('👨‍🏫 [TEACHERS] URL: $url');
      print('👨‍🏫 [TEACHERS] Teacher ID: $teacherId');

      final response = await http.delete(
        Uri.parse('$url?teacherId=$teacherId'),
        headers: headers,
      );

      print('👨‍🏫 [TEACHERS] Response status: ${response.statusCode}');
      print('👨‍🏫 [TEACHERS] Response body: ${response.body}');

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw TeachersException(errorData['message'] ?? 'Invalid teacher ID');
      } else if (response.statusCode == 404) {
        throw TeachersException('Teacher not found');
      } else if (response.statusCode == 403) {
        throw TeachersException('Unauthorized access');
      } else {
        throw TeachersException('Failed to delete teacher: ${response.statusCode}');
      }
    } catch (e) {
      print('👨‍🏫 [TEACHERS] Error deleting teacher: $e');
      if (e is TeachersException) rethrow;
      throw TeachersException('Failed to delete teacher: $e');
    }
  }
}

