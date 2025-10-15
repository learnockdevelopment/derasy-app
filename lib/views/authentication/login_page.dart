import 'dart:ui';
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

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
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

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    print('🔐 [LOGIN] LoginPage initState called');

    _identifierController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    print('🔐 [LOGIN] LoginPage dispose called');
    _identifierController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
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
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String identifier = _isEmailSelected
          ? _identifierController.text.trim()
          : '${_selectedCountry.dialCode}${_identifierController.text.trim()}';

      print('🔐 [LOGIN] Starting login process for: $identifier');

      final response = await AuthService.login(
        loginField: identifier,
        password: _passwordController.text.trim(),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
              'Login request timed out. Please check your internet connection.');
        },
      );

      print('🔐 [LOGIN] Login response received: $response');

      if (response.isEmpty) {
        throw Exception('Empty response from server');
      }

      final loginResponse = LoginResponse.fromJson(response);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      print('🔐 [LOGIN] Navigating to home page');
      Get.offAllNamed<void>(AppRoutes.home);

      Get.snackbar(
        'Success',
        loginResponse.message.isNotEmpty
            ? loginResponse.message
            : 'Login successful',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
    } catch (e) {
      print('🔐 [LOGIN] Login error: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      String errorMessage = 'An unexpected error occurred. Please try again.';

      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Invalid response from server. Please try again.';
      } else if (e.toString().contains('Invalid credentials')) {
        errorMessage = 'Invalid email or password. Please try again.';
      } else if (e.toString().contains('User is banned')) {
        errorMessage =
            'Your account has been suspended. Please contact support.';
      } else if (e.toString().isNotEmpty) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      Get.snackbar(
        'Error',
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
    print('🔐 [LOGIN] LoginPage build called');

    return Scaffold(
      body: Stack(
        children: [
          // Blurred background image
          _buildBlurredBackground(),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                child: FadeTransition(
                  opacity: _animationController,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Login form
                      _buildLoginForm(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurredBackground() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AssetsManager.login),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.black.withOpacity(0.2),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Title
            Text(
              'Welcome Back',
              style: AppFonts.robotoBold24.copyWith(
                color: AppColors.textPrimary,
                fontSize: 24.sp,
              ),
            ),

            SizedBox(height: 4.h),

            Text(
              'Sign in to continue',
              style: AppFonts.robotoRegular16.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14.sp,
              ),
            ),

            SizedBox(height: 20.h),

            // Login Method Selector with Icons
            _buildMethodSelector(),

            SizedBox(height: 20.h),

            // Identifier Field
            _isEmailSelected ? _buildEmailField() : _buildPhoneField(),

            SizedBox(height: 16.h),

            // Password Field
            _buildPasswordField(),

            SizedBox(height: 24.h),

            // Login Button
            _buildLoginButton(),

            SizedBox(height: 20.h),

            // Forgot Password & Sign Up
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(
          color: AppColors.grey200,
          width: 1,
        ),
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color:
                      _isEmailSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Icon(
                  Icons.email_outlined,
                  color:
                      _isEmailSelected ? Colors.white : AppColors.textSecondary,
                  size: 24.w,
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: !_isEmailSelected
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Icon(
                  Icons.phone_outlined,
                  color: !_isEmailSelected
                      ? Colors.white
                      : AppColors.textSecondary,
                  size: 24.w,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.grey200,
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: _identifierController,
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Email is required';
          }
          if (!_isValidEmail(value)) {
            return 'Please enter a valid email';
          }
          return null;
        },
        style: AppFonts.robotoRegular16.copyWith(
          color: AppColors.textPrimary,
          fontSize: 16.sp,
        ),
        decoration: InputDecoration(
          hintText: 'Enter your email',
          hintStyle: AppFonts.robotoRegular14.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14.sp,
          ),
          prefixIcon: Icon(
            Icons.email_outlined,
            color: AppColors.primary,
            size: 20.w,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Row(
      children: [
        // Country Selector
        GestureDetector(
          onTap: () => _showCountrySelector(),
          child: Container(
            width: 80.w,
            height: 50.h,
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(12.r),
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
                        fontSize: 12.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
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
            height: 50.h,
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(12.r),
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
                  return 'Phone number is required';
                }
                if (!_isValidPhone(value)) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
              style: AppFonts.robotoRegular16.copyWith(
                color: AppColors.textPrimary,
                fontSize: 16.sp,
              ),
              decoration: InputDecoration(
                hintText: 'Enter phone number',
                hintStyle: AppFonts.robotoRegular14.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14.sp,
                ),
                prefixIcon: Icon(
                  Icons.phone_outlined,
                  color: AppColors.primary,
                  size: 20.w,
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
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey50,
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
            return 'Password is required';
          }
          if (value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
        style: AppFonts.robotoRegular16.copyWith(
          color: AppColors.textPrimary,
          fontSize: 16.sp,
        ),
        decoration: InputDecoration(
          hintText: 'Enter your password',
          hintStyle: AppFonts.robotoRegular14.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14.sp,
          ),
          prefixIcon: Icon(
            Icons.lock_outline,
            color: AppColors.primary,
            size: 20.w,
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
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 50.h,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: (_isLoading || !_isIdentifierValid) ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: 24.w,
                height: 24.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Sign In',
                style: AppFonts.robotoBold16.copyWith(
                  color: Colors.white,
                  fontSize: 18.sp,
                ),
              ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Forgot Password
        GestureDetector(
          onTap: () => Get.toNamed<void>(AppRoutes.otpEmail),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.blue50,
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Text(
              'Forgot Password?',
              style: AppFonts.robotoMedium12.copyWith(
                color: AppColors.primary,
                fontSize: 12.sp,
              ),
            ),
          ),
        ),

        // Sign Up
        GestureDetector(
          onTap: () => Get.toNamed<void>(AppRoutes.register),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Text(
              'Sign Up',
              style: AppFonts.robotoBold12.copyWith(
                color: Colors.white,
                fontSize: 12.sp,
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
