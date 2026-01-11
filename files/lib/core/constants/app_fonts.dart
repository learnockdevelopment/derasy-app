import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/responsive_utils.dart';

class AppFonts {
  // Font Family - Noto Sans Arabic Only
  static const String Almarai = 'Almarai';

  // Font Weights - Matching Noto Sans Arabic available weights
  static const FontWeight thin = FontWeight.w100;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight black = FontWeight.w900;

  // Font Sizes
  static double get size10 => Responsive.sp(10); 
  static double get size12 => Responsive.sp(12);
  static double get size14 => Responsive.sp(14);
  static double get size16 => Responsive.sp(16);
  static double get size18 => Responsive.sp(18);
  static double get size20 => Responsive.sp(20);
  static double get size22 => Responsive.sp(22);
  static double get size24 => Responsive.sp(24);
  static double get size28 => Responsive.sp(28);
  static double get size32 => Responsive.sp(32);
  static double get size36 => Responsive.sp(36);
  static double get size40 => Responsive.sp(40);
  static double get size48 => Responsive.sp(48);
  static double get size56 => Responsive.sp(56);
  static double get size64 => Responsive.sp(64);
  static double get size72 => Responsive.sp(72);

  // ===== Almarai FONT SYSTEM =====

  // Almarai Thin (100)
  static TextStyle get AlmaraiThin10 =>
      TextStyle(fontFamily: Almarai, fontWeight: thin, fontSize: size10);
  static TextStyle get AlmaraiThin12 =>
      TextStyle(fontFamily: Almarai, fontWeight: thin, fontSize: size12);
  static TextStyle get AlmaraiThin14 =>
      TextStyle(fontFamily: Almarai, fontWeight: thin, fontSize: size14);
  static TextStyle get AlmaraiThin16 =>
      TextStyle(fontFamily: Almarai, fontWeight: thin, fontSize: size16);
  static TextStyle get AlmaraiThin18 =>
      TextStyle(fontFamily: Almarai, fontWeight: thin, fontSize: size18);
  static TextStyle get AlmaraiThin20 =>
      TextStyle(fontFamily: Almarai, fontWeight: thin, fontSize: size20);
  static TextStyle get AlmaraiThin24 =>
      TextStyle(fontFamily: Almarai, fontWeight: thin, fontSize: size24);
  static TextStyle get AlmaraiThin28 =>
      TextStyle(fontFamily: Almarai, fontWeight: thin, fontSize: size28);
  static TextStyle get AlmaraiThin32 =>
      TextStyle(fontFamily: Almarai, fontWeight: thin, fontSize: size32);
  static TextStyle get AlmaraiThin36 =>
      TextStyle(fontFamily: Almarai, fontWeight: thin, fontSize: size36);
  static TextStyle get AlmaraiThin40 =>
      TextStyle(fontFamily: Almarai, fontWeight: thin, fontSize: size40);
  static TextStyle get AlmaraiThin48 =>
      TextStyle(fontFamily: Almarai, fontWeight: thin, fontSize: size48);
  static TextStyle get AlmaraiThin56 =>
      TextStyle(fontFamily: Almarai, fontWeight: thin, fontSize: size56);
  static TextStyle get AlmaraiThin64 =>
      TextStyle(fontFamily: Almarai, fontWeight: thin, fontSize: size64);
  static TextStyle get AlmaraiThin72 =>
      TextStyle(fontFamily: Almarai, fontWeight: thin, fontSize: size72);

