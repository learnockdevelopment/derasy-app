import 'package:flutter/material.dart';
import '../../core/controllers/app_config_controller.dart';

class AppColors {

  // Primary Color Variants
  static const Color blue1 = Color(0xFF0ea5e9);
  static const Color blue2 = Color(0xFF00e1b5);

  // Selection Colors
  static const Color selectedBlue = Color(0xFF7AC1FF);

  // Secondary Colors (dynamic from API)
  static Color get secondary {
    try {
      return AppConfigController.to.secondaryColorAsColor;
    } catch (_) {
      return const Color(0xFF1E88E5);
    }
  }
  static Color get secondaryLight => secondary.withOpacity(0.8);
  static Color get secondaryDark => secondary.withOpacity(0.9);

  // Accent Colors (dynamic from API)
  static Color get accent {
    try {
      return AppConfigController.to.accentColorAsColor;
    } catch (_) {
      return const Color(0xFF64B5F6);
    }
  }
  static Color get accentLight => accent.withOpacity(0.8);
  static Color get accentDark => accent.withOpacity(0.9);

  // Basic Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  // Grey Palette
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // Red Palette
  static const Color red50 = Color(0xFFFFEBEE);
  static const Color red100 = Color(0xFFFFCDD2);
  static const Color red200 = Color(0xFFEF9A9A);
  static const Color red300 = Color(0xFFE57373);
  static const Color red400 = Color(0xFFEF5350);
  static const Color red500 = Color(0xFFF44336);
  static const Color red600 = Color(0xFFE53935);
  static const Color red700 = Color(0xFFD32F2F);
  static const Color red800 = Color(0xFFC62828);
  static const Color red900 = Color(0xFFB71C1C);

  // Blue Palette
  static const Color blue50 = Color(0xFFE3F2FD);
  static const Color blue100 = Color(0xFFBBDEFB);
  static const Color blue200 = Color(0xFF90CAF9);
  static const Color blue250 = Color(0xFF7AC1FF);
  static const Color blue300 = Color(0xFF64B5F6);
  static const Color blue400 = Color(0xFF42A5F5);
  static const Color blue500 = Color(0xFF2196F3);
  static const Color blue600 = Color(0xFF1E88E5);
  static const Color blue700 = Color(0xFF1976D2);
  static const Color blue800 = Color(0xFF1565C0);
  static const Color blue900 = Color(0xFF0D47A1);

  // Green Palette
  static const Color green50 = Color(0xFFE8F5E8);
  static const Color green100 = Color(0xFFC8E6C9);
  static const Color green200 = Color(0xFFA5D6A7);
  static const Color green300 = Color(0xFF81C784);
  static const Color green400 = Color(0xFF66BB6A);
  static const Color green500 = Color(0xFF4CAF50);
  static const Color green600 = Color(0xFF43A047);
  static const Color green700 = Color(0xFF388E3C);
  static const Color green800 = Color(0xFF2E7D32);
  static const Color green900 = Color(0xFF1B5E20);

  // Orange Palette
  static const Color orange50 = Color(0xFFFFF3E0);
  static const Color orange100 = Color(0xFFFFE0B2);
  static const Color orange200 = Color(0xFFFFCC80);
  static const Color orange300 = Color(0xFFFFB74D);
  static const Color orange400 = Color(0xFFFFA726);
  static const Color orange500 = Color(0xFFFF9800);
  static const Color orange600 = Color(0xFFFB8C00);
  static const Color orange700 = Color(0xFFF57C00);
  static const Color orange800 = Color(0xFFEF6C00);
  static const Color orange900 = Color(0xFFE65100);

  // Purple Palette
  static const Color purple50 = Color(0xFFF3E5F5);
  static const Color purple100 = Color(0xFFE1BEE7);
  static const Color purple200 = Color(0xFFCE93D8);
  static const Color purple300 = Color(0xFFBA68C8);
  static const Color purple400 = Color(0xFFAB47BC);
  static const Color purple500 = Color(0xFF9C27B0);
  static const Color purple600 = Color(0xFF8E24AA);
  static const Color purple700 = Color(0xFF7B1FA2);
  static const Color purple800 = Color(0xFF6A1B9A);
  static const Color purple900 = Color(0xFF4A148C);

  // Yellow Palette
  static const Color yellow50 = Color(0xFFFFFDE7);
  static const Color yellow100 = Color(0xFFFFF9C4);
  static const Color yellow200 = Color(0xFFFFF59D);
  static const Color yellow300 = Color(0xFFFFF176);
  static const Color yellow400 = Color(0xFFFFEE58);
  static const Color yellow500 = Color(0xFFFFEB3B);
  static const Color yellow600 = Color(0xFFFDD835);
  static const Color yellow700 = Color(0xFFFBC02D);
  static const Color yellow800 = Color(0xFFF9A825);
  static const Color yellow900 = Color(0xFFF57F17);

