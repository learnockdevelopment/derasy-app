import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class Responsive {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  static bool get isRTL => Get.locale?.languageCode == 'ar';

  static double get _screenWidth {
    try {
      // Direct ScreenUtil access is safer if Get isn't ready
      return ScreenUtil().screenWidth > 0 ? ScreenUtil().screenWidth : 375.0;
    } catch (_) {
      try {
        return Get.width;
      } catch (_) {
        return 375.0; // Fail-safe default
      }
    }
  }

  static bool get isMobile => _screenWidth < mobileBreakpoint;
  static bool get isTablet => _screenWidth >= mobileBreakpoint && _screenWidth < tabletBreakpoint;
  static bool get isDesktop => _screenWidth >= tabletBreakpoint;

  /// Returns a scaling factor to make objects smaller on larger screens.
  /// On Mobile (375x812 design), factor is 1.0.
  /// On Tablet/PC, we reduce the factor to avoid "blown up" UI.
  static double get scalingFactor {
    if (isMobile) return 1.0;
    if (isTablet) return 0.85;
    return 0.75;
  }

  static double get _screenHeight {
    try {
      return ScreenUtil().screenHeight > 0 ? ScreenUtil().screenHeight : 812.0;
    } catch (_) {
      try {
        return Get.height;
      } catch (_) {
        return 812.0;
      }
    }
  }

  /// Master scale factor on tablet/desktop to ensure uniform scaling and prevent layout overflows
  static double get masterScale {
    if (isMobile) return 1.0;
    final rawScale = (_screenWidth / 375.0) * scalingFactor;
    return rawScale.clamp(1.05, 1.20);
  }

  /// Adaptive width: scales with screen width but clamped for larger screens.
  static double w(double width) {
    if (isMobile) return width.w * scalingFactor;
    return width * masterScale;
  }

  /// Adaptive height: scales with screen height but clamped for larger screens.
  static double h(double height) {
    if (isMobile) return height.h * scalingFactor;
    return height * masterScale;
  }

  /// Adaptive font size: scales with screen width but clamped for larger screens.
  static double sp(double fontSize) {
    if (isMobile) return fontSize.sp * scalingFactor;
    final fontScale = masterScale.clamp(1.02, 1.15);
    return fontSize * fontScale;
  }

  /// Adaptive radius: scales with screen size but clamped for larger screens.
  static double r(double radius) {
    if (isMobile) return radius.r * scalingFactor;
    return radius * masterScale;
  }

  /// Adaptive padding/margin: uses clamped scaling.
  static EdgeInsets symmetric({double horizontal = 0, double vertical = 0}) {
    return EdgeInsets.symmetric(
      horizontal: w(horizontal),
      vertical: h(vertical),
    );
  }

  static EdgeInsets all(double value) => EdgeInsets.all(w(value));
  
  static EdgeInsets only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return EdgeInsets.only(
      left: w(left),
      top: h(top),
      right: w(right),
      bottom: h(bottom),
    );
  }

  static EdgeInsets fromLTRB(double left, double top, double right, double bottom) {
    return EdgeInsets.fromLTRB(
      w(left),
      h(top),
      w(right),
      h(bottom),
    );
  }

  /// Format school name to keep only the first two words if the name is large
  static String formatSchoolName(String name) {
    if (name.isEmpty) return '';
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length <= 2) return name;
    return '${words[0]} ${words[1]}';
  }

  /// Format time string (e.g. "14:30") to AM/PM format
  static String formatTimeToAmPm(String timeStr) {
    if (timeStr.isEmpty) return '';
    try {
      final lower = timeStr.toLowerCase();
      if (lower.contains('am') || lower.contains('pm') || lower.contains('ص') || lower.contains('م')) {
        return timeStr;
      }
      final parts = timeStr.split(':');
      if (parts.isNotEmpty) {
        int hour = int.parse(parts[0].trim());
        int minute = parts.length > 1 ? int.parse(parts[1].trim()) : 0;
        final period = hour >= 12 ? 'PM' : 'AM';
        int displayHour = hour % 12;
        if (displayHour == 0) displayHour = 12;
        final minuteStr = minute.toString().padLeft(2, '0');
        return '$displayHour:$minuteStr $period';
      }
    } catch (_) {}
    return timeStr;
  }
}

