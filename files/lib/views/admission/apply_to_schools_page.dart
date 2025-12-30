import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
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
  bool _showResults = false;
  
  // Selection for final submission
  School? _selectedSchoolForApplication;

  @override
  void initState() {
    super.initState();
    _loadArguments();
    _loadAllSchools(); // Needed for AI to analyze
  }

  void _loadArguments() {
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args['child'] != null) {
      setState(() {
        _selectedChild = args['child'] as Student;
      });
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
    if (_selectedChild == null || _allSchools.isEmpty) return;

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
    if (_selectedChild == null || _selectedSchoolForApplication == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final request = ApplyToSchoolsRequest(
        childId: _selectedChild!.id,
        selectedSchools: [
          SelectedSchool.fromSchool(_selectedSchoolForApplication!)
        ],
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
    );
  }

  Widget _buildStudentHeader() {
    if (_selectedChild == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16.w),
      color: AppColors.primaryBlue.withOpacity(0.1),
      child: Row(
        children: [
          Icon(Icons.person, color: AppColors.primaryBlue, size: 24.sp),
          SizedBox(width: 12.w),
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
    final otherSchools = _allSchools.where((s) => !suggestedIds.contains(s.id)).toList();
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Analysis Section
          if (_aiResponse != null) ...[ 
            Container(
              padding: EdgeInsets.all(20.w),
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
                      SizedBox(width: 12.w),
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
            SizedBox(height: 24.h),
          ],

          // AI Suggested Schools Section
          if (_suggestedSchools.isNotEmpty) ...[ 
            Row(
              children: [
                Icon(Icons.stars, color: AppColors.primaryBlue, size: 22.sp),
                SizedBox(width: 8.w),
                Text(
                  'ai_suggested_schools'.tr,
                  style: AppFonts.h4.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(12.r),
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
            SizedBox(height: 12.h),
            ..._suggestedSchools.map((school) => _buildSchoolCard(school, isAISuggested: true)).toList(),
            SizedBox(height: 32.h),
          ],

          // Other Schools Section
          if (otherSchools.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.school, color: AppColors.textSecondary, size: 22.sp),
                SizedBox(width: 8.w),
                Text(
                  'other_schools'.tr,
                  style: AppFonts.h4.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '${otherSchools.length}',
                    style: AppFonts.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            ...otherSchools.map((school) => _buildSchoolCard(school, isAISuggested: false)).toList(),
          ],
          
          if (_suggestedSchools.isEmpty && otherSchools.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(40.w),
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 64.sp, color: AppColors.grey400),
                    SizedBox(height: 16.h),
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
                  _selectedSchoolForApplication = null;
                });
              },
              icon: const Icon(Icons.refresh),
              label: Text('try_different_preferences'.tr),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
                side: BorderSide(color: AppColors.primaryBlue, width: 2),
              ),
            ),
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildSchoolCard(School school, {bool isAISuggested = false}) {
    final isSelected = _selectedSchoolForApplication?.id == school.id;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSchoolForApplication = school;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
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
                  height: 140.h,
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
                  ),
                  child: school.bannerImage != null || (school.media?.schoolImages?.isNotEmpty ?? false)
                      ? ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
                          child: Stack(
                            children: [
                              SafeNetworkImage(
                                imageUrl: school.bannerImage ?? school.media!.schoolImages!.first.url,
                                width: double.infinity,
                                height: 140.h,
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
                          borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
                          child: Container(
                            width: double.infinity,
                            height: 140.h,
                            color: Colors.white,
                            child: Padding(
                              padding: EdgeInsets.all(20.w),
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
                    top: 12.h,
                    right: 12.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryBlue,
                            AppColors.primaryBlue.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 14.sp,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'AI',
                            style: AppFonts.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Selection indicator
                if (isSelected)
                  Positioned(
                    top: 12.h,
                    right: 12.w,
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                  ),
              ],
            ),
            
            // Content
            Padding(
              padding: EdgeInsets.all(18.w),
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
                    SizedBox(height: 12.h),
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
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // Apply button when selected
                  if (isSelected) ...[
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitApplication,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          disabledBackgroundColor: AppColors.grey300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? SizedBox(
                                height: 22.h,
                                width: 22.h,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send_rounded, size: 18.sp),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'apply_now'.tr,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
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
