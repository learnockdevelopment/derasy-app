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
import '../../views/widgets/country_selector.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();

  bool _isLoading = false;
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
  }

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final identifier = _identifierController.text.trim();

    setState(() {
      _isIdentifierValid = _isValidIdentifier(identifier);
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

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String identifier = _isEmailSelected
          ? _identifierController.text.trim()
          : '${_selectedCountry.dialCode}${_identifierController.text.trim()}';

      Map<String, dynamic> response;
      String? devCode;

      if (_isEmailSelected) {
        response = await AuthService.sendOtpToEmail(email: identifier);
        // Extract dev code if available
        if (response['devCode'] != null) {
          devCode = response['devCode'].toString();
        }
      } else {
        response = await AuthService.sendOtpToPhone(phoneNumber: identifier);
        // Extract OTP from message if available
        if (response['message'] != null &&
            response['message'].toString().contains(',')) {
          final parts = response['message'].toString().split(',');
          if (parts.length > 1) {
            devCode = parts[1].trim();
          }
        }
      }

      setState(() {
        _isLoading = false;
      });

      // Navigate to verify OTP page
      Get.toNamed<void>(AppRoutes.verifyForgotPassword, arguments: {
        'identifier': identifier,
        'sentVia': _isEmailSelected ? 'email' : 'phone',
        'devCode': devCode,
      });
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
            size: 20.w,
          ),
          onPressed: () => Get.back<void>(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),

                // Header with logo and company name
                Row(
                  children: [
                    Image.asset(
                      AssetsManager.logo,
                      width: 40.w,
                      height: 40.h,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'app_name'.tr,
                      style: AppFonts.robotoBold18.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 32.h),

                // Forgot Password title
                Text(
                  'forgot_password'.tr,
                  style: AppFonts.robotoBold24.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),

                SizedBox(height: 8.h),

                // Description
                Text(
                  'forgot_password_description'.tr,
                  style: AppFonts.robotoRegular14.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),

                SizedBox(height: 32.h),

                // Method Selector
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
                      )
                    : _buildPhoneField(),

                SizedBox(height: 32.h),

                // Send OTP Button
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed:
                        (_isLoading || !_isIdentifierValid) ? null : _sendOtp,
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
                            'send_otp'.tr,
                            style: AppFonts.robotoBold16,
                          ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Back to Login Link
                Center(
                  child: GestureDetector(
                    onTap: () => Get.back<void>(),
                    child: Text(
                      'back_to_login'.tr,
                      style: AppFonts.robotoBold14.copyWith(
                        color: AppColors.primary,
                      ),
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
