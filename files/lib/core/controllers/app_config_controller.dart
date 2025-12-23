import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../models/app_config_models.dart';
import '../../services/app_config_service.dart';

class AppConfigController extends GetxController {
  static AppConfigController get to => Get.find();

  final _storage = GetStorage();
  final _configKey = 'app_config';

  // Observable app configuration
  final _appConfig = Rx<AppConfigData?>(null);
  AppConfigData? get appConfig => _appConfig.value;

  // Observable loading state
  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  // Observable error state
  final _error = RxString('');
  String get error => _error.value;

  @override
  void onInit() {
    super.onInit();
    loadAppConfig();
  }

  /// Load app configuration
  Future<void> loadAppConfig() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      // Try to get cached config
      final cachedConfig = _getCachedConfig();
      if (cachedConfig != null) {
        _appConfig.value = cachedConfig;
        print('🔧 [APP CONFIG] Loaded from cache');
      }

      // Fetch fresh config from API
      print('🔧 [APP CONFIG] Fetching from API...');
      final response = await AppConfigService.getAppConfig();

      if (response.success && response.data != null) {
        _appConfig.value = response.data;
        _cacheConfig(response.data!);
        print('🔧 [APP CONFIG] ✅ Loaded successfully from API');
      } else {
        print('🔧 [APP CONFIG] ❌ Failed to load configuration');
        if (_appConfig.value == null) {
          _error.value = 'Failed to load app configuration';
        }
      }
    } catch (e) {
      print('🔧 [APP CONFIG] ❌ Error: $e');
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get cached app configuration
  AppConfigData? _getCachedConfig() {
    try {
      final configMap = _storage.read(_configKey);
      if (configMap != null) {
        return AppConfigData.fromJson(configMap as Map<String, dynamic>);
      }
    } catch (e) {
      print('🔧 [APP CONFIG] Error loading cached config: $e');
    }
    return null;
  }

  /// Cache app configuration
  void _cacheConfig(AppConfigData config) {
    try {
      _storage.write(_configKey, config.toJson());
      print('🔧 [APP CONFIG] ✅ Configuration cached');
    } catch (e) {
      print('🔧 [APP CONFIG] Error caching config: $e');
    }
  }

  /// Check if app is in maintenance mode
  bool get isMaintenanceMode {
    return AppConfigService.isMaintenanceMode(_appConfig.value);
  }

  /// Get maintenance message
  String get maintenanceMessage {
    return AppConfigService.getMaintenanceMessage(_appConfig.value);
  }

  /// Get app name
  String get appName {
    return _appConfig.value?.appName ?? 'xx';
  }

  /// Get app version
  String get appVersion {
    return _appConfig.value?.appVersion ?? '1.0.0';
  }

  /// Get primary color
  String get primaryColor {
    return _appConfig.value?.branding.colors.primary ?? '#3b82f6';
  }

  /// Get secondary color
  String get secondaryColor {
    return _appConfig.value?.branding.colors.secondary ?? '#64748b';
  }

  /// Get accent color
  String get accentColor {
    return _appConfig.value?.branding.colors.accent ?? '#f59e0b';
  }

  /// Get light logo URL
  String get lightLogoUrl {
    return _appConfig.value?.branding.logo.light ?? 'assets/png/logo.png';
  }

  /// Get dark logo URL
  String get darkLogoUrl {
    return _appConfig.value?.branding.logo.dark ??
        'assets/png/white_logo.png';
  }

  /// Get store URLs
  StoreUrls get storeUrls {
    return _appConfig.value?.mobile.storeUrls ?? StoreUrls.empty();
  }

  /// Get social links
  SocialLinks get socialLinks {
    return _appConfig.value?.social ?? SocialLinks.empty();
  }

  /// Get features
  Features get features {
    return _appConfig.value?.features ?? Features.empty();
  }

  /// Clear cached configuration
  void clearCache() {
    _storage.remove(_configKey);
  }

  /// Convert hex color to Color
  static Color hexToColor(String hexString, {Color fallback = Colors.blue}) {
    try {
      final hex = hexString.replaceAll('#', '');
      return Color(int.parse(hex, radix: 16) + 0xFF000000);
    } catch (e) {
      print('🔧 [APP CONFIG] Error parsing color: $hexString');
      return fallback;
    }
  }

  /// Get primary color as Color
  Color get primaryColorAsColor {
    return hexToColor(primaryColor, fallback: Colors.blue);
  }

  /// Get secondary color as Color
  Color get secondaryColorAsColor {
    return hexToColor(secondaryColor, fallback: Colors.grey);
  }

  /// Get accent color as Color
  Color get accentColorAsColor {
    return hexToColor(accentColor, fallback: Colors.orange);
  }

  // Extended colors from API
  String get backgroundColorHex {
    return _appConfig.value?.branding.colors.background ?? '#FFFFFF';
  }
  String get surfaceColorHex {
    return _appConfig.value?.branding.colors.surface ?? '#F8FAFC';
  }
  String get textColorHex {
    return _appConfig.value?.branding.colors.text ?? '#1F2937';
  }
  String get textSecondaryColorHex {
    return _appConfig.value?.branding.colors.textSecondary ?? '#6B7280';
  }
  String get errorColorHex {
    return _appConfig.value?.branding.colors.error ?? '#EF4444';
  }
  String get warningColorHex {
    return _appConfig.value?.branding.colors.warning ?? '#F59E0B';
  }
  String get successColorHex {
    return _appConfig.value?.branding.colors.success ?? '#10B981';
  }
  String get infoColorHex {
    return _appConfig.value?.branding.colors.info ?? '#3B82F6';
  }

  Color get backgroundColorAsColor => hexToColor(backgroundColorHex, fallback: Colors.white);
  Color get surfaceColorAsColor => hexToColor(surfaceColorHex, fallback: const Color(0xFFF8FAFC));
  Color get textColorAsColor => hexToColor(textColorHex, fallback: const Color(0xFF1F2937));
  Color get textSecondaryColorAsColor => hexToColor(textSecondaryColorHex, fallback: const Color(0xFF6B7280));
  Color get errorColorAsColor => hexToColor(errorColorHex, fallback: Colors.red);
  Color get warningColorAsColor => hexToColor(warningColorHex, fallback: Colors.orange);
  Color get successColorAsColor => hexToColor(successColorHex, fallback: Colors.green);
  Color get infoColorAsColor => hexToColor(infoColorHex, fallback: Colors.blue);
}

