import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class Responsive {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

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

  /// Adaptive width: scales with screen width but clamped for larger screens.
  static double w(double width) => width.w * scalingFactor;

  /// Adaptive height: scales with screen height but clamped for larger screens.
  static double h(double height) => height.h * scalingFactor;

  /// Adaptive font size: scales with screen width but clamped for larger screens.
  static double sp(double fontSize) => fontSize.sp * scalingFactor;

  /// Adaptive radius: scales with screen size but clamped for larger screens.
  static double r(double radius) => radius.r * scalingFactor;

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
}

