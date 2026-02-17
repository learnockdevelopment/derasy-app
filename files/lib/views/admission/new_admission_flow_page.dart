import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/assets.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/routes/app_routes.dart';
import '../../models/student_models.dart';
import '../../models/lookup_models.dart';
import '../../models/education_system_models.dart';
import '../../models/admission_models.dart';
import '../../models/school_models.dart';  
import '../../services/students_service.dart';
import '../../services/admission_service.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/safe_network_image.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../widgets/loading_page.dart';

extension NumberFormatting on num {
  String toLocaleString() => NumberFormat.decimalPattern().format(this);
}

class NewAdmissionFlowPage extends StatefulWidget {
  const NewAdmissionFlowPage({Key? key}) : super(key: key);

  @override
  State<NewAdmissionFlowPage> createState() => _NewAdmissionFlowPageState();
}

class _NewAdmissionFlowPageState extends State<NewAdmissionFlowPage> with TickerProviderStateMixin {
  int _currentStep = 1;
  final int _totalSteps = 5;
  bool _isLoadingData = true;
  List<Student> _relatedChildren = [];
  LookupData? _lookups;
  List<EducationSystem> _educationSystems = [];
  String? _selectedChildId;
  EducationSystem? _selectedSystem;
  Track? _selectedTrack; 
  Stage? _selectedStage;
  Grade? _selectedGrade;
  
  Governorate? _selectedGovernorate;
  Administration? _selectedAdministration;

