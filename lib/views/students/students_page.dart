import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../models/student_models.dart';
import '../../services/students_service.dart';
import '../../models/school_models.dart';
import '../../services/schools_service.dart';
import '../../core/routes/app_routes.dart';
import 'data/student_details_page.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/safe_network_image.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({Key? key}) : super(key: key);

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Student> _students = [];
  List<Student> _filteredStudents = [];
  bool _isLoading = false;
  String? _schoolId;
  String _searchQuery = '';
  Timer? _debounceTimer;
  List<School> _schools = [];
  int _currentPage = 1;
  int _limit = 20;
  int _totalPages = 1;
  int _totalStudents = 0;
  bool _hasNextPage = false;
  bool _hasPrevPage = false;
  bool _isSearchMode = false;

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
        // store schools
        _schools = response.schools;
        // if no schoolId passed, default to first available
        _schoolId ??= _schools.isNotEmpty ? _schools.first.id : null;
      });
      // load students for selected school if any
      if (_schoolId != null) {
        await _loadStudents(resetPage: true);
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // silently ignore; dropdown will be empty
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadStudents({bool resetPage = false, String? searchQuery}) async {
    if (_schoolId == null) return;

    if (resetPage) {
      _currentPage = 1;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await StudentsService.getStudentsPaginated(
        _schoolId!,
        _currentPage,
        _limit,
        search: searchQuery,
      );

      if (mounted) {
        setState(() {
          if (resetPage) {
            _students = response.students;
          } else {
            _students.addAll(response.students);
          }
          _filteredStudents = List.from(_students);
          
          // Update pagination info
          _currentPage = response.pagination.currentPage;
          _totalPages = response.pagination.totalPages;
          _totalStudents = response.pagination.totalStudents;
          _hasNextPage = response.pagination.hasNextPage;
          _hasPrevPage = response.pagination.hasPrevPage;
        });
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_load_students'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterStudents(String query) {
    if (mounted) {
      setState(() {
        _searchQuery = query;
      });
      
      // Cancel previous timer
      _debounceTimer?.cancel();
      
      if (query.isEmpty) {
        // Clear search immediately for instant feedback
        setState(() {
          _filteredStudents = List.from(_students);
          _isSearchMode = false;
        });
        // Reload students without search when cleared
        _loadStudents(resetPage: true);
      } else {
        // When searching, show partial matches from loaded students first (instant feedback)
        setState(() {
          _filteredStudents = _students
              .where((student) =>
                  student.fullName.toLowerCase().contains(query.toLowerCase()) ||
                  student.studentCode.toLowerCase().contains(query.toLowerCase()) ||
                  student.nationalId.toLowerCase().contains(query.toLowerCase()) ||
                  (student.grade.name.isNotEmpty 
                      ? student.grade.name 
                      : '').toLowerCase().contains(query.toLowerCase()))
              .toList();
          _isSearchMode = true;
        });
        
        // Debounce API call to avoid too many requests while typing
        _debounceTimer = Timer(const Duration(milliseconds: 500), () {
          // Then search the API for more results (search all students, not just loaded ones)
          _loadStudents(resetPage: true, searchQuery: query);
        });
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _filterStudents('');
  }

  void _goToNextPage() {
    if (_hasNextPage && !_isLoading) {
      _currentPage++;
      _loadStudents(searchQuery: _searchQuery.isEmpty ? null : _searchQuery);
    }
  }

  void _goToPrevPage() {
    if (_hasPrevPage && !_isLoading) {
      _currentPage--;
      _loadStudents(searchQuery: _searchQuery.isEmpty ? null : _searchQuery);
    }
  }

  void _goToPage(int page) {
    if (page != _currentPage && page >= 1 && page <= _totalPages && !_isLoading) {
      _currentPage = page;
      _loadStudents(searchQuery: _searchQuery.isEmpty ? null : _searchQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( 
      backgroundColor: const Color(0xFFF6F8FB),
      body: Stack(
        children: [
          // Gradient Header BG
          Container(
            height: 160.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.95),
                  AppColors.primary.withOpacity(0.85),
                  AppColors.primary.withOpacity(0.75),
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
                // TopBar: title + add button + refresh
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                        onPressed: () => Get.back(),
                        splashRadius: 23,
                      ),
                      const Spacer(),
                      Text('students'.tr, style: AppFonts.h2.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20.sp)),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.25),
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
                                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
                                tooltip: 'add_student'.tr,
                                onPressed: () async {
                                  if (_schoolId != null) {
                                    final result = await Get.toNamed(AppRoutes.addStudent, arguments: {'schoolId': _schoolId});
                                    if (result == true) _loadStudents(resetPage: true);
                                  } else {
                                    Get.snackbar('error'.tr, 'school_id_not_available'.tr, backgroundColor: Colors.red, colorText: Colors.white);
                                  }
                                },
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              shape: const CircleBorder(),
                              child: IconButton(
                                icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 23),
                                tooltip: 'refresh'.tr,
                                onPressed: () => _loadStudents(resetPage: true),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Dropdown spacing from top bar
                SizedBox(height: 16.h),
                // School dropdown
                if (_schools.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        isDense: true,
                        value: _schoolId,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                        style: AppFonts.bodySmall.copyWith(fontSize: 12.sp, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'my_schools'.tr,
                          labelStyle: AppFonts.labelSmall.copyWith(fontSize: 11.sp, color: Colors.white.withOpacity(0.9)),
                          prefixIcon: const Icon(Icons.school_rounded, color: Colors.white),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                        items: _schools
                            .map((s) => DropdownMenuItem<String>(
                                  value: s.id,
                                  child: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.bodySmall.copyWith(fontSize: 12.sp, color: AppColors.textPrimary)),
                                ))
                            .toList(),
                        onChanged: (val) async {
                          if (val == null || val == _schoolId) return;
                          setState(() {
                            _schoolId = val;
                            _students.clear();
                            _filteredStudents.clear();
                            _currentPage = 1;
                            _totalPages = 1;
                            _totalStudents = 0;
                            _hasNextPage = false;
                            _hasPrevPage = false;
                          });
                          await _loadStudents(resetPage: true);
                        },
                        menuMaxHeight: 280.h,
                      ),
                    ),
                  ),
                SizedBox(height: 8.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(20.r),
                    color: Colors.white.withOpacity(0.82),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      height: 46.h,
                      child: Center(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterStudents,
                          style: AppFonts.bodyMedium,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'search_students'.tr,
                            hintStyle: TextStyle(color: const Color(0xFF7F7FD5)),
                            prefixIcon: Icon(Icons.search, color: const Color(0xFF7F7FD5), size: 21),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? GestureDetector(
                                    child: Icon(Icons.clear, color: const Color(0xFF7F7FD5), size: 20),
                                    onTap: _clearSearch,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                // BODY: Students List
                Expanded(
                  child: _isLoading
                      ? ListView.builder(
                          itemCount: 10,
                          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 9.h),
                          itemBuilder: (c, i) {
                            return const ShimmerListTile(padding: null);
                          }, 
                        )
                      : _filteredStudents.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: () => _loadStudents(resetPage: true),
                              color: const Color(0xFF7F7FD5),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: ListView.separated(
                                      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 9.h),
                                      itemCount: _filteredStudents.length,
                                      separatorBuilder: (_, __) => SizedBox(height: 8.h),
                                      itemBuilder: (ctx, idx) => _buildStudentCard(_filteredStudents[idx]),
                                    ),
                                  ),
                                  if (_totalPages > 1) _buildPaginationControls(),
                                ],
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
              child: Image.asset('assets/svg/dashboard.svg', fit: BoxFit.contain),
            ),
            SizedBox(height: 20.h),
            Text(
              _isSearchMode ? 'no_students_found'.tr : 'no_students_available'.tr,
              style: AppFonts.h3.copyWith(
                color: const Color(0xFF374151),
                fontWeight: FontWeight.w700,
                fontSize: 18.sp,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: 7.h),
            Text(
              _isSearchMode
                  ? 'try_adjusting_search_terms'.tr
                  : 'students_will_appear_here_once_added'.tr,
              style: AppFonts.bodyMedium.copyWith(
                color: const Color(0xFF6B7280),
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
            if (!_isSearchMode) ...[
              SizedBox(height: 24.h),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Get.toNamed(AppRoutes.addStudent, arguments: {'schoolId': _schoolId});
                  if (result == true) _loadStudents(resetPage: true);
                },
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: Text(
                  'add_student'.tr,
                  style: AppFonts.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7F7FD5),
                  padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 13.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(23.r),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(Student student) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () async {
          final result = await Get.to(() => StudentDetailsPage(student: student, schoolId: _schoolId));
          if (result == true) _loadStudents(resetPage: true);
        },
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
          child: Row(
            children: [
              // AVATAR
              Hero(
                tag: 'student-avatar-${student.id}',
                child: Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x8046A3E7),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SafeAvatarImage(
                    imageUrl: student.avatar?.isNotEmpty == true
                        ? student.avatar
                        : student.profileImage?.isNotEmpty == true
                            ? student.profileImage
                            : student.image,
                    size: 48,
                    backgroundColor: const Color(0xFF7F7FD5),
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              // INFO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: AppFonts.bodyLarge.copyWith(
                        color: const Color(0xFF131C30),
                        fontWeight: FontWeight.w600,
                        fontSize: 15.5.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 5.h),
                    Row(
                      children: [
                        // GRADE CHIP
                        if (student.grade.name.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF86A8E7).withOpacity(0.14),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                            child: Text(
                              student.grade.name,
                              style: AppFonts.labelSmall.copyWith(color: const Color(0xFF5981BB), fontSize: 12.sp, fontWeight: FontWeight.w500),
                            ),
                          ),
                        // STUDENT CODE CHIP
                        if (student.studentCode.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(left: 7.w),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFDAE6FC),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                              child: Row(
                                children: [
                                  Icon(Icons.badge_rounded, color: const Color(0xFF7F7FD5), size: 14),
                                  SizedBox(width: 2),
                                  Text(student.studentCode, style: AppFonts.labelSmall.copyWith(fontSize: 12.sp, color: const Color(0xFF6B7280))),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // STATUS DOT
              Row(
                children: [
                  Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: _getStatusColor(student.status),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.8),
                    ),
                  ),
                  SizedBox(width: 7.w),
                  Icon(Icons.arrow_forward_ios_rounded, color: const Color(0xFF9CA3AF), size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF10B981);
      case 'inactive':
        return const Color(0xFFF59E0B);
      case 'suspended':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }


  Widget _buildPaginationControls() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Pagination Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'page_of_total'.tr.replaceAll('{current}', '$_currentPage').replaceAll('{total}', '$_totalPages'),
                style: AppFonts.bodySmall.copyWith(
                  color: const Color(0xFF6B7280),
                  fontSize: 12.sp,
                ),
              ),
              Text(
                'students_total'.tr.replaceAll('{count}', '$_totalStudents'),
                style: AppFonts.bodySmall.copyWith(
                  color: const Color(0xFF6B7280),
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          // Pagination Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous Button
              _buildPaginationButton(
                icon: Icons.chevron_left_rounded,
                onPressed: _hasPrevPage ? _goToPrevPage : null,
                isEnabled: _hasPrevPage,
              ),
              SizedBox(width: 8.w),
              
              // Page Numbers
              ...List.generate(
                _totalPages > 5 ? 5 : _totalPages,
                (index) {
                  int pageNumber;
                  if (_totalPages <= 5) {
                    pageNumber = index + 1;
                  } else {
                    // Show current page and 2 pages before/after
                    int startPage = (_currentPage - 2).clamp(1, _totalPages - 4);
                    pageNumber = startPage + index;
                  }
                  
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.w),
                    child: _buildPageNumberButton(
                      pageNumber: pageNumber,
                      isActive: pageNumber == _currentPage,
                      onPressed: () => _goToPage(pageNumber),
                    ),
                  );
                },
              ),
              
              SizedBox(width: 8.w),
              
              // Next Button
              _buildPaginationButton(
                icon: Icons.chevron_right_rounded,
                onPressed: _hasNextPage ? _goToNextPage : null,
                isEnabled: _hasNextPage,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isEnabled,
  }) {
    return Container(
      width: 40.w,
      height: 40.h,
      decoration: BoxDecoration(
        color: isEnabled 
            ? const Color(0xFF1E3A8A) 
            : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: isEnabled ? [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8.r),
          child: Icon(
            icon,
            color: isEnabled ? Colors.white : const Color(0xFF9CA3AF),
            size: 20.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildPageNumberButton({
    required int pageNumber,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 40.w,
      height: 40.h,
      decoration: BoxDecoration(
        color: isActive 
            ? const Color(0xFF1E3A8A) 
            : Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isActive 
              ? const Color(0xFF1E3A8A) 
              : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: isActive ? [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8.r),
          child: Center(
            child: Text(
              '$pageNumber',
              style: AppFonts.bodyMedium.copyWith(
                color: isActive 
                    ? Colors.white 
                    : const Color(0xFF374151),
                fontWeight: isActive 
                    ? FontWeight.bold 
                    : FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

