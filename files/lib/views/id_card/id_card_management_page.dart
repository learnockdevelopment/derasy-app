import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../services/id_card_service.dart';
import '../../widgets/safe_network_image.dart';

class IdCardManagementPage extends StatefulWidget {
  const IdCardManagementPage({Key? key}) : super(key: key);

  @override
  State<IdCardManagementPage> createState() => _IdCardManagementPageState();
}

class _IdCardManagementPageState extends State<IdCardManagementPage> {
  final _nationalIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cardIdController = TextEditingController();
  final _customIdController = TextEditingController();
  
  IdCard? _idCard;
  bool _isLoading = false;
  bool _showResetPassword = false;
  String? _newPassword;

  @override
  void dispose() {
    _nationalIdController.dispose();
    _passwordController.dispose();
    _cardIdController.dispose();
    _customIdController.dispose();
    super.dispose();
  }

  Future<void> _getIdCard() async {
    if (_nationalIdController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      Get.snackbar(
        'error'.tr,
        'please_enter_national_id_and_password'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _idCard = null;
    });

    try {
      final card = await IdCardService.getIdCard(
        _nationalIdController.text.trim(),
        _passwordController.text.trim(),
      );
      setState(() {
        _idCard = card;
      });
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    if (_cardIdController.text.trim().isEmpty || _customIdController.text.trim().isEmpty) {
      Get.snackbar(
        'error'.tr,
        'please_enter_card_id_and_custom_id'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _newPassword = null;
    });

    try {
      final newPassword = await IdCardService.resetPassword(
        _cardIdController.text.trim(),
        _customIdController.text.trim(),
      );
      setState(() {
        _newPassword = newPassword;
      });
      Get.snackbar(
        'success'.tr,
        'password_reset_successfully'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primaryBlue,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: Text(
          'id_card_management'.tr,
          style: AppFonts.h2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle between Get Card and Reset Password
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showResetPassword = false),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: !_showResetPassword ? AppColors.primaryBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'get_id_card'.tr,
                          textAlign: TextAlign.center,
                          style: AppFonts.bodyMedium.copyWith(
                            color: !_showResetPassword ? Colors.white : const Color(0xFF6B7280),
                            fontWeight: !_showResetPassword ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showResetPassword = true),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: _showResetPassword ? AppColors.primaryBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'reset_password'.tr,
                          textAlign: TextAlign.center,
                          style: AppFonts.bodyMedium.copyWith(
                            color: _showResetPassword ? Colors.white : const Color(0xFF6B7280),
                            fontWeight: _showResetPassword ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            if (!_showResetPassword) ...[
              // Get ID Card Form
              _buildTextField(_nationalIdController, 'national_id'.tr, Icons.badge_rounded, keyboardType: TextInputType.number, maxLength: 14),
              SizedBox(height: 16.h),
              _buildTextField(_passwordController, 'password'.tr, Icons.lock_rounded, obscureText: true),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _getIdCard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
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
                      : Text(
                          'get_id_card'.tr,
                          style: AppFonts.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              if (_idCard != null) ...[
                SizedBox(height: 32.h),
                _buildIdCardDisplay(_idCard!),
              ],
            ] else ...[
              // Reset Password Form
              _buildTextField(_cardIdController, 'card_id'.tr, Icons.badge_rounded),
              SizedBox(height: 16.h),
              _buildTextField(_customIdController, 'custom_id'.tr, Icons.vpn_key_rounded),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
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
                      : Text(
                          'reset_password'.tr,
                          style: AppFonts.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              if (_newPassword != null) ...[
                SizedBox(height: 24.h),
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.primaryBlue),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'new_password'.tr,
                        style: AppFonts.bodyMedium.copyWith(
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _newPassword!,
                        style: AppFonts.h3.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                          
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscureText = false,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  Widget _buildIdCardDisplay(IdCard card) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (card.photoUrl != null && card.photoUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: SafeNetworkImage(
                    imageUrl: card.photoUrl!,
                    width: 80.w,
                    height: 80.h,
                  ),
                )
              else
                Container(
                  width: 80.w,
                  height: 80.h,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.person_rounded, color: AppColors.primaryBlue, size: 40.sp),
                ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.studentName,
                      style: AppFonts.h3.copyWith(
                        fontWeight: FontWeight.bold,
                        
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      card.studentCode,
                      style: AppFonts.bodyMedium.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _buildInfoRow('school_name'.tr, card.schoolName, Icons.school_rounded),
          SizedBox(height: 12.h),
          _buildInfoRow('grade'.tr, card.grade, Icons.class_rounded),
          SizedBox(height: 12.h),
          _buildInfoRow('section'.tr, card.section, Icons.group_rounded),
          SizedBox(height: 12.h),
          _buildInfoRow('national_id'.tr, card.nationalId, Icons.badge_rounded),
          if (card.qrCode != null && card.qrCode!.isNotEmpty) ...[
            SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'qr_code'.tr,
                    style: AppFonts.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    card.qrCode!,
                    style: AppFonts.bodySmall.copyWith(
                      color: const Color(0xFF6B7280),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryBlue, size: 20.sp),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppFonts.bodySmall.copyWith(
                  color: const Color(0xFF6B7280),
                  
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: AppFonts.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

