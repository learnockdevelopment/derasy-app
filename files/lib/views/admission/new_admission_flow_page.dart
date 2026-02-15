import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/api_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/controllers/dashboard_controller.dart';
import '../../models/student_models.dart';
import '../../models/school_models.dart';
import '../../models/admission_models.dart';
import '../../services/admission_service.dart';
import '../../services/schools_service.dart';
import '../../services/user_storage_service.dart';
import '../../services/wallet_service.dart';
import '../../core/constants/assets.dart';
import '../../../widgets/safe_network_image.dart';

class NewAdmissionFlowPage extends StatefulWidget {
  const NewAdmissionFlowPage({Key? key}) : super(key: key);

  @override
  State<NewAdmissionFlowPage> createState() => _NewAdmissionFlowPageState();
}

class _NewAdmissionFlowPageState extends State<NewAdmissionFlowPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // Step 1: Student Type
  Student? _selectedChild;
  String _studentType = ''; // 'new' or 'transfer'
  
  // Step 2: Education Details
  String? _selectedEducationType;
  String? _selectedCountry;
  String? _selectedCity;
  
  // Step 3: Current School (if transfer)
  School? _currentSchool;
  List<School> _allSchools = [];
  bool _isLoadingSchools = false;
  
  // Step 4: Grade and Budget
  String? _selectedGrade;
  double _minBudget = 0;
  double _maxBudget = 100000;
  
  // Step 5: Health Issues
  bool _hasHealthIssues = false;
  final TextEditingController _healthIssuesController = TextEditingController();
  
  // Step 6: School Selection
  List<School> _suggestedSchools = [];
  final Set<School> _selectedSchools = {};
  bool _isLoadingSuggestions = false;
  String _schoolSearchQuery = '';
  
  // Step 7: Submission
  bool _isSubmitting = false;
  
  final List<String> _educationTypes = [
    'national',
    'international',
    'language',
    'religious',
  ];
  
  final List<String> _countries = [
    'egypt',
    'saudi_arabia',
    'uae',
  ];
  
  final Map<String, List<String>> _citiesByCountry = {
    'egypt': ['cairo', 'alexandria', 'giza', 'aswan'],
    'saudi_arabia': ['riyadh', 'jeddah', 'mecca', 'medina'],
    'uae': ['dubai', 'abu_dhabi', 'sharjah'],
  };

  @override
  void initState() {
    super.initState();
    _loadArguments();
    _loadAllSchools();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _healthIssuesController.dispose();
    super.dispose();
  }

  void _loadArguments() {
    final args = Get.arguments as Map<String, dynamic>?;
    if (args == null) return;

    if (args['child'] != null) {
      setState(() {
        _selectedChild = args['child'] as Student;
      });
    } else if (args['childId'] != null) {
      final childId = args['childId'] as String;
      final child = DashboardController.to.relatedChildren.firstWhereOrNull(
        (c) => c.id == childId,
      );
      if (child != null) {
        setState(() {
          _selectedChild = child;
        });
      }
    }
  }

  Future<void> _loadAllSchools() async {
    setState(() {
      _isLoadingSchools = true;
    });

    try {
      final response = await SchoolsService.getAllSchools();
      if (mounted) {
        setState(() {
          _allSchools = response.schools;
          _isLoadingSchools = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSchools = false;
        });
      }
      Get.snackbar(
        'error'.tr,
        'failed_to_load_schools'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  void _nextStep() {
    if (_currentStep < 6) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canProceedFromCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _studentType.isNotEmpty;
      case 1:
        return _selectedEducationType != null &&
            _selectedCountry != null &&
            _selectedCity != null;
      case 2:
        return _studentType == 'new' || _currentSchool != null;
      case 3:
        return _selectedGrade != null;
      case 4:
        return !_hasHealthIssues || _healthIssuesController.text.isNotEmpty;
      case 5:
        return _selectedSchools.length == 3;
      default:
        return true;
    }
  }

  Future<void> _getSuggestions() async {
    if (_selectedChild == null) return;

    setState(() {
      _isLoadingSuggestions = true;
    });

    try {
      // Filter schools based on criteria
      final filteredSchools = _allSchools.where((school) {
        // Filter by education type
        if (_selectedEducationType != null) {
          // Add your education type filtering logic here
        }
        
        // Filter by location
        if (_selectedCity != null) {
          if (school.location?.city.toLowerCase() != _selectedCity?.toLowerCase()) {
            return false;
          }
        }

        // Filter by budget
        final fees = school.fees;
        if (fees != null) {
          final admissionFee = fees.admissionFee ?? 0;
          if (admissionFee < _minBudget || admissionFee > _maxBudget) {
            return false;
          }
        }

        return true;
      }).toList();

      // Take top 3 as suggestions
      setState(() {
        _suggestedSchools = filteredSchools.take(3).toList();
        _isLoadingSuggestions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSuggestions = false;
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

  Future<void> _submitApplication() async {
    if (_selectedChild == null || _selectedSchools.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    int successCount = 0;
    String lastError = '';

    try {
      // Update child's desiredGrade
      if (_selectedGrade != null && _selectedGrade!.isNotEmpty) {
        try {
          final updateUrl = '${ApiConstants.baseUrl}${ApiConstants.getRelatedChildrenEndpoint}/${_selectedChild!.id}';
          final token = UserStorageService.getAuthToken();
          
          if (token != null) {
            await http.put(
              Uri.parse(updateUrl),
              headers: ApiConstants.getAuthHeaders(token),
              body: jsonEncode({
                'desiredGrade': _selectedGrade,
              }),
            );
          }
        } catch (e) {
          print('⚠️ Failed to update child desiredGrade: $e');
        }
      }

      // Submit applications for all selected schools in one batch request
      try {
        final selectedSchoolsList = _selectedSchools
            .map((school) => SelectedSchool.fromSchool(school))
            .toList();
            
        final request = ApplyToSchoolsRequest(
          childId: _selectedChild!.id,
          selectedSchools: selectedSchoolsList,
        );

        await AdmissionService.applyToSchools(request);
        successCount = _selectedSchools.length;
      } catch (e) {
        lastError = e.toString();
        print('❌ Error applying to schools: $e');
      }

      if (!mounted) return;

      // Reload wallet to check if charged
      try {
        await WalletService.getWallet();
        await DashboardController.to.refreshAll();
      } catch (e) {
        print('⚠️ Failed to reload wallet: $e');
      }

      setState(() {
        _isSubmitting = false;
      });

      if (successCount > 0) {
        Get.snackbar(
          'success'.tr,
          'applications_submitted_successfully'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );

        await Future.delayed(const Duration(milliseconds: 500));
        Get.offNamed(AppRoutes.applications);
      } else {
        Get.snackbar(
          'error'.tr,
          lastError.isNotEmpty ? lastError : 'failed_to_apply'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      Get.snackbar(
        'error'.tr,
        'failed_to_apply'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'admission_application'.tr,
          style: AppFonts.h4.copyWith(color: Colors.white, fontSize: Responsive.sp(16)),
        ),
        backgroundColor: AppColors.blue1,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => _currentStep > 0 ? _previousStep() : Get.back(),
        ),
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: [
                _buildStudentTypeStep(),
                _buildEducationDetailsStep(),
                _buildCurrentSchoolStep(),
                _buildGradeAndBudgetStep(),
                _buildHealthIssuesStep(),
                _buildSchoolSelectionStep(),
                _buildConfirmationStep(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: Responsive.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(7, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;
          
          return Expanded(
            child: Container(
              margin: Responsive.symmetric(horizontal: 2),
              height: Responsive.h(4),
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? AppColors.blue1
                    : AppColors.grey200,
                borderRadius: BorderRadius.circular(Responsive.r(2)),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStudentTypeStep() {
    return SingleChildScrollView(
      padding: Responsive.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedChild != null) ...[
            _buildStudentHeader(),
            SizedBox(height: Responsive.h(24)),
          ],
          
          Text(
            'student_type_question'.tr,
            style: AppFonts.h3.copyWith(
              color: AppColors.textPrimary,
              fontSize: Responsive.sp(20),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: Responsive.h(8)),
          Text(
            'select_student_type_description'.tr,
            style: AppFonts.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: Responsive.sp(14),
            ),
          ),
          SizedBox(height: Responsive.h(32)),
          
          _buildTypeCard(
            type: 'new',
            title: 'new_student'.tr,
            description: 'new_student_description'.tr,
            icon: Icons.person_add_rounded,
            color: AppColors.success,
          ),
          SizedBox(height: Responsive.h(16)),
          _buildTypeCard(
            type: 'transfer',
            title: 'transfer_student'.tr,
            description: 'transfer_student_description'.tr,
            icon: Icons.swap_horiz_rounded,
            color: AppColors.blue1,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard({
    required String type,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _studentType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _studentType = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: Responsive.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(Responsive.r(16)),
          border: Border.all(
            color: isSelected ? color : AppColors.grey200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: Responsive.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(Responsive.r(12)),
              ),
              child: Icon(icon, color: color, size: Responsive.sp(28)),
            ),
            SizedBox(width: Responsive.w(16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.h4.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: Responsive.sp(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: Responsive.h(4)),
                  Text(
                    description,
                    style: AppFonts.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: Responsive.sp(12),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: color,
                size: Responsive.sp(24),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationDetailsStep() {
    return SingleChildScrollView(
      padding: Responsive.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'start_admission_to_new_school'.tr,
            style: AppFonts.h3.copyWith(
              color: AppColors.textPrimary,
              fontSize: Responsive.sp(20),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: Responsive.h(8)),
          Text(
            'select_education_preferences'.tr,
            style: AppFonts.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: Responsive.sp(14),
            ),
          ),
          SizedBox(height: Responsive.h(32)),
          
          // Education Type
          Text(
            'education_type'.tr,
            style: AppFonts.h4.copyWith(fontSize: Responsive.sp(14)),
          ),
          SizedBox(height: Responsive.h(8)),
          DropdownButtonFormField<String>(
            value: _selectedEducationType,
            items: _educationTypes
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.tr, style: TextStyle(fontSize: Responsive.sp(13))),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedEducationType = value),
            decoration: InputDecoration(
              hintText: 'select_education_type'.tr,
              hintStyle: TextStyle(fontSize: Responsive.sp(13)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Responsive.r(12)),
              ),
              contentPadding: Responsive.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          SizedBox(height: Responsive.h(20)),
          
          // Country
          Text(
            'country'.tr,
            style: AppFonts.h4.copyWith(fontSize: Responsive.sp(14)),
          ),
          SizedBox(height: Responsive.h(8)),
          DropdownButtonFormField<String>(
            value: _selectedCountry,
            items: _countries
                .map((country) => DropdownMenuItem(
                      value: country,
                      child: Text(country.tr, style: TextStyle(fontSize: Responsive.sp(13))),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedCountry = value;
                _selectedCity = null; // Reset city when country changes
              });
            },
            decoration: InputDecoration(
              hintText: 'select_country'.tr,
              hintStyle: TextStyle(fontSize: Responsive.sp(13)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Responsive.r(12)),
              ),
              contentPadding: Responsive.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          SizedBox(height: Responsive.h(20)),
          
          // City
          Text(
            'city'.tr,
            style: AppFonts.h4.copyWith(fontSize: Responsive.sp(14)),
          ),
          SizedBox(height: Responsive.h(8)),
          DropdownButtonFormField<String>(
            value: _selectedCity,
            items: _selectedCountry != null
                ? (_citiesByCountry[_selectedCountry] ?? [])
                    .map((city) => DropdownMenuItem(
                          value: city,
                          child: Text(city.tr, style: TextStyle(fontSize: Responsive.sp(13))),
                        ))
                    .toList()
                : [],
            onChanged: (value) => setState(() => _selectedCity = value),
            decoration: InputDecoration(
              hintText: 'select_city'.tr,
              hintStyle: TextStyle(fontSize: Responsive.sp(13)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Responsive.r(12)),
              ),
              contentPadding: Responsive.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: Colors.white,
              enabled: _selectedCountry != null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSchoolStep() {
    if (_studentType == 'new') {
      // Skip this step for new students
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_currentStep == 2) {
          _nextStep();
        }
      });
      return const SizedBox.shrink();
    }
    
    return SingleChildScrollView(
      padding: Responsive.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'current_school'.tr,
            style: AppFonts.h3.copyWith(
              color: AppColors.textPrimary,
              fontSize: Responsive.sp(20),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: Responsive.h(8)),
          Text(
            'select_current_school_description'.tr,
            style: AppFonts.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: Responsive.sp(14),
            ),
          ),
          SizedBox(height: Responsive.h(24)),
          
          if (_isLoadingSchools)
            const Center(child: CircularProgressIndicator())
          else
            DropdownButtonFormField<School>(
              value: _currentSchool,
              items: _allSchools
                  .map((school) => DropdownMenuItem(
                        value: school,
                        child: Text(
                          school.name,
                          style: TextStyle(fontSize: Responsive.sp(13)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _currentSchool = value),
              decoration: InputDecoration(
                hintText: 'select_current_school'.tr,
                hintStyle: TextStyle(fontSize: Responsive.sp(13)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Responsive.r(12)),
                ),
                contentPadding: Responsive.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGradeAndBudgetStep() {
    final availableGrades = _selectedSchools.isNotEmpty
        ? _selectedSchools.first.gradesOffered
        : ['KG1', 'KG2', 'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10', 'Grade 11', 'Grade 12'];
    
    return SingleChildScrollView(
      padding: Responsive.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'grade_and_budget'.tr,
            style: AppFonts.h3.copyWith(
              color: AppColors.textPrimary,
              fontSize: Responsive.sp(20),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: Responsive.h(8)),
          Text(
            'select_grade_and_budget_description'.tr,
            style: AppFonts.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: Responsive.sp(14),
            ),
          ),
          SizedBox(height: Responsive.h(32)),
          
          // Grade Selection
          Text(
            'desired_grade'.tr,
            style: AppFonts.h4.copyWith(fontSize: Responsive.sp(14)),
          ),
          SizedBox(height: Responsive.h(8)),
          DropdownButtonFormField<String>(
            value: _selectedGrade,
            items: availableGrades
                .map((grade) => DropdownMenuItem(
                      value: grade,
                      child: Text(grade, style: TextStyle(fontSize: Responsive.sp(13))),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedGrade = value),
            decoration: InputDecoration(
              hintText: 'select_grade'.tr,
              hintStyle: TextStyle(fontSize: Responsive.sp(13)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Responsive.r(12)),
              ),
              contentPadding: Responsive.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          SizedBox(height: Responsive.h(32)),
          
          // Budget Range
          Text(
            'budget_range'.tr,
            style: AppFonts.h4.copyWith(fontSize: Responsive.sp(14)),
          ),
          SizedBox(height: Responsive.h(8)),
          Container(
            padding: Responsive.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(Responsive.r(12)),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_minBudget.toInt()} ${'egp'.tr}',
                      style: AppFonts.h4.copyWith(
                        color: AppColors.blue1,
                        fontSize: Responsive.sp(14),
                      ),
                    ),
                    Text(
                      '${_maxBudget.toInt()} ${'egp'.tr}',
                      style: AppFonts.h4.copyWith(
                        color: AppColors.blue1,
                        fontSize: Responsive.sp(14),
                      ),
                    ),
                  ],
                ),
                RangeSlider(
                  values: RangeValues(_minBudget, _maxBudget),
                  min: 0,
                  max: 100000,
                  divisions: 100,
                  activeColor: AppColors.blue1,
                  inactiveColor: AppColors.grey200,
                  onChanged: (values) {
                    setState(() {
                      _minBudget = values.start;
                      _maxBudget = values.end;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthIssuesStep() {
    return SingleChildScrollView(
      padding: Responsive.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'health_information'.tr,
            style: AppFonts.h3.copyWith(
              color: AppColors.textPrimary,
              fontSize: Responsive.sp(20),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: Responsive.h(8)),
          Text(
            'health_information_description'.tr,
            style: AppFonts.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: Responsive.sp(14),
            ),
          ),
          SizedBox(height: Responsive.h(32)),
          
          Text(
            'does_student_have_health_issues'.tr,
            style: AppFonts.h4.copyWith(fontSize: Responsive.sp(14)),
          ),
          SizedBox(height: Responsive.h(16)),
          
          Row(
            children: [
              Expanded(
                child: _buildYesNoButton(
                  label: 'yes'.tr,
                  value: true,
                  isSelected: _hasHealthIssues,
                  onTap: () => setState(() => _hasHealthIssues = true),
                ),
              ),
              SizedBox(width: Responsive.w(16)),
              Expanded(
                child: _buildYesNoButton(
                  label: 'no'.tr,
                  value: false,
                  isSelected: !_hasHealthIssues,
                  onTap: () => setState(() {
                    _hasHealthIssues = false;
                    _healthIssuesController.clear();
                  }),
                ),
              ),
            ],
          ),
          
          if (_hasHealthIssues) ...[
            SizedBox(height: Responsive.h(24)),
            Text(
              'describe_health_issues'.tr,
              style: AppFonts.h4.copyWith(fontSize: Responsive.sp(14)),
            ),
            SizedBox(height: Responsive.h(8)),
            TextField(
              controller: _healthIssuesController,
              maxLines: 4,
              style: TextStyle(fontSize: Responsive.sp(13)),
              decoration: InputDecoration(
                hintText: 'enter_health_issues_details'.tr,
                hintStyle: TextStyle(fontSize: Responsive.sp(13)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Responsive.r(12)),
                ),
                contentPadding: Responsive.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildYesNoButton({
    required String label,
    required bool value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: Responsive.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? (value ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1))
              : Colors.white,
          borderRadius: BorderRadius.circular(Responsive.r(12)),
          border: Border.all(
            color: isSelected
                ? (value ? AppColors.success : AppColors.error)
                : AppColors.grey200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppFonts.h4.copyWith(
              color: isSelected
                  ? (value ? AppColors.success : AppColors.error)
                  : AppColors.textSecondary,
              fontSize: Responsive.sp(14),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolSelectionStep() {
    // Load suggestions when entering this step
    if (_suggestedSchools.isEmpty && !_isLoadingSuggestions && _currentStep == 5) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _getSuggestions();
      });
    }
    
    final query = _schoolSearchQuery.toLowerCase();
    final filteredSchools = _allSchools
        .where((s) => !_suggestedSchools.any((suggested) => suggested.id == s.id))
        .where((s) => query.isEmpty || s.name.toLowerCase().contains(query))
        .toList();
    
    return Column(
      children: [
        Container(
          padding: Responsive.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'select_three_schools'.tr,
                style: AppFonts.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: Responsive.sp(18),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: Responsive.h(8)),
              Container(
                padding: Responsive.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedSchools.length == 3
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Responsive.r(8)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedSchools.length == 3
                          ? Icons.check_circle_rounded
                          : Icons.info_rounded,
                      color: _selectedSchools.length == 3
                          ? AppColors.success
                          : AppColors.warning,
                      size: Responsive.sp(16),
                    ),
                    SizedBox(width: Responsive.w(8)),
                    Text(
                      '${_selectedSchools.length}/3 ${'schools_selected'.tr}',
                      style: AppFonts.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: Responsive.sp(12),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: _isLoadingSuggestions
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: Responsive.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Suggested Schools
                      if (_suggestedSchools.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.stars, color: AppColors.blue1, size: Responsive.sp(18)),
                            SizedBox(width: Responsive.w(8)),
                            Text(
                              'suggested_schools'.tr,
                              style: AppFonts.h4.copyWith(
                                color: AppColors.blue1,
                                fontSize: Responsive.sp(14),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: Responsive.h(12)),
                        ..._suggestedSchools.map((school) => _buildSchoolCard(school, isSuggested: true)),
                        SizedBox(height: Responsive.h(24)),
                      ],
                      
                      // Search Bar
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            _schoolSearchQuery = value;
                          });
                        },
                        style: TextStyle(fontSize: Responsive.sp(12)),
                        decoration: InputDecoration(
                          hintText: 'search_schools'.tr,
                          hintStyle: TextStyle(fontSize: Responsive.sp(12)),
                          prefixIcon: Icon(Icons.search, color: AppColors.blue1, size: Responsive.sp(20)),
                          suffixIcon: _schoolSearchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _schoolSearchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Responsive.r(12)),
                          ),
                          contentPadding: Responsive.symmetric(horizontal: 12, vertical: 10),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      SizedBox(height: Responsive.h(16)),
                      
                      // All Schools
                      Row(
                        children: [
                          Icon(Icons.school, color: AppColors.textSecondary, size: Responsive.sp(18)),
                          SizedBox(width: Responsive.w(8)),
                          Text(
                            'all_schools'.tr,
                            style: AppFonts.h4.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: Responsive.sp(14),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.h(12)),
                      ...filteredSchools.map((school) => _buildSchoolCard(school, isSuggested: false)),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSchoolCard(School school, {required bool isSuggested}) {
    final isSelected = _selectedSchools.any((s) => s.id == school.id);
    final canSelect = _selectedSchools.length < 3 || isSelected;
    
    return GestureDetector(
      onTap: canSelect
          ? () {
              setState(() {
                if (isSelected) {
                  _selectedSchools.removeWhere((s) => s.id == school.id);
                } else {
                  _selectedSchools.add(school);
                }
              });
            }
          : null,
      child: Container(
        margin: Responsive.only(bottom: 12),
        padding: Responsive.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Responsive.r(16)),
          border: Border.all(
            color: isSelected
                ? AppColors.blue1
                : (isSuggested ? AppColors.warning.withOpacity(0.3) : AppColors.grey200),
            width: isSelected ? 2 : 1,
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
            ClipRRect(
              borderRadius: BorderRadius.circular(Responsive.r(12)),
              child: SafeNetworkImage(
                imageUrl: school.bannerImage,
                fallbackAsset: AssetsManager.login,
                width: Responsive.w(60),
                height: Responsive.w(60),
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: Responsive.w(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          school.name,
                          style: AppFonts.h4.copyWith(
                            fontSize: Responsive.sp(13),
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSuggested)
                        Container(
                          padding: Responsive.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(Responsive.r(4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: Responsive.sp(10), color: AppColors.warning),
                              SizedBox(width: Responsive.w(2)),
                              Text(
                                'suggested'.tr,
                                style: AppFonts.bodySmall.copyWith(
                                  color: AppColors.warning,
                                  fontSize: Responsive.sp(9),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (school.location?.city != null) ...[
                    SizedBox(height: Responsive.h(4)),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: Responsive.sp(12), color: AppColors.textSecondary),
                        SizedBox(width: Responsive.w(4)),
                        Text(
                          school.location!.city,
                          style: AppFonts.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: Responsive.sp(11),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (school.fees?.admissionFee != null) ...[
                    SizedBox(height: Responsive.h(4)),
                    Text(
                      '${school.fees!.admissionFee} ${'egp'.tr}',
                      style: AppFonts.bodySmall.copyWith(
                        color: AppColors.blue1,
                        fontSize: Responsive.sp(12),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: Responsive.w(8)),
            if (canSelect)
              Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? AppColors.blue1 : AppColors.grey300,
                size: Responsive.sp(24),
              )
            else
              Icon(
                Icons.block,
                color: AppColors.grey300,
                size: Responsive.sp(24),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationStep() {
    return SingleChildScrollView(
      padding: Responsive.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'confirm_application'.tr,
            style: AppFonts.h3.copyWith(
              color: AppColors.textPrimary,
              fontSize: Responsive.sp(20),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: Responsive.h(8)),
          Text(
            'review_application_details'.tr,
            style: AppFonts.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: Responsive.sp(14),
            ),
          ),
          SizedBox(height: Responsive.h(24)),
          
          _buildSummaryCard(
            title: 'student_information'.tr,
            children: [
              _buildSummaryRow('student_name'.tr, _selectedChild?.arabicFullName ?? _selectedChild?.fullName ?? ''),
              _buildSummaryRow('student_type'.tr, _studentType.tr),
            ],
          ),
          
          SizedBox(height: Responsive.h(16)),
          
          _buildSummaryCard(
            title: 'education_preferences'.tr,
            children: [
              _buildSummaryRow('education_type'.tr, _selectedEducationType?.tr ?? ''),
              _buildSummaryRow('location'.tr, '${_selectedCity?.tr ?? ''}, ${_selectedCountry?.tr ?? ''}'),
              _buildSummaryRow('grade'.tr, _selectedGrade ?? ''),
              _buildSummaryRow('budget'.tr, '${_minBudget.toInt()} - ${_maxBudget.toInt()} ${'egp'.tr}'),
            ],
          ),
          
          if (_hasHealthIssues) ...[
            SizedBox(height: Responsive.h(16)),
            _buildSummaryCard(
              title: 'health_information'.tr,
              children: [
                _buildSummaryRow('health_issues'.tr, _healthIssuesController.text),
              ],
            ),
          ],
          
          SizedBox(height: Responsive.h(16)),
          
          _buildSummaryCard(
            title: 'selected_schools'.tr,
            children: _selectedSchools.toList().asMap().entries.map((entry) {
              final index = entry.key;
              final school = entry.value;
              
              // Preference labels using translation keys
              String preferenceLabel = '';
              Color preferenceColor = AppColors.blue1;
              
              if (index == 0) {
                preferenceLabel = 'preference_first'.tr;
                preferenceColor = AppColors.error; // Red
              } else if (index == 1) {
                preferenceLabel = 'preference_second'.tr;
                preferenceColor = AppColors.success; // Green
              } else if (index == 2) {
                preferenceLabel = 'preference_third'.tr;
                preferenceColor = AppColors.warning; // Yellow
              }
              
              return Padding(
                padding: Responsive.only(bottom: 8),
                child: Row(
                  children: [
                    // Preference Order Badge
                    Container(
                      width: Responsive.w(32),
                      height: Responsive.w(32),
                      decoration: BoxDecoration(
                        color: preferenceColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(Responsive.r(8)),
                      ),
                      child: Center(
                        child: Text(
                          preferenceLabel,
                          style: AppFonts.bodySmall.copyWith(
                            color: preferenceColor,
                            fontSize: Responsive.sp(9),
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    SizedBox(width: Responsive.w(8)),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Responsive.r(8)),
                      child: SafeNetworkImage(
                        imageUrl: school.bannerImage,
                        fallbackAsset: AssetsManager.login,
                        width: Responsive.w(40),
                        height: Responsive.w(40),
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(width: Responsive.w(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            school.name,
                            style: AppFonts.h4.copyWith(fontSize: Responsive.sp(12)),
                          ),
                          if (school.location?.city != null)
                            Text(
                              school.location!.city,
                              style: AppFonts.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: Responsive.sp(10),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: Responsive.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.r(12)),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppFonts.h4.copyWith(
              fontSize: Responsive.sp(14),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: Responsive.h(12)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: Responsive.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppFonts.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: Responsive.sp(12),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppFonts.bodyMedium.copyWith(
                fontSize: Responsive.sp(12),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentHeader() {
    if (_selectedChild == null) return const SizedBox.shrink();

    return Container(
      padding: Responsive.all(12),
      decoration: BoxDecoration(
        color: AppColors.blue1.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Responsive.r(12)),
        border: Border.all(color: AppColors.blue1.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: Responsive.all(8),
            decoration: BoxDecoration(
              color: AppColors.blue1.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, color: AppColors.blue1, size: Responsive.sp(18)),
          ),
          SizedBox(width: Responsive.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedChild!.arabicFullName ?? _selectedChild!.fullName,
                  style: AppFonts.h4.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: Responsive.sp(14),
                  ),
                ),
                if (_selectedChild!.schoolId.id.isNotEmpty)
                  Text(
                    '${'current_school_colon'.tr} ${_selectedChild!.schoolId.name}',
                    style: AppFonts.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: Responsive.sp(11),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: Responsive.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: Responsive.symmetric(vertical: 14),
                    side: BorderSide(color: AppColors.blue1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Responsive.r(12)),
                    ),
                  ),
                  child: Text(
                    'back'.tr,
                    style: TextStyle(
                      color: AppColors.blue1,
                      fontSize: Responsive.sp(14),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0) SizedBox(width: Responsive.w(12)),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _canProceedFromCurrentStep()
                    ? (_currentStep == 6 ? _submitApplication : _nextStep)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue1,
                  disabledBackgroundColor: AppColors.grey300,
                  padding: Responsive.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Responsive.r(12)),
                  ),
                  elevation: 4,
                ),
                child: _isSubmitting
                    ? SizedBox(
                        height: Responsive.h(20),
                        width: Responsive.h(20),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _currentStep == 6 ? 'submit_application'.tr : 'next'.tr,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Responsive.sp(14),
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
}
