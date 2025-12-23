import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';

class LanguageController extends GetxController {
  static LanguageController get to => Get.find();

  final _storage = GetStorage();
  final _languageKey = 'language';

  @override
  void onInit() {
    super.onInit();
    _loadLanguage();
  }

  void _loadLanguage() {
    String? savedLanguage = _storage.read(_languageKey);
    if (savedLanguage != null) {
      Get.updateLocale(
          Locale(savedLanguage.split('_')[0], savedLanguage.split('_')[1]));
    }
  }

  void changeLanguage(String languageCode) {
    Get.updateLocale(
        Locale(languageCode.split('_')[0], languageCode.split('_')[1]));
    _storage.write(_languageKey, languageCode);
  }

  String get currentLanguage => Get.locale?.languageCode ?? 'en';

  bool get isEnglish => currentLanguage == 'en';
  bool get isArabic => currentLanguage == 'ar';
}
