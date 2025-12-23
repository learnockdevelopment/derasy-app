import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../models/student_models.dart';
import '../../models/school_models.dart';
import '../../services/students_service.dart';
import '../../services/schools_service.dart';

class AddChildPage extends StatefulWidget {
  const AddChildPage({Key? key}) : super(key: key);

  @override
  State<AddChildPage> createState() => _AddChildPageState();
}

class _AddChildPageState extends State<AddChildPage> {
  final _formKey = GlobalKey<FormState>();
  final _arabicFullNameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _nationalityController = TextEditingController(text: 'Egyptian');
  final _birthPlaceController = TextEditingController();
  final _currentSchoolController = TextEditingController();

  DateTime? _selectedBirthDate;
  String? _selectedGender;
  String? _selectedReligion;
  File? _birthCertificateFile;
  String? _birthCertificateBase64;
  String? _birthCertificateMimeType;
  
  // Current school selection
  String _currentSchoolOption = 'none'; // 'none', 'list', 'other'
  School? _selectedSchool;
  List<School> _schools = [];
  bool _isLoadingSchools = false;

  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  final List<String> _genderOptions = ['male', 'female'];
  final List<String> _religionOptions = ['Muslim', 'Christian', 'Jewish', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  @override
  void dispose() {
    _arabicFullNameController.dispose();
    _fullNameController.dispose();
    _nationalIdController.dispose();
    _nationalityController.dispose();
    _birthPlaceController.dispose();
    _currentSchoolController.dispose();
    super.dispose();
  }

  Future<void> _loadSchools() async {
    setState(() {
      _isLoadingSchools = true;
    });

    try {
      final response = await SchoolsService.getAllSchools();
      if (mounted) {
        setState(() {
          // Get all schools without any filtering
          _schools = response.schools;
          _isLoadingSchools = false;
        });
        print('🏫 [ADD_CHILD] Loaded ${_schools.length} schools');
        if (_schools.isEmpty) {
          print('🏫 [ADD_CHILD] Warning: No schools found');
        }
      }
    } catch (e) {
      print('🏫 [ADD_CHILD] Error loading schools: $e');
      if (mounted) {
        setState(() {
          _isLoadingSchools = false;
        });
      }
      Get.snackbar(
        'error'.tr,
        'Failed to load schools: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _pickBirthCertificate() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (image != null) {
        final file = File(image.path);
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        
        // Determine mime type
        String mimeType = 'image/jpeg';
        if (image.path.toLowerCase().endsWith('.png')) {
          mimeType = 'image/png';
        } else if (image.path.toLowerCase().endsWith('.webp')) {
          mimeType = 'image/webp';
        }

        setState(() {
          _birthCertificateFile = file;
          _birthCertificateBase64 = base64String;
          _birthCertificateMimeType = mimeType;
        });
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate that at least arabicFullName or fullName is provided
    if ((_arabicFullNameController.text.trim().isEmpty) &&
        (_fullNameController.text.trim().isEmpty)) {
      Get.snackbar(
        'error'.tr,
        'arabic_name_or_english_name_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    if (_selectedBirthDate == null) {
      Get.snackbar(
        'error'.tr,
        'birth_date_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    if (_selectedGender == null) {
      Get.snackbar(
        'error'.tr,
        'gender_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare birth certificate data if available
      Map<String, dynamic>? birthCertificate;
      if (_birthCertificateBase64 != null && _birthCertificateMimeType != null) {
        birthCertificate = {
          'data': 'data:$_birthCertificateMimeType;base64,$_birthCertificateBase64',
          'mimeType': _birthCertificateMimeType,
        };
      }

      // Determine current school
      String? currentSchool;
      if (_currentSchoolOption == 'list' && _selectedSchool != null) {
        currentSchool = _selectedSchool!.name;
      } else if (_currentSchoolOption == 'other') {
        currentSchool = _currentSchoolController.text.trim();
        if (currentSchool.isEmpty) {
          currentSchool = null;
        }
      }

      final request = AddChildRequest(
        arabicFullName: _arabicFullNameController.text.trim().isNotEmpty
            ? _arabicFullNameController.text.trim()
            : null,
        fullName: _fullNameController.text.trim().isNotEmpty
            ? _fullNameController.text.trim()
            : null,
        gender: _selectedGender!,
        birthDate: _selectedBirthDate!.toIso8601String().split('T')[0],
        nationalId: _nationalIdController.text.trim().isNotEmpty
            ? _nationalIdController.text.trim()
            : null,
        nationality: _nationalityController.text.trim().isNotEmpty
            ? _nationalityController.text.trim()
            : null,
        religion: _selectedReligion,
        birthPlace: _birthPlaceController.text.trim().isNotEmpty
            ? _birthPlaceController.text.trim()
            : null,
        currentSchool: currentSchool,
        birthCertificate: birthCertificate,
      );

      final response = await StudentsService.addChildren(request);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
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
        _isLoading = false;
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
          'child_data'.tr,
          style: AppFonts.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'fill_child_data'.tr,
                style: AppFonts.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 20.h),

              // Birth Certificate Upload
              _buildBirthCertificateUpload(),
              SizedBox(height: 20.h),

              // Arabic Full Name
              TextFormField(
                controller: _arabicFullNameController,
                style: AppFonts.bodyMedium,
                decoration: InputDecoration(
                  labelText: 'arabic_full_name'.tr + ' *',
                  labelStyle: AppFonts.bodySmall,
                  hintText: 'أدخل الاسم الكامل بالعربي',
                  prefixIcon: Icon(Icons.text_fields, color: AppColors.primaryBlue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),
              SizedBox(height: 16.h),

              // English Full Name
              TextFormField(
                controller: _fullNameController,
                style: AppFonts.bodyMedium,
                decoration: InputDecoration(
                  labelText: 'full_name_english'.tr,
                  labelStyle: AppFonts.bodySmall,
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryBlue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),
              SizedBox(height: 16.h),

              // Birth Date
              InkWell(
                onTap: _selectBirthDate,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.grey300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, color: AppColors.primaryBlue),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'birth_date'.tr + ' *',
                              style: AppFonts.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              _selectedBirthDate == null
                                  ? 'mm/dd/yyyy'
                                  : '${_selectedBirthDate!.month.toString().padLeft(2, '0')}/${_selectedBirthDate!.day.toString().padLeft(2, '0')}/${_selectedBirthDate!.year}',
                              style: AppFonts.bodyMedium.copyWith(
                                color: _selectedBirthDate == null
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Gender
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: InputDecoration(
                  labelText: 'gender'.tr + ' *',
                  labelStyle: AppFonts.bodySmall,
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryBlue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                items: _genderOptions.map((gender) {
                  return DropdownMenuItem(
                    value: gender,
                    child: Text(gender == 'male' ? 'male'.tr : 'female'.tr),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'gender_required'.tr;
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // National ID
              TextFormField(
                controller: _nationalIdController,
                style: AppFonts.bodyMedium,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'national_id'.tr,
                  labelStyle: AppFonts.bodySmall,
                  prefixIcon: Icon(Icons.badge_outlined, color: AppColors.primaryBlue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),
              SizedBox(height: 16.h),

              // Nationality
              TextFormField(
                controller: _nationalityController,
                style: AppFonts.bodyMedium,
                decoration: InputDecoration(
                  labelText: 'nationality'.tr,
                  labelStyle: AppFonts.bodySmall,
                  prefixIcon: Icon(Icons.flag_outlined, color: AppColors.primaryBlue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),
              SizedBox(height: 16.h),

              // Birth Place
              TextFormField(
                controller: _birthPlaceController,
                style: AppFonts.bodyMedium,
                decoration: InputDecoration(
                  labelText: 'birth_place'.tr,
                  labelStyle: AppFonts.bodySmall,
                  prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.primaryBlue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),
              SizedBox(height: 16.h),

              // Religion
              DropdownButtonFormField<String>(
                value: _selectedReligion,
                decoration: InputDecoration(
                  labelText: 'religion'.tr,
                  labelStyle: AppFonts.bodySmall,
                  prefixIcon: Icon(Icons.church_outlined, color: AppColors.primaryBlue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                items: _religionOptions.map((religion) {
                  return DropdownMenuItem(
                    value: religion,
                    child: Text(religion.tr),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedReligion = value;
                  });
                },
              ),
              SizedBox(height: 16.h),

              // Current School Section
              _buildCurrentSchoolSection(),
              SizedBox(height: 24.h),

              // Submit Button
              SizedBox(
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    disabledBackgroundColor: AppColors.grey300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
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
                          'add_child'.tr,
                          style: AppFonts.h4.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBirthCertificateUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'egyptian_birth_certificate'.tr,
          style: AppFonts.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: _pickBirthCertificate,
          child: Container(
            width: double.infinity,
            height: 120.h,
            decoration: BoxDecoration(
              border: Border.all(
                color: _birthCertificateFile != null
                    ? AppColors.primaryBlue
                    : AppColors.grey300,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12.r),
              color: AppColors.surface,
            ),
            child: _birthCertificateFile != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.r),
                        child: Image.file(
                          _birthCertificateFile!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8.h,
                        right: 8.w,
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16.sp,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        color: AppColors.primaryBlue,
                        size: 40.sp,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'click_to_upload_birth_certificate'.tr,
                        style: AppFonts.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'PNG, JPG, PDF up to 10MB',
                        style: AppFonts.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentSchoolSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'current_school_optional'.tr,
          style: AppFonts.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'if_child_registered_school'.tr,
          style: AppFonts.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12.sp,
          ),
        ),
        SizedBox(height: 12.h),

        // No current school option
        RadioListTile<String>(
          value: 'none',
          groupValue: _currentSchoolOption,
          onChanged: (value) {
            setState(() {
              _currentSchoolOption = value!;
              _selectedSchool = null;
              _currentSchoolController.clear();
            });
          },
          title: Text('no_current_school'.tr),
          contentPadding: EdgeInsets.zero,
        ),

        // Select from list option
        RadioListTile<String>(
          value: 'list',
          groupValue: _currentSchoolOption,
          onChanged: (value) {
            setState(() {
              _currentSchoolOption = value!;
              _currentSchoolController.clear();
            });
          },
          title: Text('select_from_list'.tr),
          contentPadding: EdgeInsets.zero,
        ),
        if (_currentSchoolOption == 'list') ...[
          SizedBox(height: 8.h),
          _isLoadingSchools
              ? const Center(child: CircularProgressIndicator())
              : _schools.isEmpty
                  ? Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.grey300),
                      ),
                      child: Text(
                        'no_schools_available'.tr,
                        style: AppFonts.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : DropdownButtonFormField<School>(
                      value: _selectedSchool,
                      decoration: InputDecoration(
                        labelText: 'select_school'.tr,
                        labelStyle: AppFonts.bodySmall,
                        prefixIcon: Icon(Icons.school_outlined, color: AppColors.primaryBlue),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                      items: _schools.map((school) {
                        return DropdownMenuItem(
                          value: school,
                          child: Text(school.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSchool = value;
                        });
                      },
                    ),
        ],

        // Enter other school option
        RadioListTile<String>(
          value: 'other',
          groupValue: _currentSchoolOption,
          onChanged: (value) {
            setState(() {
              _currentSchoolOption = value!;
              _selectedSchool = null;
            });
          },
          title: Text('enter_other_school_name'.tr),
          contentPadding: EdgeInsets.zero,
        ),
        if (_currentSchoolOption == 'other') ...[
          SizedBox(height: 8.h),
          TextFormField(
            controller: _currentSchoolController,
            style: AppFonts.bodyMedium,
            decoration: InputDecoration(
              labelText: 'school_name'.tr,
              labelStyle: AppFonts.bodySmall,
              prefixIcon: Icon(Icons.school_outlined, color: AppColors.primaryBlue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              filled: true,
              fillColor: AppColors.surface,
            ),
          ),
        ],
      ],
    );
  }
}
