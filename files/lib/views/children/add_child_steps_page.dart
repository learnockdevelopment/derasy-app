import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/countries.dart';
import '../../core/constants/assets.dart';
import '../../core/controllers/app_config_controller.dart';
import '../../models/student_models.dart';
import '../../services/students_service.dart';
import '../../widgets/animated_app_background.dart';
import 'certificate_scanner_page.dart';

enum AddChildStep {
  nationalitySelection,
  egyptianMethodSelection,
  egyptianOcrTypeSelection,
  egyptianOcrUpload,
  reviewExtractedData,
  manualForm,
  nonEgyptianForm,
  guardianOtpSelection,
  otpCodeVerification,
  success
}

class AddChildStepsPage extends StatefulWidget {
  const AddChildStepsPage({Key? key}) : super(key: key);

  @override
  State<AddChildStepsPage> createState() => _AddChildStepsPageState();
}

class _AddChildStepsPageState extends State<AddChildStepsPage> {
  // Navigation stack of steps
  final List<AddChildStep> _stepHistory = [AddChildStep.nationalitySelection];
  AddChildStep get _currentStep => _stepHistory.last;

  // Form State
  String? _selectedNationality; // 'egyptian' or 'foreign'
  String? _selectedForeignCountry;
  String? _selectedEgyptianMethod; // 'ocr' or 'manual'
  String? _selectedOcrType; // 'birth_certificate' or 'national_id'

  // Files
  File? _birthCertificateFile;
  File? _nationalIdFrontFile;
  File? _nationalIdBackFile;
  // Passport Numbers
  final _parentPassportController = TextEditingController();
  final _childPassportController = TextEditingController();

  // Form Field Controllers
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _arabicFullNameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _birthPlaceController = TextEditingController();
  final _religionController = TextEditingController();
  final _currentSchoolController = TextEditingController();
  String? _selectedGender; // 'male' or 'female'

  // Image Picker
  final ImagePicker _picker = ImagePicker();

  // Loading indicator state
  bool _isLoading = false;
  String _loadingMessage = '';

  // Duplicate / Linkage conflict state
  Map<String, dynamic>? _conflictChild;
  List<dynamic>? _conflictGuardians;
  Map<String, dynamic>? _selectedGuardian;
  String? _selectedPhoneNumber;
  final _otpController = TextEditingController();

  // Newly added student details (to display in success step)
  String _successChildName = '';

