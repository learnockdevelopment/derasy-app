import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/controllers/dashboard_controller.dart';
import '../../models/student_models.dart';
import '../../models/school_models.dart';
import '../../models/admission_models.dart';
import '../../models/school_suggestion_models.dart';
import '../../services/admission_service.dart';
import '../../services/schools_service.dart';
import '../../services/user_storage_service.dart';
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
  
  // Selection for final submission
  final Set<School> _selectedSchools = {};
  bool _isFormVisible = false;

  // Form State
  String? _selectedGrade;
  final TextEditingController _notesController = TextEditingController();
  String _applicationType = 'new_student';
  final List<InterviewSlot> _preferredInterviewSlots = [];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

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
        _applicationType = (_selectedChild?.schoolId.id.isNotEmpty ?? false) ? 'transfer' : 'new_student';
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
          _applicationType = (_selectedChild?.schoolId.id.isNotEmpty ?? false) ? 'transfer' : 'new_student';
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

    if (_selectedGrade == null || _selectedGrade!.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'please_select_grade'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    int successCount = 0;
    String lastError = '';

    try {
      // First, update the child's desiredGrade if it's different
      if (_selectedGrade != null && _selectedGrade!.isNotEmpty) {
        try {
          print('📝 [APPLY] Updating child desiredGrade to: $_selectedGrade');
          final updateUrl = '${ApiConstants.baseUrl}${ApiConstants.getRelatedChildrenEndpoint}/${_selectedChild!.id}';
          final token = UserStorageService.getAuthToken();
          
          if (token != null) {
            final updateResponse = await http.put(
              Uri.parse(updateUrl),
              headers: ApiConstants.getAuthHeaders(token),
              body: jsonEncode({
                'desiredGrade': _selectedGrade,
              }),
            );
            
            print('📝 [APPLY] Update response: ${updateResponse.statusCode}');
            if (updateResponse.statusCode == 200) {
              print('✅ [APPLY] Child desiredGrade updated successfully');
            }
          }
        } catch (e) {
          print('⚠️ [APPLY] Failed to update child desiredGrade: $e');
          // Continue anyway - this is not critical
        }
      }

      // Now submit applications for each selected school
      for (final school in _selectedSchools) {
        try {
          final request = AdmissionApplyRequest(
            childId: _selectedChild!.id,
            schoolId: school.id,
            applicationType: _applicationType,
            desiredGrade: _selectedGrade,
            preferredInterviewSlots: _preferredInterviewSlots,
            notes: _notesController.text.trim(),
          );

          await AdmissionService.applyAdmission(request);
          successCount++;
        } catch (e) {
          lastError = e.toString();
          print('❌ [APPLY] Error applying to ${school.name}: $e');
        }
      }

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      if (successCount > 0) {
        Get.snackbar(
          'success'.tr,
          successCount == _selectedSchools.length 
              ? 'applications_submitted_successfully'.tr 
              : 'some_applications_submitted_successfully'.tr,
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
    // Determine if it's a transfer or new application
    final isTransfer = _selectedChild?.schoolId.id.isNotEmpty == true;
    final title = isTransfer ? 'transfer_to_school'.tr : 'apply_to_school'.tr;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: AppFonts.h4.copyWith(color: Colors.white, fontSize: Responsive.sp(16))),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        centerTitle: false,
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
                    onPressed: _isSubmitting ? null : (_isFormVisible ? _submitApplication : () {
                      setState(() {
                        _isFormVisible = true;
                      });
                    }),
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
                              Icon(_isFormVisible ? Icons.send_rounded : Icons.arrow_forward_rounded, size: 18.sp, color: Colors.white),
                              SizedBox(width: Responsive.w(12)),
                              Text(
                                _isFormVisible ? 'submit_applications'.tr : 'continue_to_details'.tr,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: Responsive.sp(14),
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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      color: AppColors.primaryBlue.withOpacity(0.05),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, color: AppColors.primaryBlue, size: Responsive.sp(18)),
          ),
          SizedBox(width: Responsive.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedChild!.arabicFullName ?? _selectedChild!.fullName,
                  style: AppFonts.h4.copyWith(color: AppColors.textPrimary, fontSize: Responsive.sp(14)),
                ),
                if (_selectedChild!.schoolId.id.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Text(
                      '${'current_school_colon'.tr} ${_selectedChild!.schoolId.name}',
                      style: AppFonts.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: Responsive.sp(11)),
                    ),
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
    if (_isFormVisible && _selectedSchools.isNotEmpty) {
      return _buildAdmissionForm();
    }

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
              padding: Responsive.all(16),
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
                      Icon(Icons.auto_awesome, color: AppColors.primaryBlue, size: 20.sp),
                      SizedBox(width: Responsive.w(8)),
                      Text(
                        'ai_analysis_result'.tr,
                        style: AppFonts.h4.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: Responsive.sp(14),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  MarkdownBody(
                    data: _aiResponse!.markdown ?? _aiResponse!.message,
                    styleSheet: MarkdownStyleSheet(
                      p: AppFonts.bodySmall.copyWith(fontSize: Responsive.sp(11)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.h(16)),
          ],

          // Selection Progress Hint 
          Container(
            padding: Responsive.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _selectedSchools.isNotEmpty
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  _selectedSchools.isNotEmpty
                      ? AppColors.success.withOpacity(0.05)
                      : AppColors.warning.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(Responsive.r(16)),
              border: Border.all(
                color: _selectedSchools.isNotEmpty
                    ? AppColors.success.withOpacity(0.3)
                    : AppColors.warning.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _selectedSchools.isNotEmpty
                      ? Icons.check_circle_rounded
                      : Icons.info_rounded,
                  color: _selectedSchools.isNotEmpty ? AppColors.success : AppColors.warning,
                  size: Responsive.sp(18),
                ),
                SizedBox(width: Responsive.w(12)),
                Expanded(
                  child: Text(
                    _selectedSchools.isNotEmpty
                        ? '${_selectedSchools.length} ${'schools_selected_tap_to_continue'.tr}'
                        : 'select_up_to_3_schools_to_continue'.tr,
                    style: AppFonts.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.sp(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // AI Suggested Schools Section
          if (_suggestedSchools.isNotEmpty) ...[ 
            Row(
              children: [
                Icon(Icons.stars, color: AppColors.primaryBlue, size: Responsive.sp(18)),
                SizedBox(width: Responsive.w(8)),
                Text(
                  'ai_suggested_schools'.tr,
                  style: AppFonts.h4.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.sp(12),
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.h(10)),
            ..._suggestedSchools.map((school) => _buildSchoolCard(school, isAISuggested: true)).toList(),
            SizedBox(height: Responsive.h(16)),
          ],

          // Search Bar for Schools
          Container(
            margin: EdgeInsets.only(bottom: Responsive.h(16)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(Responsive.r(12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
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
              style: TextStyle(fontSize: Responsive.sp(12)),
              decoration: InputDecoration(
                hintText: 'search_schools_hint'.tr,
                hintStyle: TextStyle(fontSize: Responsive.sp(12)),
                prefixIcon: Icon(Icons.search, color: AppColors.primaryBlue, size: Responsive.sp(20)),
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
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: Responsive.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),

          // Other Schools Section
          if (filteredOtherSchools.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.school, color: AppColors.textSecondary, size: Responsive.sp(18)),
                SizedBox(width: Responsive.w(8)),
                Text(
                  'other_schools'.tr,
                  style: AppFonts.h4.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.sp(12),
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.h(10)),
            ...filteredOtherSchools.map((school) => _buildSchoolCard(school, isAISuggested: false)).toList(),
          ],
          
          if (_suggestedSchools.isEmpty && filteredOtherSchools.isEmpty)
            Center(
              child: Padding(
                padding: Responsive.all(40),
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: Responsive.sp(48), color: AppColors.grey400),
                    SizedBox(height: Responsive.h(12)),
                    Text(
                      'no_schools_match_preferences'.tr,
                      style: AppFonts.bodySmall.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
             
          SizedBox(height: 16.h),
          
          // Retry Button
          Center(
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _showResults = false;
                  _selectedSchools.clear();
                });
              },
              icon: Icon(Icons.refresh, size: 16.sp),
              label: Text('try_different_preferences'.tr, style: TextStyle(fontSize: Responsive.sp(12))),
              style: OutlinedButton.styleFrom(
                padding: Responsive.symmetric(horizontal: 16, vertical: 10),
                side: BorderSide(color: AppColors.primaryBlue),
              ),
            ),
          ),
          SizedBox(height: Responsive.h(24)),
        ],
      ),
    );
  }

  Widget _buildAdmissionForm() {
    return SingleChildScrollView(
      padding: Responsive.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _isFormVisible = false),
                icon: const Icon(Icons.arrow_back),
              ),
              Text(
                'admission_details'.tr,
                style: AppFonts.h3.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(20)),
          
          // School Info Card
          Column(
            children: _selectedSchools.map((school) => Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: Responsive.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(Responsive.r(12)),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(Responsive.r(8)),
                  child: SafeNetworkImage(
                    imageUrl: school.bannerImage,
                    width: Responsive.w(32),
                    height: Responsive.w(32),
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
                      Text(
                        school.location?.city ?? '',
                        style: AppFonts.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: Responsive.sp(10)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
          ),
          SizedBox(height: Responsive.h(20)),

          // Application Type (Auto-determined)
          Text('application_type'.tr, style: AppFonts.h4.copyWith(fontSize: Responsive.sp(13))),
          SizedBox(height: Responsive.h(8)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(Responsive.r(12)),
              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  _applicationType == 'transfer' ? Icons.swap_horiz_rounded : Icons.person_add_rounded,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
                SizedBox(width: 12.w),
                Text(
                  _applicationType.tr,
                  style: AppFonts.bodyMedium.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'auto_determined'.tr,
                    style: AppFonts.bodySmall.copyWith(
                      color: AppColors.primaryBlue,
                      fontSize: 10.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: Responsive.h(20)),

          // Desired Grade
          Text('desired_grade'.tr, style: AppFonts.h4.copyWith(fontSize: Responsive.sp(13))),
          SizedBox(height: Responsive.h(8)),
          DropdownButtonFormField<String>(
            value: _selectedGrade,
            items: (_selectedSchools.firstOrNull?.gradesOffered ?? [])
                .map((grade) => DropdownMenuItem(
                      value: grade,
                      child: Text(grade, style: TextStyle(fontSize: Responsive.sp(13))),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedGrade = value),
            decoration: InputDecoration(
              hintText: 'please_select_grade'.tr,
              hintStyle: TextStyle(fontSize: Responsive.sp(13)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(Responsive.r(12))),
              contentPadding: Responsive.symmetric(horizontal: 16, vertical: 8),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          SizedBox(height: Responsive.h(20)),

          // Preferred Interview Slots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('preferred_interview_slots'.tr, style: AppFonts.h4.copyWith(fontSize: Responsive.sp(13))),
              TextButton.icon(
                onPressed: _addInterviewSlot,
                icon: const Icon(Icons.add, size: 16),
                label: Text('add'.tr, style: TextStyle(fontSize: Responsive.sp(12))),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          if (_preferredInterviewSlots.isEmpty)
             Text('no_slots_selected'.tr, style: AppFonts.bodySmall.copyWith(color: AppColors.textSecondary)),
          ..._preferredInterviewSlots.asMap().entries.map((entry) {
            final idx = entry.key;
            final slot = entry.value;
            return Card(
              margin: EdgeInsets.only(bottom: 8.h),
              child: ListTile(
                dense: true,
                title: Text('${slot.date.year}-${slot.date.month}-${slot.date.day}'),
                subtitle: Text('${slot.timeRange.from} - ${slot.timeRange.to}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.red50, size: 18),
                  onPressed: () => setState(() => _preferredInterviewSlots.removeAt(idx)),
                ),
              ),
            );
          }).toList(),
          SizedBox(height: Responsive.h(20)),

          // Notes
          Text('notes'.tr, style: AppFonts.h4.copyWith(fontSize: Responsive.sp(13))),
          SizedBox(height: Responsive.h(8)),
          TextField(
            controller: _notesController,
            maxLines: 2,
            style: TextStyle(fontSize: Responsive.sp(13)),
            decoration: InputDecoration(
              hintText: 'additional_notes'.tr,
              hintStyle: TextStyle(fontSize: Responsive.sp(13)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(Responsive.r(12))),
              contentPadding: Responsive.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          SizedBox(height: Responsive.h(40)),
        ],
      ),
    );
  }

  void _addInterviewSlot() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    
    if (date != null) {
      // For simplicity, just adding a default time range or opening a time picker
      // here I'll just use a simple mock time range for now
      setState(() {
        _preferredInterviewSlots.add(InterviewSlot(
          date: date,
          timeRange: TimeRange(from: '10:00 AM', to: '12:00 PM'),
        ));
      });
    }
  }

  Widget _buildSchoolCard(School school, {bool isAISuggested = false}) {
    final isSelected = _selectedSchools.any((s) => s.id == school.id);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedSchools.removeWhere((s) => s.id == school.id);
          } else {
            if (_selectedSchools.length < 3) {
              _selectedSchools.add(school);
            } else {
              Get.snackbar(
                'info'.tr,
                'max_3_schools_allowed'.tr,
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColors.primaryBlue,
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
              );
            }
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: Responsive.h(12)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Responsive.r(16)),
          border: Border.all(
            color: isSelected 
                ? AppColors.primaryBlue 
                : (isAISuggested ? AppColors.primaryBlue.withOpacity(0.3) : Colors.transparent),
            width: isSelected ? 2.5 : (isAISuggested ? 1.5 : 0),
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? AppColors.primaryBlue.withOpacity(0.15)
                  : (isAISuggested ? AppColors.primaryBlue.withOpacity(0.08) : Colors.black.withOpacity(0.04)),
              blurRadius: isSelected ? 15 : 10,
              offset: Offset(0, isSelected ? 6 : 3),
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
                  height: Responsive.h(110),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(Responsive.r(15))),
                  ),
                  child: school.bannerImage != null || (school.media?.schoolImages?.isNotEmpty ?? false)
                      ? ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(Responsive.r(15))),
                          child: Stack(
                            children: [
                              SafeNetworkImage(
                                imageUrl: school.bannerImage ?? school.media!.schoolImages!.first.url,
                                width: double.infinity,
                                height: Responsive.h(110),
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
                                      Colors.black.withOpacity(0.25),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(Responsive.r(15))),
                          child: Container(
                            width: double.infinity,
                            height: Responsive.h(110),
                            color: Colors.white,
                            child: Padding(
                              padding: Responsive.all(12),
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
                      padding: Responsive.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryBlue,
                            AppColors.primaryBlue.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(Responsive.r(12)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: Responsive.sp(12),
                            color: Colors.white,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'AI',
                            style: AppFonts.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: Responsive.sp(10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Selection indicator
                if (isSelected)
                  Positioned(
                    top: Responsive.h(10),
                    right: Responsive.w(10),
                    child: Container(
                      padding: Responsive.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: Responsive.sp(16),
                      ),
                    ),
                  ),
              ],
            ),
            
            // Content
            Padding(
              padding: Responsive.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // School name
                  Text(
                    school.name,
                    style: AppFonts.h4.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  
                  // Tags and info
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 6.h,
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
                    SizedBox(height: Responsive.h(10)),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.payments_outlined,
                            size: 16.sp,
                            color: AppColors.success,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '${school.admissionFee!.amount} ${'egp'.tr}',
                            style: AppFonts.bodyMedium.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                              fontSize: Responsive.sp(12),
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
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            text,
            style: AppFonts.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }

}
