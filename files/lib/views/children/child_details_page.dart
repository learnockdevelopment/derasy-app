import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'dart:ui';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../models/student_models.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/safe_network_image.dart';
import '../../core/controllers/app_config_controller.dart';
import 'package:iconly/iconly.dart';
import '../../services/students_service.dart';

class ChildDetailsPage extends StatefulWidget {
  final Student child;

  const ChildDetailsPage({Key? key, required this.child}) : super(key: key);

  @override
  State<ChildDetailsPage> createState() => _ChildDetailsPageState();
}

class _ChildDetailsPageState extends State<ChildDetailsPage> {
  @override
  void initState() {
    super.initState();
    print('👤 [CHILD DETAILS] ===========================================');
    print('👤 [CHILD DETAILS] Child Details Page Opened');
    print('USER PROFILE CHILD DATA: ${widget.child.fullName}');
    print('CHILD DETAILS ID: ${widget.child.id}');
    print('CHILD DETAILS CODE: ${widget.child.studentCode}');
    print('CHILD DETAILS NATIONAL ID: ${widget.child.nationalId}');
    print('CHILD DETAILS GENDER: ${widget.child.gender}');
    print('CHILD DETAILS BIRTHDATE: ${widget.child.birthDate}');
    print('CHILD DETAILS AGE: ${widget.child.ageInOctober}');
    print('CHILD DETAILS ADDRESS: ${widget.child.address}');
    print('CHILD DETAILS MEDICAL: ${widget.child.medicalNotes}');
    print('CHILD DETAILS STAGE: ${widget.child.stage.name}');
    print('CHILD DETAILS GRADE: ${widget.child.grade.name}');
    print('CHILD DETAILS CLASS: ${widget.child.studentClass.name}');
    print('👤 [CHILD DETAILS] ===========================================');
    _fetchAndPrintChildDetailsFromApi();
  }

