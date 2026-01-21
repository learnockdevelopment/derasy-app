import 'package:derasy/widgets/app_scaffold_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/on_generate_route.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_fonts.dart';
import 'core/controllers/app_translations.dart';
import 'core/controllers/language_controller.dart';
import 'core/controllers/app_config_controller.dart';
import 'core/controllers/dashboard_controller.dart'; 

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (FlutterErrorDetails details) {
      final errorString = details.exception.toString().toLowerCase();
      if (errorString.contains('invalid image data') ||
          errorString.contains('failed to decode image') ||
          errorString.contains('imagedecoder') ||
          errorString.contains('networkimageloadexception') ||
          errorString.contains('statuscode: 404') ||
          errorString.contains('http request failed') ||
          (details.library?.contains('image') == true && 
           details.exception.toString().contains('Exception'))) {
        debugPrint('🖼️ [GLOBAL IMAGE ERROR] Caught image error - suppressing');
        debugPrint('🖼️ [GLOBAL IMAGE ERROR] Exception: ${details.exception}');
        return;
      }
      FlutterError.presentError(details);
    };
    
    await GetStorage.init();
    await AppTranslations.loadTranslations();
    Get.put(LanguageController());
    Get.put(AppConfigController());
    Get.put(DashboardController());
    runApp(const DerasyApp());
  } catch (e) {
    print('❌ Error initializing app: $e');
    print('❌ Stack trace: ${StackTrace.current}');
    runApp(const DerasyApp());
  }
}

class DerasyApp extends StatelessWidget {
  const DerasyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) { 
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      useInheritedMediaQuery: true,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl, // RTL for Arabic
        child: GetMaterialApp(
          title: 'Derasy',
          translations: AppTranslations(),
          locale: const Locale('ar', 'SA'),
          fallbackLocale: const Locale('ar', 'SA'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ar', 'SA'),
            Locale('en', 'US'),
          ],
          builder: (context, child) {
            return AppScaffoldWrapper(child: child ?? const SizedBox());
          },
          theme: ThemeData(
            primaryColor: AppColors.primaryBlue,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryBlue,
              primary: AppColors.primaryBlue,
              secondary: AppColors.secondary,
            ),
            fontFamily: AppFonts.Almarai,
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.background,
            textTheme: TextTheme(
              displayLarge: AppFonts.AlmaraiBold64,
              displayMedium: AppFonts.AlmaraiBold56,
              displaySmall: AppFonts.AlmaraiBold48,
              headlineLarge: AppFonts.AlmaraiBold40,
              headlineMedium: AppFonts.AlmaraiBold36,
              headlineSmall: AppFonts.AlmaraiBold32,
              titleLarge: AppFonts.AlmaraiMedium28,
              titleMedium: AppFonts.AlmaraiMedium24,
              titleSmall: AppFonts.AlmaraiMedium20,
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
      ),
    );
  }
}
