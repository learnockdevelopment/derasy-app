import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../models/student_models.dart';
import '../../models/school_models.dart';
import '../../models/admission_models.dart';
import '../../services/admission_service.dart';
import '../../services/schools_service.dart';
import '../../services/students_service.dart';
import '../../core/routes/app_routes.dart';
import '../../../widgets/safe_network_image.dart';
import '../../../widgets/shimmer_loading.dart';

class ApplyToSchoolsPage extends StatefulWidget {
  const ApplyToSchoolsPage({Key? key}) : super(key: key);

  @override
  State<ApplyToSchoolsPage> createState() => _ApplyToSchoolsPageState();
}

class _ApplyToSchoolsPageState extends State<ApplyToSchoolsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<School> _allSchools = [];
  List<School> _filteredSchools = [];
  List<School> _selectedSchools = [];
  Student? _selectedChild;
  bool _isLoadingSchools = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadArguments();
    _loadSchools();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadArguments() {
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args['child'] != null) {
      setState(() {
        _selectedChild = args['child'] as Student;
      });
    }
  }

  Future<void> _loadSchools() async {
    setState(() {
      _isLoadingSchools = true;
    });

    try {
      final response = await SchoolsService.getAllSchools();
      if (mounted) {
        setState(() {
          // Get ALL schools without filtering by admissionOpen
          _allSchools = response.schools;
          _filteredSchools = _allSchools;
          _isLoadingSchools = false;
        });
        print('🏫 [APPLY_TO_SCHOOLS] Loaded ${_allSchools.length} schools (all schools)');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSchools = false;
        });
      }
      Get.snackbar(
        'error'.tr,
        'Failed to load schools: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  void _filterSchools(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSchools = _allSchools;
      } else {
        _filteredSchools = _allSchools
            .where((school) =>
                school.name.toLowerCase().contains(query.toLowerCase()) ||
                (school.location?.governorate ?? '')
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _toggleSchoolSelection(School school) {
    setState(() {
      if (_selectedSchools.any((s) => s.id == school.id)) {
        _selectedSchools.removeWhere((s) => s.id == school.id);
      } else {
        _selectedSchools.add(school);
      }
    });
  }

  Future<void> _submitApplication() async {
    if (_selectedChild == null) {
      Get.snackbar(
        'error'.tr,
        'please_select_child_first'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    if (_selectedSchools.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'please_select_at_least_one_school'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    // Check if child already has a school (transfer mode)
    final isTransfer = _selectedChild!.schoolId.id.isNotEmpty;
    
    // For transfer, only allow selecting one school
    if (isTransfer && _selectedSchools.length > 1) {
      Get.snackbar(
        'error'.tr,
        'please_select_only_one_school_for_transfer'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final request = ApplyToSchoolsRequest(
        childId: _selectedChild!.id,
        selectedSchools: _selectedSchools
            .map((school) => SelectedSchool.fromSchool(school))
            .toList(),
      );

      final response = await AdmissionService.applyToSchools(request);

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      Get.snackbar(
        'success'.tr,
        isTransfer 
            ? 'transfer_request_submitted_successfully'.tr
            : response.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Navigate to applications page
      Get.offNamed(AppRoutes.applications);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      String errorMessage = isTransfer 
          ? 'failed_to_transfer'.tr
          : 'failed_to_apply'.tr;
      if (e is AdmissionException) {
        errorMessage = e.message;
      }

      Get.snackbar(
        'error'.tr,
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
          onPressed: () => Get.back(),
        ),
        title: Text(
          _selectedChild != null && _selectedChild!.schoolId.id.isNotEmpty
              ? 'transfer_to_school'.tr
              : 'apply_to_schools'.tr,
          style: AppFonts.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: Column(
        children: [
          // Selected Child Info
          if (_selectedChild != null)
            Column(
              children: [
            Container(
              padding: EdgeInsets.all(16.w),
              color: AppColors.primaryBlue.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.child_care, color: AppColors.primaryBlue, size: 24.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                              '${'child_colon'.tr}: ${_selectedChild!.fullName}',
                          style: AppFonts.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                            if (_selectedChild!.schoolId.id.isNotEmpty) ...[
                              SizedBox(height: 4.h),
                              Text(
                                '${'current_school_colon'.tr}: ${_selectedChild!.schoolId.name}',
                                style: AppFonts.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
                if (_selectedChild!.schoolId.id.isNotEmpty)
                  Container(
                    padding: EdgeInsets.all(12.w),
                    color: AppColors.warning.withOpacity(0.1),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.warning, size: 18.sp),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            'this_will_transfer_your_child'.tr,
                            style: AppFonts.bodySmall.copyWith(
                              color: AppColors.warning,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

          // Modern Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.primaryBlue.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterSchools,
                style: AppFonts.bodyMedium.copyWith(fontSize: 13.sp),
              decoration: InputDecoration(
                  hintText: 'search_schools_placeholder'.tr,
                  hintStyle: AppFonts.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13.sp,
                  ),
                  prefixIcon: Container(
                    padding: EdgeInsets.all(10.w),
                    child: Icon(Icons.search, color: AppColors.primaryBlue, size: 20.sp),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                ),
              ),
            ),
          ),

          // Modern Selected Schools Summary
          if (_selectedSchools.isNotEmpty)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.success.withOpacity(0.15),
                    AppColors.success.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
              color: AppColors.success.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.check_circle, color: AppColors.success, size: 18.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_selectedSchools.length} ${_selectedSchools.length == 1 ? 'school'.tr : 'schools'.tr} ${'selected'.tr}',
                      style: AppFonts.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '${'total_colon'.tr} ${_calculateTotalFee()} EGP',
                          style: AppFonts.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                            fontSize: 12.sp,
                      ),
                    ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Schools List
          Expanded(
            child: _isLoadingSchools
                ? ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      return ShimmerCard(
                        height: 120.h,
                        margin: EdgeInsets.only(bottom: 16.h),
                      );
                    },
                  )
                : _filteredSchools.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.school_outlined,
                                size: 64.sp, color: AppColors.textSecondary),
                            SizedBox(height: 16.h),
                            Text(
                              'no_schools_found'.tr,
                              style: AppFonts.h4.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16.w),
                        itemCount: _filteredSchools.length,
                        itemBuilder: (context, index) {
                          final school = _filteredSchools[index];
                          final isSelected =
                              _selectedSchools.any((s) => s.id == school.id);
                          final admissionFee = school.admissionFee?.amount ?? 0.0;

                          return Container(
                            margin: EdgeInsets.only(bottom: 10.h),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [
                                        AppColors.primaryBlue.withOpacity(0.1),
                                        AppColors.primaryBlue.withOpacity(0.05),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isSelected ? null : AppColors.surface,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : AppColors.grey200,
                                width: isSelected ? 2.5 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? AppColors.primaryBlue.withOpacity(0.2)
                                      : Colors.black.withOpacity(0.04),
                                  blurRadius: isSelected ? 12 : 8,
                                  offset: Offset(0, isSelected ? 6 : 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _toggleSchoolSelection(school),
                                borderRadius: BorderRadius.circular(16.r),
                                child: Padding(
                                  padding: EdgeInsets.all(14.w),
                                  child: Row(
                                    children: [
                                      // Modern Selection Checkbox
                                      Container(
                                        width: 22.w,
                                        height: 22.h,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: isSelected
                                              ? LinearGradient(
                                                  colors: [
                                                    AppColors.primaryBlue,
                                                    AppColors.primaryBlue.withOpacity(0.8),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                )
                                              : null,
                                          color: isSelected ? null : Colors.transparent,
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.primaryBlue
                                                : AppColors.grey400,
                                            width: 2.5,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: AppColors.primaryBlue.withOpacity(0.4),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: isSelected
                                            ? Icon(Icons.check,
                                                size: 14.sp, color: Colors.white)
                                            : null,
                                      ),
                                      SizedBox(width: 12.w),
                                      // School Logo with modern design
                                      if (school.media?.schoolImages?.isNotEmpty == true ||
                                          school.bannerImage?.isNotEmpty == true)
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12.r),
                                            border: Border.all(
                                              color: AppColors.primaryBlue.withOpacity(0.2),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.08),
                                                blurRadius: 6,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12.r),
                                          child: SafeNetworkImage(
                                            imageUrl: school.media?.schoolImages?.isNotEmpty == true
                                                ? school.media!.schoolImages!.first.url
                                                : school.bannerImage ?? '',
                                              width: 56.w,
                                              height: 56.h,
                                            fit: BoxFit.cover,
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          width: 56.w,
                                          height: 56.h,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppColors.primaryBlue.withOpacity(0.2),
                                                AppColors.primaryBlue.withOpacity(0.1),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(12.r),
                                            border: Border.all(
                                              color: AppColors.primaryBlue.withOpacity(0.3),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.school_rounded,
                                            color: AppColors.primaryBlue,
                                            size: 28.sp,
                                          ),
                                        ),
                                      SizedBox(width: 12.w),
                                      // School Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              school.name,
                                              style: AppFonts.h4.copyWith(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.sp,
                                                letterSpacing: 0.2,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 6.h),
                                            if (school.location?.governorate != null)
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryBlue.withOpacity(0.08),
                                                  borderRadius: BorderRadius.circular(6.r),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.location_on,
                                                        size: 11.sp,
                                                        color: AppColors.primaryBlue),
                                                    SizedBox(width: 3.w),
                                                  Text(
                                                    school.location!.governorate,
                                                      style: AppFonts.bodySmall.copyWith(
                                                        color: AppColors.primaryBlue,
                                                        fontSize: 10.sp,
                                                        fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              ),
                                            if (school.location?.governorate != null) SizedBox(height: 4.h),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    AppColors.success.withOpacity(0.15),
                                                    AppColors.success.withOpacity(0.08),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(6.r),
                                                border: Border.all(
                                                  color: AppColors.success.withOpacity(0.3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.payments,
                                                      size: 11.sp,
                                                      color: AppColors.success),
                                                  SizedBox(width: 3.w),
                                                Text(
                                                  '$admissionFee EGP',
                                                    style: AppFonts.bodySmall.copyWith(
                                                      color: AppColors.success,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 10.sp,
                                                  ),
                                                ),
                                              ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Submit Button
          if (_selectedSchools.isNotEmpty)
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50.h,
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
                          height: 20.h,
                          width: 20.w,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _selectedChild != null && _selectedChild!.schoolId.id.isNotEmpty
                              ? '${'transfer_to'.tr} ${_selectedSchools.length} ${'school_s'.tr}'
                              : '${'apply_to'.tr} ${_selectedSchools.length} ${'school_s'.tr}',
                          style: AppFonts.h4.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _calculateTotalFee() {
    double total = 0.0;
    // Only count the highest fee as per API documentation
    if (_selectedSchools.isNotEmpty) {
      final sorted = List<School>.from(_selectedSchools)
        ..sort((a, b) =>
            (b.admissionFee?.amount ?? 0.0)
                .compareTo(a.admissionFee?.amount ?? 0.0));
      total = sorted.first.admissionFee?.amount ?? 0.0;
    }
    return total;
  }
}

