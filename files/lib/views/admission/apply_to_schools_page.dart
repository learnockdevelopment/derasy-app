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
          _allSchools = response.schools
              .where((school) => school.admissionOpen)
              .toList();
          _filteredSchools = _allSchools;
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
        'Please select a child first',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    if (_selectedSchools.isEmpty) {
      Get.snackbar(
        'error'.tr,
        'Please select at least one school',
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
        response.message,
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

      String errorMessage = 'Failed to apply. Please try again.';
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
          'Apply to Schools',
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
                          'Child: ${_selectedChild!.fullName}',
                          style: AppFonts.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Search Bar
          Padding(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              controller: _searchController,
              onChanged: _filterSchools,
              decoration: InputDecoration(
                hintText: 'Search schools...',
                prefixIcon: Icon(Icons.search, color: AppColors.primaryBlue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
            ),
          ),

          // Selected Schools Summary
          if (_selectedSchools.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              color: AppColors.success.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 20.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      '${_selectedSchools.length} school(s) selected',
                      style: AppFonts.bodyMedium.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  Text(
                    'Total: ${_calculateTotalFee()} EGP',
                    style: AppFonts.bodyMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
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
                              'No schools found',
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
                            margin: EdgeInsets.only(bottom: 12.h),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : AppColors.grey200,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _toggleSchoolSelection(school),
                                borderRadius: BorderRadius.circular(16.r),
                                child: Padding(
                                  padding: EdgeInsets.all(16.w),
                                  child: Row(
                                    children: [
                                      // Selection Checkbox
                                      Container(
                                        width: 24.w,
                                        height: 24.h,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.primaryBlue
                                                : AppColors.grey400,
                                            width: 2,
                                          ),
                                          color: isSelected
                                              ? AppColors.primaryBlue
                                              : Colors.transparent,
                                        ),
                                        child: isSelected
                                            ? Icon(Icons.check,
                                                size: 16.sp, color: Colors.white)
                                            : null,
                                      ),
                                      SizedBox(width: 12.w),
                                      // School Logo
                                      if (school.media?.schoolImages?.isNotEmpty == true ||
                                          school.bannerImage?.isNotEmpty == true)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8.r),
                                          child: SafeNetworkImage(
                                            imageUrl: school.media?.schoolImages?.isNotEmpty == true
                                                ? school.media!.schoolImages!.first.url
                                                : school.bannerImage ?? '',
                                            width: 50.w,
                                            height: 50.h,
                                            fit: BoxFit.cover,
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
                                                fontSize: 15.sp,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 4.h),
                                            if (school.location?.governorate != null)
                                              Row(
                                                children: [
                                                  Icon(Icons.location_on,
                                                      size: 12.sp,
                                                      color:
                                                          AppColors.textSecondary),
                                                  SizedBox(width: 4.w),
                                                  Text(
                                                    school.location!.governorate,
                                                    style:
                                                        AppFonts.bodySmall.copyWith(
                                                      color: AppColors.textSecondary,
                                                      fontSize: 12.sp,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            SizedBox(height: 4.h),
                                            Row(
                                              children: [
                                                Icon(Icons.payments,
                                                    size: 12.sp,
                                                    color: AppColors.primaryBlue),
                                                SizedBox(width: 4.w),
                                                Text(
                                                  '$admissionFee EGP',
                                                  style:
                                                      AppFonts.bodySmall.copyWith(
                                                    color: AppColors.primaryBlue,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12.sp,
                                                  ),
                                                ),
                                              ],
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
                          'Apply to ${_selectedSchools.length} School(s)',
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

