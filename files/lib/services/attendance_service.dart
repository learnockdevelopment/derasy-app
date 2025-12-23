import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../services/user_storage_service.dart';

class AttendanceRecord {
  final String? id;
  final String childId;
  final String? childName;
  final String? childGender;
  final String date;
  final String status; // present, absent, late
  final String? checkInTime;
  final String? checkOutTime;
  final String? schoolId;
  final String? notes;

  AttendanceRecord({
    this.id,
    required this.childId,
    this.childName,
    this.childGender,
    required this.date,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
    this.schoolId,
    this.notes,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['_id'] ?? json['id'],
      childId: json['childId']?['_id'] ?? json['childId'] ?? '',
      childName: json['childId']?['fullName'],
      childGender: json['childId']?['gender'],
      date: json['date'] ?? '',
      status: json['status'] ?? '',
      checkInTime: json['checkInTime'],
      checkOutTime: json['checkOutTime'],
      schoolId: json['schoolId'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'childId': childId,
      'schoolId': schoolId,
      'date': date,
      'status': status,
      if (checkInTime != null) 'checkInTime': checkInTime,
      if (checkOutTime != null) 'checkOutTime': checkOutTime,
      if (notes != null) 'notes': notes,
    };
  }
}

class AttendanceSummary {
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final double attendanceRate;

  AttendanceSummary({
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.attendanceRate,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      totalDays: json['totalDays'] ?? 0,
      presentDays: json['presentDays'] ?? 0,
      absentDays: json['absentDays'] ?? 0,
      attendanceRate: (json['attendanceRate'] ?? 0.0).toDouble(),
    );
  }
}

class AttendanceResponse {
  final bool success;
  final String message;
  final List<AttendanceRecord>? attendances;
  final AttendanceRecord? attendance;
  final AttendanceSummary? summary;

  AttendanceResponse({
    required this.success,
    required this.message,
    this.attendances,
    this.attendance,
    this.summary,
  });

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? '',
      attendances: (json['attendances'] as List<dynamic>?)
          ?.map((record) => AttendanceRecord.fromJson(record))
          .toList(),
      attendance: json['attendance'] != null
          ? AttendanceRecord.fromJson(json['attendance'])
          : null,
      summary: json['summary'] != null
          ? AttendanceSummary.fromJson(json['summary'])
          : null,
    );
  }
}

class AttendanceException implements Exception {
  final String message;
  final dynamic error;

  AttendanceException(this.message, {this.error});

  @override
  String toString() => 'AttendanceException: $message';
}

class AttendanceService {
  static const String _baseUrl = ApiConstants.baseUrl;

  /// Get all attendance records for a school
  static Future<AttendanceResponse> getAllAttendance(String schoolId) async {
    try {
      print('📅 [ATTENDANCE] Getting all attendance for school: $schoolId');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw AttendanceException('No authentication token found');
      }

      final url = _baseUrl + ApiConstants.getAllAttendanceEndpoint;
      final headers = ApiConstants.getAuthHeaders(token);
      final queryParams = {'schoolId': schoolId};

      print('📅 [ATTENDANCE] URL: $url');
      print('📅 [ATTENDANCE] Headers: $headers');
      print('📅 [ATTENDANCE] Query params: $queryParams');

      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      print('📅 [ATTENDANCE] Response status: ${response.statusCode}');
      print('📅 [ATTENDANCE] Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          
          // Handle case where API returns just an array
          if (responseData is List) {
            return AttendanceResponse(
              success: true,
              message: 'Attendance records retrieved successfully',
              attendances: responseData.map((item) => AttendanceRecord.fromJson(item)).toList(),
            );
          }
          
          // Handle case where API returns proper object
          return AttendanceResponse.fromJson(responseData);
        } catch (e) {
          print('📅 [ATTENDANCE] Error parsing response: $e');
          print('📅 [ATTENDANCE] Raw response: ${response.body}');
          return AttendanceResponse(
            success: true,
            message: 'Attendance records retrieved successfully',
            attendances: [],
          );
        }
      } else if (response.statusCode == 400) {
        try {
          final errorData = jsonDecode(response.body);
          throw AttendanceException(
              'Missing schoolId: ${errorData['message']}');
        } catch (e) {
          throw AttendanceException('Missing schoolId: ${response.body}');
        }
      } else if (response.statusCode == 403) {
        try {
          final errorData = jsonDecode(response.body);
          throw AttendanceException('Unauthorized: ${errorData['message']}');
        } catch (e) {
          throw AttendanceException('Unauthorized: ${response.body}');
        }
      } else {
        throw AttendanceException(
            'Failed to get attendance records. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('📅 [ATTENDANCE] Error getting attendance records: $e');
      if (e is AttendanceException) {
        rethrow;
      } else {
        throw AttendanceException('Network error: ${e.toString()}');
      }
    }
  }

