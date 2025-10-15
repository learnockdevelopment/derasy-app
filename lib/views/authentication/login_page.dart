import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/assets.dart';
import '../../core/constants/countries.dart';
import '../../core/routes/app_routes.dart';
import '../../services/authentication/auth_service.dart';
import '../../models/authentication/auth_models.dart';
import '../../views/widgets/country_selector.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isEmailSelected = true;
  bool _isIdentifierValid = false;
  Country _selectedCountry = Countries.countries.firstWhere(
    (country) => country.code == 'EG',
    orElse: () => Countries.countries.first,
  );

  @override
  void initState() {
    super.initState();
    _identifierController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _isIdentifierValid =
          _isValidIdentifier(identifier) && password.isNotEmpty;
    });
  }

  bool _isValidIdentifier(String identifier) {
    if (identifier.isEmpty) return false;
    if (_isEmailSelected) {
      return _isValidEmail(identifier);
    } else {
      return _isValidPhone(identifier);
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^[0-9]+$').hasMatch(phone) && phone.length >= 7;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String identifier = _isEmailSelected
          ? _identifierController.text.trim()
          : '${_selectedCountry.dialCode}${_identifierController.text.trim()}';

      final response = await AuthService.login(
        email: identifier,
        password: _passwordController.text.trim(),
      );

      final loginResponse = LoginResponse.fromJson(response);

      setState(() {
        _isLoading = false;
      });

      // Navigate to home page after successful login
      Get.offAllNamed<void>(AppRoutes.home);

      Get.snackbar(
        'success'.tr,
        loginResponse.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFF8F9FF),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20.h),

                  // Header with logo and company name
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(
                            AssetsManager.logo,
                            width: 60.w,
                            height: 60.h,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'app_name'.tr,
                          style: AppFonts.robotoBold24.copyWith(
                            color: AppColors.primary,
                            fontSize: 28.sp,
                          ),
                        ),
                        Text(
                          'app_tagline'.tr,
                          style: AppFonts.robotoRegular16.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Login title
                  Text(
                    'login_to_your_account'.tr,
                    style: AppFonts.robotoBold24.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),

                  SizedBox(height: 8.h),

                  // Welcome message
                  Text(
                    'welcome_back'.tr,
                    style: AppFonts.robotoBold24.copyWith(
                      color: AppColors.primary,
                      fontSize: 28.sp,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'sign_in_to_continue'.tr,
                    style: AppFonts.robotoRegular16.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 16.sp,
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // Login Method Selector
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isEmailSelected = true;
                                _identifierController.clear();
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              decoration: BoxDecoration(
                                color: _isEmailSelected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: Text(
                                'email'.tr,
                                textAlign: TextAlign.center,
                                style: AppFonts.robotoMedium14.copyWith(
                                  color: _isEmailSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isEmailSelected = false;
                                _identifierController.clear();
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              decoration: BoxDecoration(
                                color: !_isEmailSelected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: Text(
                                'phone'.tr,
                                textAlign: TextAlign.center,
                                style: AppFonts.robotoMedium14.copyWith(
                                  color: !_isEmailSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Identifier Field
                  _isEmailSelected
                      ? _buildTextField(
                          controller: _identifierController,
                          label: 'email'.tr,
                          hint: 'enter_your_email'.tr,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'email_required'.tr;
                            }
                            if (!_isValidEmail(value)) {
                              return 'email_invalid'.tr;
                            }
                            return null;
                          },
                        )
                      : _buildPhoneField(),

                  SizedBox(height: 24.h),

                  // Password Field
                  _buildPasswordField(),

                  SizedBox(height: 32.h),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed:
                          (_isLoading || !_isIdentifierValid) ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.r),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 24.w,
                              height: 24.h,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'sign_in'.tr,
                              style: AppFonts.robotoBold16,
                            ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Forgot Password Link
                  Center(
                    child: GestureDetector(
                      onTap: () => Get.toNamed<void>(AppRoutes.forgotPassword),
                      child: Text(
                        'forgot_password'.tr,
                        style: AppFonts.robotoBold14.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Terms and Conditions
                  Center(
                    child: Text(
                      'terms_and_conditions'.tr,
                      style: AppFonts.robotoRegular12.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Register Link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'dont_have_account'.tr,
                          style: AppFonts.robotoRegular14.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Get.toNamed<void>(AppRoutes.register),
                          child: Text(
                            'sign_up'.tr,
                            style: AppFonts.robotoBold14.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppFonts.robotoMedium14.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: AppFonts.robotoRegular16.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppFonts.robotoRegular14.copyWith(
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: AppColors.grey100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: AppColors.error,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'phone_number'.tr,
          style: AppFonts.robotoMedium14.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            // Country Selector
            GestureDetector(
              onTap: () => _showCountrySelector(),
              child: Container(
                width: 90.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: AppColors.grey200,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _selectedCountry.flag,
                        style: TextStyle(fontSize: 16.sp),
                      ),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          _selectedCountry.dialCode,
                          style: AppFonts.robotoMedium12.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                        size: 14.w,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(width: 12.w),

            // Phone Number Field
            Expanded(
              child: Container(
                height: 48.h,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: AppColors.grey200,
                    width: 1,
                  ),
                ),
                child: TextFormField(
                  controller: _identifierController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'phone_required'.tr;
                    }
                    if (!_isValidPhone(value)) {
                      return 'phone_invalid'.tr;
                    }
                    return null;
                  },
                  style: AppFonts.robotoRegular16.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'phone_placeholder'.tr,
                    hintStyle: AppFonts.robotoRegular14.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'password'.tr,
          style: AppFonts.robotoMedium14.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          height: 48.h,
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.grey200,
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'password_required'.tr;
              }
              if (value.length < 6) {
                return 'password_too_short'.tr;
              }
              return null;
            },
            style: AppFonts.robotoRegular16.copyWith(
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'enter_your_password'.tr,
              hintStyle: AppFonts.robotoRegular14.copyWith(
                color: AppColors.textSecondary,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
              suffixIcon: GestureDetector(
                onTap: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
                child: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: AppColors.textSecondary,
                  size: 20.w,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCountrySelector() {
    showDialog<void>(
      context: context,
      builder: (context) => CountrySelector(
        selectedCountry: _selectedCountry,
        onCountrySelected: (country) {
          setState(() {
            _selectedCountry = country;
          });
        },
      ),
    );
  }
}