  // Almarai Light (300)
  static TextStyle get AlmaraiLight10 =>
      TextStyle(fontFamily: Almarai, fontWeight: light, fontSize: size10);
  static TextStyle get AlmaraiLight12 =>
      TextStyle(fontFamily: Almarai, fontWeight: light, fontSize: size12);
  static TextStyle get AlmaraiLight14 =>
      TextStyle(fontFamily: Almarai, fontWeight: light, fontSize: size14);
  static TextStyle get AlmaraiLight16 =>
      TextStyle(fontFamily: Almarai, fontWeight: light, fontSize: size16);
  static TextStyle get AlmaraiLight18 =>
      TextStyle(fontFamily: Almarai, fontWeight: light, fontSize: size18);
  static TextStyle get AlmaraiLight20 =>
      TextStyle(fontFamily: Almarai, fontWeight: light, fontSize: size20);
  static TextStyle get AlmaraiLight24 =>
      TextStyle(fontFamily: Almarai, fontWeight: light, fontSize: size24);
  static TextStyle get AlmaraiLight28 =>
      TextStyle(fontFamily: Almarai, fontWeight: light, fontSize: size28);
  static TextStyle get AlmaraiLight32 =>
      TextStyle(fontFamily: Almarai, fontWeight: light, fontSize: size32);
  static TextStyle get AlmaraiLight36 =>
      TextStyle(fontFamily: Almarai, fontWeight: light, fontSize: size36);
  static TextStyle get AlmaraiLight40 =>
      TextStyle(fontFamily: Almarai, fontWeight: light, fontSize: size40);
  static TextStyle get AlmaraiLight48 =>
      TextStyle(fontFamily: Almarai, fontWeight: light, fontSize: size48);
  static TextStyle get AlmaraiLight56 =>
      TextStyle(fontFamily: Almarai, fontWeight: light, fontSize: size56);
  static TextStyle get AlmaraiLight64 =>
      TextStyle(fontFamily: Almarai, fontWeight: light, fontSize: size64);
  static TextStyle get AlmaraiLight72 =>
      TextStyle(fontFamily: Almarai, fontWeight: light, fontSize: size72);

  // Almarai Regular (400)
  static TextStyle get AlmaraiRegular10 =>
      TextStyle(fontFamily: Almarai, fontWeight: regular, fontSize: size10);
  static TextStyle get AlmaraiRegular12 =>
      TextStyle(fontFamily: Almarai, fontWeight: regular, fontSize: size12);
  static TextStyle get AlmaraiRegular14 =>
      TextStyle(fontFamily: Almarai, fontWeight: regular, fontSize: size14);
  static TextStyle get AlmaraiRegular16 =>
      TextStyle(fontFamily: Almarai, fontWeight: regular, fontSize: size16);
  static TextStyle get AlmaraiRegular18 =>
      TextStyle(fontFamily: Almarai, fontWeight: regular, fontSize: size18);
  static TextStyle get AlmaraiRegular20 =>
      TextStyle(fontFamily: Almarai, fontWeight: regular, fontSize: size20);
  static TextStyle get AlmaraiRegular24 =>
      TextStyle(fontFamily: Almarai, fontWeight: regular, fontSize: size24);
  static TextStyle get AlmaraiRegular28 =>
      TextStyle(fontFamily: Almarai, fontWeight: regular, fontSize: size28);
  static TextStyle get AlmaraiRegular32 =>
      TextStyle(fontFamily: Almarai, fontWeight: regular, fontSize: size32);
  static TextStyle get AlmaraiRegular36 =>
      TextStyle(fontFamily: Almarai, fontWeight: regular, fontSize: size36);
  static TextStyle get AlmaraiRegular40 =>
      TextStyle(fontFamily: Almarai, fontWeight: regular, fontSize: size40);
  static TextStyle get AlmaraiRegular48 =>
      TextStyle(fontFamily: Almarai, fontWeight: regular, fontSize: size48);
  static TextStyle get AlmaraiRegular56 =>
      TextStyle(fontFamily: Almarai, fontWeight: regular, fontSize: size56);
  static TextStyle get AlmaraiRegular64 =>
      TextStyle(fontFamily: Almarai, fontWeight: regular, fontSize: size64);
  static TextStyle get AlmaraiRegular72 =>
      TextStyle(fontFamily: Almarai, fontWeight: regular, fontSize: size72);

  // Almarai Medium (500)
  static TextStyle get AlmaraiMedium10 =>
      TextStyle(fontFamily: Almarai, fontWeight: medium, fontSize: size10);
  static TextStyle get AlmaraiMedium12 =>
      TextStyle(fontFamily: Almarai, fontWeight: medium, fontSize: size12);
  static TextStyle get AlmaraiMedium14 =>
      TextStyle(fontFamily: Almarai, fontWeight: medium, fontSize: size14);
  static TextStyle get AlmaraiMedium16 =>
      TextStyle(fontFamily: Almarai, fontWeight: medium, fontSize: size16);
  static TextStyle get AlmaraiMedium18 =>
      TextStyle(fontFamily: Almarai, fontWeight: medium, fontSize: size18);
  static TextStyle get AlmaraiMedium20 =>
      TextStyle(fontFamily: Almarai, fontWeight: medium, fontSize: size20);
  static TextStyle get AlmaraiMedium24 =>
      TextStyle(fontFamily: Almarai, fontWeight: medium, fontSize: size24);
  static TextStyle get AlmaraiMedium28 =>
      TextStyle(fontFamily: Almarai, fontWeight: medium, fontSize: size28);
  static TextStyle get AlmaraiMedium32 =>
      TextStyle(fontFamily: Almarai, fontWeight: medium, fontSize: size32);
  static TextStyle get AlmaraiMedium36 =>
      TextStyle(fontFamily: Almarai, fontWeight: medium, fontSize: size36);
  static TextStyle get AlmaraiMedium40 =>
      TextStyle(fontFamily: Almarai, fontWeight: medium, fontSize: size40);
  static TextStyle get AlmaraiMedium48 =>
      TextStyle(fontFamily: Almarai, fontWeight: medium, fontSize: size48);
  static TextStyle get AlmaraiMedium56 =>
      TextStyle(fontFamily: Almarai, fontWeight: medium, fontSize: size56);
  static TextStyle get AlmaraiMedium64 =>
      TextStyle(fontFamily: Almarai, fontWeight: medium, fontSize: size64);
  static TextStyle get AlmaraiMedium72 =>
      TextStyle(fontFamily: Almarai, fontWeight: medium, fontSize: size72);

