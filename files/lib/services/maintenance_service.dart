import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import 'user_storage_service.dart';

class MaintenanceSettings {
  final bool enabled;
  final String message;
  final String? scheduledStart;
  final String? scheduledEnd;
  final List<String> allowedIPs;

  MaintenanceSettings({
    required this.enabled,
    required this.message,
    this.scheduledStart,
    this.scheduledEnd,
    this.allowedIPs = const [],
  });

  factory MaintenanceSettings.fromJson(Map<String, dynamic> json) {
    return MaintenanceSettings(
      enabled: json['enabled'] ?? false,
      message: json['message'] ?? '',
      scheduledStart: json['scheduledStart'],
      scheduledEnd: json['scheduledEnd'],
      allowedIPs: (json['allowedIPs'] as List<dynamic>?)
          ?.map((ip) => ip.toString())
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'message': message,
      if (scheduledStart != null) 'scheduledStart': scheduledStart,
      if (scheduledEnd != null) 'scheduledEnd': scheduledEnd,
      'allowedIPs': allowedIPs,
    };
  }
}

class MaintenanceResponse {
  final bool success;
  final MaintenanceSettings? data;
  final String? message;
  final int? version;
  final String? updatedAt;

  MaintenanceResponse({
    required this.success,
    this.data,
    this.message,
    this.version,
    this.updatedAt,
  });

  factory MaintenanceResponse.fromJson(Map<String, dynamic> json) {
    return MaintenanceResponse(
      success: json['success'] ?? false,
      data: json['data'] != null ? MaintenanceSettings.fromJson(json['data']) : null,
      message: json['message'],
      version: json['data']?['version'],
      updatedAt: json['data']?['updatedAt'],
    );
  }
}

class MaintenanceException implements Exception {
  final String message;

  MaintenanceException(this.message);

  @override
  String toString() => 'MaintenanceException: $message';
}

class MaintenanceService {
  static const String _baseUrl = ApiConstants.baseUrl;

  /// Get maintenance status
  static Future<MaintenanceResponse> getMaintenanceStatus() async {
    try {
      print('🔧 [MAINTENANCE] Getting maintenance status');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw MaintenanceException('No authentication token found');
      }

      final url = '$_baseUrl/app-settings/maintenance';
      final headers = ApiConstants.getAuthHeaders(token);

      print('🔧 [MAINTENANCE] URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('🔧 [MAINTENANCE] Response status: ${response.statusCode}');
      print('🔧 [MAINTENANCE] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return MaintenanceResponse.fromJson(responseData);
      } else if (response.statusCode == 403) {
        throw MaintenanceException('Unauthorized access');
      } else {
        throw MaintenanceException('Failed to get maintenance status: ${response.statusCode}');
      }
    } catch (e) {
      print('🔧 [MAINTENANCE] Error getting status: $e');
      if (e is MaintenanceException) rethrow;
      throw MaintenanceException('Failed to get maintenance status: $e');
    }
  }

  /// Update maintenance settings
  static Future<MaintenanceResponse> updateMaintenanceSettings(MaintenanceSettings settings) async {
    try {
      print('🔧 [MAINTENANCE] Updating maintenance settings');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw MaintenanceException('No authentication token found');
      }

      final url = '$_baseUrl/app-settings/maintenance';
      final headers = ApiConstants.getAuthHeaders(token);

      print('🔧 [MAINTENANCE] URL: $url');
      print('🔧 [MAINTENANCE] Data: ${settings.toJson()}');

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(settings.toJson()),
      );

      print('🔧 [MAINTENANCE] Response status: ${response.statusCode}');
      print('🔧 [MAINTENANCE] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return MaintenanceResponse.fromJson(responseData);
      } else if (response.statusCode == 403) {
        throw MaintenanceException('Unauthorized: Only admin users can update maintenance settings');
      } else {
        final errorData = jsonDecode(response.body);
        throw MaintenanceException(errorData['message'] ?? 'Failed to update maintenance settings');
      }
    } catch (e) {
      print('🔧 [MAINTENANCE] Error updating settings: $e');
      if (e is MaintenanceException) rethrow;
      throw MaintenanceException('Failed to update maintenance settings: $e');
    }
  }

  /// Toggle maintenance mode
  static Future<MaintenanceResponse> toggleMaintenanceMode(bool enabled, String message) async {
    try {
      print('🔧 [MAINTENANCE] Toggling maintenance mode: $enabled');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw MaintenanceException('No authentication token found');
      }

      final url = '$_baseUrl/app-settings/maintenance';
      final headers = ApiConstants.getAuthHeaders(token);

      final body = {
        'enabled': enabled,
        'message': message,
      };

      print('🔧 [MAINTENANCE] URL: $url');
      print('🔧 [MAINTENANCE] Data: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      print('🔧 [MAINTENANCE] Response status: ${response.statusCode}');
      print('🔧 [MAINTENANCE] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return MaintenanceResponse.fromJson(responseData);
      } else if (response.statusCode == 403) {
        throw MaintenanceException('Unauthorized: Only admin users can toggle maintenance mode');
      } else {
        final errorData = jsonDecode(response.body);
        throw MaintenanceException(errorData['message'] ?? 'Failed to toggle maintenance mode');
      }
    } catch (e) {
      print('🔧 [MAINTENANCE] Error toggling mode: $e');
      if (e is MaintenanceException) rethrow;
      throw MaintenanceException('Failed to toggle maintenance mode: $e');
    }
  }
}