  Future<void> _fetchAndPrintChildDetailsFromApi() async {
    try {
      final res = await StudentsService.getChildDetails(widget.child.id);
      print('👤 [CHILD DETAILS API] RESPONSE: $res');
    } catch (e) {
      print('👤 [CHILD DETAILS API] ERROR calling API: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = AppConfigController.to.isDarkMode;
      final child = widget.child;
      final imageUrl = child.avatar ?? child.profileImage ?? child.image;
      final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
      final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
      final cardColor = isDark ? const Color(0xFF1E293B).withOpacity(0.6) : Colors.white;
      final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.2);
      
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20.sp),
            onPressed: () => Get.back(),
          ), 
          title: Text(
            'student_details'.tr,
            style: AppFonts.h3.copyWith(
              color: textColor,
              fontWeight: FontWeight.w900,
              fontSize: 18.sp,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Premium Header with Avatar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(20.w, 40.h, 20.w, 20.h),
                      margin: EdgeInsets.only(top: 40.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF9333EA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 24.h),
                          Text(
                            child.fullName,
                            style: AppFonts.h3.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 20.sp,
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (child.studentCode.isNotEmpty) ...[
                            SizedBox(height: 8.h),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Text(
                                '${'code_colon'.tr} ${child.studentCode}',
                                style: AppFonts.bodySmall.copyWith(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: SizedBox(
                              width: 90.w,
                              height: 90.h,
                              child: SafeAvatarImage(
                                imageUrl: imageUrl?.isNotEmpty == true ? imageUrl : null,
                                size: 90,
                                backgroundColor: Colors.grey[200]!,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: child.schoolId.id.isNotEmpty
                    ? Column(
                        children: [
                          // Highlighted School Info
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(color: borderColor),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.blue1.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16.r),
                                  ),
                                  child: Icon(IconlyBold.work, color: AppColors.blue1, size: 28.sp),
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('enrolled_at'.tr, style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600], fontSize: 12.sp, fontWeight: FontWeight.w600)),
                                      SizedBox(height: 4.h),
                                      Text(child.schoolId.name, style: TextStyle(color: textColor, fontSize: 15.sp, fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          _buildActionButton(
                            onTap: () => _viewApplications(),
                            icon: IconlyBold.document,
                            label: 'view_applications'.tr,
                            isPrimary: false,
                            isFullWidth: true,
                            isDark: isDark,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              onTap: () => _navigateToApply(),
                              icon: IconlyBold.send,
                              label: 'apply_to_schools'.tr,
                              isPrimary: true,
                              isDark: isDark,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildActionButton(
                              onTap: () => _viewApplications(),
                              icon: IconlyBold.document,
                              label: 'view_applications'.tr,
                              isPrimary: false,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
              ),

              // Modern Information Cards
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    _buildInfoCard(
                      isDark: isDark,
                      icon: IconlyBold.profile,
                      title: 'personal_information'.tr,
                      children: [
                        _buildInfoRow('full_name'.tr, child.fullName, isDark),
                        if (child.arabicFullName != null && child.arabicFullName!.isNotEmpty)
                          _buildInfoRow('arabic_name'.tr, child.arabicFullName!, isDark),
                        if (child.nationalId.isNotEmpty)
                          _buildInfoRow('national_id_label'.tr, child.nationalId, isDark, isHighlight: true),
                        if (child.gender.isNotEmpty)
                          _buildInfoRow('gender'.tr, child.gender.toLowerCase().tr, isDark),
                        if (child.birthDate.isNotEmpty)
                          _buildInfoRow('birth_date_label'.tr, _formatDate(child.birthDate), isDark),
                        if (child.ageInOctober > 0)
                          _buildInfoRow('age'.tr, _formatAgeInOctober(child.ageInOctober, child.birthDate), isDark),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    if (child.schoolId.name.isNotEmpty || child.studentClass.name.isNotEmpty)
                      _buildInfoCard(
                        isDark: isDark,
                        icon: IconlyBold.bookmark,
                        title: 'academic_information'.tr,
                        children: [
                          if (child.schoolId.name.isNotEmpty)
                            _buildInfoRow('school_label'.tr, child.schoolId.name, isDark),
                          if (child.stage.name.isNotEmpty)
                            _buildInfoRow('stage'.tr, child.stage.name, isDark),
                          if (child.grade.name.isNotEmpty)
                            _buildInfoRow('grade'.tr, child.grade.name, isDark),
                          if (child.section.name.isNotEmpty)
                            _buildInfoRow('section'.tr, child.section.name, isDark),
                          if (child.studentClass.name.isNotEmpty)
                            _buildInfoRow('class'.tr, child.studentClass.name, isDark),
                        ],
                      ),
                    if (child.address.isNotEmpty || child.medicalNotes.isNotEmpty)
                      SizedBox(height: 16.h),
                    if (child.address.isNotEmpty || child.medicalNotes.isNotEmpty)
                      _buildInfoCard(
                        isDark: isDark,
                        icon: IconlyBold.info_circle,
                        title: 'additional_information'.tr,
                        children: [
                          if (child.address.isNotEmpty)
                            _buildInfoRow('address'.tr, child.address, isDark),
                          if (child.medicalNotes.isNotEmpty)
                            _buildInfoRow('medical_notes'.tr, child.medicalNotes, isDark),
                        ],
                      ),
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildInfoCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final cardColor = isDark ? const Color(0xFF1E293B).withOpacity(0.6) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.2);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF9333EA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: Colors.white, size: 20.sp),
              ),
              SizedBox(width: 14.w),
              Text(
                title,
                style: AppFonts.h4.copyWith(
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  fontWeight: FontWeight.w900,
                  fontSize: 16.sp,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark, {bool isHighlight = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: isHighlight 
            ? (isDark ? AppColors.blue1.withOpacity(0.15) : AppColors.blue1.withOpacity(0.08))
            : (isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isHighlight 
              ? (isDark ? AppColors.blue1.withOpacity(0.3) : AppColors.blue1.withOpacity(0.2))
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.transparent),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: AppFonts.bodySmall.copyWith(
                color: isHighlight 
                    ? (isDark ? AppColors.blue1 : const Color(0xFF4F46E5))
                    : (isDark ? Colors.white54 : Colors.grey[600]),
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppFonts.bodyMedium.copyWith(
                color: isHighlight 
                    ? (isDark ? Colors.white : const Color(0xFF1E293B))
                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
                fontWeight: isHighlight ? FontWeight.w900 : FontWeight.bold,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToApply() {
    Get.toNamed(AppRoutes.applyToSchools, arguments: {'child': widget.child});
  }

  void _viewApplications() {
    Get.toNamed(
      AppRoutes.applications,
      arguments: {
        'childId': widget.child.id,
        'child': widget.child,
      },
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    bool isPrimary = false,
    bool isFullWidth = false,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          width: isFullWidth ? double.infinity : null,
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF9333EA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isPrimary ? null : (isDark ? Colors.white.withOpacity(0.08) : Colors.white),
            borderRadius: BorderRadius.circular(16.r),
            border: isPrimary
                ? null
                : Border.all(
                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.3),
                    width: 1,
                  ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Icon(
                icon, 
                size: 20.sp, 
                color: isPrimary ? Colors.white : (isDark ? Colors.white : const Color(0xFF1E293B)),
              ),
              SizedBox(width: 10.w),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.bodyMedium.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 14.sp,
                    color: isPrimary ? Colors.white : (isDark ? Colors.white : const Color(0xFF1E293B)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }

  String _formatAgeInOctober(int ageInMonths, String? birthDate) {
    final years = ageInMonths ~/ 12;
    final months = ageInMonths % 12;

    int days = 0;
    if (birthDate != null && birthDate.isNotEmpty) {
      try {
        final birth = DateTime.parse(birthDate);
        final now = DateTime.now();
        final targetDate = now.month < 10
            ? DateTime(now.year, 10, 1)
            : DateTime(now.year + 1, 10, 1);

        final totalDays = targetDate.difference(birth).inDays;
        final totalMonthsFromBirth = (totalDays / 30.44).floor();
        final remainingDays = totalDays - (totalMonthsFromBirth * 30.44).round();
        days = remainingDays.round().abs();
      } catch (e) {}
    }

    final parts = <String>[];
    if (years > 0) parts.add('$years ${years == 1 ? 'year'.tr : 'years'.tr}');
    if (months > 0) parts.add('$months ${months == 1 ? 'month'.tr : 'months'.tr}');
    if (days > 0) parts.add('$days ${days == 1 ? 'day'.tr : 'days'.tr}');

    return parts.isEmpty ? '0 ${'months'.tr}' : parts.join(' - ');
  }
}
