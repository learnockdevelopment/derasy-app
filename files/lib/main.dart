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
import 'widgets/animated_app_background.dart';

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
      builder: (context, child) => Obx(() => GetMaterialApp(
          title: 'Derasy',
          themeMode: AppConfigController.to.isDarkMode ? ThemeMode.dark : ThemeMode.light,
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

          theme: ThemeData(
            primaryColor: AppColors.salesAccent,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.salesAccent,
              primary: AppColors.salesAccent,
              secondary: AppColors.secondary,
              brightness: Brightness.light,
              surface: AppColors.salesBackgroundLight,
              onSurface: AppColors.salesForegroundLight,
            ),
            fontFamily: AppFonts.Almarai,
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.transparent,
            textTheme: TextTheme( 
              displayLarge: AppFonts.AlmaraiBold64.copyWith(color: AppColors.salesForegroundLight),
              displayMedium: AppFonts.AlmaraiBold56.copyWith(color: AppColors.salesForegroundLight),
              displaySmall: AppFonts.AlmaraiBold48.copyWith(color: AppColors.salesForegroundLight),
              headlineLarge: AppFonts.AlmaraiBold40.copyWith(color: AppColors.salesForegroundLight),
              headlineMedium: AppFonts.AlmaraiBold36.copyWith(color: AppColors.salesForegroundLight),
              headlineSmall: AppFonts.AlmaraiBold32.copyWith(color: AppColors.salesForegroundLight),
              titleLarge: AppFonts.AlmaraiMedium28.copyWith(color: AppColors.salesForegroundLight),
              titleMedium: AppFonts.AlmaraiMedium24.copyWith(color: AppColors.salesForegroundLight),
              titleSmall: AppFonts.AlmaraiMedium20.copyWith(color: AppColors.salesForegroundLight),
              bodyLarge: AppFonts.bodyLarge.copyWith(color: AppColors.salesForegroundLight),
              bodyMedium: AppFonts.bodyMedium.copyWith(color: AppColors.salesForegroundLight),
              bodySmall: AppFonts.bodySmall.copyWith(color: AppColors.salesForegroundLight),
              labelLarge: AppFonts.buttonLarge.copyWith(color: AppColors.salesForegroundLight),
              labelMedium: AppFonts.buttonMedium.copyWith(color: AppColors.salesForegroundLight),
              labelSmall: AppFonts.buttonSmall.copyWith(color: AppColors.salesForegroundLight),
            ),
          ),
          darkTheme: ThemeData(
            primaryColor: AppColors.salesAccent,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.salesAccent,
              primary: AppColors.salesAccent,
              secondary: AppColors.secondary,
              brightness: Brightness.dark,
              surface: AppColors.salesBackgroundDark,
              onSurface: AppColors.salesForegroundDark,
              surfaceContainerLowest: AppColors.salesSurfaceDark,
            ),
            fontFamily: AppFonts.Almarai,
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.transparent,
            textTheme: TextTheme( 
              displayLarge: AppFonts.AlmaraiBold64.copyWith(color: AppColors.salesForegroundDark),
              displayMedium: AppFonts.AlmaraiBold56.copyWith(color: AppColors.salesForegroundDark),
              displaySmall: AppFonts.AlmaraiBold48.copyWith(color: AppColors.salesForegroundDark),
              headlineLarge: AppFonts.AlmaraiBold40.copyWith(color: AppColors.salesForegroundDark),
              headlineMedium: AppFonts.AlmaraiBold36.copyWith(color: AppColors.salesForegroundDark),
              headlineSmall: AppFonts.AlmaraiBold32.copyWith(color: AppColors.salesForegroundDark),
              titleLarge: AppFonts.AlmaraiMedium28.copyWith(color: AppColors.salesForegroundDark),
              titleMedium: AppFonts.AlmaraiMedium24.copyWith(color: AppColors.salesForegroundDark),
              titleSmall: AppFonts.AlmaraiMedium20.copyWith(color: AppColors.salesForegroundDark),
              bodyLarge: AppFonts.bodyLarge.copyWith(color: AppColors.salesForegroundDark),
              bodyMedium: AppFonts.bodyMedium.copyWith(color: AppColors.salesForegroundDark),
              bodySmall: AppFonts.bodySmall.copyWith(color: AppColors.salesForegroundDark),
              labelLarge: AppFonts.buttonLarge.copyWith(color: AppColors.salesForegroundDark),
              labelMedium: AppFonts.buttonMedium.copyWith(color: AppColors.salesForegroundDark),
              labelSmall: AppFonts.buttonSmall.copyWith(color: AppColors.salesForegroundDark),
            ),
          ),
          builder: (context, child) {
            return AnimatedAppBackground(
              child: child ?? const SizedBox(),
            );
          },
          onGenerateRoute: RouteGenerator.onGenerate,
          initialRoute: AppRoutes.splash,
          debugShowCheckedModeBanner: false,
        )),
    );
  }
}