  /// Create attendance record
  static Future<AttendanceResponse> createAttendance(
      AttendanceRecord record) async {
    try {
      print(
          '📅 [ATTENDANCE] Creating attendance record for child: ${record.childId}');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw AttendanceException('No authentication token found');
      }

      final url = _baseUrl + ApiConstants.createAttendanceEndpoint;
      final headers = ApiConstants.getAuthHeaders(token);
      final body = record.toJson();

      print('📅 [ATTENDANCE] URL: $url');
      print('📅 [ATTENDANCE] Headers: $headers');
      print('📅 [ATTENDANCE] Body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      print('📅 [ATTENDANCE] Response status: ${response.statusCode}');
      print('📅 [ATTENDANCE] Response body: ${response.body}');

      if (response.statusCode == 201) {
        try {
          final responseData = jsonDecode(response.body);
          return AttendanceResponse.fromJson(responseData);
        } catch (e) {
          print(
              '📅 [ATTENDANCE] Response is not JSON format, treating as success');
          return AttendanceResponse(
            success: true,
            message: 'Attendance record created successfully',
          );
        }
      } else if (response.statusCode == 400) {
        try {
          final errorData = jsonDecode(response.body);
          throw AttendanceException(
              'Missing required fields: ${errorData['message']}');
        } catch (e) {
          throw AttendanceException(
              'Missing required fields: ${response.body}');
        }
      } else if (response.statusCode == 403) {
        try {
          final errorData = jsonDecode(response.body);
          throw AttendanceException('Unauthorized: ${errorData['message']}');
        } catch (e) {
          throw AttendanceException('Unauthorized: ${response.body}');
        }
      } else {
        throw AttendanceException(
            'Failed to create attendance record. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('📅 [ATTENDANCE] Error creating attendance record: $e');
      if (e is AttendanceException) {
        rethrow;
      } else {
        throw AttendanceException('Network error: ${e.toString()}');
      }
    }
  }

  /// Get attendance by child
  static Future<AttendanceResponse> getAttendanceByChild(String childId) async {
    try {
      print('📅 [ATTENDANCE] Getting attendance for child: $childId');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw AttendanceException('No authentication token found');
      }

      final url = _baseUrl +
          ApiConstants.getAttendanceByChildEndpoint
              .replaceFirst('[childId]', childId);
      final headers = ApiConstants.getAuthHeaders(token);

      print('📅 [ATTENDANCE] URL: $url');
      print('📅 [ATTENDANCE] Headers: $headers');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📅 [ATTENDANCE] Response status: ${response.statusCode}');
      print('📅 [ATTENDANCE] Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          
          // Handle case where API returns just an array
          if (responseData is List) {
            return AttendanceResponse(
              success: true,
              message: 'Child attendance records retrieved successfully',
              attendances: responseData.map((item) => AttendanceRecord.fromJson(item)).toList(),
            );
          }
          
          // Handle case where API returns proper object
          return AttendanceResponse.fromJson(responseData);
        } catch (e) {
          print('📅 [ATTENDANCE] Error parsing response: $e');
          print('📅 [ATTENDANCE] Raw response: ${response.body}');
          return AttendanceResponse(
            success: true,
            message: 'Child attendance records retrieved successfully',
            attendances: [],
          );
        }
      } else if (response.statusCode == 403) {
        try {
          final errorData = jsonDecode(response.body);
          throw AttendanceException('Unauthorized: ${errorData['message']}');
        } catch (e) {
          throw AttendanceException('Unauthorized: ${response.body}');
        }
      } else if (response.statusCode == 404) {
        try {
          final errorData = jsonDecode(response.body);
          throw AttendanceException('Child not found: ${errorData['message']}');
        } catch (e) {
          throw AttendanceException('Child not found: ${response.body}');
        }
      } else {
        throw AttendanceException(
            'Failed to get child attendance. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('📅 [ATTENDANCE] Error getting child attendance: $e');
      if (e is AttendanceException) {
        rethrow;
      } else {
        throw AttendanceException('Network error: ${e.toString()}');
      }
    }
  }
}
