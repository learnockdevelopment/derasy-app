import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/assets.dart';
import '../../core/routes/app_routes.dart';
import '../../models/auth_models.dart';
import '../../services/auth_service.dart';

class SetNewPasswordPage extends StatefulWidget {
  const SetNewPasswordPage({Key? key}) : super(key: key);

  @override
  State<SetNewPasswordPage> createState() => _SetNewPasswordPageState();
}

class _SetNewPasswordPageState extends State<SetNewPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _email;
  String? _phone;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String _passwordStrength = '';

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordStrength);

    final args = Get.arguments as Map<String, dynamic>?;
    _email = args?['email'];
    _phone = args?['phone'];

    if (_email != null) _emailController.text = _email!;
    if (_phone != null) _phoneController.text = _phone!;
  }

  @override
  void dispose() {
    _passwordController.removeListener(_checkPasswordStrength);
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength() {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _passwordStrength = '');
      return;
    }

    var score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    String strength;
    if (score < 3) {
      strength = 'weak';
    } else if (score < 5) {
      strength = 'medium';
    } else {
      strength = 'strong';
    }

    setState(() => _passwordStrength = strength);
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
    final email = _emailController.text.trim();
    return email.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text;
  }

  Future<void> _setNewPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        Get.snackbar(
          'error'.tr,
          'email_not_found_try_again'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
        return;
      }

      final request = SetNewPasswordRequest(
        email: email,
        newPassword: _passwordController.text,
      );

      final response = await AuthService.setNewPassword(request);

      if (response.success) {
        Get.snackbar(
          'success'.tr,
          'password_updated_successfully'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
        Get.offAllNamed(AppRoutes.login);
      } else {
        Get.snackbar(
          'error'.tr,
          response.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'generic_error_with_message'.tr.replaceAll('{message}', e.toString()),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: Responsive.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                        size: Responsive.sp(24),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(Responsive.r(8)),
                      onTap: () {
                        final isAr = Get.locale?.languageCode == 'ar';
                        Get.updateLocale(isAr ? const Locale('en', 'US') : const Locale('ar', 'SA'));
                        setState(() {});
                      },
                      child: Padding(
                        padding: Responsive.symmetric(horizontal: 8, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.language,
                              color: AppColors.primaryBlue,
                              size: Responsive.sp(22),
                            ),
                            SizedBox(width: Responsive.w(4)),
                            Text(
                              (Get.locale?.languageCode == 'ar') ? 'English' : 'العربية',
                              style: AppFonts.AlmaraiMedium14.copyWith(
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: double.infinity,
                height: Responsive.h(320),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryBlue,
                      AppColors.primaryBlue,
                      AppColors.primaryBlue.withOpacity(0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(Responsive.r(30)),
                    bottomRight: Radius.circular(Responsive.r(30)),
                  ),
                ),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: EdgeInsets.only(top: Responsive.h(24)),
                        child: Image.asset(
                          AssetsManager.logo,
                          width: Responsive.w(120),
                          height: Responsive.w(120),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Positioned(
                      top: Responsive.h(40),
                      right: Responsive.w(30),
                      child: Container(
                        width: Responsive.w(80),
                        height: Responsive.h(80),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(Responsive.r(40)),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: Responsive.h(60),
                      left: Responsive.w(30),
                      child: Container(
                        width: Responsive.w(50),
                        height: Responsive.h(50),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(Responsive.r(25)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: Responsive.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: Responsive.h(20)),
                          Row(
                            children: [
                              Container(
                                padding: Responsive.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withOpacity(0.22),
                                  borderRadius: BorderRadius.circular(Responsive.r(16)),
                                ),
                                child: Icon(
                                  Icons.lock_reset,
                                  color: AppColors.white,
                                  size: Responsive.sp(32),
                                ),
                              ),
                              SizedBox(width: Responsive.w(16)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'set_new_password'.tr,
                                      style: AppFonts.AlmaraiBold28.copyWith(
                                        color: AppColors.white,
                                      ),
                                    ),
                                    Text(
                                      'create_secure_password'.tr,
                                      style: AppFonts.AlmaraiRegular16.copyWith(
                                        color: AppColors.white.withOpacity(0.88),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: Responsive.h(32)),
                          Container(
                            padding: Responsive.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.13),
                              borderRadius: BorderRadius.circular(Responsive.r(20)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.security, color: AppColors.white, size: Responsive.sp(16)),
                                SizedBox(width: Responsive.w(8)),
                                Text(
                                  'secure_password_reset'.tr,
                                  style: AppFonts.AlmaraiMedium14.copyWith(color: AppColors.white),
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

              Container(
                margin: Responsive.all(20),
                padding: Responsive.all(28),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(Responsive.r(24)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.grey200,
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'create_new_password'.tr,
                        style: AppFonts.AlmaraiBold20.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: Responsive.h(8)),
                      Text(
                        'enter_your_new_password_below'.tr,
                        style: AppFonts.AlmaraiRegular14.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: Responsive.h(20)),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'email'.tr,
                          hintText: 'enter_your_email'.tr,
                          prefixIcon: Icon(Icons.email_outlined, color: AppColors.primaryBlue, size: Responsive.sp(20)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Responsive.r(16)),
                            borderSide: BorderSide(color: AppColors.grey300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Responsive.r(16)),
                            borderSide: BorderSide(color: AppColors.primaryBlue, width: Responsive.w(2)),
                          ),
                          filled: true,
                          fillColor: AppColors.grey50,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'email_required'.tr;
                          final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                          if (!emailRegex.hasMatch(value.trim())) return 'invalid_email'.tr;
                          return null;
                        },
                      ),
                      SizedBox(height: Responsive.h(14)),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'phone_number_optional'.tr,
                          hintText: 'enter_phone_optional'.tr,
                          prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primaryBlue, size: Responsive.sp(20)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Responsive.r(16)),
                            borderSide: BorderSide(color: AppColors.grey300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Responsive.r(16)),
                            borderSide: BorderSide(color: AppColors.primaryBlue, width: Responsive.w(2)),
                          ),
                          filled: true,
                          fillColor: AppColors.grey50,
                        ),
                      ),
                      SizedBox(height: Responsive.h(20)),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'new_password'.tr,
                          hintText: 'enter_your_new_password'.tr,
                          prefixIcon: Container(
                            margin: Responsive.all(8),
                            padding: Responsive.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(Responsive.r(8)),
                            ),
                            child: Icon(Icons.lock_outlined, color: AppColors.primaryBlue, size: Responsive.sp(20)),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.primaryBlue,
                            ),
                            onPressed: () {
                              setState(() => _isPasswordVisible = !_isPasswordVisible);
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Responsive.r(16)),
                            borderSide: BorderSide(color: AppColors.grey300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Responsive.r(16)),
                            borderSide: BorderSide(color: AppColors.primaryBlue, width: Responsive.w(2)),
                          ),
                          filled: true,
                          fillColor: AppColors.grey50,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'password_required'.tr;
                          if (value.length < 6) return 'password_min_length'.tr;
                          return null;
                        },
                      ),
                      if (_passwordStrength.isNotEmpty) ...[
                        SizedBox(height: Responsive.h(12)),
                        Container(
                          padding: Responsive.all(12),
                          decoration: BoxDecoration(
                            color: _getPasswordStrengthColor().withOpacity(0.09),
                            borderRadius: BorderRadius.circular(Responsive.r(8)),
                            border: Border.all(
                              color: _getPasswordStrengthColor().withOpacity(0.23),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.security, color: _getPasswordStrengthColor(), size: Responsive.sp(16)),
                              SizedBox(width: Responsive.w(8)),
                              Text(
                                'password_strength'.tr,
                                style: AppFonts.AlmaraiRegular12.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: Responsive.sp(12),
                                ),
                              ),
                              SizedBox(width: Responsive.w(8)),
                              Text(
                                _passwordStrength.tr,
                                style: AppFonts.AlmaraiBold12.copyWith(
                                  color: _getPasswordStrengthColor(),
                                  fontSize: Responsive.sp(12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: Responsive.h(18)),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: !_isConfirmPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'confirm_password'.tr,
                          hintText: 're_enter_new_password'.tr,
                          prefixIcon: Container(
                            margin: Responsive.all(8),
                            padding: Responsive.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(Responsive.r(8)),
                            ),
                            child: Icon(Icons.lock_outlined, color: AppColors.primaryBlue, size: Responsive.sp(20)),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.primaryBlue,
                            ),
                            onPressed: () {
                              setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Responsive.r(16)),
                            borderSide: BorderSide(color: AppColors.grey300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Responsive.r(16)),
                            borderSide: BorderSide(color: AppColors.primaryBlue, width: Responsive.w(2)),
                          ),
                          filled: true,
                          fillColor: AppColors.grey50,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'please_confirm_your_password'.tr;
                          if (value != _passwordController.text) return 'passwords_do_not_match'.tr;
                          return null;
                        },
                      ),
                      SizedBox(height: Responsive.h(28)),
                      SizedBox(
                        height: Responsive.h(56),
                        child: ElevatedButton(
                          onPressed: _isFormValid() && !_isLoading ? _setNewPassword : null,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: AppColors.primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Responsive.r(16)),
                            ),
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_outline, color: Colors.white, size: Responsive.sp(20)),
                                    SizedBox(width: Responsive.w(8)),
                                    Text(
                                      'set_new_password'.tr,
                                      style: AppFonts.AlmaraiBold16.copyWith(
                                        color: Colors.white,
                                        fontSize: Responsive.sp(16),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      SizedBox(height: Responsive.h(22)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'remember_your_password'.tr,
                            style: AppFonts.AlmaraiRegular14.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: Responsive.sp(14),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Get.offAllNamed(AppRoutes.login),
                            style: TextButton.styleFrom(
                              padding: Responsive.symmetric(horizontal: 8, vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Responsive.r(6)),
                              ),
                            ),
                            child: Text(
                              'back_to_sign_in'.tr,
                              style: AppFonts.AlmaraiBold14.copyWith(
                                color: AppColors.primaryBlue,
                                fontSize: Responsive.sp(14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  } 
}
