import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/assets.dart';
import '../../services/classes_service.dart';
import '../../models/school_models.dart';
import '../../services/schools_service.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/safe_network_image.dart';

class ClassesPage extends StatefulWidget {
  const ClassesPage({Key? key}) : super(key: key);

  @override
  State<ClassesPage> createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  final TextEditingController _searchController = TextEditingController();
  List<SchoolClass> _classes = [];
  List<SchoolClass> _filteredClasses = [];
  bool _isLoading = false;
  String? _schoolId;
  School? _selectedSchool;
  String _searchQuery = '';
  Timer? _debounceTimer;
  List<School> _schools = [];

  @override
  void initState() {
    super.initState();
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
        await _loadClasses();
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

  Future<void> _loadClasses() async {
    if (_schoolId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ClassesService.getAllClasses(_schoolId!);
      if (mounted) {
        setState(() {
          _classes = response.classes;
          _filteredClasses = List.from(_classes)
            ..sort((a, b) {
              // Sort by grade first, then by class name
              final gradeA = a.grade?.name ?? '';
              final gradeB = b.grade?.name ?? '';
              final gradeCompare = gradeA.compareTo(gradeB);
              if (gradeCompare != 0) return gradeCompare;
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            });
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
        'failed_to_load_classes'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    }
  }

  void _filterClasses(String query) {
    if (mounted) {
      setState(() {
        _searchQuery = query;
        if (query.isEmpty) {
          _filteredClasses = List.from(_classes)
            ..sort((a, b) {
              final gradeA = a.grade?.name ?? '';
              final gradeB = b.grade?.name ?? '';
              final gradeCompare = gradeA.compareTo(gradeB);
              if (gradeCompare != 0) return gradeCompare;
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            });
        } else {
          _filteredClasses = _classes
              .where((cls) =>
                  cls.name.toLowerCase().contains(query.toLowerCase()) ||
                  (cls.grade?.name ?? '').toLowerCase().contains(query.toLowerCase()))
              .toList()
            ..sort((a, b) {
              final gradeA = a.grade?.name ?? '';
              final gradeB = b.grade?.name ?? '';
              final gradeCompare = gradeA.compareTo(gradeB);
              if (gradeCompare != 0) return gradeCompare;
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            });
        }
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _filterClasses('');
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: Stack(
        children: [
          // Gradient Header BG
          Container(
            height: 140.h,
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
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                            onPressed: () => Get.back(),
                            splashRadius: 23,
                          ),
                          const Spacer(),
                          Text('classes'.tr, style: AppFonts.h2.copyWith(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20.sp)),
                          const Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28.r),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryBlue.withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  shape: const CircleBorder(),
                                  child: IconButton(
                                    icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 23),
                                    tooltip: 'refresh'.tr,
                                    onPressed: () => _loadClasses(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      // Search bar and school filter
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
                                    onChanged: _filterClasses,
                                    style: AppFonts.bodyMedium.copyWith(fontSize: 14.sp),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'search_classes'.tr,
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
                // BODY: Classes List
                Expanded(
                  child: _isLoading
                      ? ListView.builder(
                          itemCount: 10,
                          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 9.h),
                          itemBuilder: (c, i) {
                            return const ShimmerListTile(padding: null);
                          },
                        )
                      : _filteredClasses.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: () => _loadClasses(),
                              color: const Color(0xFF7F7FD5),
                              child: ListView.separated(
                                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 9.h),
                                itemCount: _filteredClasses.length,
                                separatorBuilder: (_, __) => SizedBox(height: 12.h),
                                itemBuilder: (ctx, idx) => _buildClassCard(_filteredClasses[idx]),
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
              _searchQuery.isNotEmpty ? 'no_classes_found'.tr : 'no_classes_available'.tr,
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
                  : 'classes_will_appear_here_once_added'.tr,
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

  Widget _buildClassCard(SchoolClass schoolClass) {
    final studentsInClass = schoolClass.studentCount ?? 0;
    
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.06),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () {
          Get.toNamed(AppRoutes.classDetails, arguments: {
            'schoolId': _schoolId,
            'classId': schoolClass.id,
            'className': schoolClass.name,
            'grade': schoolClass.grade?.name ?? '',
            'schoolClass': schoolClass,
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            color: const Color(0xFF8B5CF6).withOpacity(0.1),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.class_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 14.w),
              // Class Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      schoolClass.name,
                      style: AppFonts.h3.copyWith(
                        color: const Color(0xFF1F2937),
                        fontWeight: FontWeight.bold,
                        fontSize: AppFonts.size16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        if (schoolClass.grade != null && schoolClass.grade!.name.isNotEmpty) ...[
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.school_rounded,
                                  color: Colors.white,
                                  size: 12.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  schoolClass.grade!.name,
                                  style: AppFonts.bodySmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: AppFonts.size10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                        ],
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_rounded,
                              size: 14.sp,
                              color: const Color(0xFF6B7280),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '$studentsInClass ${'students'.tr}',
                              style: AppFonts.bodySmall.copyWith(
                                color: const Color(0xFF6B7280),
                                fontSize: AppFonts.size12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 4.w),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: const Color(0xFF9CA3AF),
                size: 16.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _getSchoolImageUrl(School school) {
    if (school.visibilitySettings?.officialLogo?.url != null && 
        school.visibilitySettings!.officialLogo!.url.isNotEmpty &&
        school.visibilitySettings!.officialLogo!.url.trim().toLowerCase() != 'null') {
      final url = school.visibilitySettings!.officialLogo!.url.trim();
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return url;
      }
    }
    if (school.media?.schoolImages != null && school.media!.schoolImages!.isNotEmpty) {
      final url = school.media!.schoolImages!.first.url;
      if (url.isNotEmpty && url.trim().toLowerCase() != 'null') {
        final trimmedUrl = url.trim();
        if (trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://')) {
          return trimmedUrl;
        }
      }
    }
    if (school.bannerImage != null && 
        school.bannerImage!.isNotEmpty &&
        school.bannerImage!.trim().toLowerCase() != 'null') {
      final url = school.bannerImage!.trim();
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return url;
      }
    }
    return null;
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
                            _classes.clear();
                            _filteredClasses.clear();
                          });
                          await _loadClasses();
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


