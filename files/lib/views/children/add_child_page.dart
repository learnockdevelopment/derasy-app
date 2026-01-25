import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../models/student_models.dart';
import '../../services/students_service.dart';
import 'package:iconly/iconly.dart';
import 'certificate_scanner_page.dart';

class AddChildPage extends StatefulWidget {
  const AddChildPage({Key? key}) : super(key: key);

  @override
  State<AddChildPage> createState() => _AddChildPageState();
}

class _AddChildPageState extends State<AddChildPage> {
  File? _birthCertificateFile;
  bool _isExtracting = false;
  bool _isSubmitting = false;
  BirthCertificateExtractionResponse? _extractionResponse;
  ExtractedData? _extractedData;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.blue1,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'add_child'.tr,
          style: AppFonts.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: _extractedData == null
          ? _buildUploadSection()
          : _buildReviewSection(),
    );
  }

  Widget _buildUploadSection() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 20.h),
          // Header
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.blue1,
                  AppColors.blue1.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue1.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  IconlyBroken.document,
                  color: Colors.white,
                  size: 48.sp,
                ),
                SizedBox(height: 16.h),
                Text(
                  'upload_birth_certificate'.tr,
                  style: AppFonts.h2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  'extract_data_automatically'.tr,
                  style: AppFonts.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(height: 32.h),
          
          // Upload Area
          GestureDetector(
            onTap: _isExtracting ? null : _showImageSourceDialog,
            child: Container(
              width: double.infinity,
              height: 300.h,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _birthCertificateFile != null
                      ? AppColors.blue1
                      : AppColors.grey300,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20.r),
                color: AppColors.surface,
              ),
              child: _isExtracting
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.blue1),
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            'extracting_data'.tr,
                            style: AppFonts.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 16.sp,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'please_wait'.tr,
                            style: AppFonts.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _birthCertificateFile != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(17.r),
                              child: Image.file(
                                _birthCertificateFile!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 12.h,
                              right: 12.w,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _birthCertificateFile = null;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20.sp,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(24.w),
                              decoration: BoxDecoration(
                                color: AppColors.blue1.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                IconlyBroken.upload,
                                color: AppColors.blue1,
                                size: 48.sp,
                              ),
                            ),
                            SizedBox(height: 20.h),
                            Text(
                              'click_to_upload_birth_certificate'.tr,
                              style: AppFonts.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'PNG, JPG up to 10MB',
                              style: AppFonts.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
            ),
          ),
          SizedBox(height: 24.h),
          // Info Card
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.blue1.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppColors.blue1.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  IconlyBroken.info_circle,
                  color: AppColors.blue1,
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'supported_documents'.tr,
                    style: AppFonts.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Success Header
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppColors.success.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'data_extracted_successfully'.tr,
                        style: AppFonts.h4.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'review_and_confirm'.tr,
                        style: AppFonts.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          
          // Extracted Data Cards
          _buildDataCard(
            icon: IconlyBroken.profile,
            title: 'full_name'.tr,
            value: _extractedData!.fullName ?? _extractedData!.arabicFullName ?? 'N/A',
            subtitle: _extractedData!.arabicFullName != null && _extractedData!.fullName != null
                ? _extractedData!.arabicFullName
                : null,
          ),
          SizedBox(height: 12.h),
          _buildDataCard(
            icon: IconlyBroken.calendar,
            title: 'birth_date'.tr,
            value: _extractedData!.birthDate != null
                ? _formatDate(_extractedData!.birthDate!)
                : 'N/A',
          ),
          SizedBox(height: 12.h),
          _buildDataCard(
            icon: IconlyBroken.profile,
            title: 'gender'.tr,
            value: _extractedData!.gender != null
                ? (_extractedData!.gender == 'male' ? 'male'.tr : 'female'.tr)
                : 'N/A',
          ),
          SizedBox(height: 12.h),
          if (_extractedData!.nationalId != null)
            _buildDataCard(
              icon: IconlyBroken.document,
              title: 'national_id'.tr,
              value: _extractedData!.nationalId!,
            ),
          if (_extractedData!.nationalId != null) SizedBox(height: 12.h),
          if (_extractedData!.nationality != null)
            _buildDataCard(
              icon: Icons.flag_rounded,
              title: 'nationality'.tr, 
              value: _extractedData!.nationality!,
            ),
          if (_extractedData!.nationality != null) SizedBox(height: 12.h),
          if (_extractedData!.birthPlace != null)
            _buildDataCard(
              icon: IconlyBroken.location,
              title: 'birth_place'.tr,
              value: _extractedData!.birthPlace!,
            ),
          if (_extractedData!.birthPlace != null) SizedBox(height: 12.h),
          if (_extractedData!.religion != null)
            _buildDataCard(
              icon: IconlyBroken.star,
              title: 'religion'.tr,
              value: _extractedData!.religion!,
            ),
          if (_extractedData!.religion != null) SizedBox(height: 12.h),
          if (_extractedData!.ageInComingOctober != null)
            _buildDataCard(
              icon: IconlyBroken.time_circle,
              title: 'age_in_coming_october'.tr,
              value: _extractedData!.ageInComingOctober!.formatted,
            ),
          if (_extractedData!.ageInComingOctober != null) SizedBox(height: 12.h),
          
          SizedBox(height: 24.h),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : () {
                    setState(() {
                      _extractedData = null;
                      _extractionResponse = null;
                      _birthCertificateFile = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    side: BorderSide(color: AppColors.blue1, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'upload_again'.tr,
                    style: AppFonts.h4.copyWith(
                      color: AppColors.blue1,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitChild,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue1,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          height: 20.h,
                          width: 20.w,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'add_child'.tr,
                          style: AppFonts.h4.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildDataCard({
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.grey200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.blue1.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              color: AppColors.blue1,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: AppFonts.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: AppFonts.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                child: Text(
                  'select_option'.tr,
                  style: AppFonts.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
              ),
              // Scan Option
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: AppColors.blue1,
                    size: 24.sp,
                  ),
                ),
                title: Text(
                  'scan_certificate'.tr,
                  style: AppFonts.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                  ),
                ),
                subtitle: Text(
                  'scan_with_camera'.tr,
                  style: AppFonts.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  // Navigate to document scanner
                  final scannedFile = await Get.to(() => const CertificateScannerPage());
                  if (scannedFile != null && scannedFile is File) {
                    await _processScannedCertificate(scannedFile);
                  }
                },
              ),
              // Upload Option
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    IconlyBroken.upload,
                    color: AppColors.blue1,
                    size: 24.sp,
                  ),
                ),
                title: Text(
                  'upload_from_gallery'.tr,
                  style: AppFonts.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                  ),
                ),
                subtitle: Text(
                  'select_from_gallery'.tr,
                  style: AppFonts.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickBirthCertificate(ImageSource.gallery);
                },
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickBirthCertificate(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (image != null) {
        final file = File(image.path);
        setState(() {
          _birthCertificateFile = file;
        });
        
        // Automatically extract data
        await _extractData(file);
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_pick_image'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _processScannedCertificate(File file) async {
    setState(() {
      _birthCertificateFile = file;
    });
    
    // Automatically extract data
    await _extractData(file);
  }

  Future<void> _extractData(File file) async {
    setState(() {
      _isExtracting = true;
    });

    try {
      final response = await StudentsService.extractBirthCertificate(file);
      
      if (!mounted) return;

      setState(() {
        _extractionResponse = response;
        _extractedData = response.extractedData;
        _isExtracting = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isExtracting = false;
      });

      String errorMessage = 'Failed to extract data. Please try again.';
      if (e is StudentsException) {
        errorMessage = e.message;
      } else if (e is BirthCertificateExtractionException) {
        errorMessage = e.message;
        if (e.canContinue) {
          // Show error but allow manual entry if needed
          Get.snackbar(
            'warning'.tr,
            errorMessage,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
          return;
        }
      }

      Get.snackbar(
        'error'.tr,
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _submitChild() async {
    if (_extractedData == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Prepare birth certificate data
      Map<String, dynamic>? birthCertificate;
      if (_extractionResponse?.extractedData.birthCertificateImage != null) {
        final img = _extractionResponse!.extractedData.birthCertificateImage!;
        birthCertificate = {
          'data': img.data,
          'mimeType': img.mimeType,
        };
      } else if (_birthCertificateFile != null) {
        final bytes = await _birthCertificateFile!.readAsBytes();
        final base64String = base64Encode(bytes);
        final mimeType = _birthCertificateFile!.path.toLowerCase().endsWith('.png')
            ? 'image/png'
            : 'image/jpeg';
        birthCertificate = {
          'data': 'data:$mimeType;base64,$base64String',
          'mimeType': mimeType,
        };
      }

      final request = AddChildRequest(
        arabicFullName: _extractedData!.arabicFullName,
        fullName: _extractedData!.fullName,
        gender: _extractedData!.gender ?? 'male',
        birthDate: _extractedData!.birthDate ?? DateTime.now().toIso8601String().split('T')[0],
        nationalId: _extractedData!.nationalId,
        nationality: _extractedData!.nationality,
        religion: _extractedData!.religion,
        birthPlace: _extractedData!.birthPlace,
        birthCertificate: birthCertificate,
      );

      final response = await StudentsService.addChildren(request);

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      Get.snackbar(
        'success'.tr,
        response.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      Get.back(result: true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      String errorMessage = 'Failed to add child. Please try again.';
      if (e is StudentsException) {
        errorMessage = e.message;
      }

      Get.snackbar(
        'error'.tr,
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