  RangeValues _feeRange = const RangeValues(0, 200000);
  String? _genderPolicy;
  String? _specialNeeds;
  String? _religion;
  LatLng? _userLocation;
  bool _isAnalyzing = false;
  bool _isStepLoading = false;
  SchoolSuggestionResponse? _aiSuggestion;
  AIAssessmentReport? _assessmentReport;
  Student? get _selectedStudent => _relatedChildren.firstWhereOrNull((s) => s.id == _selectedChildId);
  List<School> _filteredSchools = [];
  bool _isLoadingSchools = false;
  final Map<String, School> _selectedSchoolsMap = {};
  Set<String> get _selectedSchoolIds => _selectedSchoolsMap.keys.toSet();
  int _matchingSchoolsCount = 0;
  late AnimationController _aiProgressController;
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;
  double _aiProgress = 0.0;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _aiProgressController = AnimationController(vsync: this, duration: Duration(seconds: 5));
    _aiProgressController.addListener(() {
      setState(() => _aiProgress = _aiProgressController.value * 100);
    });
    _loadingController = AnimationController(vsync: this, duration: Duration(milliseconds: 1500))..repeat(reverse: true);
    _loadingAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut));
    
    _loadInitialData();
  }
 
  String _schoolSearchQuery = '';

  @override
  void dispose() {
    _aiProgressController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (mounted) setState(() => _isLoadingData = true);
    
    try {
      // 1. Fetch Lookups (Governorates, Cities, etc.)
      final lookups = await AdmissionService.getLookups();
      
      // 2. Fetch Education Systems (with nested tracks/stages/grades)
      final systems = await AdmissionService.getEducationSystems();
      
      // 3. Fetch Linked Children using StudentsService
      final childrenResponse = await StudentsService.getRelatedChildren();
      final children = childrenResponse.success ? childrenResponse.students : <Student>[];

      // Check args for pre-selected child
      final args = Get.arguments as Map<String, dynamic>?;
      if (args != null && args['child'] is Student) {
        _selectedChildId = (args['child'] as Student).id;
      }

      if (mounted) {
        setState(() {
          _lookups = lookups.data;
          _educationSystems = systems.systems;
          _relatedChildren = children;
          
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        CustomSnackbar.showError('error_loading_data'.tr);
      }
    }
  }

  void _updateMatchingCount() {
    // Just trigger a quiet fetch of schools to get the count from the filtered API
    _fetchSchools(isQuiet: true);
  }

  // --- Step Logic ---

  void _nextStep() async {
    if (_currentStep == 1) {
      if (_selectedChildId == null) {
        CustomSnackbar.showError('select_student'.tr); 
        return;
      }
      if (mounted) setState(() => _currentStep++);
    } else if (_currentStep == 2) {
       if (_selectedSystem == null) {
          CustomSnackbar.showError('select_education_system'.tr);
          return;
       }
       
       if (_selectedGovernorate == null) {
          CustomSnackbar.showError('select_governorate'.tr);
          return;
       }

       if (_selectedAdministration == null) {
          CustomSnackbar.showError('select_city'.tr);
          return;
       }
       
       if (mounted) setState(() => _isStepLoading = true);
       await Future.delayed(Duration(milliseconds: 1500));
       await _fetchSchools();
       
       if (mounted) {
         setState(() {
           _isStepLoading = false;
           _currentStep++;
         });
       }
    } else if (_currentStep == 3) {
      if (_selectedSchoolIds.isEmpty) {
        CustomSnackbar.showError('select_at_least_one_school'.tr);
        return;
      }
      if (mounted) setState(() => _currentStep++);
    } else if (_currentStep == 4) {
      // AI Assessment step - usually proceeds via onComplete
      if (mounted) setState(() => _currentStep++);
    } else if (_currentStep < _totalSteps) {
      if (mounted) setState(() => _currentStep++);
    }
  }



  double _calculateAgeInOctober(String? birthDate) {
    if (birthDate == null) return 0;
    try {
      final now = DateTime.now();
      // Target Date is Oct 1st of the current year (or next if already past)
      DateTime targetDate = DateTime(now.year, 10, 1);
      
      final birth = DateTime.parse(birthDate);
      final difference = targetDate.difference(birth).inDays;
      return difference / 365.25;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _fetchSchools({bool isQuiet = false}) async {
    if (!isQuiet && mounted) setState(() => _isLoadingSchools = true);
    try {
      final child = _relatedChildren.firstWhereOrNull((c) => c.id == _selectedChildId);
      if (child == null) {
         if (mounted) setState(() => _isLoadingSchools = false);
         return;
      }

      final request = ViewSchoolsRequest(
        child: child.toJson(),
        filters: {
          'system': _selectedSystem?.id,
          'track': _selectedTrack?.id,
          'grade': _selectedGrade?.id,
          'stage': _selectedStage?.id,
          'governorate': _selectedGovernorate?.nameAr,
          'city': _selectedAdministration?.id,
          'minFees': _feeRange.start,
          'maxFees': _feeRange.end,
          'genderPolicy': _genderPolicy, 
          'specialNeeds': _specialNeeds ?? 'none',
          'userLocation': _userLocation != null ? {
            'lat': _userLocation!.latitude,
            'lng': _userLocation!.longitude
          } : null,
        },
      );

      final schools = await AdmissionService.viewSchools(request);
      
      if (mounted) {
        setState(() {
          _filteredSchools = schools;
          _matchingSchoolsCount = schools.length;
          _isLoadingSchools = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSchools = false);
        if (!isQuiet) CustomSnackbar.showError(e.toString());
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    if (_isLoadingLocation) return;
    
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        CustomSnackbar.showError('enable_location_services'.tr);
        setState(() => _isLoadingLocation = false);
        return;
      }

      PermissionStatus status = await Permission.location.status;
      if (!status.isGranted) {
        status = await Permission.location.request();
        if (!status.isGranted) {
          CustomSnackbar.showError('location_permission_denied'.tr);
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      
      if (!mounted) return;

      // Reverse Geocoding to find Governorate
      String? matchedGovName;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
           final p = placemarks.first;
           final area = p.administrativeArea; 
           // e.g. "Cairo", "Giza"
           if (area != null && _lookups != null) {
              final match = _lookups!.locations.governorates.firstWhereOrNull((g) => 
                 g.nameEn.toLowerCase().contains(area.toLowerCase()) || 
                 g.nameAr.toLowerCase().contains(area.toLowerCase()) ||
                 area.toLowerCase().contains(g.nameEn.toLowerCase())
              );
              if (match != null) {
                 matchedGovName = Responsive.isRTL ? match.nameAr : match.nameEn;
                 setState(() {
                   _selectedGovernorate = match;
                   
                   // Try to match city/administration too
                   Administration? matchedAdmin;
                   if (_lookups!.locations.administrations.containsKey(match.id)) {
                     final possibleCities = [
                       p.locality,
                       p.subLocality,
                       p.subAdministrativeArea,
                       p.thoroughfare
                     ].whereType<String>().toList();

                     for (var city in possibleCities) {
                        if (matchedAdmin != null) break;
                        matchedAdmin = _lookups!.locations.administrations[match.id]!.firstWhereOrNull((a) =>
                           a.nameEn.toLowerCase().contains(city.toLowerCase()) ||
                           a.nameAr.toLowerCase().contains(city.toLowerCase()) ||
                           city.toLowerCase().contains(a.nameEn.toLowerCase()) ||
                           city.toLowerCase().contains(a.nameAr.toLowerCase())
                        );
                     }
                   }
                   _selectedAdministration = matchedAdmin;
                   _updateMatchingCount();
                 });
              }
           }
        }
      } catch (e) {
        print('Geocoding error: $e');
      }

      if (mounted) {
        setState(() {
          _userLocation = LatLng(pos.latitude, pos.longitude);
          _isLoadingLocation = false;
        });
        
        if (matchedGovName != null) {
           String msg = 'location_set_to'.trParams({'name': matchedGovName});
           if (_selectedAdministration != null) {
             msg += ' - ${Responsive.isRTL ? _selectedAdministration!.nameAr : _selectedAdministration!.nameEn}';
           }
           CustomSnackbar.showSuccess(msg);
        } else {
           CustomSnackbar.showSuccess('location_determined'.tr);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
        CustomSnackbar.showError('failed_to_get_location'.tr);
      }
    }
  }

  Widget _buildLocationButton() {
     return InkWell(
       onTap: _getCurrentLocation,
       borderRadius: BorderRadius.circular(16),
       child: Container(
         width: double.infinity,
         padding: EdgeInsets.symmetric(vertical: 14),
         decoration: BoxDecoration(
           color: _userLocation != null ? Colors.green[50] : Color(0xFFF9FAFB),
           borderRadius: BorderRadius.circular(16),
           border: Border.all(color: _userLocation != null ? Colors.green[200]! : Colors.grey[200]!),
         ),
         child: Row(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             if (_isLoadingLocation)
                SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue1))
             else
                Icon(IconlyBold.location, size: 18, color: _userLocation != null ? Colors.green : Colors.grey),
             
             SizedBox(width: 8.w),
             Text(
               _isLoadingLocation 
                  ? 'loading'.tr 
                  : (_userLocation != null ? 'location_determined'.tr : 'use_current_location'.tr),
               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, color: _userLocation != null ? Colors.green[700] : Colors.grey[700]),
             ),
           ],
         ),
       ),
     );
  }
  Future<void> _analyzeWithAI() async {
    final child = _relatedChildren.firstWhereOrNull((c) => c.id == _selectedChildId);
    if (child == null) return;
    
    setState(() {
      _isAnalyzing = true;
      _aiProgress = 0;
    });
    _aiProgressController.reset();
    _aiProgressController.forward();
    
    try {
      final simpleSchools = _filteredSchools.map((s) => {
        '_id': s.id, 
        'name': s.name,
        'admissionFee': {'amount': s.admissionFee?.amount ?? 0},
        'type': s.type,
      }).toList();

      final prefs = SuggestionPreferences(
        minFee: _feeRange.start,
        maxFee: _feeRange.end,
        zone: _selectedGovernorate?.nameEn,
        type: _selectedSystem?.name,
      );

      final request = SchoolSuggestionRequest(
        child: child.toJson(),
        schools: simpleSchools,
        preferences: prefs,
      );

      final response = await AdmissionService.suggestThreeSchools(request);
      
      if (_aiProgressController.isAnimating) {
        await Future.delayed(Duration(milliseconds: (5000 * (1 - _aiProgressController.value)).toInt()));
      }

      if (mounted) {
        setState(() {
          _aiSuggestion = response;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        CustomSnackbar.showError(e.toString());
      }
    }
  }

  Future<void> _submitApplication() async {
    if (_selectedChildId == null) return;
    if (mounted) setState(() => _isStepLoading = true);
    
    try {
      final child = _relatedChildren.firstWhereOrNull((c) => c.id == _selectedChildId);
      if (child == null) return;

      final selectedSchoolsList = _selectedSchoolsMap.values.map((found) {
        return SelectedSchool.fromSchool(found);
      }).toList();

      final request = ApplyToSchoolsRequest(
        childId: _selectedChildId!, 
        selectedSchools: selectedSchoolsList,
        paymentMethod: 'wallet',
        filters: {
          'system': _selectedSystem?.id ?? '',
          'track': _selectedTrack?.id ?? '',
          'stage': _selectedStage?.id ?? '',
          'grade': _selectedGrade?.id ?? '',
          'genderPolicy': _genderPolicy ?? 'Mixed',
          'governorate': _selectedGovernorate?.nameAr ?? '',
          'city': _selectedAdministration?.id ?? '',
          'minFees': _feeRange.start,
          'maxFees': _feeRange.end,
          'specialNeeds': _specialNeeds ?? 'none',
          'userLocation': _userLocation != null ? {
            'lat': _userLocation!.latitude,
            'lng': _userLocation!.longitude
          } : null,
        },
        aiAssessment: _assessmentReport,
      );

      final response = await AdmissionService.applyToSchools(request);

      if (mounted) {
        setState(() => _isStepLoading = false);
        CustomSnackbar.showSuccess(response.message);
        Get.offNamedUntil(AppRoutes.home, (route) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isStepLoading = false);
        _showApplicationErrorPrompt(e.toString());
      }
    }
  }

  void _showApplicationErrorPrompt(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
                child: Icon(Icons.error_outline, color: Colors.red, size: 40),
              ),
              SizedBox(height: 24),
              Text(
                'عذراً!', 
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.black87)
              ),
              SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 13.sp, height: 1.5),
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54.h,
                child: ElevatedButton(
                  onPressed: () => Get.offAllNamed(AppRoutes.home),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue1,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text('back_to_home'.tr, style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const LoadingPage();
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Color(0xFFFDFBF7),
          body: SafeArea(
            child: Column(
              children: [
                // Header (Stepper is inside header now)
                _buildHeader(),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: 100),
                    child: _buildCurrentStep(),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomBar(),
        ),
        
        // AI Overlay
        if (_isAnalyzing)
          _buildAIOverlay(),

        // Step Loading Overlay
        if (_isStepLoading)
          _buildStepLoadingOverlay(),
      ],
    );
  }

  Widget _buildStepLoadingOverlay() {
    return Material(
      color: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: const LoadingPage(),
      ),
    );
  }


  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
                onPressed: () {
                  if (_currentStep > 1) {
                    setState(() => _currentStep--);
                  } else {
                    Get.back();
                  }
                },
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
              Text(
                'submit_new_admission'.tr,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16.sp, color: Colors.black87),
              ),
              SizedBox(width: 20), // Balance the back button
            ],
          ),
          _buildStepper(),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    final steps = [
      {'id': 1, 'label': 'student'.tr},
      {'id': 2, 'label': 'preferences'.tr},
      {'id': 3, 'label': 'schools'.tr},
      {'id': 4, 'label': 'ai_assessment'.tr},
      {'id': 5, 'label': 'review'.tr},
    ];

    return Container(
      margin: EdgeInsets.symmetric(vertical: 20.h),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: steps.asMap().entries.map((entry) {
          int idx = entry.key;
          var step = entry.value;
          int id = step['id'] as int;
          bool isActive = id == _currentStep;
          bool isCompleted = id < _currentStep;
          bool isLast = idx == steps.length - 1;

          return Expanded(
            flex: isLast ? 0 : 1,
            child: Row(
              mainAxisSize: isLast ? MainAxisSize.min : MainAxisSize.max,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.blue1 : (isCompleted ? Colors.green : Colors.white),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isActive ? AppColors.blue1 : (isCompleted ? Colors.green : Colors.grey[300]!), 
                          width: 2
                        ),
                        boxShadow: isActive ? [BoxShadow(color: AppColors.blue1.withOpacity(0.2), blurRadius: 8, offset: Offset(0, 4))] : null,
                      ),
                      child: Center(
                        child: isCompleted 
                          ? Icon(Icons.check, color: Colors.white, size: 16)
                          : Text('${idx + 1}', style: TextStyle(color: isActive ? Colors.white : Colors.grey[500], fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      step['label'] as String,
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: isActive ? FontWeight.w900 : FontWeight.w500,
                        color: isActive ? AppColors.blue1 : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                if (!isLast)
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(bottom: 18, left: 8, right: 8),
                    height: 2,
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green : Colors.grey[200],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCurrentStep() {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 400),
      child: _getStepWidget(),
    );
  }

  Widget _getStepWidget() {
    switch (_currentStep) {
      case 1: return _buildChildSelectionStep();
      case 2: return _buildPreferencesStep();
      case 3: return _buildSchoolResultsStep();
      case 4: return _buildAIAssessmentStep();
      case 5: return _buildReviewStep();
      default: return SizedBox();
    }
  }

  // --- Step 1: Child Selection ---
  Widget _buildChildSelectionStep() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('who_is_student_applying'.tr, style: AppFonts.h3.copyWith(fontWeight: FontWeight.w900, color: Color(0xFF111827))),
          SizedBox(height: 8.h),
          Text('select_child_desc'.tr, style: TextStyle(color: Colors.grey[600], fontSize: 13.sp, fontWeight: FontWeight.w500)),
          SizedBox(height: 24.h),
          
          Center(
            child: Wrap(
              spacing: 16.w,
              runSpacing: 16.h,
              children: [
                 ..._relatedChildren.map((child) => _buildChildCard(child)).toList(),
                 _buildAddChildCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildCard(Student child) {
    String birthDateStr = '';
    try {
       final date = DateTime.parse(child.birthDate);
       birthDateStr = DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
       birthDateStr = child.birthDate;
    }

    final isSelected = _selectedChildId == child.id;

    return InkWell(
      onTap: () {
        setState(() => _selectedChildId = child.id);
        _nextStep(); // Auto advance
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 155.w,
        height: 165.w,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? AppColors.blue1 : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Container(
                width: 60.w, height: 60.w,
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(
                   gradient: LinearGradient(colors: [AppColors.blue1, Colors.blueAccent]),
                   shape: BoxShape.circle,
                ),
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: ClipOval(
                  child: Center(
                    child: Icon(IconlyBold.profile, color: AppColors.blue1, size: 30.w),
                  ),
                  ),
                ),
             ),
            SizedBox(height: 12.h),
            Text(
              child.arabicFullName ?? child.fullName, 
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.sp, color: Color(0xFF1F2937)),
              textAlign: TextAlign.center,
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(10)),
              child: Text(birthDateStr, style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 9.sp)),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAddChildCard() {
    return InkWell(
      onTap: () {
        // Navigate
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 155.w,
        height: 155.w,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
              child: Icon(Icons.add, color: Colors.grey[600], size: 28),
            ),
            SizedBox(height: 12.h),
            Text('add_new_child'.tr, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 11.sp)),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedChildInfo(Student child) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.blue1.withOpacity(0.2), width: 2)),
            child: Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Center(
                child: Icon(IconlyBold.profile, color: AppColors.blue1, size: 28),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(child.arabicFullName ?? child.fullName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: Color(0xFF111827))),
                 SizedBox(height: 4),
                 Row(
                   children: [
                     Icon(Icons.school, size: 12, color: Colors.grey[400]),
                     SizedBox(width: 4),
                     Text(child.grade.name, style: TextStyle(color: Colors.grey[600], fontSize: 11.sp, fontWeight: FontWeight.w500)),
                   ],
                 )
              ],
            ),
          )
        ],
      ),
    );
  }


  // --- Step 2: Preferences ---
  Widget _buildPreferencesStep() {
    // Sort lists alphabetically based on current language
    if (_educationSystems.isNotEmpty) {
      _educationSystems.sort((a, b) => a.name.compareTo(b.name));
    }

    if (_lookups != null) {
      _lookups!.locations.governorates.sort((a, b) => 
        Responsive.isRTL 
          ? a.nameAr.compareTo(b.nameAr) 
          : a.nameEn.compareTo(b.nameEn)
      );
      
      if (_selectedGovernorate != null && _lookups!.locations.administrations.containsKey(_selectedGovernorate!.id)) {
         _lookups!.locations.administrations[_selectedGovernorate!.id]!.sort((a, b) => 
            Responsive.isRTL 
              ? a.nameAr.compareTo(b.nameAr) 
              : a.nameEn.compareTo(b.nameEn)
         );
      }
    }

    // Prepare lists
    final tracks = _selectedSystem?.tracks ?? [];
    final stages = _selectedTrack?.stages ?? [];
    final grades = _selectedStage?.grades ?? [];
    
    final cities = (_selectedGovernorate != null && _lookups != null && _lookups!.locations.administrations.containsKey(_selectedGovernorate!.id))
        ? _lookups!.locations.administrations[_selectedGovernorate!.id]!
        : <Administration>[];

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('search_preferences'.tr, style: AppFonts.h3.copyWith(fontWeight: FontWeight.w900, color: Color(0xFF111827))),
          SizedBox(height: 8.h),
          Text('search_preferences_desc'.tr, style: TextStyle(color: Colors.grey[600], fontSize: 13.sp, fontWeight: FontWeight.w500)),
          SizedBox(height: 24.h),
          
          // 1. Education System (Plan)
          _buildPreferencesCard(
            title: 'education_system'.tr, 
            icon: Icons.book_outlined,
            color: Colors.indigo,
            children: [
              _buildDropdownSection('education_system'.tr, 
                 DropdownButtonFormField<EducationSystem>(
                   value: _selectedSystem,
                   hint: Text('select_education_system'.tr, style: TextStyle(fontSize: 13.sp)),
                   style: TextStyle(fontSize: 13.sp, color: Colors.black87),
                   items: _educationSystems.map((e) => DropdownMenuItem(value: e, child: Text(e.name, style: TextStyle(fontSize: 13.sp)))).toList(),
                   onChanged: (val) { if (mounted) setState(() { _selectedSystem = val; _selectedTrack = null; _selectedStage = null; _selectedGrade = null; _updateMatchingCount(); }); },
                   decoration: _inputDeco(),
                   borderRadius: BorderRadius.circular(12),
                   elevation: 8,
                   menuMaxHeight: 400,
                   icon: Icon(IconlyLight.arrow_down_2, size: 18),
                 )
              ),
              _buildDropdownSection('track'.tr, 
                DropdownButtonFormField<Track>(
                  key: ValueKey('track_${_selectedSystem?.id}'),
                  value: _selectedTrack,
                  hint: Text(tracks.isEmpty ? 'no_tracks_available'.tr : 'select_track'.tr, style: TextStyle(fontSize: 13.sp)),
                  style: TextStyle(fontSize: 13.sp, color: Colors.black87),
                  items: tracks.map((e) => DropdownMenuItem(value: e, child: Text(e.name, style: TextStyle(fontSize: 13.sp)))).toList(),
                   onChanged: tracks.isEmpty ? null : (val) { if (mounted) setState(() { _selectedTrack = val; _selectedStage = null; _selectedGrade = null; _updateMatchingCount(); }); },
                  decoration: _inputDeco(),
                  borderRadius: BorderRadius.circular(12),
                  elevation: 8,
                  menuMaxHeight: 400,
                  icon: Icon(IconlyLight.arrow_down_2, size: 18),
                )
              ),
              _buildDropdownSection('stage'.tr, 
                DropdownButtonFormField<Stage>(
                  key: ValueKey('stage_${_selectedSystem?.id}'),
                  value: _selectedStage,
                  style: TextStyle(fontSize: 13.sp, color: Colors.black87),
                  hint: Text(stages.isEmpty ? 'no_stages_available'.tr : 'select_stage'.tr, style: TextStyle(fontSize: 13.sp)),
                  items: stages.map((e) => DropdownMenuItem(value: e, child: Text(e.name, style: TextStyle(fontSize: 13.sp)))).toList(),
                   onChanged: stages.isEmpty ? null : (val) { if (mounted) setState(() { _selectedStage = val; _selectedGrade = null; _updateMatchingCount(); }); },
                  decoration: _inputDeco(),
                  borderRadius: BorderRadius.circular(12),
                  elevation: 8,
                  menuMaxHeight: 400,
                  icon: Icon(IconlyLight.arrow_down_2, size: 18),
                )
              ),
              _buildDropdownSection('grade'.tr, 
                DropdownButtonFormField<Grade>(
                  key: ValueKey('grade_${_selectedStage?.id}'),
                  value: _selectedGrade,
                  style: TextStyle(fontSize: 13.sp, color: Colors.black87),
                  hint: Text(grades.isEmpty ? 'select_stage_first'.tr : 'select_grade'.tr, style: TextStyle(fontSize: 13.sp)),
                  items: grades.map((e) => DropdownMenuItem(value: e, child: Text(e.name, style: TextStyle(fontSize: 13.sp)))).toList(),
                   onChanged: grades.isEmpty ? null : (val) { if (mounted) setState(() { _selectedGrade = val; _updateMatchingCount(); }); },
                  decoration: _inputDeco(),
                  borderRadius: BorderRadius.circular(12),
                  elevation: 8,
                  menuMaxHeight: 400,
                  icon: Icon(IconlyLight.arrow_down_2, size: 18),
                )
              ),
            ],
          ),

          // 2. Location Section
          _buildPreferencesCard(
            title: 'location'.tr, 
            icon: Icons.location_on_outlined,
            color: Colors.pinkAccent,
            children: [
              _buildLocationButton(),
              SizedBox(height: 16.h),
              if (_lookups != null) ...[
                _buildDropdownSection('governorate'.tr,
                   DropdownButtonFormField<Governorate>(
                     value: _selectedGovernorate,
                     hint: Text('select_governorate'.tr, style: TextStyle(fontSize: 13.sp)),
                     items: _lookups!.locations.governorates.map((e) => DropdownMenuItem(value: e, child: Text(Responsive.isRTL ? e.nameAr : e.nameEn, style: TextStyle(fontSize: 13.sp)))).toList(),
                     onChanged: (v) { if (mounted) setState(() { _selectedGovernorate = v; _selectedAdministration = null; _updateMatchingCount(); }); },
                     decoration: _inputDeco(),
                     borderRadius: BorderRadius.circular(12),
                     menuMaxHeight: 400,
                   )
                ),
                _buildDropdownSection('select_city'.tr,
                     DropdownButtonFormField<Administration>(
                       key: ValueKey('city_${_selectedGovernorate?.id}'),
                       value: _selectedAdministration,
                       hint: Text(cities.isEmpty ? 'select_gov_first'.tr : 'select_city'.tr, style: TextStyle(fontSize: 13.sp)),
                       items: cities.map((e) => DropdownMenuItem(value: e, child: Text(Responsive.isRTL ? e.nameAr : e.nameEn, style: TextStyle(fontSize: 13.sp)))).toList(),
                       onChanged: cities.isEmpty ? null : (v) { if (mounted) setState(() { _selectedAdministration = v; _updateMatchingCount(); }); },
                       decoration: _inputDeco(),
                       borderRadius: BorderRadius.circular(12),
                       menuMaxHeight: 400,
                     )
                  ),
              ],
            ],
          ),

          // 3. Financials
          _buildPreferencesCard(
            title: 'fees_range'.tr,
            icon: Icons.monetization_on_outlined,
            color: Colors.green,
            children: [
              RangeSlider(
                values: _feeRange,
                min: 0, max: 500000,
                divisions: 100,
                activeColor: Colors.green,
                inactiveColor: Colors.green.withOpacity(0.1),
                labels: RangeLabels('${_feeRange.start.round()} ${'currency'.tr}', '${_feeRange.end.round()} ${'currency'.tr}'),
                onChanged: (v) => setState(() { _feeRange = v; _updateMatchingCount(); }),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_feeRange.start.toInt().toLocaleString()} ${'currency'.tr}', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 12.sp)),
                  Text('${_feeRange.end.toInt().toLocaleString()} ${'currency'.tr}', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 12.sp)),
                ],
              ),
            ],
          ),

          // 4. Policies (Gender & Special Needs)
          _buildPreferencesCard(
            title: 'admission_policies'.tr,
            icon: Icons.people_outline,
            color: Colors.blue,
            children: [
              _buildChoiceSection(
                label: 'gender_policy'.tr,
                choices: [
                  {'id': 'Mixed', 'label': 'mixed'.tr},
                  {'id': 'Boys', 'label': 'boys'.tr},
                  {'id': 'Girls', 'label': 'girls'.tr},
                ],
                selectedId: _genderPolicy,
                onSelected: (id) => setState(() { _genderPolicy = id; _updateMatchingCount(); }),
              ),
              SizedBox(height: 20.h),
              _buildChoiceSection(
                label: 'special_needs'.tr,
                choices: [
                  {'id': 'none', 'label': 'none'.tr},
                  {'id': 'adhd', 'label': 'adhd'.tr},
                  {'id': 'autism', 'label': 'autism'.tr},
                  {'id': 'down', 'label': 'down_syndrome'.tr},
                ],
                selectedId: _specialNeeds,
                onSelected: (id) => setState(() { _specialNeeds = id; _updateMatchingCount(); }),
              ),
              SizedBox(height: 20.h),
              _buildChoiceSection(
                label: 'religion'.tr,
                choices: [
                  {'id': 'None', 'label': 'general_unspecified'.tr},
                  {'id': 'Muslim', 'label': 'muslim'.tr},
                  {'id': 'Christian', 'label': 'christian'.tr},
                ],
                selectedId: _religion,
                onSelected: (id) => setState(() { _religion = id; _updateMatchingCount(); }),
              ),
            ],
          ),
          
          _buildMatchingSchoolsBadge(),
          SizedBox(height: 100.h), // Space for bottom bar
        ],
      ),
    );
  }

  Widget _buildPreferencesCard({required String title, required IconData icon, required Color color, required List<Widget> children}) {
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: 12.w),
              Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.sp, color: Color(0xFF1F2937))),
            ],
          ),
          SizedBox(height: 20.h),
          ...children,
        ],
      ),
    );
  }



  Widget _buildChoiceSection({required String label, required List<Map<String, String>> choices, required String? selectedId, required Function(String?) onSelected}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.grey[800])),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: choices.map((c) {
            final isSelected = selectedId == c['id'];
            return InkWell(
              onTap: () {
                if (isSelected) {
                   onSelected(null); // Unselect if already selected
                } else {
                   onSelected(c['id']!);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.blue1 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? AppColors.blue1 : Colors.grey[300]!, width: isSelected ? 2 : 1),
                  boxShadow: isSelected ? [BoxShadow(color: AppColors.blue1.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 4))] : null,
                ),
                child: Text(
                  c['label']!,
                  style: TextStyle(color: isSelected ? Colors.white : Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 13.sp),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  Widget _buildDropdownSection(String label, Widget field) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14.sp, color: Colors.grey[800], fontWeight: FontWeight.w700)),
          SizedBox(height: 10.h),
          SizedBox(
            height: 52.h, // Bigger size
            child: field
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey[50], // Slightly off-white for depth
      hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey[400]),
      contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[200]!), 
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.blue1, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red[300]!),
      ),
    );
  }

  // --- Step 3: School Results ---
  Widget _buildSchoolResultsStep() {
    if (_isLoadingSchools) return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('searching_schools'.tr, style: TextStyle(color: Colors.grey)),
      ],
    ));

    final child = _relatedChildren.firstWhereOrNull((c) => c.id == _selectedChildId);
    final suggestedIds = _aiSuggestion?.suggestedIds ?? [];
    List<School> displayList = _filteredSchools.where((s) => 
      s.name.toLowerCase().contains(_schoolSearchQuery.toLowerCase())
    ).toList();
    
    // Sort so suggested are first if any
    if (suggestedIds.isNotEmpty) {
      displayList.sort((a,b) {
         final aSug = suggestedIds.contains(a.id) ? 1 : 0;
         final bSug = suggestedIds.contains(b.id) ? 1 : 0;
         return bSug.compareTo(aSug);
      });
    }

    return SingleChildScrollView(
       child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               if (child != null) ...[
                 _buildApplicantHeader(child),
                 SizedBox(height: 24.h),
               ],

               // Search & Suggest Bar
               Container(
                 padding: EdgeInsets.all(12),
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(24),
                   border: Border.all(color: Colors.grey[200]!),
                   boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: Offset(0, 8))],
                 ),
                 child: Column(
                   children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          onChanged: (v) { if (mounted) setState(() => _schoolSearchQuery = v); },
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
                          decoration: InputDecoration(
                            hintText: 'search_school_name'.tr,
                            hintStyle: TextStyle(fontSize: 12.sp, color: Colors.grey[400]),
                            prefixIcon: Icon(IconlyLight.search, color: Colors.grey, size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _isAnalyzing ? null : _analyzeWithAI,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                height: 50.h,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(color: Color(0xFF4F46E5).withOpacity(0.2), blurRadius: 10, offset: Offset(0, 4))
                                  ],
                                ),
                                child: Center(
                                  child: _isAnalyzing
                                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                                          SizedBox(width: 8),
                                          Text('get_derasay_opinion'.tr, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13.sp)),
                                        ],
                                      ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Container(
                            height: 50.h,
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.indigo[50],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                '${displayList.length} ${'schools'.tr}',
                                style: TextStyle(color: Colors.indigo[700], fontWeight: FontWeight.w900, fontSize: 12.sp),
                              ),
                            ),
                          ),
                        ],
                      ),
                   ],
                 ),
               ),
               
               SizedBox(height: 24.h),

               // List
               if (displayList.isEmpty)
                 Center(child: Padding(
                   padding: const EdgeInsets.all(40.0),
                   child: Column(
                     children: [
                       Icon(IconlyLight.info_square, size: 60, color: Colors.grey[300]),
                       SizedBox(height: 16),
                       Text('no_schools_found'.tr, style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold)),
                     ],
                   ),
                 ))
                else
                  ListView.builder(
                     shrinkWrap: true,
                     physics: NeverScrollableScrollPhysics(),
                     itemCount: displayList.length,
                     itemBuilder: (context, index) {
                       final school = displayList[index];
                       final isSuggested = suggestedIds.contains(school.id);
                       final suggestion = isSuggested ? _aiSuggestion?.suggestions.firstWhereOrNull((s) => s.id == school.id) : null;
                       
                       return Padding(
                         padding: EdgeInsets.only(bottom: 20.h),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             _buildSchoolCard(school, isSuggested),
                             if (suggestion?.reason != null) ...[
                               SizedBox(height: 12.h),
                               Container(
                                 width: double.infinity,
                                 margin: EdgeInsets.symmetric(horizontal: 12.w),
                                 padding: EdgeInsets.all(16),
                                 decoration: BoxDecoration(
                                   color: Colors.indigo[50]!.withOpacity(0.6),
                                   borderRadius: BorderRadius.only(
                                     bottomLeft: Radius.circular(24),
                                     bottomRight: Radius.circular(24),
                                     topLeft: Radius.circular(4),
                                     topRight: Radius.circular(4),
                                   ),
                                   border: Border.all(color: Colors.indigo[200]!.withOpacity(0.5)),
                                 ),
                                 child: Row(
                                   children: [
                                     Container(
                                       padding: EdgeInsets.all(8),
                                       decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                       child: Icon(Icons.auto_awesome, color: Colors.indigo, size: 16),
                                     ),
                                     SizedBox(width: 12.w),
                                     Expanded(
                                       child: Column(
                                         crossAxisAlignment: CrossAxisAlignment.start,
                                         children: [
                                           Text('ai_recommendation'.tr, style: TextStyle(fontWeight: FontWeight.w900, color: Colors.indigo[800], fontSize: 11.sp)),
                                           SizedBox(height: 4),
                                           Text(
                                             suggestion!.reason,
                                             style: TextStyle(fontSize: 12.sp, color: Colors.indigo[700], fontWeight: FontWeight.w500, height: 1.4),
                                           ),
                                         ],
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                             ],
                           ],
                         ),
                       );
                     },
                  ),
                 
               SizedBox(height: 100.h),
            ],
          ),
       ),
    );
  }

  Widget _buildApplicantHeader(Student child) {
    final age = _calculateAgeInOctober(child.birthDate);
    final isTransfer = child.schoolId.id.isNotEmpty || child.studentStatus.isEnrolled;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: Offset(0, 8))],
      ),
      child: Stack(
        children: [
          Positioned(
            left: -20, top: -20,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: Colors.indigo[50]!.withOpacity(0.4), shape: BoxShape.circle),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  // Profile Image
                  Container(
                    width: 70.w, height: 70.w,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: (child.avatar ?? '').isNotEmpty 
                        ? SafeNetworkImage(imageUrl: child.avatar!, fit: BoxFit.cover)
                        : Center(child: Icon(IconlyBold.profile, color: Colors.indigo[200], size: 30)),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(
                           child.arabicFullName ?? child.fullName,
                           style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18.sp, color: Color(0xFF111827), letterSpacing: -0.5),
                         ),
                         SizedBox(height: 6),
                         Row(
                           children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, color: Color(0xFF10B981), size: 12),
                                    SizedBox(width: 4),
                                    Text(
                                      child.nationalId.isNotEmpty ? '${child.nationalId.substring(0, 4)}... (موثق)' : 'no_national_id'.tr,
                                      style: TextStyle(fontSize: 10.sp, color: Colors.grey[500], fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isTransfer ? Colors.amber[50] : Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isTransfer ? Colors.amber[100]! : Color(0xFFD1FAE5)),
                                ),
                                child: Text(
                                  isTransfer ? 'transfer_request'.tr : 'new_admission'.tr,
                                  style: TextStyle(fontSize: 10.sp, color: isTransfer ? Colors.amber[800] : Color(0xFF047857), fontWeight: FontWeight.w900),
                                ),
                              ),
                           ],
                         )
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  _headerStatCard(
                    label: 'estimated_age'.tr,
                    value: age.toStringAsFixed(1),
                    unit: 'years'.tr,
                    color: Color(0xFF111827),
                  ),
                  SizedBox(width: 12.w),
                  _headerStatCard(
                    label: 'target_grade'.tr,
                    value: _selectedGrade?.name ?? child.grade.name,
                    unit: '',
                    color: Color(0xFF111827),
                    isHighlight: true,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStatCard({required String label, required String value, required String unit, required Color color, bool isHighlight = false}) {
    return Expanded(
      child: Container(
        height: 75.h,
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 8.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: isHighlight ? Color(0xFF818CF8) : Colors.white, fontSize: isHighlight ? 12.sp : 18.sp, fontWeight: FontWeight.w900),
            ),
            if (unit.isNotEmpty)
              Text(unit, style: TextStyle(color: Color(0xFF818CF8), fontSize: 8.sp, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolCard(School school, bool isSuggested) {
    final isSelected = _selectedSchoolIds.contains(school.id);
    final suggestion = isSuggested ? _aiSuggestion?.suggestions.firstWhereOrNull((s) => s.id == school.id) : null;
    final suggestScore = suggestion?.score;

    return InkWell(
      onTap: () {
        if (mounted) {
          setState(() {
            if (isSelected) {
              _selectedSchoolsMap.remove(school.id);
            } else {
              if (_selectedSchoolIds.length >= 3) {
                 CustomSnackbar.showError('max_schools_limit'.tr);
                 return;
              }
              _selectedSchoolsMap[school.id] = school;
            }
          });
        }
      },
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFF5F3FF) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.blue1 : Colors.grey[100]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                ? AppColors.blue1.withOpacity(0.12) 
                : Colors.black.withOpacity(0.04),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Hero(
                  tag: 'school_img_${school.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SafeSchoolImage(
                      imageUrl: school.bannerImage,
                      width: 100.w,
                      height: 100.w,
                      fit: BoxFit.cover,
                      fallbackAsset: AssetsManager.login,
                      placeholder: Container(
                        color: Colors.grey[50], 
                        child: Icon(Icons.school_rounded, color: Colors.grey[200], size: 40)
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                // Data
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                       Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (isSuggested) 
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA855F7)]),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [BoxShadow(color: Color(0xFF6366F1).withOpacity(0.2), blurRadius: 4)],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome, color: Colors.white, size: 10),
                                  SizedBox(width: 4),
                                  Text(
                                    suggestScore != null ? '${'ai_match'.tr} $suggestScore%' : 'ai_best_match'.tr, 
                                    style: TextStyle(color: Colors.white, fontSize: 8.sp, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                                  ),
                                ],
                              ),
                            ),
                          if (isSelected)
                             Container(
                               padding: EdgeInsets.all(4),
                               decoration: BoxDecoration(color: AppColors.blue1, shape: BoxShape.circle),
                               child: Icon(Icons.check, color: Colors.white, size: 12),
                             ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                         school.name, 
                         maxLines: 1, overflow: TextOverflow.ellipsis,
                         style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.sp, color: Color(0xFF111827), letterSpacing: -0.3)
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(IconlyLight.location, size: 10, color: Colors.grey[400]),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              '${school.location?.city ?? ''}, ${school.location?.governorate ?? ''}',
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 9.sp, color: Colors.grey[500], fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      // Info Row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                             if (school.type != null) 
                               _miniBadge(school.type!, isIndigo: true),
                             SizedBox(width: 6),
                             _miniBadge(school.gender ?? 'mixed'.tr, isGender: true),
                            
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Expanded details row
            if (school.educationSystem != null || school.religionType != null || school.mainTeachingLanguage != null) ...[
              Divider(height: 32, color: Colors.grey[100]),
              Row(
                children: [
                  if (school.educationSystem != null) 
                    _detailItem(Icons.book_outlined, school.educationSystem!),
                  if (school.religionType != null) 
                    _detailItem(Icons.mosque_outlined, school.religionType!),
                  if (school.mainTeachingLanguage != null)
                    _detailItem(Icons.translate, school.mainTeachingLanguage!),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailItem(IconData icon, String text) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[400]),
          SizedBox(width: 4),
          Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.sp, color: Colors.grey[600], fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _miniBadge(String text, {bool isIndigo = false, bool isPrice = false, bool isGender = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPrice ? Color(0xFFECFDF5) : (isGender ? Colors.orange[50] : (isIndigo ? Colors.indigo[50] : Color(0xFFF3F4F6))), 
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPrice ? Color(0xFFD1FAE5) : (isGender ? Colors.orange[100]! : (isIndigo ? Colors.indigo[100]! : Colors.transparent)), 
          width: 0.5
        ),
      ),
      child: Text(
        text, 
        style: TextStyle(
          fontSize: 9.sp, 
          fontWeight: FontWeight.w800, 
          color: isPrice ? Color(0xFF047857) : (isGender ? Colors.orange[700] : (isIndigo ? Colors.indigo[700] : Color(0xFF4B5563))),
        ),
      ),
    );
  }



  Widget _buildReviewStep() {
    final selectedSchools = _selectedSchoolsMap.values.toList();
    
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          SizedBox(height: 10),
          _buildSelectedChildInfo(_relatedChildren.firstWhere((c) => c.id == _selectedChildId!)),
          SizedBox(height: 24.h),
          
          Align(
            alignment: Responsive.isRTL ? Alignment.centerRight : Alignment.centerLeft,
            child: Text('selected_schools'.trParams({'n': '${selectedSchools.length}'}), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16.sp, color: Color(0xFF111827))),
          ),
          SizedBox(height: 16.h),
          
          if (selectedSchools.isEmpty)
             Center(child: Padding(
               padding: const EdgeInsets.symmetric(vertical: 20),
               child: Text('no_schools_selected'.tr, style: TextStyle(color: Colors.grey)),
             )),

          // Selected List - Small modern items
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: selectedSchools.length,
            separatorBuilder: (_,__) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final school = selectedSchools[index];
              return Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(16),
                   border: Border.all(color: Colors.grey[200]!),
                   boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SafeSchoolImage(
                        imageUrl: school.bannerImage, 
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover, 
                        fallbackAsset: AssetsManager.login,
                        placeholder: Icon(Icons.school, size: 20, color: Colors.grey[400])
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(school.name, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937), fontSize: 12.sp)),
                        Text('${school.admissionFee?.amount.toInt() ?? 0} ${'currency'.tr}', style: TextStyle(color: AppColors.blue1, fontWeight: FontWeight.bold, fontSize: 10.sp)),
                      ],
                    )),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red[300], size: 18),
                      onPressed: () => setState(() => _selectedSchoolsMap.remove(school.id)),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        padding: EdgeInsets.zero,
                        minimumSize: Size(32, 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          SizedBox(height: 24.h),
          // Notice
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(16)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.orange[800], size: 20),
                SizedBox(width: 10),
                Expanded(child: Text('non_refundable_notice'.tr, style: TextStyle(color: Colors.orange[900], fontSize: 10.sp, height: 1.4))),
              ],
            ),
          ),
          SizedBox(height: 100.h),
        ],
      ),
    );
  }

  Widget _buildMatchingSchoolsBadge() {
    return Container(
      margin: EdgeInsets.only(top: 20.h),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.blue1.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue1.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(IconlyBold.search, color: AppColors.blue1, size: 20),
          SizedBox(width: 12),
          Text(
            'found_matching_schools'.trParams({'count': _matchingSchoolsCount.toString()}),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.blue1,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }



  // --- Overlays ---
  
  Widget _buildAIOverlay() {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: Color(0xFF1E1B4B).withOpacity(0.3)), // Deep indigo tint
            ),
          ),
          Center(
            child: Container(
              width: 320.w,
              margin: EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 40,
                    offset: Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Premium Gradient Header
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF9333EA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 70.w,
                          height: 70.w,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Center(
                            child: AnimatedBuilder(
                              animation: _loadingAnimation,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _loadingAnimation.value * 2 * 3.14,
                                  child: Icon(IconlyBold.discovery, color: Colors.white, size: 32.sp),
                                );
                              }
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          'ai_analyzing'.tr,
                          style: TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.w900, 
                            fontSize: 18.sp,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
                    child: Column(
                      children: [
                        Text(
                          'ai_analyzing_desc'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            height: 1.5,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 32.h),
                        
                        // Sleek Progress Bar
                        Stack(
                          children: [
                            Container(
                              height: 8.h,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            AnimatedContainer(
                              duration: Duration(milliseconds: 500),
                              height: 8.h,
                              width: 272.w * (_aiProgress / 100),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF4F46E5), Color(0xFF9333EA)],
                                ),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF4F46E5).withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 32.h),
                        
                        // Status List
                        _buildAiStatusItem(
                          'analyzing_profile'.tr,
                          _aiProgress > 20,
                          _aiProgress > 0 && _aiProgress <= 20,
                        ),
                        _buildAiStatusItem(
                          'searching_schools'.tr,
                          _aiProgress > 50,
                          _aiProgress > 20 && _aiProgress <= 50,
                        ),
                        _buildAiStatusItem(
                          'generating_recommendations'.tr,
                          _aiProgress > 80,
                          _aiProgress > 50 && _aiProgress <= 80,
                        ),
                      ],
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

  Widget _buildAiStatusItem(String text, bool completed, bool isCurrent) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: completed ? Colors.green[50] : (isCurrent ? Color(0xFF4F46E5).withOpacity(0.1) : Colors.grey[50]),
            ),
            child: Center(
              child: isCurrent 
                ? SizedBox(width: 14.w, height: 14.w, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)))
                : Icon(
                    completed ? Icons.check_rounded : Icons.circle_outlined,
                    color: completed ? Colors.green : Colors.grey[300],
                    size: 16.sp,
                  ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: completed || isCurrent ? Colors.black87 : Colors.grey[400],
                fontWeight: completed || isCurrent ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13.sp,
              ),
            ),
          ),
          if (completed)
            Text(
              'DONE',
              style: TextStyle(
                color: Colors.green,
                fontSize: 10.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
        ],
      ),
    );
  }




  // --- Bottom Bar ---
  Widget _buildBottomBar() {
    if (_isAnalyzing) return SizedBox();
    
    // Hide bottom bar on step 1 since we select by clicking card
    if (_currentStep == 1) return SizedBox();

    String label = 'next'.tr;
    VoidCallback? onTap = _nextStep;

    if (_currentStep == 4) {
      label = _assessmentReport != null ? 'confirm_results'.tr : 'skip_interview'.tr;
      onTap = _nextStep;
    } else if (_currentStep == 5) {
      label = 'submit_application'.tr;
      onTap = _submitApplication;
    }

    return Container(
      padding: EdgeInsets.only(top: 16, bottom: 24, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: Offset(0, -5))],
        border: Border(top: BorderSide(color: Colors.grey[50]!)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Back button removed as requested
            Expanded(
              child: SizedBox(
                height: 44.h,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue1,
                    elevation: 0,
                    shadowColor: AppColors.blue1.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(label, style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                      // No arrows as requested
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildAIAssessmentStep() {
    return _AIAssessmentStepView(
      child: _relatedChildren.firstWhere((c) => c.id == _selectedChildId!),
      onComplete: (report) {
        if (mounted) {
          setState(() {
            _assessmentReport = report;
            _currentStep++;
          });
        }
      },
      onSkip: () {
        if (mounted) setState(() => _currentStep++);
      },
      onBack: () {
        if (mounted) setState(() => _currentStep--);
      },
    );
  } 
}

class _AIAssessmentStepView extends StatefulWidget {
  final Student child;
  final Function(AIAssessmentReport) onComplete;
  final VoidCallback onSkip;
  final VoidCallback onBack; 
 
  const _AIAssessmentStepView({
    required this.child,
    required this.onComplete,
    required this.onSkip,
    required this.onBack,
  });

  @override
  State<_AIAssessmentStepView> createState() => _AIAssessmentStepViewState();
}

class _AIAssessmentStepViewState extends State<_AIAssessmentStepView> {
  bool _isAnalyzing = false;
  AIAssessmentReport? _report;
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startInterview();
  }

  void _startInterview() {
    setState(() {
      _messages.add({
        'role': 'ai',
        'content': 'ahlan_ya'.trParams({'name': widget.child.fullName}) + ' ' + 'ai_interview_start'.tr,
      });
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isAnalyzing = true;
    });

    try {
      final response = await AdmissionService.performAIAssessment(
        AIAssessmentRequest(
          message: text,
          context: {
            'studentName': widget.child.fullName,
          },
          history: _messages,
        ),
      );

      if (mounted) {
        setState(() {
          if (response.reply != null) {
            _messages.add({'role': 'ai', 'content': response.reply!});
          }
          if (response.assessment != null) {
            _report = response.assessment;
          }
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        CustomSnackbar.showError('ai_failed'.tr);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('ai_interview_title'.tr, style: AppFonts.h2.copyWith(fontWeight: FontWeight.w900)),
                   Text('ai_interview_subtitle'.tr, style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
                ],
              ),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(16)),
                child: Icon(IconlyBold.discovery, color: Colors.white),
              )
            ],
          ),
          SizedBox(height: 24.h),
          
          if (_report != null)
             _buildReportCard()
          else
             _buildChatView(),
          
          if (_report == null)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h),
            child: Row(
               children: [
                 Expanded(
                   child: TextField(
                     controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'type_your_answer'.tr,
                        hintStyle: TextStyle(fontSize: 11.sp, color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                     onSubmitted: (v) {
                       _sendMessage(v);
                       _textController.clear();
                     },
                   ),
                 ),
                 SizedBox(width: 12),
                 CircleAvatar(
                   backgroundColor: AppColors.blue1,
                   child: IconButton(
                     icon: Icon(Icons.send, color: Colors.white, size: 20),
                     onPressed: () {
                       _sendMessage(_textController.text);
                       _textController.clear();
                     },
                   ),
                 )
               ],
            ),
          ),

          if (_report != null)
          Padding(
            padding: EdgeInsets.only(top: 20.h),
            child: ElevatedButton(
              onPressed: () => widget.onComplete(_report!),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue1,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('confirm_and_continue'.tr, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),

          TextButton(
            onPressed: widget.onSkip,
            child: Text('skip_interview'.tr, style: TextStyle(color: Colors.grey)),
          ),
          SizedBox(height: 100.h),
        ],
      ),
    ); 
  }

  Widget _buildChatView() {
    return Container(
      height: 350.h,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: ListView.builder( 
        itemCount: _messages.length + (_isAnalyzing ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _messages.length) {
             return _buildTypingIndicator();
          }
          final msg = _messages[index];
          final isAi = msg['role'] == 'ai';
          return Align(
            alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 4),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isAi ? Colors.grey[100] : AppColors.blue1,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: isAi ? Radius.zero : Radius.circular(16),
                  bottomRight: isAi ? Radius.circular(16) : Radius.zero,
                ),
              ),
              child: Text(
                msg['content'],
                style: TextStyle(color: isAi ? Colors.black87 : Colors.white, fontSize: 13.sp),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
        child: Text('ai_typing'.tr, style: TextStyle(color: Colors.grey, fontSize: 11.sp)),
      ),
    );
  }

  Widget _buildReportCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.indigo[900]!, Colors.indigo[800]!]),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                child: Icon(Icons.bolt, color: Colors.amber, size: 30),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('assessment_completed'.tr, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18.sp)),
                    Text('ai_summary_available'.tr, style: TextStyle(color: Colors.indigo[100], fontSize: 12.sp)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Text(
            _report!.report,
            style: TextStyle(color: Colors.white, fontSize: 14.sp, height: 1.5),
          ),
          SizedBox(height: 24.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('confidence_score'.tr, style: TextStyle(color: Colors.indigo[100], fontWeight: FontWeight.bold)),
                Text('${_report!.score}%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24.sp)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
