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
        backgroundColor: AppColors.blue1,
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
            // Compact Header with Avatar
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.blue1,
                    AppColors.blue1.withOpacity(0.85),
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

            // Compact Action Buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _navigateToApply(),
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.blue1,
                                AppColors.blue1.withOpacity(0.85),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.blue1.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.school_rounded, size: 16.sp, color: Colors.white),
                              SizedBox(width: 6.w),
                              Text(
                                child.schoolId.id.isNotEmpty ? 'transfer_to_school'.tr : 'apply_to_schools'.tr,
                                style: AppFonts.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.sp,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _viewApplications(),
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: AppColors.blue1,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.blue1.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.assignment_rounded, size: 16.sp, color: AppColors.blue1),
                              SizedBox(width: 6.w),
                              Text(
                                'view_applications'.tr,
                                style: AppFonts.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.sp,
                                  color: AppColors.blue1,
                                ),
                              ),
                            ],
                          ),
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
                    title: 'personal_information'.tr,
                    children: [
                      _buildInfoRow('full_name'.tr, child.fullName),
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
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surface,
            AppColors.surface.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppColors.blue1.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.blue1.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(7.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.blue1,
                      AppColors.blue1.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blue1.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 16.sp),
              ),
              SizedBox(width: 10.w),
              Text(
                title,
                style: AppFonts.h4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: AppColors.grey200.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90.w,
            child: Text(
              label,
              style: AppFonts.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppFonts.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12.sp,
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
}


