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

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  Country _selectedCountry = Countries.countries.firstWhere(
    (country) => country.code == 'EG',
    orElse: () => Countries.countries.first,
  );

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    print('📝 [REGISTER] RegisterPage initState called');

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    print('📝 [REGISTER] RegisterPage dispose called');
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _validateForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final email = _emailController.text.trim();
      final phone =
          '${_selectedCountry.dialCode}${_phoneController.text.trim()}';

      try {
        final response = await AuthService.register(
          firstName: _nameController.text.trim().split(' ').first,
          lastName: _nameController.text.trim().split(' ').length > 1
              ? _nameController.text.trim().split(' ').skip(1).join(' ')
              : '',
          email: email,
          phone: phone,
          password: _passwordController.text.trim(),
          role: 'user', // Default role
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception(
                'Registration request timed out. Please check your internet connection.');
          },
        );

        print('📝 [REGISTER] Registration response received: $response');

        if (response.isEmpty) {
          throw Exception('Empty response from server');
        }

        final registerResponse = RegisterResponse.fromJson(response);

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        print('📝 [REGISTER] Navigating to email verification');

        // Navigate to email verification
        Get.offNamed<void>(
          AppRoutes.verifyEmail,
          arguments: {
            'userId': registerResponse.data.id,
            'email': email,
          },
        );

        Get.snackbar(
          'Success',
          'Registration successful! Please verify your email address.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primary,
          colorText: Colors.white,
        );
      } catch (e) {
        print('📝 [REGISTER] Registration error: $e');

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        String errorMessage = 'An unexpected error occurred. Please try again.';

        if (e.toString().contains('SocketException') ||
            e.toString().contains('TimeoutException')) {
          errorMessage =
              'Network error. Please check your internet connection.';
        } else if (e.toString().contains('FormatException')) {
          errorMessage = 'Invalid response from server. Please try again.';
        } else if (e.toString().contains('Email already exists')) {
          errorMessage = 'An account with this email already exists.';
        } else if (e.toString().contains('Phone already exists')) {
          errorMessage = 'An account with this phone number already exists.';
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildBackground(),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
              child: FadeTransition(
                opacity: _animationController,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildRegisterForm(),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
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

  Widget _buildRegisterForm() {
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
            Text(
              'Create Account',
              style: AppFonts.robotoBold24.copyWith(
                color: AppColors.textPrimary,
                fontSize: 24.sp,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Sign up to get started',
              style: AppFonts.robotoRegular16.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 20.h),
            _buildNameField(),
            SizedBox(height: 20.h),
            _buildEmailField(),
            SizedBox(height: 20.h),
            _buildPhoneField(),
            SizedBox(height: 16.h),
            _buildPasswordField(),
            SizedBox(height: 16.h),
            _buildConfirmPasswordField(),
            SizedBox(height: 24.h),
            _buildRegisterButton(),
            SizedBox(height: 20.h),
            _buildLoginLink(),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      keyboardType: TextInputType.name,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: 'Full Name',
        hintText: 'Enter your full name',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your full name';
        }
        if (value.length < 2) {
          return 'Name must be at least 2 characters long';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Email Address',
        hintText: 'Enter your email',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Email is required';
        }
        if (!GetUtils.isEmail(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return Row(
      children: [
        GestureDetector(
          onTap: _showCountryPicker,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Text(
              _selectedCountry.dialCode,
              style: AppFonts.robotoMedium16.copyWith(fontSize: 16.sp),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: 'Enter your phone number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primary),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Phone number is required';
              }
              if (value.length < 7) {
                return 'Phone number must be at least 7 digits';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: AppColors.textSecondary,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Password is required';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters long';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: !_isConfirmPasswordVisible,
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        hintText: 'Re-enter your password',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        prefixIcon: Icon(Icons.lock_reset, color: AppColors.primary),
        suffixIcon: IconButton(
          icon: Icon(
            _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: AppColors.textSecondary,
          ),
          onPressed: () {
            setState(() {
              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your password';
        }
        if (value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildRegisterButton() {
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
        onPressed: _isLoading ? null : _validateForm,
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
                'Sign Up',
                style: AppFonts.robotoBold16.copyWith(
                  color: Colors.white,
                  fontSize: 18.sp,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account?',
          style: AppFonts.robotoRegular14.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14.sp,
          ),
        ),
        SizedBox(width: 5.w),
        GestureDetector(
          onTap: () => Get.offNamed<void>(AppRoutes.login),
          child: Text(
            'Login',
            style: AppFonts.robotoBold14.copyWith(
              color: AppColors.primary,
              fontSize: 14.sp,
            ),
          ),
        ),
      ],
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 400.h,
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            Text(
              'Select Country',
              style: AppFonts.robotoBold20.copyWith(
                color: AppColors.textPrimary,
                fontSize: 20.sp,
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: ListView.builder(
                itemCount: Countries.countries.length,
                itemBuilder: (context, index) {
                  final country = Countries.countries[index];
                  return ListTile(
                    leading: Text(
                      country.flag,
                      style: TextStyle(fontSize: 24.sp),
                    ),
                    title: Text(
                      country.name,
                      style: AppFonts.robotoMedium16.copyWith(fontSize: 16.sp),
                    ),
                    subtitle: Text(
                      country.dialCode,
                      style: AppFonts.robotoRegular14.copyWith(fontSize: 14.sp),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedCountry = country;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
