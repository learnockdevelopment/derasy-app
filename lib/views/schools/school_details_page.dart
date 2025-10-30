import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/routes/app_routes.dart';
import '../../models/school_models.dart';
import '../widgets/safe_network_image.dart';

class SchoolDetailsPage extends StatelessWidget {
  final School school;

  const SchoolDetailsPage({Key? key, required this.school}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
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
                      imageUrl: _getSchoolImageUrl(school),
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
                            school.type ?? 'N/A',
                            style: AppFonts.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 11.sp,
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          school.name,
                          style: AppFonts.h2.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20.sp,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 6.h),
                        if (school.location?.city != null || school.location?.governorate != null)
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded, 
                                  color: Colors.white.withOpacity(0.9), 
                                  size: 13.sp),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Text(
                                  '${school.location?.city ?? ''}, ${school.location?.governorate ?? ''}',
                                  style: AppFonts.bodySmall.copyWith(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 11.sp,
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

                  // All Information in One Box
                  _buildAllInfoSection(),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildContactSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            const Color(0xFFF8FAFC),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern Contact Header
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFEF4444),
                  Color(0xFFDC2626),
                ],
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: const Icon(
                    Icons.phone_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'contact_information'.tr,
                    style: AppFonts.h3.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          
          if (school.location?.mainPhone != null && school.location!.mainPhone!.isNotEmpty)
            _buildContactItem(
              icon: Icons.phone_rounded,
              label: 'main_phone'.tr,
              value: school.location!.mainPhone!,
              color: const Color(0xFF3B82F6),
            ),
          
          if (school.location?.secondaryPhone != null && school.location!.secondaryPhone!.isNotEmpty)
            _buildContactItem(
              icon: Icons.phone_rounded,
              label: 'secondary_phone'.tr,
              value: school.location!.secondaryPhone!,
              color: const Color(0xFF8B5CF6),
            ),
          
          if (school.location?.officialEmail != null && school.location!.officialEmail!.isNotEmpty)
            _buildContactItem(
              icon: Icons.email_rounded,
              label: 'official_email'.tr,
              value: school.location!.officialEmail!,
              color: const Color(0xFFEF4444),
            ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.08),
            color.withOpacity(0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color,
                  color.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppFonts.bodySmall.copyWith(
                    color: const Color(0xFF6B7280),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: AppFonts.bodyMedium.copyWith(
                    color: const Color(0xFF1F2937),
                    fontWeight: FontWeight.bold,
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

  Widget _buildQuickActionsSection() {
    final actions = [
      {
        'icon': Icons.school_rounded,
        'label': 'my_schools'.tr,
        'color': const Color(0xFF3B82F6),
        'onTap': () => Get.back(),
      },
    ];

    return Container(
      padding: EdgeInsets.all(20.w),
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            const Color(0xFFF8FAFC),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
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
          // Modern Header with Gradient
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF3B82F6),
                  Color(0xFF1E3A8A),
                ],
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
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.flash_on_rounded,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'quick_actions'.tr,
                        style: AppFonts.h3.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'access_school_features'.tr,
                        style: AppFonts.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '1',
                    style: AppFonts.bodySmall.copyWith(
                      color: const Color(0xFF3B82F6),
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 1.1,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: color.withOpacity(0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36.w,
              height: 36.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 18.sp),
            ),
            SizedBox(height: 6.h),
            Text(
              label,
              style: AppFonts.bodySmall.copyWith(
                color: const Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
                fontSize: 11.sp,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _viewReports() {
    Get.snackbar(
      'reports_coming_soon'.tr,
      'reports_coming_soon'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF3B82F6),
      colorText: Colors.white,
    );
  }

  void _openSettings() {
    Get.snackbar(
      'settings_coming_soon'.tr,
      'settings_coming_soon'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF3B82F6),
      colorText: Colors.white,
    );
  }


  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24.w,
                height: 24.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF3B82F6),
                  size: 12.sp,
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  label,
                  style: AppFonts.bodySmall.copyWith(
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                    fontSize: 10.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            style: AppFonts.bodySmall.copyWith(
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.w500,
              fontSize: 12.sp,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.08),
            color.withOpacity(0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 18.sp,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    label,
                    style: AppFonts.bodySmall.copyWith(
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                      fontSize: 11.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              value,
              style: AppFonts.bodyMedium.copyWith(
                color: const Color(0xFF1F2937),
                fontWeight: FontWeight.bold,
                fontSize: 13.sp,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
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
          onTap: () => Get.toNamed(AppRoutes.students, arguments: {'schoolId': school.id}),
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
                          fontSize: 18.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'view_and_manage_students'.tr,
                        style: AppFonts.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12.sp,
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
              fontSize: 18.sp,
            ),
          ),
          SizedBox(height: 16.h),
          
          // School Name
          _buildInfoRow('school_name'.tr, school.name, Icons.school_rounded, const Color(0xFF3B82F6)),
          SizedBox(height: 12.h),
          
          // School Type
          _buildInfoRow('school_type'.tr, school.type ?? 'N/A', Icons.category_rounded, const Color(0xFF10B981)),
          SizedBox(height: 12.h),
          
          // Education System
          _buildInfoRow('education_system'.tr, school.educationSystem ?? 'N/A', Icons.auto_stories_rounded, const Color(0xFFF59E0B)),
          SizedBox(height: 12.h),
          
          // Location
          if (school.location?.city != null || school.location?.governorate != null)
            _buildInfoRow('school_location'.tr, '${school.location?.city ?? 'N/A'}, ${school.location?.governorate ?? 'N/A'}', Icons.location_on_rounded, const Color(0xFF8B5CF6)),
          
          // Contact Information
          if (school.location?.mainPhone != null && school.location!.mainPhone!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Divider(color: const Color(0xFFE5E7EB), thickness: 1),
            SizedBox(height: 12.h),
            _buildInfoRow('main_phone'.tr, school.location!.mainPhone!, Icons.phone_rounded, const Color(0xFF3B82F6)),
          ],
          
          if (school.location?.secondaryPhone != null && school.location!.secondaryPhone!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _buildInfoRow('secondary_phone'.tr, school.location!.secondaryPhone!, Icons.phone_rounded, const Color(0xFF8B5CF6)),
          ],
          
          if (school.location?.officialEmail != null && school.location!.officialEmail!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _buildInfoRow('official_email'.tr, school.location!.officialEmail!, Icons.email_rounded, const Color(0xFFEF4444)),
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
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: AppFonts.bodyMedium.copyWith(
                  color: const Color(0xFF1F2937),
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
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