  // Teal Palette
  static const Color teal50 = Color(0xFFE0F2F1);
  static const Color teal100 = Color(0xFFB2DFDB);
  static const Color teal200 = Color(0xFF80CBC4);
  static const Color teal300 = Color(0xFF4DB6AC);
  static const Color teal400 = Color(0xFF26A69A);
  static const Color teal500 = Color(0xFF009688);
  static const Color teal600 = Color(0xFF00897B);
  static const Color teal700 = Color(0xFF00796B);
  static const Color teal800 = Color(0xFF00695C);
  static const Color teal900 = Color(0xFF004D40);

  // Pink Palette
  static const Color pink50 = Color(0xFFFCE4EC);
  static const Color pink100 = Color(0xFFF8BBD9);
  static const Color pink200 = Color(0xFFF48FB1);
  static const Color pink300 = Color(0xFFF06292);
  static const Color pink400 = Color(0xFFEC407A);
  static const Color pink500 = Color(0xFFE91E63);
  static const Color pink600 = Color(0xFFD81B60);
  static const Color pink700 = Color(0xFFC2185B);
  static const Color pink800 = Color(0xFFAD1457);
  static const Color pink900 = Color(0xFF880E4F);

  // Indigo Palette
  static const Color indigo50 = Color(0xFFE8EAF6);
  static const Color indigo100 = Color(0xFFC5CAE9);
  static const Color indigo200 = Color(0xFF9FA8DA);
  static const Color indigo300 = Color(0xFF7986CB);
  static const Color indigo400 = Color(0xFF5C6BC0);
  static const Color indigo500 = Color(0xFF3F51B5);
  static const Color indigo600 = Color(0xFF3949AB);
  static const Color indigo700 = Color(0xFF303F9F);
  static const Color indigo800 = Color(0xFF283593);
  static const Color indigo900 = Color(0xFF1A237E);

  // Cyan Palette
  static const Color cyan50 = Color(0xFFE0F7FA);
  static const Color cyan100 = Color(0xFFB2EBF2);
  static const Color cyan200 = Color(0xFF80DEEA);
  static const Color cyan300 = Color(0xFF4DD0E1);
  static const Color cyan400 = Color(0xFF26C6DA);
  static const Color cyan500 = Color(0xFF00BCD4);
  static const Color cyan600 = Color(0xFF00ACC1);
  static const Color cyan700 = Color(0xFF0097A7);
  static const Color cyan800 = Color(0xFF00838F);
  static const Color cyan900 = Color(0xFF006064);

  // Brown Palette
  static const Color brown50 = Color(0xFFEFEBE9);
  static const Color brown100 = Color(0xFFD7CCC8);
  static const Color brown200 = Color(0xFFBCAAA4);
  static const Color brown300 = Color(0xFFA1887F);
  static const Color brown400 = Color(0xFF8D6E63);
  static const Color brown500 = Color(0xFF795548);
  static const Color brown600 = Color(0xFF6D4C41);
  static const Color brown700 = Color(0xFF5D4037);
  static const Color brown800 = Color(0xFF4E342E);
  static const Color brown900 = Color(0xFF3E2723);

  // Deep Orange Palette
  static const Color deepOrange50 = Color(0xFFFBE9E7);
  static const Color deepOrange100 = Color(0xFFFFCCBC);
  static const Color deepOrange200 = Color(0xFFFFAB91);
  static const Color deepOrange300 = Color(0xFFFF8A65);
  static const Color deepOrange400 = Color(0xFFFF7043);
  static const Color deepOrange500 = Color(0xFFFF5722);
  static const Color deepOrange600 = Color(0xFFF4511E);
  static const Color deepOrange700 = Color(0xFFE64A19);
  static const Color deepOrange800 = Color(0xFFD84315);
  static const Color deepOrange900 = Color(0xFFBF360C);

  // Light Blue Palette
  static const Color lightBlue50 = Color(0xFFE1F5FE);
  static const Color lightBlue100 = Color(0xFFB3E5FC);
  static const Color lightBlue200 = Color(0xFF81D4FA);
  static const Color lightBlue300 = Color(0xFF4FC3F7);
  static const Color lightBlue400 = Color(0xFF29B6F6);
  static const Color lightBlue500 = Color(0xFF03A9F4);
  static const Color lightBlue600 = Color(0xFF039BE5);
  static const Color lightBlue700 = Color(0xFF0288D1);
  static const Color lightBlue800 = Color(0xFF0277BD);
  static const Color lightBlue900 = Color(0xFF01579B);

