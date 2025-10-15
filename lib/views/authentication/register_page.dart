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

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isFormValid = false;
  bool _isPasswordVisible = false;
  Country _selectedCountry = Countries.countries.firstWhere(
    (country) => country.code == 'EG',
    orElse: () => Countries.countries.first,
  );

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(_validateForm);
    _lastNameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _phoneController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _isFormValid = _isValidName(firstName) &&
          _isValidName(lastName) &&
          _isValidEmail(email) &&
          _isValidPhone(phone) &&
          _isValidPassword(password);
    });
  }

  bool _isValidName(String name) {
    if (name.isEmpty) return false;
    // Name should not contain numbers
    return !RegExp(r'[0-9]').hasMatch(name);
  }

  bool _isValidEmail(String email) {
    if (email.isEmpty) return false;
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    if (phone.isEmpty) return false;
    // Phone should contain only numbers
    return RegExp(r'^[0-9]+$').hasMatch(phone) && phone.length >= 7;
  }

  bool _isValidPassword(String password) {
    if (password.isEmpty) return false;
    return password.length >= 6;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthService.register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: '${_selectedCountry.dialCode}${_phoneController.text.trim()}',
        password: _passwordController.text.trim(),
        role: 'student',
      );

      final registerResponse = RegisterResponse.fromJson(response);

      setState(() {
        _isLoading = false;
      });

      // Navigate to home page after successful registration
      Get.offAllNamed<void>(AppRoutes.home);

      Get.snackbar(
        'success'.tr,
        registerResponse.message,
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with logo and company name
                    Padding(
                      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 20.h),
                      child: Center(
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
                    ),

                    SizedBox(height: 20.h),

                    // Create Account title
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Text(
                        'sign_up'.tr,
                        style: AppFonts.robotoBold28.copyWith(
                          color: AppColors.primary,
                          fontSize: 32.sp,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Text(
                        'nursery_description'.tr,
                        style: AppFonts.robotoRegular16.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Form content
                    Padding(
                      padding: EdgeInsets.all(24.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // First Name Field
                          _buildTextField(
                            controller: _firstNameController,
                            label: 'first_name'.tr,
                            hint: 'your_first_name'.tr,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'first_name_required'.tr;
                              }
                              if (!_isValidName(value)) {
                                return 'name_no_numbers'.tr;
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 24.h),

                          // Last Name Field
                          _buildTextField(
                            controller: _lastNameController,
                            label: 'last_name'.tr,
                            hint: 'your_last_name'.tr,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'last_name_required'.tr;
                              }
                              if (!_isValidName(value)) {
                                return 'name_no_numbers'.tr;
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 24.h),

                          // Phone Number Field with Country Selector
                          Column(
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
                                        borderRadius:
                                            BorderRadius.circular(24.r),
                                        border: Border.all(
                                          color: AppColors.grey200,
                                          width: 1,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8.w),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              _selectedCountry.flag,
                                              style: TextStyle(fontSize: 16.sp),
                                            ),
                                            SizedBox(width: 4.w),
                                            Flexible(
                                              child: Text(
                                                _selectedCountry.dialCode,
                                                style: AppFonts.robotoMedium12
                                                    .copyWith(
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
                                        borderRadius:
                                            BorderRadius.circular(24.r),
                                        border: Border.all(
                                          color: AppColors.grey200,
                                          width: 1,
                                        ),
                                      ),
                                      child: TextFormField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
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
                                        style:
                                            AppFonts.robotoRegular16.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'phone_placeholder'.tr,
                                          hintStyle:
                                              AppFonts.robotoRegular14.copyWith(
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
                          ),

                          SizedBox(height: 24.h),

                          // Email Field
                          _buildTextField(
                            controller: _emailController,
                            label: 'email'.tr,
                            hint: 'email_placeholder'.tr,
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
                          ),

                          SizedBox(height: 24.h),

                          // Password Field
                          _buildPasswordField(),

                          SizedBox(height: 48.h),

                          // Sign Up Button
                          SizedBox(
                            width: double.infinity,
                            height: 48.h,
                            child: ElevatedButton(
                              onPressed: (_isLoading || !_isFormValid)
                                  ? null
                                  : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24.r),
                                ),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 24.w,
                                      height: 24.h,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'sign_up'.tr,
                                      style: AppFonts.robotoBold16,
                                    ),
                            ),
                          ),

                          SizedBox(height: 32.h),

                          // Login Link
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'already_have_account'.tr,
                                  style: AppFonts.robotoRegular14.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      Get.toNamed<void>(AppRoutes.login),
                                  child: Text(
                                    'login'.tr,
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
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  void _showCountrySelector() {
    showDialog<void>(
      context: context,
      builder: (context) => CountrySelector(
        selectedCountry: _selectedCountry,
        onCountrySelected: (country) {
          setState(() {
            _selectedCountry = country;
            _validateForm();
          });
        },
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
        Container(
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
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
            ),
          ),
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
            borderRadius: BorderRadius.circular(24.r),
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
              hintText: 'password_placeholder'.tr,
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
}
