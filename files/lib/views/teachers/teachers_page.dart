import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/assets.dart';
import '../../services/teachers_service.dart';
import '../../models/school_models.dart';
import '../../services/schools_service.dart';
import '../../services/grades_service.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/safe_network_image.dart';
import 'package:iconly/iconly.dart';

class TeachersPage extends StatefulWidget {
  const TeachersPage({Key? key}) : super(key: key);

  @override
  State<TeachersPage> createState() => _TeachersPageState();
}

class _TeachersPageState extends State<TeachersPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Teacher> _teachers = [];
  List<Teacher> _filteredTeachers = [];
  bool _isLoading = false;
  String? _schoolId;
  School? _selectedSchool;
  String _searchQuery = '';
  Timer? _debounceTimer;
  List<School> _schools = [];
  // Filter state
  String? _selectedGradeId;
  String? _selectedClassId;
  List<Grade> _grades = [];
  List<String> _classes = [];

  @override
  void initState() {
    super.initState();
    // Get schoolId from arguments if provided
    final args = Get.arguments as Map<String, dynamic>?;
    _schoolId = args?['schoolId'];
    _loadSchools();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSchools() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }
      final response = await SchoolsService.getAllSchools();
      setState(() {
        _schools = response.schools;
        if (_schoolId == null && _schools.isNotEmpty) {
          _schoolId = _schools.first.id;
          _selectedSchool = _schools.first;
        } else if (_schoolId != null) {
          _selectedSchool = _schools.firstWhere(
            (s) => s.id == _schoolId,
            orElse: () => _schools.first,
          );
        }
      });
      if (_schoolId != null) {
        await _loadGrades();
        await _loadTeachers();
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadGrades() async {
    if (_schoolId == null) return;
    try {
      final response = await GradesService.getAllGrades(_schoolId!);
      if (mounted) {
        setState(() {
          _grades = response.grades;
        });
      }
    } catch (e) {
      print('Failed to load grades: $e');
    }
  }

  Future<void> _loadTeachers() async {
    if (_schoolId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await TeachersService.getAllTeachers(_schoolId!);

      if (mounted) {
        setState(() {
          _teachers = response.teachers;
          _filteredTeachers = _applyFilters(_teachers);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      Get.snackbar(
        'error'.tr,
        'failed_to_load_teachers'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    }
  }

  List<Teacher> _applyFilters(List<Teacher> teachers) {
    var filtered = teachers;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((teacher) =>
          teacher.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (teacher.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (teacher.subject?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }

    // Apply grade filter (if teachers have grade info)
    if (_selectedGradeId != null) {
      // This would need to be implemented based on teacher model
    }

    // Apply class filter (if teachers have class info)
    if (_selectedClassId != null) {
      // This would need to be implemented based on teacher model
    }

    return filtered;
  }

  void _filterTeachers(String query) {
    if (mounted) {
      setState(() {
        _searchQuery = query;
        _filteredTeachers = _applyFilters(_teachers);
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _filterTeachers('');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: Stack(
        children: [
          // Gradient Header BG
          Container(
            height: 180.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue.withOpacity(0.95),
                  AppColors.primaryBlue.withOpacity(0.85),
                  AppColors.primaryBlue.withOpacity(0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // PAGE BODY
          SafeArea(
            child: Column(
              children: [
                // TopBar: title + buttons
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Spacer(),
                          Text('school_follow'.tr, style: AppFonts.h2.copyWith(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: AppFonts.size20)),
                          const Spacer(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Bus Button
                              Container(
                                margin: EdgeInsets.only(right: 8.w),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => Get.toNamed(AppRoutes.buses),
                                    borderRadius: BorderRadius.circular(12.r),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(IconlyBold.discovery, color: Colors.white, size: 18.sp),
                                          SizedBox(width: 6.w),
                                          Text(
                                            'buses'.tr,
                                            style: AppFonts.bodyMedium.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Refresh Button
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  shape: const CircleBorder(),
                                  child: IconButton(
                                    icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                                    tooltip: 'refresh'.tr,
                                    onPressed: () => _loadTeachers(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      // Search bar and filter buttons
                      Row(
                        children: [
                          Expanded(
                            child: Material(
                              elevation: 6,
                              borderRadius: BorderRadius.circular(12.r),
                              color: Colors.white.withOpacity(0.95),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12.w),
                                height: 42.h,
                                child: Center(
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: _filterTeachers,
                                    style: AppFonts.bodyMedium.copyWith(fontSize: AppFonts.size14),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'search_teachers'.tr,
                                      hintStyle: TextStyle(color: const Color(0xFF7F7FD5).withOpacity(0.7), fontSize: 14.sp),
                                      prefixIcon: Icon(Icons.search, color: const Color(0xFF7F7FD5), size: 20),
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? GestureDetector(
                                              child: Icon(Icons.clear, color: const Color(0xFF7F7FD5), size: 18),
                                              onTap: _clearSearch,
                                            )
                                          : null,
                                      contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          // Filter button
                          Material(
                            elevation: 6,
                            borderRadius: BorderRadius.circular(12.r),
                            color: Colors.white.withOpacity(0.95),
                            child: InkWell(
                              onTap: _showFilterModal,
                              borderRadius: BorderRadius.circular(12.r),
                              child: Container(
                                width: 42.w,
                                height: 42.h,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Icon(
                                        Icons.filter_list_rounded,
                                        color: (_selectedGradeId != null || _selectedClassId != null)
                                            ? AppColors.primaryBlue
                                            : const Color(0xFF7F7FD5),
                                        size: 22.sp,
                                      ),
                                    ),
                                    if (_selectedGradeId != null || _selectedClassId != null)
                                      Positioned(
                                        right: 6,
                                        top: 6,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryBlue,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          // School filter button
                          Material(
                            elevation: 6,
                            borderRadius: BorderRadius.circular(12.r),
                            color: Colors.white.withOpacity(0.95),
                            child: InkWell(
                              onTap: _showSchoolFilterModal,
                              borderRadius: BorderRadius.circular(12.r),
                              child: Container(
                                width: 42.w,
                                height: 42.h,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: _selectedSchool != null && _getSchoolImageUrl(_selectedSchool!) != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12.r),
                                        child: SafeSchoolImage(
                                          imageUrl: _getSchoolImageUrl(_selectedSchool!),
                                          width: 42.w,
                                          height: 42.h,
                                        ),
                                      )
                                    : Icon(
                                        Icons.school_rounded,
                                        color: const Color(0xFF7F7FD5),
                                        size: 22.sp,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                // BODY: Teachers List
                Expanded(
                  child: _isLoading
                      ? ListView.builder(
                          itemCount: 10,
                          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 9.h),
                          itemBuilder: (c, i) {
                            return const ShimmerListTile(padding: null);
                          },
                        )
                      : _filteredTeachers.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: () => _loadTeachers(),
                              color: const Color(0xFF7F7FD5),
                              child: ListView.separated(
                                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 9.h),
                                itemCount: _filteredTeachers.length,
                                separatorBuilder: (_, __) => SizedBox(height: 8.h),
                                itemBuilder: (ctx, idx) => _buildTeacherCard(_filteredTeachers[idx]),
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


  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(top: 30.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100.w,
              height: 100.h,
              child: SvgPicture.asset(AssetsManager.emptySvg, fit: BoxFit.contain),
            ),
            SizedBox(height: 20.h),
            Text(
              _searchQuery.isNotEmpty ? 'no_teachers_found'.tr : 'no_teachers_available'.tr,
              style: AppFonts.h3.copyWith(
                color: const Color(0xFF374151),
                fontWeight: FontWeight.w700,
                
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: 7.h),
            Text(
              _searchQuery.isNotEmpty
                  ? 'try_adjusting_search_terms'.tr
                  : 'teachers_will_appear_here_once_added'.tr,
              style: AppFonts.bodyMedium.copyWith(
                color: const Color(0xFF6B7280),
                
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherCard(Teacher teacher) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.r),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.06),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () {
          Get.toNamed(AppRoutes.teacherDetails, arguments: {
            'teacher': teacher,
            'schoolId': _schoolId,
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            color: const Color(0xFF10B981).withOpacity(0.1),
          ),
          child: Row(
            children: [
              // AVATAR
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              // INFO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      teacher.name,
                      style: AppFonts.bodyLarge.copyWith(
                        color: const Color(0xFF1F2937),
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    if (teacher.subject != null && teacher.subject!.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        child: Text(
                          teacher.subject!,
                          style: AppFonts.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Edit Button (Admin/Moderator only)
              SizedBox(width: 8.w),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: const Color(0xFF9CA3AF),
                size: 14.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _getSchoolImageUrl(School school) {
    if (school.visibilitySettings?.officialLogo?.url.isNotEmpty == true) {
      return school.visibilitySettings!.officialLogo!.url;
    } else if (school.media?.schoolImages?.isNotEmpty == true) {
      return school.media!.schoolImages!.first.url;
    } else if (school.bannerImage?.isNotEmpty == true) {
      return school.bannerImage;
    }
    return null;
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'filters'.tr,
                    style: AppFonts.h3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      
                    ),
                  ),
                  const Spacer(),
                  if (_selectedGradeId != null || _selectedClassId != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedGradeId = null;
                          _selectedClassId = null;
                        });
                        Get.back();
                        _filteredTeachers = _applyFilters(_teachers);
                      },
                      child: Text(
                        'clear_all'.tr,
                        style: AppFonts.bodyMedium.copyWith(
                          color: AppColors.primaryBlue,
                          
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280)),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            // Filter Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grade Filter
                    Text(
                      'grade'.tr,
                      style: AppFonts.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGradeId,
                          isExpanded: true,
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          hint: Text(
                            'select_grade'.tr,
                            style: AppFonts.bodyMedium.copyWith(
                              color: const Color(0xFF9CA3AF),
                              
                            ),
                          ),
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text(
                                'all_grades'.tr,
                                style: AppFonts.bodyMedium.copyWith(fontSize: 14.sp),
                              ),
                            ),
                            ..._grades.map((grade) => DropdownMenuItem<String>(
                              value: grade.id,
                              child: Text(
                                grade.name,
                                style: AppFonts.bodyMedium.copyWith(fontSize: 14.sp),
                              ),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedGradeId = value;
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    // Class Filter
                    Text(
                      'class'.tr,
                      style: AppFonts.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedClassId,
                          isExpanded: true,
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          hint: Text(
                            'select_class'.tr,
                            style: AppFonts.bodyMedium.copyWith(
                              color: const Color(0xFF9CA3AF),
                              
                            ),
                          ),
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text(
                                'all_classes'.tr,
                                style: AppFonts.bodyMedium.copyWith(fontSize: 14.sp),
                              ),
                            ),
                            ..._classes.map((cls) => DropdownMenuItem<String>(
                              value: cls,
                              child: Text(
                                cls,
                                style: AppFonts.bodyMedium.copyWith(fontSize: 14.sp),
                              ),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedClassId = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Apply Button
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    setState(() {
                      _filteredTeachers = _applyFilters(_teachers);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'apply_filters'.tr,
                    style: AppFonts.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      
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

  void _showSchoolFilterModal() {
    if (_schools.isEmpty) {
      Get.snackbar('error'.tr, 'no_schools_available'.tr, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'select_school'.tr,
                    style: AppFonts.h3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280)),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            // Schools List
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.all(16.w),
                itemCount: _schools.length,
                separatorBuilder: (_, __) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final school = _schools[index];
                  final isSelected = _schoolId == school.id;
                  final imageUrl = _getSchoolImageUrl(school);

                  return Material(
                    color: isSelected
                        ? AppColors.primaryBlue.withOpacity(0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    child: InkWell(
                      onTap: () async {
                        Get.back();
                        if (school.id != _schoolId) {
                          setState(() {
                            _schoolId = school.id;
                            _selectedSchool = school;
                            _teachers.clear();
                            _filteredTeachers.clear();
                          });
                          await _loadGrades();
                          await _loadTeachers();
                        }
                      },
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryBlue
                                : const Color(0xFFE5E7EB),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // School Image/Icon
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10.r),
                              child: Container(
                                width: 48.w,
                                height: 48.h,
                                child: imageUrl != null
                                    ? SafeSchoolImage(
                                        imageUrl: imageUrl,
                                        width: 48.w,
                                        height: 48.h,
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF1E3A8A),
                                              Color(0xFF3B82F6),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.school_rounded,
                                          color: Colors.white,
                                          size: 24.sp,
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            // School Name
                            Expanded(
                              child: Text(
                                school.name,
                                style: AppFonts.bodyLarge.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            // Selected Indicator
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primaryBlue,
                                size: 24.sp,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

