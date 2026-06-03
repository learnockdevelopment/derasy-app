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
import '../../core/controllers/app_config_controller.dart';

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
  final int _totalSteps = 4;
  final ScrollController _scrollController = ScrollController();
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
      // Fetch concurrently to save loading time
      final results = await Future.wait([
        AdmissionService.getLookups(),
        AdmissionService.getEducationSystems(),
        StudentsService.getRelatedChildren(),
      ]);

      final lookups = results[0] as LookupsResponse;
      final systems = results[1] as EducationSystemsResponse;
      final childrenResponse = results[2] as StudentsResponse;
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

  bool _hasFetchedSchools = false;

  void _updateMatchingCount() {
    setState(() {
      _hasFetchedSchools = false;
      _matchingSchoolsCount = 0;
    });
  }

  void _nextStep() async {
    if (_currentStep == 1) {
      if (_selectedChildId == null) {
        CustomSnackbar.showError('select_student'.tr); 
        return;
      }
      if (mounted) {
        setState(() => _currentStep++);
        _scrollController.jumpTo(0.0);
      }
    } else if (_currentStep == 2) {
       if (_selectedSystem == null) {
          CustomSnackbar.showError('select_education_system'.tr);
          return;
       }
       if (!_hasFetchedSchools || _matchingSchoolsCount == 0) {
          CustomSnackbar.showError('get_schools_first'.tr);
          return;
       }
       
       if (mounted) {
         setState(() {
            _currentStep++;
         });
         _scrollController.jumpTo(0.0);
       }
    } else if (_currentStep == 3) {
      if (_selectedSchoolIds.isEmpty) {
        CustomSnackbar.showError('select_at_least_one_school'.tr);
        return;
      }
      if (mounted) {
        setState(() => _currentStep++);
        _scrollController.jumpTo(0.0);
      }
    } else if (_currentStep < _totalSteps) {
      if (mounted) {
        setState(() => _currentStep++);
        _scrollController.jumpTo(0.0);
      }
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
        child: child.id,
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
          _hasFetchedSchools = true;
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
           final rawArea = p.administrativeArea ?? '';
           final rawLocality = p.locality ?? '';
           final rawSubAdmin = p.subAdministrativeArea ?? '';
           
           print('📍 [LOCATION] Raw data -> adminArea: "$rawArea", locality: "$rawLocality", subAdmin: "$rawSubAdmin", country: "${p.country}"');
           
           // Normalize: strip common prefixes/suffixes from the geocoded area
           String normalizeEn(String s) => s.toLowerCase().replaceAll(RegExp(r'governorate|muhafazat|province|al |el |-|_'), '').trim();
           String normalizeAr(String s) => s.replaceAll(RegExp(r'محافظة |محافظه |ال|-|_'), '').trim();
           
           final String areaNormEn = normalizeEn(rawArea);
           final String areaNormAr = normalizeAr(rawArea);
           
           // Also try locality as fallback search term
           final String localityNormEn = normalizeEn(rawLocality);
           final String localityNormAr = normalizeAr(rawLocality);
           
           if (_lookups != null && _lookups!.locations.governorates.isNotEmpty) {
               // Phase 1: Exact match on normalized names (non-empty only)
               var match = _lookups!.locations.governorates.firstWhereOrNull((g) {
                  final en = normalizeEn(g.nameEn);
                  final ar = normalizeAr(g.nameAr);
                  if (en.isEmpty && ar.isEmpty) return false;
                  return (en.isNotEmpty && en == areaNormEn) || 
                         (ar.isNotEmpty && ar == areaNormAr) || 
                         (ar.isNotEmpty && ar == areaNormEn) || 
                         (en.isNotEmpty && en == areaNormAr);
               });
               
               // Phase 2: Contains match (non-empty only)
               match ??= _lookups!.locations.governorates.firstWhereOrNull((g) {
                  final en = normalizeEn(g.nameEn);
                  final ar = normalizeAr(g.nameAr);
                  if (en.isEmpty && ar.isEmpty) return false;
                  return (areaNormEn.isNotEmpty && en.isNotEmpty && (en.contains(areaNormEn) || areaNormEn.contains(en))) ||
                         (areaNormAr.isNotEmpty && ar.isNotEmpty && (ar.contains(areaNormAr) || areaNormAr.contains(ar))) ||
                         (en.isNotEmpty && rawArea.toLowerCase().contains(en)) || 
                         (ar.isNotEmpty && rawArea.contains(ar));
               });
               
               // Phase 3: Try matching by locality name
               match ??= _lookups!.locations.governorates.firstWhereOrNull((g) {
                  final en = normalizeEn(g.nameEn);
                  final ar = normalizeAr(g.nameAr);
                  if (en.isEmpty && ar.isEmpty) return false;
                  return (localityNormEn.isNotEmpty && en.isNotEmpty && (en.contains(localityNormEn) || localityNormEn.contains(en))) ||
                         (localityNormAr.isNotEmpty && ar.isNotEmpty && (ar.contains(localityNormAr) || localityNormAr.contains(ar)));
               });
               
               // Phase 4: Try matching by subAdministrativeArea
               if (match == null && rawSubAdmin.isNotEmpty) {
                 final subNormEn = normalizeEn(rawSubAdmin);
                 final subNormAr = normalizeAr(rawSubAdmin);
                 match = _lookups!.locations.governorates.firstWhereOrNull((g) {
                   final en = normalizeEn(g.nameEn);
                   final ar = normalizeAr(g.nameAr);
                   if (en.isEmpty && ar.isEmpty) return false;
                   return (en.isNotEmpty && en == subNormEn) || 
                          (ar.isNotEmpty && ar == subNormAr) || 
                          (subNormEn.isNotEmpty && en.isNotEmpty && (en.contains(subNormEn) || subNormEn.contains(en))) ||
                          (subNormAr.isNotEmpty && ar.isNotEmpty && (ar.contains(subNormAr) || subNormAr.contains(ar)));
                 });
               }
               
               // Fallback to Cairo or first available governorate if geocoding yields no match
               if (match == null) {
                  // Try to find Cairo first
                  match = _lookups!.locations.governorates.firstWhereOrNull((g) => 
                    g.nameEn.toLowerCase().contains('cairo') || 
                    g.nameAr.contains('قاهرة')
                  );
                  // Otherwise fallback to first
                  match ??= _lookups!.locations.governorates.first;
                  print('📍 [LOCATION] Match failed, falling back to default governorate: ${match.nameEn}');
               }
               
               print('📍 [LOCATION] Match result: ${match.nameEn} (${match.nameAr})');
              
              if (match != null) {
                 matchedGovName = Responsive.isRTL ? match.nameAr : match.nameEn;
                 setState(() {
                   _selectedGovernorate = match;
                   
                   // Try to match city/administration
                   Administration? matchedAdmin;
                   if (_lookups!.locations.administrations.containsKey(match!.id)) {
                     final possibleCities = [
                       p.locality,
                       p.subLocality,
                       p.subAdministrativeArea,
                       p.thoroughfare
                     ].whereType<String>().map((c) => c.toLowerCase().replaceAll(RegExp(r'al |el |-'), '').trim()).where((c) => c.isNotEmpty).toList();

                     final adminList = _lookups!.locations.administrations[match!.id]!;
                     for (var city in possibleCities) {
                        if (matchedAdmin != null) break;
                        matchedAdmin = adminList.firstWhereOrNull((a) {
                           final en = a.nameEn.toLowerCase().replaceAll(RegExp(r'al |el |-'), '').trim();
                           final ar = a.nameAr.replaceAll(RegExp(r'ال|-'), '').trim();
                           return en == city || ar == city;
                        }) ?? adminList.firstWhereOrNull((a) {
                           final en = a.nameEn.toLowerCase().replaceAll(RegExp(r'al |el |-'), '').trim();
                           final ar = a.nameAr.replaceAll(RegExp(r'ال|-'), '').trim();
                           return en.contains(city) || city.contains(en) || ar.contains(city) || city.contains(ar);
                        });
                     }
                     // Only fallback to first city if governorate was properly matched
                     if (matchedAdmin == null && adminList.isNotEmpty) {
                        matchedAdmin = adminList.first;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const LoadingPage();
    }

    return Obx(() {
    final isDark = AppConfigController.to.isDarkMode;
    final headerTextColor = isDark ? Colors.white : Colors.black87;
    final stepperBg = isDark ? Colors.black.withOpacity(0.18) : Colors.white.withOpacity(0.65);
    final stepperBorder = isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(isDark: isDark, headerTextColor: headerTextColor, stepperBg: stepperBg, stepperBorder: stepperBorder),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: EdgeInsets.only(bottom: 100),
                    child: _buildCurrentStep(),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomBar(),
        ),
        if (_isAnalyzing)
          _buildAIOverlay(),
        if (_isStepLoading)
          _buildStepLoadingOverlay(),
      ],
    );
    });
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

  Widget _buildHeader({
    bool isDark = false,
    Color? headerTextColor,
    Color? stepperBg,
    Color? stepperBorder,
  }) {
    final textColor = headerTextColor ?? Colors.black87;
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios, size: 20, color: textColor),
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
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16.sp, color: textColor),
              ),
              IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 24, color: textColor),
                onPressed: () => AppConfigController.to.toggleTheme(),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),
          _buildStepper(isDark: isDark, stepperBg: stepperBg, stepperBorder: stepperBorder),
        ],
      ),
    );
  }

  Widget _buildStepper({
    bool isDark = false,
    Color? stepperBg,
    Color? stepperBorder,
  }) {
    final bg = stepperBg ?? const Color(0xFFF9FAFB);
    final border = stepperBorder ?? Colors.grey.shade100;
    final steps = [
      {'id': 1, 'label': 'student'.tr},
      {'id': 2, 'label': 'preferences'.tr},
      {'id': 3, 'label': 'schools'.tr},
      {'id': 4, 'label': 'review'.tr},
    ];

    return Container(
      margin: EdgeInsets.symmetric(vertical: 20.h),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
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
                        color: isActive ? AppColors.blue1 : (isCompleted ? Colors.green : (isDark ? const Color(0xFF334155) : Colors.white)),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isActive ? AppColors.blue1 : (isCompleted ? Colors.green : (isDark ? Colors.white24 : Colors.grey.shade300)),
                          width: 2
                        ),
                        boxShadow: isActive ? [BoxShadow(color: AppColors.blue1.withOpacity(0.2), blurRadius: 8, offset: Offset(0, 4))] : null,
                      ),
                      child: Center(
                        child: isCompleted
                          ? Icon(Icons.check, color: isDark ? Colors.black.withOpacity(0.3) : Colors.white, size: 16)
                          : Text('${idx + 1}', style: TextStyle(color: isActive ? Colors.white : (isDark ? Colors.white54 : Colors.grey.shade500), fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      step['label'] as String,
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: isActive ? FontWeight.w900 : FontWeight.w500,
                        color: isActive ? AppColors.blue1 : (isDark ? Colors.white38 : Colors.grey.shade500),
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
                      color: isCompleted ? Colors.green : (isDark ? Colors.white12 : Colors.grey.shade200),
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
      case 4: return _buildReviewStep();
      default: return SizedBox();
    }
  }

  Widget _buildChildSelectionStep() {
    final isDark = AppConfigController.to.isDarkMode;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('who_is_student_applying'.tr, style: AppFonts.h3.copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF111827))),
          SizedBox(height: 8.h),
          Text('select_child_desc'.tr, style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF475569), fontSize: 13.sp, fontWeight: FontWeight.w500)),
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

    final isDark = AppConfigController.to.isDarkMode;
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
          color: isSelected
              ? (isDark ? AppColors.blue1.withOpacity(0.25) : AppColors.blue1.withOpacity(0.12))
              : (isDark ? Colors.black.withOpacity(0.18) : Colors.white.withOpacity(0.65)),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? AppColors.blue1
                : (isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6)),
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: [
             BoxShadow(
               color: isSelected ? AppColors.blue1.withOpacity(0.15) : Colors.black.withOpacity(0.03),
               blurRadius: 16,
               offset: const Offset(0, 6),
             ),
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
                   decoration: BoxDecoration(color: isDark ? Colors.white : Colors.white, shape: BoxShape.circle),
                   child: ClipOval(
                     child: (child.avatar ?? child.profileImage ?? child.image ?? '').isNotEmpty
                         ? SafeNetworkImage(
                             imageUrl: child.avatar ?? child.profileImage ?? child.image,
                             width: 60.w,
                             height: 60.w,
                             fit: BoxFit.cover,
                           )
                         : Center(
                             child: Icon(IconlyBold.profile, color: AppColors.blue1, size: 30.w),
                           ),
                   ),
                ),
             ),
            SizedBox(height: 12.h),
            Text(
              child.arabicFullName ?? child.fullName, 
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12.sp,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.indigo[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                birthDateStr,
                style: TextStyle(
                  color: isDark ? Colors.indigo[200] : Colors.indigo,
                  fontWeight: FontWeight.bold,
                  fontSize: 9.sp,
                ),
              ),
            ),
            if ((child.nationalId.isNotEmpty) || (child.passport != null && child.passport!.isNotEmpty)) ...[
              SizedBox(height: 4.h),
              Text(
                child.nationality == 'Egyptian' || child.nationalId.isNotEmpty
                    ? child.nationalId
                    : child.passport ?? '',
                style: TextStyle(
                  color: isDark ? Colors.indigo[100]!.withOpacity(0.7) : Colors.indigo[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 8.sp,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildAddChildCard() {
    final isDark = AppConfigController.to.isDarkMode;
    return InkWell(
      onTap: () => Get.toNamed(AppRoutes.addChildSteps),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 155.w,
        height: 165.w,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.45),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.5),
            width: 1.2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, color: isDark ? Colors.white70 : Colors.grey[600], size: 28),
            ),
            SizedBox(height: 12.h),
            Text(
              'add_new_child'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 11.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedChildInfo(Student child) {
    final isDark = AppConfigController.to.isDarkMode;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.18) : Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6), width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.blue1.withOpacity(0.2), width: 2)),
            child: Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.04) : Colors.white, shape: BoxShape.circle),
              child: ClipOval(
                child: (child.avatar ?? child.profileImage ?? child.image ?? '').isNotEmpty
                    ? SafeNetworkImage(
                        imageUrl: child.avatar ?? child.profileImage ?? child.image,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: Icon(IconlyBold.profile, color: AppColors.blue1, size: 28),
                      ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(child.arabicFullName ?? child.fullName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: isDark ? Colors.white : const Color(0xFF111827))),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.school, size: 12, color: Colors.grey[400]),
                      SizedBox(width: 4),
                      Text(child.grade.name, style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600], fontSize: 11.sp, fontWeight: FontWeight.w500)),
                      if (child.nationalId.isNotEmpty || (child.passport != null && child.passport!.isNotEmpty)) ...[
                        SizedBox(width: 12.w),
                        Icon(Icons.badge, size: 12, color: Colors.grey[400]),
                        SizedBox(width: 4),
                        Text(
                          child.nationality == 'Egyptian' || child.nationalId.isNotEmpty
                              ? child.nationalId
                              : child.passport ?? '',
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600], fontSize: 11.sp, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  )
               ],
            ),
          )
        ],
      ),
    );
  }

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

    final isDark = AppConfigController.to.isDarkMode;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('search_preferences'.tr, style: AppFonts.h3.copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF111827))),
          SizedBox(height: 8.h),
          Text('search_preferences_desc'.tr, style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF475569), fontSize: 13.sp, fontWeight: FontWeight.w500)),
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
                   hint: Text('select_education_system'.tr, style: TextStyle(fontSize: 13.sp, color: isDark ? Colors.white70 : Colors.black54)),
                   style: TextStyle(fontSize: 13.sp, color: isDark ? Colors.white : Colors.black87),
                   items: _educationSystems.map((e) => DropdownMenuItem(value: e, child: Text(e.name, style: TextStyle(fontSize: 13.sp)))).toList(),
                   onChanged: (val) { if (mounted) setState(() { _selectedSystem = val; _selectedTrack = null; _selectedStage = null; _selectedGrade = null; _updateMatchingCount(); }); },
                   dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                  hint: Text(tracks.isEmpty ? 'no_tracks_available'.tr : 'select_track'.tr, style: TextStyle(fontSize: 13.sp, color: isDark ? Colors.white70 : Colors.black54)),
                  style: TextStyle(fontSize: 13.sp, color: isDark ? Colors.white : Colors.black87),
                  items: tracks.map((e) => DropdownMenuItem(value: e, child: Text(e.name, style: TextStyle(fontSize: 13.sp)))).toList(),
                   onChanged: tracks.isEmpty ? null : (val) { if (mounted) setState(() { _selectedTrack = val; _selectedStage = null; _selectedGrade = null; _updateMatchingCount(); }); },
                  dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                  style: TextStyle(fontSize: 13.sp, color: isDark ? Colors.white : Colors.black87),
                  hint: Text(stages.isEmpty ? 'no_stages_available'.tr : 'select_stage'.tr, style: TextStyle(fontSize: 13.sp, color: isDark ? Colors.white70 : Colors.black54)),
                  items: stages.map((e) => DropdownMenuItem(value: e, child: Text(e.name, style: TextStyle(fontSize: 13.sp)))).toList(),
                   onChanged: stages.isEmpty ? null : (val) { if (mounted) setState(() { _selectedStage = val; _selectedGrade = null; _updateMatchingCount(); }); },
                  dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                  style: TextStyle(fontSize: 13.sp, color: isDark ? Colors.white : Colors.black87),
                  hint: Text(grades.isEmpty ? 'select_stage_first'.tr : 'select_grade'.tr, style: TextStyle(fontSize: 13.sp, color: isDark ? Colors.white70 : Colors.black54)),
                  items: grades.map((e) => DropdownMenuItem(value: e, child: Text(e.name, style: TextStyle(fontSize: 13.sp)))).toList(),
                   onChanged: grades.isEmpty ? null : (val) { if (mounted) setState(() { _selectedGrade = val; _updateMatchingCount(); }); },
                  dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                     key: ValueKey('gov_${_selectedGovernorate?.id ?? "none"}'),
                     value: _selectedGovernorate,
                     hint: Text('select_governorate'.tr, style: TextStyle(fontSize: 13.sp, color: isDark ? Colors.white70 : Colors.black54)),
                     style: TextStyle(fontSize: 13.sp, color: isDark ? Colors.white : Colors.black87),
                     items: _lookups!.locations.governorates.map((e) => DropdownMenuItem(value: e, child: Text(Responsive.isRTL ? e.nameAr : e.nameEn, style: TextStyle(fontSize: 13.sp)))).toList(),
                     onChanged: (v) { if (mounted) setState(() { _selectedGovernorate = v; _selectedAdministration = null; _updateMatchingCount(); }); },
                     dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                     decoration: _inputDeco(),
                     borderRadius: BorderRadius.circular(12),
                     menuMaxHeight: 400,
                   )
                ),
                _buildDropdownSection('select_city'.tr,
                     DropdownButtonFormField<Administration>(
                       key: ValueKey('city_${_selectedAdministration?.id ?? "none"}_gov_${_selectedGovernorate?.id ?? "none"}'),
                       value: _selectedAdministration,
                       hint: Text(cities.isEmpty ? 'select_gov_first'.tr : 'select_city'.tr, style: TextStyle(fontSize: 13.sp, color: isDark ? Colors.white70 : Colors.black54)),
                       style: TextStyle(fontSize: 13.sp, color: isDark ? Colors.white : Colors.black87),
                       items: cities.map((e) => DropdownMenuItem(value: e, child: Text(Responsive.isRTL ? e.nameAr : e.nameEn, style: TextStyle(fontSize: 13.sp)))).toList(),
                       onChanged: cities.isEmpty ? null : (v) { if (mounted) setState(() { _selectedAdministration = v; _updateMatchingCount(); }); },
                       dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                  Text('${_feeRange.start.toInt().toLocaleString()} ${'currency'.tr}', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 12.sp)),
                  Text('${_feeRange.end.toInt().toLocaleString()} ${'currency'.tr}', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 12.sp)),
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
    final isDark = AppConfigController.to.isDarkMode;
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.18) : Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: 12.w),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14.sp,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildChoiceSection({required String label, required List<Map<String, String>> choices, required String? selectedId, required Function(String?) onSelected}) {
    final isDark = AppConfigController.to.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
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
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.blue1
                      : (isDark ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.55)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.blue1
                        : (isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.5)),
                    width: isSelected ? 2 : 1.2,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: AppColors.blue1.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]
                      : null,
                ),
                child: Text(
                  c['label']!,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.grey[700]),
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDropdownSection(String label, Widget field) {
    final isDark = AppConfigController.to.isDarkMode;
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            height: 52.h,
            child: field
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco() {
    final isDark = AppConfigController.to.isDarkMode;
    return InputDecoration(
      filled: true,
      fillColor: isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.5),
      hintStyle: TextStyle(fontSize: 13.sp, color: isDark ? Colors.white30 : Colors.grey[400]),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6)), 
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

  Widget _buildSchoolResultsStep() {
    final isDark = AppConfigController.to.isDarkMode;
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
                 padding: EdgeInsets.all(10),
                 decoration: BoxDecoration(
                   color: isDark ? Colors.black.withOpacity(0.18) : Colors.white.withOpacity(0.65),
                   borderRadius: BorderRadius.circular(24),
                   border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6), width: 1.2),
                   boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 6))],
                 ),
                 child: Column(
                   children: [
                      Container(
                        height: 42.h,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200]!),
                        ),
                        child: TextField(
                          onChanged: (v) { if (mounted) setState(() => _schoolSearchQuery = v); },
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp, color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            hintText: 'search_school_name'.tr,
                            hintStyle: TextStyle(fontSize: 11.sp, color: isDark ? Colors.grey[500] : Colors.grey[400]),
                            prefixIcon: Icon(IconlyLight.search, color: isDark ? Colors.grey[500] : Colors.grey, size: 18),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _isAnalyzing ? null : _analyzeWithAI,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                height: 42.h,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
                                  ],
                                ),
                                child: Center(
                                  child: _isAnalyzing
                                    ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                                          SizedBox(width: 8),
                                          Text('get_derasay_opinion'.tr, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12.sp)),
                                        ],
                                      ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Container(
                            height: 42.h,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.indigo.withOpacity(0.2) : Colors.indigo[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isDark ? Colors.indigo.withOpacity(0.4) : Colors.transparent),
                            ),
                            child: Center(
                              child: Text(
                                '${displayList.length} ${'schools'.tr}',
                                style: TextStyle(color: isDark ? Colors.indigo[200] : Colors.indigo[700], fontWeight: FontWeight.w900, fontSize: 11.sp),
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
                                       decoration: BoxDecoration(color: isDark ? Colors.black.withOpacity(0.3) : Colors.white, shape: BoxShape.circle),
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
    final isDark = AppConfigController.to.isDarkMode;

    String formattedAge = '';
    try {
      final bDate = DateTime.parse(child.birthDate);
      final now = DateTime.now();
      int y = now.year - bDate.year;
      int m = now.month - bDate.month;
      int d = now.day - bDate.day;
      if (d < 0) {
        m -= 1;
        d += DateTime(now.year, now.month, 0).day;
      }
      if (m < 0) {
        y -= 1;
        m += 12;
      }
      formattedAge = '$y ${'years'.tr} $m ${'months'.tr} $d ${'days'.tr}';
    } catch(e) {
      formattedAge = age.toStringAsFixed(1) + ' ' + 'years'.tr;
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.5), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.03), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -10, top: -10,
            child: Icon(Icons.school, size: 100, color: isDark ? Colors.white.withOpacity(0.02) : Colors.grey.withOpacity(0.05)),
          ),
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 65.w, height: 65.w,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.indigo.withOpacity(0.2) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? Colors.white10 : Colors.white, width: 3),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)],
                    ),
                    child: ClipOval(
                      child: (child.avatar ?? child.profileImage ?? child.image ?? '').isNotEmpty 
                        ? SafeNetworkImage(imageUrl: child.avatar ?? child.profileImage ?? child.image, fit: BoxFit.cover)
                        : Center(child: Icon(IconlyBold.profile, color: isDark ? Colors.indigo[100] : Colors.indigo[200], size: 30)),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(
                           child.arabicFullName ?? child.fullName,
                           style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18.sp, color: isDark ? Colors.white : const Color(0xFF111827), letterSpacing: -0.5),
                         ),
                         SizedBox(height: 6),
                         Row(
                           children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey[200]!)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 12),
                                    SizedBox(width: 4),
                                    Text(
                                      child.nationalId.isNotEmpty
                                          ? child.nationalId
                                          : (child.temporaryNationalId != null && child.temporaryNationalId!.isNotEmpty
                                              ? child.temporaryNationalId!
                                              : (child.passport != null && child.passport!.isNotEmpty
                                                  ? child.passport!
                                                  : 'no_national_id'.tr)),
                                      style: TextStyle(fontSize: 10.sp, color: isDark ? Colors.white54 : Colors.grey[500], fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isTransfer ? Colors.amber[50] : const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isTransfer ? Colors.amber[100]! : const Color(0xFFD1FAE5)),
                                ),
                                child: Text(
                                  isTransfer ? 'transfer_request'.tr : 'new_admission'.tr,
                                  style: TextStyle(fontSize: 10.sp, color: isTransfer ? Colors.amber[800] : const Color(0xFF047857), fontWeight: FontWeight.w900),
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
                    label: 'age'.tr,
                    value: formattedAge,
                    unit: '',
                    color: const Color(0xFF111827),
                    isAge: true,
                  ),
                  SizedBox(width: 12.w),
                  _headerStatCard(
                    label: 'target_grade'.tr,
                    value: _selectedGrade?.name ?? child.grade.name,
                    unit: '',
                    color: const Color(0xFF111827),
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

  Widget _headerStatCard({required String label, required String value, required String unit, required Color color, bool isHighlight = false, bool isAge = false}) {
    final isDark = AppConfigController.to.isDarkMode;
    return Expanded(
      child: Container(
        height: 75.h,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.08) : color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.transparent),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(color: isDark ? Colors.white30 : Colors.grey[400], fontSize: 8.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: isHighlight ? const Color(0xFF818CF8) : Colors.white, fontSize: isAge ? 11.sp : (isHighlight ? 12.sp : 18.sp), fontWeight: FontWeight.w900),
            ),
            if (unit.isNotEmpty)
              Text(unit, style: TextStyle(color: const Color(0xFF818CF8), fontSize: 8.sp, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolCard(School school, bool isSuggested) {
    final isDark = AppConfigController.to.isDarkMode;
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
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.blue1.withOpacity(0.25) : AppColors.blue1.withOpacity(0.12))
              : (isDark ? Colors.black.withOpacity(0.18) : Colors.white.withOpacity(0.65)),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.blue1 : (isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6)),
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                ? AppColors.blue1.withOpacity(0.15) 
                : Colors.black.withOpacity(0.03),
              blurRadius: 24,
              offset: const Offset(0, 8),
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
                      imageUrl: school.bannerImage ?? school.visibilitySettings?.officialLogo?.url,
                      width: 100.w,
                      height: 100.w,
                      fit: BoxFit.cover,
                      fallbackAsset: AssetsManager.login,
                      placeholder: Container(
                        color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey[50], 
                        child: Icon(Icons.school_rounded, color: isDark ? Colors.white10 : Colors.grey[200], size: 40)
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
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA855F7)]),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.2), blurRadius: 4)],
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
                               padding: const EdgeInsets.all(4),
                               decoration: BoxDecoration(color: AppColors.blue1, shape: BoxShape.circle),
                               child: const Icon(Icons.check, color: Colors.white, size: 12),
                             ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                         Responsive.formatSchoolName(school.name), 
                         maxLines: 1, overflow: TextOverflow.ellipsis,
                         style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.sp, color: isDark ? Colors.white : const Color(0xFF111827), letterSpacing: -0.3)
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(IconlyLight.location, size: 10, color: isDark ? Colors.white30 : Colors.grey[400]),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              '${school.location?.city ?? ''}, ${school.location?.governorate ?? ''}',
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 9.sp, color: isDark ? Colors.white54 : Colors.grey[500], fontWeight: FontWeight.w600),
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
                               _miniBadge(school.type!.toLowerCase().tr, isIndigo: true),
                             const SizedBox(width: 6),
                             _miniBadge((school.gender ?? 'mixed').toLowerCase().tr, isGender: true),
                             if (school.admissionFee != null && school.admissionFee!.amount > 0) ...[
                               const SizedBox(width: 6),
                               _miniBadge('${school.admissionFee!.amount.toInt()} ${school.admissionFee!.currency.tr}', isPrice: true),
                             ],
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
              Divider(height: 32, color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey[100]),
              Row(
                children: [
                  if (school.educationSystem != null) 
                    _detailItem(Icons.book_outlined, school.educationSystem!.toLowerCase().tr),
                  if (school.religionType != null) 
                    _detailItem(Icons.mosque_outlined, school.religionType!.toLowerCase().tr),
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
    final isDark = AppConfigController.to.isDarkMode;
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isDark ? Colors.white38 : Colors.grey[400]),
          SizedBox(width: 4),
          Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.sp, color: isDark ? Colors.white54 : Colors.grey[600], fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _miniBadge(String text, {bool isIndigo = false, bool isPrice = false, bool isGender = false}) {
    final isDark = AppConfigController.to.isDarkMode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPrice 
            ? (isDark ? Colors.teal.withOpacity(0.2) : const Color(0xFFECFDF5))
            : (isGender 
                ? (isDark ? Colors.orange.withOpacity(0.2) : Colors.orange[50])
                : (isIndigo 
                    ? (isDark ? Colors.indigo.withOpacity(0.2) : Colors.indigo[50])
                    : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF3F4F6)))), 
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPrice 
              ? (isDark ? Colors.teal.withOpacity(0.4) : const Color(0xFFD1FAE5))
              : (isGender 
                  ? (isDark ? Colors.orange.withOpacity(0.4) : Colors.orange[100]!)
                  : (isIndigo 
                      ? (isDark ? Colors.indigo.withOpacity(0.4) : Colors.indigo[100]!)
                      : (isDark ? Colors.white.withOpacity(0.1) : Colors.transparent))), 
          width: 0.5
        ),
      ),
      child: Text(
        text, 
        style: TextStyle(
          fontSize: 9.sp, 
          fontWeight: FontWeight.w800, 
          color: isPrice 
              ? (isDark ? Colors.teal[200] : const Color(0xFF047857))
              : (isGender 
                  ? (isDark ? Colors.orange[300] : Colors.orange[700])
                  : (isIndigo 
                      ? (isDark ? Colors.indigo[300] : Colors.indigo[700])
                      : (isDark ? Colors.white70 : const Color(0xFF4B5563)))),
        ),
      ),
    );
  }

  Widget _buildReviewStep() {
    final selectedSchools = _selectedSchoolsMap.values.toList();
    final isDark = AppConfigController.to.isDarkMode;
    
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          const SizedBox(height: 10),
          _buildSelectedChildInfo(_relatedChildren.firstWhere((c) => c.id == _selectedChildId!)),
          SizedBox(height: 24.h),
          
          Align(
            alignment: Responsive.isRTL ? Alignment.centerRight : Alignment.centerLeft,
            child: Text('selected_schools'.trParams({'n': '${selectedSchools.length}'}), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16.sp, color: isDark ? Colors.white : const Color(0xFF111827))),
          ),
          SizedBox(height: 16.h),
          
          if (selectedSchools.isEmpty)
             Center(child: Padding(
               padding: const EdgeInsets.symmetric(vertical: 20),
               child: Text('no_schools_selected'.tr, style: const TextStyle(color: Colors.grey)),
             )),

          // Selected List - Small modern items
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: selectedSchools.length,
            separatorBuilder: (_,__) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final school = selectedSchools[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                   color: isDark ? Colors.black.withOpacity(0.18) : Colors.white.withOpacity(0.65),
                   borderRadius: BorderRadius.circular(16),
                   border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6), width: 1.2),
                   boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SafeSchoolImage(
                            imageUrl: school.bannerImage, 
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover, 
                            fallbackAsset: AssetsManager.login,
                            placeholder: Icon(Icons.school, size: 24, color: Colors.grey[400])
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(Responsive.formatSchoolName(school.name), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1F2937), fontSize: 12.sp)),
                            if (school.type != null && school.type!.isNotEmpty) ...[
                              SizedBox(height: 2),
                              Text(school.type!.tr, style: TextStyle(color: AppColors.blue1, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                            ],
                          ],
                        )),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red[300], size: 18),
                          onPressed: () => setState(() => _selectedSchoolsMap.remove(school.id)),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red[50],
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(32, 32),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    if (school.location != null) ...[
                      _buildSchoolDetailMiniRow(
                        icon: Icons.location_on_rounded,
                        label: 'location'.tr,
                        value: '${school.location!.governorate.tr} - ${school.location!.city.tr}${school.location!.address != null && school.location!.address!.isNotEmpty ? ', ${school.location!.address}' : ''}',
                        isDark: isDark,
                      ),
                      SizedBox(height: 6.h),
                    ],
                    if (school.gender != null && school.gender!.isNotEmpty) ...[
                      _buildSchoolDetailMiniRow(
                        icon: Icons.wc_rounded,
                        label: 'gender'.tr,
                        value: school.gender!.tr,
                        isDark: isDark,
                      ),
                      SizedBox(height: 6.h),
                    ],
                    if (school.mainTeachingLanguage != null && school.mainTeachingLanguage!.isNotEmpty) ...[
                      _buildSchoolDetailMiniRow(
                        icon: Icons.translate_rounded,
                        label: 'language'.tr,
                        value: school.mainTeachingLanguage!.tr,
                        isDark: isDark,
                      ),
                      SizedBox(height: 6.h),
                    ],
                    if (school.location?.website != null && school.location!.website!.isNotEmpty) ...[
                      _buildSchoolDetailMiniRow(
                        icon: Icons.language_rounded,
                        label: 'website'.tr,
                        value: school.location!.website!,
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          
          SizedBox(height: 24.h),
          // Notice
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.orange.withOpacity(0.1) : Colors.orange[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.orange.withOpacity(0.2) : Colors.orange[100]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: isDark ? Colors.orange[300] : Colors.orange[800], size: 20),
                SizedBox(width: 10),
                Expanded(child: Text('non_refundable_notice'.tr, style: TextStyle(color: isDark ? Colors.orange[200] : Colors.orange[900], fontSize: 10.sp, height: 1.4))),
              ],
            ),
          ),
          SizedBox(height: 100.h),
        ],
      ),
    );
  }

  Widget _buildSchoolDetailMiniRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 12.sp, color: AppColors.blue1),
        SizedBox(width: 8.w),
        Text(
          '$label: ',
          style: TextStyle(
            color: isDark ? Colors.white38 : Colors.grey[500],
            fontSize: 9.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey[700],
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchingSchoolsBadge() {
    final isDark = AppConfigController.to.isDarkMode;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
             style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue1,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
             ),
             onPressed: () async {
                await _fetchSchools();
                if (_matchingSchoolsCount == 0) {
                   CustomSnackbar.showError('no_schools_found'.tr);
                }
             },
             child: _isLoadingSchools 
                 ? SizedBox(width: 20, height: 20, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                 : Text('get_schools'.tr, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.sp)),
          ),
        ),
        if (_hasFetchedSchools && _matchingSchoolsCount > 0) ...[
          Container(
            margin: EdgeInsets.only(top: 16.h),
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
          )
        ]
      ],
    );
  }



  // --- Overlays ---
  
  Widget _buildAIOverlay() {
    final isDark = AppConfigController.to.isDarkMode;
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: (isDark ? Colors.black : const Color(0xFF1E1B4B)).withOpacity(0.3)), // Deep indigo tint
            ),
          ),
          Center(
            child: Container(
              width: 320.w,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withOpacity(0.65) : Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Premium Gradient Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: const BoxDecoration(
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
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    child: Column(
                      children: [
                        Text(
                          'ai_analyzing_desc'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.grey[600],
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
                                color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              height: 8.h,
                              width: 272.w * (_aiProgress / 100),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4F46E5), Color(0xFF9333EA)],
                                ),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4F46E5).withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
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
    final isDark = AppConfigController.to.isDarkMode;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: completed
                  ? (isDark ? Colors.green.withOpacity(0.15) : Colors.green[50])
                  : (isCurrent
                      ? const Color(0xFF4F46E5).withOpacity(0.15)
                      : (isDark ? Colors.white.withOpacity(0.04) : Colors.grey[50])),
            ),
            child: Center(
              child: isCurrent 
                ? SizedBox(width: 14.w, height: 14.w, child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)))
                : Icon(
                    completed ? Icons.check_rounded : Icons.circle_outlined,
                    color: completed
                        ? Colors.green
                        : (isDark ? Colors.white30 : Colors.grey[300]),
                    size: 16.sp,
                  ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: completed || isCurrent
                    ? (isDark ? Colors.white70 : Colors.black87)
                    : (isDark ? Colors.white30 : Colors.grey[400]),
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
    if (_isAnalyzing) return const SizedBox();
    
    // Hide bottom bar on step 1 since we select by clicking card
    if (_currentStep == 1) return const SizedBox();

    String label = 'next'.tr;
    VoidCallback? onTap = _nextStep;

    if (_currentStep == 4) {
      label = 'submit_application'.tr;
      onTap = _submitApplication;
    }

    bool isDisabled = false;
    if (_currentStep == 2 && (!_hasFetchedSchools || _matchingSchoolsCount == 0)) {
      isDisabled = true;
      onTap = null;
    }

    final isDark = AppConfigController.to.isDarkMode;

    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 24, left: 20, right: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.04), blurRadius: 20, offset: const Offset(0, -5))],
        border: Border(top: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey[100]!, width: 1)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Back button removed as requested
            Expanded(
              child: SizedBox(
                height: 44.h,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isDisabled 
                      ? LinearGradient(colors: [isDark ? Colors.grey[800]! : Colors.grey[300]!, isDark ? Colors.grey[800]! : Colors.grey[300]!])
                      : const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      if (!isDisabled)
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        )
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: onTap,
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
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
