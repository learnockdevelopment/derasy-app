import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../models/school_models.dart';
import '../../services/schools_service.dart';
import '../../services/user_storage_service.dart';
import '../schools/school_details_page.dart';
import '../profile/user_profile_page.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/safe_network_image.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = false;
  List<School> _schools = [];
  Map<String, dynamic>? _userData;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load user data
      final userData = await UserStorageService.getUserData();
      
      // Print full user data
      print('🏠 [HOME] ===========================================');
      print('🏠 [HOME] FULL USER DATA FROM API:');
      print('🏠 [HOME] ${userData?.toString() ?? 'null'}');
      print('🏠 [HOME] ===========================================');
      
      if (userData != null) {
        userData.forEach((key, value) {
          print('🏠 [HOME] $key: $value');
        });
      }
      
      setState(() {
        _userData = userData;
      });

      // Load schools
      final response = await SchoolsService.getAllSchools();
      if (response.success) {
        setState(() {
          _schools = response.schools;
        });
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'network_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeContent(),
          _buildProfileContent(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(), 
    );
  }

  Widget _buildHomeContent() {
    return CustomScrollView(
      slivers: [
        // Enhanced App Bar
        SliverAppBar( 
          expandedHeight: 80.h,
          floating: false,
          pinned: true,
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF1E3A8A),
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1E3A8A),
                    Color(0xFF3B82F6),
                    Color(0xFF60A5FA),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                   padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 10.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          // User Avatar with Badge
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2.5,
                              ),
                            ),
                            child: Stack(
                              children: [
                                _buildUserAvatar(),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 14.w,
                                    height: 14.h,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 14.w),
                          // User Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _userData?['name'] ?? 'User',
                                  style: AppFonts.h2.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  _userData?['email'] ?? '',
                                  style: AppFonts.bodySmall.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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

        // Content - Only Schools
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 80.h),
            child: _buildSchoolsSection(),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileContent() {
    return const UserProfilePage();
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'home'.tr,
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.person_rounded,
                label: 'profile'.tr,
                index: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1E3A8A).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF1E3A8A)
                  : const Color(0xFF9CA3AF),
              size: 24.sp,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: AppFonts.labelSmall.copyWith(
                color: isSelected
                    ? const Color(0xFF1E3A8A)
                    : const Color(0xFF9CA3AF),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Modern Section Header
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 18.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              'my_schools'.tr,
              style: AppFonts.h3.copyWith(
                color: const Color(0xFF1F2937),
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
            const Spacer(),
            if (_schools.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '${_schools.length}',
                  style: AppFonts.bodySmall.copyWith(
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
              ),
          ],
        ),
        
        // Schools List or Empty State
        if (_isLoading)
          _buildLoadingShimmer()
        else if (_schools.isEmpty)
          _buildEmptyState()
        else
          _buildModernSchoolsList(),
      ],
    );
  }

  Widget _buildLoadingShimmer() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: 3.8,
        mainAxisSpacing: 10.h,
      ),
      itemCount: 3,
      itemBuilder: (context, index) {
        return ShimmerListTile(hasAvatar: true, hasSubtitle: true);
      },
    );
  }

  Widget _buildModernSchoolsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _schools.length,
              separatorBuilder: (context, index) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        final school = _schools[index];
        return _buildModernSchoolCard(school);
      },
    );
  }

  Widget _buildModernSchoolCard(School school) {
    String? imageUrl = _getSchoolImageUrl(school);
    
      return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.to(() => SchoolDetailsPage(school: school)),
          borderRadius: BorderRadius.circular(10.r),
          child: Padding(
            padding: EdgeInsets.all(10.w),
            child: Row(
              children: [
                // School Avatar
                          Container(
                            width: 40.w,
                            height: 40.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)],  
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: SafeSchoolImage(
                      imageUrl: imageUrl,
                      width: 40.w,
                      height: 40.h,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                // School Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              school.name,
                              style: AppFonts.h4.copyWith(
                                color: const Color(0xFF1F2937),
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 3.h),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: const Color(0xFF6B7280),
                            size: 12.sp,
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Text(
                              '${school.location?.city ?? 'N/A'}, ${school.location?.governorate ?? 'N/A'}',
                              style: AppFonts.bodySmall.copyWith(
                                color: const Color(0xFF6B7280),
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
                SizedBox(width: 8.w),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: const Color(0xFF3B82F6),
                  size: 16.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
              ),
              borderRadius: BorderRadius.circular(40.r),
            ),
            child: Icon(
              Icons.school_outlined,
              size: 40.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'no_schools_found'.tr,
            style: AppFonts.h4.copyWith(
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'add_first_school'.tr,
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

  Widget _buildUserAvatar() {
    // Get user image from user data
    String? imageUrl = _userData?['avatar'] ??
        _userData?['profileImage'] ??
        _userData?['image'];

    return Container(
      width: 44.w,
      height: 44.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: SafeAvatarImage(
          imageUrl: imageUrl,
          size: 40,
          backgroundColor: const Color(0xFF1E3A8A),
        ),
      ),
    );
  }

}
