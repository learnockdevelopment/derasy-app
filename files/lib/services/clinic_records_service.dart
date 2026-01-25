import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../services/user_storage_service.dart';

class ClinicRecord {
  final String id;
  final String date;
  final String? symptoms;
  final String? diagnosis;
  final String? treatment;
  final String? medication;
  final String? followUp;

  ClinicRecord({
    required this.id,
    required this.date,
    this.symptoms,
    this.diagnosis,
    this.treatment,
    this.medication,
    this.followUp,
  });

  factory ClinicRecord.fromJson(Map<String, dynamic> json) {
    return ClinicRecord(
      id: json['_id'] ?? '',
      date: json['date'] ?? '',
      symptoms: json['symptoms'],
      diagnosis: json['diagnosis'],
      treatment: json['treatment'],
      medication: json['medication'],
      followUp: json['followUp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'date': date,
      'symptoms': symptoms,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'medication': medication,
      'followUp': followUp,
    };
  }
}

class StudentClinicInfo {
  final String id;
  final String fullName;
  final String? medicalNotes;

  StudentClinicInfo({
    required this.id,
    required this.fullName,
    this.medicalNotes,
  });

  factory StudentClinicInfo.fromJson(Map<String, dynamic> json) {
    return StudentClinicInfo(
      id: json['_id'] ?? '',
      fullName: json['fullName'] ?? '',
      medicalNotes: json['medicalNotes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'medicalNotes': medicalNotes,
    };
  }
}

class ClinicRecordsResponse {
  final bool success;
  final String message;
  final StudentClinicInfo? student;
  final List<ClinicRecord> clinicRecords;

  ClinicRecordsResponse({
    required this.success,
    required this.message,
    this.student,
    required this.clinicRecords,
  });

  factory ClinicRecordsResponse.fromJson(Map<String, dynamic> json) {
    return ClinicRecordsResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? '',
      student: json['student'] != null
          ? StudentClinicInfo.fromJson(json['student'])
          : null,
      clinicRecords: (json['clinicRecords'] as List<dynamic>?)
              ?.map((record) => ClinicRecord.fromJson(record))
              .toList() ??
          [],
    );
  }
}

class ClinicRecordsService {
  static Future<ClinicRecordsResponse> getStudentClinicRecords(
      String schoolId, String studentId) async {
    try {
      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw ClinicRecordsException('No authentication token found');
      }

      final url = ApiConstants.getStudentClinicRecordsEndpoint
          .replaceAll('[id]', schoolId)
          .replaceAll('[studentId]', studentId);

      print('🏥 [CLINIC] Getting clinic records for student: $studentId');
      print('🏥 [CLINIC] URL: ${ApiConstants.baseUrl}$url');

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}$url'),
        headers: ApiConstants.getAuthHeaders(token),
      );

      print('🏥 [CLINIC] Response status: ${response.statusCode}');
      print('🏥 [CLINIC] Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          return ClinicRecordsResponse.fromJson(jsonData);
        } catch (e) {
          print('🏥 [CLINIC] Error parsing JSON: $e');
          throw ClinicRecordsException(
              'Invalid JSON response: ${response.body}');
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          throw ClinicRecordsException(
              'Failed to get clinic records: ${errorData['message'] ?? 'Unknown error'}');
        } catch (e) {
          throw ClinicRecordsException(
              'Failed to get clinic records. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('🏥 [CLINIC] Error getting clinic records: $e');
      if (e is ClinicRecordsException) {
        rethrow;
      }
      throw ClinicRecordsException('Network error: ${e.toString()}');
    }
  }
}

class ClinicRecordsException implements Exception {
  final String message;

  ClinicRecordsException(this.message);

  @override
  String toString() => 'ClinicRecordsException: $message';
}

