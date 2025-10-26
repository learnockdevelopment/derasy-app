import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_fonts.dart';
import '../../models/school_models.dart';
import '../../services/schools_service.dart';
import 'school_details_page.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/safe_network_image.dart';

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
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      Get.snackbar(
        'Error',
        'Failed to load schools: ${e.toString()}',
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
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        title: Text(
          'My Schools',
          style: AppFonts.h2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
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
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A8A),
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
                  hintText: 'Search schools...',
                  hintStyle: AppFonts.bodyMedium.copyWith(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 14.sp,
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
                        color: const Color(0xFF1E3A8A),
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
            'No schools found',
            style: AppFonts.h3.copyWith(
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Schools will appear here once added',
            style: AppFonts.bodyMedium.copyWith(
              color: const Color(0xFF6B7280),
              fontSize: 14.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolCard(School school) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.to(
            () => SchoolDetailsPage(school: school),
          ),
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // School Avatar with Image
                    _buildSchoolAvatar(school),
                    SizedBox(width: 16.w),

                    // School Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            school.name,
                            style: AppFonts.h3.copyWith(
                              color: const Color(0xFF1F2937),
                              fontWeight: FontWeight.bold,
                              fontSize: 18.sp,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: const Color(0xFF6B7280),
                                size: 16.sp,
                              ),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Text(
                                  '${school.location?.city ?? 'N/A'}, ${school.location?.governorate ?? 'N/A'}',
                                  style: AppFonts.bodyMedium.copyWith(
                                    color: const Color(0xFF6B7280),
                                    fontSize: 14.sp,
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

                    // Arrow
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: const Color(0xFF9CA3AF),
                      size: 16.sp,
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // School Details
                Container(
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
                      _buildDetailItem(
                        icon: Icons.phone_rounded,
                        label: 'Phone',
                        value: school.location?.mainPhone ?? 'N/A',
                      ),
                      SizedBox(width: 16.w),
                      _buildDetailItem(
                        icon: Icons.email_rounded,
                        label: 'Email',
                        value: school.location?.officialEmail ?? 'N/A',
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12.h),

                // Status Badge
                Row(
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'ACTIVE',
                        style: AppFonts.labelSmall.copyWith(
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Tap to view details',
                      style: AppFonts.labelSmall.copyWith(
                        color: const Color(0xFF9CA3AF),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF6B7280),
                size: 14.sp,
              ),
              SizedBox(width: 4.w),
              Text(
                label,
                style: AppFonts.labelSmall.copyWith(
                  color: const Color(0xFF6B7280),
                  fontSize: 10.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: AppFonts.bodySmall.copyWith(
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
              fontSize: 12.sp,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolAvatar(School school) {
    // Get school image from various sources
    String? imageUrl;

    // Try to get image from visibility settings logo
    if (school.visibilitySettings?.officialLogo?.url.isNotEmpty == true) {
      imageUrl = school.visibilitySettings!.officialLogo!.url;
    }
    // Try to get image from media school images
    else if (school.media?.schoolImages?.isNotEmpty == true) {
      imageUrl = school.media!.schoolImages!.first.url;
    }
    // Try to get banner image
    else if (school.bannerImage?.isNotEmpty == true) {
      imageUrl = school.bannerImage;
    }

    return Container(
      width: 60.w,
      height: 60.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF3B82F6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: SafeSchoolImage(
          imageUrl: imageUrl,
          width: 60.w,
          height: 60.h,
        ),
      ),
    );
  }
}
