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
  String? _selectedNationality;
  String? _selectedForeignCountry;
  File? _parentNationalIdFrontFile;
  File? _parentNationalIdBackFile;
  bool _isExtractingParentId = false;
  ExtractedData? _parentExtractedData;
  File? _birthCertificateFile;
  bool _isExtracting = false;
  BirthCertificateExtractionResponse? _extractionResponse;
  ExtractedData? _extractedData;
  File? _parentPassportFile;
  File? _childPassportFile;
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _arabicFullNameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  String? _selectedGender;
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();
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
      // Egyptian flow: Step 1 = Parent ID (verify), Step 2 = Child ID, Step 3 = Certificate, Step 4 = Review
      switch (_currentStep) {
        case 1:
          return _buildNewParentNationalIdStep();
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

  Widget _buildDataRow(String label, String value) {
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
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.grey300),
            ),
            child: Text(
              value,
              style: AppFonts.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCleanArabicFullNameFromData(ExtractedData extractedData) {
    // Always prefer constructing from firstName + lastName if both are available
    // First name is written first, then last name
    if (extractedData.arabicFirstName != null && extractedData.arabicLastName != null) {
      // Combine: firstName + " " + lastName
      String combinedName = '${extractedData.arabicFirstName} ${extractedData.arabicLastName}'.trim();
      
      // Clean the combined name
      combinedName = combinedName
          .replaceAll('بطاقة تحقيق الشخصية', '')
          .replaceAll('بطاقة الهوية', '')
          .replaceAll('بطاقة', '')
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .join(' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      
      // Remove address patterns if they somehow got included
      if (combinedName.contains('عمارة') || 
          combinedName.contains('مجاورة') ||
          combinedName.contains('حى') ||
          combinedName.contains('شارع') ||
          combinedName.contains('طريق')) {
        // Remove address parts
        final parts = combinedName.split(RegExp(r'عمارة|مجاورة|حى|شارع|طريق'));
        combinedName = parts.first.trim();
      }
      
      return combinedName.isNotEmpty ? combinedName : '';
    }
    
    // If we don't have both firstName and lastName, try to clean arabicFullName
    String? cleanArabicFullName = extractedData.arabicFullName;
    
    if (cleanArabicFullName != null && cleanArabicFullName.isNotEmpty) {
      // Remove unwanted text like "بطاقة تحقيق الشخصية" and addresses
      cleanArabicFullName = cleanArabicFullName
          .replaceAll('بطاقة تحقيق الشخصية', '')
          .replaceAll('بطاقة الهوية', '')
          .replaceAll('بطاقة', '')
          .trim();
      
      // Remove empty lines and extra spaces
      cleanArabicFullName = cleanArabicFullName
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .join(' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      
      // Remove address patterns
      if (cleanArabicFullName.contains('عمارة') || 
          cleanArabicFullName.contains('مجاورة') ||
          cleanArabicFullName.contains('حى') ||
          cleanArabicFullName.contains('شارع') ||
          cleanArabicFullName.contains('طريق')) {
        // Remove address parts - keep only the part before address
        final parts = cleanArabicFullName.split(RegExp(r'عمارة|مجاورة|حى|شارع|طريق'));
        cleanArabicFullName = parts.first.trim();
      }
      
      // If it's too short or still has issues, try using firstName or lastName
      if (cleanArabicFullName.length < 3) {
        if (extractedData.arabicFirstName != null && extractedData.arabicLastName != null) {
          return '${extractedData.arabicFirstName} ${extractedData.arabicLastName}'.trim();
        } else if (extractedData.arabicFirstName != null) {
          return extractedData.arabicFirstName!;
        } else if (extractedData.arabicLastName != null) {
          return extractedData.arabicLastName!;
        }
      }
      
      return cleanArabicFullName;
    }
    
    // Fallback: use firstName or lastName if available
    if (extractedData.arabicFirstName != null) {
      return extractedData.arabicFirstName!;
    } else if (extractedData.arabicLastName != null) {
      return extractedData.arabicLastName!;
    }
    
    return '';
  }

  Future<void> _showExtractedDataModal({
    required String title,
    required ExtractedData extractedData,
    required VoidCallback onAccept,
    VoidCallback? onRetry,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppFonts.h3.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20.sp,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (extractedData.nationalId != null)
                        _buildDataRow('national_id'.tr, extractedData.nationalId!),
                      if (extractedData.fullName != null)
                        _buildDataRow('full_name'.tr, extractedData.fullName!),
                      _buildDataRow('arabic_full_name'.tr, _getCleanArabicFullNameFromData(extractedData)),
                      if (extractedData.firstName != null)
                        _buildDataRow('first_name'.tr, extractedData.firstName!),
                      if (extractedData.lastName != null)
                        _buildDataRow('last_name'.tr, extractedData.lastName!),
                      if (extractedData.arabicFirstName != null)
                        _buildDataRow('arabic_first_name'.tr, extractedData.arabicFirstName!),
                      if (extractedData.arabicLastName != null)
                        _buildDataRow('arabic_last_name'.tr, extractedData.arabicLastName!),
                      if (extractedData.birthDate != null)
                        _buildDataRow('birth_date'.tr, extractedData.birthDate!),
                      if (extractedData.gender != null)
                        _buildDataRow('gender'.tr, _translateGender(extractedData.gender)),
                      if (extractedData.nationality != null)
                        _buildDataRow('nationality'.tr, _translateNationality(extractedData.nationality)),
                      if (extractedData.birthPlace != null)
                        _buildDataRow('birth_place'.tr, extractedData.birthPlace!),
                      if (extractedData.religion != null)
                        _buildDataRow('religion'.tr, _translateReligion(extractedData.religion)),
                      if (extractedData.fatherNationalId != null)
                        _buildDataRow('father_national_id'.tr, extractedData.fatherNationalId!),
                      if (extractedData.motherNationalId != null)
                        _buildDataRow('mother_national_id'.tr, extractedData.motherNationalId!),
                      if (extractedData.parentNationalIds != null && extractedData.parentNationalIds!.isNotEmpty)
                        _buildDataRow('parent_national_ids'.tr, extractedData.parentNationalIds!.join(', ')),
                      if (extractedData.ageInComingOctober != null)
                        _buildDataRow('age_in_october'.tr, _formatAgeInOctober(extractedData.ageInComingOctober)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              // Buttons Row
              Row(
                children: [
                  if (onRetry != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onRetry();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          side: BorderSide(color: AppColors.primaryBlue, width: 2),
                        ),
                        child: Text(
                          'retry'.tr,
                          style: AppFonts.bodyMedium.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ),
                  if (onRetry != null) SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onAccept();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'accept'.tr,
                        style: AppFonts.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

  // Step 2: Child National ID Upload (Egyptian)

  // Step 1: Parent National ID Upload (for verification only)

  // Step 3: Child National ID Upload (Egyptian) - This is the child ID, not certificate
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
                  Icons.badge,
                  color: Colors.white,
                  size: 36.sp,
                ),
                SizedBox(height: 12.h),
                Text(
                  'upload_child_national_id'.tr,
                  style: AppFonts.h3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6.h),
                Text(
                  'child_id_validation_desc'.tr,
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
          // Continue Button
          if (_birthCertificateFile != null)
            _isExtracting
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: CircularProgressIndicator(color: AppColors.primaryBlue),
                    ),
                  )
                : ElevatedButton(
                    onPressed: () async {
                      await _extractBirthCertificateData(_birthCertificateFile!);
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
                // Parent Data Section
                if (_parentExtractedData != null) ...[
                  Row(
                    children: [
                      Icon(IconlyBroken.profile, color: AppColors.primaryBlue, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'parent_data'.tr,
                        style: AppFonts.h3.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _buildReviewField('full_name'.tr, 
                    (_parentExtractedData!.arabicFullName != null && _parentExtractedData!.arabicFullName!.isNotEmpty)
                        ? _parentExtractedData!.arabicFullName!
                        : (_parentExtractedData!.fullName ?? '')
                  ),
                  _buildReviewField('national_id'.tr, _parentExtractedData!.nationalId ?? ''),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Divider(color: AppColors.grey300),
                  ),
                  SizedBox(height: 8.h),
                ],

                // Child Data Section
                Row(
                  children: [
                    Icon(IconlyBroken.star, color: AppColors.primaryBlue, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'child_data'.tr,
                      style: AppFonts.h3.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                _buildReviewField('full_name'.tr, 
                  _getCleanArabicFullName().isNotEmpty 
                    ? _getCleanArabicFullName() 
                    : (_extractedData!.fullName ?? 
                      (_extractedData!.firstName != null && _extractedData!.lastName != null
                        ? '${_extractedData!.firstName} ${_extractedData!.lastName}'
                        : _extractedData!.firstName ?? _extractedData!.lastName ?? ''))
                ),
                _buildReviewField('birth_date'.tr, _extractedData!.birthDate ?? ''),
                _buildReviewField('gender'.tr, _translateGender(_extractedData!.gender)),
                if (_extractedData!.nationalId != null)
                  _buildReviewField('national_id'.tr, _extractedData!.nationalId!),
                if (_extractedData!.nationality != null)
                  _buildReviewField('nationality'.tr, _translateNationality(_extractedData!.nationality)),
                if (_extractedData!.ageInComingOctober != null)
                  _buildReviewField('age_in_october'.tr, _formatAgeInOctober(_extractedData!.ageInComingOctober)),
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
      // Egyptian flow: 5 steps (nationality, parent ID, child ID, certificate, review)
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
            _buildEnhancedStepIndicator(2, _currentStep >= 1, _currentStep > 1, 'parent_id_verify'.tr),
            Expanded(child: _buildEnhancedStepLine(_currentStep > 1)),
            _buildEnhancedStepIndicator(3, _currentStep >= 2, _currentStep > 2, 'birth_certificate'.tr),
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


  Future<void> _extractBirthCertificateData(File file) async {
    setState(() {
      _isExtracting = true;
    });

    try {
      final response = await StudentsService.extractBirthCertificate(file);
      
      print('👶 [BIRTH_CERT_EXTRACT] API Response:');
      print('👶 [BIRTH_CERT_EXTRACT] Success: ${response.success}');
      print('👶 [BIRTH_CERT_EXTRACT] Document Type: ${response.documentType}');
      print('👶 [BIRTH_CERT_EXTRACT] Extracted Data:');
      print('👶 [BIRTH_CERT_EXTRACT]   - National ID: ${response.extractedData.nationalId}');
      
      if (!mounted) return;

      // Check if extraction was successful
      if (response.success != true) {
        setState(() {
          _isExtracting = false;
        });
        Get.snackbar(
          'error'.tr,
          'certificate_extraction_failed'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
        return;
      }

      // Success - we don't set isExtracting=false here yet to keep spinner until modal shows or we transition
      // Actually better to hide spinner before showing modal
      setState(() {
        _isExtracting = false;
        _extractionResponse = response;
        _extractedData = response.extractedData;
        // _childNationalId = response.extractedData.nationalId; // No longer needed as state variable
      });

      // Show modal with extracted data
      if (mounted) {
        await _showExtractedDataModal(
          title: 'extracted_data'.tr,
          extractedData: response.extractedData,
          onAccept: () {
            if (mounted) {
              setState(() {
                _currentStep = 3; // Move to review step (Step 3 is Review in 0-indexed? No, 1=Parent, 2=Cert, 3=Review)
                // Wait, logic says: 1=Parent, 2=Cert, 3=Review. So move to 3.
              });
            }
          },
          onRetry: () {
            if (mounted) {
              setState(() {
                _birthCertificateFile = null;
                _extractedData = null;
                _isExtracting = false;
              });
            }
          },
        );
      }
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


  Future<void> _extractParentNationalId([File? dummy]) async {
    if (_parentNationalIdFrontFile == null || _parentNationalIdBackFile == null) return;
    
    setState(() {
      _isExtractingParentId = true;
    });

    try {
      final response = await StudentsService.extractNationalId(
        nationalIdFront: _parentNationalIdFrontFile!,
        nationalIdBack: _parentNationalIdBackFile!,
      );
      
      print('👨 [PARENT_ID_EXTRACT] API Response:');
      print('👨 [PARENT_ID_EXTRACT] Success: ${response.success}');
      print('👨 [PARENT_ID_EXTRACT] Document Type: ${response.documentType}');
      print('👨 [PARENT_ID_EXTRACT] Extracted Data:');
      print('👨 [PARENT_ID_EXTRACT]   - National ID: ${response.extractedData.nationalId}');
      print('👨 [PARENT_ID_EXTRACT]   - Full Name: ${response.extractedData.fullName}');
      print('👨 [PARENT_ID_EXTRACT]   - Arabic Full Name: ${response.extractedData.arabicFullName}');
      print('👨 [PARENT_ID_EXTRACT]   - First Name: ${response.extractedData.firstName}');
      print('👨 [PARENT_ID_EXTRACT]   - Last Name: ${response.extractedData.lastName}');
      print('👨 [PARENT_ID_EXTRACT]   - Birth Date: ${response.extractedData.birthDate}');
      print('👨 [PARENT_ID_EXTRACT]   - Gender: ${response.extractedData.gender}');
      print('👨 [PARENT_ID_EXTRACT]   - Nationality: ${response.extractedData.nationality}');
      if (response.extractedText != null) {
        final text = response.extractedText!;
        print('👨 [PARENT_ID_EXTRACT] Extracted Text: ${text.length > 100 ? text.substring(0, 100) + "..." : text}');
      }
      
      if (!mounted) return;

      final extractedId = response.extractedData.nationalId;
      if (extractedId == null || extractedId.isEmpty) {
        throw StudentsException('parent_id_extraction_failed'.tr);
      }

      setState(() {
        _parentExtractedData = response.extractedData;
        _isExtractingParentId = false;
      });

      // Show modal with extracted data
      await _showExtractedDataModal(
        title: 'parent_id_extracted'.tr,
        extractedData: response.extractedData,
        onAccept: () {
          setState(() {
            _currentStep = 2; // Move to child ID step
          });
        },
        onRetry: () {
          if (mounted) {
            setState(() {
              _parentNationalIdFrontFile = null;
              _isExtractingParentId = false;
            });
          }
        },
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
                  final scannedFile = await Get.to(() => const CertificateScannerPage(documentType: 'child_id'));
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

      // Clean and construct Arabic full name using helper method
      String cleanArabicFullName = _getCleanArabicFullName();

      // Clean and construct English full name
      String? cleanFullName = _extractedData!.fullName;
      if (cleanFullName == null || cleanFullName.isEmpty) {
        // Construct from first and last name
        if (_extractedData!.firstName != null && _extractedData!.lastName != null) {
          cleanFullName = '${_extractedData!.firstName} ${_extractedData!.lastName}'.trim();
        } else if (_extractedData!.firstName != null) {
          cleanFullName = _extractedData!.firstName;
        } else if (_extractedData!.lastName != null) {
          cleanFullName = _extractedData!.lastName;
        }
      }

      print('📝 [SUBMIT] Cleaned Arabic Full Name: $cleanArabicFullName');
      print('📝 [SUBMIT] Cleaned English Full Name: $cleanFullName');

      // Use child's national ID from extracted birth certificate data
      final request = AddChildRequest(
        arabicFullName: cleanArabicFullName,
        fullName: cleanFullName,
        gender: _extractedData!.gender ?? 'male',
        birthDate: _extractedData!.birthDate ?? DateTime.now().toIso8601String().split('T')[0],
        nationalId: _extractedData!.nationalId ?? '', // Extracted from birth certificate
        nationality: _extractedData!.nationality ?? 'Egyptian',
        religion: _extractedData!.religion,
        birthPlace: _extractedData!.birthPlace,
        birthCertificate: birthCertificate,
      );
      
      print('📝 [SUBMIT] Using National ID: ${_extractedData!.nationalId} (from birth certificate)');

      final response = await StudentsService.addChildren(request);

      print('✅ [ADD_CHILD] API Response:');
      print('✅ [ADD_CHILD] Message: ${response.message}');
      print('✅ [ADD_CHILD] Children Count: ${response.children.length}');
      for (var i = 0; i < response.children.length; i++) {
        print('✅ [ADD_CHILD] Child ${i + 1}:');
        print('✅ [ADD_CHILD]   - ID: ${response.children[i].id}');
        print('✅ [ADD_CHILD]   - Full Name: ${response.children[i].fullName}');
        print('✅ [ADD_CHILD]   - National ID: ${response.children[i].nationalId}');
        print('✅ [ADD_CHILD]   - Nationality: ${response.children[i].nationality}');
      }

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
      final response = await StudentsService.submitNonEgyptianRequest(
        parentPassport: _parentPassportFile!,
        childPassport: _childPassportFile!,
        fullName: _fullNameController.text.isNotEmpty ? _fullNameController.text : null,
        arabicFullName: _arabicFullNameController.text.isNotEmpty ? _arabicFullNameController.text : null,
        firstName: _fullNameController.text.isNotEmpty ? _fullNameController.text.split(' ').first : null,
        lastName: _fullNameController.text.isNotEmpty && _fullNameController.text.split(' ').length > 1
            ? _fullNameController.text.split(' ').skip(1).join(' ')
            : null,
        birthDate: _birthDateController.text,
        gender: _selectedGender ?? 'male',
        nationality: _selectedForeignCountry != null
            ? Countries.getCountryByCode(_selectedForeignCountry!).name
            : 'Non-Egyptian',
      );

      print('🌍 [NON_EGYPTIAN_REQUEST] API Response:');
      print('🌍 [NON_EGYPTIAN_REQUEST] Full Response: $response');
      print('🌍 [NON_EGYPTIAN_REQUEST] Message: ${response['message']}');
      if (response['request'] != null) {
        print('🌍 [NON_EGYPTIAN_REQUEST] Request ID: ${response['request']['id']}');
        print('🌍 [NON_EGYPTIAN_REQUEST] Request Status: ${response['request']['status']}');
        print('🌍 [NON_EGYPTIAN_REQUEST] Requested At: ${response['request']['requestedAt']}');
      }

      if (!mounted) return;
      
      setState(() {
        _isSubmitting = false;
      });

      Get.back(result: true);
      
      Get.snackbar(
        'success'.tr,
        response['message']?.toString() ?? 'non_egyptian_request_submitted'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
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

  String _getCleanArabicFullName() {
    if (_extractedData == null) return '';
    
    String? cleanArabicFullName = _extractedData!.arabicFullName;
    
    if (cleanArabicFullName != null && cleanArabicFullName.isNotEmpty) {
      // Remove unwanted text like "بطاقة تحقيق الشخصية" and addresses
      cleanArabicFullName = cleanArabicFullName
          .replaceAll('بطاقة تحقيق الشخصية', '')
          .replaceAll('بطاقة الهوية', '')
          .replaceAll('بطاقة', '')
          .trim();
      
      // If it still contains unwanted patterns or is too short, reconstruct from first/last name
      if (cleanArabicFullName.length < 3 || 
          cleanArabicFullName.contains('عمارة') || 
          cleanArabicFullName.contains('مجاورة') ||
          cleanArabicFullName.contains('حى') ||
          cleanArabicFullName.contains('شارع') ||
          cleanArabicFullName.contains('طريق')) {
        // Reconstruct from first and last name
        if (_extractedData!.arabicFirstName != null && _extractedData!.arabicLastName != null) {
          cleanArabicFullName = '${_extractedData!.arabicFirstName} ${_extractedData!.arabicLastName}'.trim();
        } else if (_extractedData!.arabicFirstName != null) {
          cleanArabicFullName = _extractedData!.arabicFirstName;
        } else if (_extractedData!.arabicLastName != null) {
          cleanArabicFullName = _extractedData!.arabicLastName;
        } else {
          cleanArabicFullName = '';
        }
      }
    } else {
      // If arabicFullName is null or empty, construct from first and last name
      if (_extractedData!.arabicFirstName != null && _extractedData!.arabicLastName != null) {
        cleanArabicFullName = '${_extractedData!.arabicFirstName} ${_extractedData!.arabicLastName}'.trim();
      } else if (_extractedData!.arabicFirstName != null) {
        cleanArabicFullName = _extractedData!.arabicFirstName;
      } else if (_extractedData!.arabicLastName != null) {
        cleanArabicFullName = _extractedData!.arabicLastName;
      } else {
        cleanArabicFullName = '';
      }
    }
    
    return cleanArabicFullName ?? '';
  }

  // Helper widget for ID upload card
  Widget _buildIdUploadCard({
    required String title,
    required File? imageFile,
    required VoidCallback? onTap,
    required VoidCallback onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160.h,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(
            color: imageFile != null ? AppColors.primaryBlue : AppColors.grey300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: imageFile != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                   ClipRRect(
                    borderRadius: BorderRadius.circular(14.r),
                    child: Image.file(
                      imageFile,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: GestureDetector(
                      onTap: onClear,
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, color: Colors.white, size: 16.sp),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(IconlyBroken.upload, color: AppColors.primaryBlue, size: 32.sp),
                  SizedBox(height: 8.h),
                  Text(
                    title,
                    style: AppFonts.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  // Helper dialog for image source selection
  void _showIdImageSourceDialog({required bool isFront}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r),
              topRight: Radius.circular(24.r),
            ),
          ),
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
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.primaryBlue),
                title: Text('scan_with_camera'.tr),
                onTap: () async {
                  Navigator.pop(context);
                  final scannedFile = await Get.to(() => CertificateScannerPage(
                    documentType: isFront ? 'parent_id_front' : 'parent_id_back',
                  ));
                  if (scannedFile != null && scannedFile is File) {
                    setState(() {
                      if (isFront) {
                        _parentNationalIdFrontFile = scannedFile;
                      } else {
                        _parentNationalIdBackFile = scannedFile;
                      }
                    });
                  }
                },
              ),
              ListTile(
                leading: Icon(IconlyBroken.upload, color: AppColors.primaryGreen),
                title: Text('upload_from_gallery'.tr),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      if (isFront) {
                        _parentNationalIdFrontFile = File(image.path);
                      } else {
                        _parentNationalIdBackFile = File(image.path);
                      }
                    });
                  }
                },
              ),
              SizedBox(height: 24.h),
            ],
          ),
        );
      },
    );
  }

  // Translation helper methods for extracted data
  String _translateGender(String? gender) {
    if (gender == null || gender.isEmpty) return '';
    final lowerGender = gender.toLowerCase();
    if (lowerGender.contains('male') && !lowerGender.contains('female')) {
      return 'male'.tr;
    } else if (lowerGender.contains('female')) {
      return 'female'.tr;
    }
    return gender;
  }

  String _translateReligion(String? religion) {
    if (religion == null || religion.isEmpty) return '';
    final lowerReligion = religion.toLowerCase();
    if (lowerReligion.contains('muslim') || lowerReligion.contains('إسلام') || lowerReligion.contains('مسلم')) {
      return 'muslim'.tr;
    } else if (lowerReligion.contains('christian') || lowerReligion.contains('مسيحي')) {
      return 'christian'.tr;
    }
    return 'other_religion'.tr;
  }

  String _translateNationality(String? nationality) {
    if (nationality == null || nationality.isEmpty) return '';
    if (nationality.toLowerCase().contains('egypt') || nationality.contains('مصر')) {
      return 'egyptian'.tr;
    }
    return nationality;
  }

  String _formatAgeInOctober(AgeInComingOctober? age) {
    if (age == null) return '';
    // Always use translated format, ignoring backend formatted string if any
    return '${age.years} ${'years'.tr} ${'and'.tr} ${age.months} ${'months'.tr}';
  }

  // Rewritten for dual upload
  Widget _buildNewParentNationalIdStep() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildEnhancedStepper(),
            SizedBox(height: 32.h),
            Text(
              'parent_id_verify'.tr,
              style: AppFonts.h3.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'upload_both_sides_desc'.tr,
              style: AppFonts.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            
            // Dual Upload Cards
            Row(
              children: [
                Expanded(
                  child: _buildIdUploadCard(
                    title: 'national_id_front'.tr,
                    imageFile: _parentNationalIdFrontFile,
                    onTap: _isExtractingParentId ? null : () => _showIdImageSourceDialog(isFront: true),
                    onClear: () {
                      setState(() {
                        _parentNationalIdFrontFile = null;
                        _parentExtractedData = null;
                      });
                    },
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildIdUploadCard(
                    title: 'national_id_back'.tr,
                    imageFile: _parentNationalIdBackFile,
                    onTap: _isExtractingParentId ? null : () => _showIdImageSourceDialog(isFront: false),
                    onClear: () {
                      setState(() {
                        _parentNationalIdBackFile = null;
                        _parentExtractedData = null;
                      });
                    },
                  ),
                ),
              ],
            ),

            if (_isExtractingParentId)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'extracting_data'.tr,
                      style: AppFonts.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 16.sp,
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 32.h),
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: (_parentNationalIdFrontFile != null && _parentNationalIdBackFile != null && !_isExtractingParentId)
                    ? _extractParentNationalId
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  disabledBackgroundColor: AppColors.grey300,
                ),
                child: _isExtractingParentId
                    ? SizedBox(
                        width: 24.w,
                        height: 24.h,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'extract_data'.tr,
                        style: AppFonts.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _arabicFullNameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }
}


