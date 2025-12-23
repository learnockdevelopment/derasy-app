import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../models/school_models.dart';
import '../../services/schools_service.dart';
import 'school_details_page.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/safe_network_image.dart';

class SchoolsPage extends StatefulWidget {
  const SchoolsPage({Key? key}) : super(key: key);

  @override
  State<SchoolsPage> createState() => _SchoolsPageState();
}

class _SchoolsPageState extends State<SchoolsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<School> _schools = [];
  List<School> _filteredSchools = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSchools() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await SchoolsService.getAllSchools();

      if (mounted) {
        setState(() {
          _schools = response.schools;
          _filteredSchools = _schools;
          _isLoading = false;
        });
        
        // Show info if loaded from cache
        if (response.message.contains('cache')) {
          Get.snackbar(
            'info'.tr,
            'server_error_try_again'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFF59E0B),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      // Show appropriate error message
      String errorMessage = 'network_error'.tr;
      if (e.toString().contains('Server error') || e.toString().contains('500')) {
        errorMessage = 'server_error_try_again'.tr;
      }
      
      Get.snackbar(
        'error'.tr,
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    }
  }

  void _filterSchools(String query) {
    if (mounted) {
      setState(() {
        _searchQuery = query;
        if (query.isEmpty) {
          _filteredSchools = _schools;
        } else {
          _filteredSchools = _schools
              .where((school) =>
                  school.name.toLowerCase().contains(query.toLowerCase()) ||
                  (school.location?.governorate ?? '')
                      .toLowerCase()
                      .contains(query.toLowerCase()) ||
                  (school.location?.city ?? '')
                      .toLowerCase()
                      .contains(query.toLowerCase()))
              .toList();
        }
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _filterSchools('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: Text(
          'my_schools_title'.tr,
          style: AppFonts.h2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            
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
            icon: const Icon(Icons.refresh_rounded,
                color: Colors.white, size: 20),
            onPressed: _loadSchools,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
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
                onChanged: _filterSchools,
                decoration: InputDecoration(
                  hintText: 'search_schools'.tr,
                  hintStyle: AppFonts.bodyMedium.copyWith(
                    color: const Color(0xFF9CA3AF),
                    
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

          // Schools List
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      return ShimmerCard(
                        height: 120.h,
                        margin: EdgeInsets.only(bottom: 16.h),
                      );
                    },
                  )
                : _filteredSchools.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadSchools,
                        color: AppColors.primaryBlue,
                        child: ListView.builder(
                          padding: EdgeInsets.all(16.w),
                          itemCount: _filteredSchools.length,
                          itemBuilder: (context, index) {
                            return _buildSchoolCard(_filteredSchools[index]);
                          },
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
            'no_schools_found'.tr,
            style: AppFonts.h3.copyWith(
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.bold,
              
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'schools_will_appear_here'.tr,
            style: AppFonts.bodyMedium.copyWith(
              color: const Color(0xFF6B7280),
              
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolCard(School school) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.to(() => SchoolDetailsPage(school: school)),
          borderRadius: BorderRadius.circular(14.r),
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Accent bar
                    Container(width: 4.w, height: 48.h, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2.r), gradient: LinearGradient(colors: [AppColors.primaryBlue, AppColors.primaryBlue.withOpacity(0.6)], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
                    SizedBox(width: 12.w),
                    // Logo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.r),
                      child: SizedBox(width: 48.w, height: 48.h, child: SafeSchoolImage(imageUrl: _getSchoolImageUrlLocal(school), width: 48.w, height: 48.h)),
                    ),
                    SizedBox(width: 12.w),

                    // School Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(school.name, style: AppFonts.h4.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded, color: AppColors.textSecondary, size: 14.sp),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Text(
                                  '${school.location?.city ?? 'N/A'}, ${school.location?.governorate ?? 'N/A'}',
                                  style: AppFonts.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 12.sp),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Arrow
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: const Color(0xFF9CA3AF),
                      size: 16.sp,
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // School Details
                Row(children: [
                  _buildPill(icon: Icons.phone_rounded, text: school.location?.mainPhone ?? 'N/A'),
                  SizedBox(width: 8.w),
                  _buildPill(icon: Icons.email_rounded, text: school.location?.officialEmail ?? 'N/A'),
                ]),

                SizedBox(height: 12.h),

                // Status Badge
                Row(children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: AppColors.success.withOpacity(0.3), width: 1)),
                    child: Text('active_status'.tr, style: AppFonts.labelSmall.copyWith(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: AppFonts.size10)),
                  ),
                  const Spacer(),
                  Text('view_details'.tr, style: AppFonts.labelSmall.copyWith(color: AppColors.textSecondary, fontSize: 11.sp)),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _getSchoolImageUrlLocal(School school) => _getSchoolImageUrl(school);

  Widget _buildPill({required IconData icon, required String text}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 14.sp),
          SizedBox(width: 6.w),
          Text(text, style: AppFonts.labelSmall.copyWith(color: AppColors.textPrimary, fontSize: 11.sp)),
        ],
      ),
    );
  }

  // Helper to resolve school image URL
  String? _getSchoolImageUrl(School school) {
    if (school.visibilitySettings?.officialLogo?.url.isNotEmpty == true) {
      return school.visibilitySettings!.officialLogo!.url;
    } else if (school.media?.schoolImages?.isNotEmpty == true) {
      return school.media!.schoolImages!.first.url;
    } else if (school.bannerImage?.isNotEmpty == true) {
      return school.bannerImage;
    }
    return null;
  }


}
