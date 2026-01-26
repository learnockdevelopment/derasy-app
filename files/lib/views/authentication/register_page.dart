import 'package:flutter/material.dart';

import 'package:get/get.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:country_code_picker/country_code_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/assets.dart';
import '../../core/constants/countries.dart';
import '../../core/routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../models/auth_models.dart';
import '../../core/controllers/app_config_controller.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/user_storage_service.dart';
import 'dart:io' show Platform;

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String _passwordStrength = '';
  String _selectedRole = 'parent'; // Default to parent
  CountryCode _selectedCountryCode = CountryCode(name: 'Egypt', code: 'EG', dialCode: '+20');
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);

    // Add listeners to all text fields to trigger UI updates
    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);

    // Initialize animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    final password = _passwordController.text;
    setState(() {
      _passwordStrength = _calculatePasswordStrength(password);
    });
  }

  void _validateForm() {
    setState(() {});
  }

  String _calculatePasswordStrength(String password) {
    if (password.isEmpty) return '';
    if (password.length < 6) return 'weak';
    if (password.length < 8) return 'medium';
    if (password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]'))) {
      return 'strong';
    }
    return 'medium';
  }

  Color _getPasswordStrengthColor() {
    switch (_passwordStrength) {
      case 'weak':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'strong':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  bool _isFormValid() {
    final isValid = _nameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _isValidEmail(_emailController.text) &&
        _passwordController.text == _confirmPasswordController.text;

    print('🔐 [REGISTER] Form validation: $isValid');
    print('🔐 [REGISTER] Name: ${_nameController.text.isNotEmpty}');
    print('🔐 [REGISTER] Email: ${_emailController.text.isNotEmpty}');
    print('🔐 [REGISTER] Password: ${_passwordController.text.isNotEmpty}');
    print(
        '🔐 [REGISTER] Confirm: ${_confirmPasswordController.text.isNotEmpty}');
    print('🔐 [REGISTER] Valid email: ${_isValidEmail(_emailController.text)}');
    print(
        '🔐 [REGISTER] Passwords match: ${_passwordController.text == _confirmPasswordController.text}');

    return isValid;
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
                                      style: AppFonts.AlmaraiRegular12.copyWith(
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

  Future<void> _register() async {
    print('🔐 [REGISTER] Register button pressed');
    if (!_formKey.currentState!.validate()) {
      print('🔐 [REGISTER] Form validation failed');
      return;
    }
    if (_isLoading || !_isFormValid()) {
      print('🔐 [REGISTER] Form not valid or loading');
      return;
    }

    print('🔐 [REGISTER] Starting registration process');
    setState(() {
      _isLoading = true;
    });

    try {
      final request = RegisterRequest(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: _selectedRole,
      );

      final response = await AuthService.register(request);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Navigate to email verification page
      Get.toNamed(AppRoutes.verifyEmail, arguments: {
        'email': _emailController.text.trim(),
      });

      Get.snackbar(
        'success'.tr,
        response.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.blue1,
        colorText: Colors.white,
      );
    } catch (e) {
      print('🔐 [REGISTER] Registration error: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      String errorMessage = 'unexpected_error_try_again'.tr;

      if (e is AuthException) {
        errorMessage = e.message;
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        errorMessage = 'network_error_check_connection'.tr;
      }

      Get.snackbar(
        'error'.tr,
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
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
        // User canceled the sign-in
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

      // Check user role - only allow student or parent
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
        // Assuming DashboardController is available globally or injected
         // DashboardController.to.refreshAll();
      } catch (e) {
        print('📊 [LOGIN] Error triggering pre-fetch: $e');
      }

      // Navigate to home
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

      // Check user role - only allow student or parent
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
      
        // Navigate to home
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
        body: SafeArea(
            child: Column(children: [
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
          Expanded(
              child: SingleChildScrollView(
            child: Padding(
              padding: Responsive.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Logo
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Image.asset(
                      AssetsManager.login,
                      width: Responsive.w(70),
                      height: Responsive.w(70),
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
                          'create_account'.tr,
                          style: AppFonts.AlmaraiBold20.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: Responsive.h(6)),
                        Text(
                          'register_intro'.tr,
                          style: AppFonts.AlmaraiRegular12.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: Responsive.h(24)),

                  // Form Fields
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                              TextFormField(
                                controller: _nameController,
                                style: AppFonts.AlmaraiRegular14,
                                decoration: InputDecoration(
                                  labelText: 'full_name'.tr,
                                  labelStyle: AppFonts.AlmaraiRegular14,
                                  hintText: 'enter_full_name'.tr,
                                  hintStyle:
                                      AppFonts.AlmaraiRegular12.copyWith(
                                    color: AppColors.grey400,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.person_outlined,
                                    color: AppColors.blue1,
                                    size: Responsive.sp(20),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(Responsive.r(12)),
                                    borderSide:
                                        BorderSide(color: AppColors.grey300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(Responsive.r(12)),
                                    borderSide: BorderSide(
                                      color: AppColors.blue1,
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
                                return 'name_required'.tr;
                              }
                              if (value.length < 2) {
                                return 'name_min_length'.tr;
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: Responsive.h(16)),

                          // Phone Field with Flag and Country Code
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: AppFonts.AlmaraiRegular14,
                              decoration: InputDecoration(
                                labelText: 'phone_number'.tr,
                                labelStyle: AppFonts.AlmaraiRegular14,
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
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(Responsive.r(12)),
                                  borderSide: BorderSide(
                                    color: AppColors.blue1,
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
                                return 'phone_required'.tr;
                              }
                              if (value.replaceAll(RegExp(r'[\s-]'), '').length < 8) {
                                return 'enter_valid_phone'.tr;
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: Responsive.h(12)),

                          // Role Selection Dropdown
                          Container(
                            padding: Responsive.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.grey50,
                              borderRadius: BorderRadius.circular(Responsive.r(12)),
                              border: Border.all(
                                color: AppColors.grey300,
                              ),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedRole,
                              decoration: InputDecoration(
                                labelText: 'role'.tr,
                                labelStyle: AppFonts.AlmaraiRegular14,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: AppColors.blue1,
                                  size: Responsive.sp(20),
                                ),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'parent',
                                  child: Text('parent'.tr, style: AppFonts.AlmaraiRegular14),
                                ),
                                DropdownMenuItem(
                                  value: 'student',
                                  child: Text('student'.tr, style: AppFonts.AlmaraiRegular14),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedRole = value;
                                  });
                                }
                              },
                            ),
                          ),
                          SizedBox(height: Responsive.h(12)),

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: AppFonts.AlmaraiRegular14,
                            decoration: InputDecoration(
                              labelText: 'email'.tr,
                              labelStyle: AppFonts.AlmaraiRegular14,
                              hintText: 'enter_your_email'.tr,
                              hintStyle:
                                  AppFonts.AlmaraiRegular12.copyWith(
                                color: AppColors.grey400,
                              ),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: AppColors.blue1,
                                size: Responsive.sp(20),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(Responsive.r(12)),
                                borderSide:
                                    BorderSide(color: AppColors.grey300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(Responsive.r(12)),
                                borderSide: BorderSide(
                                  color: AppColors.blue1,
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
                              labelStyle: AppFonts.AlmaraiRegular14,
                              hintText: 'password_placeholder'.tr,
                              hintStyle:
                                  AppFonts.AlmaraiRegular12.copyWith(
                                color: AppColors.grey400,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outlined,
                                color: AppColors.blue1,
                                size: Responsive.sp(20),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppColors.blue1,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(Responsive.r(12)),
                                borderSide:
                                    BorderSide(color: AppColors.grey300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(Responsive.r(12)),
                                borderSide: BorderSide(
                                  color: AppColors.blue1,
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
                              if (value.length < 6) {
                                return 'password_too_short'.tr;
                              }
                              return null;
                            },
                          ),
                          if (_passwordStrength.isNotEmpty) ...[
                            SizedBox(height: Responsive.h(12)),
                             Container(
                               padding: Responsive.all(12),
                               decoration: BoxDecoration(
                                 color: _getPasswordStrengthColor()
                                     .withOpacity(0.1),
                                 borderRadius: BorderRadius.circular(Responsive.r(8)),
                                 border: Border.all(
                                   color: _getPasswordStrengthColor()
                                       .withOpacity(0.3),
                                 ),
                               ),
                               child: Row(
                                 children: [
                                   Icon(
                                     Icons.security,
                                     color: _getPasswordStrengthColor(),
                                     size: Responsive.sp(16),
                                   ),
                                   SizedBox(width: Responsive.w(8)),
                                   Text(
                                     'password_strength_label'.tr,
                                     style: AppFonts.AlmaraiRegular12
                                         .copyWith(
                                       color: AppColors.textSecondary,
                                     ),
                                   ),
                                   Text(
                                     _passwordStrength.tr,
                                     style:
                                         AppFonts.AlmaraiBold12.copyWith(
                                       color: _getPasswordStrengthColor(),
                                     ),
                                   ),
                                 ],
                               ),
                             ),
                          ],
                          SizedBox(height: Responsive.h(16)),

                          // Confirm Password Field
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: !_isConfirmPasswordVisible,
                            style: AppFonts.AlmaraiRegular14,
                            decoration: InputDecoration(
                              labelText: 'confirm_password'.tr,
                              labelStyle: AppFonts.AlmaraiRegular14,
                              hintText: 're_enter_password'.tr,
                              hintStyle:
                                  AppFonts.AlmaraiRegular12.copyWith(
                                color: AppColors.grey400,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outlined,
                                color: AppColors.blue1,
                                size: Responsive.sp(20),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isConfirmPasswordVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppColors.blue1,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isConfirmPasswordVisible =
                                        !_isConfirmPasswordVisible;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(Responsive.r(12)),
                                borderSide:
                                    BorderSide(color: AppColors.grey300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(Responsive.r(12)),
                                borderSide: BorderSide(
                                  color: AppColors.blue1,
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
                                return 'confirm_password_prompt'.tr;
                              }
                              if (value != _passwordController.text) {
                                return 'passwords_no_match'.tr;
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: Responsive.h(20)),

                          // Register Button
                          SizedBox(
                            height: Responsive.h(50),
                            child: ElevatedButton(
                              onPressed: _isFormValid() && !_isLoading
                                  ? () {
                                      _register();
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.blue1,
                                disabledBackgroundColor: AppColors.grey300,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(Responsive.r(12)),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: Responsive.h(20),
                                      width: Responsive.w(20),
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.person_add,
                                          color: Colors.white,
                                          size: Responsive.sp(18),
                                        ),
                                        SizedBox(width: Responsive.w(8)),
                                        Text(
                                          'create_account'.tr,
                                          style: AppFonts.AlmaraiBold16
                                              .copyWith(
                                            color: Colors.white,
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
                            height: Responsive.h(50),
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
                              height: Responsive.h(50),
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
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ))
        ])));
  }
}

