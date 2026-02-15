import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../views/introduction/splash_page.dart';
import '../../views/authentication/role_selection_page.dart';
import '../../views/authentication/login_page.dart';
import '../../views/authentication/register_page.dart';
import '../../views/home/home_page.dart';
import '../../views/authentication/verify_email_page.dart';
import '../../views/authentication/set_new_password_page.dart';
import '../../views/students/my_students_page.dart';
import '../../views/students/data/student_details_page.dart';
import '../../views/students/management/add_student_page.dart';
import '../../views/students/management/edit_student_page.dart';
import '../../views/profile/user_profile_page.dart';
import '../../views/settings/settings_page.dart';
import '../../views/notifications/notifications_page.dart';
import '../../views/notifications/notification_details_page.dart';
import '../../models/notification_model.dart';
import '../../views/chatbot/chatbot_page.dart';
import '../../models/student_models.dart';
import '../../views/children/add_child_page.dart';
import '../../views/children/add_child_steps_page.dart';
import '../../views/children/child_details_page.dart';
import '../../views/admission/apply_to_schools_page.dart';
import '../../views/admission/applications_page.dart';
import '../../views/admission/application_details_page.dart';
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
      case AppRoutes.roleSelection:
        return GetPageRoute(
          settings: settings,
          page: () => const RoleSelectionPage(),
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
      case AppRoutes.myStudents:
        return GetPageRoute(
          settings: settings,
          page: () => const MyStudentsPage(),
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
      case AppRoutes.userProfile:
        return GetPageRoute(
          settings: settings,
          page: () => const UserProfilePage(),
        );
      case AppRoutes.settings:
        return GetPageRoute(
          settings: settings,
          page: () => const SettingsPage(),
        );
      case AppRoutes.notifications:
        return GetPageRoute(
          settings: settings,
          page: () => const NotificationsPage(),
        );
      case AppRoutes.notificationDetails:
        final notification = settings.arguments as NotificationItem;
        return GetPageRoute(
          settings: settings,
          page: () => NotificationDetailsPage(notification: notification),
        );
      case AppRoutes.chatbot:
        return GetPageRoute(
          settings: settings,
          page: () => const ChatbotPage(),
        );
      case AppRoutes.addChild:
        return GetPageRoute(
          settings: settings,
          page: () => const AddChildPage(),
        );
      case AppRoutes.addChildSteps:
        return GetPageRoute(
          settings: settings,
          page: () => const AddChildStepsPage(),
        );
      case AppRoutes.childDetails:
        final args = settings.arguments as Map<String, dynamic>;
        return GetPageRoute(
          settings: settings,
          page: () => ChildDetailsPage(child: args['child'] as Student),
        );

      case AppRoutes.applyToSchools:
        return GetPageRoute(
          settings: settings,
          page: () => const ApplyToSchoolsPage(),
        );
      case AppRoutes.applications:
        final args = settings.arguments as Map<String, dynamic>?;
        return GetPageRoute(
          settings: settings,
          page: () => ApplicationsPage(
            childId: args?['childId'],
            child: args?['child'],
          ),
        );
      case AppRoutes.applicationDetails:
        return GetPageRoute(
          settings: settings,
          page: () => const ApplicationDetailsPage(),
        );
      default:
        return errorRoute();
    }
  }

  static Route<dynamic> errorRoute() {
    return GetPageRoute(
      page: () => Scaffold(
        body: Center(
          child: Text('page_not_found'.tr),
        ),
      ),
    );
  }
}

