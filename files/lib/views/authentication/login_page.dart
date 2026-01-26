import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:country_code_picker/country_code_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/assets.dart';
import '../../core/constants/countries.dart';
import '../../core/routes/app_routes.dart';
import '../../core/controllers/app_config_controller.dart';
import '../../services/auth_service.dart';
import '../../services/user_storage_service.dart';
import '../../models/auth_models.dart';
import '../../core/controllers/dashboard_controller.dart';
import 'package:local_auth/local_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io' show Platform;

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key); 

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isPhoneLogin = true;
  Offset _chatButtonPosition = Offset(0, 0);
  CountryCode _selectedCountryCode = CountryCode(name: 'Egypt', code: 'EG', dialCode: '+20');

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Biometric
  final LocalAuthentication auth = LocalAuthentication();
  bool _canCheckBiometric = false;

  @override
  void initState() {
    super.initState();  
 
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>( 
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _checkBiometrics();
    
    // Set initial chat button position after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      setState(() {
        _chatButtonPosition = Offset(size.width - Responsive.w(80), size.height - Responsive.h(110));
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidPhone(String phone) {
    // Remove spaces and dashes
    final cleanPhone = phone.replaceAll(RegExp(r'[\s-]'), '');
    // Check if it's a valid phone number (8-15 digits)
    return RegExp(r'^[0-9]{8,15}$').hasMatch(cleanPhone);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  String _getTranslatedCountryName(String code, String fallback) {
    final key = 'country_${code.toLowerCase()}';
    final translated = key.tr;
    // If translation key doesn't exist, Get.tr returns the key itself
    return translated == key ? fallback : translated;
  }

  void _showModernCountryPicker(BuildContext context) {
    final TextEditingController searchController = TextEditingController();
    List<Country> filteredCountries = Countries.countries;
    Country? selectedCountry = Countries.getCountryByCode(_selectedCountryCode.code ?? 'EG');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          void filterCountries(String query) {
            setModalState(() {
              if (query.isEmpty) {
                filteredCountries = Countries.countries;
              } else {
                filteredCountries = Countries.searchCountries(query);
              }
            });
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(Responsive.r(24)),
                topRight: Radius.circular(Responsive.r(24)),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: Responsive.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.grey200, width: Responsive.w(1)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'select_country'.tr,
                        style: AppFonts.AlmaraiBold18.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                // Search Bar
                Padding(
                  padding: Responsive.all(16),
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: searchController,
                    builder: (context, value, child) {
                      return TextField(
                        controller: searchController,
                        onChanged: filterCountries,
                        autofocus: false,
                        decoration: InputDecoration(
                          hintText: 'search_countries'.tr,
                          hintStyle: AppFonts.AlmaraiRegular14.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.textSecondary,
                            size: Responsive.sp(22),
                          ),
                          suffixIcon: value.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: AppColors.textSecondary),
                                  onPressed: () {
                                    searchController.clear();
                                    filterCountries('');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: AppColors.grey50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Responsive.r(12)),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: Responsive.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Countries List
                Expanded(
                  child: ListView.builder(
                    padding: Responsive.symmetric(horizontal: 16),
                    itemCount: filteredCountries.length,
                    itemBuilder: (context, index) {
                      final country = filteredCountries[index];
                      final isSelected = selectedCountry.code == country.code;
                      final primary = AppConfigController.to.primaryColorAsColor;

                      return InkWell(
                        onTap: () {
                          // Convert Country to CountryCode
                          final countryCode = CountryCode(
                            name: country.name,
                            code: country.code,
                            dialCode: country.dialCode,
                          );
                          setState(() {
                            _selectedCountryCode = countryCode;
                          });
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(Responsive.r(12)),
                        child: Container(
                          margin: EdgeInsets.only(bottom: Responsive.h(4)),
                          padding: Responsive.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? primary.withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(Responsive.r(10)),
                            border: isSelected
                                ? Border.all(color: primary, width: Responsive.w(1.5))
                                : Border.all(color: AppColors.grey200, width: Responsive.w(1)),
                          ),
                          child: Row(
                            children: [
                              // Flag
                              Container(
                                width: Responsive.w(32),
                                height: Responsive.w(32),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.grey200,
                                    width: Responsive.w(1),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    country.flag,
                                    style: TextStyle(fontSize: Responsive.sp(20)),
                                  ),
                                ),
                              ),
                              SizedBox(width: Responsive.w(12)),
                              // Country Name and Code
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getTranslatedCountryName(country.code, country.name),
                                      style: AppFonts.AlmaraiMedium12.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: Responsive.h(2)),
                                    Text(
                                      country.dialCode,
                                      style: AppFonts.AlmaraiRegular10.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Selected Indicator
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: primary,
                                  size: Responsive.sp(20),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get email or phone based on login type
      // Note: API expects email field, so we use the entered value (email or phone)
      final String email = _isPhoneLogin 
          ? _phoneController.text.trim() 
          : _emailController.text.trim();
      
      // Create login request
      final loginRequest = LoginRequest(
        email: email,
        password: _passwordController.text.trim(),
      );

      // Call login API
      final loginResponse = await AuthService.login(loginRequest);

      if (!mounted) return;

      // Check user role - only allow student or parent
      final userRole = loginResponse.user.role.toLowerCase();
      
      if (userRole != 'student' && userRole != 'parent') {
        // Role not allowed
        setState(() {
          _isLoading = false;
        });
        
        Get.snackbar(
          'login_failed'.tr,
          'only_student_or_parent_allowed'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      // Save user data and token
      await UserStorageService.saveCurrentUser(
        loginResponse.user,
        loginResponse.token,
      );

      setState(() {
        _isLoading = false;
      });

      // Show success message
      Get.snackbar(
        'login_success'.tr,
        loginResponse.message.isNotEmpty 
            ? loginResponse.message 
            : 'welcome_back_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.blue1,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // Trigger pre-fetching of all data
      try {
        DashboardController.to.refreshAll();
      } catch (e) {
        print('📊 [LOGIN] Error triggering pre-fetch: $e');
      }

      // Navigate to home
      Get.offNamed<void>(AppRoutes.home);
      
    } on AuthException catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });

      // Translate error message
      String errorMessage = e.message;
      if (e.message.toLowerCase().contains('invalid credentials')) {
        errorMessage = 'invalid_credentials'.tr;
      }

      // Show error message
      Get.snackbar(
        'login_failed'.tr,
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });

      // Show generic error message
      Get.snackbar(
        'login_failed'.tr,
        'network_error_please_try_again'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }


  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await auth.canCheckBiometrics;
      final isEnabled = UserStorageService.isBiometricEnabled();
      final creds = UserStorageService.getBiometricCredentials();
      if (mounted) {
        setState(() {
          _canCheckBiometric = canCheck && isEnabled && creds != null;
        });
      }
    } catch (e) {
      print('Biometric check failed: $e');
    }
  }

  Future<void> _triggerBiometric() async {
    try {
      final didAuthenticate = await auth.authenticate(
        localizedReason: 'scan_fingerprint'.tr,
        options: const AuthenticationOptions(stickyAuth: true),
      );
      if (didAuthenticate) {
        final creds = UserStorageService.getBiometricCredentials();
        if (creds != null) {
          setState(() {
            _isPhoneLogin = false; // Force email mode to use the stored email/username
            _emailController.text = creds['email']!;
            _passwordController.text = creds['password']!;
          });
          _handleLogin();
        }
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'biometric_error'.tr, 
          snackPosition: SnackPosition.BOTTOM, 
          backgroundColor: AppColors.error, 
          colorText: Colors.white);
    }
  }



  Future<void> _handleGoogleLogin() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw AuthException('Failed to get Google ID token', 0);
      }

      final loginResponse = await AuthService.loginWithGoogle(idToken);

      if (!mounted) return;

      final userRole = loginResponse.user.role.toLowerCase();

      if (userRole != 'student' && userRole != 'parent') {
        setState(() {
          _isLoading = false;
        });

        Get.snackbar(
          'login_failed'.tr,
          'only_student_or_parent_allowed'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      await UserStorageService.saveCurrentUser(
        loginResponse.user,
        loginResponse.token,
      );

      setState(() {
        _isLoading = false;
      });

      Get.snackbar(
        'login_success'.tr,
        loginResponse.message.isNotEmpty
            ? loginResponse.message
            : 'welcome_back_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.blue1,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      try {
        DashboardController.to.refreshAll();
      } catch (e) {
        print('📊 [LOGIN] Error triggering pre-fetch: $e');
      }

      Get.offNamed<void>(AppRoutes.home);

    } catch (e) {
      if (!mounted) return;
        setState(() {
        _isLoading = false;
      });
      print('Google Sign In Error: $e');
      Get.snackbar(
        'error'.tr,
        'google_login_failed'.tr,
        snackPosition: SnackPosition.BOTTOM,
         backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _handleAppleLogin() async {
    try {
        setState(() {
        _isLoading = true;
      });

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken;
      final authorizationCode = credential.authorizationCode;

      if (identityToken == null) {
          throw AuthException('Failed to get Apple Identity Token', 0);
      }

      final loginResponse = await AuthService.loginWithApple(identityToken, authorizationCode);

       if (!mounted) return;

      final userRole = loginResponse.user.role.toLowerCase();

      if (userRole != 'student' && userRole != 'parent') {
        setState(() {
          _isLoading = false;
        });

        Get.snackbar(
          'login_failed'.tr,
          'only_student_or_parent_allowed'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      await UserStorageService.saveCurrentUser(
        loginResponse.user,
        loginResponse.token,
      );

      setState(() {
        _isLoading = false;
      });

      Get.snackbar(
        'login_success'.tr,
        loginResponse.message.isNotEmpty
            ? loginResponse.message
            : 'welcome_back_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.blue1,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      
      Get.offNamed<void>(AppRoutes.home);

    } catch (e) {
        if (!mounted) return;
        setState(() {
        _isLoading = false;
      });
      print('Apple Sign In Error: $e');
       Get.snackbar(
        'error'.tr,
        'apple_login_failed'.tr,
        snackPosition: SnackPosition.BOTTOM,
         backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppConfigController.to.primaryColorAsColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Top Bar with Back Button and Language Selector
                Padding(
                  padding: Responsive.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: Icon(
                          Icons.arrow_back,
                          color: AppColors.textPrimary,
                          size: Responsive.sp(20),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                      // Language Button (toggle)
                      InkWell(
                        borderRadius: BorderRadius.circular(Responsive.r(6)),
                        onTap: () {
                          final isAr = Get.locale?.languageCode == 'ar';
                          Get.updateLocale(isAr ? const Locale('en', 'US') : const Locale('ar', 'SA'));
                          setState(() {});
                        },
                        child: Padding(
                          padding: Responsive.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.language,
                                color: primary,
                                size: Responsive.sp(18),
                              ),
                              SizedBox(width: Responsive.w(3)),
                              Text(
                                (Get.locale?.languageCode == 'ar') ? 'English' : 'العربية',
                                style: AppFonts.AlmaraiMedium12.copyWith(
                                  color: primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Padding(
                      padding: Responsive.symmetric(horizontal: 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            SizedBox(height: Responsive.h(20)),

                            // Logo
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Image.asset(
                                AssetsManager.login,
                                width: Responsive.w(90),
                                height: Responsive.w(90),
                                fit: BoxFit.contain,
                              ),
                            ),

                            SizedBox(height: Responsive.h(20)),

                            // Title
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Column(
                                children: [
                                  Text(
                                    'login'.tr,
                                    style: AppFonts.AlmaraiBold20.copyWith(
                                      color: AppColors.textPrimary,
                                    ),  
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: Responsive.h(6)),
                                  Text(
                                    'sign_in_to_continue'.tr,
                                    style: AppFonts.AlmaraiRegular12.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: Responsive.h(24)),
                            SlideTransition(
                              position: _slideAnimation,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: Column(
                                  children: [ 
                                    if (_isPhoneLogin)
                                      // Phone Field with Flag and Country Code
                                      TextFormField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        style: AppFonts.AlmaraiRegular14,
                                        decoration: InputDecoration(
                                          labelText: 'phone_number'.tr,
                                          labelStyle: AppFonts.AlmaraiRegular14.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                          hintText: 'enter_your_phone'.tr,
                                          hintStyle: AppFonts.AlmaraiRegular12.copyWith(
                                            color: AppColors.grey400,
                                          ),
                                          prefixIcon: GestureDetector(
                                            onTap: () {
                                              _showModernCountryPicker(context);
                                            },
                                            child: Container(
                                              padding: Responsive.symmetric(horizontal: 12),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // Flag - using emoji from Countries
                                                  Container(
                                                    width: Responsive.w(28),
                                                    height: Responsive.w(28),
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: AppColors.grey200,
                                                        width: Responsive.w(1),
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        Countries.getCountryByCode(_selectedCountryCode.code ?? 'EG').flag,
                                                        style: TextStyle(fontSize: Responsive.sp(20)),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: Responsive.w(8)),
                                                  // Country Code
                                                  Text(
                                                    _selectedCountryCode.dialCode ?? '+20',
                                                    style: AppFonts.AlmaraiRegular14.copyWith(
                                                      color: AppColors.textPrimary,
                                                    ),
                                                  ),
                                                  SizedBox(width: Responsive.w(8)),
                                                  // Separator
                                                  Container(
                                                    width: Responsive.w(1),
                                                    height: Responsive.h(20),
                                                    color: AppColors.grey300,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(Responsive.r(12)),
                                            borderSide: BorderSide(color: AppColors.grey300),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(Responsive.r(12)),
                                            borderSide: BorderSide(color: AppColors.grey300),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(Responsive.r(12)),
                                            borderSide: BorderSide(
                                              color: primary,
                                              width: Responsive.w(2),
                                            ),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(Responsive.r(12)),
                                            borderSide: BorderSide(color: AppColors.error),
                                          ),
                                          focusedErrorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(Responsive.r(12)),
                                            borderSide: BorderSide(
                                              color: AppColors.error,
                                              width: Responsive.w(2),
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: AppColors.grey50,
                                          contentPadding: Responsive.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'phone_required'.tr;
                                          }
                                          if (!_isValidPhone(value)) {
                                            return 'enter_valid_phone'.tr;
                                          }
                                          return null;
                                        },
                                      )
                                    else
                                       // Email Field
                                      TextFormField(
                                        controller: _emailController,
                                        keyboardType: TextInputType.emailAddress,
                                        style: AppFonts.AlmaraiRegular14,
                                        decoration: InputDecoration(
                                          labelText: 'email'.tr,
                                          labelStyle: AppFonts.AlmaraiRegular14.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                          hintText: 'enter_your_email'.tr,
                                          hintStyle: AppFonts.AlmaraiRegular12.copyWith(
                                            color: AppColors.grey400,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.email_outlined,
                                            color: primary,
                                            size: Responsive.sp(20),
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(Responsive.r(12)),
                                            borderSide: BorderSide(color: AppColors.grey300),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(Responsive.r(12)),
                                            borderSide: BorderSide(color: AppColors.grey300),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(Responsive.r(12)),
                                            borderSide: BorderSide(
                                              color: primary,
                                              width: Responsive.w(2),
                                            ),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(Responsive.r(12)),
                                            borderSide: BorderSide(color: AppColors.error),
                                          ),
                                          focusedErrorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(Responsive.r(12)),
                                            borderSide: BorderSide(
                                              color: AppColors.error,
                                              width: Responsive.w(2),
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: AppColors.grey50,
                                          contentPadding: Responsive.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'email_required'.tr;
                                          }
                                          if (!_isValidEmail(value)) {
                                            return 'enter_valid_email'.tr;
                                          }
                                          return null;
                                        },
                                      ),
                                    SizedBox(height: Responsive.h(12)),

                                // Password Field
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: !_isPasswordVisible,
                                  style: AppFonts.AlmaraiRegular14,
                                  decoration: InputDecoration(
                                    labelText: 'password'.tr,
                                    labelStyle: AppFonts.AlmaraiRegular14.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    hintText: 'password_placeholder'.tr,
                                    hintStyle: AppFonts.AlmaraiRegular12.copyWith(
                                      color: AppColors.grey400,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock_outlined,
                                      color: primary,
                                      size: Responsive.sp(20),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: primary,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible = !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(Responsive.r(12)),
                                      borderSide: BorderSide(color: AppColors.grey300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(Responsive.r(12)),
                                      borderSide: BorderSide(color: AppColors.grey300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(Responsive.r(12)),
                                      borderSide: BorderSide(
                                        color: primary,
                                        width: Responsive.w(2),
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(Responsive.r(12)),
                                      borderSide: BorderSide(color: AppColors.error),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(Responsive.r(12)),
                                      borderSide: BorderSide(
                                        color: AppColors.error,
                                        width: Responsive.w(2),
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: AppColors.grey50,
                                    contentPadding: Responsive.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'password_required'.tr;
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: Responsive.h(6)),

                                SizedBox(height: Responsive.h(12)),

                                // Login Button
                                SizedBox(
                                  width: double.infinity,
                                  height: Responsive.h(45),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.blue1,
                                      foregroundColor: Colors.white,
                                      elevation: 6,
                                      disabledBackgroundColor: AppColors.grey300,
                                      side: BorderSide(
                                        color: AppColors.blue1,
                                        width: Responsive.w(2),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(Responsive.r(12)),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                            height: Responsive.w(24),
                                            width: Responsive.w(24),
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: Responsive.w(2),
                                            ),
                                          )
                                        : Text(
                                            'login'.tr,
                                            style: AppFonts.AlmaraiBold16.copyWith(
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                                
                                if (_canCheckBiometric) ...[
                                  SizedBox(height: Responsive.h(20)),
                                  InkWell(
                                    onTap: _triggerBiometric,
                                    borderRadius: BorderRadius.circular(50),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.blue1.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.blue1.withOpacity(0.3)),
                                      ),
                                      child: Icon(
                                        Icons.fingerprint,
                                        size: 40,
                                        color: AppColors.blue1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'biometric_login'.tr,
                                    style: TextStyle(
                                      color: AppColors.blue1, 
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                                // Login with Email/Phone Toggle
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isPhoneLogin = !_isPhoneLogin;
                                    });
                                  },
                                  child: Text(
                                    _isPhoneLogin
                                        ? 'login_with_email'.tr
                                        : 'login_with_phone'.tr,
                                    style: AppFonts.AlmaraiBold14.copyWith(
                                      color: primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),


                          SizedBox(height: Responsive.h(24)),
                           Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: AppColors.grey300,
                                ),
                              ),
                              Padding(
                                padding: Responsive.symmetric(horizontal: 16),
                                child: Text(
                                  'or_continue_with'.tr,
                                  style: AppFonts.AlmaraiRegular12.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: AppColors.grey300,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: Responsive.h(24)),

                          // Google Button
                          SizedBox(
                            height: Responsive.h(45),
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : _handleGoogleLogin,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppColors.grey300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(Responsive.r(12)),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    AssetsManager.googleSvg,
                                    width: Responsive.w(24),
                                    height: Responsive.w(24),
                                  ),
                                  SizedBox(width: Responsive.w(12)),
                                  Text(
                                    'continue_with_google'.tr,
                                    style: AppFonts.AlmaraiMedium14.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          if (Platform.isIOS) ...[
                            SizedBox(height: Responsive.h(16)),
                            // Apple Button
                            SizedBox(
                              height: Responsive.h(45),
                               child: OutlinedButton(
                                onPressed: _isLoading ? null : _handleAppleLogin,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  side: BorderSide(color: Colors.black),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(Responsive.r(12)),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      AssetsManager.appleSvg,
                                      width: Responsive.w(24),
                                      height: Responsive.w(24),
                                       colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                    ),
                                    SizedBox(width: Responsive.w(12)),
                                    Text(
                                      'continue_with_apple'.tr,
                                      style: AppFonts.AlmaraiMedium14.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        SizedBox(height: Responsive.h(20)),

                        // Register Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'dont_have_account'.tr,
                              style: AppFonts.AlmaraiRegular14.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Get.toNamed(AppRoutes.register);
                              },
                              child: Text(
                                'register'.tr,
                                style: AppFonts.AlmaraiBold14.copyWith(
                                  color: primary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: Responsive.h(24)),

                        // Terms and Privacy Policy
                        Padding(
                          padding: Responsive.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  _showPolicyDialog(context, 'privacy_policy'.tr, 'privacy_policy_content'.tr);
                                },
                                child: Text(
                                  'privacy_policy'.tr,
                                  style: AppFonts.AlmaraiRegular12.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: Responsive.symmetric(horizontal: 8),
                                child: Text(
                                  '|',
                                  style: AppFonts.AlmaraiRegular12.copyWith(
                                    color: AppColors.grey400,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  _showPolicyDialog(context, 'terms_conditions'.tr, 'terms_conditions_content'.tr);
                                },
                                child: Text(
                                  'terms_conditions'.tr,
                                  style: AppFonts.AlmaraiRegular12.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: Responsive.h(40)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),      // Draggable Floating Chat Button
      Positioned(
        left: _chatButtonPosition.dx,
        top: _chatButtonPosition.dy,
        child: Draggable(
          feedback: Material(
            color: Colors.transparent,
            child: Container(
              width: Responsive.w(56),
              height: Responsive.h(56),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blue1,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blue1.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                IconlyBold.chat,
                color: Colors.white,
                size: Responsive.sp(24),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: FloatingActionButton(
              onPressed: null,
              backgroundColor: AppColors.blue1,
              elevation: 0,
              child: Icon(
                IconlyBold.chat,
                color: Colors.white,
                size: Responsive.sp(24),
              ),
            ),
          ),
          onDragEnd: (details) {
            setState(() {
              final size = MediaQuery.of(context).size;
              double newX = details.offset.dx;
              double newY = details.offset.dy;

              // Keep button within screen bounds
              newX = newX.clamp(0.0, size.width - Responsive.w(56));
              newY = newY.clamp(0.0, size.height - Responsive.h(56));

              _chatButtonPosition = Offset(newX, newY);
            });
          },
          child: FloatingActionButton(
            onPressed: () {
              Get.toNamed(AppRoutes.chatbot);
            },
            backgroundColor: AppColors.blue1,
            elevation: 6,
            child: Icon(
              IconlyBold.chat,
              color: Colors.white,
              size: Responsive.sp(24),
            ),
          ),
        ),
      ),
    ],
    ),
    );
  }


  void _showPolicyDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: AppFonts.AlmaraiBold18.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: AppFonts.AlmaraiRegular14.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'close'.tr,
              style: AppFonts.AlmaraiBold14.copyWith(
                color: AppConfigController.to.primaryColorAsColor,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Responsive.r(16)),
        ),
      ),
    );
  }
}

