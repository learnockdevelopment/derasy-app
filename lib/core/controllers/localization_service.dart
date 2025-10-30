import 'dart:convert';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class LocalizationService extends GetxService {
  static LocalizationService get to => Get.find();

  late Map<String, dynamic> _translations;
  String _currentLanguage = 'ar-SA';

  String get currentLanguage => _currentLanguage;

  Future<void> init() async {
    await _loadTranslations();
  }

  Future<void> _loadTranslations() async {
    try {
      final String response = await rootBundle
          .loadString('assets/translations/$_currentLanguage.json');
      _translations = json.decode(response);
      print('🌐 [LOCALIZATION] Loaded translations for $_currentLanguage');
    } catch (e) {
      print('❌ [LOCALIZATION] Error loading translations: $e');
      // Fallback to English if Arabic fails
      if (_currentLanguage == 'ar-SA') {
        _currentLanguage = 'en-US';
        await _loadTranslations();
      }
    }
  }

  String translate(String key, {Map<String, String>? params}) {
    try {
      String translation = _translations[key] ?? key;

      // Replace parameters if provided
      if (params != null) {
        params.forEach((paramKey, value) {
          translation = translation.replaceAll('{$paramKey}', value);
        });
      }

      return translation;
    } catch (e) {
      print('❌ [LOCALIZATION] Error translating key: $key - $e');
      return key;
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    if (_currentLanguage != languageCode) {
      _currentLanguage = languageCode;
      await _loadTranslations();
      Get.updateLocale(
          Locale(languageCode.split('-')[0], languageCode.split('-')[1]));
    }
  }

  bool get isArabic => _currentLanguage == 'ar-SA';
  bool get isEnglish => _currentLanguage == 'en-US';
}

// Extension for easy access
extension LocalizationExtension on String {
  String get tr => LocalizationService.to.translate(this);

  String trParams(Map<String, String> params) =>
      LocalizationService.to.translate(this, params: params);
}