  // Almarai Bold (700)
  static TextStyle get AlmaraiBold10 =>
      TextStyle(fontFamily: Almarai, fontWeight: bold, fontSize: size10);
  static TextStyle get AlmaraiBold12 =>
      TextStyle(fontFamily: Almarai, fontWeight: bold, fontSize: size12);
  static TextStyle get AlmaraiBold14 =>
      TextStyle(fontFamily: Almarai, fontWeight: bold, fontSize: size14);
  static TextStyle get AlmaraiBold16 =>
      TextStyle(fontFamily: Almarai, fontWeight: bold, fontSize: size16);
  static TextStyle get AlmaraiBold18 =>
      TextStyle(fontFamily: Almarai, fontWeight: bold, fontSize: size18);
  static TextStyle get AlmaraiBold20 =>
      TextStyle(fontFamily: Almarai, fontWeight: bold, fontSize: size20);
  static TextStyle get AlmaraiBold22 =>
      TextStyle(fontFamily: Almarai, fontWeight: bold, fontSize: size22);
  static TextStyle get AlmaraiBold24 =>
      TextStyle(fontFamily: Almarai, fontWeight: bold, fontSize: size24);
  static TextStyle get AlmaraiBold28 =>
      TextStyle(fontFamily: Almarai, fontWeight: bold, fontSize: size28);
  static TextStyle get AlmaraiBold32 =>
      TextStyle(fontFamily: Almarai, fontWeight: bold, fontSize: size32);
  static TextStyle get AlmaraiBold36 =>
      TextStyle(fontFamily: Almarai, fontWeight: bold, fontSize: size36);
  static TextStyle get AlmaraiBold40 =>
      TextStyle(fontFamily: Almarai, fontWeight: bold, fontSize: size40);
  static TextStyle get AlmaraiBold48 =>
      TextStyle(fontFamily: Almarai, fontWeight: bold, fontSize: size48);
  static TextStyle get AlmaraiBold56 =>
      TextStyle(fontFamily: Almarai, fontWeight: bold, fontSize: size56);
  static TextStyle get AlmaraiBold64 =>
      TextStyle(fontFamily: Almarai, fontWeight: bold, fontSize: size64);
  static TextStyle get AlmaraiBold72 =>
      TextStyle(fontFamily: Almarai, fontWeight: bold, fontSize: size72);

  // Almarai Black (900)
  static TextStyle get AlmaraiBlack10 =>
      TextStyle(fontFamily: Almarai, fontWeight: black, fontSize: size10);
  static TextStyle get AlmaraiBlack12 =>
      TextStyle(fontFamily: Almarai, fontWeight: black, fontSize: size12);
  static TextStyle get AlmaraiBlack14 =>
      TextStyle(fontFamily: Almarai, fontWeight: black, fontSize: size14);
  static TextStyle get AlmaraiBlack16 =>
      TextStyle(fontFamily: Almarai, fontWeight: black, fontSize: size16);
  static TextStyle get AlmaraiBlack18 =>
      TextStyle(fontFamily: Almarai, fontWeight: black, fontSize: size18);
  static TextStyle get AlmaraiBlack20 =>
      TextStyle(fontFamily: Almarai, fontWeight: black, fontSize: size20);
  static TextStyle get AlmaraiBlack24 =>
      TextStyle(fontFamily: Almarai, fontWeight: black, fontSize: size24);
  static TextStyle get AlmaraiBlack28 =>
      TextStyle(fontFamily: Almarai, fontWeight: black, fontSize: size28);
  static TextStyle get AlmaraiBlack32 =>
      TextStyle(fontFamily: Almarai, fontWeight: black, fontSize: size32);
  static TextStyle get AlmaraiBlack36 =>
      TextStyle(fontFamily: Almarai, fontWeight: black, fontSize: size36);
  static TextStyle get AlmaraiBlack40 =>
      TextStyle(fontFamily: Almarai, fontWeight: black, fontSize: size40);
  static TextStyle get AlmaraiBlack48 =>
      TextStyle(fontFamily: Almarai, fontWeight: black, fontSize: size48);
  static TextStyle get AlmaraiBlack56 =>
      TextStyle(fontFamily: Almarai, fontWeight: black, fontSize: size56);
  static TextStyle get AlmaraiBlack64 =>
      TextStyle(fontFamily: Almarai, fontWeight: black, fontSize: size64);
  static TextStyle get AlmaraiBlack72 =>
      TextStyle(fontFamily: Almarai, fontWeight: black, fontSize: size72);

