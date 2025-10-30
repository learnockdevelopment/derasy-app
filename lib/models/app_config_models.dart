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
    // logo can be a map with light/dark, or a map with url, or a string URL
    final dynamic rawLogo = json['logo'];
    LogoPaths logo;
    if (rawLogo is Map<String, dynamic>) {
      if ((rawLogo['light'] is String) || (rawLogo['dark'] is String)) {
        logo = LogoPaths.fromJson(rawLogo);
      } else if (rawLogo['url'] is String && (rawLogo['url'] as String).isNotEmpty) {
        final url = rawLogo['url'] as String;
        logo = LogoPaths(light: url, dark: url);
      } else {
        logo = LogoPaths.empty();
      }
    } else if (rawLogo is String && rawLogo.isNotEmpty) {
      logo = LogoPaths(light: rawLogo, dark: rawLogo);
    } else {
      logo = LogoPaths.empty();
    }

    // colors must be a map
    final dynamic rawColors = json['colors'];
    final parsedColors = (rawColors is Map<String, dynamic>)
        ? AppColors.fromJson(rawColors)
        : AppColors.empty();

    return Branding(
      logo: logo,
      colors: parsedColors,
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
  final String background;
  final String surface;
  final String text;
  final String textSecondary;
  final String error;
  final String warning;
  final String success;
  final String info;

  AppColors({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.text,
    required this.textSecondary,
    required this.error,
    required this.warning,
    required this.success,
    required this.info,
  });

  factory AppColors.fromJson(Map<String, dynamic> json) {
    return AppColors(
      primary: json['primary'] as String? ?? '#3b82f6',
      secondary: json['secondary'] as String? ?? '#10B981',
      accent: json['accent'] as String? ?? '#F59E0B',
      background: json['background'] as String? ?? '#FFFFFF',
      surface: json['surface'] as String? ?? '#F8FAFC',
      text: json['text'] as String? ?? '#1F2937',
      textSecondary: json['textSecondary'] as String? ?? '#6B7280',
      error: json['error'] as String? ?? '#EF4444',
      warning: json['warning'] as String? ?? '#F59E0B',
      success: json['success'] as String? ?? '#10B981',
      info: json['info'] as String? ?? '#3B82F6',
    );
  }

  factory AppColors.empty() {
    return AppColors(
      primary: '#3b82f6',
      secondary: '#10B981',
      accent: '#F59E0B',
      background: '#FFFFFF',
      surface: '#F8FAFC',
      text: '#1F2937',
      textSecondary: '#6B7280',
      error: '#EF4444',
      warning: '#F59E0B',
      success: '#10B981',
      info: '#3B82F6',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primary': primary,
      'secondary': secondary,
      'accent': accent,
      'background': background,
      'surface': surface,
      'text': text,
      'textSecondary': textSecondary,
      'error': error,
      'warning': warning,
      'success': success,
      'info': info,
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
  final AppMobileMinVersion minVersion;
  final AppForceUpdate forceUpdate;
  final StoreUrls storeUrls;

  MobileConfig({
    required this.minVersion,
    required this.forceUpdate,
    required this.storeUrls,
  });

  factory MobileConfig.fromJson(Map<String, dynamic> json) {
    final dynamic minV = json['minVersion'];
    final dynamic forceU = json['forceUpdate'];
    return MobileConfig(
      minVersion: (minV is Map<String, dynamic>)
          ? AppMobileMinVersion.fromJson(minV)
          : AppMobileMinVersion.empty(),
      forceUpdate: (forceU is Map<String, dynamic>)
          ? AppForceUpdate.fromJson(forceU)
          : AppForceUpdate.empty(),
      storeUrls: json['storeUrls'] != null && json['storeUrls'] is Map<String, dynamic>
          ? StoreUrls.fromJson(json['storeUrls'] as Map<String, dynamic>)
          : StoreUrls.empty(),
    );
  }

  factory MobileConfig.empty() {
    return MobileConfig(
      minVersion: AppMobileMinVersion.empty(),
      forceUpdate: AppForceUpdate.empty(),
      storeUrls: StoreUrls.empty(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minVersion': minVersion.toJson(),
      'forceUpdate': forceUpdate.toJson(),
      'storeUrls': storeUrls.toJson(),
    };
  }
}

class AppMobileMinVersion {
  final String android;
  final String ios;

  AppMobileMinVersion({
    required this.android,
    required this.ios,
  });

  factory AppMobileMinVersion.fromJson(Map<String, dynamic> json) {
    return AppMobileMinVersion(
      android: json['android'] as String? ?? '1.0.0',
      ios: json['ios'] as String? ?? '1.0.0',
    );
  }

  factory AppMobileMinVersion.empty() {
    return AppMobileMinVersion(android: '1.0.0', ios: '1.0.0');
  }

  Map<String, dynamic> toJson() {
    return {
      'android': android,
      'ios': ios,
    };
  }
}

class AppForceUpdate {
  final bool android;
  final bool ios;

  AppForceUpdate({
    required this.android,
    required this.ios,
  });

  factory AppForceUpdate.fromJson(Map<String, dynamic> json) {
    return AppForceUpdate(
      android: json['android'] as bool? ?? false,
      ios: json['ios'] as bool? ?? false,
    );
  }

  factory AppForceUpdate.empty() {
    return AppForceUpdate(android: false, ios: false);
  }

  Map<String, dynamic> toJson() {
    return {
      'android': android,
      'ios': ios,
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

