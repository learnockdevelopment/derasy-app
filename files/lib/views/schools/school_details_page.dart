import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/routes/app_routes.dart';
import '../../models/school_models.dart';
import '../../widgets/safe_network_image.dart';

class SchoolDetailsPage extends StatefulWidget {
  final School school;

  const SchoolDetailsPage({Key? key, required this.school}) : super(key: key);

  @override
  State<SchoolDetailsPage> createState() => _SchoolDetailsPageState();
}
 
class _SchoolDetailsPageState extends State<SchoolDetailsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Professional App Bar
              SliverAppBar(
            expandedHeight: 160.h,
          floating: false,
          pinned: true,
          automaticallyImplyLeading: true,
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
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient Background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF1E3A8A), // Deep blue
                          Color(0xFF3B82F6), // Medium blue
                          Color(0xFF60A5FA), // Light blue
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                  // School Image
                  Positioned.fill(
                    child: SafeSchoolImage(
                      imageUrl: _getSchoolImageUrl(widget.school),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Dark overlay for better text contrast
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                  // School Name and Basic Info
                  Positioned(
                    bottom: 12.h,
                    left: 16.w,
                    right: 16.w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            widget.school.type ?? 'N/A',
                            style: AppFonts.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          widget.school.name,
                          style: AppFonts.h2.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 6.h),
                        if (widget.school.location?.city != null || widget.school.location?.governorate != null)
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded, 
                                  color: Colors.white.withOpacity(0.9), 
                                  size: 13.sp),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Text(
                                  '${widget.school.location?.city ?? ''}, ${widget.school.location?.governorate ?? ''}',
                                  style: AppFonts.bodySmall.copyWith(
                                    color: Colors.white.withOpacity(0.85),
                                    
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              ),
            ),

              // Content
              SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(14.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Students Button
                  _buildStudentsButton(),
                  SizedBox(height: 16.h),

                  // Teachers Button
                  _buildTeachersButton(),
                  SizedBox(height: 16.h),

                  // Classes Button
                  _buildClassesButton(),
                  SizedBox(height: 16.h),

                  // Buses Button
                  _buildBusesButton(),
                  SizedBox(height: 16.h),

                  // All Information in One Box
                  _buildAllInfoSection(),
                ],
              ),
            ),
              )            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassesButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.toNamed(AppRoutes.classes, arguments: {'schoolId': widget.school.id}),
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(18.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: const Icon(
                    Icons.class_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'classes'.tr,
                        style: AppFonts.h3.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'view_and_manage_classes'.tr,
                        style: AppFonts.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBusesButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF0EA5E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.toNamed(AppRoutes.buses, arguments: {
            'schoolId': widget.school.id,
            'school': widget.school,
          }),
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(18.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: const Icon(
                    IconlyBold.discovery,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'buses'.tr,
                        style: AppFonts.h3.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'view_and_manage'.tr,
                        style: AppFonts.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _getSchoolImageUrl(School school) {
    // Try to get image from visibility settings logo
    if (school.visibilitySettings?.officialLogo?.url.isNotEmpty == true) {
      return school.visibilitySettings!.officialLogo!.url;
    }
    // Try to get image from media school images
    else if (school.media?.schoolImages?.isNotEmpty == true) {
      return school.media!.schoolImages!.first.url;
    }
    // Try to get banner image
    else if (school.bannerImage?.isNotEmpty == true) {
      return school.bannerImage;
    }
    return null;
  }

  Widget _buildStudentsButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.toNamed(AppRoutes.students, arguments: {'schoolId': widget.school.id}),
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(18.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: const Icon(
                    Icons.people_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'students'.tr,
                        style: AppFonts.h3.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'view_and_manage_students'.tr,
                        style: AppFonts.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeachersButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.toNamed(AppRoutes.teachers, arguments: {'schoolId': widget.school.id}),
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(18.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'teachers'.tr,
                        style: AppFonts.h3.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'view_and_manage_teachers'.tr,
                        style: AppFonts.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllInfoSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'school_information'.tr,
            style: AppFonts.h3.copyWith(
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.bold,
              
            ),
          ),
          SizedBox(height: 16.h),
          
          // School Name
          _buildInfoRow('school_name'.tr, widget.school.name, Icons.school_rounded, const Color(0xFF3B82F6)),
          SizedBox(height: 12.h),
          
          // School Type
          _buildInfoRow('school_type'.tr, widget.school.type ?? 'N/A', Icons.category_rounded, const Color(0xFF10B981)),
          SizedBox(height: 12.h),
          
          // Education System
          _buildInfoRow('education_system'.tr, widget.school.educationSystem ?? 'N/A', Icons.auto_stories_rounded, const Color(0xFFF59E0B)),
          SizedBox(height: 12.h),
          
          // Location
          if (widget.school.location?.city != null || widget.school.location?.governorate != null)
            _buildInfoRow('school_location'.tr, '${widget.school.location?.city ?? 'N/A'}, ${widget.school.location?.governorate ?? 'N/A'}', Icons.location_on_rounded, const Color(0xFF8B5CF6)),
          
          // Contact Information
          if (widget.school.location?.mainPhone != null && widget.school.location!.mainPhone!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Divider(color: const Color(0xFFE5E7EB), thickness: 1),
            SizedBox(height: 12.h),
            _buildInfoRow('main_phone'.tr, widget.school.location!.mainPhone!, Icons.phone_rounded, const Color(0xFF3B82F6)),
          ],
          
          if (widget.school.location?.secondaryPhone != null && widget.school.location!.secondaryPhone!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _buildInfoRow('secondary_phone'.tr, widget.school.location!.secondaryPhone!, Icons.phone_rounded, const Color(0xFF8B5CF6)),
          ],
          
          if (widget.school.location?.officialEmail != null && widget.school.location!.officialEmail!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _buildInfoRow('official_email'.tr, widget.school.location!.officialEmail!, Icons.email_rounded, const Color(0xFFEF4444)),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: color, size: 20.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppFonts.bodySmall.copyWith(
                  color: const Color(0xFF6B7280),
                  
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: AppFonts.bodyMedium.copyWith(
                  color: const Color(0xFF1F2937),
                  fontWeight: FontWeight.bold,
                  
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

}
