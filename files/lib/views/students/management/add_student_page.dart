import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../models/student_models.dart';
import '../../../services/students_service.dart';
import '../../../services/grades_service.dart';
import '../../../utils/egyptian_national_id_parser.dart';
import '../data/student_details_page.dart';
import '../../../widgets/step_navigation.dart';
import '../../../widgets/error_prompts.dart';
import '../../../widgets/enhanced_address_field.dart';

class AddStudentPage extends StatefulWidget {
  const AddStudentPage({Key? key}) : super(key: key);

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps =
      6; // Identity, Age & Birth, Name & Grade, Address, Medical, Completion

  // Form controllers
  final _nationalityController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _passportController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _addressController = TextEditingController();

  // Form data
  String _selectedNationality = '';
  String _selectedGrade = '';
  DateTime? _selectedBirthdate;
  String _calculatedAge = '';
  String _selectedGender = '';
  double? _selectedLatitude;
  double? _selectedLongitude;

  // Data
  List<Grade> _grades = [];
  bool _isLoading = false;
  String? _schoolId;

  final List<String> _nationalities = ['Egyptian', 'Other'];

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    _schoolId = args?['schoolId'];
    print('🎓 [INIT] AddStudentPage initialized with schoolId: $_schoolId');
    print('🎓 [INIT] Arguments received: $args');
    _loadGrades();
  }

  @override
  void dispose() {
    _nationalityController.dispose();
    _nationalIdController.dispose();
    _passportController.dispose();
    _fullNameController.dispose();
    _addressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step >= 0 && step < _totalSteps) {
      setState(() {
        _currentStep = step;
      });
      _pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _loadGrades() async {
    print('🎓 [GRADES] Loading grades for schoolId: $_schoolId');

    if (_schoolId == null) {
      print('❌ [GRADES] No schoolId provided');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🎓 [GRADES] Calling GradesService.getAllGrades...');
      final response = await GradesService.getAllGrades(_schoolId!);
      print(
          '🎓 [GRADES] Response received: success=${response.success}, grades count=${response.grades.length}');

      if (response.success) {
        setState(() {
          _grades = response.grades;
        });
        print(
            '✅ [GRADES] Grades loaded successfully: ${_grades.length} grades');
        print('✅ [GRADES] Grade names: ${_grades.map((g) => g.name).toList()}');
        print('✅ [GRADES] Grade IDs: ${_grades.map((g) => g.id).toList()}');
      } else {
        print('❌ [GRADES] Failed to load grades: ${response.message}');
        Get.snackbar(
          'error'.tr,
          'failed_to_load_grades'.tr + ': ${response.message}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFEF4444),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('💥 [GRADES] Error loading grades: $e');
        Get.snackbar(
          'error'.tr,
        'failed_to_load_grades'.tr + ': ${e.toString()}',
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

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onNationalIdChanged(String value) {
    // Clear previous data when changing
    setState(() {
      _calculatedAge = '';
      _selectedBirthdate = null;
      _selectedGender = '';
    });
  }

  void _generateDataFromNationalId() {
    final nationalId = _nationalIdController.text.trim();

    if (nationalId.length != 14) {
      ErrorPrompts.showError(
        title: 'invalid_national_id_title'.tr,
        message: 'invalid_national_id_message'.tr,
      );
      return;
    }

    try {
      final parsedData = EgyptianNationalIdParser.parseNationalId(nationalId);
      if (parsedData['isValid'] == true) {
        setState(() {
          _calculatedAge = parsedData['age'].toString();
          _selectedBirthdate = parsedData['birthDate'] as DateTime?;
          _selectedGender = parsedData['gender'] as String? ?? '';
        });

        // Show success message
        Get.snackbar(
          'success'.tr,
          'data_extracted_from_id'.tr,
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );
      } else {
        ErrorPrompts.showError(
          title: 'invalid_national_id_title'.tr,
          message: 'correct_id_number'.tr,
        );
      }
    } catch (e) {
      print('Error parsing national ID: $e');
      ErrorPrompts.showError(
        title: 'error'.tr,
        message: 'failed_parse_national_id'.tr,
      );
    }
  }

  Future<void> _createStudent() async {
    if (_schoolId == null) {
      Get.snackbar(
        'error'.tr,
        'school_id_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = AddStudentRequest(
        fullName: _fullNameController.text.trim(),
        grade: _selectedGrade,
        ageInOctober: _calculatedAge,
        birthDate: _selectedBirthdate?.toIso8601String().split('T')[0] ?? '',
        gender: _selectedGender,
        nationality: _selectedNationality,
        nationalId: _selectedNationality == 'Egyptian'
            ? _nationalIdController.text.trim()
            : '',
        passport: _selectedNationality == 'Other'
            ? _passportController.text.trim()
            : null,
        address: _addressController.text.trim(),
        status: 'active',
        medicalNotes: '',
      );
      print(
          '📍 [ADDRESS] Selected coordinates: $_selectedLatitude, $_selectedLongitude');

      final response = await StudentsService.addStudent(_schoolId!, request);

      if (response.success) {
        Get.snackbar(
          'success'.tr,
          'student_created_successfully'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
        );

        // Navigate to student details page
        Get.off(() => StudentDetailsPage(
              student: response.student!,
              schoolId: _schoolId,
            ));
      } else {
        if (response.message.toLowerCase().contains('existed')) {
          _showExistedDialog();
        } else {
          Get.snackbar(
            'error'.tr,
            response.message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFEF4444),
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'error_adding_student'.tr + ': ${e.toString()}',
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

  void _showExistedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: const Color(0xFFF59E0B),
              size: 24.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              'account_already_exists'.tr,
              style: AppFonts.h3.copyWith(
                color: const Color(0xFF1F2937),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'duplicate_student'.tr,
          style: AppFonts.bodyMedium.copyWith(
            color: const Color(0xFF6B7280),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'ok'.tr,
              style: AppFonts.bodyMedium.copyWith(
                color: const Color(0xFF3B82F6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        title: Text(
          'add_student_title'.tr,
          style: AppFonts.h2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white, size: 18),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          // Step Navigation
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A8A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: StepNavigation(
              currentStep: _currentStep,
              totalSteps: StudentSteps.addSteps.length,
              steps: StudentSteps.addSteps,
              onStepTap: (step) {
                // In add mode, only allow going forward sequentially
                if (step <= _currentStep + 1) {
                  _goToStep(step);
                }
              },
              allowJumping: false, // Sequential steps only for add
            ),
          ),

          // Form Content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: [
                _buildNationalityStep(),
                _buildIdentityStep(),
                _buildPersonalInfoStep(),
                _buildAddressStep(),
                _buildMedicalStep(),
                _buildCompletionStep(),
              ],
            ),
          ),

          // Navigation Buttons
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        side: const BorderSide(color: Color(0xFF6B7280)),
                      ),
                      child: Text(
                        'previous_step'.tr,
                        style: AppFonts.bodyMedium.copyWith(
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (_currentStep > 0) SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentStep == _totalSteps - 1
                        ? _createStudent
                        : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
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
                            _currentStep == _totalSteps - 1
                                ? 'create_account_cta'.tr
                                : 'next_step'.tr,
                            style: AppFonts.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
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

  Widget _buildNationalityStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Box
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3B82F6).withOpacity(0.08),
                  const Color(0xFF1E40AF).withOpacity(0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: const Color(0xFF3B82F6).withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.public_rounded,
                        color: const Color(0xFF3B82F6),
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'select_nationality'.tr,
                            style: AppFonts.h3.copyWith(
                              color: const Color(0xFF1F2937),
                              fontWeight: FontWeight.bold,
                              
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'choose_nationality_documents'.tr,
                            style: AppFonts.bodySmall.copyWith(
                              color: const Color(0xFF6B7280),
                              
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // Options Container
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: _nationalities
                  .map((nationality) =>
                      _buildModernNationalityOption(nationality))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildModernNationalityOption(String nationality) {
    final isSelected = _selectedNationality == nationality;
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF3B82F6).withOpacity(0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF3B82F6).withOpacity(0.3)
              : const Color(0xFFE5E7EB),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedNationality = nationality;
          });
          _nextStep();
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF6B7280).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  nationality == 'Egyptian'
                      ? Icons.flag_rounded
                      : Icons.public_rounded,
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nationality == 'Egyptian' ? 'egyptian'.tr : 'other'.tr,
                      style: AppFonts.bodyMedium.copyWith(
                        color: isSelected
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFF1F2937),
                        fontWeight: FontWeight.w600,
                        
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      nationality == 'Egyptian'
                          ? 'national_id_required'.tr
                          : 'passport_required'.tr,
                      style: AppFonts.bodySmall.copyWith(
                        color: const Color(0xFF6B7280),
                        
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16.sp,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdentityStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Box
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3B82F6).withOpacity(0.08),
                  const Color(0xFF1E40AF).withOpacity(0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: const Color(0xFF3B82F6).withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.fingerprint_rounded,
                    color: const Color(0xFF3B82F6),
                    size: 18.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'identity_information'.tr,
                        style: AppFonts.h3.copyWith(
                          color: const Color(0xFF1F2937),
                          fontWeight: FontWeight.bold,
                          
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _selectedNationality == 'Egyptian'
                            ? 'enter_14_digit_national_id'.tr
                            : 'enter_passport_number'.tr,
                        style: AppFonts.bodySmall.copyWith(
                          color: const Color(0xFF6B7280),
                          
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // Input Section
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildEnhancedTextField(
                  controller: _selectedNationality == 'Egyptian'
                      ? _nationalIdController
                      : _passportController,
                  label: _selectedNationality == 'Egyptian'
                      ? 'national_id'.tr
                      : 'passport'.tr,
                  hint: _selectedNationality == 'Egyptian'
                      ? 'enter_14_digit_national_id'.tr
                      : 'enter_passport_number'.tr,
                  icon: _selectedNationality == 'Egyptian'
                      ? Icons.badge_rounded
                      : Icons.credit_card_rounded,
                  onChanged: _selectedNationality == 'Egyptian'
                      ? (value) => _onNationalIdChanged(value)
                      : null,
                  maxLength: _selectedNationality == 'Egyptian' ? 14 : null,
                  keyboardType: TextInputType.number,
                ),

                // Save Button for National ID
                if (_selectedNationality == 'Egyptian') ...[
                  SizedBox(height: 20.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _nationalIdController.text.length == 14
                          ? _generateDataFromNationalId
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _nationalIdController.text.length == 14
                            ? const Color(0xFF10B981)
                            : const Color(0xFF9CA3AF),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      icon: Icon(
                        Icons.auto_fix_high_rounded,
                        size: 20.sp,
                      ),
                      label: Text(
                        'generate_data_from_national_id'.tr,
                        style: AppFonts.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_selectedNationality == 'Egyptian' &&
              (_calculatedAge.isNotEmpty || _selectedBirthdate != null)) ...[
            SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: const Color(0xFF10B981),
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'data_extracted_successfully'.tr,
                        style: AppFonts.bodyMedium.copyWith(
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      _buildExtractedData('age'.tr, _calculatedAge),
                      SizedBox(width: 16.w),
                      _buildExtractedData('gender'.tr, _selectedGender),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      _buildExtractedData(
                          'birthdate'.tr, _formatBirthdate(_selectedBirthdate!)),
                      SizedBox(width: 16.w),
                      _buildExtractedData('birth_place'.tr, 'egypt'.tr),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExtractedData(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppFonts.labelSmall.copyWith(
              color: const Color(0xFF6B7280),
              
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: AppFonts.bodyMedium.copyWith(
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
              
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Box
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B5CF6).withOpacity(0.08),
                  const Color(0xFF7C3AED).withOpacity(0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: const Color(0xFF8B5CF6),
                    size: 18.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'personal_information_section'.tr,
                        style: AppFonts.h3.copyWith(
                          color: const Color(0xFF1F2937),
                          fontWeight: FontWeight.bold,
                          
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'enter_student_details_academic'.tr,
                        style: AppFonts.bodySmall.copyWith(
                          color: const Color(0xFF6B7280),
                          
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // Form Section
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildEnhancedTextField(
                  controller: _fullNameController,
                  label: 'full_name'.tr,
                  hint: 'enter_student_full_name'.tr,
                  icon: Icons.person_rounded,
                ),
                SizedBox(height: 20.h),
                _buildGradeDropdown(),
                if (_selectedNationality == 'Other') ...[
                  SizedBox(height: 20.h),
                  _buildBirthdateField(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeDropdown() {
    print(
        '🎓 [DROPDOWN] Building grade dropdown with ${_grades.length} grades');
    print(
        '🎓 [DROPDOWN] Grades: ${_grades.map((g) => '${g.name}(${g.id})').toList()}');
    print('🎓 [DROPDOWN] Is loading: $_isLoading');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'grade'.tr,
              style: AppFonts.bodyMedium.copyWith(
                color: const Color(0xFF374151),
                fontWeight: FontWeight.w600,
                
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: _grades.isEmpty ? Colors.red : Colors.green,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '${_grades.length}',
                style: TextStyle(
                  color: Colors.white,
                  
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedGrade.isEmpty ? null : _selectedGrade,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.school_rounded,
                color: const Color(0xFF6B7280),
                size: 20.sp,
              ),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            ),
            hint: Text(
              _isLoading
                  ? 'loading_grades'.tr
                  : _grades.isEmpty
                      ? 'no_grades_available'.tr
                      : 'select_grade_placeholder'.tr,
              style: AppFonts.bodySmall.copyWith(
                color: const Color(0xFF9CA3AF),
                
              ),
            ),
            items: _grades.isEmpty
                ? []
                : _grades.map((grade) {
                    print(
                        '🎓 [DROPDOWN] Creating item for grade: ${grade.name} (ID: ${grade.id})');
                    return DropdownMenuItem<String>(
                      value: grade.id,
                      child: Text(
                        grade.name,
                        style: AppFonts.bodyMedium.copyWith(
                          color: const Color(0xFF1F2937),
                          
                        ),
                      ),
                    );
                  }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedGrade = value ?? '';
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBirthdateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Text(
            'birthdate'.tr,
          style: AppFonts.bodyMedium.copyWith(
            color: const Color(0xFF374151),
            fontWeight: FontWeight.w600,
            
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: _selectBirthdate,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: const Color(0xFF6B7280),
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  _selectedBirthdate != null
                      ? '${_selectedBirthdate!.day}/${_selectedBirthdate!.month}/${_selectedBirthdate!.year}'
                      : 'select_birthdate'.tr,
                  style: _selectedBirthdate != null
                      ? AppFonts.bodyMedium.copyWith(
                          color: const Color(0xFF1F2937),
                          
                        )
                      : AppFonts.bodySmall.copyWith(
                          color: const Color(0xFF9CA3AF),
                          
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectBirthdate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthdate ??
          DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedBirthdate = picked;
        _calculatedAge = _calculateAge(picked);
      });
    }
  }

  String _calculateAge(DateTime birthdate) {
    final now = DateTime.now();
    int years = now.year - birthdate.year;
    int months = now.month - birthdate.month;
    int days = now.day - birthdate.day;

    if (days < 0) {
      months--;
      days += DateTime(now.year, now.month, 0).day;
    }
    if (months < 0) {
      years--;
      months += 12;
    }

    return '$years سنة و $months شهر و $days يوم';
  }

  String _formatBirthdate(DateTime birthdate) {
    return '${birthdate.day.toString().padLeft(2, '0')}/${birthdate.month.toString().padLeft(2, '0')}/${birthdate.year}';
  }

  Widget _buildAddressStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Box
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981).withOpacity(0.08),
                  const Color(0xFF059669).withOpacity(0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: const Color(0xFF10B981),
                    size: 18.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'address_information'.tr,
                        style: AppFonts.h3.copyWith(
                          color: const Color(0xFF1F2937),
                          fontWeight: FontWeight.bold,
                          
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'enter_student_address_location'.tr,
                        style: AppFonts.bodySmall.copyWith(
                          color: const Color(0xFF6B7280),
                          
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // Address Field
          EnhancedAddressField(
            controller: _addressController,
            label: 'address'.tr,
            hint: 'enter_student_address'.tr,
            onLocationSelected: (address, latitude, longitude) {
              setState(() {
                _selectedLatitude = latitude;
                _selectedLongitude = longitude;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Box
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF59E0B).withOpacity(0.08),
                  const Color(0xFFD97706).withOpacity(0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: const Color(0xFFF59E0B).withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.medical_services_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 18.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'medical_information'.tr,
                        style: AppFonts.h3.copyWith(
                          color: const Color(0xFF1F2937),
                          fontWeight: FontWeight.bold,
                          
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'optional_medical_notes_status'.tr,
                        style: AppFonts.bodySmall.copyWith(
                          color: const Color(0xFF6B7280),
                          
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // Medical Notes Field
          _buildEnhancedTextField(
            controller: TextEditingController(),
            label: 'medical_notes'.tr,
            hint: 'medical_notes_optional'.tr,
            icon: Icons.notes_rounded,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 40.h),

          // Success Icon
          Container(
            width: 120.w,
            height: 120.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981),
                  const Color(0xFF059669),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(60.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 60.sp,
            ),
          ),

          SizedBox(height: 32.h),

          // Title
          Text(
            'youre_done'.tr,
            style: AppFonts.h1.copyWith(
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.bold,
              
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 16.h),

          // Description
          Text(
            'all_info_collected'.tr,
            style: AppFonts.bodyLarge.copyWith(
              color: const Color(0xFF6B7280),
              
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 40.h),

          // Create Account Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _createStudent,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 4,
                shadowColor: const Color(0xFF10B981).withOpacity(0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add_rounded,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'create_account_cta'.tr,
                    style: AppFonts.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int? maxLength,
    TextInputType? keyboardType,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppFonts.bodyMedium.copyWith(
            color: const Color(0xFF374151),
            fontWeight: FontWeight.w600,
            
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            onChanged: onChanged,
            maxLength: maxLength,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: AppFonts.bodyMedium.copyWith(
              color: const Color(0xFF1F2937),
              
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppFonts.bodySmall.copyWith(
                color: const Color(0xFF9CA3AF),
                
              ),
              prefixIcon: Container(
                margin: EdgeInsets.all(8.w),
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF3B82F6),
                  size: 20.sp,
                ),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }
}

