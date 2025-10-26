class AppConfigModels {
  /// App Configuration Response Model
  static parseAppConfig(Map<String, dynamic> json) {
    return AppConfigResponse(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null
          ? AppConfigData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AppConfigResponse {
  final bool success;
  final AppConfigData? data;

  AppConfigResponse({
    required this.success,
    this.data,
  });

  factory AppConfigResponse.fromJson(Map<String, dynamic> json) {
    return AppConfigResponse(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null
          ? AppConfigData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data?.toJson(),
    };
  }
}

class AppConfigData {
  final String appName;
  final String appVersion;
  final Branding branding;
  final Features features;
  final MobileConfig mobile;
  final SocialLinks social;
  final LocalizationConfig localization;
  final MaintenanceConfig maintenance;

  AppConfigData({
    required this.appName,
    required this.appVersion,
    required this.branding,
    required this.features,
    required this.mobile,
    required this.social,
    required this.localization,
    required this.maintenance,
  });

  factory AppConfigData.fromJson(Map<String, dynamic> json) {
    return AppConfigData(
      appName: json['appName'] as String? ?? 'Derasy',
      appVersion: json['appVersion'] as String? ?? '1.0.0',
      branding: json['branding'] != null
          ? Branding.fromJson(json['branding'] as Map<String, dynamic>)
          : Branding.empty(),
      features: json['features'] != null
          ? Features.fromJson(json['features'] as Map<String, dynamic>)
          : Features.empty(),
      mobile: json['mobile'] != null
          ? MobileConfig.fromJson(json['mobile'] as Map<String, dynamic>)
          : MobileConfig.empty(),
      social: json['social'] != null
          ? SocialLinks.fromJson(json['social'] as Map<String, dynamic>)
          : SocialLinks.empty(),
      localization: json['localization'] != null
          ? LocalizationConfig.fromJson(
              json['localization'] as Map<String, dynamic>)
          : LocalizationConfig.empty(),
      maintenance: json['maintenance'] != null
          ? MaintenanceConfig.fromJson(
              json['maintenance'] as Map<String, dynamic>)
          : MaintenanceConfig.empty(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'appVersion': appVersion,
      'branding': branding.toJson(),
      'features': features.toJson(),
      'mobile': mobile.toJson(),
      'social': social.toJson(),
      'localization': localization.toJson(),
      'maintenance': maintenance.toJson(),
    };
  }
}

class Branding {
  final LogoPaths logo;
  final AppColors colors;

  Branding({
    required this.logo,
    required this.colors,
  });

  factory Branding.fromJson(Map<String, dynamic> json) {
    return Branding(
      logo: json['logo'] != null && json['logo'] is Map && (json['logo'] as Map).isNotEmpty
          ? LogoPaths.fromJson(json['logo'] as Map<String, dynamic>)
          : LogoPaths.empty(),
      colors: json['colors'] != null && json['colors'] is Map && (json['colors'] as Map).isNotEmpty
          ? AppColors.fromJson(json['colors'] as Map<String, dynamic>)
          : AppColors.empty(),
    );
  }

  factory Branding.empty() {
    return Branding(
      logo: LogoPaths.empty(),
      colors: AppColors.empty(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'logo': logo.toJson(),
      'colors': colors.toJson(),
    };
  }
}

class LogoPaths {
  final String light;
  final String dark;

  LogoPaths({
    required this.light,
    required this.dark,
  });

  factory LogoPaths.fromJson(Map<String, dynamic> json) {
    return LogoPaths(
      light: json['light'] as String? ?? '',
      dark: json['dark'] as String? ?? '',
    );
  }

  factory LogoPaths.empty() {
    return LogoPaths(
      light: 'assets/png/logo.png',
      dark: 'assets/png/white_logo.png',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'light': light,
      'dark': dark,
    };
  }
}

class AppColors {
  final String primary;
  final String secondary;
  final String accent;

  AppColors({
    required this.primary,
    required this.secondary,
    required this.accent,
  });

  factory AppColors.fromJson(Map<String, dynamic> json) {
    return AppColors(
      primary: json['primary'] as String? ?? '#3b82f6',
      secondary: json['secondary'] as String? ?? '#64748b',
      accent: json['accent'] as String? ?? '#f59e0b',
    );
  }

  factory AppColors.empty() {
    return AppColors(
      primary: '#3b82f6',
      secondary: '#64748b',
      accent: '#f59e0b',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primary': primary,
      'secondary': secondary,
      'accent': accent,
    };
  }
}

class Features {
  final bool enableNotifications;
  final bool enableDarkMode;
  final bool enableRTL;
  final bool enableMultiLanguage;

  Features({
    required this.enableNotifications,
    required this.enableDarkMode,
    required this.enableRTL,
    required this.enableMultiLanguage,
  });

  factory Features.fromJson(Map<String, dynamic> json) {
    return Features(
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      enableDarkMode: json['enableDarkMode'] as bool? ?? true,
      enableRTL: json['enableRTL'] as bool? ?? true,
      enableMultiLanguage: json['enableMultiLanguage'] as bool? ?? true,
    );
  }

  factory Features.empty() {
    return Features(
      enableNotifications: true,
      enableDarkMode: true,
      enableRTL: true,
      enableMultiLanguage: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableNotifications': enableNotifications,
      'enableDarkMode': enableDarkMode,
      'enableRTL': enableRTL,
      'enableMultiLanguage': enableMultiLanguage,
    };
  }
}

class MobileConfig {
  final String minVersion;
  final bool forceUpdate;
  final StoreUrls storeUrls;

  MobileConfig({
    required this.minVersion,
    required this.forceUpdate,
    required this.storeUrls,
  });

  factory MobileConfig.fromJson(Map<String, dynamic> json) {
    return MobileConfig(
      minVersion: json['minVersion'] as String? ?? '1.0.0',
      forceUpdate: json['forceUpdate'] as bool? ?? false,
      storeUrls: json['storeUrls'] != null
          ? StoreUrls.fromJson(json['storeUrls'] as Map<String, dynamic>)
          : StoreUrls.empty(),
    );
  }

  factory MobileConfig.empty() {
    return MobileConfig(
      minVersion: '1.0.0',
      forceUpdate: false,
      storeUrls: StoreUrls.empty(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minVersion': minVersion,
      'forceUpdate': forceUpdate,
      'storeUrls': storeUrls.toJson(),
    };
  }
}

class StoreUrls {
  final String ios;
  final String android;

  StoreUrls({
    required this.ios,
    required this.android,
  });

  factory StoreUrls.fromJson(Map<String, dynamic> json) {
    return StoreUrls(
      ios: json['ios'] as String? ?? '',
      android: json['android'] as String? ?? '',
    );
  }

  factory StoreUrls.empty() {
    return StoreUrls(
      ios: '',
      android: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ios': ios,
      'android': android,
    };
  }
}

class SocialLinks {
  final String facebook;
  final String twitter;
  final String instagram;
  final String linkedin;

  SocialLinks({
    required this.facebook,
    required this.twitter,
    required this.instagram,
    required this.linkedin,
  });

  factory SocialLinks.fromJson(Map<String, dynamic> json) {
    return SocialLinks(
      facebook: json['facebook'] as String? ?? '',
      twitter: json['twitter'] as String? ?? '',
      instagram: json['instagram'] as String? ?? '',
      linkedin: json['linkedin'] as String? ?? '',
    );
  }

  factory SocialLinks.empty() {
    return SocialLinks(
      facebook: '',
      twitter: '',
      instagram: '',
      linkedin: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'facebook': facebook,
      'twitter': twitter,
      'instagram': instagram,
      'linkedin': linkedin,
    };
  }
}

class LocalizationConfig {
  final String defaultLanguage;
  final List<String> supportedLanguages;
  final List<String> rtlLanguages;

  LocalizationConfig({
    required this.defaultLanguage,
    required this.supportedLanguages,
    required this.rtlLanguages,
  });

  factory LocalizationConfig.fromJson(Map<String, dynamic> json) {
    return LocalizationConfig(
      defaultLanguage: json['defaultLanguage'] as String? ?? 'en',
      supportedLanguages: (json['supportedLanguages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['en', 'ar'],
      rtlLanguages:
          (json['rtlLanguages'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              ['ar'],
    );
  }

  factory LocalizationConfig.empty() {
    return LocalizationConfig(
      defaultLanguage: 'en',
      supportedLanguages: ['en', 'ar'],
      rtlLanguages: ['ar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultLanguage': defaultLanguage,
      'supportedLanguages': supportedLanguages,
      'rtlLanguages': rtlLanguages,
    };
  }
}

class MaintenanceConfig {
  final bool enabled;
  final String message;

  MaintenanceConfig({
    required this.enabled,
    required this.message,
  });

  factory MaintenanceConfig.fromJson(Map<String, dynamic> json) {
    return MaintenanceConfig(
      enabled: json['enabled'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }

  factory MaintenanceConfig.empty() {
    return MaintenanceConfig(
      enabled: false,
      message: 'System is under maintenance. Please try again later.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'message': message,
    };
  }
}