  // Lime Palette
  static const Color lime50 = Color(0xFFF9FBE7);
  static const Color lime100 = Color(0xFFF0F4C3);
  static const Color lime200 = Color(0xFFE6EE9C);
  static const Color lime300 = Color(0xFFDCE775);
  static const Color lime400 = Color(0xFFD4E157);
  static const Color lime500 = Color(0xFFCDDC39);
  static const Color lime600 = Color(0xFFC0CA33);
  static const Color lime700 = Color(0xFFAFB42B);
  static const Color lime800 = Color(0xFF9E9D24);
  static const Color lime900 = Color(0xFF827717);

  // Amber Palette
  static const Color amber50 = Color(0xFFFFF8E1);
  static const Color amber100 = Color(0xFFFFECB3);
  static const Color amber200 = Color(0xFFFFE082);
  static const Color amber300 = Color(0xFFFFD54F);
  static const Color amber400 = Color(0xFFFFCA28);
  static const Color amber500 = Color(0xFFFFC107);
  static const Color amber600 = Color(0xFFFFB300);
  static const Color amber700 = Color(0xFFFFA000);
  static const Color amber800 = Color(0xFFFF8F00);
  static const Color amber900 = Color(0xFFFF6F00);

  // Light Green Palette
  static const Color lightGreen50 = Color(0xFFF1F8E9);
  static const Color lightGreen100 = Color(0xFFDCEDC8);
  static const Color lightGreen200 = Color(0xFFC5E1A5);
  static const Color lightGreen300 = Color(0xFFAED581);
  static const Color lightGreen400 = Color(0xFF9CCC65);
  static const Color lightGreen500 = Color(0xFF8BC34A);
  static const Color lightGreen600 = Color(0xFF7CB342);
  static const Color lightGreen700 = Color(0xFF689F38);
  static const Color lightGreen800 = Color(0xFF558B2F);
  static const Color lightGreen900 = Color(0xFF33691E);

  // Deep Purple Palette
  static const Color deepPurple50 = Color(0xFFEDE7F6);
  static const Color deepPurple100 = Color(0xFFD1C4E9);
  static const Color deepPurple200 = Color(0xFFB39DDB);
  static const Color deepPurple300 = Color(0xFF9575CD);
  static const Color deepPurple400 = Color(0xFF7E57C2);
  static const Color deepPurple500 = Color(0xFF673AB7);
  static const Color deepPurple600 = Color(0xFF5E35B1);
  static const Color deepPurple700 = Color(0xFF512DA8);
  static const Color deepPurple800 = Color(0xFF4527A0);
  static const Color deepPurple900 = Color(0xFF311B92);

  // Common UI Colors
  static Color get success {
    try {
      return AppConfigController.to.successColorAsColor;
    } catch (_) {
      return green500;
    }
  }
  static Color get warning {
    try {
      return AppConfigController.to.warningColorAsColor;
    } catch (_) {
      return orange500;
    }
  }
  static Color get error {
    try {
      return AppConfigController.to.errorColorAsColor;
    } catch (_) {
      return red500;
    }
  }
  static Color get info {
    try {
      return AppConfigController.to.infoColorAsColor;
    } catch (_) {
      return blue500;
    }
  }

  // Background Colors
  static Color get background {
    try {
      return AppConfigController.to.backgroundColorAsColor;
    } catch (_) {
      return const Color(0xFFf6fef8);
    }
  }
  static Color get surface {
    try {
      return AppConfigController.to.surfaceColorAsColor;
    } catch (_) {
      return grey50;
    }
  }
  static const Color cardBackground = white;
  static const Color itemsBackground = grey50;

  // Text Colors
  static Color get textPrimary {
    try {
      return AppConfigController.to.textColorAsColor;
    } catch (_) {
      return grey900;
    }
  }
  static Color get textSecondary {
    try {
      return AppConfigController.to.textSecondaryColorAsColor;
    } catch (_) {
      return grey600;
    }
  }
  static const Color textHint = grey400;
  static const Color textDisabled = grey300;

  // Border Colors
  static const Color border = grey300;
  static const Color borderLight = grey200;
  static const Color borderDark = grey400;

  // Shadow Colors
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowDark = Color(0x33000000);

  // Custom Colors
  static const Color lightPeach = Color(0xFFFFDBB2);
}

