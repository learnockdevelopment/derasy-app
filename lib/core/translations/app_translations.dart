import 'package:get/get.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': _enUs,
        'ar_SA': _arSa,
      };

  static Map<String, String> _enUs = {};
  static Map<String, String> _arSa = {};

  static Future<void> loadTranslations() async {
    // Load English translations
    String enJson =
        await rootBundle.loadString('assets/translations/en-US.json');
    Map<String, dynamic> enData = json.decode(enJson) as Map<String, dynamic>;
    _enUs = enData.cast<String, String>();

    // Load Arabic translations
    String arJson =
        await rootBundle.loadString('assets/translations/ar-SA.json');
    Map<String, dynamic> arData = json.decode(arJson) as Map<String, dynamic>;
    _arSa = arData.cast<String, String>();
  }
}
