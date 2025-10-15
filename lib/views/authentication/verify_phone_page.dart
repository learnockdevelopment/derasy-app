import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/assets.dart';
import '../../core/routes/app_routes.dart';
import '../../services/authentication/auth_service.dart';
import '../../models/authentication/auth_models.dart';
import '../../views/widgets/error_prompts.dart';

class VerifyPhonePage extends StatefulWidget {
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;

  const VerifyPhonePage({
    Key? key,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
  }) : super(key: key);

  @override
  State<VerifyPhonePage> createState() => _VerifyPhonePageState();
}

class _VerifyPhonePageState extends State<VerifyPhonePage> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _codeControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _codeFocusNodes =
      List.generate(6, (index) => FocusNode());

  bool _isLoading = false;
  bool _isCodeSent = false;
  String? _devCode;
  bool _isCodeValid = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 6; i++) {
      _codeControllers[i].addListener(() => _validateCode());
    }
    _sendCode();
  }

  @override
  void dispose() {
    for (int i = 0; i < 6; i++) {
      _codeControllers[i].dispose();
      _codeFocusNodes[i].dispose();
    }
    super.dispose();
  }

  void _validateCode() {
    final code = _getCodeFromControllers(_codeControllers);
    setState(() {
      _isCodeValid = _isValidCode(code);
    });
  }

  String _getCodeFromControllers(List<TextEditingController> controllers) {
    return controllers.map((controller) => controller.text.trim()).join('');
  }

  bool _isValidCode(String code) {
    if (code.isEmpty) return false;
    // Code should be 6 digits only
    return RegExp(r'^\d{6}$').hasMatch(code);
  }

  Future<void> _pasteFromClipboard(
    List<TextEditingController> controllers,
    List<FocusNode> focusNodes,
  ) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null) return;
    final focusedIndex = focusNodes.indexWhere((f) => f.hasFocus);
    final start = focusedIndex >= 0 ? focusedIndex : 0;
    _handlePaste(data.text!, start, controllers, focusNodes);
  }

  void _handlePaste(
    String text,
    int startIndex,
    List<TextEditingController> controllers,
    List<FocusNode> focusNodes,
  ) {
    final pastedDigits = text.replaceAll(RegExp(r'\D'), '');
    if (pastedDigits.isEmpty) return;

    int writeCount = 0;
    for (int i = 0;
        i < pastedDigits.length && (startIndex + i) < controllers.length;
        i++) {
      controllers[startIndex + i].text = pastedDigits[i];
      writeCount++;
    }

    final nextIndex = startIndex + writeCount;
    if (nextIndex < controllers.length) {
      focusNodes[nextIndex].requestFocus();
    } else {
      focusNodes[controllers.length - 1].unfocus();
    }
    _validateCode();
  }

  Future<void> _sendCode() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthService.verifyPhone(
        userId: widget.userId,
        action: 'send',
      );

      final verifyResponse = VerifyPhoneResponse.fromJson(response);

      // Debug logging
      print('📱 [VERIFY PHONE] Response data: $response');
      print('📱 [VERIFY PHONE] All response keys: ${response.keys.toList()}');
      print('📱 [VERIFY PHONE] DevCode from response: ${response['devCode']}');
      print('📱 [VERIFY PHONE] Code from response: ${response['code']}');
      print('📱 [VERIFY PHONE] Message from response: ${response['message']}');
      print('📱 [VERIFY PHONE] DevCode from model: ${verifyResponse.devCode}');

      // Try to get devCode from response directly or fallback to 'code'
      String? devCode =
          response['devCode']?.toString() ?? response['code']?.toString();

      // If no devCode is found, show a message
      if (devCode == null) {
        print(
            '📱 [VERIFY PHONE] ⚠️ No verification code found in API response');
        print(
            '📱 [VERIFY PHONE] Available fields: ${response.keys.join(', ')}');

        // For development purposes, generate a mock code
        devCode = '654321';
        print(
            '📱 [VERIFY PHONE] 🔧 Using mock verification code for development: $devCode');
      }

      setState(() {
        _isCodeSent = verifyResponse.sent;
        _devCode = devCode;
      });

      if (verifyResponse.sent) {
        Get.snackbar(
          'Code Sent',
          'Verification code sent to your phone',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );

        // Print verification code if available
        if (devCode != null) {
          print('📱 [VERIFY PHONE] 📱 PHONE VERIFICATION CODE: $devCode');
        }
      }
    } catch (e) {
      int? statusCode;
      if (e is AuthException) {
        statusCode = e.statusCode;
      }
      ErrorPrompts.showSendCodeError(e.toString(), statusCode: statusCode);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthService.verifyPhone(
        userId: widget.userId,
        action: 'verify',
        code: _getCodeFromControllers(_codeControllers),
      );

      final verifyResponse = VerifyPhoneResponse.fromJson(response);

      if (verifyResponse.verified) {
        Get.snackbar(
          'Phone Verified',
          'Your phone number has been verified successfully',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      int? statusCode;
      if (e is AuthException) {
        statusCode = e.statusCode;
      }
      ErrorPrompts.showVerificationError(e.toString(), statusCode: statusCode);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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

                SizedBox(height: 40.h),

                // Header
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'verify'.tr,
                      style: AppFonts.robotoBold24.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'we_sent_verification_code_phone'.tr,
                      style: AppFonts.robotoRegular14.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 32.h),

                // Code Field
                _buildCodeField(
                    'verification_code'.tr, _codeControllers, _codeFocusNodes),

                // Dev Code Display (for development)
                if (_devCode != null) ...[
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'development_code'.tr,
                          style: AppFonts.robotoMedium12.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _devCode!,
                          style: AppFonts.robotoBold16.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 32.h),

                // Verify Button
                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed:
                        (_isLoading || !_isCodeValid) ? null : _verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
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
                    onTap: _isLoading ? null : _sendCode,
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
          maxLength: 6,
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
            counterText: '',
          ),
        ),
      ],
    );
  }

  Widget _buildCodeField(String label, List<TextEditingController> controllers,
      List<FocusNode> focusNodes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppFonts.robotoMedium14.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => _pasteFromClipboard(controllers, focusNodes),
              child: Text(
                'Paste',
                style:
                    AppFonts.robotoMedium12.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            return Container(
              width: 48.w,
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
                controller: controllers[index],
                focusNode: focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: AppFonts.robotoBold18.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) {
                  if (value.length > 1) {
                    _handlePaste(value, index, controllers, focusNodes);
                    return;
                  }
                  if (value.isNotEmpty) {
                    if (index < 5) {
                      focusNodes[index + 1].requestFocus();
                    } else {
                      focusNodes[index].unfocus();
                    }
                  } else if (value.isEmpty && index > 0) {
                    focusNodes[index - 1].requestFocus();
                  }
                  _validateCode();
                },
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