  List<Country> get _foreignCountries {
    return Countries.countries.where((country) => country.code != 'EG').toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  String _getTranslatedCountryName(String code) {
    try {
      return 'country_${code.toLowerCase()}'.tr;
    } catch (e) {
      return Countries.getCountryByCode(code).name;
    }
  }

  void _pushStep(AddChildStep step) {
    setState(() {
      _stepHistory.add(step);
    });
  }

  void _popStep() {
    if (_stepHistory.length > 1) {
      setState(() {
        _stepHistory.removeLast();
      });
    } else {
      Get.back();
    }
  }

  @override
  void initState() {
    super.initState();
    _nationalIdController.addListener(_onNationalIdChanged);
  }

  void _onNationalIdChanged() {
    final text = _nationalIdController.text.trim();
    if (text.length == 14) {
      final parsedDate = _parseBirthDateFromNationalId(text);
      if (parsedDate != null) {
        setState(() {
          _birthDateController.text = parsedDate;
        });
      }
      final genderDigit = int.tryParse(text[12]);
      if (genderDigit != null) {
        setState(() {
          _selectedGender = (genderDigit % 2 != 0) ? 'male' : 'female';
        });
      }
    }
  }

  String? _parseBirthDateFromNationalId(String nationalId) {
    if (nationalId.length != 14) return null;
    final centuryDigit = int.tryParse(nationalId[0]);
    if (centuryDigit == null) return null;

    final yearStr = nationalId.substring(1, 3);
    final monthStr = nationalId.substring(3, 5);
    final dayStr = nationalId.substring(5, 7);

    final month = int.tryParse(monthStr);
    final day = int.tryParse(dayStr);
    if (month == null || month < 1 || month > 12) return null;
    if (day == null || day < 1 || day > 31) return null;

    String century;
    if (centuryDigit == 2) {
      century = '19';
    } else if (centuryDigit == 3) {
      century = '20';
    } else {
      return null;
    }

    final year = '$century$yearStr';
    return '$year-$monthStr-$dayStr';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _arabicFullNameController.dispose();
    _nationalIdController.dispose();
    _birthDateController.dispose();
    _birthPlaceController.dispose();
    _religionController.dispose();
    _currentSchoolController.dispose();
    _otpController.dispose();
    _parentPassportController.dispose();
    _childPassportController.dispose();
    super.dispose();
  }

  // Pick Date helper
  Future<void> _selectBirthDate() async {
    final isDark = AppConfigController.to.isDarkMode;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 4)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.blue1,
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E293B),
                    onSurface: Colors.white,
                  ),
                  dialogBackgroundColor: const Color(0xFF0F172A),
                )
              : ThemeData.light().copyWith(
                  colorScheme: ColorScheme.light(
                    primary: AppColors.blue1,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: AppColors.textPrimary,
                  ),
                ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // OCR Processing Helpers
  Future<void> _processOcrBirthCertificate(File file) async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'extracting_data'.tr + '...';
    });

    try {
      final response = await StudentsService.extractBirthCertificate(file);
      final data = response.extractedData;
      
      _fullNameController.text = data.fullName ?? '';
      _arabicFullNameController.text = data.arabicFullName ?? '';
      _nationalIdController.text = data.nationalId ?? '';
      _birthDateController.text = data.birthDate ?? '';
      _selectedGender = data.gender?.toLowerCase() == 'female' ? 'female' : 'male';
      _birthPlaceController.text = data.birthPlace ?? '';
      _religionController.text = data.religion ?? '';

      _pushStep(AddChildStep.reviewExtractedData);
    } catch (e) {
      if (e is BirthCertificateExtractionException && e.canContinue) {
        Get.snackbar(
          'warning'.tr,
          e.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        // Direct to review with whatever is present
        _pushStep(AddChildStep.reviewExtractedData);
      } else {
        Get.snackbar(
          'error'.tr,
          e.toString().replaceAll('StudentsException:', '').trim(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processOcrNationalId(File front, File? back) async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'extracting_data'.tr + '...';
    });

    try {
      final response = await StudentsService.extractNationalId(
        nationalIdFront: front,
        nationalIdBack: back,
      );
      final data = response.extractedData;
      
      _fullNameController.text = data.fullName ?? '';
      _arabicFullNameController.text = data.arabicFullName ?? '';
      _nationalIdController.text = data.nationalId ?? '';
      _birthDateController.text = data.birthDate ?? '';
      _selectedGender = data.gender?.toLowerCase() == 'female' ? 'female' : 'male';
      _birthPlaceController.text = data.birthPlace ?? '';
      _religionController.text = data.religion ?? '';

      _pushStep(AddChildStep.reviewExtractedData);
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString().replaceAll('StudentsException:', '').trim(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Handle child registration submit
  Future<void> _submitChildRegistration() async {
    // Collect child certificate payload
    Map<String, dynamic>? birthCertificatePayload;
    if (_birthCertificateFile != null) {
      final bytes = await _birthCertificateFile!.readAsBytes();
      final base64String = base64Encode(bytes);
      final mimeType = _birthCertificateFile!.path.toLowerCase().endsWith('.png')
          ? 'image/png'
          : 'image/jpeg';
      birthCertificatePayload = {
        'data': 'data:$mimeType;base64,$base64String',
        'mimeType': mimeType,
      };
    }

    final request = AddChildRequest(
      fullName: _fullNameController.text.trim(),
      arabicFullName: _arabicFullNameController.text.trim(),
      birthDate: _birthDateController.text.trim(),
      gender: _selectedGender ?? 'male',
      nationalId: _nationalIdController.text.trim().isEmpty ? null : _nationalIdController.text.trim(),
      nationality: _selectedNationality == 'egyptian' ? 'Egyptian' : _selectedForeignCountry,
      religion: _religionController.text.trim().isEmpty ? null : _religionController.text.trim(),
      birthPlace: _birthPlaceController.text.trim().isEmpty ? null : _birthPlaceController.text.trim(),
      currentSchool: _currentSchoolController.text.trim().isEmpty ? null : _currentSchoolController.text.trim(),
      birthCertificate: birthCertificatePayload,
    );

    setState(() {
      _isLoading = true;
      _loadingMessage = 'submitting'.tr + '...';
    });

    try {
      final response = await StudentsService.addChildren(request);
      if (response.children.isNotEmpty) {
        setState(() {
          _successChildName = response.children.first.fullName;
        });
      } else {
        setState(() {
          _successChildName = _fullNameController.text.isEmpty
              ? _arabicFullNameController.text
              : _fullNameController.text;
        });
      }
      _pushStep(AddChildStep.success);
    } catch (e) {
      if (e is StudentsException && e.error != null) {
        final rawJson = e.error!.rawJson;
        final errorCode = e.error!.error;

        if (errorCode == 'CHILD_EXISTS' && rawJson != null) {
          // Trigger link duplicate flow
          setState(() {
            _conflictChild = rawJson['child'];
            _conflictGuardians = rawJson['guardians'];
            if (_conflictGuardians != null && _conflictGuardians!.isNotEmpty) {
              _selectedGuardian = _conflictGuardians!.first;
              final List<dynamic> phones = _selectedGuardian!['phones'] ?? [];
              _selectedPhoneNumber = phones.isNotEmpty ? phones.first.toString() : null;
            }
          });
          _pushStep(AddChildStep.guardianOtpSelection);
          return;
        }
      }

      Get.snackbar(
        'error'.tr,
        e.toString().replaceAll('StudentsException:', '').trim(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Handle foreign / non-Egyptian child registration (with files)
  Future<void> _submitNonEgyptianRegistration() async {
    if (_parentPassportController.text.trim().isEmpty || _childPassportController.text.trim().isEmpty) {
      Get.snackbar(
        'error'.tr,
        'passports_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'submitting'.tr + '...';
    });

    try {
      final response = await StudentsService.submitNonEgyptianRequest(
        parentPassportNumber: _parentPassportController.text.trim(),
        childPassportNumber: _childPassportController.text.trim(),
        fullName: _fullNameController.text.trim(),
        arabicFullName: _arabicFullNameController.text.trim().isEmpty ? null : _arabicFullNameController.text.trim(),
        birthDate: _birthDateController.text.trim(),
        gender: _selectedGender ?? 'male',
        nationality: _selectedForeignCountry,
        birthPlace: _birthPlaceController.text.trim().isEmpty ? null : _birthPlaceController.text.trim(),
        religion: _religionController.text.trim().isEmpty ? null : _religionController.text.trim(),
        currentSchool: _currentSchoolController.text.trim().isEmpty ? null : _currentSchoolController.text.trim(),
      );

      setState(() {
        _successChildName = _fullNameController.text.isEmpty
            ? _arabicFullNameController.text
            : _fullNameController.text;
      });
      _pushStep(AddChildStep.success);
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString().replaceAll('StudentsException:', '').trim(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Send Linkage OTP
  Future<void> _sendGuardianOtp() async {
    if (_conflictChild == null || _selectedGuardian == null || _selectedPhoneNumber == null) {
      Get.snackbar(
        'error'.tr,
        'please_select_guardian_and_phone'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'sending_otp'.tr + '...';
    });

    try {
      final req = SendOtpRequest(
        childId: _conflictChild!['id'] ?? _conflictChild!['_id'],
        guardianUserId: _selectedGuardian!['userId'],
        phoneNumber: _selectedPhoneNumber!,
      );

      await StudentsService.sendOtpToGuardian(req);
      _otpController.clear();
      _pushStep(AddChildStep.otpCodeVerification);
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString().replaceAll('StudentsException:', '').trim(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Verify Linkage OTP
  Future<void> _verifyGuardianOtp() async {
    if (_otpController.text.trim().length != 6) {
      Get.snackbar(
        'error'.tr,
        'enter_valid_otp'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'verifying'.tr + '...';
    });

    try {
      final req = VerifyOtpRequest(
        childId: _conflictChild!['id'] ?? _conflictChild!['_id'],
        guardianUserId: _selectedGuardian!['userId'],
        otp: _otpController.text.trim(),
      );

      await StudentsService.verifyOtpAndLinkChild(req);
      setState(() {
        _successChildName = _conflictChild!['fullName'] ?? 'Child';
      });
      _pushStep(AddChildStep.success);
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString().replaceAll('StudentsException:', '').trim(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Image Source Bottom Sheet Picker
  void _showImagePickerModal({required Function(File) onImagePicked, String documentType = 'certificate'}) {
    final isDark = AppConfigController.to.isDarkMode;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: surfaceColor,
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
                  color: isDark ? Colors.white24 : AppColors.grey300,
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
                leading: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.blue1),
                ),
                title: Text('scan_with_camera'.tr),
                onTap: () async {
                  Navigator.pop(context);
                  final file = await Get.to(() => CertificateScannerPage(documentType: documentType));
                  if (file != null && file is File) {
                    onImagePicked(file);
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: const Icon(IconlyBroken.upload, color: AppColors.blue1),
                ),
                title: Text('upload_from_gallery'.tr),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  if (image != null) {
                    onImagePicked(File(image.path));
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

  // Country Selection Custom Search Bottom Sheet
  void _showCountrySelectionSheet() {
    final isDark = AppConfigController.to.isDarkMode;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimaryColor = isDark ? Colors.white : AppColors.textPrimary;
    final countries = _foreignCountries;
    final searchController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final query = searchController.text.toLowerCase();
          final filtered = countries.where((c) {
            final name = c.name.toLowerCase();
            final trName = _getTranslatedCountryName(c.code).toLowerCase();
            return name.contains(query) || trName.contains(query);
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24.r),
                topRight: Radius.circular(24.r),
              ),
            ),
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : AppColors.grey300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  child: Text(
                    'select_country'.tr,
                    style: AppFonts.h3.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                  child: TextField(
                    controller: searchController,
                    onChanged: (_) => setModalState(() {}),
                    decoration: InputDecoration(
                      hintText: 'search'.tr,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final c = filtered[index];
                      return ListTile(
                        leading: Text(c.flag, style: TextStyle(fontSize: 24.sp)),
                        title: Text(
                          _getTranslatedCountryName(c.code),
                          style: AppFonts.bodyMedium.copyWith(color: textPrimaryColor),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedNationality = 'foreign';
                            _selectedForeignCountry = c.code;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  String _tr(String key, String fallback) {
    final t = key.tr;
    return t == key ? fallback : t;
  }

  double _getProgressPercentage() {
    switch (_currentStep) {
      case AddChildStep.nationalitySelection:
        return 0.15;
      case AddChildStep.egyptianMethodSelection:
        return 0.3;
      case AddChildStep.egyptianOcrTypeSelection:
        return 0.45;
      case AddChildStep.egyptianOcrUpload:
      case AddChildStep.manualForm:
      case AddChildStep.nonEgyptianForm:
        return 0.65;
      case AddChildStep.reviewExtractedData:
        return 0.8;
      case AddChildStep.guardianOtpSelection:
        return 0.85;
      case AddChildStep.otpCodeVerification:
        return 0.95;
      case AddChildStep.success:
        return 1.0;
    }
  }

  int _getCurrentStepNumber() {
    switch (_currentStep) {
      case AddChildStep.nationalitySelection:
        return 1;
      case AddChildStep.egyptianMethodSelection:
      case AddChildStep.egyptianOcrTypeSelection:
        return 2;
      case AddChildStep.egyptianOcrUpload:
      case AddChildStep.manualForm:
      case AddChildStep.nonEgyptianForm:
        return 3;
      case AddChildStep.reviewExtractedData:
      case AddChildStep.guardianOtpSelection:
      case AddChildStep.otpCodeVerification:
        return 4;
      case AddChildStep.success:
        return 5;
    }
  }

  Widget _buildTopProgressBar() {
    final isDark = AppConfigController.to.isDarkMode;
    final percent = _getProgressPercentage();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_tr('step', 'Step')} ${_getCurrentStepNumber()} ${_tr('of', 'of')} 5',
                style: AppFonts.bodySmall.copyWith(
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(percent * 100).toInt()}%',
                style: AppFonts.bodySmall.copyWith(
                  color: AppColors.blue1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: percent),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            builder: (context, value, child) {
              return Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 6.h,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : AppColors.grey200,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: value,
                    child: Container(
                      height: 6.h,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.blue1, AppColors.blue2],
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.blue1.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppConfigController.to.isDarkMode;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : AppColors.textPrimary,
            size: 20.sp,
          ),
          onPressed: _popStep,
        ),
        title: Text(
          'add_child'.tr,
          style: AppFonts.h3.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 24, color: isDark ? Colors.white : AppColors.textPrimary),
            onPressed: () => AppConfigController.to.toggleTheme(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedAppBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // Content
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                      child: Column(
                        children: [
                          _buildTopProgressBar(),
                          SizedBox(height: 12.h),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              key: ValueKey('header_${_currentStep}'),
                              child: _buildStepHeader(),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOutCubic,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              switchInCurve: Curves.easeInOutCubic,
                              switchOutCurve: Curves.easeInOutCubic,
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                final offsetAnimation = Tween<Offset>(
                                  begin: const Offset(0.06, 0.0),
                                  end: Offset.zero,
                                ).animate(animation);
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: offsetAnimation,
                                    child: child,
                                  ),
                                );
                              },
                              child: Container(
                                key: ValueKey('content_${_currentStep}'),
                                child: _buildGlassContainer(
                                  child: _buildCurrentStepContent(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Loader Overlay
              if (_isLoading)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: _buildGlassContainer(
                      child: Padding(
                        padding: EdgeInsets.all(24.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 60.w,
                              height: 60.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.blue1.withOpacity(0.1),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(12.w),
                                child: Image.asset(
                                  AssetsManager.logo,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            SizedBox(
                              width: 24.w,
                              height: 24.w,
                              child: const CircularProgressIndicator(color: AppColors.blue1, strokeWidth: 2),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              _loadingMessage,
                              style: AppFonts.bodyMedium.copyWith(
                                color: isDark ? Colors.white : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader() {
    final isDark = AppConfigController.to.isDarkMode;
    String stepTitle = '';
    String stepDesc = '';

    switch (_currentStep) {
      case AddChildStep.nationalitySelection:
        stepTitle = 'select_student_nationality'.tr;
        stepDesc = 'select_nationality_description'.tr;
        break;
      case AddChildStep.egyptianMethodSelection:
        stepTitle = 'select_add_method'.tr;
        stepDesc = 'choose_intelligent_or_manual_desc'.tr;
        break;
      case AddChildStep.egyptianOcrTypeSelection:
        stepTitle = 'select_document_type'.tr;
        stepDesc = 'select_document_type_desc'.tr;
        break;
      case AddChildStep.egyptianOcrUpload:
        stepTitle = _selectedOcrType == 'birth_certificate'
            ? 'birth_certificate'.tr
            : 'national_id'.tr;
        stepDesc = 'upload_document_for_ocr_desc'.tr;
        break;
      case AddChildStep.reviewExtractedData:
        stepTitle = 'scanned_details_title'.tr;
        stepDesc = 'verify_ocr_details_desc'.tr;
        break;
      case AddChildStep.manualForm:
        stepTitle = 'manual_add'.tr;
        stepDesc = 'fill_child_details_desc'.tr;
        break;
      case AddChildStep.nonEgyptianForm:
        stepTitle = 'non_egyptian_form_title'.tr;
        stepDesc = 'fill_international_details_desc'.tr;
        break;
      case AddChildStep.guardianOtpSelection:
        stepTitle = 'link_child'.tr;
        stepDesc = 'child_exists_warning'.tr;
        break;
      case AddChildStep.otpCodeVerification:
        stepTitle = 'enter_otp_code'.tr;
        stepDesc = 'otp_verification_desc'.tr;
        break;
      case AddChildStep.success:
        stepTitle = 'success'.tr;
        stepDesc = 'registration_completed_desc'.tr;
        break;
    }

    return Column(
      children: [
        Text(
          stepTitle,
          style: AppFonts.h2.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 6.h),
        Text(
          stepDesc,
          style: AppFonts.bodyMedium.copyWith(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
            fontSize: 13.sp,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGlassContainer({required Widget child}) {
    final isDark = AppConfigController.to.isDarkMode;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0x33000000) : const Color(0x55FFFFFF),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.white60,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: child,
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case AddChildStep.nationalitySelection:
        return _buildNationalitySelection();
      case AddChildStep.egyptianMethodSelection:
        return _buildEgyptianMethodSelection();
      case AddChildStep.egyptianOcrTypeSelection:
        return _buildEgyptianOcrTypeSelection();
      case AddChildStep.egyptianOcrUpload:
        return _buildEgyptianOcrUpload();
      case AddChildStep.reviewExtractedData:
        return _buildReviewExtractedData();
      case AddChildStep.manualForm:
        return _buildManualForm(isEgyptian: true);
      case AddChildStep.nonEgyptianForm:
        return _buildManualForm(isEgyptian: false);
      case AddChildStep.guardianOtpSelection:
        return _buildGuardianOtpSelection();
      case AddChildStep.otpCodeVerification:
        return _buildOtpCodeVerification();
      case AddChildStep.success:
        return _buildSuccess();
    }
  }

  Widget _buildModernChoiceCard({
    required String title,
    required String desc,
    required Widget visual,
    required Color glowColor,
    required bool isDark,
  }) {
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimaryColor = isDark ? Colors.white : AppColors.textPrimary;
    final textSecondaryColor = isDark ? Colors.white70 : AppColors.textSecondary;

    return Container(
      height: 190.h,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: glowColor.withOpacity(isDark ? 0.3 : 0.15),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(isDark ? 0.15 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Stack(
          children: [
            Positioned(
              right: -30.w,
              top: -30.h,
              child: Container(
                width: 120.w,
                height: 120.h,
                decoration: BoxDecoration(
                  color: glowColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  visual,
                  SizedBox(height: 12.h),
                  Text(
                    title,
                    style: AppFonts.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textPrimaryColor,
                      fontSize: 15.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    desc,
                    style: AppFonts.bodySmall.copyWith(
                      color: textSecondaryColor,
                      fontSize: 10.5.sp,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Nationality Selection Step
  Widget _buildNationalitySelection() {
    final isDark = AppConfigController.to.isDarkMode;

    return Row(
      children: [
        // Egyptian Card
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedNationality = 'egyptian';
              });
              _pushStep(AddChildStep.egyptianMethodSelection);
            },
            child: _buildModernChoiceCard(
              title: _tr('egyptian', 'Egyptian'),
              desc: _tr('egyptian_nationality_desc', 'Egyptian National ID / OCR registration'),
              visual: Text('🇪🇬', style: TextStyle(fontSize: 42.sp)),
              glowColor: Colors.redAccent,
              isDark: isDark,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        // International/Other Card
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedNationality = 'foreign';
                _selectedForeignCountry = null;
              });
              _pushStep(AddChildStep.nonEgyptianForm);
            },
            child: _buildModernChoiceCard(
              title: _tr('other_nationalities', 'International'),
              desc: _tr('select_nationality_description', 'Other nationalities & passports'),
              visual: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.public, color: AppColors.blue1, size: 32.sp),
              ),
              glowColor: AppColors.blue1,
              isDark: isDark,
            ),
          ),
        ),
      ],
    );
  }

  // 2. Egyptian Add Method (Intelligent vs Manual)
  Widget _buildEgyptianMethodSelection() {
    final isDark = AppConfigController.to.isDarkMode;

    return Row(
      children: [
        // Intelligent / OCR Card
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedEgyptianMethod = 'ocr';
              });
              _pushStep(AddChildStep.egyptianOcrTypeSelection);
            },
            child: _buildModernChoiceCard(
              title: _tr('intelligent_add', 'Intelligent Add'),
              desc: _tr('intelligent_add_desc', 'Scan document using camera to auto-fill details'),
              visual: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(IconlyBroken.scan, color: Colors.purple, size: 32.sp),
              ),
              glowColor: Colors.purple,
              isDark: isDark,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        // Manual Card
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedEgyptianMethod = 'manual';
                _birthCertificateFile = null;
                _nationalIdFrontFile = null;
                _nationalIdBackFile = null;
                _fullNameController.clear();
                _arabicFullNameController.clear();
                _nationalIdController.clear();
                _birthDateController.clear();
                _birthPlaceController.clear();
                _religionController.clear();
                _parentPassportController.clear();
                _childPassportController.clear();
                _selectedGender = null;
              });
              _pushStep(AddChildStep.manualForm);
            },
            child: _buildModernChoiceCard(
              title: _tr('manual_add', 'Manual Add'),
              desc: _tr('manual_add_desc', 'Manually type child registration details'),
              visual: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(IconlyBroken.edit, color: Colors.orange, size: 32.sp),
              ),
              glowColor: Colors.orange,
              isDark: isDark,
            ),
          ),
        ),
      ],
    );
  }

  // 3. Select OCR Document Type (Birth Certificate or National ID)
  Widget _buildEgyptianOcrTypeSelection() {
    final isDark = AppConfigController.to.isDarkMode;

    return Row(
      children: [
        // Birth Certificate
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedOcrType = 'birth_certificate';
                _birthCertificateFile = null;
              });
              _pushStep(AddChildStep.egyptianOcrUpload);
            },
            child: _buildModernChoiceCard(
              title: _tr('birth_certificate', 'Birth Certificate'),
              desc: _tr('upload_birth_certificate', 'Scan child\'s official Egyptian birth certificate'),
              visual: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(IconlyBroken.document, color: Colors.blue, size: 32.sp),
              ),
              glowColor: Colors.blue,
              isDark: isDark,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        // National ID
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedOcrType = 'national_id';
                _nationalIdFrontFile = null;
                _nationalIdBackFile = null;
              });
              _pushStep(AddChildStep.egyptianOcrUpload);
            },
            child: _buildModernChoiceCard(
              title: _tr('national_id', 'National ID'),
              desc: _tr('upload_child_national_id', 'Scan front and back of child\'s National ID'),
              visual: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.badge_outlined, color: Colors.teal, size: 32.sp),
              ),
              glowColor: Colors.teal,
              isDark: isDark,
            ),
          ),
        ),
      ],
    );
  }

  // 4. Egyptian OCR Upload
  Widget _buildEgyptianOcrUpload() {
    final isDark = AppConfigController.to.isDarkMode;

    if (_selectedOcrType == 'birth_certificate') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildUploadBox(
            title: 'click_to_upload_birth_certificate'.tr,
            file: _birthCertificateFile,
            onTap: () => _showImagePickerModal(
              onImagePicked: (file) {
                setState(() {
                  _birthCertificateFile = file;
                });
              },
              documentType: 'certificate',
            ),
          ),
          SizedBox(height: 24.h),
          if (_birthCertificateFile != null)
            ElevatedButton(
              onPressed: () => _processOcrBirthCertificate(_birthCertificateFile!),
              style: _buildButtonStyle(),
              child: Text('extract_and_validate'.tr, style: const TextStyle(color: Colors.white)),
            ),
        ],
      );
    } else {
      // National ID front & back
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'upload_national_id_front'.tr + ' *',
            style: AppFonts.bodyMedium.copyWith(
              color: isDark ? Colors.white70 : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          _buildUploadBox(
            title: 'upload_national_id_front'.tr,
            file: _nationalIdFrontFile,
            onTap: () => _showImagePickerModal(
              onImagePicked: (file) {
                setState(() {
                  _nationalIdFrontFile = file;
                });
              },
              documentType: 'child_id',
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'upload_national_id_back'.tr + ' (' + 'optional'.tr + ')',
            style: AppFonts.bodyMedium.copyWith(
              color: isDark ? Colors.white70 : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          _buildUploadBox(
            title: 'upload_national_id_back'.tr,
            file: _nationalIdBackFile,
            onTap: () => _showImagePickerModal(
              onImagePicked: (file) {
                setState(() {
                  _nationalIdBackFile = file;
                });
              },
              documentType: 'child_id',
            ),
          ),
          SizedBox(height: 24.h),
          if (_nationalIdFrontFile != null)
            ElevatedButton(
              onPressed: () => _processOcrNationalId(_nationalIdFrontFile!, _nationalIdBackFile),
              style: _buildButtonStyle(),
              child: Text('extract_and_validate'.tr, style: const TextStyle(color: Colors.white)),
            ),
        ],
      );
    }
  }

  // 5. Review Extracted Data Screen (OCR Results)
  Widget _buildReviewExtractedData() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _fullNameController,
            label: 'full_name'.tr + ' (English)',
            icon: Icons.person_outline,
            validator: (val) => val == null || val.isEmpty ? 'field_required'.tr : null,
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            controller: _arabicFullNameController,
            label: 'arabic_full_name'.tr,
            icon: Icons.person_outline,
            validator: (val) => val == null || val.isEmpty ? 'field_required'.tr : null,
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            controller: _nationalIdController,
            label: 'national_id'.tr,
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            validator: (val) {
              if (val == null || val.isEmpty) return 'field_required'.tr;
              if (val.length != 14) return 'national_id_must_be_14_digits'.tr;
              return null;
            },
          ),
          SizedBox(height: 16.h),
          _buildDatePickerField(
            controller: _birthDateController,
            label: 'birth_date'.tr,
            onTap: _selectBirthDate,
            enabled: _selectedNationality != 'egyptian',
          ),
          SizedBox(height: 16.h),
          _buildGenderSelector(),
          SizedBox(height: 16.h),
          _buildTextField(
            controller: _birthPlaceController,
            label: 'birth_place'.tr,
            icon: Icons.location_on_outlined,
          ),
          SizedBox(height: 16.h),
          _buildReligionSelector(),
          SizedBox(height: 16.h),
          _buildTextField(
            controller: _currentSchoolController,
            label: 'current_school'.tr + ' (' + 'optional'.tr + ')',
            icon: Icons.school_outlined,
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _submitChildRegistration();
              }
            },
            style: _buildButtonStyle(),
            child: Text('add_child'.tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 6. Manual Registration Form (Egyptian or Foreign)
  Widget _buildManualForm({required bool isEgyptian}) {
    final isDark = AppConfigController.to.isDarkMode;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isEgyptian) ...[
            GestureDetector(
              onTap: _showCountrySelectionSheet,
              child: AbsorbPointer(
                child: TextFormField(
                  key: ValueKey('country_field_${_selectedForeignCountry}'),
                  decoration: _buildInputDecoration(
                    'select_country'.tr + ' *',
                    Icons.public,
                  ),
                  controller: TextEditingController(
                    text: _selectedForeignCountry != null
                        ? _getTranslatedCountryName(_selectedForeignCountry!)
                        : '',
                  ),
                  style: AppFonts.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  validator: (val) {
                    if (_selectedForeignCountry == null) {
                      return 'please_select_country'.tr;
                    }
                    return null;
                  },
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],
          _buildTextField(
            controller: _fullNameController,
            label: 'full_name'.tr + ' (English)',
            icon: Icons.person_outline,
            validator: (val) => val == null || val.isEmpty ? 'field_required'.tr : null,
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            controller: _arabicFullNameController,
            label: 'arabic_full_name'.tr + (isEgyptian ? ' *' : ' (' + 'optional'.tr + ')'),
            icon: Icons.person_outline,
            validator: isEgyptian ? (val) => val == null || val.isEmpty ? 'field_required'.tr : null : null,
          ),
          SizedBox(height: 16.h),
          if (isEgyptian) ...[
            _buildTextField(
              controller: _nationalIdController,
              label: 'national_id'.tr + ' *',
              icon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val == null || val.isEmpty) return 'field_required'.tr;
                if (val.length != 14) return 'national_id_must_be_14_digits'.tr;
                return null;
              },
            ),
            SizedBox(height: 16.h),
          ],
          _buildDatePickerField(
            controller: _birthDateController,
            label: 'birth_date'.tr + ' *',
            onTap: _selectBirthDate,
            enabled: !isEgyptian,
          ),
          SizedBox(height: 16.h),
          _buildGenderSelector(),
          SizedBox(height: 16.h),
          _buildTextField(
            controller: _birthPlaceController,
            label: 'birth_place'.tr,
            icon: Icons.location_on_outlined,
          ),
          SizedBox(height: 16.h),
          _buildReligionSelector(),
          SizedBox(height: 16.h),
          if (!isEgyptian) ...[
            SizedBox(height: 16.h),
            _buildTextField(
              controller: _childPassportController,
              label: 'child_passport'.tr + ' *',
              icon: Icons.badge_outlined,
              validator: (val) => val == null || val.isEmpty ? 'field_required'.tr : null,
            ),
          ],
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                if (isEgyptian) {
                  _submitChildRegistration();
                } else {
                  if (_parentPassportController.text.isNotEmpty && _childPassportController.text.isNotEmpty) {
                    _submitNonEgyptianRegistration();
                  } else {
                    _submitChildRegistration();
                  }
                }
              }
            },
            style: _buildButtonStyle(),
            child: Text('add_child'.tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 7. Guardian OTP Selection (Duplicate Linkage step 1)
  Widget _buildGuardianOtpSelection() {
    final isDark = AppConfigController.to.isDarkMode;
    final textPrimaryColor = isDark ? Colors.white : AppColors.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'child_exists_warning'.tr,
                  style: AppFonts.bodySmall.copyWith(color: textPrimaryColor),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        Text(
          'guardian_selection_title'.tr,
          style: AppFonts.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: textPrimaryColor),
        ),
        SizedBox(height: 10.h),
        if (_conflictGuardians != null && _conflictGuardians!.isNotEmpty)
          DropdownButtonFormField<Map<String, dynamic>>(
            value: _selectedGuardian,
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            decoration: _buildInputDecoration('guardian'.tr, Icons.person_outline),
            items: _conflictGuardians!.map((g) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: g as Map<String, dynamic>,
                child: Text(
                  '${g['name'] ?? 'Guardian'} (${g['relation'] ?? ''})',
                  style: AppFonts.bodyMedium.copyWith(color: textPrimaryColor),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedGuardian = value;
                  final List<dynamic> phones = _selectedGuardian!['phones'] ?? [];
                  _selectedPhoneNumber = phones.isNotEmpty ? phones.first.toString() : null;
                });
              }
            },
          ),
        SizedBox(height: 20.h),
        if (_selectedGuardian != null) ...[
          Text(
            'phone'.tr,
            style: AppFonts.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: textPrimaryColor),
          ),
          SizedBox(height: 10.h),
          DropdownButtonFormField<String>(
            value: _selectedPhoneNumber,
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            decoration: _buildInputDecoration('phone'.tr, Icons.phone_android_outlined),
            items: ((_selectedGuardian!['phones'] ?? []) as List<dynamic>).map((phone) {
              return DropdownMenuItem<String>(
                value: phone.toString(),
                child: Text(
                  phone.toString(),
                  style: AppFonts.bodyMedium.copyWith(color: textPrimaryColor),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedPhoneNumber = value;
              });
            },
          ),
        ],
        SizedBox(height: 30.h),
        ElevatedButton(
          onPressed: _sendGuardianOtp,
          style: _buildButtonStyle(),
          child: Text('send_verification_code'.tr, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  // 8. OTP Code Verification (Duplicate Linkage step 2)
  Widget _buildOtpCodeVerification() {
    final isDark = AppConfigController.to.isDarkMode;
    final textPrimaryColor = isDark ? Colors.white : AppColors.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          controller: _otpController,
          label: 'enter_otp_code'.tr,
          icon: Icons.lock_outline,
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        SizedBox(height: 10.h),
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColors.blue1.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.blue1),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'test_otp_helper'.tr,
                  style: AppFonts.bodySmall.copyWith(color: textPrimaryColor),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 30.h),
        ElevatedButton(
          onPressed: _verifyGuardianOtp,
          style: _buildButtonStyle(),
          child: Text('verify_and_link'.tr, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  // 9. Success Step
  Widget _buildSuccess() {
    final isDark = AppConfigController.to.isDarkMode;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 48,
          ),
        ),
        SizedBox(height: 24.h),
        Text(
          _conflictChild != null
              ? 'linking_success'.tr
              : 'registration_success'.tr,
          style: AppFonts.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12.h),
        Text(
          _successChildName,
          style: AppFonts.h2.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.blue1,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 32.h),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // Return success to the caller screen
              Get.back(result: true);
            },
            style: _buildButtonStyle(),
            child: Text('done'.tr, style: const TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  // Upload Area Widget
  Widget _buildUploadBox({
    required String title,
    required File? file,
    required VoidCallback onTap,
  }) {
    final isDark = AppConfigController.to.isDarkMode;
    final textPrimaryColor = isDark ? Colors.white : AppColors.textPrimary;
    final textSecondaryColor = isDark ? Colors.grey : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 140.h,
        decoration: BoxDecoration(
          border: Border.all(
            color: file != null ? AppColors.blue1 : (isDark ? Colors.white24 : AppColors.grey300),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16.r),
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
        ),
        child: file != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14.r),
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
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(IconlyBroken.upload, color: AppColors.blue1, size: 36),
                  SizedBox(height: 8.h),
                  Text(
                    title,
                    style: AppFonts.bodySmall.copyWith(
                      color: textPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'PNG, JPG up to 10MB',
                    style: AppFonts.bodySmall.copyWith(color: textSecondaryColor, fontSize: 11.sp),
                  ),
                ],
              ),
      ),
    );
  }

  // Gender Selector Widget
  Widget _buildGenderSelector() {
    final isDark = AppConfigController.to.isDarkMode;
    final textPrimaryColor = isDark ? Colors.white : AppColors.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'gender'.tr + ' *',
          style: AppFonts.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: textPrimaryColor,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGender = 'male';
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: _selectedGender == 'male'
                        ? AppColors.blue1
                        : (isDark ? const Color(0xFF1E293B) : Colors.white),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: _selectedGender == 'male'
                          ? AppColors.blue1
                          : (isDark ? Colors.white10 : AppColors.grey300),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'male'.tr,
                      style: AppFonts.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _selectedGender == 'male'
                            ? Colors.white
                            : (isDark ? Colors.white70 : AppColors.textPrimary),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGender = 'female';
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: _selectedGender == 'female'
                        ? AppColors.blue1
                        : (isDark ? const Color(0xFF1E293B) : Colors.white),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: _selectedGender == 'female'
                          ? AppColors.blue1
                          : (isDark ? Colors.white10 : AppColors.grey300),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'female'.tr,
                      style: AppFonts.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _selectedGender == 'female'
                            ? Colors.white
                            : (isDark ? Colors.white70 : AppColors.textPrimary),
                      ),
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

  // Text Field Widget
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      validator: validator,
      decoration: _buildInputDecoration(label, icon),
      style: AppFonts.bodyMedium.copyWith(
        color: AppConfigController.to.isDarkMode ? Colors.white : AppColors.textPrimary,
      ),
    );
  }

  // Date Picker Field Widget
  Widget _buildDatePickerField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final isDark = AppConfigController.to.isDarkMode;
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: enabled ? onTap : null,
      validator: (val) => val == null || val.isEmpty ? 'field_required'.tr : null,
      decoration: _buildInputDecoration(label, Icons.calendar_today_outlined).copyWith(
        filled: true,
        fillColor: enabled
            ? (isDark ? const Color(0xFF1E293B) : Colors.white)
            : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200]),
      ),
      style: AppFonts.bodyMedium.copyWith(
        color: enabled
            ? (isDark ? Colors.white : AppColors.textPrimary)
            : (isDark ? Colors.white30 : Colors.grey),
      ),
    );
  }

  Widget _buildReligionSelector() {
    final isDark = AppConfigController.to.isDarkMode;
    final textPrimaryColor = isDark ? Colors.white : AppColors.textPrimary;
    final religions = ['Muslim', 'Christian', 'Other'];

    String? currentValue;
    if (_religionController.text.isNotEmpty) {
      final matched = religions.firstWhere(
        (r) => r.toLowerCase() == _religionController.text.trim().toLowerCase(),
        orElse: () => '',
      );
      if (matched.isNotEmpty) {
        currentValue = matched;
      } else {
        currentValue = 'Other';
      }
    }

    return DropdownButtonFormField<String>(
      value: currentValue,
      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      decoration: _buildInputDecoration('religion'.tr, Icons.wb_sunny_outlined),
      style: AppFonts.bodyMedium.copyWith(color: textPrimaryColor),
      items: religions.map((r) {
        return DropdownMenuItem<String>(
          value: r,
          child: Text(
            r.toLowerCase().tr,
            style: AppFonts.bodyMedium.copyWith(color: textPrimaryColor),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _religionController.text = value;
          });
        }
      },
    );
  }

  // Input Decoration Helper
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    final isDark = AppConfigController.to.isDarkMode;
    final secondaryTextColor = isDark ? Colors.white70 : AppColors.textSecondary;
    final borderColor = isDark ? Colors.white10 : AppColors.grey300;

    return InputDecoration(
      labelText: label,
      labelStyle: AppFonts.bodyMedium.copyWith(color: secondaryTextColor),
      prefixIcon: Icon(icon, color: AppColors.blue1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColors.blue1, width: 2),
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      counterText: '',
    );
  }

  // Button Style Helper
  ButtonStyle _buildButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.blue1,
      padding: EdgeInsets.symmetric(vertical: 16.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      elevation: 2,
    );
  }
}
