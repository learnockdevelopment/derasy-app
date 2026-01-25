import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../services/user_storage_service.dart';

class Guardian {
  final String? id;
  final String name;
  final String phone;
  final String email;
  final String relation;
  final String nationalId;
  final String nationality;

  Guardian({
    this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.relation,
    required this.nationalId,
    required this.nationality,
  });

  factory Guardian.fromJson(Map<String, dynamic> json) {
    return Guardian(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      relation: json['relation'] ?? '',
      nationalId: json['nationalId'] ?? '',
      nationality: json['nationality'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'relation': relation,
      'nationalId': nationalId,
      'nationality': nationality,
    };
  }
}

class GuardiansResponse {
  final bool success;
  final String message;
  final List<Guardian>? addedOrUpdatedGuardians;
  final Map<String, dynamic>? student;

  GuardiansResponse({
    required this.success,
    required this.message,
    this.addedOrUpdatedGuardians,
    this.student,
  });

  factory GuardiansResponse.fromJson(Map<String, dynamic> json) {
    return GuardiansResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? '',
      addedOrUpdatedGuardians:
          (json['addedOrUpdatedGuardians'] as List<dynamic>?)
              ?.map((guardian) => Guardian.fromJson(guardian))
              .toList(),
      student: json['student'],
    );
  }
}

class GuardiansException implements Exception {
  final String message;
  final dynamic error;

  GuardiansException(this.message, {this.error});

  @override
  String toString() => 'GuardiansException: $message';
}

class GuardiansService {
  static const String _baseUrl = ApiConstants.baseUrl;

  /// Update student guardians
  static Future<GuardiansResponse> updateStudentGuardians(
    String schoolId,
    String studentId,
    List<Guardian> guardians,
  ) async {
    try {
      print('👥 [GUARDIANS] Updating guardians for student: $studentId');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw GuardiansException('No authentication token found');
      }

      final url = _baseUrl +
          ApiConstants.updateStudentGuardiansEndpoint
              .replaceFirst('[id]', schoolId)
              .replaceFirst('[studentId]', studentId);
      final headers = ApiConstants.getAuthHeaders(token);

      final body = {
        'guardians': guardians.map((guardian) => guardian.toJson()).toList(),
      };

      print('👥 [GUARDIANS] URL: $url');
      print('👥 [GUARDIANS] Headers: $headers');
      print('👥 [GUARDIANS] Body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      print('👥 [GUARDIANS] Response status: ${response.statusCode}');
      print('👥 [GUARDIANS] Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          return GuardiansResponse.fromJson(responseData);
        } catch (e) {
          print(
              '👥 [GUARDIANS] Response is not JSON format, treating as success');
          return GuardiansResponse(
            success: true,
            message: 'Guardians updated successfully',
          );
        }
      } else if (response.statusCode == 400) {
        try {
          final errorData = jsonDecode(response.body);
          throw GuardiansException(errorData['message'] ?? 'Invalid input');
        } catch (e) {
          throw GuardiansException('Invalid input: ${response.body}');
        }
      } else if (response.statusCode == 403) {
        try {
          final errorData = jsonDecode(response.body);
          throw GuardiansException('Unauthorized: ${errorData['message']}');
        } catch (e) {
          throw GuardiansException('Unauthorized: ${response.body}');
        }
      } else if (response.statusCode == 404) {
        try {
          final errorData = jsonDecode(response.body);
          throw GuardiansException(
              'Student not found: ${errorData['message']}');
        } catch (e) {
          throw GuardiansException('Student not found: ${response.body}');
        }
      } else {
        throw GuardiansException(
            'Failed to update guardians. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('👥 [GUARDIANS] Error updating guardians: $e');
      if (e is GuardiansException) {
        rethrow;
      } else {
        throw GuardiansException('Network error: ${e.toString()}');
      }
    }
  }
}

