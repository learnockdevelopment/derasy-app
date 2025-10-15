import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/on_generate_route.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_fonts.dart';
import 'core/translations/app_translations.dart';
import 'core/controllers/language_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await AppTranslations.loadTranslations();
  Get.put(LanguageController());
  runApp(const KidsCottageApp());
}

class KidsCottageApp extends StatelessWidget {
  const KidsCottageApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      useInheritedMediaQuery: true,
      builder: (context, child) => GetMaterialApp(
        title: 'Kids Cottage',
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        theme: ThemeData(
          primaryColor: AppColors.primary,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.secondary,
          ),
          fontFamily: AppFonts.roboto,
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,
          textTheme: TextTheme(
            displayLarge: AppFonts.robotoBold64,
            displayMedium: AppFonts.robotoBold56,
            displaySmall: AppFonts.robotoBold48,
            headlineLarge: AppFonts.robotoBold40,
            headlineMedium: AppFonts.robotoBold36,
            headlineSmall: AppFonts.robotoBold32,
            titleLarge: AppFonts.robotoMedium28,
            titleMedium: AppFonts.robotoMedium24,
            titleSmall: AppFonts.robotoMedium20,
            bodyLarge: AppFonts.bodyLarge,
            bodyMedium: AppFonts.bodyMedium,
            bodySmall: AppFonts.bodySmall,
            labelLarge: AppFonts.buttonLarge,
            labelMedium: AppFonts.buttonMedium,
            labelSmall: AppFonts.buttonSmall,
          ),
        ),
        onGenerateRoute: RouteGenerator.onGenerate,
        initialRoute: AppRoutes.splash,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
