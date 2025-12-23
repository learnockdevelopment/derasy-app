import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../services/user_storage_service.dart';

class PickupPermission {
  final String id;
  final String guardianName;
  final String guardianPhone;
  final String relation;
  final bool isActive;
  final String createdAt;
  final String expiresAt;

  PickupPermission({
    required this.id,
    required this.guardianName,
    required this.guardianPhone,
    required this.relation,
    required this.isActive,
    required this.createdAt,
    required this.expiresAt,
  });

  factory PickupPermission.fromJson(Map<String, dynamic> json) {
    return PickupPermission(
      id: json['_id'] ?? '',
      guardianName: json['guardianName'] ?? '',
      guardianPhone: json['guardianPhone'] ?? '',
      relation: json['relation'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] ?? '',
      expiresAt: json['expiresAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'guardianName': guardianName,
      'guardianPhone': guardianPhone,
      'relation': relation,
      'isActive': isActive,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
    };
  }
}

class PickupPermissionsResponse {
  final bool success;
  final String message;
  final List<PickupPermission> permissions;

  PickupPermissionsResponse({
    required this.success,
    required this.message,
    required this.permissions,
  });

  factory PickupPermissionsResponse.fromJson(Map<String, dynamic> json) {
    return PickupPermissionsResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? '',
      permissions: (json['pickupPermissions'] as List<dynamic>?)
              ?.map((permission) => PickupPermission.fromJson(permission))
              .toList() ??
          [],
    );
  }
}

class PickupPermissionsService {
  static Future<PickupPermissionsResponse> getPickupPermissions(
      String schoolId, String studentId) async {
    try {
      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw PickupPermissionsException('No authentication token found');
      }

      final url = ApiConstants.getPickupPermissionsEndpoint
          .replaceAll('[id]', schoolId)
          .replaceAll('[studentId]', studentId);

      print('🚗 [PICKUP] Getting pickup permissions for student: $studentId');
      print('🚗 [PICKUP] URL: ${ApiConstants.baseUrl}$url');

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}$url'),
        headers: ApiConstants.getAuthHeaders(token),
      );

      print('🚗 [PICKUP] Response status: ${response.statusCode}');
      print('🚗 [PICKUP] Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          return PickupPermissionsResponse.fromJson(jsonData);
        } catch (e) {
          print('🚗 [PICKUP] Error parsing JSON: $e');
          // Handle empty array response
          if (response.body.trim() == '[]') {
            return PickupPermissionsResponse(
              success: true,
              message: 'No pickup permissions found',
              permissions: [],
            );
          }
          throw PickupPermissionsException(
              'Invalid JSON response: ${response.body}');
        }
      } else if (response.statusCode == 405) {
        // Method Not Allowed - feature not available
        return PickupPermissionsResponse(
          success: false,
          message:
              'Pickup permissions retrieval is not available for this school',
          permissions: [],
        );
      } else {
        try {
          final errorData = jsonDecode(response.body);
          throw PickupPermissionsException(
              'Failed to get pickup permissions: ${errorData['message'] ?? 'Unknown error'}');
        } catch (e) {
          throw PickupPermissionsException(
              'Failed to get pickup permissions. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('🚗 [PICKUP] Error getting pickup permissions: $e');
      if (e is PickupPermissionsException) {
        rethrow;
      }
      throw PickupPermissionsException('Network error: ${e.toString()}');
    }
  }

  static Future<PickupPermissionsResponse> addPickupPermission(String schoolId,
      String studentId, Map<String, dynamic> permissionData) async {
    try {
      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw PickupPermissionsException('No authentication token found');
      }

      final url = ApiConstants.addPickupPermissionEndpoint
          .replaceAll('[id]', schoolId)
          .replaceAll('[studentId]', studentId);

      print('🚗 [PICKUP] Adding pickup permission for student: $studentId');
      print('🚗 [PICKUP] URL: ${ApiConstants.baseUrl}$url');
      print('🚗 [PICKUP] Data: $permissionData');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}$url'),
        headers: ApiConstants.getAuthHeaders(token),
        body: jsonEncode(permissionData),
      );

      print('🚗 [PICKUP] Response status: ${response.statusCode}');
      print('🚗 [PICKUP] Response body: ${response.body}');

      if (response.statusCode == 201) {
        try {
          final jsonData = jsonDecode(response.body);
          return PickupPermissionsResponse.fromJson(jsonData);
        } catch (e) {
          print('🚗 [PICKUP] Error parsing JSON: $e');
          throw PickupPermissionsException(
              'Invalid JSON response: ${response.body}');
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          throw PickupPermissionsException(
              'Failed to add pickup permission: ${errorData['message'] ?? 'Unknown error'}');
        } catch (e) {
          throw PickupPermissionsException(
              'Failed to add pickup permission. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('🚗 [PICKUP] Error adding pickup permission: $e');
      if (e is PickupPermissionsException) {
        rethrow;
      }
      throw PickupPermissionsException('Network error: ${e.toString()}');
    }
  }
}

class PickupPermissionsException implements Exception {
  final String message;

  PickupPermissionsException(this.message);

  @override
  String toString() => 'PickupPermissionsException: $message';
}
