import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/countries.dart';
import '../../models/student_models.dart';
import '../../services/students_service.dart';
import 'package:iconly/iconly.dart';
import 'certificate_scanner_page.dart';

class AddChildStepsPage extends StatefulWidget {
  const AddChildStepsPage({Key? key}) : super(key: key);

  @override
  State<AddChildStepsPage> createState() => _AddChildStepsPageState();
}

class _AddChildStepsPageState extends State<AddChildStepsPage> {
  int _currentStep = 0;
  String? _selectedNationality; // 'egyptian' or 'foreign'
  String? _selectedForeignCountry; // Country code for foreign students
  
  // Egyptian flow - Parent National ID
  File? _parentNationalIdFile;
  bool _isExtractingParentId = false;
  BirthCertificateExtractionResponse? _parentIdExtractionResponse;
  ExtractedData? _parentIdExtractedData;
  String? _parentNationalId; // Extracted parent National ID
  
  // Egyptian flow - Child Birth Certificate
  File? _birthCertificateFile;
  bool _isExtracting = false;
  BirthCertificateExtractionResponse? _extractionResponse;
  ExtractedData? _extractedData;
  bool _parentIdValidated = false;
  
  // Non-Egyptian flow
  File? _parentPassportFile;
  File? _childPassportFile;
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _arabicFullNameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  String? _selectedGender;
  
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();
  
