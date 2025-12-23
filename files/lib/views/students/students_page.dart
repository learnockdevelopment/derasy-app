import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/assets.dart';
import '../../models/student_models.dart';
import '../../models/pagination_models.dart';
import '../../services/students_service.dart';
import '../../models/school_models.dart';
import '../../services/schools_service.dart';
import '../../services/grades_service.dart';
import '../../core/routes/app_routes.dart';
import '../../core/constants/api_constants.dart';
import 'data/student_details_page.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/safe_network_image.dart';

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
  School? _selectedSchool;
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
  // Filter state
  String? _selectedGradeId;
  int? _selectedAge;
  String? _selectedClassId;
  List<Grade> _grades = [];

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
      // load students for selected school if any
      if (_schoolId != null) {
        await _loadGrades();
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
      // Silently fail - grades will be empty
      print('Failed to load grades: $e');
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
      final response = await StudentsService.getStudents(
        _schoolId!,
        request: StudentsRequest(
          page: _currentPage,
          limit: _limit,
        search: searchQuery,
          grade: _selectedGradeId,
          age: _selectedAge,
          classId: _selectedClassId,
        ),
      );

      if (mounted) {
        setState(() {
          // Always replace the list when loading a specific page
          // This ensures pagination shows correct data for each page
          _students = response.students;
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
                          Text('students'.tr, style: AppFonts.h2.copyWith(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: AppFonts.size20)),
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
                      SizedBox(height: 12.h),
                      // Search bar and filter button in blue bar
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
                                    onChanged: _filterStudents,
                                    style: AppFonts.bodyMedium.copyWith(fontSize: AppFonts.size14),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'search_students'.tr,
                                      hintStyle: TextStyle(color: const Color(0xFF7F7FD5).withOpacity(0.7), fontSize: AppFonts.size14),
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
                                        color: (_selectedGradeId != null || _selectedAge != null)
                                            ? AppColors.primaryBlue
                                            : const Color(0xFF7F7FD5),
                                        size: AppFonts.size22,
                                      ),
                                    ),
                                    if (_selectedGradeId != null || _selectedAge != null)
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
                                        size: AppFonts.size22,
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
              child: SvgPicture.asset(AssetsManager.emptySvg, fit: BoxFit.contain),
            ),
            SizedBox(height: 20.h),
            Text(
              _isSearchMode ? 'no_students_found'.tr : 'no_students_available'.tr,
              style: AppFonts.h3.copyWith(
                color: const Color(0xFF374151),
                fontWeight: FontWeight.w700,
                fontSize: AppFonts.size18,
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
                fontSize: AppFonts.size14,
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
                    imageUrl: _getStudentImageUrl(student),
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
                              style: AppFonts.labelSmall.copyWith(color: const Color(0xFF5981BB), fontSize: AppFonts.size12, fontWeight: FontWeight.w500),
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
                                  Text(student.studentCode, style: AppFonts.labelSmall.copyWith(fontSize: AppFonts.size12, color: const Color(0xFF6B7280))),
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


  String? _getStudentImageUrl(Student student) {
    // Safely extract image URL, handling null values properly
    String? imageUrl;
    
    // Debug: Print student image fields
    debugPrint('🎓 [STUDENT IMAGE] Student: ${student.fullName}');
    debugPrint('🎓 [STUDENT IMAGE] avatar: ${student.avatar} (${student.avatar.runtimeType})');
    debugPrint('🎓 [STUDENT IMAGE] profileImage: ${student.profileImage} (${student.profileImage.runtimeType})');
    debugPrint('🎓 [STUDENT IMAGE] image: ${student.image} (${student.image.runtimeType})');
    
    // Try avatar field - convert to string if needed
    final avatar = student.avatar;
    if (avatar != null) {
      final String avatarStr;
      avatarStr = avatar;
          if (avatarStr.trim().isNotEmpty && avatarStr.trim().toLowerCase() != 'null') {
        final trimmed = avatarStr.trim();
        debugPrint('🎓 [STUDENT IMAGE] Checking avatar URL: $trimmed');
        if (_isValidImageUrl(trimmed)) {
          debugPrint('🎓 [STUDENT IMAGE] ✅ Using avatar URL: $trimmed');
          imageUrl = trimmed;
        } else {
          debugPrint('🎓 [STUDENT IMAGE] ❌ Avatar URL invalid: $trimmed');
        }
      }
    }
    
    // Try profileImage field
    if (imageUrl == null || imageUrl.isEmpty) {
      final profileImage = student.profileImage;
      if (profileImage != null) {
        final String profileImageStr;
        profileImageStr = profileImage;
              if (profileImageStr.trim().isNotEmpty && profileImageStr.trim().toLowerCase() != 'null') {
          final trimmed = profileImageStr.trim();
          debugPrint('🎓 [STUDENT IMAGE] Checking profileImage URL: $trimmed');
          if (_isValidImageUrl(trimmed)) {
            debugPrint('🎓 [STUDENT IMAGE] ✅ Using profileImage URL: $trimmed');
            imageUrl = trimmed;
          } else {
            debugPrint('🎓 [STUDENT IMAGE] ❌ profileImage URL invalid: $trimmed');
          }
        }
      }
    }

    // Try image field
    if (imageUrl == null || imageUrl.isEmpty) {
      final image = student.image;
      if (image != null) {
        final String imageStr;
        imageStr = image;
              if (imageStr.trim().isNotEmpty && imageStr.trim().toLowerCase() != 'null') {
          final trimmed = imageStr.trim();
          debugPrint('🎓 [STUDENT IMAGE] Checking image URL: $trimmed');
          if (_isValidImageUrl(trimmed)) {
            debugPrint('🎓 [STUDENT IMAGE] ✅ Using image URL: $trimmed');
            imageUrl = trimmed;
          } else {
            debugPrint('🎓 [STUDENT IMAGE] ❌ image URL invalid: $trimmed');
          }
        }
      }
    }
    
    if (imageUrl == null) {
      debugPrint('🎓 [STUDENT IMAGE] ❌ No valid image URL found for ${student.fullName}');
    } else {
      // If it's a relative URL, prepend base URL
      if (imageUrl.startsWith('/') && !imageUrl.startsWith('//')) {
        final fullUrl = '${ApiConstants.baseUrl}$imageUrl';
        debugPrint('🎓 [STUDENT IMAGE] 🔄 Converted relative URL to full URL: $fullUrl');
        return fullUrl;
      }
    }
    
    return imageUrl?.isNotEmpty == true ? imageUrl : null;
  }

  bool _isValidImageUrl(String url) {
    if (url.isEmpty) {
      debugPrint('🎓 [URL VALIDATION] Empty URL');
      return false;
    }
    
    // Reject obviously invalid URLs
    final lower = url.toLowerCase().trim();
    if (lower == 'null' || 
        lower == 'undefined' ||
        lower == 'none' ||
        lower == 'n/a' ||
        url.length < 4) {
      debugPrint('🎓 [URL VALIDATION] Invalid URL: $url');
      return false;
    }
    
    // Accept http/https URLs
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      debugPrint('🎓 [URL VALIDATION] ✅ Valid HTTP/HTTPS URL: $url');
      return true;
    }
    
    // Accept data URLs (base64 images)
    if (lower.startsWith('data:image/')) {
      debugPrint('🎓 [URL VALIDATION] ✅ Valid data URL: $url');
      return true;
    }
    
    // Accept asset paths
    if (url.startsWith('assets/')) {
      debugPrint('🎓 [URL VALIDATION] ✅ Valid asset path: $url');
      return true;
    }
    
    // Accept relative URLs that might be valid (like /uploads/image.jpg)
    if (url.startsWith('/') && url.length > 1) {
      debugPrint('🎓 [URL VALIDATION] ⚠️ Relative URL (will need base URL): $url');
      return true; // Accept it, but might need base URL prepended
    }
    
    debugPrint('🎓 [URL VALIDATION] ❌ Rejected URL: $url');
    return false;
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
                    'filters'.tr,
                    style: AppFonts.h3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: AppFonts.size20,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedGradeId != null || _selectedAge != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedGradeId = null;
                          _selectedAge = null;
                          _selectedClassId = null;
                        });
                        Get.back();
                        _loadStudents(resetPage: true);
                      },
                      child: Text(
                        'clear_all'.tr,
                        style: AppFonts.bodyMedium.copyWith(
                          color: AppColors.primaryBlue,
                          fontSize: AppFonts.size14,
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
                        fontSize: AppFonts.size16,
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
                              fontSize: AppFonts.size14,
                            ),
                          ),
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text(
                                'all_grades'.tr,
                                style: AppFonts.bodyMedium.copyWith(fontSize: AppFonts.size14),
                              ),
                            ),
                            ..._grades.map((grade) => DropdownMenuItem<String>(
                              value: grade.id,
                              child: Text(
                                grade.name,
                                style: AppFonts.bodyMedium.copyWith(fontSize: AppFonts.size14),
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
                    // Age Filter
                    Text(
                      'age'.tr,
                      style: AppFonts.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: AppFonts.size16,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedAge,
                          isExpanded: true,
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          hint: Text(
                            'select_age'.tr,
                            style: AppFonts.bodyMedium.copyWith(
                              color: const Color(0xFF9CA3AF),
                              fontSize: AppFonts.size14,
                            ),
                          ),
                          items: [
                            DropdownMenuItem<int>(
                              value: null,
                              child: Text(
                                'all_ages'.tr,
                                style: AppFonts.bodyMedium.copyWith(fontSize: AppFonts.size14),
                              ),
                            ),
                            ...List.generate(20, (index) => index + 3).map((age) => DropdownMenuItem<int>(
                              value: age,
                              child: Text(
                                '$age',
                                style: AppFonts.bodyMedium.copyWith(fontSize: AppFonts.size14),
                              ),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedAge = value;
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
                    _loadStudents(resetPage: true);
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
                      fontSize: AppFonts.size16,
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
                      fontSize: AppFonts.size20,
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
                            _students.clear();
                            _filteredStudents.clear();
                            _currentPage = 1;
                            _totalPages = 1;
                            _totalStudents = 0;
                            _hasNextPage = false;
                            _hasPrevPage = false;
                            // Reset filters when school changes
                            _selectedGradeId = null;
                            _selectedAge = null;
                            _selectedClassId = null;
                          });
                          await _loadGrades();
                          await _loadStudents(resetPage: true);
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
                                  fontSize: AppFonts.size14,
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
                  
                ),
              ),
              Text(
                'students_total'.tr.replaceAll('{count}', '$_totalStudents'),
                style: AppFonts.bodySmall.copyWith(
                  color: const Color(0xFF6B7280),
                  
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
                fontSize: AppFonts.size14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

