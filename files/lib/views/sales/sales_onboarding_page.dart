import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/sales_service.dart';
import '../../services/schools_service.dart';
import '../../widgets/loading_page.dart';
import '../../core/controllers/app_config_controller.dart';
import '../../core/constants/app_fonts.dart';

class SalesOnboardingPage extends StatefulWidget {
  const SalesOnboardingPage({super.key});

  @override
  State<SalesOnboardingPage> createState() => _SalesOnboardingPageState();
}

class _SalesOnboardingPageState extends State<SalesOnboardingPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 8;
  bool _isLoading = false;
  bool _showErrors = false;

  // Controllers for all fields
  // Step 1: School Data
  final TextEditingController _schoolNameArController = TextEditingController();
  final TextEditingController _schoolNameEnController = TextEditingController();
  final TextEditingController _shortNameController = TextEditingController();
  final TextEditingController _detailedAddressController = TextEditingController();
  final TextEditingController _administrationController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  // Step 3: Financial Data
  final TextEditingController _admissionFeeController = TextEditingController();
  final TextEditingController _registrationFeesController = TextEditingController();
  final TextEditingController _uniformFeesController = TextEditingController();
  final TextEditingController _busFeesMinController = TextEditingController();
  final TextEditingController _busFeesMaxController = TextEditingController();

  // Step 6: Owner Data
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _ownerEmailController = TextEditingController();
  final TextEditingController _ownerPhoneController = TextEditingController();

  // Step 7: Moderator Data
  final TextEditingController _modNameController = TextEditingController();
  final TextEditingController _modEmailController = TextEditingController();
  final TextEditingController _modPhoneController = TextEditingController();

  // Step 8: Site Setup
  final TextEditingController _primaryColorController = TextEditingController(text: '#1e40af');
  final TextEditingController _secondaryColorController = TextEditingController(text: '#1e293b');

  // Selection States
  String? _selectedType = 'private'; // private, international, experimental, language, other
  String? _selectedGenderPolicy = 'mixed'; // boys, girls, mixed
  String? _selectedReligionType = 'muslim'; // muslim, christian, all
  String? _selectedSpecialNeedsType = 'none'; // none, limited, special
  String? _selectedEducationSystemId;
  String? _selectedEducationTrackId;
  String? _selectedGovernorate;
  String? _selectedAdministration;

  // Academic Settings (Simple for now)
  Map<String, dynamic> _selectedStructure = {'stages': {}, 'classes': {}, 'subjects': {}};
  List<dynamic> _systems = [];
  List<dynamic> _tracks = [];
  List<dynamic> _schoolTypes = [];
  List<dynamic> _genderPolicies = [];
  List<dynamic> _religionTypes = [];
  List<dynamic> _specialNeedsTypes = [];
  List<dynamic> _governorates = [];
  Map<String, dynamic> _administrationsMap = {};
  List<dynamic> _availableAdministrationsList = [];
  List<dynamic> _apiFacilities = [];

  bool _isLoadingSystems = false;
  bool _isLoadingLookups = false;

  // Facilities
  List<String> _selectedFacilities = [];

  // Working Hours (Simplified: Weekday booleans)
  Map<String, bool> _workingDays = {
    'sunday': true,
    'monday': true,
    'tuesday': true,
    'wednesday': true,
    'thursday': true,
    'friday': false,
    'saturday': false,
  };

  @override
  void initState() {
    super.initState();
    _fetchEducationSystems();
    _fetchLookups();
  }

  Future<void> _fetchLookups() async {
    setState(() => _isLoadingLookups = true);
    try {
      final response = await SchoolsService.getLookups();
      final data = response['data'] ?? response;

      if (mounted) {
        setState(() {
          if (data.containsKey('schoolTypes')) _schoolTypes = data['schoolTypes'];
          if (data.containsKey('genderPolicies')) _genderPolicies = data['genderPolicies'];
          if (data.containsKey('religionTypes')) _religionTypes = data['religionTypes'];
          if (data.containsKey('specialNeedsTypes')) _specialNeedsTypes = data['specialNeedsTypes'];
          if (data.containsKey('facilities')) _apiFacilities = data['facilities'];
          
          if (data.containsKey('locations')) {
            final locations = data['locations'];
            _governorates = locations['governorates'] ?? [];
            _administrationsMap = locations['administrations'] ?? {};
          }

          // Initialize first values if available
          if (_selectedType == 'private' && _schoolTypes.isNotEmpty) _selectedType = _schoolTypes[0]['id']?.toString();
          if (_selectedGenderPolicy == 'mixed' && _genderPolicies.isNotEmpty) _selectedGenderPolicy = _genderPolicies[0]['id']?.toString();
          if (_selectedReligionType == 'muslim' && _religionTypes.isNotEmpty) _selectedReligionType = _religionTypes[0]['id']?.toString();
          if (_selectedSpecialNeedsType == 'none' && _specialNeedsTypes.isNotEmpty) _selectedSpecialNeedsType = _specialNeedsTypes[0]['id']?.toString();
        });
      }
    } catch (e) {
      print('Error fetching lookups: $e');
    } finally {
      if (mounted) setState(() => _isLoadingLookups = false);
    }
  }

  Future<void> _fetchEducationSystems() async {
    setState(() => _isLoadingSystems = true);
    try {
      final systems = await SchoolsService.getEducationSystems();
      if (mounted) {
        setState(() {
          _systems = systems;
          if (_systems.isNotEmpty) {
            // Initialize first system if nothing selected
            if (_selectedEducationSystemId == null) {
              _selectedEducationSystemId = _systems[0]['id']?.toString() ?? _systems[0]['_id']?.toString();
              if (_systems[0]['tracks'] != null && (_systems[0]['tracks'] as List).isNotEmpty) {
                _tracks = _systems[0]['tracks'];
                _selectedEducationTrackId = _tracks[0]['id']?.toString() ?? _tracks[0]['_id']?.toString();
              }
            }
          }
        });
      }
    } catch (e) {
      print('Error fetching systems: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSystems = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar('error'.tr, 'Location services are disabled.', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar('error'.tr, 'Location permissions are denied.', backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar('error'.tr, 'Location permissions are permanently denied.', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    setState(() => _isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _latController.text = position.latitude.toString();
          _lngController.text = position.longitude.toString();
        });
        Get.snackbar('success'.tr, 'Location fetched successfully.', backgroundColor: Colors.green, colorText: Colors.white);
      }
    } catch (e) {
      if (mounted) Get.snackbar('error'.tr, e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isCurrentStepValid() {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    
    switch (_currentStep) {
      case 0: // School Data
        final bool adminValid = _availableAdministrationsList.isNotEmpty 
            ? _selectedAdministration != null 
            : _administrationController.text.isNotEmpty;

        return _schoolNameArController.text.isNotEmpty &&
               _schoolNameEnController.text.isNotEmpty &&
               _selectedEducationSystemId != null &&
               _selectedGovernorate != null &&
               adminValid;
      case 1: // Academic Settings
        final stages = _selectedStructure['stages'] as Map? ?? {};
        return stages.values.any((s) => s['active'] == true);
      case 2: // Financial Data - No strict validation as per JS
        return true;
      case 3: // Working Hours - No strict validation as per JS
        return true;
      case 4: // Facilities - Optional
        return true;
      case 5: // Owner Data
        return _ownerNameController.text.isNotEmpty &&
               emailRegex.hasMatch(_ownerEmailController.text) &&
               _ownerPhoneController.text.isNotEmpty;
      case 6: // Moderator Data
        return _modNameController.text.isNotEmpty &&
               emailRegex.hasMatch(_modEmailController.text) &&
               _modPhoneController.text.isNotEmpty;
      case 7: // Review
        return true;
      default:
        return false;
    }
  }

  Future<void> _nextStep() async {
    setState(() => _showErrors = true);
    if (!_isCurrentStepValid()) return;

    // Additional Collision Checks for Owner/Admin
    if (_currentStep == 5) { // Owner step
       setState(() => _isLoading = true);
       final isColliding = await _checkCollision(_ownerEmailController.text, _ownerPhoneController.text);
       if (mounted) setState(() => _isLoading = false);
       if (isColliding) {
          Get.snackbar('collision'.tr, 'email_or_phone_already_exists'.tr, backgroundColor: Colors.red, colorText: Colors.white);
          return;
       }
    } else if (_currentStep == 6) { // Moderator step
       setState(() => _isLoading = true);
       final isColliding = await _checkCollision(_modEmailController.text, _modPhoneController.text);
       if (mounted) setState(() => _isLoading = false);
       if (isColliding) {
          Get.snackbar('collision'.tr, 'email_or_phone_already_exists'.tr, backgroundColor: Colors.red, colorText: Colors.white);
          return;
       }
    }

    setState(() => _showErrors = false);
    if (_currentStep < _totalSteps - 1) {
      if (mounted) setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitForm();
    }
  }

  Future<bool> _checkCollision(String email, String phone) async {
     try {
        final emailCollision = await AuthService.checkUserCollision(email: email);
        if (emailCollision) return true;
        final phoneCollision = await AuthService.checkUserCollision(phone: phone);
        return phoneCollision;
     } catch (e) {
        return false;
     }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitForm() async {
    setState(() => _isLoading = true);
    try {
      // Map working days to time slots if true
      final Map<String, dynamic> formattedWorkingHours = {};
      final List<String> arDays = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
      final List<String> enDays = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
      
      for (int i = 0; i < enDays.length; i++) {
        final dayEn = enDays[i];
        final dayAr = arDays[i];
        if (_workingDays[dayEn] == true) {
          formattedWorkingHours[dayAr] = {'from': '08:00', 'to': '15:00'};
          formattedWorkingHours[dayEn] = {'from': '08:00', 'to': '15:00'};
        }
      }

      final onboardingData = {
        'schoolData': {
          'name': _schoolNameArController.text,
          'nameEn': _schoolNameEnController.text,
          'shortName': _shortNameController.text,
          'type': _selectedType,
          'gender': _selectedGenderPolicy,
          'religion': _selectedReligionType,
          'specialNeeds': _selectedSpecialNeedsType,
          'educationSystemId': _selectedEducationSystemId,
          'educationTrackId': _selectedEducationTrackId,
          'location': {
            'governorate': _selectedGovernorate,
            'educationalAdministration': _selectedAdministration ?? _administrationController.text,
            'detailedAddress': _detailedAddressController.text,
            'coordinates': {'lat': _latController.text, 'lng': _lngController.text},
          },
          'selectedStructure': _selectedStructure,
          'feesDetails': {
            'admissionFee': _admissionFeeController.text,
            'registrationFees': _registrationFeesController.text,
            'uniformFees': _uniformFeesController.text,
            'busFees': {'min': _busFeesMinController.text, 'max': _busFeesMaxController.text},
          },
          'financials': {
            'registrationFees': double.tryParse(_registrationFeesController.text) ?? 0,
            'busFees': double.tryParse(_busFeesMinController.text) ?? 0,
            'uniformFees': double.tryParse(_uniformFeesController.text) ?? 0,
            'otherFees': 0,
          },
          'admissionFee': {
            'amount': double.tryParse(_admissionFeeController.text) ?? 0,
            'currency': 'EGP',
            'isRefundable': false,
          },
        },
        'workingHours': formattedWorkingHours,
        'facilities': _selectedFacilities,
        'ownerData': {
          'name': _ownerNameController.text,
          'email': _ownerEmailController.text,
          'phone': _ownerPhoneController.text,
        },
        'moderatorData': {
          'name': _modNameController.text,
          'email': _modEmailController.text,
          'phone': _modPhoneController.text,
        },
        'configData': {
          'siteSetup': {
            'primaryColor': _primaryColorController.text,
            'secondaryColor': _secondaryColorController.text,
            'showInSearch': true,
          },
        },
      };

      print('📤 [ONBOARDING] Request Payload: ${const JsonEncoder.withIndent('  ').convert(onboardingData)}');
      
      final response = await SalesService.onboardSchool(onboardingData);
      print('📥 [ONBOARDING] Response: $response');

      Get.snackbar(
        'success'.tr,
        'school_created_successfully'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      
      // Navigate to sales home after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        Get.offAllNamed(AppRoutes.salesHome);
      });
    } catch (e) {
      print('❌ [ONBOARDING] Error: $e');
      Get.snackbar(
        'error'.tr,
        e.toString().tr, // Ensure error messages are translated if they keys
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isRtl = Get.locale?.languageCode == 'ar';
    
    return Obx(() {
      final isDark = AppConfigController.to.isDarkMode;
      final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
      final surfaceColor = Theme.of(context).colorScheme.surface;
      final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

      return PopScope(
        canPop: _currentStep == 0,
        onPopInvoked: (didPop) {
          if (didPop) return;
          _previousStep();
        },
        child: Stack(
          children: [
            Scaffold(
              backgroundColor: scaffoldColor,
          appBar: AppBar(
            title: Text('onboard_new_school'.tr, 
                style: AppFonts.AlmaraiBold18.copyWith(color: onSurfaceColor)),
            centerTitle: true,
            backgroundColor: surfaceColor,
            elevation: 0,
            foregroundColor: onSurfaceColor,
            leading: IconButton(
              icon: Icon(isRtl ? Icons.arrow_back_ios : Icons.arrow_forward_ios, size: 18),
              onPressed: () {
                if (_currentStep > 0) {
                  _previousStep(); 
                } else {
                  Get.back();
                }
              },
            ),
            actions: [
              IconButton(
                icon: Icon(isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round_rounded),
                onPressed: () => AppConfigController.to.toggleTheme(),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              _buildModernStepIndicator(isDark, surfaceColor, onSurfaceColor),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _fadeIn(0, child: _buildStepSchoolData(isDark)),
                    _fadeIn(0, child: _buildStepAcademicSettings(isDark)),
                    _fadeIn(0, child: _buildStepFinancialData(isDark)),
                    _fadeIn(0, child: _buildStepWorkingHours(isDark)),
                    _fadeIn(0, child: _buildStepFacilities(isDark)),
                    _fadeIn(0, child: _buildStepOwnerData(isDark)),
                    _fadeIn(0, child: _buildStepModeratorData(isDark)),
                    _fadeIn(0, child: _buildStepReview(isDark)),
                  ],
                ),
              ),
              _buildNavigationButtons(surfaceColor, onSurfaceColor),
            ],
          ),
        ),
        if (_isLoading)
          const Positioned.fill(
            child: LoadingPage(),
          ),
      ],
    ),
  );
});
}

  Widget _fadeIn(int index, {required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildModernStepIndicator(bool isDark, Color surfaceColor, Color onSurfaceColor) {
    final List<String> stepNames = [
      'school'.tr,
      'academic_settings'.tr,
      'financial_data'.tr,
      'working_hours'.tr,
      'facilities'.tr,
      'owner'.tr,
      'accounts'.tr, // moderator
      'review'.tr,
    ];

    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black12, width: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSteps, (index) {
              bool isCompleted = index < _currentStep;
              bool isActive = index == _currentStep;
              
              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 28.w,
                      height: 28.w,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.salesAccent : (isCompleted ? Colors.green : (isDark ? Colors.white12 : Colors.grey[200])),
                        shape: BoxShape.circle,
                        boxShadow: isActive ? [BoxShadow(color: AppColors.salesAccent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : Text(
                                (index + 1).toString(),
                                style: AppFonts.AlmaraiBold12.copyWith(
                                  color: isActive ? Colors.white : (isDark ? Colors.white54 : Colors.grey[600]),
                                ),
                              ),
                      ),
                    ),
                    if (index < _totalSteps - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index < _currentStep ? Colors.green : (isDark ? Colors.white12 : Colors.grey[200]),
                          margin: EdgeInsets.symmetric(horizontal: 4.w),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${'Step'.tr} ${_currentStep + 1} / $_totalSteps',
                style: AppFonts.AlmaraiBold10.copyWith(color: isDark ? Colors.white38 : Colors.grey[500]),
              ),
              Text(
                stepNames[_currentStep],
                style: AppFonts.AlmaraiBold12.copyWith(color: AppColors.salesAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(Color surfaceColor, Color onSurfaceColor) {
    return Container(
      padding: EdgeInsets.all(24.h),
      decoration: BoxDecoration(
        color: surfaceColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                side: BorderSide(color: AppColors.salesAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('previous'.tr, style: AppFonts.AlmaraiBold14.copyWith(color: AppColors.salesAccent)),
              ),
            ),
          if (_currentStep > 0) SizedBox(width: 16.w),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.salesAccent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.salesAccent.withOpacity(0.35),
                disabledForegroundColor: Colors.white.withOpacity(0.7),
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_currentStep == _totalSteps - 1 ? 'submit'.tr : 'next'.tr, style: AppFonts.AlmaraiBold14),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step Content Widgets ---

  Widget _buildStepSchoolData(bool isDark) {
    bool isRtl = Get.locale?.languageCode == 'ar';
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('school_information'.tr, 'school_step_desc'.tr, isDark),
          SizedBox(height: 24.h),
          _buildTextField(_schoolNameArController, 'school_name_ar'.tr, IconlyLight.edit, isRtl: true),
          _buildTextField(_schoolNameEnController, 'school_name_en'.tr, IconlyLight.edit),
          _buildTextField(_shortNameController, 'short_name'.tr, IconlyLight.ticket_star),
          
          _buildSectionTitle('school_type'.tr),
          _buildTypeSelector(isDark),
          
          _buildSectionTitle('admission_policies'.tr),
          _buildEnhancedDropdown(
            'gender_policy_label'.tr, 
            _selectedGenderPolicy, 
            _genderPolicies.isNotEmpty ? _genderPolicies.map((p) => p['id']?.toString() ?? '').toList() : ['mixed', 'boys', 'girls'], 
            (val) => setState(() => _selectedGenderPolicy = val), 
            itemsLabels: _genderPolicies.isNotEmpty ? _genderPolicies.map((p) => (isRtl ? p['label'] : (p['labelEn'] ?? p['label']))?.toString() ?? '').toList() : null,
            icon: IconlyLight.user_1
          ),
          _buildEnhancedDropdown(
            'religion_policy_label'.tr, 
            _selectedReligionType, 
            _religionTypes.isNotEmpty ? _religionTypes.map((p) => p['id']?.toString() ?? '').toList() : ['muslim', 'christian', 'all'], 
            (val) => setState(() => _selectedReligionType = val), 
            itemsLabels: _religionTypes.isNotEmpty ? _religionTypes.map((p) => (isRtl ? p['label'] : (p['labelEn'] ?? p['label']))?.toString() ?? '').toList() : null,
            icon: IconlyLight.info_square
          ),
          _buildEnhancedDropdown(
            'special_needs_policy_label'.tr, 
            _selectedSpecialNeedsType, 
            _specialNeedsTypes.isNotEmpty ? _specialNeedsTypes.map((p) => p['id']?.toString() ?? '').toList() : ['none', 'limited', 'special'], 
            (val) => setState(() => _selectedSpecialNeedsType = val), 
            itemsLabels: _specialNeedsTypes.isNotEmpty ? _specialNeedsTypes.map((p) => (isRtl ? p['label'] : (p['labelEn'] ?? p['label']))?.toString() ?? '').toList() : null,
            icon: IconlyLight.heart
          ),

          _buildSectionTitle('education_details'.tr),
          if (_isLoadingSystems)
            const Center(child: CircularProgressIndicator())
          else ...[
            _buildEnhancedDropdown('education_system'.tr, _selectedEducationSystemId, _systems.map((s) => (s['id']?.toString() ?? s['_id']?.toString() ?? '')).toList(), (val) {
              setState(() {
                 _selectedEducationSystemId = val;
                 _selectedStructure['stages'] = {}; // Clear previous choices
                 final system = _systems.firstWhereOrNull((s) => (s['id']?.toString() ?? s['_id']?.toString()) == val);
                 _tracks = system?['tracks'] ?? [];
                 if (_tracks.isNotEmpty) {
                   _selectedEducationTrackId = _tracks[0]['id']?.toString() ?? _tracks[0]['_id']?.toString();
                 } else {
                   _selectedEducationTrackId = null;
                 }
              });
            }, itemsLabels: _systems.map((s) => (s['name']?.toString() ?? '')).toList(), icon: IconlyLight.category),
            
            if (_tracks.isNotEmpty)
              _buildEnhancedDropdown('education_track'.tr, _selectedEducationTrackId, _tracks.map((t) => (t['id']?.toString() ?? t['_id']?.toString() ?? '')).toList(), (val) {
                setState(() {
                  _selectedEducationTrackId = val;
                  _selectedStructure['stages'] = {}; // Clear previous choices
                });
              }, itemsLabels: _tracks.map((t) => (t['name']?.toString() ?? '')).toList(), icon: IconlyLight.discovery),
          ],

          _buildSectionTitle('location'.tr),
          _buildEnhancedDropdown(
            'governorate'.tr, 
            _selectedGovernorate, 
            _governorates.map((g) => g['id']?.toString() ?? '').toList(), 
            (val) {
              setState(() {
                _selectedGovernorate = val;
                _selectedAdministration = null;
                _availableAdministrationsList = _administrationsMap[val] ?? [];
              });
            }, 
            itemsLabels: _governorates.map((g) => (isRtl ? g['nameAr'] : g['nameEn'])?.toString() ?? '').toList(),
            icon: IconlyLight.location, 
            hintText: 'governorate_hint'.tr
          ),
          
          if (_availableAdministrationsList.isNotEmpty)
            _buildEnhancedDropdown(
              'administration'.tr, 
              _selectedAdministration, 
              _availableAdministrationsList.map((a) => a['id']?.toString() ?? '').toList(), 
              (val) => setState(() => _selectedAdministration = val), 
              itemsLabels: _availableAdministrationsList.map((a) => (isRtl ? a['nameAr'] : a['nameEn'])?.toString() ?? '').toList(),
              icon: IconlyLight.location, 
              hintText: 'administration_hint'.tr
            )
          else
            _buildTextField(_administrationController, 'administration'.tr, IconlyLight.location, hintText: 'administration_hint'.tr),
          _buildTextField(_detailedAddressController, 'detailed_address'.tr, IconlyLight.more_square, maxLines: 2, hintText: 'detailed_address_hint'.tr),
          
          Row(
            children: [
              Expanded(child: _buildTextField(_latController, 'latitude'.tr, IconlyLight.discovery, keyboardType: TextInputType.number, hintText: 'latitude_hint'.tr)),
              SizedBox(width: 16.w),
              Expanded(child: _buildTextField(_lngController, 'longitude'.tr, IconlyLight.discovery, keyboardType: TextInputType.number, hintText: 'longitude_hint'.tr)),
            ],
          ),
          _buildGetLocationButton(isDark),
        ],
      ),
    );
  }

  Widget _buildGetLocationButton(bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: InkWell(
        onTap: _getCurrentLocation,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
          decoration: BoxDecoration(
            color: AppColors.salesAccent.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.salesAccent.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(IconlyLight.location, color: AppColors.salesAccent, size: 20),
              SizedBox(width: 8.w),
              Text(
                'get_current_location'.tr,
                style: AppFonts.AlmaraiBold12.copyWith(color: AppColors.salesAccent),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepAcademicSettings(bool isDark) {
    if (_selectedEducationSystemId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(IconlyLight.info_square, size: 64, color: Colors.grey),
            SizedBox(height: 16.h),
            Text('select_education_system'.tr, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      );
    }

    final system = _systems.firstWhereOrNull((s) => (s['id']?.toString() ?? s['_id']?.toString()) == _selectedEducationSystemId);
    
    List stages = [];
    if (_selectedEducationTrackId != null && system != null) {
      final track = (system['tracks'] as List?)?.firstWhereOrNull((t) => (t['id']?.toString() ?? t['_id']?.toString()) == _selectedEducationTrackId);
      if (track != null && track['stages'] != null) {
        stages = track['stages'];
      }
    }
    
    if (stages.isEmpty && system != null) {
      stages = system['stages'] ?? [];
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('academic_settings'.tr, 'academic_step_desc'.tr, isDark),
          SizedBox(height: 24.h),
          
          if (stages.isEmpty)
             _buildEmptyState('no_stages_available'.tr)
          else
            ...stages.map((stage) {
              final stageId = stage['id']?.toString() ?? stage['_id']?.toString() ?? '';
              final stageName = stage['name']?.toString() ?? '';
              final isStageActive = _selectedStructure['stages'][stageId]?['active'] ?? false;
              int gradeCount = (stage['grades'] as List?)?.length ?? 0;

              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isStageActive ? AppColors.salesAccent : (isDark ? Colors.white12 : Colors.grey[200]!)),
                ),
                child: CheckboxListTile(
                  title: Text(stageName, style: AppFonts.AlmaraiBold14.copyWith(color: isStageActive ? AppColors.salesAccent : Theme.of(context).colorScheme.onSurface)),
                  subtitle: Text('total_grades'.trParams({'count': gradeCount.toString()}), style: AppFonts.AlmaraiRegular12.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                  value: isStageActive,
                  activeColor: AppColors.salesAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedStructure['stages'][stageId] = {'active': true, 'customName': ''};
                      } else {
                        _selectedStructure['stages'][stageId] = {'active': false};
                      }
                    });
                  },
                ),
              );
            }).toList(),
            
          SizedBox(height: 32.h),
          _buildInfoBox('customize_academic_info'.tr, isDark),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        children: [
          Icon(IconlyLight.info_square, size: 48, color: Colors.amber[200]),
          SizedBox(height: 12.h),
          Text(message, style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String message, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: AppColors.salesAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.salesAccent.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(IconlyLight.info_square, color: AppColors.salesAccent, size: 20),
          SizedBox(width: 12.w),
          Expanded(child: Text(message, style: AppFonts.AlmaraiMedium12.copyWith(color: AppColors.salesAccent))),
        ],
      ),
    );
  }

  Widget _buildStepFinancialData(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('financial_data'.tr, 'financial_step_desc'.tr, isDark),
          SizedBox(height: 24.h),
          _buildTextField(_admissionFeeController, 'admission_fees'.tr, IconlyLight.wallet, keyboardType: TextInputType.number),
          _buildTextField(_registrationFeesController, 'registration'.tr, IconlyLight.document, keyboardType: TextInputType.number),
          _buildTextField(_uniformFeesController, 'uniform'.tr, IconlyLight.bag, keyboardType: TextInputType.number),
          
          _buildSectionTitle('bus_subscription'.tr),
          Row(
            children: [
              Expanded(child: _buildTextField(_busFeesMinController, 'min'.tr, IconlyLight.arrow_down, keyboardType: TextInputType.number)),
              SizedBox(width: 16.w),
              Expanded(child: _buildTextField(_busFeesMaxController, 'max'.tr, IconlyLight.arrow_up, keyboardType: TextInputType.number)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepWorkingHours(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('working_hours'.tr, 'working_hours_step_desc'.tr, isDark),
          SizedBox(height: 24.h),
          ..._workingDays.keys.map((day) {
            bool isActive = _workingDays[day]!;
            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isActive ? AppColors.salesAccent : (isDark ? Colors.white12 : Colors.grey[200]!)),
              ),
              child: CheckboxListTile(
                title: Text(day.tr, style: AppFonts.AlmaraiBold14.copyWith(color: isActive ? AppColors.salesAccent : Theme.of(context).colorScheme.onSurface)),
                value: isActive,
                activeColor: AppColors.salesAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onChanged: (val) => setState(() => _workingDays[day] = val!),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStepFacilities(bool isDark) {
    final List<Map<String, dynamic>> defaultFacilities = [
      {'id': 'swimming_pool', 'name': 'swimming_pool', 'icon': Icons.pool, 'color': Colors.blue},
      {'id': 'library', 'name': 'library', 'icon': Icons.library_books, 'color': Colors.brown},
      {'id': 'lab', 'name': 'lab', 'icon': Icons.science, 'color': Colors.orange},
      {'id': 'gym', 'name': 'gym', 'icon': Icons.sports_basketball, 'color': Colors.red},
      {'id': 'theater', 'name': 'theater', 'icon': Icons.theater_comedy, 'color': Colors.purple},
      {'id': 'clinic', 'name': 'clinic', 'icon': Icons.medical_services, 'color': Colors.teal},
      {'id': 'playground', 'name': 'playground', 'icon': Icons.child_care, 'color': Colors.green},
      {'id': 'cafeteria', 'name': 'cafeteria', 'icon': Icons.restaurant, 'color': Colors.amber},
      {'id': 'computer_lab', 'name': 'computer_lab', 'icon': Icons.computer, 'color': Colors.indigo},
    ];

    final displayFacilities = _apiFacilities.isNotEmpty ? _apiFacilities : defaultFacilities;

    return SingleChildScrollView(
      padding: EdgeInsets.all(24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('facilities'.tr, 'facilities_step_desc'.tr, isDark),
          SizedBox(height: 24.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 0.9,
            ),
            itemCount: displayFacilities.length,
            itemBuilder: (context, index) {
              final f = displayFacilities[index];
              final id = f['id']?.toString() ?? '';
              final isSelected = _selectedFacilities.contains(id);
              
              IconData iconData = Icons.star;
              Color facilityColor = Colors.blue;
              
              String iconKey = (f['icon'] ?? f['id'] ?? '').toString().toLowerCase();
              String nameKey = (f['name'] ?? '').toString().toLowerCase();
              String combinedKey = '$iconKey $nameKey';

              if (combinedKey.contains('pool')) { iconData = Icons.pool; facilityColor = Colors.blue; }
              else if (combinedKey.contains('library')) { iconData = Icons.library_books; facilityColor = Colors.brown; }
              else if (combinedKey.contains('lab') || combinedKey.contains('science')) { iconData = Icons.science; facilityColor = Colors.orange; }
              else if (combinedKey.contains('gym') || combinedKey.contains('sport') || combinedKey.contains('fitness')) { iconData = Icons.sports_basketball; facilityColor = Colors.red; }
              else if (combinedKey.contains('theater') || combinedKey.contains('cinema') || combinedKey.contains('hall')) { iconData = Icons.theater_comedy; facilityColor = Colors.purple; }
              else if (combinedKey.contains('clinic') || combinedKey.contains('medical') || combinedKey.contains('nurse')) { iconData = Icons.medical_services; facilityColor = Colors.teal; }
              else if (combinedKey.contains('playground') || combinedKey.contains('fun') || combinedKey.contains('kids')) { iconData = Icons.child_care; facilityColor = Colors.green; }
              else if (combinedKey.contains('cafeteria') || combinedKey.contains('food') || combinedKey.contains('restaurant')) { iconData = Icons.restaurant; facilityColor = Colors.amber; }
              else if (combinedKey.contains('computer') || combinedKey.contains('it ') || combinedKey.contains('coding')) { iconData = Icons.computer; facilityColor = Colors.indigo; }
              else if (combinedKey.contains('soccer') || combinedKey.contains('football') || combinedKey.contains('field')) { iconData = Icons.sports_soccer; facilityColor = Colors.green[700]!; }
              else if (combinedKey.contains('music') || combinedKey.contains('piano')) { iconData = Icons.music_note; facilityColor = Colors.pink; }
              else if (combinedKey.contains('art') || combinedKey.contains('paint')) { iconData = Icons.palette; facilityColor = Colors.deepOrange; }
              else if (combinedKey.contains('mosque') || combinedKey.contains('prayer')) { iconData = Icons.mosque; facilityColor = Colors.teal; }
              else if (combinedKey.contains('security') || combinedKey.contains('camera')) { iconData = Icons.security; facilityColor = Colors.blueGrey; }
              else if (combinedKey.contains('bus') || combinedKey.contains('transport')) { iconData = Icons.directions_bus; facilityColor = Colors.orange[800]!; }

              if (f['icon'] is IconData) iconData = f['icon'];
              if (f['color'] is Color) facilityColor = f['color'];

              String label = (f['name'] ?? f['label'] ?? id).toString();
              String slug = label.toLowerCase().replaceAll(' ', '_');
              String translated = slug.tr;
              label = translated != slug ? translated : label.tr;

              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) _selectedFacilities.remove(id);
                    else _selectedFacilities.add(id);
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? facilityColor.withOpacity(0.08) : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? facilityColor : (isDark ? Colors.white12 : Colors.grey[200]!), width: isSelected ? 2 : 1),
                    boxShadow: isSelected ? [BoxShadow(color: facilityColor.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))] : null,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(color: isSelected ? facilityColor : facilityColor.withOpacity(0.1), shape: BoxShape.circle),
                              child: Icon(iconData, color: isSelected ? Colors.white : facilityColor, size: 24),
                            ),
                            SizedBox(height: 10.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 10.sp, color: isSelected ? Colors.black87 : Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected) Positioned(top: 8, right: 8, child: Icon(Icons.check_circle, color: facilityColor, size: 16)),
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 24.h),
          _buildInfoBox('facilities_step_info'.tr, isDark),
        ],
      ),
    );
  }

  Widget _buildStepOwnerData(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('owner_information'.tr, 'owner_step_desc'.tr, isDark),
          SizedBox(height: 24.h),
          _buildTextField(_ownerNameController, 'full_name'.tr, IconlyLight.user, isDark: isDark),
          _buildTextField(_ownerEmailController, 'email'.tr, IconlyLight.message, keyboardType: TextInputType.emailAddress, isDark: isDark),
          _buildTextField(_ownerPhoneController, 'phone'.tr, IconlyLight.call, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly], isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildStepModeratorData(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('accounts'.tr, 'accounts_step_desc'.tr, isDark),
          SizedBox(height: 24.h),
          _buildTextField(_modNameController, 'full_name'.tr, IconlyLight.user, isDark: isDark),
          _buildTextField(_modEmailController, 'email'.tr, IconlyLight.message, keyboardType: TextInputType.emailAddress, isDark: isDark),
          _buildTextField(_modPhoneController, 'phone'.tr, IconlyLight.call, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly], isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildStepReview(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('review_and_submit'.tr, 'review_step_desc'.tr, isDark),
          SizedBox(height: 24.h),
          _buildReviewCard('school'.tr, [
            {'label': 'school_name_ar'.tr, 'value': _schoolNameArController.text},
            {'label': 'school_name_en'.tr, 'value': _schoolNameEnController.text},
            {'label': 'short_name'.tr, 'value': _shortNameController.text},
            {'label': 'school_type'.tr, 'value': _selectedType?.tr},
            {'label': 'governorate'.tr, 'value': _selectedGovernorate},
            {'label': 'administration'.tr, 'value': _selectedAdministration ?? _administrationController.text},
            {'label': 'detailed_address'.tr, 'value': _detailedAddressController.text},
            {'label': 'coordinates'.tr, 'value': '${_latController.text}, ${_lngController.text}'},
          ], isDark),
          _buildReviewCard('admission_policies'.tr, [
            {'label': 'gender_policy_label'.tr, 'value': _selectedGenderPolicy?.tr},
            {'label': 'religion_policy_label'.tr, 'value': _selectedReligionType?.tr},
            {'label': 'special_needs_policy_label'.tr, 'value': _selectedSpecialNeedsType?.tr},
          ], isDark),
          _buildReviewCard('financial_data'.tr, [
            {'label': 'admission_fees'.tr, 'value': _admissionFeeController.text},
            {'label': 'registration_fees'.tr, 'value': _registrationFeesController.text},
            {'label': 'uniform_fees'.tr, 'value': _uniformFeesController.text},
            {'label': 'bus_fees'.tr, 'value': '${_busFeesMinController.text} - ${_busFeesMaxController.text}'},
          ], isDark),
          _buildReviewCard('owner'.tr, [
            {'label': 'full_name'.tr, 'value': _ownerNameController.text},
            {'label': 'email'.tr, 'value': _ownerEmailController.text},
            {'label': 'phone'.tr, 'value': _ownerPhoneController.text},
          ], isDark),
          _buildReviewCard('moderator'.tr, [
            {'label': 'full_name'.tr, 'value': _modNameController.text},
            {'label': 'email'.tr, 'value': _modEmailController.text},
            {'label': 'phone'.tr, 'value': _modPhoneController.text},
          ], isDark),
          
          Container(
            padding: EdgeInsets.all(16.h),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber[100]!),
            ),
            child: Row(
              children: [
                const Icon(IconlyLight.info_square, color: Colors.amber),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'onboarding_final_notice'.tr,
                    style: TextStyle(fontSize: 11, color: Colors.amber[900], fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper UI Components ---

  Widget _buildStepHeader(String title, String subtitle, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppFonts.AlmaraiBold22.copyWith(color: Theme.of(context).colorScheme.onSurface)),
        SizedBox(height: 4.h),
        Text(subtitle, style: AppFonts.AlmaraiRegular12.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 24.h, bottom: 12.h),
      child: Text(title, style: AppFonts.AlmaraiBold14.copyWith(color: Theme.of(context).colorScheme.onSurface)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscureText = false, TextInputType? keyboardType, bool isRtl = false, int maxLines = 1, String? hintText, List<TextInputFormatter>? inputFormatters, bool isDark = false}) {
    final bool isEmail = keyboardType == TextInputType.emailAddress;
    final bool isEmpty = controller.text.trim().isEmpty;
    final bool isValidEmail = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(controller.text);
    
    final bool showGreen = isEmail ? isValidEmail : !isEmpty;
    final bool showRed = _showErrors && (isEmail ? !isValidEmail : isEmpty);
    
    final Color borderColor = showRed ? Colors.red : (showGreen ? Colors.green : (isDark ? Colors.white12 : Colors.grey[200]!));

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        textAlign: isRtl ? TextAlign.right : TextAlign.left,
        onChanged: (_) => setState(() {}),
        style: AppFonts.AlmaraiRegular14.copyWith(color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          labelStyle: AppFonts.AlmaraiRegular12.copyWith(color: showRed ? Colors.red[300] : (isDark ? Colors.white38 : Colors.grey[600])),
          hintStyle: AppFonts.AlmaraiRegular12.copyWith(color: isDark ? Colors.white24 : Colors.grey[300]),
          prefixIcon: Icon(icon, color: showRed ? Colors.red[300] : (showGreen ? Colors.green : AppColors.salesAccent), size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: showRed ? Colors.red : (showGreen ? Colors.green : AppColors.salesAccent), width: 2)),
          filled: true,
          fillColor: showRed ? Colors.red.withOpacity(0.01) : (showGreen ? Colors.green.withOpacity(0.01) : Theme.of(context).colorScheme.surface),
        ),
      ),
    );
  }

  Widget _buildEnhancedDropdown(String label, String? value, List<String> items, Function(String?) onChanged, {List<String>? itemsLabels, IconData? icon, String? hintText, bool isDark = false}) {
    final bool isEmpty = value == null || value.isEmpty;
    final Color borderColor = isEmpty ? Colors.red.withOpacity(0.5) : (isDark ? Colors.white12 : Colors.green.withOpacity(0.5));

    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppFonts.AlmaraiBold12.copyWith(color: isEmpty ? Colors.red[300] : (isDark ? Colors.white54 : Colors.grey[700]))),
          SizedBox(height: 8.h),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: isEmpty ? Colors.red.withOpacity(0.05) : (isDark ? Colors.black26 : Colors.black.withOpacity(0.03)), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: DropdownButtonFormField<String>(
              value: items.contains(value) ? value : null,
              onChanged: (val) {
                onChanged(val);
                setState(() {}); // Force visual update
              },
              hint: hintText != null ? Text(hintText, style: AppFonts.AlmaraiRegular12.copyWith(color: isDark ? Colors.white24 : Colors.grey[400])) : null,
              icon: Icon(IconlyLight.arrow_down_2, size: 18, color: isEmpty ? Colors.red[300] : AppColors.salesAccent),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                prefixIcon: Icon(icon ?? IconlyLight.category, color: isEmpty ? Colors.red[300] : AppColors.salesAccent, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isEmpty ? Colors.red : AppColors.salesAccent, width: 2)),
                filled: true,
                fillColor: isEmpty ? Colors.red.withOpacity(0.01) : Colors.green.withOpacity(0.01),
              ),
              dropdownColor: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              items: List.generate(items.length, (index) {
                return DropdownMenuItem(
                  value: items[index],
                  child: Text(
                    itemsLabels != null ? itemsLabels[index] : items[index].tr,
                    style: AppFonts.AlmaraiRegular12.copyWith(color: Theme.of(context).colorScheme.onSurface),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(bool isDark) {
    if (_isLoadingLookups && _schoolTypes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final types = _schoolTypes.isNotEmpty ? _schoolTypes : [
      {'id': 'private', 'label': 'private', 'icon': Icons.school},
      {'id': 'international', 'label': 'international', 'icon': Icons.public},
      {'id': 'experimental', 'label': 'experimental', 'icon': Icons.science},
      {'id': 'language', 'label': 'language', 'icon': Icons.translate},
      {'id': 'other', 'label': 'other', 'icon': Icons.more_horiz},
    ];

    bool isAr = Get.locale?.languageCode == 'ar';

    return SizedBox(
      height: 90.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: types.length,
        itemBuilder: (context, index) {
          final type = types[index];
          final typeId = type['id']?.toString() ?? '';
          final isSelected = _selectedType == typeId;
          
          // Map icons for well-known types
          IconData iconData = Icons.school;
          if (typeId.toLowerCase().contains('international')) iconData = Icons.public;
          if (typeId.toLowerCase().contains('experimental')) iconData = Icons.science;
          if (typeId.toLowerCase().contains('language')) iconData = Icons.translate;
          if (typeId.toLowerCase().contains('national')) iconData = Icons.account_balance;
          if (type.containsKey('icon')) iconData = type['icon'] as IconData;

          String label = typeId;
          if (type.containsKey('label')) {
            label = isAr ? type['label'] : (type['labelEn'] ?? type['label']);
          } else {
            label = typeId.tr;
          }

          return GestureDetector(
            onTap: () => setState(() => _selectedType = typeId),
            child: Container(
              width: 100.w,
              margin: EdgeInsets.only(right: 12.w),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.salesAccent.withOpacity(0.05) : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? AppColors.salesAccent : (isDark ? Colors.white12 : Colors.grey[200]!), width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.salesAccent : (isDark ? Colors.white12 : Colors.grey[100]),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: isSelected ? Colors.white : (isDark ? Colors.white38 : Colors.grey[400]), size: 20),
                  ),
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.AlmaraiBold10.copyWith(color: isSelected ? AppColors.salesAccent : (isDark ? Colors.white54 : Colors.grey[600])),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _schoolNameArController.dispose();
    _schoolNameEnController.dispose();
    _shortNameController.dispose();
    _detailedAddressController.dispose();
    _administrationController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _admissionFeeController.dispose();
    _registrationFeesController.dispose();
    _uniformFeesController.dispose();
    _busFeesMinController.dispose();
    _busFeesMaxController.dispose();
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _ownerPhoneController.dispose();
    _modNameController.dispose();
    _modEmailController.dispose();
    _modPhoneController.dispose();
    _primaryColorController.dispose();
    _secondaryColorController.dispose();
    super.dispose();
  }

  Widget _buildReviewCard(String title, List<Map<String, String?>> details, bool isDark) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppFonts.AlmaraiBold14.copyWith(color: AppColors.salesAccent)),
          Divider(color: isDark ? Colors.white10 : Colors.black12),
          ...details.map((d) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(d['label']!, style: AppFonts.AlmaraiRegular12.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                Text(d['value'] ?? 'N/A', style: AppFonts.AlmaraiBold12.copyWith(color: Theme.of(context).colorScheme.onSurface)),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}
