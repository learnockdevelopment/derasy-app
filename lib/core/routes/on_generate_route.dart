import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../views/introduction/splash_page.dart';
import '../../views/introduction/intro_page.dart';
import '../../views/authentication/login_page.dart';
import '../../views/authentication/register_page.dart';
import '../../views/home/home_page.dart';
import '../../views/authentication/otp_email_page.dart';
import '../../views/authentication/validate_otp_page.dart';
import '../../views/authentication/reset_password_page.dart';
import '../../views/authentication/verify_email_page.dart';
import '../../views/authentication/verify_phone_page.dart';
import 'app_routes.dart';

class RouteGenerator {
  static Route<dynamic> onGenerate(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.initial:
      case AppRoutes.splash:
        return GetPageRoute(
          settings: settings,
          page: () => const SplashPage(),
        );
      case AppRoutes.intro:
        return GetPageRoute(
          settings: settings,
          page: () => const IntroPage(),
        );
      case AppRoutes.login:
        return GetPageRoute(
          settings: settings,
          page: () => const LoginPage(),
        );
      case AppRoutes.register:
        return GetPageRoute(
          settings: settings,
          page: () => const RegisterPage(),
        );
      case AppRoutes.home:
        return GetPageRoute(
          settings: settings,
          page: () => const HomePage(),
        );
      case AppRoutes.verifyEmail:
        final args = settings.arguments as Map<String, dynamic>?;
        return GetPageRoute(
          settings: settings,
          page: () => VerifyEmailPage(
            userId: args?['userId'] as int? ?? 0,
            email: args?['email']?.toString() ?? '',
          ),
        );
      case AppRoutes.verifyPhone:
        final args = settings.arguments as Map<String, dynamic>?;
        return GetPageRoute(
          settings: settings,
          page: () => VerifyPhonePage(
            userId: args?['userId'] as int? ?? 0,
            phone: args?['phone']?.toString() ?? '',
          ),
        );
      case AppRoutes.otpEmail:
        return GetPageRoute(
          settings: settings,
          page: () => const OtpEmailPage(),
        );
      case AppRoutes.validateOtp:
        final args = settings.arguments as Map<String, dynamic>?;
        return GetPageRoute(
          settings: settings,
          page: () => ValidateOtpPage(
            email: args?['email']?.toString() ?? '',
          ),
        );
      case AppRoutes.resetPassword:
        final args = settings.arguments as Map<String, dynamic>?;
        return GetPageRoute(
          settings: settings,
          page: () => ResetPasswordPage(
            email: args?['email']?.toString() ?? '',
            otp: args?['otp']?.toString() ?? '',
          ),
        );
      default:
        return errorRoute();
    }
  }

  static Route<dynamic> errorRoute() {
    return GetPageRoute(
      page: () => const Scaffold(
        body: Center(
          child: Text('Page not found'),
        ),
      ),
    );
  }
}
