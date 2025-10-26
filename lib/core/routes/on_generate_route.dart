import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../views/introduction/splash_page.dart';
import '../../views/authentication/login_page.dart';
import '../../views/authentication/register_page.dart';
import '../../views/home/home_page.dart';
import '../../views/authentication/verify_email_page.dart';
import '../../views/authentication/set_new_password_page.dart';
import '../../views/students/students_page.dart';
import '../../views/students/data/student_details_page.dart';
import '../../views/students/management/add_student_page.dart';
import '../../views/students/management/edit_student_page.dart';
import '../../views/schools/schools_page.dart';
import '../../views/schools/school_details_page.dart';
import '../../views/attendance/attendance_page.dart';
import '../../views/profile/user_profile_page.dart';
import '../../models/school_models.dart';
import '../../models/student_models.dart';
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
        return GetPageRoute(
          settings: settings,
          page: () => const VerifyEmailPage(),
        );
      case AppRoutes.setNewPassword:
        return GetPageRoute(
          settings: settings,
          page: () => const SetNewPasswordPage(),
        );
      case AppRoutes.students:
        return GetPageRoute(
          settings: settings,
          page: () => const StudentsPage(),
        );
      case AppRoutes.schools:
        return GetPageRoute(
          settings: settings,
          page: () => const SchoolsPage(),
        );
      case AppRoutes.schoolDetails:
        final school = settings.arguments as School;
        return GetPageRoute(
          settings: settings,
          page: () => SchoolDetailsPage(school: school),
        );
      case AppRoutes.studentDetails:
        final args = settings.arguments as Map<String, dynamic>;
        final student = args['student'] as Student;
        final schoolId = args['schoolId'] as String?;
        return GetPageRoute(
          settings: settings,
          page: () => StudentDetailsPage(student: student, schoolId: schoolId),
        );
      case AppRoutes.addStudent:
        final args = settings.arguments as Map<String, dynamic>;
        final schoolId = args['schoolId'] as String;
        return GetPageRoute(
          settings: settings,
          page: () => AddStudentPage(),
        );
      case AppRoutes.editStudent:
        final args = settings.arguments as Map<String, dynamic>;
        final student = args['student'] as Student;
        final schoolId = args['schoolId'] as String;
        return GetPageRoute(
          settings: settings,
          page: () => EditStudentPage(student: student, schoolId: schoolId),
        );
      case AppRoutes.attendance:
        return GetPageRoute(
          settings: settings,
          page: () => const AttendancePage(),
        );
      case AppRoutes.userProfile:
        return GetPageRoute(
          settings: settings,
          page: () => const UserProfilePage(),
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
