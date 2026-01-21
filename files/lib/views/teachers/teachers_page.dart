import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
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
            height: Responsive.h(180),
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
                  padding: Responsive.fromLTRB(16, 12, 16, 12),
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
                                margin: Responsive.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(Responsive.r(12)),
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
                                    borderRadius: BorderRadius.circular(Responsive.r(12)),
                                    child: Padding(
                                      padding: Responsive.symmetric(horizontal: 12, vertical: 8),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(IconlyBold.discovery, color: Colors.white, size: Responsive.sp(18)),
                                          SizedBox(width: Responsive.w(6)),
                                          Text(
                                            'buses'.tr,
                                            style: AppFonts.bodyMedium.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: Responsive.sp(13),
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
                                  borderRadius: BorderRadius.circular(Responsive.r(12)),
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
                      SizedBox(height: Responsive.h(12)),
                      // Search bar and filter buttons
                      Row(
                        children: [
                          Expanded(
                            child: Material(
                              elevation: 6,
                              borderRadius: BorderRadius.circular(Responsive.r(12)),
                              color: Colors.white.withOpacity(0.95),
                              child: Container(
                                padding: Responsive.symmetric(horizontal: 12),
                                height: Responsive.h(42),
                                child: Center(
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: _filterTeachers,
                                    style: AppFonts.bodyMedium.copyWith(fontSize: AppFonts.size14),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'search_teachers'.tr,
                                      hintStyle: TextStyle(color: const Color(0xFF7F7FD5).withOpacity(0.7), fontSize: Responsive.sp(14)),
                                      prefixIcon: Icon(Icons.search, color: const Color(0xFF7F7FD5), size: 20),
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? GestureDetector(
                                              child: Icon(Icons.clear, color: const Color(0xFF7F7FD5), size: 18),
                                              onTap: _clearSearch,
                                            )
                                          : null,
                                      contentPadding: Responsive.symmetric(vertical: 8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: Responsive.w(10)),
                          // Filter button
                          Material(
                            elevation: 6,
                            borderRadius: BorderRadius.circular(Responsive.r(12)),
                            color: Colors.white.withOpacity(0.95),
                            child: InkWell(
                              onTap: _showFilterModal,
                              borderRadius: BorderRadius.circular(Responsive.r(12)),
                              child: Container(
                                width: Responsive.w(42),
                                height: Responsive.h(42),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(Responsive.r(12)),
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Icon(
                                        Icons.filter_list_rounded,
                                        color: (_selectedGradeId != null || _selectedClassId != null)
                                            ? AppColors.primaryBlue
                                            : const Color(0xFF7F7FD5),
                                        size: Responsive.sp(22),
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
                          SizedBox(width: Responsive.w(10)),
                          // School filter button
                          Material(
                            elevation: 6,
                            borderRadius: BorderRadius.circular(Responsive.r(12)),
                            color: Colors.white.withOpacity(0.95),
                            child: InkWell(
                              onTap: _showSchoolFilterModal,
                              borderRadius: BorderRadius.circular(Responsive.r(12)),
                              child: Container(
                                width: Responsive.w(42),
                                height: Responsive.h(42),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(Responsive.r(12)),
                                ),
                                child: _selectedSchool != null && _getSchoolImageUrl(_selectedSchool!) != null
                                    ? ClipRRect(
                                  borderRadius: BorderRadius.circular(Responsive.r(12)),
                                  child: SafeSchoolImage(
                                    imageUrl: _getSchoolImageUrl(_selectedSchool!),
                                    width: Responsive.w(42),
                                    height: Responsive.h(42),
                                  ),
                                )
                              : Icon(
                                  Icons.school_rounded,
                                  color: const Color(0xFF7F7FD5),
                                  size: Responsive.sp(22),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Responsive.h(20)),
                // BODY: Teachers List
                Expanded(
                  child: _isLoading
                      ? ListView.builder(
                          itemCount: 10,
                          padding: Responsive.symmetric(horizontal: 18, vertical: 9),
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
                                padding: Responsive.symmetric(horizontal: 18, vertical: 9),
                                itemCount: _filteredTeachers.length,
                                separatorBuilder: (_, __) => SizedBox(height: Responsive.h(8)),
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
        padding: Responsive.only(top: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: Responsive.w(100),
              height: Responsive.h(100),
              child: SvgPicture.asset(AssetsManager.emptySvg, fit: BoxFit.contain),
            ),
            SizedBox(height: Responsive.h(20)),
            Text(
              _searchQuery.isNotEmpty ? 'no_teachers_found'.tr : 'no_teachers_available'.tr,
              style: AppFonts.h3.copyWith(
                color: const Color(0xFF374151),
                fontWeight: FontWeight.w700,
                
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: Responsive.h(7)),
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
      borderRadius: BorderRadius.circular(Responsive.r(12)),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.06),
      child: InkWell(
        borderRadius: BorderRadius.circular(Responsive.r(12)),
        onTap: () {
          Get.toNamed(AppRoutes.teacherDetails, arguments: {
            'teacher': teacher,
            'schoolId': _schoolId,
          });
        },
        child: Container(
          padding: Responsive.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Responsive.r(12)),
            color: const Color(0xFF10B981).withOpacity(0.1),
          ),
          child: Row(
            children: [
              // AVATAR
              Container(
                width: Responsive.w(48),
                height: Responsive.w(48),
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
                  size: Responsive.sp(24),
                ),
              ),
              SizedBox(width: Responsive.w(12)),
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
                        fontSize: Responsive.sp(15),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: Responsive.h(4)),
                    if (teacher.subject != null && teacher.subject!.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(Responsive.r(6)),
                        ),
                        padding: Responsive.symmetric(horizontal: 8, vertical: 3),
                        child: Text(
                          teacher.subject!,
                          style: AppFonts.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: Responsive.sp(11),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Edit Button (Admin/Moderator only)
              SizedBox(width: Responsive.w(8)),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: const Color(0xFF9CA3AF),
                size: Responsive.sp(14),
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
            topLeft: Radius.circular(Responsive.r(24)),
            topRight: Radius.circular(Responsive.r(24)),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: Responsive.all(20),
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
                padding: Responsive.all(20),
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
                    SizedBox(height: Responsive.h(12)),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(Responsive.r(12)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGradeId,
                          isExpanded: true,
                          padding: Responsive.symmetric(horizontal: 16),
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
                                style: AppFonts.bodyMedium.copyWith(fontSize: Responsive.sp(14)),
                              ),
                            ),
                            ..._grades.map((grade) => DropdownMenuItem<String>(
                              value: grade.id,
                              child: Text(
                                grade.name,
                                style: AppFonts.bodyMedium.copyWith(fontSize: Responsive.sp(14)),
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
                    SizedBox(height: Responsive.h(24)),
                    // Class Filter
                    Text(
                      'class'.tr,
                      style: AppFonts.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        
                      ),
                    ),
                    SizedBox(height: Responsive.h(12)),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(Responsive.r(12)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedClassId,
                          isExpanded: true,
                          padding: Responsive.symmetric(horizontal: 16),
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
                                style: AppFonts.bodyMedium.copyWith(fontSize: Responsive.sp(14)),
                              ),
                            ),
                            ..._classes.map((cls) => DropdownMenuItem<String>(
                              value: cls,
                              child: Text(
                                cls,
                                style: AppFonts.bodyMedium.copyWith(fontSize: Responsive.sp(14)),
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
              padding: Responsive.all(20),
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
                    padding: Responsive.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Responsive.r(12)),
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
            topLeft: Radius.circular(Responsive.r(24)),
            topRight: Radius.circular(Responsive.r(24)),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: Responsive.all(20),
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
                padding: Responsive.all(16),
                itemCount: _schools.length,
                separatorBuilder: (_, __) => SizedBox(height: Responsive.h(12)),
                itemBuilder: (context, index) {
                  final school = _schools[index];
                  final isSelected = _schoolId == school.id;
                  final imageUrl = _getSchoolImageUrl(school);

                  return Material(
                    color: isSelected
                        ? AppColors.primaryBlue.withOpacity(0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(Responsive.r(12)),
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
                      borderRadius: BorderRadius.circular(Responsive.r(12)),
                      child: Container(
                        padding: Responsive.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Responsive.r(12)),
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
                              borderRadius: BorderRadius.circular(Responsive.r(10)),
                              child: Container(
                                width: Responsive.w(48),
                                height: Responsive.h(48),
                                child: imageUrl != null
                                    ? SafeSchoolImage(
                                        imageUrl: imageUrl,
                                        width: Responsive.w(48),
                                        height: Responsive.h(48),
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
                                          size: Responsive.sp(24),
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(width: Responsive.w(12)),
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
                            SizedBox(width: Responsive.w(8)),
                            // Selected Indicator
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primaryBlue,
                                size: Responsive.sp(24),
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

