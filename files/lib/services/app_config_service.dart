import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/app_config_models.dart';

class AppConfigService {
  static const String _baseUrl = ApiConstants.baseUrl;

  /// Get public app configuration from API
  static Future<AppConfigResponse> getAppConfig() async {
    try {
      print('🔧 [APP CONFIG] Fetching app configuration...');
      print('🔧 [APP CONFIG] URL: $_baseUrl${ApiConstants.appConfigEndpoint}');

      final response = await http.get(
        Uri.parse('$_baseUrl${ApiConstants.appConfigEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('🔧 [APP CONFIG] Response status: ${response.statusCode}');
      print('🔧 [APP CONFIG] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData =
            jsonDecode(response.body) as Map<String, dynamic>;
        print('🔧 [APP CONFIG] ✅ Configuration fetched successfully');
        return AppConfigResponse.fromJson(responseData);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage =
            errorData['message'] as String? ?? 'Failed to load app configuration';
        print('🔧 [APP CONFIG] ❌ Error: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('🔧 [APP CONFIG] ❌ Exception: $e');
      // Return default configuration on error
      return AppConfigResponse(
        success: false,
        data: AppConfigData(
          appName: 'Derasy',
          appVersion: '1.0.0',
          branding: Branding.empty(),
          features: Features.empty(),
          mobile: MobileConfig.empty(),
          social: SocialLinks.empty(),
          localization: LocalizationConfig.empty(),
          maintenance: MaintenanceConfig.empty(),
        ),
      );
    }
  }

  /// Check if app is in maintenance mode
  static bool isMaintenanceMode(AppConfigData? config) {
    return config?.maintenance.enabled ?? false;
  }

  /// Get maintenance message
  static String getMaintenanceMessage(AppConfigData? config) {
    return config?.maintenance.message ??
        'System is under maintenance. Please try again later.';
  }
}