  // Get all countries except Egypt
  List<Country> get _foreignCountries {
    return Countries.countries.where((country) => country.code != 'EG').toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
  
  String _getTranslatedCountryName(String code) {
    final translationKey = 'country_${code.toLowerCase()}';
    try {
      return translationKey.tr;
    } catch (e) {
      return Countries.getCountryByCode(code).name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
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
      body: _buildStepContent(),
    );
  }

  Widget _buildStepContent() {
    if (_selectedNationality == null) {
      return _buildNationalitySelectionStep();
    }
    
    if (_selectedNationality == 'egyptian') {
      // Egyptian flow: Step 1 = Parent ID, Step 2 = Child Certificate, Step 3 = Review
      switch (_currentStep) {
        case 1:
          return _buildParentNationalIdStep();
        case 2:
          return _buildCertificateUploadStep();
        case 3:
          return _buildReviewStep();
        default:
          return _buildNationalitySelectionStep();
      }
    } else {
      // Non-Egyptian flow: Step 1 = Form with passports
      switch (_currentStep) {
        case 1:
          return _buildForeignStudentForm();
        default:
          return _buildNationalitySelectionStep();
      }
    }
  }

  // Step 1: Nationality Selection
  Widget _buildNationalitySelectionStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 20.h),
          // Enhanced Step Indicator
          _buildEnhancedStepper(), 
          SizedBox(height: 30.h),
          // Title
          Text(
            'select_student_nationality'.tr,
            style: AppFonts.h2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6.h),
          Text(
            'select_nationality_description'.tr,
            style: AppFonts.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          // Egyptian Selection Card
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedNationality = 'egyptian';
                  _selectedForeignCountry = null;
                  _currentStep = 1; // Start with parent National ID step
                });
              },
              borderRadius: BorderRadius.circular(16.r),
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: _selectedNationality == 'egyptian'
                      ? AppColors.primaryBlue.withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: _selectedNationality == 'egyptian'
                        ? AppColors.primaryBlue
                        : AppColors.borderLight,
                    width: _selectedNationality == 'egyptian' ? 2 : 1.5,
                  ),
                  boxShadow: _selectedNationality == 'egyptian'
                      ? [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
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
                        color: _selectedNationality == 'egyptian'
                            ? AppColors.primaryBlue
                            : AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        '🇪🇬',
                        style: TextStyle(fontSize: 24.sp),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'egyptian'.tr,
                            style: AppFonts.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15.sp,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'egyptian_nationality_desc'.tr,
                            style: AppFonts.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedNationality == 'egyptian')
                      Icon(
                        Icons.check_circle,
                        color: AppColors.primaryBlue,
                        size: 24.sp,
                      ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: AppColors.grey300)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Text(
                  'or'.tr,
                  style: AppFonts.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
              ),
              Expanded(child: Divider(color: AppColors.grey300)),
            ],
          ),
          SizedBox(height: 16.h),
          // Foreign Countries Dropdown - Modern Design
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedForeignCountry,
              isExpanded: true,
              icon: Container(
                margin: EdgeInsets.only(right: 8.w),
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primaryGreen,
                  size: 22.sp,
                ),
              ),
              dropdownColor: Colors.white,
              style: AppFonts.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
              ),
              menuMaxHeight: 400.h,
              decoration: InputDecoration(
                labelText: 'other_nationalities'.tr,
                labelStyle: AppFonts.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
                hintText: 'select_country'.tr,
                hintStyle: AppFonts.bodyMedium.copyWith(
                  color: AppColors.textSecondary.withOpacity(0.6),
                  fontSize: 15.sp,
                ),
                prefixIcon: Container(
                  margin: EdgeInsets.only(left: 12.w, right: 8.w),
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryGreen.withOpacity(0.15),
                        AppColors.primaryGreen.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.public_rounded,
                    color: AppColors.primaryGreen,
                    size: 22.sp,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 16.h,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide(
                    color: AppColors.primaryGreen.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide(
                    color: AppColors.primaryGreen.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide(
                    color: AppColors.primaryGreen,
                    width: 2.5,
                  ),
                ),
              ),
              items: _foreignCountries.map((country) {
                return DropdownMenuItem<String>(
                  value: country.code,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.grey200,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36.w,
                          height: 36.w,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Center(
                            child: Text(
                              country.flag,
                              style: TextStyle(fontSize: 22.sp),
                            ),
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Text(
                            _getTranslatedCountryName(country.code),
                            style: AppFonts.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (_selectedForeignCountry == country.code)
                          Icon(
                            Icons.check_circle,
                            color: AppColors.primaryGreen,
                            size: 20.sp,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedNationality = 'foreign';
                    _selectedForeignCountry = value;
                    _currentStep = 1; // Start with foreign student form
                  });
                }
              },
            ),
          ),
          SizedBox(height: 20.h),
          // Info Card
          if (_selectedNationality != null)
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: _selectedNationality == 'egyptian'
                    ? AppColors.primaryBlue.withOpacity(0.05)
                    : AppColors.primaryGreen.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: _selectedNationality == 'egyptian'
                      ? AppColors.primaryBlue.withOpacity(0.2)
                      : AppColors.primaryGreen.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    IconlyBroken.info_circle,
                    color: _selectedNationality == 'egyptian'
                        ? AppColors.primaryBlue
                        : AppColors.primaryGreen,
                    size: 20.sp,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      _selectedNationality == 'egyptian'
                          ? 'egyptian_nationality_desc'.tr
                          : _selectedForeignCountry != null
                              ? 'foreign_nationality_desc'.tr + ' (${_getTranslatedCountryName(_selectedForeignCountry!)})'
                              : 'foreign_nationality_desc'.tr,
                      style: AppFonts.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 12.sp,
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

  // Step 1: Parent National ID Upload (Egyptian)
  Widget _buildParentNationalIdStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 20.h),
          _buildEnhancedStepper(),
          SizedBox(height: 30.h),
          Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryBlue,
                  AppColors.primaryBlue.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  IconlyBroken.profile,
                  color: Colors.white,
                  size: 36.sp,
                ),
                SizedBox(height: 12.h),
                Text(
                  'upload_parent_national_id'.tr,
                  style: AppFonts.h3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6.h),
                Text(
                  'parent_id_validation_desc'.tr,
                  style: AppFonts.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          GestureDetector(
            onTap: _isExtractingParentId ? null : _showParentIdImageSourceDialog,
            child: Container(
              width: double.infinity,
              height: 200.h,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _parentNationalIdFile != null
                      ? AppColors.primaryBlue
                      : AppColors.grey300,
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(16.r),
                color: AppColors.surface,
              ),
              child: _isExtractingParentId
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            'extracting_parent_id'.tr,
                            style: AppFonts.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 16.sp,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _parentNationalIdFile != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(17.r),
                              child: Image.file(
                                _parentNationalIdFile!,
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
                                    _parentNationalIdFile = null;
                                    _parentNationalId = null;
                                    _parentIdExtractedData = null;
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
                            if (_parentNationalId != null)
                              Positioned(
                                bottom: 12.h,
                                left: 12.w,
                                right: 12.w,
                                child: Container(
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Text(
                                    '${'parent_id_extracted'.tr}: $_parentNationalId',
                                    style: AppFonts.bodySmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.sp,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(18.w),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                IconlyBroken.upload,
                                color: AppColors.primaryBlue,
                                size: 36.sp,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              'click_to_upload_parent_id'.tr,
                              style: AppFonts.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14.sp,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'file_format_and_size'.tr,
                              style: AppFonts.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ),
            ),
          ),
          SizedBox(height: 24.h),
          if (_parentNationalIdFile != null && !_isExtractingParentId)
            ElevatedButton(
              onPressed: () async {
                await _extractParentNationalId(_parentNationalIdFile!);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'extract_and_continue'.tr,
                style: AppFonts.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Step 2: Certificate Upload (Egyptian)
  Widget _buildCertificateUploadStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 20.h),
          // Enhanced Step Indicator
          _buildEnhancedStepper(),
          SizedBox(height: 30.h),
          // Header - Smaller
          Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryBlue,
                  AppColors.primaryBlue.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [ 
                Icon(
                  IconlyBroken.document,
                  color: Colors.white,
                  size: 36.sp,
                ),
                SizedBox(height: 12.h),
                Text(
                  'upload_birth_certificate'.tr,
                  style: AppFonts.h3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6.h),
                Text(
                  'extract_data_automatically'.tr,
                  style: AppFonts.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          // Upload Area - Smaller
          GestureDetector(
            onTap: _isExtracting ? null : _showImageSourceDialog,
            child: Container(
              width: double.infinity,
              height: 200.h,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _birthCertificateFile != null
                      ? AppColors.primaryBlue
                      : AppColors.grey300,
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(16.r),
                color: AppColors.surface,
              ),
              child: _isExtracting
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            'extracting_data'.tr,
                            style: AppFonts.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 16.sp,
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
                              padding: EdgeInsets.all(18.w),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                IconlyBroken.upload,
                                color: AppColors.primaryBlue,
                                size: 36.sp,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              'click_to_upload_birth_certificate'.tr,
                              style: AppFonts.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14.sp,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'file_format_and_size'.tr,
                              style: AppFonts.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11.sp,
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
              color: AppColors.primaryBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  IconlyBroken.info_circle,
                  color: AppColors.primaryBlue,
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
          SizedBox(height: 24.h),
          // Continue Button
          if (_birthCertificateFile != null && !_isExtracting)
            ElevatedButton(
              onPressed: () async {
                await _extractData(_birthCertificateFile!);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'extract_and_validate'.tr,
                style: AppFonts.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Step 1: Foreign Student Form
  Widget _buildForeignStudentForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 20.h),
          _buildEnhancedStepper(),
          SizedBox(height: 30.h),
          Text(
            'non_egyptian_child_request'.tr,
            style: AppFonts.h2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6.h),
          Text(
            'non_egyptian_request_desc'.tr,
            style: AppFonts.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          // Parent Passport Upload
          _buildPassportUploadSection(
            'parent_passport'.tr,
            'upload_parent_passport'.tr,
            _parentPassportFile,
            (file) => setState(() => _parentPassportFile = file),
          ),
          SizedBox(height: 20.h),
          // Child Passport Upload
          _buildPassportUploadSection(
            'child_passport'.tr,
            'upload_child_passport'.tr,
            _childPassportFile,
            (file) => setState(() => _childPassportFile = file),
          ),
          SizedBox(height: 20.h),
          // Full Name (English)
          TextField(
            controller: _fullNameController,
            decoration: InputDecoration(
              labelText: 'full_name_english'.tr,
              hintText: 'enter_full_name_english'.tr,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          // Full Name (Arabic)
          TextField(
            controller: _arabicFullNameController,
            decoration: InputDecoration(
              labelText: 'full_name_arabic'.tr,
              hintText: 'enter_full_name_arabic'.tr,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          // Birth Date
          TextField(
            controller: _birthDateController,
            decoration: InputDecoration(
              labelText: 'birth_date'.tr,
              hintText: 'YYYY-MM-DD',
              suffixIcon: Icon(Icons.calendar_today),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                _birthDateController.text = date.toIso8601String().split('T')[0];
              }
            },
          ),
          SizedBox(height: 16.h),
          // Gender
          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: InputDecoration(
              labelText: 'gender'.tr,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            items: ['male', 'female', 'other'].map((gender) {
              return DropdownMenuItem(
                value: gender,
                child: Text(gender.tr),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedGender = value),
          ),
          SizedBox(height: 24.h),
          // Submit Button
          ElevatedButton(
            onPressed: (_parentPassportFile != null && 
                       _childPassportFile != null && 
                       (_fullNameController.text.isNotEmpty || _arabicFullNameController.text.isNotEmpty) &&
                       _birthDateController.text.isNotEmpty &&
                       _selectedGender != null &&
                       !_isSubmitting) 
                ? _submitNonEgyptianRequest 
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: _isSubmitting
                ? CircularProgressIndicator(color: Colors.white)
                : Text(
                    'submit_request'.tr,
                    style: AppFonts.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassportUploadSection(
    String title,
    String hint,
    File? file,
    Function(File?) onFileSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppFonts.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () => _showPassportImageSourceDialog(onFileSelected),
          child: Container(
            width: double.infinity,
            height: 150.h,
            decoration: BoxDecoration(
              border: Border.all(
                color: file != null ? AppColors.primaryGreen : AppColors.grey300,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12.r),
              color: AppColors.surface,
            ),
            child: file != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.file(
                          file,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8.h,
                        right: 8.w,
                        child: GestureDetector(
                          onTap: () => onFileSelected(null),
                          child: Container(
                            padding: EdgeInsets.all(6.w),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close, color: Colors.white, size: 18.sp),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(IconlyBroken.upload, color: AppColors.primaryGreen, size: 32.sp),
                      SizedBox(height: 8.h),
                      Text(
                        hint,
                        style: AppFonts.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  void _showPassportImageSourceDialog(Function(File?) onFileSelected) {
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
              Container(
                margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.primaryGreen),
                title: Text('scan_with_camera'.tr),
                onTap: () async {
                  Navigator.pop(context);
                  final scannedFile = await Get.to(() => const CertificateScannerPage());
                  if (scannedFile != null && scannedFile is File) {
                    onFileSelected(scannedFile);
                  }
                },
              ),
              ListTile(
                leading: Icon(IconlyBroken.upload, color: AppColors.primaryGreen),
                title: Text('upload_from_gallery'.tr),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 2048,
                    maxHeight: 2048,
                    imageQuality: 90,
                  );
                  if (image != null) {
                    onFileSelected(File(image.path));
                  }
                },
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  // Step 3: Review Step
  Widget _buildReviewStep() {
    if (_extractedData == null) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryBlue,
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 20.h),
          // Enhanced Step Indicator
          _buildEnhancedStepper(),
          SizedBox(height: 30.h),
          Text(
            'review_and_confirm'.tr,
            style: AppFonts.h2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 22.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30.h),
          // Review Card
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReviewField('full_name'.tr, _extractedData!.fullName ?? ''),
                if (_extractedData!.arabicFullName != null)
                  _buildReviewField('arabic_name'.tr, _extractedData!.arabicFullName!),
                _buildReviewField('birth_date'.tr, _extractedData!.birthDate ?? ''),
                _buildReviewField('gender'.tr, _extractedData!.gender ?? ''),
                if (_extractedData!.nationalId != null)
                  _buildReviewField('national_id'.tr, _extractedData!.nationalId!),
                if (_extractedData!.nationality != null)
                  _buildReviewField('nationality'.tr, _extractedData!.nationality!),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          // Submit Button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitChild,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: _isSubmitting
                ? CircularProgressIndicator(color: Colors.white)
                : Text(
                    'submit'.tr,
                    style: AppFonts.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewField(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppFonts.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: AppFonts.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 16.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStepper() {
    if (_selectedNationality == 'egyptian') {
      // Egyptian flow: 4 steps (nationality, parent ID, certificate, review)
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildEnhancedStepIndicator(1, _currentStep >= 0, _currentStep > 0, 'select_nationality'.tr),
            Expanded(child: _buildEnhancedStepLine(_currentStep > 0)),
            _buildEnhancedStepIndicator(2, _currentStep >= 1, _currentStep > 1, 'parent_id'.tr),
            Expanded(child: _buildEnhancedStepLine(_currentStep > 1)),
            _buildEnhancedStepIndicator(3, _currentStep >= 2, _currentStep > 2, 'upload_certificate'.tr),
            Expanded(child: _buildEnhancedStepLine(_currentStep > 2)),
            _buildEnhancedStepIndicator(4, _currentStep >= 3, _currentStep > 3, 'review'.tr),
          ],
        ),
      );
    } else if (_selectedNationality == 'foreign') {
      // Non-Egyptian flow: 2 steps (nationality, form)
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildEnhancedStepIndicator(1, _currentStep >= 0, _currentStep > 0, 'select_nationality'.tr),
            Expanded(child: _buildEnhancedStepLine(_currentStep > 0)),
            _buildEnhancedStepIndicator(2, _currentStep >= 1, _currentStep > 1, 'submit_request'.tr),
          ],
        ),
      );
    } else {
      // Default: nationality selection only
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildEnhancedStepIndicator(1, true, false, 'select_nationality'.tr),
          ],
        ),
      );
    }
  }

  Widget _buildEnhancedStepIndicator(int step, bool isActive, bool isCompleted, String label) {
    final isCurrentStep = _currentStep == step - 1;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isCompleted
                  ? LinearGradient(
                      colors: [AppColors.primaryGreen, AppColors.primaryGreen.withOpacity(0.8)],
                    )
                  : isCurrentStep
                      ? LinearGradient(
                          colors: [AppColors.primaryBlue, AppColors.primaryBlue.withOpacity(0.8)],
                        )
                      : null,
              color: isCompleted || isCurrentStep ? null : AppColors.grey300,
              boxShadow: (isCompleted || isCurrentStep)
                  ? [
                      BoxShadow(
                        color: (isCompleted ? AppColors.primaryGreen : AppColors.primaryBlue)
                            .withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: isCompleted
                  ? Icon(Icons.check_rounded, color: Colors.white, size: 20.sp)
                  : Text(
                      '$step',
                      style: AppFonts.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 6.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: Text(
              label,
              style: AppFonts.bodySmall.copyWith(
                color: isCurrentStep || isCompleted
                    ? AppColors.primaryBlue
                    : AppColors.textSecondary,
                fontWeight: isCurrentStep ? FontWeight.w600 : FontWeight.normal,
                fontSize: 9.sp,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStepLine(bool isCompleted) {
    return Container(
      height: 3.h,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2.r),
        gradient: isCompleted
            ? LinearGradient(
                colors: [AppColors.primaryGreen, AppColors.primaryGreen.withOpacity(0.6)],
              )
            : null,
        color: isCompleted ? null : AppColors.grey300,
      ),
    );
  }

  void _showParentIdImageSourceDialog() {
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
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: AppColors.primaryBlue,
                    size: 24.sp,
                  ),
                ),
                title: Text(
                  'scan_parent_id'.tr,
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
                  final scannedFile = await Get.to(() => const CertificateScannerPage(documentType: 'parent_id'));
                  if (scannedFile != null && scannedFile is File) {
                    setState(() {
                      _parentNationalIdFile = scannedFile;
                    });
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    IconlyBroken.upload,
                    color: AppColors.primaryGreen,
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
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 2048,
                    maxHeight: 2048,
                    imageQuality: 90,
                  );
                  if (image != null) {
                    setState(() {
                      _parentNationalIdFile = File(image.path);
                    });
                  }
                },
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _extractParentNationalId(File file) async {
    setState(() {
      _isExtractingParentId = true;
    });

    try {
      final response = await StudentsService.extractBirthCertificate(file);
      
      if (!mounted) return;

      final extractedId = response.extractedData.nationalId;
      if (extractedId == null || extractedId.isEmpty) {
        throw StudentsException('parent_id_extraction_failed'.tr);
      }

      setState(() {
        _parentIdExtractionResponse = response;
        _parentIdExtractedData = response.extractedData;
        _parentNationalId = extractedId;
        _isExtractingParentId = false;
        _currentStep = 2; // Move to child certificate step
      });

      Get.snackbar(
        'success'.tr,
        '${'parent_id_extracted'.tr}: $extractedId',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isExtractingParentId = false;
      });
      Get.snackbar(
        'error'.tr,
        e.toString().replaceAll('StudentsException: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
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
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: AppColors.primaryBlue,
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
                  final scannedFile = await Get.to(() => const CertificateScannerPage());
                  if (scannedFile != null && scannedFile is File) {
                    setState(() {
                      _birthCertificateFile = scannedFile;
                    });
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    IconlyBroken.upload,
                    color: AppColors.primaryGreen,
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
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 2048,
                    maxHeight: 2048,
                    imageQuality: 90,
                  );
                  if (image != null) {
                    setState(() {
                      _birthCertificateFile = File(image.path);
                    });
                  }
                },
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _extractData(File file) async {
    setState(() {
      _isExtracting = true;
    });

    try {
      final response = await StudentsService.extractBirthCertificate(file);
      
      if (!mounted) return;

      // Validate parent National ID
      if (_parentNationalId != null) {
        final fatherId = response.extractedData.fatherNationalId;
        final motherId = response.extractedData.motherNationalId;
        final parentIds = response.extractedData.parentNationalIds ?? [];
        
        final isValid = _parentNationalId == fatherId || 
                       _parentNationalId == motherId ||
                       parentIds.contains(_parentNationalId);
        
        if (!isValid) {
          setState(() {
            _isExtracting = false;
          });
          
          // Show warning but allow to continue
          Get.dialog(
            AlertDialog(
              title: Text('parent_id_mismatch'.tr),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${'your_id'.tr}: $_parentNationalId'),
                  if (fatherId != null) Text('${'father_id'.tr}: $fatherId'),
                  if (motherId != null) Text('${'mother_id'.tr}: $motherId'),
                  SizedBox(height: 16.h),
                  Text('parent_id_mismatch_warning'.tr),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text('cancel'.tr),
                ),
                TextButton(
                  onPressed: () {
                    Get.back();
                    setState(() {
                      _extractionResponse = response;
                      _extractedData = response.extractedData;
                      _isExtracting = false;
                      _parentIdValidated = false;
                      _currentStep = 3; // Move to review step
                    });
                  },
                  child: Text('continue_anyway'.tr),
                ),
              ],
            ),
          );
          return;
        } else {
          setState(() {
            _parentIdValidated = true;
          });
        }
      }

      setState(() {
        _extractionResponse = response;
        _extractedData = response.extractedData;
        _isExtracting = false;
        _currentStep = 3; // Move to review step
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isExtracting = false;
      });
      Get.snackbar(
        'error'.tr,
        e.toString().replaceAll('StudentsException: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
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
        nationality: _extractedData!.nationality ?? 'Egyptian',
        religion: _extractedData!.religion,
        birthPlace: _extractedData!.birthPlace,
        birthCertificate: birthCertificate,
      );

      final response = await StudentsService.addChildren(request);

      if (!mounted) return;
      Get.back(result: true);
      
      Get.snackbar(
        'success'.tr,
        response.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      Get.snackbar(
        'error'.tr,
        e.toString().replaceAll('StudentsException: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _submitNonEgyptianRequest() async {
    if (_parentPassportFile == null || _childPassportFile == null) {
      Get.snackbar(
        'error'.tr,
        'both_passports_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    if (_fullNameController.text.isEmpty && _arabicFullNameController.text.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'name_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // TODO: Implement non-Egyptian request submission
      // This requires adding a service method for POST /api/children/non-egyptian-request
      
      // For now, show a message that this feature is coming soon
      setState(() {
        _isSubmitting = false;
      });

      Get.snackbar(
        'info'.tr,
        'non_egyptian_request_coming_soon'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primaryGreen,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
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
  void dispose() {
    _fullNameController.dispose();
    _arabicFullNameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }
}

