import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_fonts.dart';
import '../../models/student_models.dart';
import '../../services/students_service.dart';
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

  // Pagination variables
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
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents({bool resetPage = false}) async {
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
        'Error',
        'Failed to load students: ${e.toString()}',
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
        if (query.isEmpty) {
          _filteredStudents = List.from(_students);
          _isSearchMode = false;
        } else {
          _filteredStudents = _students
              .where((student) =>
                  student.fullName.toLowerCase().contains(query.toLowerCase()) ||
                  student.studentCode
                      .toLowerCase()
                      .contains(query.toLowerCase()) ||
                  student.grade.name.toLowerCase().contains(query.toLowerCase()))
              .toList();
          _isSearchMode = true;
        }
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _filterStudents('');
  }

  void _goToNextPage() {
    if (_hasNextPage && !_isLoading) {
      _currentPage++;
      _loadStudents();
    }
  }

  void _goToPrevPage() {
    if (_hasPrevPage && !_isLoading) {
      _currentPage--;
      _loadStudents();
    }
  }

  void _goToPage(int page) {
    if (page != _currentPage && page >= 1 && page <= _totalPages && !_isLoading) {
      _currentPage = page;
      _loadStudents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        title: Text(
          'Students',
          style: AppFonts.h2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white, size: 18),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            onPressed: () {
              if (_schoolId != null) {
                Get.toNamed(AppRoutes.addStudent,
                    arguments: {'schoolId': _schoolId});
              } else {
                Get.snackbar(
                  'Error',
                  'School ID not available',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: Colors.white, size: 20),
            onPressed: () => _loadStudents(resetPage: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A8A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterStudents,
                decoration: InputDecoration(
                  hintText: 'Search students...',
                  hintStyle: AppFonts.bodyMedium.copyWith(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 14.sp,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: const Color(0xFF6B7280),
                    size: 20.sp,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: const Color(0xFF6B7280),
                            size: 20.sp,
                          ),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                ),
              ),
            ),
          ),

          // Students List
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      return ShimmerListTile(
                        hasAvatar: true,
                        hasSubtitle: true,
                      );
                    },
                  )
                : _filteredStudents.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => _loadStudents(resetPage: true),
                        color: const Color(0xFF1E3A8A),
                        child: Column(
                          children: [
                            // Students List
                            Expanded(
                              child: ListView.builder(
                                padding: EdgeInsets.all(16.w),
                                itemCount: _filteredStudents.length,
                                itemBuilder: (context, index) {
                                  return _buildStudentCard(_filteredStudents[index]);
                                },
                              ),
                            ),
                            // Pagination Controls
                            if (_totalPages > 1) _buildPaginationControls(),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120.w,
            height: 120.h,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(60.r),
            ),
            child: Icon(
              Icons.school_rounded,
              size: 60.sp,
              color: const Color(0xFF1E3A8A),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            _isSearchMode ? 'No students found' : 'No students available',
            style: AppFonts.h3.copyWith(
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _isSearchMode
                ? 'Try adjusting your search terms'
                : 'Students will appear here once added',
            style: AppFonts.bodyMedium.copyWith(
              color: const Color(0xFF6B7280),
              fontSize: 14.sp,
            ),
            textAlign: TextAlign.center,
          ),
          if (!_isSearchMode) ...[
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.addStudent,
                  arguments: {'schoolId': _schoolId}),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                'Add Student',
                style: AppFonts.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStudentCard(Student student) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.to(
            () => StudentDetailsPage(
              student: student,
              schoolId: _schoolId,
            ),
          ),
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // Student Avatar
                _buildStudentAvatar(student),
                SizedBox(width: 12.w),

                // Student Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        style: AppFonts.bodyLarge.copyWith(
                          color: const Color(0xFF1F2937),
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        student.grade.name,
                        style: AppFonts.bodyMedium.copyWith(
                          color: const Color(0xFF6B7280),
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.badge_rounded,
                            color: const Color(0xFF9CA3AF),
                            size: 14.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            student.studentCode,
                            style: AppFonts.labelSmall.copyWith(
                              color: const Color(0xFF9CA3AF),
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(student.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: _getStatusColor(student.status).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    student.status.toUpperCase(),
                    style: AppFonts.labelSmall.copyWith(
                      color: _getStatusColor(student.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 10.sp,
                    ),
                  ),
                ),

                SizedBox(width: 8.w),

                // Arrow
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: const Color(0xFF9CA3AF),
                  size: 16.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16.h),
      child: Center(
        child: ElevatedButton(
          onPressed: () => _loadStudents(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          child: Text(
            'Load More',
            style: AppFonts.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
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

  Widget _buildStudentAvatar(Student student) {
    // Try to get student image from various sources
    String? imageUrl;

    // Check if student has avatar field
    if (student.avatar?.isNotEmpty == true) {
      imageUrl = student.avatar;
    }
    // Check if student has profileImage field
    else if (student.profileImage?.isNotEmpty == true) {
      imageUrl = student.profileImage;
    }
    // Check if student has image field
    else if (student.image?.isNotEmpty == true) {
      imageUrl = student.image;
    }

    return Container(
      width: 50.w,
      height: 50.h,
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(
          color: const Color(0xFF1E3A8A).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25.r),
        child: SafeAvatarImage(
          imageUrl: imageUrl,
          size: 50,
          backgroundColor: const Color(0xFF1E3A8A),
        ),
      ),
    );
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
                'Page $_currentPage of $_totalPages',
                style: AppFonts.bodySmall.copyWith(
                  color: const Color(0xFF6B7280),
                  fontSize: 12.sp,
                ),
              ),
              Text(
                '$_totalStudents students total',
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
