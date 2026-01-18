import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/controllers/dashboard_controller.dart';
import '../../models/student_models.dart';
import '../../models/school_models.dart';
import '../../models/admission_models.dart';
import '../../models/school_suggestion_models.dart';
import '../../services/admission_service.dart';
import '../../services/schools_service.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/school_preferences_wizard.dart';
import '../../../widgets/safe_network_image.dart';

class ApplyToSchoolsPage extends StatefulWidget {
  const ApplyToSchoolsPage({Key? key}) : super(key: key);

  @override
  State<ApplyToSchoolsPage> createState() => _ApplyToSchoolsPageState();
}

class _ApplyToSchoolsPageState extends State<ApplyToSchoolsPage> {
  // Data
  Student? _selectedChild;
  List<School> _allSchools = [];
  List<School> _suggestedSchools = [];
  SchoolSuggestionResponse? _aiResponse;
  
  // State
  bool _isLoadingSchools = false;
  bool _isAnalyzing = false;
  bool _isSubmitting = false;
  String _schoolSearchQuery = '';
  bool _showResults = false;
  
  // Selection for final submission (must select exactly 3)
  List<School> _selectedSchools = [];

  @override
  void initState() {
    super.initState();
    _loadArguments();
    _loadAllSchools(); // Needed for AI to analyze
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
      // Find child in DashboardController
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
        print('🏫 [APPLY] Loaded ${_allSchools.length} schools for analysis');
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

  Future<void> _getSuggestions(SchoolPreferences prefs) async {
    if (_selectedChild == null) {
      Get.snackbar(
        'error'.tr,
        'please_select_student_first'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    if (_allSchools.isEmpty) {
      if (_isLoadingSchools) {
        Get.snackbar(
          'info'.tr,
          'loading_schools_please_wait'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primaryBlue,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'error'.tr,
          'failed_to_load_schools'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
        _loadAllSchools(); // Try reloading
      }
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final request = SchoolSuggestionRequest(
        child: _selectedChild!,
        schools: _allSchools,
        preferences: prefs,
      );

      final response = await SchoolsService.suggestThree(request);

      if (mounted) {
        setState(() {
          _aiResponse = response;
          // Filter schools based on suggested IDs
          _suggestedSchools = _allSchools
              .where((school) => response.suggestedIds.contains(school.id))
              .toList();
          _showResults = true;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
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

    try {
      final request = ApplyToSchoolsRequest(
        childId: _selectedChild!.id,
        selectedSchools: _selectedSchools.map((school) => SelectedSchool.fromSchool(school)).toList(),
      );

      final response = await AdmissionService.applyToSchools(request);

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      Get.snackbar(
        'success'.tr,
        response.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Wait for snackbar to start showing before navigating
      await Future.delayed(const Duration(milliseconds: 500));

      // Trigger refresh in background
      DashboardController.to.refreshAll().catchError((_) => null);
      
      // Go to applications page and clear stack
      Get.offNamed(AppRoutes.applications);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });

      String msg = 'failed_to_apply'.tr;
      if (e is AdmissionException) {
        msg = e.message;
      }

      Get.snackbar(
        'error'.tr,
        msg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if it's a transfer or new application
    final isTransfer = _selectedChild?.schoolId.id.isNotEmpty == true;
    final title = isTransfer ? 'transfer_to_school'.tr : 'apply_to_school'.tr;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: AppFonts.h3.copyWith(color: Colors.white)),
        backgroundColor: AppColors.primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: _isLoadingSchools 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStudentHeader(),
                Expanded(
                  child: _showResults ? _buildResultsView() : _buildWizardView(),
                ),
              ],
            ),
      bottomNavigationBar: (_showResults && _selectedSchools.isNotEmpty)
          ? Container(
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
                child: SizedBox(
                  width: double.infinity,
                  height: Responsive.h(52),
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitApplication,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      disabledBackgroundColor: AppColors.grey300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Responsive.r(16)),
                      ),
                      elevation: 4,
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            height: Responsive.h(24),
                            width: Responsive.h(24),
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded, size: 20.sp, color: Colors.white),
                              SizedBox(width: Responsive.w(12)),
                              Text(
                                _selectedSchools.length == 3 
                                  ? 'submit_applications'.tr 
                                  : 'submit_application'.tr,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: Responsive.sp(16),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildStudentHeader() {
    if (_selectedChild == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16.w),
      color: AppColors.primaryBlue.withOpacity(0.1),
      child: Row(
        children: [
          Icon(Icons.person, color: AppColors.primaryBlue, size: Responsive.sp(24)),
          SizedBox(width: Responsive.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedChild!.arabicFullName ?? _selectedChild!.fullName,
                  style: AppFonts.h4.copyWith(color: AppColors.textPrimary),
                ),
                if (_selectedChild!.schoolId.id.isNotEmpty)
                  Text(
                    '${'current_school_colon'.tr} ${_selectedChild!.schoolId.name}',
                    style: AppFonts.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWizardView() {
    return SchoolPreferencesWizard(
      isLoading: _isAnalyzing,
      onPreferencesSubmitted: _getSuggestions,
    );
  }

  Widget _buildResultsView() {
    // Separate schools into suggested and others
    final suggestedIds = _aiResponse?.suggestedIds.toSet() ?? {};
    final query = _schoolSearchQuery.toLowerCase();
    
    final filteredOtherSchools = _allSchools
        .where((s) => !suggestedIds.contains(s.id))
        .where((s) => query.isEmpty || s.name.toLowerCase().contains(query))
        .toList();
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Analysis Section
          if (_aiResponse != null) ...[ 
            Container(
              padding: Responsive.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue.withOpacity(0.1),
                    AppColors.primaryBlue.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: AppColors.primaryBlue, size: 24.sp),
                      SizedBox(width: Responsive.w(12)),
                      Text(
                        'ai_analysis_result'.tr,
                        style: AppFonts.h4.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  MarkdownBody(
                    data: _aiResponse!.markdown ?? _aiResponse!.message,
                    styleSheet: MarkdownStyleSheet(
                      p: AppFonts.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.h(24)),
          ],

          // Selection Progress Hint (Submit button moved to bottomNavigationBar)
          Container(
            padding: Responsive.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _selectedSchools.isNotEmpty
                      ? AppColors.success.withOpacity(0.15)
                      : AppColors.warning.withOpacity(0.15),
                  _selectedSchools.isNotEmpty
                      ? AppColors.success.withOpacity(0.05)
                      : AppColors.warning.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(Responsive.r(16)),
              border: Border.all(
                color: _selectedSchools.isNotEmpty
                    ? AppColors.success.withOpacity(0.4)
                    : AppColors.warning.withOpacity(0.4),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: Responsive.all(12),
                  decoration: BoxDecoration(
                    color: _selectedSchools.isNotEmpty
                        ? AppColors.success
                        : AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _selectedSchools.isNotEmpty
                        ? Icons.check_circle_rounded
                        : Icons.info_rounded,
                    color: Colors.white,
                    size: Responsive.sp(24),
                  ),
                ),
                SizedBox(width: Responsive.w(16)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedSchools.length == 3
                            ? 'all_schools_selected'.tr
                            : 'select_at_least_one_school'.tr,
                        style: AppFonts.h4.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: Responsive.sp(16),
                        ),
                      ),
                      SizedBox(height: Responsive.h(4)),
                      Text(
                        'schools_selected_count'.tr.replaceAll('{count}', '${_selectedSchools.length}').replaceAll('{total}', '3'),
                        style: AppFonts.bodyMedium.copyWith(
                          color: _selectedSchools.isNotEmpty
                              ? AppColors.success
                              : AppColors.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: Responsive.sp(14),
                        ),
                      ),
                    ],
                  ),
                ),
                // Progress indicator
                Container(
                  padding: Responsive.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedSchools.isNotEmpty
                        ? AppColors.success
                        : AppColors.warning,
                    borderRadius: BorderRadius.circular(Responsive.r(20)),
                  ),
                  child: Text(
                    '${_selectedSchools.length}/3',
                    style: AppFonts.h4.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.sp(18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // AI Suggested Schools Section
          if (_suggestedSchools.isNotEmpty) ...[ 
            Row(
              children: [
                Icon(Icons.stars, color: AppColors.primaryBlue, size: Responsive.sp(22)),
                SizedBox(width: Responsive.w(8)),
                Text(
                  'ai_suggested_schools'.tr,
                  style: AppFonts.h4.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.sp(13),
                  ),
                ),
                SizedBox(width: Responsive.w(8)),
                Container(
                  padding: Responsive.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(Responsive.r(12)),
                  ),
                  child: Text(
                    '${_suggestedSchools.length}',
                    style: AppFonts.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.h(12)),
            ..._suggestedSchools.map((school) => _buildSchoolCard(school, isAISuggested: true)).toList(),
            SizedBox(height: Responsive.h(24)),
          ],

          // Search Bar for Schools
          Container(
            margin: EdgeInsets.only(bottom: Responsive.h(24)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(Responsive.r(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _schoolSearchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'search_schools_hint'.tr,
                prefixIcon: Icon(Icons.search, color: AppColors.primaryBlue),
                suffixIcon: _schoolSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _schoolSearchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Responsive.r(16)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: Responsive.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),

          // Other Schools Section
          if (filteredOtherSchools.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.school, color: AppColors.textSecondary, size: Responsive.sp(22)),
                SizedBox(width: Responsive.w(8)),
                Text(
                  'other_schools'.tr,
                  style: AppFonts.h4.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: Responsive.w(8)),
                Container(
                  padding: Responsive.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(Responsive.r(12)),
                  ),
                  child: Text(
                    '${filteredOtherSchools.length}',
                    style: AppFonts.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.h(12)),
            ...filteredOtherSchools.map((school) => _buildSchoolCard(school, isAISuggested: false)).toList(),
          ],
          
          if (_suggestedSchools.isEmpty && filteredOtherSchools.isEmpty)
            Center(
              child: Padding(
                padding: Responsive.all(40),
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: Responsive.sp(64), color: AppColors.grey400),
                    SizedBox(height: Responsive.h(16)),
                    Text(
                      'no_schools_match_preferences'.tr,
                      style: AppFonts.h4.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
             
          SizedBox(height: 24.h),
          
          // Retry Button
          Center(
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _showResults = false;
                  _selectedSchools.clear();
                });
              },
              icon: const Icon(Icons.refresh),
              label: Text('try_different_preferences'.tr),
              style: OutlinedButton.styleFrom(
                padding: Responsive.symmetric(horizontal: 24, vertical: 14),
                side: BorderSide(color: AppColors.primaryBlue, width: 2),
              ),
            ),
          ),
          SizedBox(height: Responsive.h(24)),
        ],
      ),
    );
  }

  Widget _buildSchoolCard(School school, {bool isAISuggested = false}) {
    final isSelected = _selectedSchools.any((s) => s.id == school.id);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            // Deselect if already selected
            _selectedSchools.removeWhere((s) => s.id == school.id);
          } else {
            // Only allow selection if less than 3 schools selected
            if (_selectedSchools.length < 3) {
              _selectedSchools.add(school);
            } else {
              // Show message that only 3 schools can be selected
              Get.snackbar(
                'info'.tr,
                'you_can_only_select_3_schools'.tr,
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColors.warning,
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
              );
            }
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: Responsive.h(16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Responsive.r(20)),
          border: Border.all(
            color: isSelected 
                ? AppColors.primaryBlue 
                : (isAISuggested ? AppColors.primaryBlue.withOpacity(0.3) : Colors.transparent),
            width: isSelected ? 3 : (isAISuggested ? 2 : 0),
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? AppColors.primaryBlue.withOpacity(0.2)
                  : (isAISuggested ? AppColors.primaryBlue.withOpacity(0.1) : Colors.black.withOpacity(0.06)),
              blurRadius: isSelected ? 20 : 12,
              offset: Offset(0, isSelected ? 8 : 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image with gradient overlay
            Stack(
              children: [
                Container(
                  height: Responsive.h(140),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(Responsive.r(18))),
                  ),
                  child: school.bannerImage != null || (school.media?.schoolImages?.isNotEmpty ?? false)
                      ? ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(Responsive.r(18))),
                          child: Stack(
                            children: [
                              SafeNetworkImage(
                                imageUrl: school.bannerImage ?? school.media!.schoolImages!.first.url,
                                width: double.infinity,
                                height: Responsive.h(140),
                                fit: BoxFit.cover,
                              ),
                              // Gradient overlay
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.3),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(Responsive.r(18))),
                          child: Container(
                            width: double.infinity,
                            height: Responsive.h(140),
                            color: Colors.white,
                            child: Padding(
                              padding: Responsive.all(20),
                              child: Image.asset(
                                'assets/png/logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                ),
                // AI Suggestion Badge
                if (isAISuggested)
                  Positioned(
                    top: Responsive.h(12),
                    right: Responsive.w(12),
                    child: Container(
                      padding: Responsive.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryBlue,
                            AppColors.primaryBlue.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(Responsive.r(20)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.4),
                            blurRadius: Responsive.r(8),
                            offset: Offset(0, Responsive.h(2)),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: Responsive.sp(14),
                            color: Colors.white,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'AI',
                            style: AppFonts.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: Responsive.sp(11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Selection indicator
                if (isSelected)
                  Positioned(
                    top: Responsive.h(12),
                    right: Responsive.w(12),
                    child: Container(
                      padding: Responsive.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.4),
                            blurRadius: Responsive.r(8),
                            offset: Offset(0, Responsive.h(2)),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: Responsive.sp(20),
                      ),
                    ),
                  ),
              ],
            ),
            
            // Content
            Padding(
              padding: Responsive.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // School name
                  Text(
                    school.name,
                    style: AppFonts.h4.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 12.h),
                  
                  // Tags and info
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: [
                      _buildModernTag(
                        school.type ?? 'general'.tr,
                        Icons.school_outlined,
                        AppColors.primaryBlue,
                      ),
                      if (school.location?.city != null)
                        _buildModernTag(
                          school.location!.city,
                          Icons.location_on_outlined,
                          AppColors.success,
                        ),
                    ],
                  ),
                  
                  if (school.admissionFee != null) ...[
                    SizedBox(height: Responsive.h(12)),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.payments_outlined,
                            size: 18.sp,
                            color: AppColors.success,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '${school.admissionFee!.amount} ${'egp'.tr}',
                            style: AppFonts.bodyMedium.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                              fontSize: Responsive.sp(14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTag(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            text,
            style: AppFonts.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

}
