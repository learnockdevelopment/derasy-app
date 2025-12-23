import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/assets.dart';
import '../../models/student_models.dart';
import '../../services/students_service.dart';
import '../../core/routes/app_routes.dart';
import '../../services/classes_service.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/safe_network_image.dart';
import '../../core/constants/api_constants.dart';

class ClassDetailsPage extends StatefulWidget {
  const ClassDetailsPage({Key? key}) : super(key: key);

  @override
  State<ClassDetailsPage> createState() => _ClassDetailsPageState();
}

class _ClassDetailsPageState extends State<ClassDetailsPage> {
  List<Student> _students = [];
  bool _isLoading = false;
  String? _schoolId;
  String? _classId;
  String? _className;
  String? _grade;
  SchoolClass? _schoolClass;
  

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    _schoolId = args?['schoolId'];
    _classId = args?['classId'];
    _className = args?['className'];
    _grade = args?['grade'];
    _schoolClass = args?['schoolClass'] as SchoolClass?;
    _loadClassData();
    _loadStudents();
  }

  Future<void> _loadClassData() async {
    // If schoolClass is not provided, try to load it from API
    if (_schoolClass == null && _schoolId != null && _classId != null) {
      try {
        final response = await ClassesService.getAllClasses(_schoolId!);
        final foundClass = response.classes.firstWhere(
          (c) => c.id == _classId,
          orElse: () => response.classes.first,
        );
        if (mounted) {
          setState(() {
            _schoolClass = foundClass;
          });
        }
      } catch (e) {
        print('Failed to load class data: $e');
      }
    }
  }

  Future<void> _loadStudents() async {
    if (_schoolId == null || _classId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await StudentsService.getAllStudents(_schoolId!);
      
      if (mounted) {
        setState(() {
          // Filter students by class
          _students = response.students
              .where((student) => student.studentClass.id == _classId)
              .toList();
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
        'failed_to_load_students'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
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
            height: 220.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B5CF6),
                  const Color(0xFF7C3AED),
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
                // TopBar
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
                          Column(
                            children: [
                              Text(
                                _className ?? 'class'.tr,
                                style: AppFonts.h2.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  
                                ),
                              ),
                              if (_grade != null && _grade!.isNotEmpty)
                                Container(
                                  margin: EdgeInsets.only(top: 6.h),
                                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(14.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.school_rounded,
                                        color: Colors.white,
                                        size: 16.sp,
                                      ),
                                      SizedBox(width: 6.w),
                                      Text(
                                        _grade!,
                                        style: AppFonts.bodyMedium.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
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
                      : _students.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: () => _loadStudents(),
                              color: const Color(0xFF8B5CF6),
                              child: ListView.separated(
                                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 9.h),
                                itemCount: _students.length,
                                separatorBuilder: (_, __) => SizedBox(height: 8.h),
                                itemBuilder: (ctx, idx) => _buildStudentCard(_students[idx]),
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
              'no_students_in_class'.tr,
              style: AppFonts.h3.copyWith(
                color: const Color(0xFF374151),
                fontWeight: FontWeight.w700,
                
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: 7.h),
            Text(
              'students_will_appear_here_once_added'.tr,
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

  Widget _buildStudentCard(Student student) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () async {
          final result = await Get.toNamed(AppRoutes.studentDetails, arguments: {
            'student': student,
            'schoolId': _schoolId,
          });
          if (result == true) _loadStudents();
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
                        color: const Color(0x808B5CF6),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SafeAvatarImage(
                    imageUrl: _getStudentImageUrl(student),
                    size: 48,
                    backgroundColor: const Color(0xFF8B5CF6),
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
                              color: const Color(0xFF8B5CF6).withOpacity(0.14),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                            child: Text(
                              student.grade.name,
                              style: AppFonts.labelSmall.copyWith(
                                color: const Color(0xFF8B5CF6),
                                
                                fontWeight: FontWeight.w500,
                              ),
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
                                  Text(
                                    student.studentCode,
                                    style: AppFonts.labelSmall.copyWith(
                                      
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
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
    if (student.avatar != null && student.avatar.toString().trim().isNotEmpty) {
      final avatarStr = student.avatar.toString().trim();
      if (avatarStr.toLowerCase() != 'null') {
        return avatarStr.startsWith('http') ? avatarStr : '${ApiConstants.baseUrl}$avatarStr';
      }
    }
    if (student.profileImage != null && student.profileImage.toString().trim().isNotEmpty) {
      final profileStr = student.profileImage.toString().trim();
      if (profileStr.toLowerCase() != 'null') {
        return profileStr.startsWith('http') ? profileStr : '${ApiConstants.baseUrl}$profileStr';
      }
    }
    if (student.image != null && student.image.toString().trim().isNotEmpty) {
      final imageStr = student.image.toString().trim();
      if (imageStr.toLowerCase() != 'null') {
        return imageStr.startsWith('http') ? imageStr : '${ApiConstants.baseUrl}$imageStr';
      }
    }
    return null;
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
}

