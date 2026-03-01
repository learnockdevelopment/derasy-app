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
      backgroundColor: const Color(0xFF0F172A), // dark background
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
          onPressed: () => Get.back(),
        ), 
        title: Text(
          'student_details'.tr,
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
            // Compact Header with Avatar
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blue1.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: SizedBox(
                        width: 70.w,
                        height: 70.h,
                        child: SafeAvatarImage(
                          imageUrl: imageUrl?.isNotEmpty == true ? imageUrl : null,
                          size: 70,
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.fullName,
                          style: AppFonts.h3.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18.sp,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (child.studentCode.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              '${'code_colon'.tr} ${child.studentCode}',
                              style: AppFonts.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: child.schoolId.id.isNotEmpty
                  ? Column(
                      children: [
                        // Removed transfer button, show school name prominently
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10.w),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.school_rounded, color: Colors.white, size: 22.sp),
                              ),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('enrolled_at'.tr, style: TextStyle(color: Colors.white70, fontSize: 11.sp, fontWeight: FontWeight.w500)),
                                    SizedBox(height: 4.h),
                                    Text(child.schoolId.name, style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10.h),
                        _buildActionButton(
                          onTap: () => _viewApplications(),
                          icon: Icons.assignment_rounded,
                          label: 'view_applications'.tr,
                          isOutline: true,
                          isFullWidth: true,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            onTap: () => _navigateToApply(),
                            icon: Icons.school_rounded,
                            label: 'apply_to_schools'.tr,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _buildActionButton(
                            onTap: () => _viewApplications(),
                            icon: Icons.assignment_rounded,
                            label: 'view_applications'.tr,
                            isOutline: true,
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
                    title: 'personal_information'.tr,
                    children: [
                      _buildInfoRow('full_name'.tr, child.fullName),
                      if (child.arabicFullName != null && child.arabicFullName!.isNotEmpty)
                        _buildInfoRow('arabic_name'.tr, child.arabicFullName!),
                      if (child.gender.isNotEmpty)
                        _buildInfoRow('gender'.tr, child.gender.toUpperCase()),
                      if (child.birthDate.isNotEmpty)
                        _buildInfoRow('birth_date_label'.tr, child.birthDate),
                      if (child.ageInOctober > 0)
                        _buildInfoRow('age'.tr, '${child.ageInOctober} ${'years'.tr}'),
                      if (child.nationalId.isNotEmpty)
                        _buildInfoRow('national_id_label'.tr, child.nationalId),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  if (child.schoolId.name.isNotEmpty || child.studentClass.name.isNotEmpty)
                    _buildInfoCard(
                      icon: Icons.school_outlined,
                      title: 'academic_information'.tr,
                      children: [
                        if (child.schoolId.name.isNotEmpty)
                          _buildInfoRow('school_label'.tr, child.schoolId.name),
                        if (child.stage.name.isNotEmpty)
                          _buildInfoRow('stage'.tr, child.stage.name),
                        if (child.grade.name.isNotEmpty)
                          _buildInfoRow('grade'.tr, child.grade.name),
                        if (child.section.name.isNotEmpty)
                          _buildInfoRow('section'.tr, child.section.name),
                        if (child.studentClass.name.isNotEmpty)
                          _buildInfoRow('class'.tr, child.studentClass.name),
                      ],
                    ),
                  if (child.schoolId.name.isNotEmpty || child.studentClass.name.isNotEmpty)
                    SizedBox(height: 10.h),
                  if (child.address.isNotEmpty || child.medicalNotes.isNotEmpty)
                    _buildInfoCard(
                      icon: Icons.info_outline,
                      title: 'additional_information'.tr,
                      children: [
                        if (child.address.isNotEmpty)
                          _buildInfoRow('address'.tr, child.address),
                        if (child.medicalNotes.isNotEmpty)
                          _buildInfoRow('medical_notes'.tr, child.medicalNotes),
                      ],
                    ),
                  SizedBox(height: 16.h),
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
        color: const Color(0xFF1E293B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
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
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: Colors.white, size: 18.sp),
              ),
              SizedBox(width: 12.w),
              Text(
                title,
                style: AppFonts.h4.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15.sp,
                  letterSpacing: 0.3,
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
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: AppFonts.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppFonts.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
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
    bool isOutline = false,
    bool isFullWidth = false,
  }) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          width: isFullWidth ? double.infinity : null,
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
          decoration: BoxDecoration(
            gradient: isOutline
                ? null
                : LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: isOutline ? Colors.white.withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(14.r),
            border: isOutline
                ? Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  )
                : null,
            boxShadow: isOutline ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Icon(icon, size: 18.sp, color: Colors.white),
              SizedBox(width: 8.w),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return button;
  }
}


