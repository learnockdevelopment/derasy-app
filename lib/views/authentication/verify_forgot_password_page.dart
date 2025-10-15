import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/assets.dart';
import '../../core/routes/app_routes.dart';
import '../../services/authentication/auth_service.dart';

class VerifyForgotPasswordPage extends StatefulWidget {
  final String identifier;
  final String sentVia;
  final String? devCode;

  const VerifyForgotPasswordPage({
    Key? key,
    required this.identifier,
    required this.sentVia,
    this.devCode,
  }) : super(key: key);

  @override
  State<VerifyForgotPasswordPage> createState() =>
      _VerifyForgotPasswordPageState();
}

class _VerifyForgotPasswordPageState extends State<VerifyForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _codeControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _codeFocusNodes =
      List.generate(6, (index) => FocusNode());

  bool _isLoading = false;
  bool _isCodeValid = false;
  String _enteredCode = '';

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 6; i++) {
      _codeControllers[i].addListener(_validateCode);
      _codeFocusNodes[i].addListener(() {
        if (_codeFocusNodes[i].hasFocus) {
          _codeControllers[i].selection = TextSelection.fromPosition(
            TextPosition(offset: _codeControllers[i].text.length),
          );
        }
      });
    }

    // Show dev code if available
    if (widget.devCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDevCode();
      });
    }
  }

  @override
  void dispose() {
    for (int i = 0; i < 6; i++) {
      _codeControllers[i].dispose();
      _codeFocusNodes[i].dispose();
    }
    super.dispose();
  }

  void _showDevCode() {
    Get.dialog<void>(
      AlertDialog(
        title: Text('Dev Code'),
        content: Text('OTP Code: ${widget.devCode}'),
        actions: [
          TextButton(
            onPressed: () => Get.back<void>(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _validateCode() {
    _enteredCode = _codeControllers.map((controller) => controller.text).join();
    setState(() {
      _isCodeValid = _enteredCode.length == 6;
    });
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.sentVia == 'email') {
        await AuthService.validateOtpFromEmail(
          email: widget.identifier,
          otp: _enteredCode,
        );
      } else {
        await AuthService.validateOtpFromPhone(
          phoneNumber: widget.identifier,
          code: _enteredCode,
        );
      }

      setState(() {
        _isLoading = false;
      });

      // Navigate to reset password page
      Get.toNamed<void>(AppRoutes.resetPassword, arguments: {
        'identifier': widget.identifier,
        'otp': _enteredCode,
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

  Future<void> _resendCode() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> response;
      String? devCode;

      if (widget.sentVia == 'email') {
        response = await AuthService.sendOtpToEmail(email: widget.identifier);
        if (response['devCode'] != null) {
          devCode = response['devCode'].toString();
        }
      } else {
        response =
            await AuthService.sendOtpToPhone(phoneNumber: widget.identifier);
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

      // Clear the code fields
      for (var controller in _codeControllers) {
        controller.clear();
      }
      _enteredCode = '';
      _validateCode();

      // Show dev code if available
      if (devCode != null) {
        _showDevCode();
      }

      Get.snackbar(
        'success'.tr,
        'code_sent_successfully'.tr,
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

                // Verify Code title
                Text(
                  'verify_code'.tr,
                  style: AppFonts.robotoBold24.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),

                SizedBox(height: 8.h),

                // Description
                Text(
                  widget.sentVia == 'email'
                      ? 'verify_email_code_description'.tr
                      : 'verify_phone_code_description'.tr,
                  style: AppFonts.robotoRegular14.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),

                SizedBox(height: 8.h),

                // Identifier
                Text(
                  widget.identifier,
                  style: AppFonts.robotoBold14.copyWith(
                    color: AppColors.primary,
                  ),
                ),

                SizedBox(height: 32.h),

                // OTP Code Fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return _buildCodeField(index);
                  }),
                ),

                SizedBox(height: 32.h),

                // Verify Button
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed:
                        (_isLoading || !_isCodeValid) ? null : _verifyCode,
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
                            'verify'.tr,
                            style: AppFonts.robotoBold16,
                          ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Resend Code
                Center(
                  child: GestureDetector(
                    onTap: _isLoading ? null : _resendCode,
                    child: Text(
                      'resend_code'.tr,
                      style: AppFonts.robotoBold14.copyWith(
                        color: _isLoading
                            ? AppColors.textSecondary
                            : AppColors.primary,
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

  Widget _buildCodeField(int index) {
    return Container(
      width: 45.w,
      height: 45.h,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _codeFocusNodes[index].hasFocus
              ? AppColors.primary
              : AppColors.grey200,
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: _codeControllers[index],
        focusNode: _codeFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '';
          }
          return null;
        },
        style: AppFonts.robotoBold18.copyWith(
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 5) {
              _codeFocusNodes[index + 1].requestFocus();
            } else {
              _codeFocusNodes[index].unfocus();
            }
          } else if (value.isEmpty && index > 0) {
            _codeFocusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }
}
