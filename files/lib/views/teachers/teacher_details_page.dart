import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/routes/app_routes.dart';
import '../../services/teachers_service.dart';
import '../../widgets/safe_network_image.dart';

class TeacherDetailsPage extends StatefulWidget {
  const TeacherDetailsPage({Key? key}) : super(key: key);

  @override
  State<TeacherDetailsPage> createState() => _TeacherDetailsPageState();
}

class _TeacherDetailsPageState extends State<TeacherDetailsPage> {
  Teacher? _teacher;
  String? _schoolId;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    _teacher = args?['teacher'] as Teacher?;
    _schoolId = args?['schoolId'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    if (_teacher == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('teacher_details'.tr),
        ),
        body: Center(
          child: Text('teacher_not_found'.tr),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: Column(
        children: [
          // Fixed Top Section
          Container(
            height: Responsive.h(160),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981),
                  const Color(0xFF059669),
                ],
                begin: Alignment.topLeft, 
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // App Bar with Avatar
                  Padding(
                    padding: Responsive.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          margin: Responsive.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(Responsive.r(10)),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_rounded,
                                color: Colors.white, size: 18),
                            onPressed: () => Get.back(),
                          ),
                        ),
                        SizedBox(width: Responsive.w(12)),
                        // Teacher Avatar
                        Container(
                          width: Responsive.w(50),
                          height: Responsive.w(50),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _teacher!.avatar != null && _teacher!.avatar!.isNotEmpty
                                ? SafeNetworkImage(
                                    imageUrl: _teacher!.avatar!,
                                    width: Responsive.w(50),
                                    height: Responsive.w(50),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF10B981),
                                          const Color(0xFF059669),
                                        ],
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.person_rounded,
                                      color: Colors.white,
                                      size: Responsive.sp(25),
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(width: Responsive.w(12)),
                        // Teacher Name
                        Expanded(
                          child: Text(
                            _teacher!.name,
                            style: AppFonts.h2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: AppFonts.size18,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // PAGE BODY
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: Responsive.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      // Information Card
                      Container(
                          padding: Responsive.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(Responsive.r(20)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: Responsive.all(10),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(Responsive.r(12)),
                                    ),
                                    child: Icon(
                                      Icons.info_outline_rounded,
                                      color: Colors.white,
                                      size: Responsive.sp(20),
                                    ),
                                  ),
                                  SizedBox(width: Responsive.w(12)),
                                  Text(
                                    'teacher_information'.tr,
                                    style: AppFonts.h3.copyWith(
                                      color: const Color(0xFF1F2937),
                                      fontWeight: FontWeight.bold,
                                      fontSize: AppFonts.size20,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: Responsive.h(24)),
                              // Email
                              if (_teacher!.email != null && _teacher!.email!.isNotEmpty)
                                _buildInfoRow(
                                  Icons.email_rounded,
                                  'email'.tr,
                                  _teacher!.email!,
                                  const Color(0xFF3B82F6),
                                ),
                              if (_teacher!.email != null && _teacher!.email!.isNotEmpty)
                                SizedBox(height: Responsive.h(16)),
                              // Phone
                              if (_teacher!.phone != null && _teacher!.phone!.isNotEmpty)
                                _buildInfoRow(
                                  Icons.phone_rounded,
                                  'phone'.tr,
                                  _teacher!.phone!,
                                  const Color(0xFF10B981),
                                ),
                              if (_teacher!.phone != null && _teacher!.phone!.isNotEmpty)
                                SizedBox(height: Responsive.h(16)),
                              // Subject
                              if (_teacher!.subject != null && _teacher!.subject!.isNotEmpty)
                                _buildInfoRow(
                                  Icons.book_rounded,
                                  'subject'.tr,
                                  _teacher!.subject!,
                                  const Color(0xFF8B5CF6),
                                ),
                              if (_teacher!.subject != null && _teacher!.subject!.isNotEmpty)
                                SizedBox(height: Responsive.h(16)),
                              // Employee ID
                              if (_teacher!.teacher?.employeeId != null && _teacher!.teacher!.employeeId!.isNotEmpty)
                                _buildInfoRow(
                                  Icons.badge_rounded,
                                  'employee_id'.tr,
                                  _teacher!.teacher!.employeeId!,
                                  const Color(0xFFF59E0B),
                                ),
                              if (_teacher!.teacher?.employeeId != null && _teacher!.teacher!.employeeId!.isNotEmpty)
                                SizedBox(height: Responsive.h(16)),
                              // Username
                              if (_teacher!.username != null && _teacher!.username!.isNotEmpty)
                                _buildInfoRow(
                                  Icons.person_rounded,
                                  'username'.tr,
                                  _teacher!.username!,
                                  const Color(0xFF6366F1),
                                ),
                              if (_teacher!.username != null && _teacher!.username!.isNotEmpty)
                                SizedBox(height: Responsive.h(16)),
                              // Hire Date
                              if (_teacher!.teacher?.hireDate != null)
                                _buildInfoRow(
                                  Icons.calendar_today_rounded,
                                  'hire_date'.tr,
                                  _formatDate(_teacher!.teacher!.hireDate!),
                                  const Color(0xFF10B981),
                                ),
                              if (_teacher!.teacher?.hireDate != null)
                                SizedBox(height: Responsive.h(16)),
                              // Salary
                              if (_teacher!.teacher?.salary != null)
                                _buildInfoRow(
                                  Icons.attach_money_rounded,
                                  'salary'.tr,
                                  '${_teacher!.teacher!.salary}',  
                                  const Color(0xFF059669),
                                ),
                              if (_teacher!.teacher?.salary != null)
                                SizedBox(height: Responsive.h(16)),
                              // Employment Type
                              if (_teacher!.teacher?.employmentType != null && _teacher!.teacher!.employmentType!.isNotEmpty)
                                _buildInfoRow(
                                  Icons.work_rounded,
                                  'employment_type'.tr,
                                  _teacher!.teacher!.employmentType!,
                                  const Color(0xFF7C3AED),
                                ),
                              if (_teacher!.teacher?.employmentType != null && _teacher!.teacher!.employmentType!.isNotEmpty)
                                SizedBox(height: Responsive.h(16)),
                              // Experience Years
                              if (_teacher!.teacher?.experienceYears != null)
                                _buildInfoRow(
                                  Icons.trending_up_rounded,
                                  'experience_years'.tr,
                                  '${_teacher!.teacher!.experienceYears}',
                                  const Color(0xFFDC2626),
                                ),
                              if (_teacher!.teacher?.experienceYears != null)
                                SizedBox(height: Responsive.h(16)),
                              // Qualifications
                              if (_teacher!.teacher?.qualifications.isNotEmpty == true)
                                _buildInfoRow(
                                  Icons.school_rounded,
                                  'qualifications'.tr,
                                  _teacher!.teacher!.qualifications.join(', '),
                                  const Color(0xFF8B5CF6),
                                ),
                              if (_teacher!.teacher?.qualifications.isNotEmpty == true)
                                SizedBox(height: Responsive.h(16)),
                              // Grade Levels
                              if (_teacher!.teacher?.gradeLevels.isNotEmpty == true)
                                _buildInfoRow(
                                  Icons.class_rounded,
                                  'grade_levels'.tr,
                                  _teacher!.teacher!.gradeLevels.map((g) => g.name).join(', '),
                                  const Color(0xFF3B82F6),
                                ),
                              if (_teacher!.teacher?.gradeLevels.isNotEmpty == true)
                                SizedBox(height: Responsive.h(16)),
                              // Classes Section
                              if (_teacher!.teacher?.classes.isNotEmpty == true) ...[
                                Divider(
                                  height: Responsive.h(32),
                                  thickness: 1,
                                  color: const Color(0xFFE5E7EB),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: Responsive.all(8),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(Responsive.r(10)),
                                      ),
                                      child: Icon(
                                        Icons.class_rounded,
                                        color: Colors.white,
                                        size: Responsive.sp(18),
                                      ),
                                    ),
                                    SizedBox(width: Responsive.w(12)),
                                    Text(
                                      'classes'.tr,
                                      style: AppFonts.h3.copyWith(
                                        color: const Color(0xFF1F2937),
                                        fontWeight: FontWeight.bold,
                                        fontSize: AppFonts.size20,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: Responsive.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(Responsive.r(8)),
                                      ),
                                      child: Text(
                                        '${_teacher!.teacher!.classes.length}',
                                        style: AppFonts.bodyMedium.copyWith(
                                          color: const Color(0xFF10B981),
                                          fontWeight: FontWeight.bold,
                                          fontSize: AppFonts.size14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: Responsive.h(20)),
                                Wrap(
                                  spacing: Responsive.w(14),
                                  runSpacing: Responsive.h(14),
                                  children: _teacher!.teacher!.classes.map((teacherClass) {
                                    return _buildClassChip(teacherClass);
                                  }).toList(),
                                ),
                                SizedBox(height: Responsive.h(8)),
                              ],
                              // Status
                              _buildInfoRow(
                                Icons.info_rounded,
                                'status'.tr,
                                _teacher!.isActive == true ? 'active'.tr : 'inactive'.tr,
                                _teacher!.isActive == true ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: Responsive.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(Responsive.r(12)),
          ),
          child: Icon(icon, color: color, size: AppFonts.size22),
        ),
        SizedBox(width: Responsive.w(16)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppFonts.bodySmall.copyWith(
                  color: const Color(0xFF6B7280),
                  fontSize: AppFonts.size12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: Responsive.h(4)),
              Text(
                value,
                style: AppFonts.bodyMedium.copyWith(
                  color: const Color(0xFF1F2937),
                  fontWeight: FontWeight.w600,
                  fontSize: AppFonts.size14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClassChip(TeacherClass teacherClass) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(Responsive.r(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(Responsive.r(16)),
        onTap: () {
          if (_schoolId != null) {
            Get.toNamed(AppRoutes.classDetails, arguments: {
              'schoolId': _schoolId,
              'classId': teacherClass.id,
              'className': teacherClass.name,
              'grade': teacherClass.grade?.name ?? '',
            });
          }
        },
        child: Container(
          padding: Responsive.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF10B981).withOpacity(0.12),
                const Color(0xFF059669).withOpacity(0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(Responsive.r(16)),
            border: Border.all(
              color: const Color(0xFF10B981).withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: Responsive.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(Responsive.r(10)),
            ),
            child: Icon(
              Icons.class_rounded,
              color: Colors.white,
              size: Responsive.sp(18),
            ),
          ),
          SizedBox(width: Responsive.w(10)),
          Expanded(
            child: Text(
              teacherClass.name,
              style: AppFonts.bodyMedium.copyWith(
                color: const Color(0xFF1F2937),
                fontWeight: FontWeight.bold,
                fontSize: AppFonts.size14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (teacherClass.grade != null && teacherClass.grade!.name.isNotEmpty) ...[
            SizedBox(width: Responsive.w(8)),
            Container(
              padding: Responsive.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(Responsive.r(8)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 4,
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
                    size: Responsive.sp(12),
                  ),
                  SizedBox(width: Responsive.w(4)),
                  Text(
                    teacherClass.grade!.name,
                    style: AppFonts.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: AppFonts.size10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

