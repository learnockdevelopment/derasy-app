import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../views/introduction/splash_page.dart';
import '../../views/introduction/intro_page.dart';
import '../../views/authentication/login_page.dart';
import '../../views/authentication/register_page.dart';
import '../../views/home/home_page.dart';
import '../../views/authentication/forgot_password_page.dart';
import '../../views/authentication/verify_forgot_password_page.dart';
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
      case AppRoutes.forgotPassword:
        return GetPageRoute(
          settings: settings,
          page: () => const ForgotPasswordPage(),
        );
      case AppRoutes.verifyForgotPassword:
        final args = settings.arguments as Map<String, dynamic>?;
        return GetPageRoute(
          settings: settings,
          page: () => VerifyForgotPasswordPage(
            identifier: args?['identifier']?.toString() ?? '',
            sentVia: args?['sentVia']?.toString() ?? '',
            devCode: args?['devCode']?.toString(),
          ),
        );
      case AppRoutes.resetPassword:
        final args = settings.arguments as Map<String, dynamic>?;
        return GetPageRoute(
          settings: settings,
          page: () => ResetPasswordPage(
            identifier: args?['identifier']?.toString() ?? '',
            otp: args?['otp']?.toString() ?? '',
          ),
        );
      case AppRoutes.verifyEmail:
        final args = settings.arguments as Map<String, dynamic>?;
        return GetPageRoute(
          settings: settings,
          page: () => VerifyEmailPage(
            userId: args?['userId']?.toString() ?? '',
            firstName: args?['firstName']?.toString() ?? '',
            lastName: args?['lastName']?.toString() ?? '',
            email: args?['email']?.toString() ?? '',
            phone: args?['phone']?.toString() ?? '',
          ),
        );
      case AppRoutes.verifyPhone:
        final args = settings.arguments as Map<String, dynamic>?;
        return GetPageRoute(
          settings: settings,
          page: () => VerifyPhonePage(
            userId: args?['userId']?.toString() ?? '',
            firstName: args?['firstName']?.toString() ?? '',
            lastName: args?['lastName']?.toString() ?? '',
            email: args?['email']?.toString() ?? '',
            phone: args?['phone']?.toString() ?? '',
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
