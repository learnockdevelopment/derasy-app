import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:country_code_picker/country_code_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/assets.dart';
import '../../core/constants/countries.dart';
import '../../core/routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../models/auth_models.dart';
import '../../core/controllers/app_config_controller.dart';

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
                topLeft: Radius.circular(24.r),
                topRight: Radius.circular(24.r),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.grey200, width: 1),
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
                  padding: EdgeInsets.all(16.w),
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
                            size: 22.sp,
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
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Countries List
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
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
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          margin: EdgeInsets.only(bottom: 4.h),
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: isSelected ? primary.withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10.r),
                            border: isSelected
                                ? Border.all(color: primary, width: 1.5)
                                : Border.all(color: AppColors.grey200, width: 1),
                          ),
                          child: Row(
                            children: [
                              // Flag
                              Container(
                                width: 32.w,
                                height: 32.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.grey200,
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    country.flag,
                                    style: TextStyle(fontSize: 20.sp),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
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
                                    SizedBox(height: 2.h),
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
                                  size: 20.sp,
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
        backgroundColor: AppColors.primaryBlue,
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

  @override
  Widget build(BuildContext context) {
    final primary = AppConfigController.to.primaryColorAsColor;

    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: Column(children: [
          // Top Bar with Back Button and Language Selector
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(
                    Icons.arrow_back,
                    color: AppColors.textPrimary,
                    size: 20.sp,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
                  // Language Button (toggle)
                  InkWell(
                    borderRadius: BorderRadius.circular(6.r),
                    onTap: () {
                      final isAr = Get.locale?.languageCode == 'ar';
                      Get.updateLocale(isAr ? const Locale('en', 'US') : const Locale('ar', 'SA'));
                      setState(() {});
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.language,
                            color: primary,
                            size: 18.sp,
                          ),
                          SizedBox(width: 3.w),
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
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                children: [
                  // Logo
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Image.asset(
                      AssetsManager.logo,
                      width: 70.w,
                      height: 70.w,
                      fit: BoxFit.contain,
                    ),
                  ),

                  SizedBox(height: 20.h),

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
                        SizedBox(height: 6.h),
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

                  SizedBox(height: 24.h),

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
                                color: AppColors.primaryBlue,
                                size: 20.sp,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide:
                                    BorderSide(color: AppColors.grey300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide(
                                  color: AppColors.primaryBlue,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: AppColors.grey50,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 16.h,
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
                          SizedBox(height: 16.h),

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
                                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Flag - using emoji from Countries
                                      Container(
                                        width: 28.w,
                                        height: 28.w,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.grey200,
                                            width: 1,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            Countries.getCountryByCode(_selectedCountryCode.code ?? 'EG').flag,
                                            style: TextStyle(fontSize: 20.sp),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      // Country Code
                                      Text(
                                        _selectedCountryCode.dialCode ?? '+20',
                                        style: AppFonts.AlmaraiRegular14.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      // Separator
                                      Container(
                                        width: 1,
                                        height: 20.h,
                                        color: AppColors.grey300,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide(color: AppColors.grey300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide(
                                  color: AppColors.primaryBlue,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: AppColors.grey50,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 16.h,
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
                          SizedBox(height: 12.h),

                          // Role Selection Dropdown
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            decoration: BoxDecoration(
                              color: AppColors.grey50,
                              borderRadius: BorderRadius.circular(12.r),
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
                                  color: AppColors.primaryBlue,
                                  size: 20.sp,
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
                          SizedBox(height: 12.h),

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
                                color: AppColors.primaryBlue,
                                size: 20.sp,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide:
                                    BorderSide(color: AppColors.grey300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide(
                                  color: AppColors.primaryBlue,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: AppColors.grey50,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 16.h,
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
                          SizedBox(height: 12.h),

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
                                color: AppColors.primaryBlue,
                                size: 20.sp,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppColors.primaryBlue,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide:
                                    BorderSide(color: AppColors.grey300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide(
                                  color: AppColors.primaryBlue,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: AppColors.grey50,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 16.h,
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
                            SizedBox(height: 12.h),
                            Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: _getPasswordStrengthColor()
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8.r),
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
                                    size: 16.sp,
                                  ),
                                  SizedBox(width: 8.w),
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
                          SizedBox(height: 16.h),

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
                                color: AppColors.primaryBlue,
                                size: 20.sp,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isConfirmPasswordVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppColors.primaryBlue,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isConfirmPasswordVisible =
                                        !_isConfirmPasswordVisible;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide:
                                    BorderSide(color: AppColors.grey300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide(
                                  color: AppColors.primaryBlue,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: AppColors.grey50,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 16.h,
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
                          SizedBox(height: 20.h),

                          // Register Button
                          SizedBox(
                            height: 50.h,
                            child: ElevatedButton(
                              onPressed: _isFormValid() && !_isLoading
                                  ? () {
                                      _register();
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                disabledBackgroundColor: AppColors.grey300,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 20.h,
                                      width: 20.w,
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
                                          size: 18.sp,
                                        ),
                                        SizedBox(width: 8.w),
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
                          SizedBox(height: 20.h),
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
