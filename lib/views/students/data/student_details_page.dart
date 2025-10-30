import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../models/student_models.dart';
import '../../../services/students_service.dart';
import '../management/edit_student_page.dart';
import 'guardians/guardians_page.dart';
import 'pickup_permissions/pickup_permissions_page.dart';
import 'clinic_records/clinic_records_page.dart';
import 'student_attendance/student_attendance_page.dart';

class StudentDetailsPage extends StatefulWidget {
  final Student student;
  final String? schoolId;

  const StudentDetailsPage({
    Key? key,
    required this.student,
    this.schoolId,
  }) : super(key: key);

  @override
  State<StudentDetailsPage> createState() => _StudentDetailsPageState();
}

class _StudentDetailsPageState extends State<StudentDetailsPage> {
  @override
  void initState() {
    super.initState();
    _printStudentData();
  }

  void _printStudentData() {
    print('🎓 [STUDENT DETAILS] Student ID: ${widget.student.id}');
    print('🎓 [STUDENT DETAILS] Full Name: ${widget.student.fullName}');
    print('🎓 [STUDENT DETAILS] Grade: ${widget.student.grade.name.isEmpty ? 'N/A' : widget.student.grade.name}');
    print('🎓 [STUDENT DETAILS] Section: ${widget.student.section.name.isEmpty ? 'N/A' : widget.student.section.name}');
    print('🎓 [STUDENT DETAILS] Status: ${widget.student.status}');
    print('🎓 [STUDENT DETAILS] Age: ${widget.student.ageInOctober}');
    print('🎓 [STUDENT DETAILS] Gender: ${widget.student.gender}');
    print('🎓 [STUDENT DETAILS] National ID: ${widget.student.nationalId}');
    print('🎓 [STUDENT DETAILS] Parent Name: ${widget.student.parent.name.isEmpty ? 'N/A' : widget.student.parent.name}');
    print('🎓 [STUDENT DETAILS] Parent Phone: ${widget.student.parent.phone.isEmpty ? 'N/A' : widget.student.parent.phone}');
    print(
        '🎓 [STUDENT DETAILS] Moodle Username: ${widget.student.moodleUser?.username ?? 'N/A'}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Professional App Bar
          SliverAppBar(
            expandedHeight: 180.h,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1E3A8A),
            elevation: 0,
            leading: Container(
              margin: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded,
                    color: Colors.white, size: 18),
                onPressed: () => Get.back(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1E3A8A), // Professional blue
                      Color(0xFF3B82F6), // Lighter blue
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            // Professional Avatar
                            Hero(
                              tag: 'student_${widget.student.id}',
                              child: Container(
                                width: 70.w,
                                height: 70.h,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(35.r),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 35.sp,
                                  color: const Color(0xFF1E3A8A),
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            // Student Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.student.fullName,
                                    style: AppFonts.h2.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20.sp,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    widget.student.grade.name.isNotEmpty 
                                        ? widget.student.grade.name 
                                        : 'N/A',
                                    style: AppFonts.bodyMedium.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 2.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                          widget.student.status),
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Text(
                                      widget.student.status.toUpperCase(),
                                      style: AppFonts.labelSmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  _buildQuickActionsSection(),
                  SizedBox(height: 12.h),

                  _buildStudentInfoSection(),
                  SizedBox(height: 12.h),

                  _buildParentInfoSection(),
                  SizedBox(height: 12.h),

                  _buildAcademicInfoSection(),
                  SizedBox(height: 12.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    final actions = [
      {
        'icon': Icons.edit_rounded,
        'label': 'quick_edit'.tr,
        'color': const Color(0xFF3B82F6),
        'onTap': _editStudent,
      },
      {
        'icon': Icons.family_restroom_rounded,
        'label': 'quick_guardians'.tr,
        'color': const Color(0xFF10B981),
        'onTap': _manageGuardians,
      },
      {
        'icon': Icons.calendar_today_rounded,
        'label': 'quick_attendance'.tr,
        'color': const Color(0xFFF59E0B),
        'onTap': _viewAttendance,
      },
      {
        'icon': Icons.car_rental_rounded,
        'label': 'quick_pickup'.tr,
        'color': const Color(0xFF8B5CF6),
        'onTap': _managePickupPermissions,
      },
      {
        'icon': Icons.local_hospital_rounded,
        'label': 'quick_clinic'.tr,
        'color': const Color(0xFFEF4444),
        'onTap': _viewClinicRecords,
      },
      {
        'icon': Icons.delete_rounded,
        'label': 'quick_delete'.tr,
        'color': const Color(0xFF6B7280),
        'onTap': _deleteStudent,
      },
    ];

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'quick_actions'.tr,
            style: AppFonts.h3.copyWith(
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.bold,
              fontSize: 16.sp, // Reduced font size
            ),
          ),
          SizedBox(height: 8.h), // Reduced spacing
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8.w, // Reduced spacing
              mainAxisSpacing: 8.h, // Reduced spacing
              childAspectRatio:
                  1.2, // Increased aspect ratio for smaller height
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return _buildActionButton(
                icon: action['icon'] as IconData,
                label: action['label'] as String,
                color: action['color'] as Color,
                onTap: action['onTap'] as VoidCallback,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32.w, // Reduced size
              height: 32.h, // Reduced size
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius:
                    BorderRadius.circular(8.r), // Reduced border radius
              ),
              child: Icon(
                icon,
                color: color,
                size: 16.sp, // Reduced icon size
              ),
            ),
            SizedBox(height: 4.h), // Reduced spacing
            Text(
              label,
              style: AppFonts.labelMedium.copyWith(
                color: const Color(0xFF374151),
                fontWeight: FontWeight.w600,
                fontSize: 10.sp, // Reduced font size
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentInfoSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                color: const Color(0xFF3B82F6),
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
          Text(
            'student_information'.tr,
                style: AppFonts.h3.copyWith(
                  color: const Color(0xFF1F2937),
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildInfoRow('full_name'.tr, widget.student.fullName, Icons.person),
          _buildInfoRow(
              'student_code'.tr, widget.student.studentCode, Icons.badge),
          _buildInfoRow('age'.tr, widget.student.ageInOctober.toString(),
              Icons.calendar_today),
          _buildInfoRow('gender'.tr, widget.student.gender.toUpperCase(),
              Icons.person_outline),
          _buildInfoRow('national_id'.tr, widget.student.nationalId, Icons.flag),
        ],
      ),
    );
  }

  Widget _buildParentInfoSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.family_restroom_rounded,
                color: const Color(0xFF10B981),
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
          Text(
            'parent_information'.tr,
                style: AppFonts.h3.copyWith(
                  color: const Color(0xFF1F2937),
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildInfoRow(
              'parent_name'.tr, 
              widget.student.parent.name.isNotEmpty 
                  ? widget.student.parent.name 
                  : 'n_a'.tr, 
              Icons.person),
          _buildInfoRow(
              'parent_phone'.tr, 
              widget.student.parent.phone.isNotEmpty 
                  ? widget.student.parent.phone 
                  : 'n_a'.tr, 
              Icons.phone),
        ],
      ),
    );
  }

  Widget _buildAcademicInfoSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.school_rounded,
                color: const Color(0xFFF59E0B),
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
          Text(
            'academic_information'.tr,
                style: AppFonts.h3.copyWith(
                  color: const Color(0xFF1F2937),
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildInfoRow('grade'.tr, widget.student.grade.name.isNotEmpty ? widget.student.grade.name : 'n_a'.tr, Icons.grade),
          _buildInfoRow('stage'.tr, widget.student.stage.name.isNotEmpty ? widget.student.stage.name : 'n_a'.tr, Icons.school),
          _buildInfoRow('section'.tr, widget.student.section.name.isNotEmpty ? widget.student.section.name : 'n_a'.tr, Icons.class_),
          _buildInfoRow(
              'moodle_username'.tr,
              widget.student.moodleUser?.username ?? 'not_assigned'.tr,
              Icons.computer),
        ],
      ),
    );
  }

  Widget _buildAdditionalActionsSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.more_horiz_rounded,
                color: const Color(0xFF6B7280),
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Additional Actions',
                style: AppFonts.h3.copyWith(
                  color: const Color(0xFF1F2937),
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildActionTile(
            icon: Icons.assessment_rounded,
            title: 'View All Reports',
            subtitle: 'Academic and attendance reports',
            onTap: _viewAllReports,
          ),
          SizedBox(height: 12.h),
          _buildActionTile(
            icon: Icons.history_rounded,
            title: 'View History',
            subtitle: 'Student activity and changes',
            onTap: _viewHistory,
          ),
          SizedBox(height: 12.h),
          _buildActionTile(
            icon: Icons.settings_rounded,
            title: 'Student Settings',
            subtitle: 'Configure student preferences',
            onTap: _openSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF6B7280),
            size: 16.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppFonts.labelSmall.copyWith(
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: AppFonts.bodyMedium.copyWith(
                    color: const Color(0xFF1F2937),
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF3B82F6),
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.bodyMedium.copyWith(
                      color: const Color(0xFF1F2937),
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: AppFonts.labelSmall.copyWith(
                      color: const Color(0xFF6B7280),
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: const Color(0xFF6B7280),
              size: 16.sp,
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

  // Action Methods
  void _editStudent() async {
    if (widget.schoolId == null || widget.schoolId!.isEmpty) {
      Get.snackbar(
        'Error',
        'School ID is required to edit student',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
      return;
    }

    try {
      final result = await Get.to(
        () => EditStudentPage(
          student: widget.student,
          schoolId: widget.schoolId!,
        ),
      );

      if (result == true) {
        Get.snackbar(
          'Success',
          'Student updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
        );
        Get.back(result: true);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to edit student: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    }
  }

  void _manageGuardians() async {
    if (widget.schoolId == null || widget.schoolId!.isEmpty) {
      Get.snackbar(
        'Error',
        'School ID is required to manage guardians',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
      return;
    }

    try {
      Get.to(() => GuardiansPage(
            student: widget.student,
            schoolId: widget.schoolId!,
          ));
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to open guardians page: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    }
  }

  void _viewAttendance() async {
    if (widget.schoolId == null || widget.schoolId!.isEmpty) {
      Get.snackbar(
        'Error',
        'School ID is required to view attendance',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
      return;
    }

    try {
      Get.to(() => StudentAttendancePage(
            student: widget.student,
            schoolId: widget.schoolId!,
          ));
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to open attendance page: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    }
  }

  void _managePickupPermissions() async {
    if (widget.schoolId == null || widget.schoolId!.isEmpty) {
      Get.snackbar(
        'Error',
        'School ID is required to manage pickup permissions',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
      return;
    }

    try {
      Get.to(() => PickupPermissionsPage(
            student: widget.student,
            schoolId: widget.schoolId!,
          ));
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to open pickup permissions page: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    }
  }

  void _viewClinicRecords() async {
    if (widget.schoolId == null || widget.schoolId!.isEmpty) {
      Get.snackbar(
        'Error',
        'School ID is required to view clinic records',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
      return;
    }

    try {
      Get.to(() => ClinicRecordsPage(
            student: widget.student,
            schoolId: widget.schoolId!,
          ));
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to open clinic records page: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    }
  }

  void _deleteStudent() async {
    if (widget.schoolId == null || widget.schoolId!.isEmpty) {
      Get.snackbar(
        'Error',
        'School ID is required to delete student',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
      return;
    }

    Get.dialog(
      AlertDialog(
        title: Text(
          'Delete Student',
          style: AppFonts.h3.copyWith(
            color: const Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${widget.student.fullName}? This action cannot be undone.',
          style: AppFonts.bodyMedium.copyWith(
            color: const Color(0xFF6B7280),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: AppFonts.bodyMedium.copyWith(
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              try {
                await StudentsService.deleteStudent(
                  widget.schoolId!,
                  widget.student.id,
                );
                Get.snackbar(
                  'Success',
                  'Student deleted successfully',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: const Color(0xFF10B981),
                  colorText: Colors.white,
                );
                Get.back(result: true);
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to delete student: ${e.toString()}',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: const Color(0xFFEF4444),
                  colorText: Colors.white,
                );
              }
            },
            child: Text(
              'Delete',
              style: AppFonts.bodyMedium.copyWith(
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _viewAllReports() {
    Get.snackbar(
      'Info',
      'View reports functionality coming soon',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF3B82F6),
      colorText: Colors.white,
    );
  }

  void _viewHistory() {
    Get.snackbar(
      'Info',
      'View history functionality coming soon',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF3B82F6),
      colorText: Colors.white,
    );
  }

  void _openSettings() {
    Get.snackbar(
      'Info',
      'Settings functionality coming soon',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF3B82F6),
      colorText: Colors.white,
    );
  }
}
