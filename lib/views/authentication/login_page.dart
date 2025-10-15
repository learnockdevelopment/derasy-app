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
  late AnimationController _floatingAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    _identifierController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _floatingAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _floatingAnimation = Tween<double>(
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _floatingAnimationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _floatingAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    _floatingAnimationController.dispose();
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.lightBlue50,
              AppColors.blue100,
              AppColors.purple100,
              AppColors.pink100,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Stack(
              children: [
                // Animated background shapes
                _buildAnimatedBackground(),

                // Main content
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        SizedBox(height: 40.h),

                        // Animated header
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _slideAnimation.value),
                              child: Opacity(
                                opacity: _fadeAnimation.value,
                                child: _buildHeader(),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: 40.h),

                        // Login card
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _slideAnimation.value * 0.5),
                              child: Opacity(
                                opacity: _fadeAnimation.value,
                                child: _buildLoginCard(),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: 30.h),

                        // Additional options
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _slideAnimation.value * 0.3),
                              child: Opacity(
                                opacity: _fadeAnimation.value,
                                child: _buildAdditionalOptions(),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Floating circles
            Positioned(
              top: 100.h + _floatingAnimation.value,
              right: 20.w,
              child: Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.orange300.withOpacity(0.3),
                      AppColors.orange500.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 200.h - _floatingAnimation.value,
              left: 10.w,
              child: Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.green300.withOpacity(0.3),
                      AppColors.green500.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 300.h + _floatingAnimation.value * 0.5,
              right: 30.w,
              child: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.purple300.withOpacity(0.3),
                      AppColors.purple500.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 500.h - _floatingAnimation.value * 0.7,
              left: 20.w,
              child: Container(
                width: 70.w,
                height: 70.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.blue300.withOpacity(0.3),
                      AppColors.blue500.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Floating logo with animation
        AnimatedBuilder(
          animation: _floatingAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatingAnimation.value * 0.5),
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.white,
                      AppColors.blue50,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Image.asset(
                  AssetsManager.logo,
                  width: 50.w,
                  height: 50.h,
                  fit: BoxFit.contain,
                  colorBlendMode: BlendMode.multiply,
                ),
              ),
            );
          },
        ),

        SizedBox(height: 24.h),

        // App name with gradient text
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.secondary,
              AppColors.purple500,
            ],
          ).createShader(bounds),
          child: Text(
            'app_name'.tr,
            style: AppFonts.robotoBold32.copyWith(
              color: Colors.white,
              fontSize: 36.sp,
            ),
          ),
        ),

        SizedBox(height: 8.h),

        // Tagline
        Text(
          'app_tagline'.tr,
          style: AppFonts.robotoMedium18.copyWith(
            color: AppColors.textSecondary,
            fontSize: 18.sp,
          ),
        ),

        SizedBox(height: 16.h),

        // Welcome message
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(25.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Text(
            'welcome_back'.tr,
            style: AppFonts.robotoBold20.copyWith(
              color: AppColors.primary,
              fontSize: 22.sp,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Login title
          Center(
            child: Text(
              'login_to_your_account'.tr,
              style: AppFonts.robotoBold24.copyWith(
                color: AppColors.textPrimary,
                fontSize: 26.sp,
              ),
            ),
          ),

          SizedBox(height: 8.h),

          Center(
            child: Text(
              'sign_in_to_continue'.tr,
              style: AppFonts.robotoRegular16.copyWith(
                color: AppColors.textSecondary,
                fontSize: 16.sp,
              ),
            ),
          ),

          SizedBox(height: 32.h),

          // Login Method Selector
          _buildLoginMethodSelector(),

          SizedBox(height: 24.h),

          // Identifier Field
          _isEmailSelected
              ? _buildModernTextField(
                  controller: _identifierController,
                  label: 'email'.tr,
                  hint: 'enter_your_email'.tr,
                  keyboardType: TextInputType.emailAddress,
                  icon: Icons.email_outlined,
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

          SizedBox(height: 20.h),

          // Password Field
          _buildModernPasswordField(),

          SizedBox(height: 32.h),

          // Login Button
          _buildModernLoginButton(),

          SizedBox(height: 20.h),

          // Forgot Password Link
          Center(
            child: GestureDetector(
              onTap: () => Get.toNamed<void>(AppRoutes.forgotPassword),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.blue50,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'forgot_password'.tr,
                  style: AppFonts.robotoMedium14.copyWith(
                    color: AppColors.primary,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginMethodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(20.r),
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
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  color:
                      _isEmailSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.email_outlined,
                      color: _isEmailSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                      size: 18.w,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'email'.tr,
                      style: AppFonts.robotoMedium14.copyWith(
                        color: _isEmailSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
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
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  color: !_isEmailSelected
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      color: !_isEmailSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                      size: 18.w,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'phone'.tr,
                      style: AppFonts.robotoMedium14.copyWith(
                        color: !_isEmailSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    IconData? icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppFonts.robotoMedium16.copyWith(
            color: AppColors.textPrimary,
            fontSize: 16.sp,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(16.r),
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
              fontSize: 16.sp,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppFonts.robotoRegular14.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14.sp,
              ),
              prefixIcon: icon != null
                  ? Icon(
                      icon,
                      color: AppColors.primary,
                      size: 20.w,
                    )
                  : null,
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

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'phone_number'.tr,
          style: AppFonts.robotoMedium16.copyWith(
            color: AppColors.textPrimary,
            fontSize: 16.sp,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            // Country Selector
            GestureDetector(
              onTap: () => _showCountrySelector(),
              child: Container(
                width: 100.w,
                height: 56.h,
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppColors.grey200,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _selectedCountry.flag,
                        style: TextStyle(fontSize: 18.sp),
                      ),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          _selectedCountry.dialCode,
                          style: AppFonts.robotoMedium14.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 14.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                        size: 16.w,
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
                height: 56.h,
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(16.r),
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
                    fontSize: 16.sp,
                  ),
                  decoration: InputDecoration(
                    hintText: 'phone_placeholder'.tr,
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
        ),
      ],
    );
  }

  Widget _buildModernPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'password'.tr,
          style: AppFonts.robotoMedium16.copyWith(
            color: AppColors.textPrimary,
            fontSize: 16.sp,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(16.r),
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
              fontSize: 16.sp,
            ),
            decoration: InputDecoration(
              hintText: 'enter_your_password'.tr,
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
        ),
      ],
    );
  }

  Widget _buildModernLoginButton() {
    return Container(
      width: double.infinity,
      height: 56.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
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
            borderRadius: BorderRadius.circular(16.r),
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'sign_in'.tr,
                    style: AppFonts.robotoBold16.copyWith(
                      color: Colors.white,
                      fontSize: 18.sp,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20.w,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAdditionalOptions() {
    return Column(
      children: [
        // Terms and Conditions
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Text(
            'terms_and_conditions'.tr,
            style: AppFonts.robotoRegular12.copyWith(
              color: AppColors.textPrimary,
              fontSize: 12.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        SizedBox(height: 20.h),

        // Register Link
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'dont_have_account'.tr,
                style: AppFonts.robotoRegular14.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 14.sp,
                ),
              ),
              GestureDetector(
                onTap: () => Get.toNamed<void>(AppRoutes.register),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'sign_up'.tr,
                    style: AppFonts.robotoBold14.copyWith(
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
            ],
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
