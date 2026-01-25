import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/bus_models.dart';
import '../../services/classes_service.dart';
import '../../services/teachers_service.dart';
import '../../views/bus/bus_form_page.dart';
import '../../views/introduction/splash_page.dart';
import '../../views/authentication/role_selection_page.dart';
import '../../views/authentication/login_page.dart';
import '../../views/authentication/register_page.dart';
import '../../views/home/home_page.dart';
import '../../views/authentication/verify_email_page.dart';
import '../../views/authentication/set_new_password_page.dart';
import '../../views/students/my_students_page.dart';
import '../../views/students/data/student_details_page.dart';
import '../../views/teachers/teachers_page.dart';
import '../../views/teachers/teacher_details_page.dart';
import '../../views/classes/classes_page.dart';
import '../../views/classes/class_details_page.dart';
import '../../views/students/management/add_student_page.dart';
import '../../views/students/management/edit_student_page.dart';
import '../../views/schools/schools_page.dart';
import '../../views/schools/school_details_page.dart';
import '../../views/attendance/attendance_page.dart';
import '../../views/profile/user_profile_page.dart';
import '../../views/settings/settings_page.dart';
import '../../views/notifications/notifications_page.dart';
import '../../views/chatbot/chatbot_page.dart';
import '../../views/teachers/management/add_teacher_page.dart';
import '../../views/teachers/management/edit_teacher_page.dart';
import '../../views/classes/management/add_class_page.dart';
import '../../views/classes/management/edit_class_page.dart';
import '../../views/id_card/id_card_management_page.dart';
import '../../views/store/products/store_products_page.dart';
import '../../views/store/products/product_details_page.dart';
import '../../views/store/products/add_product_page.dart';
import '../../views/store/cart/shopping_cart_page.dart';
import '../../views/store/orders/orders_page.dart';
import '../../views/store/orders/order_details_page.dart';
import '../../models/school_models.dart';
import '../../models/student_models.dart';
import '../../views/bus/buses_page.dart';
import '../../views/bus/bus_details_page.dart';
import '../../views/children/add_child_page.dart';
import '../../views/children/add_child_steps_page.dart';
import '../../views/children/child_details_page.dart';
import '../../views/admission/apply_to_schools_page.dart';
import '../../views/admission/applications_page.dart';
import '../../views/admission/application_details_page.dart';
import '../../views/wallet/wallet_page.dart';
import '../../views/wallet/deposit_page.dart';
import '../../views/wallet/withdraw_page.dart';
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
      case AppRoutes.teachers:
        return GetPageRoute(
          settings: settings,
          page: () => const TeachersPage(),
        );
      case AppRoutes.teacherDetails:
        return GetPageRoute(
          settings: settings,
          page: () => const TeacherDetailsPage(),
        );
      case AppRoutes.classes:
        return GetPageRoute(
          settings: settings,
          page: () => const ClassesPage(),
        );
      case AppRoutes.classDetails:
        return GetPageRoute(
          settings: settings,
          page: () => const ClassDetailsPage(),
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
      case AppRoutes.chatbot:
        return GetPageRoute(
          settings: settings,
          page: () => const ChatbotPage(),
        );
      case AppRoutes.addTeacher:
        return GetPageRoute(
          settings: settings,
          page: () => const AddTeacherPage(),
        );
      case AppRoutes.editTeacher:
        final args = settings.arguments as Map<String, dynamic>;
        return GetPageRoute(
          settings: settings,
          page: () => EditTeacherPage(
            teacher: args['teacher'] as Teacher,
            schoolId: args['schoolId'] as String,
          ),
        );
      case AppRoutes.addClass:
        return GetPageRoute(
          settings: settings,
          page: () => const AddClassPage(),
        );
      case AppRoutes.editClass:
        final args = settings.arguments as Map<String, dynamic>;
        return GetPageRoute(
          settings: settings,
          page: () => EditClassPage(
            schoolClass: args['schoolClass'] as SchoolClass,
            schoolId: args['schoolId'] as String,
          ),
        );
      case AppRoutes.idCardManagement:
        return GetPageRoute(
          settings: settings,
          page: () => const IdCardManagementPage(),
        );
      case AppRoutes.buses:
        final args = settings.arguments as Map<String, dynamic>?;
        return GetPageRoute(
          settings: settings,
          page: () => BusesPage(
            schoolId: args?['schoolId'] as String?,
            school: args?['school'] as School?,
          ),
        );
      case AppRoutes.busDetails:
        final args = settings.arguments as Map<String, dynamic>;
        return GetPageRoute(
          settings: settings,
          page: () => BusDetailsPage(
            schoolId: args['schoolId'] as String,
            busId: args['busId'] as String,
            initialBus: args['bus'] as dynamic,
          ),
        );
      case AppRoutes.busForm:
        final args = settings.arguments as Map<String, dynamic>;
        return GetPageRoute(
          settings: settings,
          page: () => BusFormPage(
            schoolId: args['schoolId'] as String,
            bus: args['bus'] as Bus?,
          ),
        );
      case AppRoutes.storeProducts:
        return GetPageRoute(
          settings: settings,
          page: () => const StoreProductsPage(),
        );
      case AppRoutes.storeProductDetails:
        return GetPageRoute(
          settings: settings,
          page: () => const ProductDetailsPage(),
        );
      case AppRoutes.addProduct:
        return GetPageRoute(
          settings: settings,
          page: () => const AddProductPage(),
        );
      case AppRoutes.storeCart:
        return GetPageRoute(
          settings: settings,
          page: () => const ShoppingCartPage(),
        );
      case AppRoutes.storeOrders:
        return GetPageRoute(
          settings: settings,
          page: () => const OrdersPage(),
        );
      case AppRoutes.storeOrderDetails:
        return GetPageRoute(
          settings: settings,
          page: () => const OrderDetailsPage(),
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
      case AppRoutes.wallet:
        return GetPageRoute(
          settings: settings,
          page: () => const WalletPage(),
        );
      case AppRoutes.walletDeposit:
        return GetPageRoute(
          settings: settings,
          page: () => const DepositPage(),
        );
      case AppRoutes.walletWithdraw:
        return GetPageRoute(
          settings: settings,
          page: () => const WithdrawPage(),
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

