import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/on_generate_route.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_fonts.dart';
import 'core/translations/app_translations.dart';
import 'core/controllers/language_controller.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    print('✅ Flutter binding initialized');

    await GetStorage.init();
    print('✅ GetStorage initialized');

    await AppTranslations.loadTranslations();
    print('✅ Translations loaded');

    Get.put(LanguageController());
    print('✅ Language controller initialized');

    runApp(const DerasyApp());
    print('✅ App started');
  } catch (e) {
    print('❌ Error initializing app: $e');
    print('❌ Stack trace: ${StackTrace.current}');
    // Fallback initialization
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
          theme: ThemeData(
            primaryColor: AppColors.primary,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              secondary: AppColors.secondary,
            ),
            fontFamily: AppFonts.cairo,
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.background,
            textTheme: TextTheme(
              displayLarge: AppFonts.cairoBold64,
              displayMedium: AppFonts.cairoBold56,
              displaySmall: AppFonts.cairoBold48,
              headlineLarge: AppFonts.cairoBold40,
              headlineMedium: AppFonts.cairoBold36,
              headlineSmall: AppFonts.cairoBold32,
              titleLarge: AppFonts.cairoMedium28,
              titleMedium: AppFonts.cairoMedium24,
              titleSmall: AppFonts.cairoMedium20,
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
