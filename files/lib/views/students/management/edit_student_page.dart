import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../models/student_models.dart';
import '../../../services/students_service.dart';
import '../../../services/grades_service.dart';
import '../../../utils/egyptian_national_id_parser.dart';
import '../data/student_details_page.dart';
import '../../../widgets/enhanced_address_field.dart';
import '../../../widgets/step_navigation.dart';

class EditStudentPage extends StatefulWidget {
  final Student student;
  final String schoolId;

  const EditStudentPage({
    Key? key,
    required this.student,
    required this.schoolId,
  }) : super(key: key);

  @override
  State<EditStudentPage> createState() => _EditStudentPageState();
}

class _EditStudentPageState extends State<EditStudentPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 7; // Updated to match StudentSteps.editSteps.length

  // Form controllers
  final _nationalityController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _passportController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _fatherPhoneController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _motherPhoneController = TextEditingController();

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

  final List<String> _nationalities = ['Egyptian', 'Other'];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadGrades();
  }

  @override
  void dispose() {
    _nationalityController.dispose();
    _nationalIdController.dispose();
    _passportController.dispose();
    _fullNameController.dispose();
    _addressController.dispose();
    _fatherNameController.dispose();
    _fatherPhoneController.dispose();
    _motherNameController.dispose();
    _motherPhoneController.dispose();
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

  void _initializeData() {
    _selectedNationality =
        widget.student.nationalId.isNotEmpty ? 'Egyptian' : 'Other';
    _nationalIdController.text = widget.student.nationalId;
    _passportController.text = ''; // Passport not available in current model
    _fullNameController.text = widget.student.fullName;
    _addressController.text = ''; // Address not available in current model
    _selectedGrade = widget.student.grade.id;
    _selectedGender = widget.student.gender;

    // Analyze national ID if Egyptian
    if (_selectedNationality == 'Egyptian' &&
        widget.student.nationalId.isNotEmpty) {
      print('Analyzing national ID: ${widget.student.nationalId}');
      _analyzeNationalId(widget.student.nationalId);
    } else if (_selectedNationality == 'Egyptian') {
      // Test with a sample national ID if none provided
      print('No national ID provided, testing with sample: 29012345678901');
      _analyzeNationalId('29012345678901'); // Sample: Born Jan 23, 1990, Male
    } else {
      _calculatedAge = widget.student.ageInOctober.toString();
      // Parse birthdate from student data if available
      if (widget.student.birthDate.isNotEmpty) {
        try {
          _selectedBirthdate = DateTime.parse(widget.student.birthDate);
    } catch (e) {
          print('Error parsing birthdate: $e');
        }
      }
    }

    // Initialize parent data
    _fatherNameController.text = widget.student.parent.name;
    _fatherPhoneController.text = widget.student.parent.phone;
    _motherNameController.text = ''; // Will be filled from parent data
    _motherPhoneController.text = ''; // Will be filled from parent data
  }

  void _analyzeNationalId(String nationalId) {
    try {
      print('🔍 [NATIONAL ID] Analyzing: $nationalId');
      final parsedData = EgyptianNationalIdParser.parseNationalId(nationalId);
      print('🔍 [NATIONAL ID] Parsed data: $parsedData');

      if (parsedData['isValid'] == true) {
        final age = parsedData['age'] as int?;
        final birthDate = parsedData['birthDate'] as DateTime?;
        final gender = parsedData['gender'] as String?;

        print(
            '🔍 [NATIONAL ID] Age: $age, BirthDate: $birthDate, Gender: $gender');

        setState(() {
          _selectedBirthdate = birthDate;
          _calculatedAge = age?.toString() ?? '0';
          _selectedGender = gender ?? '';
        });
        print(
            '✅ [NATIONAL ID] Analysis successful: Age=$_calculatedAge, Gender=$_selectedGender');
      } else {
        print('❌ [NATIONAL ID] Analysis failed: ${parsedData['error']}');
        setState(() {
          _calculatedAge = widget.student.ageInOctober.toString();
          _selectedGender = widget.student.gender;
        });
      }
    } catch (e) {
      print('💥 [NATIONAL ID] Error: $e');
      setState(() {
        _calculatedAge = widget.student.ageInOctober.toString();
        _selectedGender = widget.student.gender;
      });
    }
  }

  Future<void> _loadGrades() async {
    print('🎓 [GRADES] Loading grades for schoolId: ${widget.schoolId}');

    setState(() {
      _isLoading = true;
    });

    try {
      print('🎓 [GRADES] Calling GradesService.getAllGrades...');
      final response = await GradesService.getAllGrades(widget.schoolId);
      print(
          '🎓 [GRADES] Response received: success=${response.success}, grades count=${response.grades.length}');

      if (response.success) {
        setState(() {
          _grades = response.grades;
        });
        print(
            '✅ [GRADES] Grades loaded successfully: ${_grades.length} grades');
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


  Future<void> _updateStudent() async {
      setState(() {
        _isLoading = true;
      });

      try {
      final request = UpdateStudentRequest(
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
        studentCode: widget.student.studentCode,
        moodleUsername: '',
        moodlePassword: '',
        parentName: _fatherNameController.text.trim(),
        parentPhone1: _fatherPhoneController.text.trim(),
        parentEmail: '',
        parentRelation: 'Father',
        parentNationalId: '',
        parentName2: _motherNameController.text.trim(),
        parentPhone2: _motherPhoneController.text.trim(),
        parentEmail2: '',
        parentRelation2: 'Mother',
        parentNationalId2: '',
      );

      final response = await StudentsService.updateStudent(
        widget.schoolId,
        widget.student.id,
        request,
      );

      print(
          '📍 [ADDRESS] Selected coordinates: $_selectedLatitude, $_selectedLongitude');

      print('🎓 [EDIT] Response success: ${response.success}');
      print('🎓 [EDIT] Response message: ${response.message}');
      print(
          '🎓 [EDIT] Response student: ${response.student != null ? "Available" : "Null"}');

        if (response.success) {
          Get.snackbar(
            'success'.tr,
          'student_updated_successfully'.tr,
            snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF10B981),
            colorText: Colors.white,
          );

        // Navigate to student details page
        if (response.student != null) {
          print('🎓 [EDIT] Navigating to StudentDetailsPage with student data');
          Get.off(() => StudentDetailsPage(
                student: response.student!,
                schoolId: widget.schoolId,
              ));
        } else {
          print('🎓 [EDIT] Student data is null, going back to previous page');
          // If student data is not available, go back to students list
          Get.back(result: true);
          Get.snackbar(
            'success'.tr,
            'student_updated_successfully'.tr,
            snackPosition: SnackPosition.TOP,
            backgroundColor: const Color(0xFF10B981),
            colorText: Colors.white,
            icon: const Icon(Icons.check_circle, color: Colors.white),
          );
        }
        } else {
          Get.snackbar(
            'error'.tr,
            response.message,
            snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFEF4444),
            colorText: Colors.white,
          );
        }
      } catch (e) {
        Get.snackbar(
          'error'.tr,
        'error_updating_student'.tr + ': ${e.toString()}',
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        title: Text(
          'edit_student_title'.tr,
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
              totalSteps: StudentSteps.editSteps.length,
              steps: StudentSteps.editSteps,
              onStepTap: (step) {
                // In edit mode, allow jumping between any completed or current step
                _goToStep(step);
              },
              allowJumping: true, // Allow jumping between steps for edit
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
                _buildAgeBirthStep(),
                _buildNameStep(),
                _buildAddressStep(),
                _buildMedicalStep(),
                _buildMotherStep(),
                _buildFatherStep(),
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
                        ? _updateStudent
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
                                ? 'update_student_cta'.tr
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
                    Icons.public_rounded,
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
                        'nationality_identity'.tr,
                        style: AppFonts.h3.copyWith(
                          color: const Color(0xFF1F2937),
                          fontWeight: FontWeight.bold,
                          
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'update_nationality_info'.tr,
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

          // Options Container
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
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

  Widget _buildAgeBirthStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF59E0B).withOpacity(0.1),
                  const Color(0xFFD97706).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: const Color(0xFFF59E0B).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.cake_rounded,
                        color: const Color(0xFFF59E0B),
                        size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'age_birth_data'.tr,
                            style: AppFonts.h2.copyWith(
                              color: const Color(0xFF1F2937),
                              fontWeight: FontWeight.bold,
                              
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
          SizedBox(height: 24.h),

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
              _buildTextField(
                  controller: _selectedNationality == 'Egyptian'
                      ? _nationalIdController
                      : _passportController,
                  label: _selectedNationality == 'Egyptian'
                      ? 'national_id_read_only'.tr
                      : 'passport_number'.tr,
                  hint: _selectedNationality == 'Egyptian'
                      ? 'national_id_cannot_edit'.tr
                      : 'enter_passport_number'.tr,
                  icon: _selectedNationality == 'Egyptian'
                      ? Icons.badge_rounded
                      : Icons.credit_card_rounded,
                  onChanged: null, // Disabled for Egyptian National ID
                  maxLength: _selectedNationality == 'Egyptian' ? 14 : null,
                  keyboardType: TextInputType.number,
                  enabled: _selectedNationality != 'Egyptian',
                ),
                if (_selectedNationality == 'Egyptian' &&
                    (_calculatedAge.isNotEmpty ||
                        _selectedBirthdate != null)) ...[
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
                            _buildExtractedData(
                                'age'.tr,
                                _calculatedAge.isNotEmpty
                                    ? _calculatedAge
                                    : 'not_calculated'.tr),
                            SizedBox(width: 16.w),
                            _buildExtractedData(
                                'gender'.tr,
                                _selectedGender.isNotEmpty
                                    ? _selectedGender
                                    : 'not_determined'.tr),
                          ],
                        ),
                        if (_selectedBirthdate != null) ...[
                          SizedBox(height: 12.h),
              Row(
                children: [
                              _buildExtractedData('birthdate'.tr,
                                  _formatBirthdate(_selectedBirthdate!)),
                              SizedBox(width: 16.w),
                              _buildExtractedData('birth_place'.tr, 'egypt'.tr),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
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

  String _formatBirthdate(DateTime birthdate) {
    // Format as DD/MM/YYYY
    return '${birthdate.day.toString().padLeft(2, '0')}/${birthdate.month.toString().padLeft(2, '0')}/${birthdate.year}';
  }

  Widget _buildNameStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          Text(
            'name_and_grade'.tr,
            style: AppFonts.h2.copyWith(
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.bold,
              
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'update_student_personal_details'.tr,
            style: AppFonts.bodyMedium.copyWith(
              color: const Color(0xFF6B7280),
              
            ),
          ),
          SizedBox(height: 32.h),
          _buildTextField(
            controller: _fullNameController,
            label: 'full_name'.tr,
            hint: 'enter_student_full_name'.tr,
            icon: Icons.person_rounded,
          ),
          SizedBox(height: 20.h),
          _buildTextField(
            controller: TextEditingController(text: widget.student.studentCode),
            label: 'student_code_read_only'.tr,
            hint: 'student_code_cannot_edit'.tr,
            icon: Icons.badge_rounded,
            enabled: false,
          ),
          SizedBox(height: 20.h),
          _buildGradeDropdown(),
        ],
      ),
    );
  }

  Widget _buildAddressStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'address_information'.tr,
            style: AppFonts.h2.copyWith(
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.bold,
              
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'update_student_address'.tr,
            style: AppFonts.bodyMedium.copyWith(
              color: const Color(0xFF6B7280),
              
            ),
          ),
          SizedBox(height: 32.h),
          EnhancedAddressField(
            controller: _addressController,
            label: 'address'.tr,
            hint: 'select_address_on_map'.tr,
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
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          Text(
            'medical_information'.tr,
            style: AppFonts.h2.copyWith(
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.bold,
              
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'add_medical_information'.tr,
            style: AppFonts.bodyMedium.copyWith(
              color: const Color(0xFF6B7280),
                                  
                                ),
                              ),
          SizedBox(height: 32.h),
          _buildTextField(
            controller:
                TextEditingController(text: widget.student.medicalNotes),
            label: 'medical_notes'.tr,
            hint:
                'enter_medical_conditions'.tr,
            icon: Icons.medical_services_rounded,
            maxLines: 5,
          ),
          SizedBox(height: 20.h),
          _buildTextField(
            controller: TextEditingController(text: widget.student.status),
            label: 'status'.tr,
            hint: 'enter_student_status'.tr,
            icon: Icons.info_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildGradeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'grade'.tr,
          style: AppFonts.bodyMedium.copyWith(
            color: const Color(0xFF374151),
            fontWeight: FontWeight.w600,
            
          ),
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

    return '$years ${'years'.tr} ${'and'.tr} $months ${'months'.tr} ${'and'.tr} $days ${'days'.tr}';
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int? maxLength,
    TextInputType? keyboardType,
    int maxLines = 1,
    Function(String)? onChanged,
    bool enabled = true,
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
        TextFormField(
          controller: controller,
          maxLength: maxLength,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppFonts.bodySmall.copyWith(
              color: const Color(0xFF9CA3AF),
              
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF6B7280),
              size: 20.sp,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          ),
        ),
      ],
    );
  }

  Widget _buildMotherStep() {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            'mother_information'.tr,
            style: AppFonts.h2.copyWith(
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.bold,
              
          ),
        ),
        SizedBox(height: 8.h),
          Text(
            'enter_mother_details'.tr,
            style: AppFonts.bodyMedium.copyWith(
              color: const Color(0xFF6B7280),
              
            ),
          ),
          SizedBox(height: 32.h),
          _buildTextField(
            controller: _motherNameController,
            label: 'mother_name'.tr,
            hint: 'enter_mother_full_name'.tr,
            icon: Icons.person_rounded,
          ),
          SizedBox(height: 20.h),
          _buildTextField(
            controller: _motherPhoneController,
            label: 'mother_phone'.tr,
            hint: 'enter_mother_phone'.tr,
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildFatherStep() {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'father_information'.tr,
            style: AppFonts.h2.copyWith(
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.bold,
              
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'enter_father_details'.tr,
            style: AppFonts.bodyMedium.copyWith(
              color: const Color(0xFF6B7280),
              
            ),
          ),
          SizedBox(height: 32.h),
          _buildTextField(
            controller: _fatherNameController,
            label: 'father_name'.tr,
            hint: 'enter_father_full_name'.tr,
            icon: Icons.person_rounded,
          ),
          SizedBox(height: 20.h),
          _buildTextField(
            controller: _fatherPhoneController,
            label: 'father_phone'.tr,
            hint: 'enter_father_phone'.tr,
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }
}
