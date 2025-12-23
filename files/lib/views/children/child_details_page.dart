import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../models/student_models.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/safe_network_image.dart';

class ChildDetailsPage extends StatefulWidget {
  final Student child;

  const ChildDetailsPage({Key? key, required this.child}) : super(key: key);

  @override
  State<ChildDetailsPage> createState() => _ChildDetailsPageState();
}

class _ChildDetailsPageState extends State<ChildDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    final imageUrl = child.avatar ?? child.profileImage ?? child.image;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
          onPressed: () => Get.back(),
        ),
        title: Text(
          child.fullName,
          style: AppFonts.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with Avatar
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue,
                    AppColors.primaryBlue.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: SizedBox(
                        width: 100.w,
                        height: 100.h,
                        child: SafeAvatarImage(
                          imageUrl: imageUrl?.isNotEmpty == true ? imageUrl : null,
                          size: 100,
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    child.fullName,
                    style: AppFonts.h2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22.sp,
                    ),
                  ),
                  if (child.studentCode.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'Code: ${child.studentCode}',
                      style: AppFonts.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Action Buttons
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToApply(),
                      icon: Icon(Icons.school_rounded, size: 20.sp),
                      label: Text(
                        'Apply to Schools',
                        style: AppFonts.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewApplications(),
                      icon: Icon(Icons.assignment_rounded, size: 20.sp),
                      label: Text(
                        'View Applications',
                        style: AppFonts.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        side: BorderSide(color: AppColors.primaryBlue, width: 2),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Information Cards
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  _buildInfoCard(
                    icon: Icons.person_outline,
                    title: 'Personal Information',
                    children: [
                      _buildInfoRow('Full Name', child.fullName),
                      if (child.gender.isNotEmpty)
                        _buildInfoRow('Gender', child.gender.toUpperCase()),
                      if (child.birthDate.isNotEmpty)
                        _buildInfoRow('Birth Date', child.birthDate),
                      if (child.ageInOctober > 0)
                        _buildInfoRow('Age', '${child.ageInOctober} years'),
                      if (child.nationalId.isNotEmpty)
                        _buildInfoRow('National ID', child.nationalId),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  if (child.schoolId.name.isNotEmpty || child.studentClass.name.isNotEmpty)
                    _buildInfoCard(
                      icon: Icons.school_outlined,
                      title: 'Academic Information',
                      children: [
                        if (child.schoolId.name.isNotEmpty)
                          _buildInfoRow('School', child.schoolId.name),
                        if (child.stage.name.isNotEmpty)
                          _buildInfoRow('Stage', child.stage.name),
                        if (child.grade.name.isNotEmpty)
                          _buildInfoRow('Grade', child.grade.name),
                        if (child.section.name.isNotEmpty)
                          _buildInfoRow('Section', child.section.name),
                        if (child.studentClass.name.isNotEmpty)
                          _buildInfoRow('Class', child.studentClass.name),
                      ],
                    ),
                  if (child.schoolId.name.isNotEmpty || child.studentClass.name.isNotEmpty)
                    SizedBox(height: 12.h),
                  if (child.address.isNotEmpty || child.medicalNotes.isNotEmpty)
                    _buildInfoCard(
                      icon: Icons.info_outline,
                      title: 'Additional Information',
                      children: [
                        if (child.address.isNotEmpty)
                          _buildInfoRow('Address', child.address),
                        if (child.medicalNotes.isNotEmpty)
                          _buildInfoRow('Medical Notes', child.medicalNotes),
                      ],
                    ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: AppColors.primaryBlue, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Text(
                title,
                style: AppFonts.h4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: AppFonts.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13.sp,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppFonts.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
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
    Get.toNamed(AppRoutes.applications);
  }
}