  // ===== COMMON STYLES =====
  static TextStyle get heading1 => AlmaraiBold32;
  static TextStyle get heading2 => AlmaraiBold28;
  static TextStyle get heading3 => AlmaraiBold24;
  static TextStyle get heading4 => AlmaraiBold20;
  static TextStyle get heading5 => AlmaraiBold18;
  static TextStyle get heading6 => AlmaraiBold16;

  static TextStyle get h1 => TextStyle(
        fontFamily: Almarai,
        fontWeight: bold,
        fontSize: Responsive.sp(24),
        height: 1.2,
      );

  static TextStyle get h2 => TextStyle(
        fontFamily: Almarai,
        fontWeight: bold,
        fontSize: Responsive.sp(20),
        height: 1.3,
      );

  static TextStyle get h3 => TextStyle(
        fontFamily: Almarai,
        fontWeight: bold,
        fontSize: Responsive.sp(18),
        height: 1.4,
      );

  static TextStyle get h4 => TextStyle(
        fontFamily: Almarai,
        fontWeight: bold,
        fontSize: Responsive.sp(16),
        height: 1.4,
      );

  static TextStyle get h5 => TextStyle(
        fontFamily: Almarai,
        fontWeight: medium,
        fontSize: Responsive.sp(14),
        height: 1.5,
      );

  static TextStyle get h6 => TextStyle(
        fontFamily: Almarai,
        fontWeight: medium,
        fontSize: Responsive.sp(12),
        height: 1.5,
      );

  static TextStyle get bodyLarge => TextStyle(
        fontFamily: Almarai,
        fontWeight: regular,
        fontSize: Responsive.sp(16),
        height: 1.5,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontFamily: Almarai,
        fontWeight: regular,
        fontSize: Responsive.sp(14),
        height: 1.5,
      );

  static TextStyle get bodySmall => TextStyle(
        fontFamily: Almarai,
        fontWeight: regular,
        fontSize: Responsive.sp(12),
        height: 1.4,
      );

  static TextStyle get caption => TextStyle(
        fontFamily: Almarai,
        fontWeight: regular,
        fontSize: Responsive.sp(10),
        height: 1.3,
      );

  static TextStyle get buttonLarge => TextStyle(
        fontFamily: Almarai,
        fontWeight: medium,
        fontSize: Responsive.sp(16),
        height: 1.2,
      );

  static TextStyle get buttonMedium => TextStyle(
        fontFamily: Almarai,
        fontWeight: medium,
        fontSize: Responsive.sp(14),
        height: 1.2,
      );

  static TextStyle get buttonSmall => TextStyle(
        fontFamily: Almarai,
        fontWeight: medium,
        fontSize: Responsive.sp(12),
        height: 1.2,
      );

  static TextStyle get labelLarge => TextStyle(
        fontFamily: Almarai,
        fontWeight: medium,
        fontSize: Responsive.sp(14),
        height: 1.3,
      );

  static TextStyle get labelMedium => TextStyle(
        fontFamily: Almarai,
        fontWeight: medium,
        fontSize: Responsive.sp(12),
        height: 1.3,
      );

  static TextStyle get labelSmall => TextStyle(
        fontFamily: Almarai,
        fontWeight: medium,
        fontSize: Responsive.sp(10),
        height: 1.2,
      );

  static TextStyle get overline => TextStyle(
        fontFamily: Almarai,
        fontWeight: medium,
        
        height: 1.2,
        letterSpacing: 0.5,
      );
}
